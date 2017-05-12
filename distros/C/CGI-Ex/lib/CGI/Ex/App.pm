package CGI::Ex::App;

###---------------------###
#  Copyright 2004-2015 - Paul Seamons
#  Distributed under the Perl Artistic License without warranty

use strict;
BEGIN {
    eval { use Time::HiRes qw(time) };
    eval { use Scalar::Util };
}
our $VERSION = '2.44';

sub croak { die sprintf "%s at %3\$s line %4\$s\n", $_[0], caller 1 }

sub new {
    my $class = shift || croak "Missing class name";
    my $self = bless ref($_[0]) ? shift() : (@_ % 2) ? {} : {@_}, $class;
    $self->init;
    $self->init_from_conf;
    return $self;
}

sub init {}
sub init_from_conf {
    my $self = shift;
    @$self{keys %$_} = values %$_  if $self->load_conf and $_ = $self->conf;
}

sub import { # only ever called with explicit use CGI::Ex::App qw() - not with use base
    my $class = shift;
    return if not @_ = grep { /^:?App($|__)/ } @_;
    require CGI::Ex::App::Constants;
    unshift @_, 'CGI::Ex::App::Constants';
    goto &CGI::Ex::App::Constants::import;
}

###---------------------###

sub navigate {
    my ($self, $args) = @_;
    $self = $self->new($args) if ! ref $self;

    $self->{'_time'} = time;
    eval {
        return $self if ! $self->{'_no_pre_navigate'} && $self->pre_navigate;
        local $self->{'_morph_lineage_start_index'} = $#{$self->{'_morph_lineage'} || []};
        $self->nav_loop;
    };
    my $err = $@;
    if ($err && (ref($err) || $err ne "Long Jump\n")) { # catch any errors
        die $err if ! $self->can('handle_error');
        if (! eval { $self->handle_error($err); 1 }) {
            die "$err\nAdditionally, the following happened while calling handle_error: $@";
        }
    }
    $self->handle_error($@) if ! $self->{'_no_post_navigate'} && ! eval { $self->post_navigate; 1 } && $@ && $@ ne "Long Jump\n";
    $self->destroy;
    return $self;
}

sub nav_loop {
    my $self = shift;
    local $self->{'_recurse'} = $self->{'_recurse'} || 0;
    if ($self->{'_recurse'}++ >= $self->recurse_limit) {
        my $err = "recurse_limit (".$self->recurse_limit.") reached";
        croak(($self->{'jumps'} || 0) <= 1 ? $err : "$err number of jumps (".$self->{'jumps'}.")");
    }

    my $path = $self->path;
    return if $self->pre_loop($path);

    foreach ($self->{'path_i'} ||= 0; $self->{'path_i'} <= $#$path; $self->{'path_i'}++) {
        my $step = $path->[$self->{'path_i'}];
        if ($step !~ /^([^\W0-9]\w*)$/) {
            $self->stash->{'forbidden_step'} = $step;
            $self->goto_step($self->forbidden_step);
        }
        $step = $1; # untaint

        if (! $self->is_authed) {
            my $req = $self->run_hook('require_auth', $step, 1);
            return if (ref($req) ? $req->{$step} : $req) && ! $self->run_hook('get_valid_auth', $step);
        }

        $self->run_hook('morph', $step); # let steps be in external modules
        $self->parse_path_info('path_info_map', $self->run_hook('path_info_map', $step));
        if ($self->run_hook('run_step', $step)) {
            $self->run_hook('unmorph', $step);
            return;
        }

        $self->run_hook('refine_path', $step, $self->{'path_i'} >= $#$path);
        $self->run_hook('unmorph', $step);
    }

    return if $self->post_loop($path);
    $self->insert_path($self->default_step); # run the default step as a last resort
    $self->nav_loop; # go recursive
    return;
}

sub path {
    my $self = shift;
    return $self->{'path'} ||= do {
        my @path;
        $self->parse_path_info('path_info_map_base', $self->path_info_map_base); # add initial items to the form hash from path_info
        my $step = $self->form->{$self->step_key}; # make sure the step is valid
        if (defined $step) {
            $step =~ s|^/+||; $step =~ s|/|__|g;
            if ($step =~ /^_/) {         # can't begin with _
                $self->stash->{'forbidden_step'} = $step;
                push @path, $self->forbidden_step;
            } elsif ($self->valid_steps  # must be in valid_steps if defined
                && ! $self->valid_steps->{$step}
                && $step ne $self->default_step
                && $step ne $self->js_step) {
                $self->stash->{'forbidden_step'} = $step;
                push @path, $self->forbidden_step;
            } else {
                push @path, $step;
            }
        }
        \@path;
    };
}

sub parse_path_info {
    my ($self, $type, $maps, $info, $form) = @_;
    return if !$maps;
    $info ||= $self->path_info || return;
    croak "Usage: sub $type { [] }" if ! UNIVERSAL::isa($maps, 'ARRAY');
    foreach my $map (@$maps) {
        croak "Usage: sub $type { [[qr{/path_info/(\\w+)}, 'keyname']] }" if ! UNIVERSAL::isa($map, 'ARRAY');
        my @match = $info =~ $map->[0] or next;
        $form ||= $self->form;
        if (UNIVERSAL::isa($map->[1], 'CODE')) {
            $map->[1]->($form, @match);
        } else {
            $form->{$map->[$_]} = $match[$_ - 1] foreach grep {! defined $form->{$map->[$_]}} 1 .. $#$map;
        }
        last;
    }
}

sub run_hook {
    my ($self, $hook, $step, @args) = @_;
    my ($code, $found) = (ref $hook eq 'CODE') ? ($_[1], $hook = 'coderef') : ($self->find_hook($hook, $step));
    croak "Could not find a method named ${step}_${hook} or ${hook}" if ! $code;

    return scalar $self->$code($step, @args) if !$self->{'no_history'};

    push @{ $self->history }, my $hist = {step => $step, meth => $hook, found => $found, time => time, level => $self->{'_level'}, elapsed => 0};
    local $self->{'_level'} = 1 + ($self->{'_level'} || 0);
    $hist->{'elapsed'}  = time - $hist->{'time'};
    return $hist->{'response'} = $self->$code($step, @args);
}

sub find_hook {
    my ($self, $hook, $step) = @_;
    croak "Missing hook name" if ! $hook;
    if ($step and my $code = $self->can("${step}_${hook}")) {
        return ($code, "${step}_${hook}");
    } elsif ($code = $self->can($hook)) {
        return ($code, $hook);
    }
    return;
}

sub run_hook_as {
    my ($self, $hook, $step, $pkg, @args) = @_;
    croak "Missing hook"    if ! $hook;
    croak "Missing step"    if ! $step;
    croak "Missing package" if ! $pkg;
    $self->morph($step, 2, $pkg);
    my $resp = $self->run_hook($hook, $step, @args);
    $self->unmorph;
    return $resp;
}

sub run_step {
    my ($self, $step) = @_;
    return 1 if $self->run_hook('pre_step', $step); # if true exit the nav_loop
    return 0 if $self->run_hook('skip', $step);     # if true skip this step

    # check for complete valid information for this step
    if (   ! $self->run_hook('prepare', $step)
        || ! $self->run_hook('info_complete', $step)
        || ! $self->run_hook('finalize', $step)) {

        $self->run_hook('prepared_print', $step); # show the page requesting the information
        $self->run_hook('post_print', $step);     # a hook after the printing process

        return 1;
    }

    return 1 if $self->run_hook('post_step', $step); # if true exit the nav_loop
    return 0; # let the nav_loop continue searching the path
}

sub prepared_print {
    my $self = shift;
    my $step = shift;
    my $hash_form = $self->run_hook('hash_form',   $step) || {};
    my $hash_base = $self->run_hook('hash_base',   $step) || {};
    my $hash_comm = $self->run_hook('hash_common', $step) || {};
    my $hash_swap = $self->run_hook('hash_swap',   $step) || {};
    my $hash_fill = $self->run_hook('hash_fill',   $step) || {};
    my $hash_errs = $self->run_hook('hash_errors', $step) || {};
    $hash_errs->{$_} = $self->format_error($hash_errs->{$_}) foreach keys %$hash_errs;
    $hash_errs->{'has_errors'} = 1 if scalar keys %$hash_errs;

    my $swap = {%$hash_form, %$hash_base, %$hash_comm, %$hash_swap, %$hash_errs};
    my $fill = {%$hash_form, %$hash_base, %$hash_comm, %$hash_fill};
    $self->run_hook('print', $step, $swap, $fill);
}

sub print {
    my ($self, $step, $swap, $fill) = @_;
    my $file = $self->run_hook('file_print', $step); # get a filename relative to template_path
    my $out  = $self->run_hook('swap_template', $step, $file, $swap);
    $self->run_hook('fill_template', $step, \$out, $fill);
    $self->run_hook('print_out',     $step, \$out);
}

sub handle_error {
    my ($self, $err) = @_;
    die $err if $self->{'_handling_error'};
    local @$self{'_handling_error', '_recurse' } = (1, 0); # allow for this next step - even if we hit a recurse error
    $self->stash->{'error_step'} = $self->current_step;
    $self->stash->{'error'}      = $err;
    eval {
        my $step = $self->error_step;
        $self->morph($step); # let steps be in external modules
        $self->run_hook('run_step', $step) && $self->unmorph($step);
    };
    die $@ if $@ && $@ ne "Long Jump\n";
}

###---------------------###
# read only accessors

sub allow_morph        { $_[0]->{'allow_morph'} }
sub auth_args          { $_[0]->{'auth_args'} }
sub auth_obj           { shift->{'auth_obj'}       || do { require CGI::Ex::Auth; CGI::Ex::Auth->new(@_) } }
sub charset            { $_[0]->{'charset'}        ||  '' }
sub conf_args          { $_[0]->{'conf_args'} }
sub conf_die_on_fail   { $_[0]->{'conf_die_on_fail'} || ! defined $_[0]->{'conf_die_on_fail'} }
sub conf_path          { $_[0]->{'conf_path'}      ||  $_[0]->base_dir_abs }
sub conf_validation    { $_[0]->{'conf_validation'} }
sub default_step       { $_[0]->{'default_step'}   || 'main'        }
sub error_step         { $_[0]->{'error_step'}     || '__error'     }
sub fill_args          { $_[0]->{'fill_args'} }
sub forbidden_step     { $_[0]->{'forbidden_step'} || '__forbidden' }
sub form_name          { $_[0]->{'form_name'}      || 'theform'     }
sub history            { $_[0]->{'history'}        ||= []           }
sub js_step            { $_[0]->{'js_step'}        || 'js'          }
sub login_step         { $_[0]->{'login_step'}     || '__login'     }
sub mimetype           { $_[0]->{'mimetype'}       ||  'text/html'  }
sub path_info          { $_[0]->{'path_info'}      ||  $ENV{'PATH_INFO'}   || '' }
sub path_info_map_base { $_[0]->{'path_info_map_base'} ||[[qr{/(\w+)}, $_[0]->step_key]] }
sub recurse_limit      { $_[0]->{'recurse_limit'}  ||  15    }
sub script_name        { $_[0]->{'script_name'}    ||  $ENV{'SCRIPT_NAME'} || $0 }
sub stash              { $_[0]->{'stash'}          ||= {}    }
sub step_key           { $_[0]->{'step_key'}       || 'step' }
sub template_args      { $_[0]->{'template_args'} }
sub template_obj       { shift->{'template_obj'}   || do { require Template::Alloy; Template::Alloy->new(@_) } }
sub template_path      { $_[0]->{'template_path'}  ||  $_[0]->base_dir_abs  }
sub val_args           { $_[0]->{'val_args'} }
sub val_path           { $_[0]->{'val_path'}       ||  $_[0]->template_path }

sub conf_obj {
    my $self = shift;
    return $self->{'conf_obj'} || do {
        my $args = $self->conf_args || {};
        $args->{'paths'}     ||= $self->conf_path;
        $args->{'directive'} ||= 'MERGE';
        require CGI::Ex::Conf;
        CGI::Ex::Conf->new($args);
    };
}

sub val_obj {
    my $self = shift;
    return $self->{'val_obj'} || do {
        my $args = $self->val_args || {};
        $args->{'cgix'} ||= $self->cgix;
        require CGI::Ex::Validate;
        CGI::Ex::Validate->new($args);
    };
}

###---------------------###
# read/write accessors

sub auth_data    { (@_ == 2) ? $_[0]->{'auth_data'}    = pop : $_[0]->{'auth_data'}              }
sub base_dir_abs { (@_ == 2) ? $_[0]->{'base_dir_abs'} = pop : $_[0]->{'base_dir_abs'} || ['.']  }
sub base_dir_rel { (@_ == 2) ? $_[0]->{'base_dir_rel'} = pop : $_[0]->{'base_dir_rel'} || ''     }
sub cgix         { (@_ == 2) ? $_[0]->{'cgix'}         = pop : $_[0]->{'cgix'}         ||= do { require CGI::Ex; CGI::Ex->new } }
sub cookies      { (@_ == 2) ? $_[0]->{'cookies'}      = pop : $_[0]->{'cookies'}      ||= $_[0]->cgix->get_cookies }
sub ext_conf     { (@_ == 2) ? $_[0]->{'ext_conf'}     = pop : $_[0]->{'ext_conf'}     || 'pl'   }
sub ext_print    { (@_ == 2) ? $_[0]->{'ext_print'}    = pop : $_[0]->{'ext_print'}    || 'html' }
sub ext_val      { (@_ == 2) ? $_[0]->{'ext_val'}      = pop : $_[0]->{'ext_val'}      || 'val'  }
sub form         { (@_ == 2) ? $_[0]->{'form'}         = pop : $_[0]->{'form'}         ||= $_[0]->cgix->get_form    }
sub load_conf    { (@_ == 2) ? $_[0]->{'load_conf'}    = pop : $_[0]->{'load_conf'}              }

sub conf {
    my $self = shift;
    $self->{'conf'} = pop if @_ == 1;
    return $self->{'conf'} ||= do {
        my $conf = $self->conf_file;
        $conf = $self->conf_obj->read($conf, {no_warn_on_fail => 1}) || ($self->conf_die_on_fail ? croak $@ : {})
            if ! ref $conf;
        my $hash = $self->conf_validation;
        if ($hash && scalar keys %$hash) {
            my $err_obj = $self->val_obj->validate($conf, $hash);
            croak "$err_obj" if $err_obj;
        }
        $conf;
    }
}

sub conf_file {
    my $self = shift;
    $self->{'conf_file'} = pop if @_ == 1;
    return $self->{'conf_file'} ||= do {
        my $module = $self->name_module || croak 'Missing name_module during conf_file call';
        $module .'.'. $self->ext_conf;
    };
}

###---------------------###
# general methods

sub add_to_base          { my $self = shift; $self->add_to_hash($self->hash_base,   @_) }
sub add_to_common        { my $self = shift; $self->add_to_hash($self->hash_common, @_) }
sub add_to_errors        { shift->add_errors(@_) }
sub add_to_fill          { my $self = shift; $self->add_to_hash($self->hash_fill,   @_) }
sub add_to_form          { my $self = shift; $self->add_to_hash($self->hash_form,   @_) }
sub add_to_path          { shift->append_path(@_) } # legacy
sub add_to_swap          { my $self = shift; $self->add_to_hash($self->hash_swap,   @_) }
sub append_path          { my $self = shift; push @{ $self->path }, @_ }
sub cleanup_user         { my ($self, $user) = @_; $user }
sub current_step         { $_[0]->step_by_path_index($_[0]->{'path_i'} || 0) }
sub destroy              {}
sub first_step           { $_[0]->step_by_path_index(0) }
sub fixup_after_morph    {}
sub fixup_before_unmorph {}
sub format_error         { my ($self, $error) = @_; $error }
sub get_pass_by_user     { croak "get_pass_by_user is a virtual method and needs to be overridden for authentication to work" }
sub has_errors           { scalar keys %{ $_[0]->hash_errors } }
sub last_step            { $_[0]->step_by_path_index($#{ $_[0]->path }) }
sub path_info_map        {}
sub post_loop            { 0 } # true value means to abort the nav_loop - don't recurse
sub post_navigate        {}
sub pre_loop             { 0 } # true value means to abort the nav_loop routine
sub pre_navigate         { 0 } # true means to not enter nav_loop
sub previous_step        { $_[0]->step_by_path_index(($_[0]->{'path_i'} || 0) - 1) }
sub valid_steps          {}
sub verify_user          { 1 }

sub add_errors {
    my $self = shift;
    my $hash = $self->hash_errors;
    my $args = ref($_[0]) ? shift : {@_};
    foreach my $key (keys %$args) {
        my $_key = ($key =~ /error$/) ? $key : "${key}_error";
        if ($hash->{$_key}) {
            $hash->{$_key} .= '<br>' . $args->{$key};
        } else {
            $hash->{$_key} = $args->{$key};
        }
    }
    $hash->{'has_errors'} = 1;
}

sub add_to_hash {
    my $self = shift;
    my $old  = shift;
    my $new  = ref($_[0]) ? shift : {@_};
    @$old{keys %$new} = values %$new;
}

sub clear_app {
    my $self = shift;
    delete @$self{qw(cgix cookies form hash_common hash_errors hash_fill hash_swap history
                     _morph_lineage _morph_lineage_start_index path path_i stash val_obj)};
    return $self;
}

sub dump_history {
    my ($self, $all) = @_;
    my $hist = $self->history;
    my $dump = [sprintf "Elapsed: %.5f", time - $self->{'_time'}];

    foreach my $row (@$hist) {
        if (! ref($row) || ref($row) ne 'HASH' || ! exists $row->{'elapsed'}) {
            push @$dump, $row;
            next;
        }
        my $note = ('    ' x ($row->{'level'} || 0))
            . join(' - ', $row->{'step'}, $row->{'meth'}, $row->{'found'}, sprintf '%.5f', $row->{'elapsed'});
        my $resp = $row->{'response'};
        if ($all) {
            $note = [$note, $resp];
        } else {
            $note .= ' - '
                .(! defined $resp                                ? 'undef'
                  : ref($resp) eq 'ARRAY' && !@$resp             ? '[]'
                  : ref($resp) eq 'HASH'  && !scalar keys %$resp ? '{}'
                  : $resp =~ /^(.{30}|.{0,30}(?=\n))(?s:.)/ ? "$1..." : $resp);
            $note .= ' - '.$row->{'info'} if defined $row->{'info'};
        }
        push @$dump, $note;
    }

    return $dump;
}

sub exit_nav_loop {
    my $self = shift;
    if (my $ref = $self->{'_morph_lineage'}) { # undo morphs
        my $index = $self->{'_morph_lineage_start_index'}; # allow for early "morphers" to only get rolled back so far
        $index = -1 if ! defined $index;
        $self->unmorph while $#$ref != $index;
    }
    die "Long Jump\n";
}

sub insert_path {
    my $self = shift;
    my $ref  = $self->path;
    my $i    = $self->{'path_i'} || 0;
    if ($i + 1 > $#$ref) { push @$ref, @_ }
    else                 { splice(@$ref, $i + 1, 0, @_) } # insert a path at the current location
}

sub jump { shift->goto_step(@_) }

sub goto_step {
    my $self   = shift;
    my $i      = @_ == 1 ? shift : 1;
    my $path   = $self->path;
    my $path_i = $self->{'path_i'} || 0;

    if (   $i eq 'FIRST'   ) { $i = - $path_i - 1 }
    elsif ($i eq 'LAST'    ) { $i = $#$path - $path_i }
    elsif ($i eq 'NEXT'    ) { $i = 1  }
    elsif ($i eq 'CURRENT' ) { $i = 0  }
    elsif ($i eq 'PREVIOUS') { $i = -1 }
    elsif ($i !~ /^-?\d+/) { # look for a step by that name in the current remaining path
        my $found;
        for (my $j = $path_i; $j < @$path; $j++) {
            if ($path->[$j] eq $i) {
                $i = $j - $path_i;
                $found = 1;
                last;
            }
        }
        if (! $found) {
            $self->replace_path($i);
            $i = $#$path;
        }
    }
    croak "Invalid jump index ($i)" if $i !~ /^-?\d+$/;

    my $cut_i   = $path_i + $i; # manipulate the path to contain the new jump location
    my @replace = ($cut_i > $#$path) ? $self->default_step
                : ($cut_i < 0)       ? @$path
                :                      @$path[$cut_i .. $#$path];
    $self->replace_path(@replace);

    $self->{'jumps'} = ($self->{'jumps'} || 0) + 1;
    $self->{'path_i'}++; # move along now that the path is updated

    my $lin  = $self->{'_morph_lineage'} || [];
    $self->unmorph if @$lin;
    $self->nav_loop;  # recurse on the path
    $self->exit_nav_loop;
}

sub js_uri_path {
    my $self   = shift;
    my $script = $self->script_name;
    my $js_step = $self->js_step;
    return ($self->can('path') == \&CGI::Ex::App::path
            && $self->can('path_info_map_base') == \&CGI::Ex::App::path_info_map_base)
        ? $script .'/'. $js_step # try to use a cache friendly URI (if path is our own)
        : $script .'?'. $self->step_key .'='. $js_step .'&js='; # use one that works with more paths
}


sub morph {
    my $self  = shift;
    my $ref   = $self->history->[-1];
    if (! $ref || ! $ref->{'meth'} || $ref->{'meth'} ne 'morph') {
        push @{ $self->history }, ($ref = {meth => 'morph', found => 'morph', elapsed => 0, step => 'unknown', level => $self->{'_level'}});
    }
    my $step  = shift || return;
    my $allow = shift || $self->run_hook('allow_morph', $step) || return;
    my $new   = shift; # optionally allow passing in the package to morph to
    my $lin   = $self->{'_morph_lineage'} ||= [];
    my $ok    = 0;
    my $cur   = ref $self;

    push @$lin, $cur; # store so subsequent unmorph calls can do the right thing

    # hash - but no step - record for unbless
    if (ref($allow) && ! ($allow = $allow->{$step})) {
        $ref->{'info'} = "not allowed to morph to that step";

    } elsif (! ($new ||= $self->run_hook('morph_package', $step))) {
        $ref->{'info'} = "Missing morph_package for step $step";

    } elsif ($cur eq $new) {
        $ref->{'info'} = "already isa $new";
        $ok = 1;

    ### if we are not already that package - bless us there
    } else {
        (my $file = "$new.pm") =~ s|::|/|g;
        if (UNIVERSAL::can($new, 'fixup_after_morph')  # check if the package space exists
            || (eval { require $file }                 # check for a file that holds this package
                && UNIVERSAL::can($new, 'fixup_after_morph'))) {
            bless $self, $new;                         # become that package
            $self->fixup_after_morph($step);
            $ref->{'info'} = "changed $cur to $new";
        } elsif ($@) {
            if ($allow eq '1' && $@ =~ /^\s*(Can\'t locate \S+ in \@INC)/) { # let us know what happened
                $ref->{'info'} = "failed from $cur to $new: $1";
            } else {
                $ref->{'info'} = "failed from $cur to $new: $@";
                die "Trouble while morphing from $cur to $new: $@";
            }
        } elsif ($allow ne '1') {
            $ref->{'info'} = "package $new doesn't support CGI::Ex::App API";
            die "Found package $new, but $new does not support CGI::Ex::App API";
        }
        $ok = 1;
    }

    return $ok;
}

sub replace_path {
    my $self = shift;
    my $ref  = $self->path;
    my $i    = $self->{'path_i'} || 0;
    if ($i + 1 > $#$ref) { push @$ref, @_; }
    else { splice(@$ref, $i + 1, $#$ref - $i, @_); } # replace remaining entries
}

sub set_path {
    my $self = shift;
    my $path = $self->{'path'} ||= [];
    croak "Cannot call set_path after the navigation loop has begun" if $self->{'path_i'};
    splice @$path, 0, $#$path + 1, @_; # change entries in the ref (which updates other copies of the ref)
}

sub step_by_path_index {
    my $self = shift;
    my $i    = shift || 0;
    my $ref  = $self->path;
    return '' if $i < 0;
    return $ref->[$i];
}

sub unmorph {
    my $self = shift;
    my $step = shift || '_no_step';
    my $ref  = $self->history->[-1] || {};
    if (! $ref || ! $ref->{'meth'} || $ref->{'meth'} ne 'unmorph') {
        push @{ $self->history }, ($ref = {meth => 'unmorph', found => 'unmorph', elapsed => 0, step => $step, level => $self->{'_level'}});
    }
    my $lin  = $self->{'_morph_lineage'} || return;
    my $cur  = ref $self;
    my $prev = pop(@$lin) || croak "unmorph called more times than morph (current: $cur)";
    delete $self->{'_morph_lineage'} if ! @$lin;

    if ($cur ne $prev) {
        $self->fixup_before_unmorph($step);
        bless $self, $prev;
        $ref->{'info'} = "changed from $cur to $prev";
    } else {
        $ref->{'info'} = "already isa $cur";
    }

    return 1;
}

###---------------------###
# hooks

sub file_print {
    my ($self, $step) = @_;
    my $base_dir = $self->base_dir_rel;
    my $module   = $self->run_hook('name_module', $step);
    my $_step    = $self->run_hook('name_step', $step) || croak "Missing name_step";
    $_step =~ s|\B__+|/|g;
    $_step .= '.'. $self->ext_print if $_step !~ /\.\w+$/;
    foreach ($base_dir, $module) { $_ .= '/' if length($_) && ! m|/$| }
    return $base_dir . $module . $_step;
}

sub file_val {
    my ($self, $step) = @_;

    my $abs = $self->val_path || [];
    $abs = $abs->() if UNIVERSAL::isa($abs, 'CODE');
    $abs = [$abs] if ! UNIVERSAL::isa($abs, 'ARRAY');
    return {} if @$abs == 0;

    my $base_dir = $self->base_dir_rel;
    my $module   = $self->run_hook('name_module', $step);
    my $_step    = $self->run_hook('name_step', $step) || croak "Missing name_step";
    $_step =~ s|\B__+|/|g;
    $_step =~ s/\.\w+$//;
    $_step .= '.'. $self->ext_val;

    foreach (@$abs, $base_dir, $module) { $_ .= '/' if length($_) && ! m|/$| }

    if (@$abs > 1) {
        foreach my $_abs (@$abs) {
            my $path = "$_abs/$base_dir/$module/$_step";
            return $path if -e $path;
        }
    }
    return $abs->[0] . $base_dir . $module . $_step;
}

sub fill_template {
    my ($self, $step, $outref, $fill) = @_;
    return if ! $fill || ! scalar keys %$fill;
    my $args = $self->run_hook('fill_args', $step) || {};
    local @$args{'text', 'form'} = ($outref, $fill);
    require CGI::Ex::Fill;
    CGI::Ex::Fill::fill($args);
}

sub finalize  { 1 } # false means show step

sub hash_base {
    my ($self, $step) = @_;
    my $hash = $self->{'hash_base'} ||= {
        script_name => $self->script_name,
        path_info   => $self->path_info,
    };

    my $copy = $self;  eval { require Scalar::Util; Scalar::Util::weaken($copy) };
    $hash->{'js_validation'} = sub { $copy->run_hook('js_validation', $step, shift) };
    $hash->{'generate_form'} = sub { $copy->run_hook('generate_form', $step, (ref($_[0]) ? (undef, shift) : shift)) };
    $hash->{'form_name'}     = $self->run_hook('form_name', $step);
    $hash->{$self->step_key} = $step;
    return $hash;
}

sub hash_common { $_[0]->{'hash_common'} ||= {} }
sub hash_errors { $_[0]->{'hash_errors'} ||= {} }
sub hash_fill   { $_[0]->{'hash_fill'}   ||= {} }
sub hash_form   { $_[0]->form }
sub hash_swap   { $_[0]->{'hash_swap'}   ||= {} }

sub hash_validation {
  my ($self, $step) = @_;
  return $self->{'hash_validation'}->{$step} ||= do {
      my $file = $self->run_hook('file_val', $step);
      $file ? $self->val_obj->get_validation($file) : {}; # if the file is not found, errors will be in the webserver logs (all else dies)
  };
}

sub info_complete {
    my ($self, $step) = @_;
    return 0 if ! $self->run_hook('ready_validate', $step);
    return $self->run_hook('validate', $step, $self->form) ? 1 : 0;
}

sub js_validation {
    my ($self, $step) = @_;
    my $form_name = $_[2] || $self->run_hook('form_name', $step);
    my $hash_val  = $_[3] || $self->run_hook('hash_validation', $step);
    return '' if ! $form_name || ! ref($hash_val) || ! scalar keys %$hash_val;
    return $self->val_obj->generate_js($hash_val, $form_name, $self->js_uri_path);
}

sub generate_form {
    my ($self, $step) = @_;
    my $form_name = $_[2] || $self->run_hook('form_name', $step);
    my $args      = ref($_[3]) eq 'HASH' ? $_[3] : {};
    my $hash_val  = $self->run_hook('hash_validation', $step);
    return '' if ! $form_name || ! ref($hash_val) || ! scalar keys %$hash_val;
    local $args->{'js_uri_path'} = $self->js_uri_path;
    return $self->val_obj->generate_form($hash_val, $form_name, $args);
}

sub morph_base { my $self = shift; ref($self) }
sub morph_package {
    my ($self, $step) = @_;
    my $cur = $self->morph_base; # default to using self as the base for morphed modules
    my $new = ($cur ? $cur .'::' : '') . ($step || croak "Missing step");
    $new =~ s/\B__+/::/g; # turn Foo::my_nested__step info Foo::my_nested::step
    $new =~ s/(?:_+|\b)(\w)/\u$1/g; # turn Foo::my_step_name into Foo::MyStepName
    return $new;
}

sub name_module {
    my ($self, $step) = @_;
    return $self->{'name_module'} ||= ($self->script_name =~ m/ (\w+) (?:\.\w+)? $/x)
        ? $1 : die "Could not determine module name from \"name_module\" lookup (".($step||'').")\n";
}

sub name_step  { my ($self, $step) = @_; $step }
sub next_step  { $_[0]->step_by_path_index(($_[0]->{'path_i'} || 0) + 1) }
sub post_print { 0 }
sub post_step  { 0 } # true indicates we handled step (exit loop)
sub pre_step   { 0 } # true indicates we handled step (exit loop)
sub prepare    { 1 } # false means show step

sub print_out {
    my ($self, $step, $out) = @_;
    $self->cgix->print_content_type($self->run_hook('mimetype', $step), $self->run_hook('charset', $step));
    print ref($out) eq 'SCALAR' ? $$out : $out;
}

sub ready_validate {
    my ($self, $step) = @_;
    if ($self->run_hook('validate_when_data', $step)
        and my @keys = keys %{ $self->run_hook('hash_validation', $step) || {} }) {
        my $form = $self->form;
        return (grep { exists $form->{$_} } @keys) ? 1 : 0;
    }
    return ($ENV{'REQUEST_METHOD'} && $ENV{'REQUEST_METHOD'} eq 'POST') ? 1 : 0;
}

sub refine_path {
    my ($self, $step, $is_at_end) = @_;
    return 0 if ! $is_at_end; # if we are not at the end of the path, do not do anything
    my $next_step = $self->run_hook('next_step', $step) || return 0;
    $self->run_hook('set_ready_validate', $step, 0);
    $self->append_path($next_step);
    return 1;
}

sub set_ready_validate {
    my $self = shift;
    my ($step, $is_ready) = (@_ == 2) ? @_ : (undef, shift); # hook and method
    $ENV{'REQUEST_METHOD'} = ($is_ready) ? 'POST' : 'GET';
    return $is_ready;
}

sub skip { 0 } # success indicates to skip the step (and continue loop)

sub swap_template {
    my ($self, $step, $file, $swap) = @_;
    my $t = $self->__template_obj($step);
    my $out = '';
    $t->process($file, $swap, \$out) || die $t->error;
    return $out;
}

sub __template_obj {
    my ($self, $step) = @_;
    my $args = $self->run_hook('template_args', $step) || {};
    $args->{'INCLUDE_PATH'} ||= $args->{'include_path'} || $self->template_path;
    return $self->template_obj($args);
}

sub validate {
    my ($self, $step, $form) = @_;
    my $hash = $self->__hash_validation($step);
    return 1 if ! ref($hash) || ! scalar keys %$hash;

    my @validated_fields;
    if (my $err_obj = eval { $self->val_obj->validate($form, $hash, \@validated_fields) }) {
        $self->add_errors($err_obj->as_hash({as_hash_join => "<br>\n", as_hash_suffix => '_error'}));
        return 0;
    }
    die "Step $step: $@" if $@;

    foreach my $ref (@validated_fields) { # allow for the validation to give us some redirection
        $self->append_path( ref $_ ? @$_ : $_) if $_ = $ref->{'append_path'};
        $self->replace_path(ref $_ ? @$_ : $_) if $_ = $ref->{'replace_path'};
        $self->insert_path( ref $_ ? @$_ : $_) if $_ = $ref->{'insert_path'};
    }

    return 1;
}

sub __hash_validation { shift->run_hook('hash_validation', @_) }

sub validate_when_data { $_[0]->{'validate_when_data'} }

###---------------------###
# authentication

sub navigate_authenticated {
    my ($self, $args) = @_;
    $self = $self->new($args) if ! ref $self;
    croak "Cannot call navigate_authenticated method if default require_auth method is overwritten"
        if $self->can('require_auth') != \&CGI::Ex::App::require_auth;
    $self->require_auth(1);
    return $self->navigate;
}

sub require_auth {
    my $self = shift;
    $self->{'require_auth'} = shift if @_ == 1 && (! defined($_[0]) || ref($_[0]) || $_[0] =~ /^[01]$/);
    return $self->{'require_auth'} || 0;
}

sub is_authed { my $data = shift->auth_data; $data && ! $data->{'error'} }

sub check_valid_auth { shift->_do_auth({login_print => sub {}, location_bounce => sub {}}) }

sub get_valid_auth {
    my $self = shift;
    return $self->_do_auth({
        login_print => sub { # use CGI::Ex::Auth - but use our formatting and printing
            my ($auth, $template, $hash) = @_;
            local $self->{'__login_file_print'}  = $template;
            local $self->{'__login_hash_common'} = $hash;
            return $self->goto_step($self->login_step);
        }
    });
}

sub _do_auth {
    my ($self, $extra) = @_;
    return $self->auth_data if $self->is_authed;
    my $args = { %{ $self->auth_args || {} }, %{ $extra || {} } };
    $args->{'script_name'}      ||= $self->script_name;
    $args->{'path_info'}        ||= $self->path_info;
    $args->{'cgix'}             ||= $self->cgix;
    $args->{'form'}             ||= $self->form;
    $args->{'cookies'}          ||= $self->cookies;
    $args->{'js_uri_path'}      ||= $self->js_uri_path;
    $args->{'get_pass_by_user'} ||= sub { my ($auth, $user) = @_; $self->get_pass_by_user($user, $auth) };
    $args->{'verify_user'}      ||= sub { my ($auth, $user) = @_; $self->verify_user(     $user, $auth) };
    $args->{'cleanup_user'}     ||= sub { my ($auth, $user) = @_; $self->cleanup_user(    $user, $auth) };

    my $obj  = $self->auth_obj($args);
    my $resp = $obj->get_valid_auth;
    my $data = $obj->last_auth_data;
    delete $data->{'real_pass'} if defined $data; # data may be defined but false
    $self->auth_data($data); # failed authentication may still have auth_data
    return ($resp && $data) ? $data : undef;
}

###---------------------###
# default steps

sub js_require_auth { 0 }
sub js_run_step { # step that allows for printing javascript libraries that are stored in perls @INC.
    my $self = shift;
    my $path = $self->form->{'js'} || $self->path_info;
    $self->cgix->print_js($path =~ m!^(?:/js/|/)?(\w+(?:/\w+)*\.js)$! ? $1 : '');
    $self->{'_no_post_navigate'} = 1;
    return 1;
}

sub __forbidden_require_auth { 0 }
sub __forbidden_allow_morph { shift->allow_morph(@_) && 1 }
sub __forbidden_info_complete { 0 } # step that will be used the path method determines it is forbidden
sub __forbidden_hash_common  { shift->stash }
sub __forbidden_file_print { \ "<h1>Denied</h1>You do not have access to the step <b>\"[% forbidden_step.html %]\"</b>" }

sub __error_allow_morph { shift->allow_morph(@_) && 1 }
sub __error_info_complete { 0 } # step that is used by the default handle_error
sub __error_hash_common  { shift->stash }
sub __error_file_print { \ "<h1>A fatal error occurred</h1>Step: <b>\"[% error_step.html %]\"</b><br>[% TRY; CONFIG DUMP => {header => 0}; DUMP error; END %]" }

sub __login_require_auth { 0 }
sub __login_allow_morph { shift->allow_morph(@_) && 1 }
sub __login_info_complete { 0 } # step used by default authentication
sub __login_hash_common { shift->{'__login_hash_common'} || {error => "hash_common not set during default __login"} }
sub __login_file_print { shift->{'__login_file_print'} || \ "file_print not set during default __login<br>[% login_error %]" }

1; # Full documentation resides in CGI/Ex/App.pod
