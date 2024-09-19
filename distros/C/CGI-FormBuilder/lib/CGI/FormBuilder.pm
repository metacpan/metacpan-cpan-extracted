
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# Note: Documentation has grown so massive it is now in FormBuilder.pod

package CGI::FormBuilder;

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';
use Scalar::Util qw(weaken);

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use CGI::FormBuilder::Messages;

our $VERSION = '3.20';

our $AUTOLOAD;

# Default options for FormBuilder
our %DEFAULT = (
    sticky     => 1,
    method     => 'get',
    submit     => 1,
    reset      => 0,
    header     => 0,
    body       => { },
    text       => '',
    table      => { },
    tr         => { },
    th         => { },
    td         => { },
    div        => { },
    jsname     => 'validate',
    jsprefix   => 'fb_',              # prefix for JS tags
    sessionidname => '_sessionid',
    submittedname => '_submitted',
    pagename   => '_page',
    template   => '',                 # default template
    debug      => 0,                  # can be 1 or 2
    javascript => 'auto',             # 0, 1, or 'auto'
    cookies    => 1,
    cleanopts  => 1,
    render     => 'render',           # render sub name
    smartness  => 1,                  # can be 1 or 2
    selectname => 1,                  # include -select-?
    selectnum  => 5,
    stylesheet => 0,                  # use stylesheet stuff?
    styleclass => 'fb',               # style class to use
    # For translating tag names (experimental)
    tagnames   => { },
    # I don't see any reason why these are variables
    formname   => '_form',
    submitname => '_submit',
    resetname  => '_reset',
    bodyname   => '_body',
    tabname    => '_tab',
    rowname    => '_row',
    labelname  => '_label',
    fieldname  => '_field',           # equiv of <tmpl_var field-tag>
    buttonname => '_button',
    errorname  => '_error',
    othername  => '_other',
    growname   => '_grow',
    statename  => '_state',
    extraname  => '_extra',
    dtd        => <<'EOD',            # modified from CGI.pm
<?xml version="1.0" encoding="{charset}"?>
<!DOCTYPE html
        PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="{lang}" xml:lang="{lang}">
EOD
);

# Which options to rearrange from new() into field()
our %REARRANGE = qw(
    options     options
    optgroups   optgroups
    labels      label
    validate    validate
    required    required
    selectname  selectname
    selectnum   selectnum
    sortopts    sortopts
    nameopts    nameopts
    cleanopts   cleanopts
    sticky      sticky
    disabled    disabled
    columns     columns
);

*redo = \&new;
sub new {
    local $^W = 0;      # -w sucks
    my $self = shift;

    # A single arg is a source; others are opt => val pairs
    my %opt;
    if (@_ == 1) {
        %opt = UNIVERSAL::isa($_[0], 'HASH')
             ? %{ $_[0] }
             : ( source => shift() );
    } else {
        %opt = arghash(@_);
    }

    # Pre-check for an external source
    if (my $src = delete $opt{source}) {

        # check for engine type
        my $mod;
        my $sopt;     # opts returned from parsing
        my $ref = ref $src;
        unless ($ref) {
            # string filename; redo format (ala $self->{template})
            $src = {
                type   => 'File',
                source => $src,
                # pass catalyst class for \&validate refs
                ($opt{c} && $opt{c}->action)
                    ? (caller => $opt{c}->action->class) : ()
            };
            $ref = 'HASH';  # tricky
            debug 2, "rewrote 'source' option since found filename";
        }
        debug 1, "creating form from source ", $ref || $src;

        if ($ref eq 'HASH') {
            # grab module
            $mod = delete $src->{type} || 'File';

            # user can give 'Their::Complete::Module' or an 'IncludedTemplate'
            $mod = join '::', __PACKAGE__, 'Source', $mod unless $mod =~ /::/;
            debug 1, "loading $mod for 'source' option";

            eval "require $mod";
            puke "Bad source module $mod: $@" if $@;

            my $sob  = $mod->new(%$src);
            $sopt = $sob->parse;
        } elsif ($ref eq 'CODE') {
            # subroutine wrapper
            $sopt = &{$src->{source}}($self);
        } elsif (UNIVERSAL::can($src->{source}, 'parse')) {
            # instantiated object
            $sopt = $src->{source}->parse($self);
        } elsif ($ref) {
            puke "Unsupported operand to 'template' option - must be \\%hash, \\&sub, or \$object w/ parse()";
        }

        # per-instance variables win
        while (my($k,$v) = each %$sopt) {
            $opt{$k} = $v unless exists $opt{$k};
        }
    }

    if (ref $self) {
        # cloned/original object
        debug 1, "rewriting existing FormBuilder object";
        while (my($k,$v) = each %opt) {
            $self->{$k} = $v;
        }
    } else {
        debug 1, "constructing new FormBuilder object";
        # damn deep copy this is SO damn annoying
        while (my($k,$v) = each %DEFAULT) {
            next if exists $opt{$k};
            if (ref $v eq 'HASH') {
                $opt{$k} = { %$v };
            } elsif (ref $v eq 'ARRAY') {
                $opt{$k} = [ @$v ];
            } else {
                $opt{$k} = $v;
            }
        }
        $self = bless \%opt, $self;
    }

    # Create our CGI object if not present
    unless (ref $self->{params}) {
        require CGI;
        $CGI::USE_PARAM_SEMICOLONS = 0;     # fuck ; in urls
        $self->{params} = CGI->new($self->{params});
    }

    # XXX not mod_perl safe
    $CGI::FormBuilder::Util::DEBUG = $ENV{FORMBUILDER_DEBUG} || $self->{debug};

    # And a messages delegate if not existent
    # Handle 'auto' mode by trying to detect from request
    # Can't do this in ::Messages because it has no CGI knowledge
    if (lc($self->{messages}) eq 'auto') {
        my $lang = $self->{messages};
        # figure out the messages from our params object
        if (UNIVERSAL::isa($self->{params}, 'CGI')) {
            $lang = $self->{params}->http('Accept-Language');
        } elsif (UNIVERSAL::isa($self->{params}, 'Apache')) {
            $lang = $self->{params}->headers_in->get('Accept-Language'); 
        } elsif (UNIVERSAL::isa($self->{params}, 'Catalyst::Request')) {
            $lang = $self->{params}->headers->header('Accept-Language'); 
        } else {
            # last-ditch effort
            $lang = $ENV{HTTP_ACCEPT_LANGUAGE}
                 || $ENV{LC_MESSAGES} || $ENV{LC_ALL} || $ENV{LANG};
        }
        $lang ||= 'default';
        $self->{messages} = CGI::FormBuilder::Messages->new(":$lang");
    } else {
        # ref or filename (::Messages will decode)
        $self->{messages} = CGI::FormBuilder::Messages->new($self->{messages});
    }

    # Initialize form fields (probably a good idea)
    if ($self->{fields}) {
        debug 1, "creating fields list";

        # check to see if 'fields' is a hash or array ref
        my $ref = ref $self->{fields};
        if ($ref && $ref eq 'HASH') {
            # with a hash ref, we setup keys/values
            debug 2, "got fields list from HASH";
            while(my($k,$v) = each %{$self->{fields}}) {
                $k = lc $k;     # must lc to ignore case
                $self->{values}{$k} = [ autodata $v ];
            }
            # reset main fields to field names
            $self->{fields} = [ sort keys %{$self->{fields}} ];
        } else {
            # rewrite fields to ensure format
            debug 2, "assuming fields list from ARRAY";
            $self->{fields} = [ autodata $self->{fields} ];
        }
    }

    if (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        debug 2, "got a Data::FormValidator for validate";
        # we're being a bit naughty and peeking inside the DFV object
        $self->{required} = $self->{validate}{profiles}{fb}{required};
    } else {
        # Catch the intersection of required and validate
        if (ref $self->{required}) {
            # ok, will handle itself automatically below
        } elsif ($self->{required}) {
            # catches for required => 'ALL'|'NONE'
            if ($self->{required} eq 'NONE') {
                delete $self->{required};   # that's it
            }
            elsif ($self->{required} eq 'ALL') {
                $self->{required} = [ @{$self->{fields}} ];
            }
            elsif ($self->{required}) {
                # required => 'single_field' catch
                $self->{required} = { $self->{required} => 1 };
            }
        } elsif ($self->{validate}) {
            # construct a required list of all validated fields
            $self->{required} = [ keys %{$self->{validate}} ];
        }
    }

    # Now, new for the 3.x series, we cycle thru the fields list and
    # replace it with a list of objects, which stringify to field names
    my @ftmp  = ();
    for (@{$self->{fields}}) {
        my %fprop = %{$self->{fieldopts}{$_} || {}}; # field properties

        if (ref $_ =~ /^CGI::FormBuilder::Field/i) {
            # is an existing Field object, so update its properties
            $_->field(%fprop);
        } else {
            # init a new one
            $fprop{name} = "$_";
            $_ = $self->new_field(%fprop);
            weaken($_->{_form});
        }
        debug 2, "push \@(@ftmp), $_";
        weaken($self->{fieldrefs}{"$_"} = $_);
        push @ftmp, $_;
    }

    # stringifiable objects (overwrite previous container)
    $self->{fields} = \@ftmp;

    # setup values
    $self->values($self->{values}) if $self->{values};

    debug 1, "field creation done, list = (@ftmp)";

    return $self;
}

*param  = \&field;
*params = \&field;
*fields = \&field;
sub field {
    local $^W = 0;      # -w sucks
    my $self = shift;
    debug 2, "called \$form->field(@_)";

    # Handle any of:
    #
    #   $form->field($name)
    #   $form->field(name => $name, arg => 'val')
    #   $form->field(\@newlist);
    #

    return $self->new(fields => $_[0])
        if ref $_[0] eq 'ARRAY' && @_ == 1;

    my $name = (@_ % 2 == 0) ? '' : shift();
    my $args = arghash(@_);
    $args->{name} ||= $name;

    # no name - return ala $cgi->param
    unless ($args->{name}) {
        # sub fields
        # return an array of the names in list context, and a
        # hashref of name/value pairs in a scalar context
        if (wantarray) {
            # pre-scan for any "order" arguments, reorder, delete
            for my $redo (grep { $_->order } @{$self->{fields}}) {
                next if $redo->order eq 'auto';   # like javascript
                # kill existing order
                for (my $i=0; $i < @{$self->{fields}}; $i++) {
                    if ($self->{fields}[$i] eq $redo) {
                        debug 2, "reorder: removed $redo from \$fields->[$i]";
                        splice(@{$self->{fields}}, $i, 1);
                    }
                }
                # put it in its new place
                debug 2, "reorder: moving $redo to $redo->{order}";
                if ($redo->order <= 1) {
                    # start
                    unshift @{$self->{fields}}, $redo;
                } elsif ($redo->order >= @{$self->{fields}}) {
                    # end
                    push @{$self->{fields}}, $redo;
                } else {
                    # middle
                    splice(@{$self->{fields}}, $redo->order - 1, 0, $redo);
                }
                # kill subsequent reorders (unnecessary)
                delete $redo->{order};
            }

            # list of all field objects
            debug 2, "return (@{$self->{fields}})";
            return @{$self->{fields}};
        } else {
            # this only returns a single scalar value for each field
            return { map { $_ => scalar($_->value) } @{$self->{fields}} };
        }
    }

    # have name, so redispatch to field member
    debug 2, "searching fields for '$args->{name}'";
    if ($args->{delete}) {
        # blow the thing away
        delete $self->{fieldrefs}{$args->{name}};
        my @tf = grep { $_->name ne $args->{name} } @{$self->{fields}};
        $self->{fields} = \@tf;
        return;
    } elsif (my $f = $self->{fieldrefs}{$args->{name}}) {
        delete $args->{name};        # segfault??
        return $f->field(%$args);    # set args, get value back
    }

    # non-existent field, and no args, so assume we're checking for it
    return unless keys %$args > 1;

    # if we're still in here, we need to init a new field
    # push it onto our mail fields array, just like initfields()
    my $f = $self->new_field(%$args);
    weaken($self->{fieldrefs}{"$f"} = $f);
    weaken($f->{_form});
    weaken($f->{fieldrefs}{"$f"});
    push @{$self->{fields}}, $f;
    
    return $f->value;
}

sub new_field {
    my $self = shift;
    my $args = arghash(@_);
    puke "Need a name for \$form->new_field()" unless exists $args->{name};
    debug 1, "called \$form->new_field($args->{name})";

    # extract our per-field options from rearrange
    while (my($from,$to) = each %REARRANGE) {
        next unless exists  $self->{$from};
        next if     defined $args->{$to};     # manually set
        my $tval = rearrange($self->{$from}, $args->{name});
        debug 2, "rearrange: \$args->{$to} = $tval;";
        $args->{$to} = $tval;
    }

    $args->{type} = lc $self->{fieldtype}
        if $self->{fieldtype} && ! exists $args->{type};
    if ($self->{fieldattr}) {   # legacy
        while (my($k,$v) = each %{$self->{fieldattr}}) {
            next if exists $args->{$k};
            $args->{$k} = $v;
        }
    }
    
    my $f = CGI::FormBuilder::Field->new($self, $args);
    debug 1, "created field $f";
    return $f;   # already set args above ^^^
}

*fieldset = \&fieldsets;
sub fieldsets {
    my $self = shift;
    if (@_) {
        if (ref($_[0]) eq 'ARRAY') {
            $self->{fieldsets} = shift;
        } elsif (@_ % 2) {
            # search for fieldset and update it, or add it
            # can't use optalign because must change in-place
            while (@_) {
                my($k,$v) = (shift,shift);
                for (@{$self->{fieldsets}||=[]}) {
                    if ($k eq $_->[0]) {
                        $_->[1] = $v;
                        undef $k;   # catch below
                    }
                }
                # not found, so append
                if ($k) {
                    push @{$self->{fieldsets}}, [$k,$v];
                }
            }
        } else {
            puke "Invalid usage of \$form->fieldsets(name => 'Label')"
        }
    }

    # We look for all the fieldset definitions, checking the main
    # form for a "proper" legend ala our other settings. We then
    # divide up all the fields and group them in fieldsets.
    my(%legends, @sets);
    for (optalign($self->{fieldsets})) {
        my($o,$n) = optval($_);
        next if exists $legends{$o};
        push @sets, $o;
        debug 2, "added fieldset $o (legend=$n) to \@sets";
        $legends{$o} = $n;
    }

    # find *all* our fieldsets, even hidden in fields w/o Human Tags
    for ($self->field) {
        next unless my $o = $_->fieldset;
        next if exists $legends{$o};
        push @sets, $o;
        debug 2, "added fieldset $o (legend=undef) to \@sets";
        $legends{$o} = $o;  # use fieldset as <legend>
    }
    return wantarray ? @sets : \%legends;
}

sub fieldlist {
    my $self = shift;
    my @fields = @_ ? @_ : $self->field;
    my(%saw, @ret);
    for my $set ($self->fieldsets) {
        # reorder fields
        for (@fields) {
            next if $saw{$_};
            if ($_->fieldset && $_->fieldset eq $set) {
                # if this field is in this fieldset, regroup
                push @ret, $_;
                debug 2, "added field $_ to field order (fieldset=$set)";
                $saw{$_} = 1;
            }
        }
    }

    # keep non-fieldset fields in order relative
    # to one another, appending them to the end
    # of the form
    for (@fields) {
        debug 2, "appended non-fieldset field $_ to form";
        push @ret, $_ unless $saw{$_};
    }

    return wantarray ? @ret : \@ret;
}

sub header {
    my $self = shift;
    $self->{header} = shift if @_;
    return unless $self->{header};
    my %head;
    if ($self->{cookies} && defined(my $sid = $self->sessionid)) {
        require CGI::Cookie;
        $head{'-cookie'} = CGI::Cookie->new(-name  => $self->{sessionidname},
                                            -value => $sid);
    }
    # Set the charset for i18n
    $head{'-charset'} = $self->charset;

    # Forcibly require - no extra time in normal case, and if 
    # using Apache::Request this needs to be loaded anyways.
    return "Content-type: text/html\n\n" if $::TESTING;
    require CGI;
    return  CGI::header(%head);    # CGI.pm MOD_PERL fanciness
}

sub charset {
    my $self = shift;
    $self->{charset} = shift if @_;
    return $self->{charset} || $self->{messages}->charset || 'iso8859-1';
}

sub lang {
    my $self = shift;
    $self->{lang} = shift if @_;
    return $self->{lang} || $self->{messages}->lang || 'en_US';
}

sub dtd {
    my $self = shift;
    $self->{dtd} = shift if @_;
    return '<html>' if $::TESTING;

    # replace special chars in dtd by exec'ing subs
    my $dtd = $self->{dtd};
    $dtd =~ s/\{(\w+)\}/$self->$1/ge;
    return $dtd;
}

sub title {
    my $self = shift;
    $self->{title} = shift if @_;
    return $self->{title} if exists $self->{title};
    return toname(basename);
}

*script_name = \&action;
sub action {
    local $^W = 0;  # -w sucks (still)
    my $self = shift;
    $self->{action} = shift if @_;
    return $self->{action} if exists $self->{action};
    return basename . $ENV{PATH_INFO};
}

sub font {
    my $self = shift;
    $self->{font} = shift if @_;
    return '' unless $self->{font};
    return '' if $self->{stylesheet};   # kill fonts for style

    # Catch for allowable hashref or string
    my $ret;
    my $ref = ref $self->{font} || '';
    if (! $ref) {
        # string "arial,helvetica"
        $ret = { face => $self->{font} };
    } elsif ($ref eq 'ARRAY') {
        # hack for array [arial,helvetica] from conf
        $ret = { face => join ',', @{$self->{font}} };
    } else {
        $ret = $self->{font};
    }
    return wantarray ? %$ret : htmltag('font', %$ret);
}

*tag = \&start;
sub start {
    my $self = shift;
    my %attr = htmlattr('form', %$self);

    $attr{action} ||= $self->action;
    $attr{method} ||= $self->method;
    $attr{method} = lc($attr{method});  # xhtml
    $self->disabled ? $attr{disabled} = 'disabled' : delete $attr{disabled};
    $attr{class}  ||= $self->class($self->formname);

    # Bleech, there's no better way to do this...?
    belch "You should really call \$form->script BEFORE \$form->start"
        unless $self->{_didscript};

    # A catch for lowercase actions
    belch "Old-style 'onSubmit' action found - should be 'onsubmit'"
        if $attr{onSubmit};

    return $self->version . htmltag('form', %attr);
}

sub end {
    return '</form>';
}

# Need to wrap this or else AUTOLOAD whines (OURATTR missing)
sub disabled {
    my $self = shift;
    $self->{disabled} = shift if @_;
    return $self->{disabled} ? 'disabled' : undef;
}
 
sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    $self->{body}{bgcolor} ||= 'white' unless $self->{stylesheet};
    return htmltag('body', $self->{body});
}

sub class {
    my $self = shift;
    return undef unless $self->{stylesheet};
    return join '', $self->{styleclass}, @_;   # remainder is optional tag 
}

sub idname {
    my $self = shift;
    $self->{id} = $self->{name}
        unless defined $self->{id};
    return undef unless $self->{id};
    return join '', $self->{id}, @_;   # remainder is optional tag 
}

sub table {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{table} = shift if @_ == 1;
    return unless $self->{table};

    # set defaults for numeric table => 1
    $self->{table} = $DEFAULT{table} if $self->{table} == 1;

    my $attr = $self->{table};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    return unless $self->{table};   # 0 or unset via table(0)
    $attr->{class} ||= $self->class;
    return htmltag('table',  $attr);
}

sub tr {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{tr} = shift if @_ == 1 && UNIVERSAL::isa($_[0], 'HASH');

    my $attr = $self->{tr};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # reduced formatting
    if ($self->{stylesheet}) {
        # extraneous - inherits from <table>
        #$attr->{class}  ||= $self->class($self->{rowname});
    } else {
        $attr->{valign} ||= 'top';
    }

    return htmltag('tr',  $attr);
}

sub th {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{th} = shift if @_ == 1 && UNIVERSAL::isa($_[0], 'HASH');

    my $attr = $self->{th};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # reduced formatting
    if ($self->{stylesheet}) {
        # extraneous - inherits from <table>
        #$attr->{class} ||= $self->class($self->{labelname});
    } else {
        $attr->{align} ||= $self->{lalign} || 'left';
    }

    return htmltag('th', $attr);
}

sub td {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{td} = shift if @_ == 1 && UNIVERSAL::isa($_[0], 'HASH');

    my $attr = $self->{td};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # extraneous - inherits from <table>
    #$attr->{class} ||= $self->class($self->{fieldname});

    return htmltag('td', $attr);
}

sub div {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{div} = shift if @_ == 1 && UNIVERSAL::isa($_[0], 'HASH');

    my $attr = $self->{div};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    return htmltag('div', $attr);
}

sub submitted {
    my $self = shift;
    my $smnam = shift || $self->submittedname;  # temp smnam
    my $smtag = $self->{name} ? "${smnam}_$self->{name}" : $smnam;

    if ($self->{params}->param($smtag)) {
        # If we've been submitted, then we return the value of
        # the submit tag (which allows multiple submission buttons).
        # Must use an "|| 0E0" or else hitting "Enter" won't cause
        # $form->submitted to be true (as the button is only sent
        # across CGI when clicked).
        my $sr = $self->{params}->param($self->submitname) || '0E0';
        debug 2, "\$form->submitted() is true, returning $sr";
        return $sr;
    }
    return 0;
}

# This creates a modified self_url, just including fields (no sessionid, etc)
sub query_string {
    my $self = shift;
    my @qstr = ();
    for my $f ($self->fields, $self->keepextras) {
        # get all values, but ONLY from CGI
        push @qstr, join('=', escapeurl($f), escapeurl($_)) for $self->cgi_param($f);
    }
    return join '&', @qstr;
}

sub self_url {
    my $self = shift;
    return join '?', $self->action, $self->query_string;
}

# must forcibly return scalar undef for CGI::Session easiness
sub sessionid {
    my $self = shift;
    $self->{sessionid} = shift if @_;
    return $self->{sessionid} if $self->{sessionid};
    return undef unless $self->{sessionidname};
    my %cookies;
    if ($self->{cookies}) {
        require CGI::Cookie;
        %cookies = CGI::Cookie->fetch;
    }
    if (my $cook = $cookies{"$self->{sessionidname}"}) {
        return $cook->value;
    } else {
        return $self->{params}->param($self->{sessionidname}) || undef;
    }
}

sub statetags {
    my $self = shift;
    my @html = ();

    # get _submitted
    my $smnam = $self->submittedname;
    my $smtag = $self->{name} ? "${smnam}_$self->{name}" : $smnam;
    my $smval = $self->{params}->param($smnam) + 1;
    push @html, htmltag('input', name => $smtag, value => $smval, type => 'hidden');

    # and how about _sessionid
    if (defined(my $sid = $self->sessionid)) {
        push @html, htmltag('input', name => $self->{sessionidname},
                                     type => 'hidden', value => $sid);
    }

    # and what page (hooks for ::Multi)
    if (defined $self->{page}) {
        push @html, htmltag('input', name => $self->pagename,
                                     type => 'hidden', value => $self->{page});
    }

    return wantarray ? @html : join "\n", @html;
}

*keepextra = \&keepextras;
sub keepextras {
    local $^W = 0;      # -w sucks
    my $self  = shift;
    my @keep  = ();
    my @html  = ();

    # which ones do they want?
    $self->{keepextras} = shift if @_;
    return '' unless $self->{keepextras};

    # If we set keepextras, then this means that any extra fields that
    # we've set that are *not* in our fields() will be added to the form
    my $ref = ref $self->{keepextras} || '';
    if ($ref eq 'ARRAY') {
        @keep = @{$self->{keepextras}};
    } elsif ($ref) {
        puke "Unsupported data structure type '$ref' passed to 'keepextras' option";
    } else {
        # Set to "1", so must go thru all params, skipping 
        # leading underscore fields and form fields
        for my $p ($self->{params}->param()) {
            next if $p =~ /^_/  || $self->{fieldrefs}{$p};
            push @keep, $p;
        }
    }

    # In array context, we just return names we've resolved
    return @keep if wantarray;

    # Make sure to get all values
    for my $p (@keep) {
        my @values = $self->{params}->can('multi_param') ? $self->{params}->multi_param($p) : $self->{params}->param($p);
        for my $v (@values) {
            debug 1, "keepextras: saving hidden param $p = $v";
            push @html, htmltag('input', name => $p, type => 'hidden', value => $v);
        }
    }
    return join "\n", @html;    # wantarray above
}

sub javascript {
    my $self = shift;
    $self->{javascript} = shift if @_;

    # auto-determine javascript setting based on user agent
    if (lc($self->{javascript}) eq 'auto') {
        if (exists $ENV{HTTP_USER_AGENT}
                && $ENV{HTTP_USER_AGENT} =~ /lynx|mosaic/i)
        {
            # Turn off for old/non-graphical browsers
            return 0;
        }
        return 1;
    }
    return $self->{javascript} if exists $self->{javascript};

    # Turn on for all other browsers by default.
    # I suspect this process should be reversed, only
    # showing JavaScript on those browsers we know accept
    # it, but maintaining a full list will result in this
    # module going out of date and having to be updated.
    return 1;
}

sub jsname {
    my $self = shift;
    return $self->{name}
           ? (join '_', $self->{jsname}, tovar($self->{name}))
           : $self->{jsname};
}

sub script {
    my $self = shift;

    # get validate() function name
    my $jsname = $self->jsname   || puke "Must have 'jsname' if 'javascript' is on";
    my $jspre  = $self->jsprefix || '';

    # "counter"
    $self->{_didscript} = 1;
    return '' unless $self->javascript;

    # code for misc non-validate functions
    my $jsmisc = $self->script_growable     # code to grow growable fields, if any
               . $self->script_otherbox;    # code to enable/disable the "other" box

    # custom user jsfunc option for w/i validate()
    my $jsfunc = $self->jsfunc || '';
    my $jshead = $self->jshead || '';

    # expand per-field validation functions, but
    # only if we are not using Data::FormValidator
    unless (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        for ($self->field) {
            $jsfunc .= $_->script;
        }
    }
      
    # skip out if we have nothing useful
    return '' unless $jsfunc || $jsmisc || $jshead;

    # prefix with opening code
    if ($jsfunc) {
        $jsfunc = <<EOJ1 . $jsfunc . <<EOJ2;
function $jsname (form) {
    var alertstr = '';
    var invalid  = 0;
    var invalid_fields = new Array();

EOJ1
    if (invalid > 0 || alertstr != '') {
EOJ2

        # Check to see if we have our own jserror callback on form failure
        # if not, then use the builtin one. Aka jsalert
        if (my $jse = $self->jserror) {
            $jsfunc .= "        return $jse(form, invalid, alertstr, invalid_fields);\n";
        } else {
            # Finally, close our JavaScript if it was opened, wrapping in <script> tags
            # We do a regex trick to turn "%s" into "+invalid+"
            (my $alertstart = $self->{messages}->js_invalid_start) =~ s/%s/'+invalid+'/g;
            (my $alertend   = $self->{messages}->js_invalid_end)   =~ s/%s/'+invalid+'/g;

            $jsfunc .= <<EOJS;
        if (! invalid) invalid = 'The following';   // catch for programmer error
        alert('$alertstart'+'\\n\\n'
                +alertstr+'\\n'+'$alertend');
        return false;
EOJS
        }

        # Close the function
        if (my $jss = $self->jsvalid) {
            $jsfunc .= "    }\n    return $jss(form);\n}\n";
        } else {
            $jsfunc .= "    }\n    return true;  // all checked ok\n}\n";
        }

        # Must set our onsubmit to call validate()
        # Unfortunately, this introduces the requirement that script()
        # must be generated/called before start() in our template engines.
        # Fortunately, that usually happens anyways. Still sucks.
        $self->{onsubmit} ||= "return $jsname(this);";
    }

    # set <script> now to the expanded javascript
    return '<script type="text/javascript">'
         . "<!-- hide from old browsers\n"
         #. "<![CDATA[\n"    # fucking web "standards"
         . $jshead . $jsmisc . $jsfunc 
         #. "\n]]>"
         . "//-->\n</script>";
}

sub script_growable {
    my $self = shift;
    return '' unless my @growable = grep { $_->growable } $self->field;

    my $jspre  = $self->jsprefix || '';
    my $jsmisc = '';

    my $grow = $self->growname;
    $jsmisc .= <<EOJS;
var ${jspre}counter = new Object;  // for assigning unique ids; keyed by field name
var ${jspre}limit   = new Object;  // for limiting the size of growable fields
function ${jspre}grow (baseID) {
    // inititalize the counter for this ID
    if (isNaN(${jspre}counter[baseID])) ${jspre}counter[baseID] = 1;

    // don't go past the growth limit for this field
    if (${jspre}counter[baseID] >= ${jspre}limit[baseID]) return;

    var base = document.getElementById(baseID + '_' + (${jspre}counter[baseID] - 1));

    // we are inserting after the last field
    insertPoint = base.nextSibling;

    // line break
    base.parentNode.insertBefore(document.createElement('br'), insertPoint);

    var dup = base.cloneNode(true);

    dup.setAttribute('id', baseID + '_' + ${jspre}counter[baseID]);
    base.parentNode.insertBefore(dup, insertPoint);

    // add some padding space between the field and the "add field" button
    base.parentNode.insertBefore(document.createTextNode(' '), insertPoint);

    ${jspre}counter[baseID]++;

    // disable the "add field" button if we are at the limit
    if (${jspre}counter[baseID] >= ${jspre}limit[baseID]) {
        var addButton = document.getElementById('$grow' + '_' + baseID);
        addButton.setAttribute('disabled', 'disabled');
    }    
}

EOJS

    # initialize growable counters
    for (@growable) {
        my $count = scalar(my @v = $_->values);
        $jsmisc .= "${jspre}counter['$_'] = $count;\n" if $count > 0;
        # assume that values of growable > 1 provide limits
        my $limit = $_->growable;
        if ($limit && $limit ne 1) {
            $jsmisc .= "${jspre}limit['$_'] = $limit;\n";
        }
    }
    return $jsmisc;
}

sub script_otherbox {
    my $self = shift;
    return '' unless my @otherable = grep { $_->other } $self->field;

    my $jspre  = $self->jsprefix || '';
    my $jsmisc = '';
    
    $jsmisc .= <<EOJS;
// turn on/off any "other"fields
function ${jspre}other_on (othername) {
    var box = document.getElementById(othername);
    box.removeAttribute('disabled');
}

function ${jspre}other_off (othername) {
    var box = document.getElementById(othername);
    box.setAttribute('disabled', 'disabled');
}

EOJS

    return $jsmisc;
}

sub noscript {
    my $self = shift;
    # no state is kept and no args are allowed
    puke "No args allowed for \$form->noscript" if @_;
    return '' unless $self->javascript;
    return '<noscript>' . $self->invalid_tag($self->{messages}->js_noscript) . '</noscript>';
}

sub submits {
    local $^W = 0;        # -w sucks
    my $self = shift;

    # handle the submit button(s)
    # logic is a little complicated - if set but to a false value,
    # then leave off. otherwise use as the value for the tags.
    my @submit = ();
    my $sn = $self->{submitname};
    my $sc = $self->class($self->{buttonname});
    if (ref $self->{submit} eq 'ARRAY') {
        # multiple buttons + JavaScript - dynamically set the _submit value
        my @oncl = $self->javascript
                       ? (onclick => "this.form.$sn.value = this.value;") : ();
        my $i=1;
        for my $subval (autodata $self->{submit}) {
            my $si = $i > 1 ? "_$i" : '';  # number with second one
            push @submit, { type  => 'submit',
                            id    => "$self->{name}$sn$si",
                            class => $sc,
                            name  => $sn, 
                            value => $subval, @oncl };
            $i++;
        }
    } else {
        # show the text on the button
        my $subval = $self->{submit} eq 1 ? $self->{messages}->form_submit_default
                                          : $self->{submit}; 
        push @submit, { type  => 'submit', 
                        id    => "$self->{name}$sn",
                        class => $sc,
                        name  => $sn, 
                        value => $subval };
    }
    return wantarray ? @submit : [ map { htmltag('input', $_) } @submit ];
}

sub submit {
    my $self = shift;
    $self->{submit} = shift if @_;
    return '' if ! $self->{submit} || $self->static || $self->disabled;

    # no newline on buttons regardless of setting
    return join '', map { htmltag('input', $_) } $self->submits(@_);
}

sub reset {
    local $^W = 0;        # -w sucks
    my $self = shift;
    $self->{reset} = shift if @_;
    return '' if ! $self->{reset} || $self->static || $self->disabled;
    my $sc = $self->class($self->{buttonname});

    # similar to submit(), but a little simpler ;-)
    my $reset = $self->{reset} eq 1 ? $self->{messages}->form_reset_default
                                    : $self->{reset}; 
    my $rn = $self->resetname;
    return htmltag('input', type  => 'reset',
                            id    => "$self->{name}$rn",
                            class => $sc,
                            name  => $rn,
                            value => $reset);
}

sub text {
    my $self = shift;
    $self->{text} = shift if @_;
    
    # having any required fields changes the leading text
    my $req = 0;
    my $inv = 0;
    for ($self->fields) {
        $req++ if $_->required;
        $inv++ if $_->invalid;  # failed validate()
    }

    unless ($self->static || $self->disabled) {
        # only show either invalid or required text
        return $self->{text} .'<p>'. sprintf($self->{messages}->form_invalid_text,
                                             $inv,
                                             $self->invalid_tag).'</p>' if $inv;

        if ($req) {
            my $form_required_text = $self->{messages}->form_required_text;
            $form_required_text = sprintf($form_required_text, $self->required_tag)
                if $form_required_text =~ /%/;
            return $self->{text} ."<p>$form_required_text</p>";
        }
    }
    return $self->{text};
}

sub invalid_tag {
    my $self = shift;
    my $label = shift || '';
    my @tags = $self->{stylesheet}
             ? (qq(<span class="$self->{styleclass}_invalid">), '</span>')
             : ('<font color="#cc0000"><b>', '</b></font>');
    return wantarray ? @tags : join $label, @tags;
}

sub required_tag {
    my $self = shift;
    my $label = shift || '';
    my @tags =  $self->{stylesheet}
             ? (qq(<span class="$self->{styleclass}_required">), '</span>')
             : ('<b>', '</b>');
    return wantarray ? @tags : join $label, @tags;
}

sub cgi_param {
    my $self = shift;
    $self->{params}->param(@_);
}

sub tmpl_param {
    my $self = shift;
    if (my $key  = shift) {
        return @_ ? $self->{tmplvar}{$key} = shift
                  : $self->{tmplvar}{$key};
    } else {
        # return hash or key/value pairs    
        my $hr = $self->{tmplvar} || {};
        return wantarray ? %$hr : $hr;
    }
}

sub version {
    # Hidden trailer. If you perceive this as annoying, let me know and I
    # may remove it. It's supposed to help.
    return '' if $::TESTING;
    if (ref $_[0]) {
        return "\n<!-- Generated by CGI::FormBuilder v$VERSION available from www.formbuilder.org -->\n";
    } else {
        return "CGI::FormBuilder v$VERSION by Nate Wiger. All Rights Reserved.\n";
    }
}

sub values {
    my $self = shift;

    if (@_) {
        $self->{values} = arghash(@_);
        my %val = ();
        my @val = ();

        # We currently make two passes, first getting the values
        # and storing them into a temp hash, and then going thru
        # the fields and picking up the values and attributes.
        local $" = ',';
        debug 1, "\$form->{values} = ($self->{values})";

        # Using isa() allows objects to transparently fit in here
        if (UNIVERSAL::isa($self->{values}, 'CODE')) {
            # it's a sub; lookup each value in turn
            for my $key (&{$self->{values}}) {
                # always assume an arrayref of values...
                $val{$key} = [ &{$self->{values}}($key) ];
                debug 2, "setting values from \\&code(): $key = (@{$val{$key}})";
            }
        } elsif (UNIVERSAL::isa($self->{values}, 'HASH')) {
            # must lc all the keys since we're case-insensitive, then
            # we turn our values hashref into an arrayref on the fly
            my @v = autodata $self->{values};
            while (@v) {
                my $key = lc shift @v;
                $val{$key} = [ autodata shift @v ];
                debug 2, "setting values from HASH: $key = (@{$val{$key}})";
            }
        } elsif (UNIVERSAL::isa($self->{values}, 'ARRAY')) {
            # also accept an arrayref which is walked sequentially below
            debug 2, "setting values from ARRAY: (walked below)";
            @val = autodata $self->{values};
        } else {
            puke "Unsupported operand to 'values' option - must be \\%hash, \\&sub, or \$object";
        }

        # redistribute values across all existing fields
        for ($self->fields) {
            my $v = $val{lc($_)} || shift @val;     # use array if no value
            $_->field(value => $v) if defined $v;
        }
    }

}

sub name {
    my $self = shift;
    @_ ? $self->{name} = shift : $self->{name};
}

sub nameopts {
    my $self = shift;
    if (@_) {
        $self->{nameopts} = shift;
        for ($self->fields) {
            $_->field(nameopts => $self->{nameopts});
        }
    }
    return $self->{nameopts};
}

sub sortopts {
    my $self = shift;
    if (@_) {
        $self->{sortopts} = shift;
        for ($self->fields) {
            $_->field(sortopts => $self->{sortopts});
        }
    }
    return $self->{sortopts};
}

sub selectnum {
    my $self = shift;
    if (@_) {
        $self->{selectnum} = shift;
        for ($self->fields) {
            $_->field(selectnum => $self->{selectnum});
        }
    }
    return $self->{selectnum};
}

sub options {
    my $self = shift;
    if (@_) {
        $self->{options} = arghash(@_);
        my %val = ();

        # same case-insensitization as $form->values
        my @v = autodata $self->{options};
        while (@v) {
            my $key = lc shift @v;
            $val{$key} = [ autodata shift @v ];
        }

        for ($self->fields) {
            my $v = $val{lc($_)};
            $_->field(options => $v) if defined $v;
        }
    }
    return $self->{options};
}

sub labels {
    my $self = shift;
    if (@_) {
        $self->{labels} = arghash(@_);
        my %val = ();

        # same case-insensitization as $form->values
        my @v = autodata $self->{labels};
        while (@v) {
            my $key = lc shift @v;
            $val{$key} = [ autodata shift @v ];
        }

        for ($self->fields) {
            my $v = $val{lc($_)};
            $_->field(label => $v) if defined $v;
        }
    }
    return $self->{labels};
}

# Note that validate does not work like a true accessor
sub validate {
    my $self = shift;
    
    if (@_) {
        if (ref $_[0]) {
            # this'll either be a hashref or a DFV object
            $self->{validate} = shift;
        } elsif (@_ % 2 == 0) {
            # someone passed a hash-as-list
            $self->{validate} = { @_ };
        } elsif (@_ > 1) {
            # just one argument we'll interpret as a DFV profile name;
            # an odd number > 1 is probably a typo...
            puke "Odd number of elements passed to validate";
        }
    }

    my $ok = 1;

    if (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        my $profile_name = shift || 'fb';
        debug 1, "validating fields via the '$profile_name' profile";
        # hang on to the DFV results, for things like DBIx::Class::WebForm
        $self->{dfv_results} = $self->{validate}->check($self, $profile_name);

	    # mark the invalid fields
	    my @invalid_fields = (
	        $self->{dfv_results}->invalid, 
	        $self->{dfv_results}->missing,
	    );
	    for my $field_name (@invalid_fields) {
	        $self->field(
		    name    => $field_name,
		    invalid => 1,
	        );
	    }
	    # validation failed
        $ok = 0 if @invalid_fields > 0;
    } else {    
        debug 1, "validating all fields via \$form->validate";
        for ($self->fields) {
            $ok = 0 unless $_->validate;
        }
    }
    debug 1, "validation done, ok = $ok (should be 1)";
    return $ok;
}

sub confirm {
    # This is nothing more than a special wrapper around render()
    my $self = shift;
    my $date = $::TESTING ? 'LOCALTIME' : localtime();
    $self->{text} ||= sprintf $self->{messages}->form_confirm_text, $date;
    $self->{static} = 1;
    return $self->render(@_);
}   

# Prepare a template
sub prepare {
    my $self = shift;
    debug 1, "Calling \$form->prepare(@_)";

    # Build a big hashref of data that can be used by the template
    # engine. Templates then have the ability to expand this however
    # they see fit.
    my %tmplvar = $self->tmpl_param;

    # This is based on the original Template Toolkit render()
    for my $field ($self->field) {

        # Extract value since used often
        my @value = $field->tag_value;

        # Create a struct for each field
        $tmplvar{field}{"$field"} = {
             %$field,   # gets invalid/missing/required
             field   => $field->tag,
             value   => $value[0],
             values  => \@value,
             options => [$field->options],
             label   => $field->label,
             type    => $field->type,
             comment => $field->comment,
             nameopts => $field->nameopts,
             cleanopts => $field->cleanopts,
        };
        # Force-stringify "$field" to get name() under buggy Perls
        $tmplvar{field}{"$field"}{error} = $field->error;
    }

    # Must generate JS first because it affects the others.
    # This is a bit action-at-a-distance, but I just can't
    # figure out a way around it.
    debug 2, "\$tmplvar{jshead} = \$self->script";
    $tmplvar{jshead}   = $self->script;
    debug 2, "\$tmplvar{title} = \$self->title";
    $tmplvar{title}    = $self->title;
    debug 2, "\$tmplvar{start} = \$self->start . \$self->statetags . \$self->keepextras";
    $tmplvar{start}    = $self->start . $self->statetags . $self->keepextras;
    debug 2, "\$tmplvar{submit} = \$self->submit";
    $tmplvar{submit}   = $self->submit;
    debug 2, "\$tmplvar{reset} = \$self->reset";
    $tmplvar{reset}    = $self->reset;
    debug 2, "\$tmplvar{end} = \$self->end";
    $tmplvar{end}      = $self->end;
    debug 2, "\$tmplvar{invalid} = \$self->invalid";
    $tmplvar{invalid}  = $self->invalid;
    debug 2, "\$tmplvar{required} = \$self->required";
    $tmplvar{required} = $self->required;

    my $fieldsets = $self->fieldsets;
    for my $key (keys %$fieldsets) {
        $tmplvar{fieldset}{$key} = {
            name => $key,
            label => $fieldsets->{$key},
        }
    }
    $tmplvar{fieldsets} = [ map $tmplvar{fieldset}{$_}, $self->fieldsets ];

    debug 2, "\$tmplvar{fields} = [ map \$tmplvar{field}{\$_}, \$self->field ]";
    $tmplvar{fields}   = [ map $tmplvar{field}{$_}, $self->field ];

    return wantarray ? %tmplvar : \%tmplvar;
}

sub render {
    local $^W = 0;        # -w sucks
    my $self = shift;
    debug 1, "starting \$form->render(@_)";

    # any arguments are used to make permanent changes to the $form
    if (@_) {
        puke "Odd number of arguments passed into \$form->render()"
            unless @_ % 2 == 0;
        while (@_) {
            my $k = shift;
            $self->$k(shift);
        }
    }

    # check for engine type
    my $mod;
    my $ref = ref $self->{template};
    if (! $ref && $self->{template}) {
        # "legacy" string filename for HTML::Template; redo format
        # modifying $self object is ok because it's compatible
        $self->{template} = {
            type     => 'HTML',
            filename => $self->{template},
        };
        $ref = 'HASH';  # tricky
        debug 2, "rewrote 'template' option since found filename";
    }
    # Get ourselves ready
    $self->{prepare} = $self->prepare;
    # weaken($self->{prepare});
    
    my $opt;
    if ($ref eq 'HASH') {
        # must copy to avoid destroying
        $opt = { %{ $self->{template} } };
        $mod = ucfirst(delete $opt->{type} || 'HTML');
    } elsif ($ref eq 'CODE') {
        # subroutine wrapper
        return &{$self->{template}}($self);
    } elsif (UNIVERSAL::can($self->{template}, 'render')) {
        # instantiated object
        return $self->{template}->render($self);
    } elsif ($ref) {
        puke "Unsupported operand to 'template' option - must be \\%hash, \\&sub, or \$object w/ render()";
    }

    # load user-specified rendering module, or builtin rendering
    $mod ||= 'Builtin';

    # user can give 'Their::Complete::Module' or an 'IncludedAdapter'
    $mod = join '::', __PACKAGE__, 'Template', $mod unless $mod =~ /::/;
    debug 1, "loading $mod for 'template' option";

    # load module
    eval "require $mod";
    puke "Bad template engine $mod: $@" if $@;

    # create new object
    #CGI::FormBuilder::Template::Builtin
    
    my $tmpl = $mod->new($opt);
    # Experiemental: Alter tag names as we're rendering, to support 
    # Ajaxian markup schemes that use their own tags (Backbase, Dojo, etc)
    local %CGI::FormBuilder::Util::TAGNAMES;
    while (my($k,$v) = each %{$self->{tagnames}}) {
        $CGI::FormBuilder::Util::TAGNAMES{$k} = $v;
    }


    # Call the engine's prepare too, if it exists
    # Give it the form object so it can do what it wants
    # This will have all of the prepared data in {prepare} anyways
    if ($tmpl && UNIVERSAL::can($tmpl, 'prepare')) {
        $tmpl->prepare($self);
    }
    


    # dispatch to engine, prepend header
    debug 1, "returning $tmpl->render($self->{prepare})";

    my $ret = $self->header . $tmpl->render($self->{prepare});
    
    #we have a circular reference but we need to kill it after setting up return
    weaken($self->{prepare});
    return $ret;
}

# These routines should be moved to ::Mail or something since they're rarely used
sub mail () {
    # This is a very generic mail handler
    my $self = shift;
    my $args = arghash(@_);

    # Where does the mailer live? Must be sendmail-compatible
    my $mailer = undef;
    unless ($mailer = $args->{mailer} && -x $mailer) {
        for my $sendmail (qw(/usr/lib/sendmail /usr/sbin/sendmail /usr/bin/sendmail)) {
            if (-x $sendmail) {
                $mailer = "$sendmail -t";
                last;
            }
        }
    }
    unless ($mailer) {
        belch "Cannot find a sendmail-compatible mailer; use mailer => '/path/to/mailer'";
        return;
    }
    unless ($args->{to}) {
        belch "Missing required 'to' argument; cannot continue without recipient";
        return;
    }
    if ($args->{from}) {
        (my $from = $args->{from}) =~ s/"/\\"/g;
        $mailer .= qq( -f "$from");
    }

    debug 1, "opening new mail to $args->{to}";

    # untaint
    my $oldpath = $ENV{PATH};
    $ENV{PATH} = '/usr/bin:/usr/sbin';

    open(MAIL, "|$mailer >/dev/null 2>&1") || next;
    print MAIL "From: $args->{from}\n";
    print MAIL "To: $args->{to}\n";
    print MAIL "Cc: $args->{cc}\n" if $args->{cc};
    print MAIL "Content-Type: text/plain; charset=\""
              . $self->charset . "\"\n" if $self->charset;
    print MAIL "Subject: $args->{subject}\n\n";
    print MAIL "$args->{text}\n";

    # retaint
    $ENV{PATH} = $oldpath;

    return close(MAIL);
}

sub mailconfirm () {

    # This prints out a very generic message. This should probably
    # be much better, but I suspect very few if any people will use
    # this method. If you do, let me know and maybe I'll work on it.

    my $self = shift;
    my $to = shift unless (@_ > 1);
    my $args = arghash(@_);

    # must have a "to"
    return unless $args->{to} ||= $to;

    # defaults
    $args->{from}    ||= 'auto-reply';
    $args->{subject} ||= sprintf $self->{messages}->mail_confirm_subject, $self->title;
    $args->{text}    ||= sprintf $self->{messages}->mail_confirm_text, scalar localtime();

    debug 1, "mailconfirm() called, subject = '$args->{subject}'";

    $self->mail($args);
}

sub mailresults () {
    # This is a wrapper around mail() that sends the form results
    my $self = shift;
    my $args = arghash(@_);

    if (exists $args->{plugin}) {
        my $lib = "CGI::FormBuilder::Mail::$args->{plugin}";
        eval "use $lib";
        puke "Cannot use mailresults() plugin '$lib': $@" if $@;
        eval {
            my $plugin = $lib->new( form => $self, %$args );
            $plugin->mailresults();
        };
        puke "Could not mailresults() with plugin '$lib': $@" if $@;
        return;
    }

    # Get the field separator to use
    my $delim = $args->{delimiter} || ': ';
    my $join  = $args->{joiner}    || $";
    my $sep   = $args->{separator} || "\n";

    # subject default
    $args->{subject} ||= sprintf $self->{messages}->mail_results_subject, $self->title;
    debug 1, "mailresults() called, subject = '$args->{subject}'";

    if ($args->{skip}) {
        if ($args->{skip} =~ m#^m?(\S)(.*)\1$#) {
            ($args->{skip} = $2) =~ s/\\\//\//g;
            $args->{skip} =~ s/\//\\\//g;
        }
    }

    my @form = ();
    for my $field ($self->fields) {
        if ($args->{skip} && $field =~ /$args->{skip}/) {
            next;
        }
        my $v = join $join, $field->value;
        $field = $field->label if $args->{labels};
        push @form, "$field$delim$v"; 
    }
    my $text = join $sep, @form;

    $self->mail(%$args, text => $text);
}

sub DESTROY { 1 }

# This is used to access all options after new(), by name
sub AUTOLOAD {
    # This allows direct addressing by name
    local $^W = 0;
    my $self = shift;
    my($name) = $AUTOLOAD =~ /.*::(.+)/;

    # If fieldsubs => 1 set, then allow grabbing fields directly
    if ($self->{fieldsubs} && $self->{fieldrefs}{$name}) {
        return $self->field(name => $name, @_);
    }

    debug 3, "-> dispatch to \$form->{$name} = @_";
    if (@_ % 2 == 1) {
        $self->{$name} = shift;

        if ($REARRANGE{$name}) {
            # needs to be splatted into every field
            for ($self->fields) {
                my $tval = rearrange($self->{$name}, "$_");
                $_->$name($tval);
            }
        }
    }

    # Try to catch  $form->$fieldname usage
    if ((! exists($self->{$name}) || @_) && ! $CGI::FormBuilder::Util::OURATTR{$name}) {
        if ($self->{fieldsubs}) {
            return $self->field(name => $name, @_);
        } else {
            belch "Possible field access via \$form->$name() - see 'fieldsubs' option"
        }
    }

    return $self->{$name};
}

1;
__END__

