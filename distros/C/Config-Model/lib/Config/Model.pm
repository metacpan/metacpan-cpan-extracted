#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model 2.155;

use 5.20.0;
use strict ;
use warnings;

use Mouse;
use Mouse::Util::TypeConstraints;
use MouseX::StrictConstructor;

use Carp;
use Storable ('dclone');
use Data::Dumper ();
use Log::Log4perl 1.11 qw(get_logger :levels);
use Config::Model::Instance;
use Hash::Merge 0.12 qw/merge/;
use Path::Tiny 0.053;
use File::HomeDir;

use Cwd;
use Config::Model::Lister;

with "Config::Model::Role::Constants";

use parent qw/Exporter/;
our @EXPORT_OK = qw/cme initialize_log4perl/;

use feature qw/signatures postderef/;
no warnings qw/experimental::signatures experimental::postderef/;

# used in some tests where we don't want to load
# ~/.log4config-model config
my $force_default_log;
sub force_usage_of_default_log_config () {
    return $force_default_log = 1;
}

my $legacy_logger = get_logger("Model::Legacy") ;
my $loader_logger = get_logger("Model::Loader") ;
my $logger = get_logger("Model") ;

# used to keep one Config::Model object to simplify programs based on
# cme function
my $model_storage;

enum LegacyTreament => qw/die warn ignore/;

has skip_include => ( isa => 'Bool',           is => 'ro', default => 0 );
has model_dir    => ( isa => 'Str',            is => 'ro', default => 'Config/Model/models' );
has legacy       => ( isa => 'LegacyTreament', is => 'ro', default => 'warn' );
has instances => (
    isa => 'HashRef[Config::Model::Instance]',
    is => 'ro',
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        store_instance => 'set',
        get_instance   => 'get',
        has_instance   => 'defined',
    },
);

# Config::Model stores 3 versions of each model

# raw_model is the model exactly as passed by the user. Since the format is quite
# liberal (e.g legacy parameters, grouped declaration of elements like '[qw/foo bar/] => {}}',
# element description in class or in element declaration)), this raw format is not
# usable without normalization (done by normalize_class_parameters)

# the key if this hash is a model name
has raw_models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        raw_model_exists  => 'exists',
        raw_model_defined => 'defined',
        raw_model         => 'get',
        get_raw_model     => 'get',
        store_raw_model   => 'set',
        raw_model_names   => 'keys',
    },
);

# the result of normalization is stored here. Normalized model aggregate user models and
# augmented features (the one found in Foo.d directory). inclusion of other class is NOT
# yet done. normalized_models are created while loading files (load method) or creating
# configuration classes (create_config_class)
has normalized_models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        normalized_model_exists  => 'exists',
        normalized_model_defined => 'defined',
        normalized_model         => 'get',
        store_normalized_model   => 'set',
        normalized_model_names   => 'keys',
    },
);

# This attribute contain the model that will be used by Config::Model::Node. They
# are created on demand when get_model is called. When created the inclusion of
# other classes is done according to the class 'include' parameter. Note that get_model
# will try to call load if the required normalized_model is not known (lazy loading)
has models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        model_exists  => 'exists',
        model_defined => 'defined',
        _get_model    => 'get',
        _store_model  => 'set',
    },
);

# model snippet may be loaded when the target class is not available
# so they must be stored before being used.
has model_snippets => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_snippet => 'push',
        all_snippets => 'elements',
    },
);


enum 'LOG_LEVELS', [ qw/ERROR WARN INFO DEBUG TRACE/ ];

has log_level => (
    isa => 'LOG_LEVELS',
    is => 'ro',
);

has skip_inheritance => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
    trigger => sub {
        my $self = shift;
        $self->show_legacy_issue("skip_inheritance is deprecated, use skip_include");
        $self->skip_include = $self->skip_inheritance;
    } );

# remove this hack mid 2022
around BUILDARGS => sub ($orig, $class, %args) {
    my %new;
    foreach my $k (keys %args) {
        if (defined $args{$k}) {
            $new{$k} = $args{$k};
        }
        else {
            # cannot use logger, it's not initialised yet
            croak("Config::Model new: passing undefined constructor argument is deprecated ($k argument)\n");
        }
    }

    return $class->$orig(%new);
};

# keep this as a separate sub from BUILD. So user can call it before
# creating Config::Model object
sub initialize_log4perl (@args) {
    if (ref $args[0]) {
        # may be called as $self-> initialize_log4perl
        shift @args;
    }

    my %args = @args;

    my $log4perl_syst_conf_file = path('/etc/log4config-model.conf');
    # avoid undef warning when homedir is not defined (e.g. with Debian cowbuilder)
    my $home = File::HomeDir->my_home // '';
    my $log4perl_user_conf_file = path( $home . '/.log4config-model' );

    my $fallback_conf_file = path($INC{"Config/Model.pm"})
        ->parent->child("Model/log4perl.conf") ;


    my $log4perl_file =
        $force_default_log                ? $fallback_conf_file # for tests
      : $log4perl_user_conf_file->is_file ? $log4perl_user_conf_file
      : $log4perl_syst_conf_file->is_file ? $log4perl_syst_conf_file
      :                                     $fallback_conf_file;
    my %log4perl_conf =
        map { split /\s*=\s*/,$_,2; }
        grep { chomp; ! /^\s*#/ } $log4perl_file->lines;

    my $verbose = $args{verbose};
    if (defined $verbose) {
        my @loggers = ref $verbose ? @$verbose : $verbose;
        foreach my $logger (@loggers) {
            $log4perl_conf{"log4perl.logger.Verbose.$logger"} = "INFO, PlainMsgOnScreen";
        }
    }

    Log::Log4perl::init(\%log4perl_conf);

    return \%log4perl_conf; # for tests
}

sub BUILD {
    my $self = shift;
    my $args = shift;
    initialize_log4perl(verbose => $args->{verbose}) unless Log::Log4perl->initialized();
    return;
}

sub show_legacy_issue {
    my $self     = shift;
    my $ref      = shift;
    my $behavior = shift || $self->legacy;

    my @msg = ref $ref ? @$ref : $ref;
    unshift @msg, "Model ";
    if ( $behavior eq 'die' ) {
        die @msg, "\n";
    }
    elsif ( $behavior eq 'warn' ) {
        $legacy_logger->warn(@msg);
    } elsif ( $behavior eq 'note' ) {
        $legacy_logger->info( @msg);
    }
    return;
}

sub _tweak_instance_args {
    my ($args) = @_  ;

    my $application = $args->{application} ;
    my $cat = '';
    if (defined $application) {
        my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;

        # root_class_name may override class found (or not) by appli in tests
        if (not $args->{root_class_name}) {
            $args->{root_class_name} = $appli_map->{$application} ||
                die "Unknown application $application. Expected one of "
                . join(' ',sort keys %$appli_map)."\n";
        }

        $cat = $appli_info->{_category} //  ''; # may be empty in tests
        # config_dir may be specified in application file
        $args->{config_dir} //= $appli_info->{$application}{config_dir};
        $args->{appli_info} = $appli_info->{$application} // {};
    }

    my $app_name = $application;
    if ($cat eq 'application') {
        # store dir in name to distinguish different runs of the same
        # app in different directories.
        $application .= " in " . cwd;
    }
    $args->{name}
        =  delete $args->{instance_name} # backward compat with test
        || delete $args->{name}          # preferred parameter
        || $app_name                     # fallback in most cases
        || 'default';                    # fallback mostly in tests
    return;
}

sub cme (@args) {
    my %args = @args == 1 ? ( application => $args[0]) : @args ;

    if (my $force = delete $args{'force-load'}) {
        $args{check} = 'no' if $force;
    }

    my $cat =_tweak_instance_args(\%args);

    my $m_args = delete $args{model_args} // {} ; # used for tests
    # model_storage is used to keep Config::Model object alive
    $model_storage //= Config::Model->new(%$m_args);

    return $model_storage->instance(%args);
}

sub instance ($self, @args) {
    my %args = @args == 1 ? ( application => $args[0]) : @args ;

    # also creates a default name
    _tweak_instance_args(\%args);

    if ( $args{name} and $self->has_instance($args{name}) ) {
        return $self->get_instance($args{name});
    }

    croak "Model: can't create instance without application or root_class_name "
        unless $args{root_class_name};

    if ( defined $args{model_file} ) {
        my $file = delete $args{model_file};
        $self->load( $args{root_class_name}, $file );
    }

    my $i = Config::Model::Instance->new(
        config_model    => $self,
        %args    # for optional parameters like *directory
    );

    $self->store_instance($args{name}, $i);
    return $i;
}

sub instance_names {
    my $self = shift;
    my @all = sort keys %{ $self->instances };
    return @all;
}

# unpacked model is:
# {
#   element_list  => [ ... ],
#   element       => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   include       => 'class_name',
#   include_after => 'element_name',
# }
# description, summary, level, status are moved
# into element description.

my @legal_params_to_move = (
    qw/read_config write_config rw_config/,    # read/write stuff

    # this parameter is filled by class generated by a program. It may
    # be used to avoid interactive edition of a generated model
    'generated_by',
    qw/class_description author copyright gist license include include_after include_backend class/
);

my @other_legal_params = qw/ author element status description summary level accept/;

# keep as external API. All internal call go through _store_model
#  See comments around raw_models attribute for explanations
sub create_config_class ($self, %raw_model) {
    my $config_class_name = delete $raw_model{name}
        or croak "create_config_class: no config class name";

    get_logger("Model")->info("Creating class $config_class_name");

    if ( $self->model_exists($config_class_name) ) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "create_config_class: attempt to clobber $config_class_name"
                . " config class name " );
    }

    $self->store_raw_model( $config_class_name, dclone( \%raw_model ) );

    my $model = $self->normalize_class_parameters( $config_class_name, \%raw_model );

    $self->store_normalized_model( $config_class_name, $model );

    return $config_class_name;
}

sub merge_included_class {
    my ( $self, $config_class_name ) = @_;

    my $normalized_model = $self->normalized_model($config_class_name);
    my $model            = dclone $normalized_model ;

    # add included elements
    if ( $self->skip_include and defined $normalized_model->{include} ) {
        my $inc = $normalized_model->{include};
        $model->{include} = ref $inc ? $inc : [$inc];
        $model->{include_after} = $normalized_model->{include_after}
            if defined $normalized_model->{include_after};
    }
    else {
        # include class in raw_copy, normalized_model is left as is
        $self->include_class( $config_class_name, $model );
    }

    # add included backend
    if ( $self->skip_include and defined $normalized_model->{include_backend} ) {
        my $inc = $normalized_model->{include_backend};
        $model->{include_backend} = ref $inc ? $inc : [$inc];
    }
    else {
        # include read/write config specifications in raw_copy,
        # normalized_model is left as is
        $self->include_backend( $config_class_name, $model );
    }

    return $model;
}

sub include_backend {
    my $self         = shift;
    my $class_name   = shift || croak "include_backend: undef includer";
    my $target_model = shift || die "include_backend:: undefined target_model";

    my $included_classes = delete $target_model->{include_backend};
    return () unless defined $included_classes;

    foreach my $included_class (@$included_classes) {
        # takes care of recursive include, because get_model will perform
        # includes (and normalization). Is already a dclone
        my $included_model = $self->get_model_clone($included_class);

        foreach my $rw (qw/rw_config read_config write_config config_dir/) {
            if ($target_model->{$rw} and $included_model->{$rw}) {
                my $msg = "Included $rw from $included_class cannot clobber "
                    . "existing data in $class_name";
                Config::Model::Exception::ModelDeclaration->throw( error => $msg );
            }
            elsif ($included_model->{$rw}) {
                $target_model->{$rw} = $included_model->{$rw};
            }
        }
    }
    return;
}

sub normalize_class_parameters {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $normalized_model  = shift || die;

    my $model = {};

    # sanity check
    my $raw_name = delete $normalized_model->{name};
    if ( defined $raw_name and $config_class_name ne $raw_name ) {
        my $e = "internal: config_class_name $config_class_name ne model name $raw_name";
        Config::Model::Exception::ModelDeclaration->throw( error => $e );
    }

    my @element_list;

    # first construct the element list
    my @compact_list = @{ $normalized_model->{element} || [] };
    while (@compact_list) {
        my ( $item, $info ) = splice @compact_list, 0, 2;

        # store the order of element as declared in 'element'
        push @element_list, ref($item) ? @$item : ($item);
    }

    if ( defined $normalized_model->{inherit_after} ) {
        $self->show_legacy_issue([ "Model $config_class_name: inherit_after is deprecated ",
            "in favor of include_after" ]);
        $normalized_model->{include_after} = delete $normalized_model->{inherit_after};
    }
    if ( defined $normalized_model->{inherit} ) {
        $self->show_legacy_issue(
            "Model $config_class_name: inherit is deprecated in favor of include");
        $normalized_model->{include} = delete $normalized_model->{inherit};
    }

    foreach my $info (@legal_params_to_move) {
        next unless defined $normalized_model->{$info};
        $model->{$info} = delete $normalized_model->{$info};
    }

    # first deal with perl file and cds_file backend
    $self->translate_legacy_backend_info( $config_class_name, $model );

    # handle accept parameter
    my @accept_list;
    my %accept_hash;
    my $accept_info = delete $normalized_model->{'accept'} || [];
    while (@$accept_info) {
        my $name_match = shift @$accept_info;    # should be a regexp

        # handle legacy
        if ( ref $name_match ) {
            my $implicit = defined $name_match->{name_match} ? '' : 'implicit ';
            unshift @$accept_info, $name_match;    # put data back in list
            $name_match = delete $name_match->{name_match} || '.*';
            $logger->warn("class $config_class_name: name_match ($implicit$name_match)",
                " in accept is deprecated");
        }

        push @accept_list, $name_match;
        $accept_hash{$name_match} = shift @$accept_info;
    }

    $model->{accept}      = \%accept_hash;
    $model->{accept_list} = \@accept_list;

    # check for duplicate in @element_list.
    my %check_list;
    foreach (@element_list) { $check_list{$_}++ };
    my @extra = grep { $check_list{$_} > 1 } keys %check_list;
    if (@extra) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "class $config_class_name: @extra element "
                . "is declared more than once. Check the included parts" );
    }

    $self->handle_experience_permission( $config_class_name, $normalized_model );

    # element is handled first
    foreach my $info_name (qw/element status description summary level/) {
        my $raw_compact_info = delete $normalized_model->{$info_name};

        next unless defined $raw_compact_info;

        Config::Model::Exception::ModelDeclaration->throw(
            error => "Data for parameter $info_name of $config_class_name"
                . " is not an array ref" )
            unless ref($raw_compact_info) eq 'ARRAY';

        my @raw_info = @$raw_compact_info;
        while (@raw_info) {
            my ( $item, $info ) = splice @raw_info, 0, 2;
            my @element_names = ref($item) ? @$item : ($item);

            # move element informations (handled first)
            if ( $info_name eq 'element' ) {

                # warp can be found only in element item
                $self->translate_legacy_info( $config_class_name, $element_names[0], $info );

                $self->handle_experience_permission( $config_class_name, $info );

                # copy in element data *after* legacy translation
                foreach (@element_names) { $model->{element}{$_} = dclone($info); };
            }

            # move some information into element declaration (without clobberring)
            elsif ( $info_name =~ /description|level|summary|status/ ) {
                foreach (@element_names) {
                    Config::Model::Exception::ModelDeclaration->throw(
                        error => "create class $config_class_name: '$info_name' "
                            . "declaration for non declared element '$_'" )
                        unless defined $model->{element}{$_};

                    $model->{element}{$_}{$info_name} ||= $info;
                }
            }
            else {
                die "Unexpected element $item in $config_class_name model";
            }

        }
    }

    Config::Model::Exception::ModelDeclaration->throw(
              error => "create class $config_class_name: unexpected "
            . "parameters '"
            . join( ', ', sort keys %$normalized_model ) . "' "
            . "Expected '"
            . join( "', '", @legal_params_to_move, @other_legal_params )
            . "'" )
        if keys %$normalized_model;

    $model->{element_list} = \@element_list;

    return $model;
}

sub handle_experience_permission {
    my ( $self, $config_class_name, $model ) = @_;

    if (delete $model->{permission}) {
        die "$config_class_name: parameter permission is obsolete\n";
    }
    if (delete $model->{experience}) {
        carp "experience parameter is deprecated";
    }
    return;
}

sub translate_legacy_info {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    $self->translate_warped_node_info( $config_class_name, $elt_name, 'warped_node', $info );

    #translate legacy warp information
    if ( defined $info->{warp} ) {
        $self->translate_warp_info( $config_class_name, $elt_name, $info->{type}, $info->{warp} );
    }

    $self->translate_cargo_info( $config_class_name, $elt_name, $info );

    if (   defined $info->{cargo}
        && defined $info->{cargo}{type}
        && $info->{cargo}{type} eq 'warped_node' ) {
        $self->translate_warped_node_info( $config_class_name, $elt_name, 'warped_node', $info->{cargo} );
    }

    if (    defined $info->{cargo}
        and defined $info->{cargo}{warp} ) {
        $self->translate_warp_info(
            $config_class_name, $elt_name,
            $info->{cargo}{type},
            $info->{cargo}{warp} );
    }

    # compute cannot be warped
    if ( defined $info->{compute} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info, 'compute' );
        $self->translate_allow_compute_override( $config_class_name, $elt_name, $info );
    }
    if (    defined $info->{cargo}
        and defined $info->{cargo}{compute} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info->{cargo}, 'compute' );
        $self->translate_allow_compute_override( $config_class_name, $elt_name, $info->{cargo} );
    }

    # refer_to cannot be warped
    if ( defined $info->{refer_to} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info,
            refer_to => 'computed_refer_to' );
    }
    if (    defined $info->{cargo}
        and defined $info->{cargo}{refer_to} ) {
        $self->translate_compute_info( $config_class_name, $elt_name,
            $info->{cargo}, refer_to => 'computed_refer_to' );
    }

    # translate id default param
    # default cannot be stored in cargo since is applies to the id itself
    if ( defined $info->{type}
        and ( $info->{type} eq 'list' or $info->{type} eq 'hash' ) ) {
        if ( defined $info->{default} ) {
            $self->translate_id_default_info( $config_class_name, $elt_name, $info );
        }
        if ( defined $info->{auto_create} ) {
            $self->translate_id_auto_create( $config_class_name, $elt_name, $info );
        }
        $self->translate_id_min_max( $config_class_name, $elt_name, $info );
        $self->translate_id_names( $config_class_name, $elt_name, $info );
        if ( defined $info->{warp} ) {
            my $rules_a = $info->{warp}{rules};
            my %h       = @$rules_a;
            foreach my $rule_effect ( values %h ) {
                $self->translate_id_names( $config_class_name, $elt_name, $rule_effect );
                $self->translate_id_min_max( $config_class_name, $elt_name, $rule_effect );
                next unless defined $rule_effect->{default};
                $self->translate_id_default_info( $config_class_name, $elt_name, $rule_effect );
            }
        }
        $self->translate_id_class($config_class_name, $elt_name, $info );
    }

    if ( defined $info->{type} and ( $info->{type} eq 'leaf' ) ) {
        $self->translate_legacy_builtin( $config_class_name, $info, $info, );
    }

    if ( defined $info->{type} and ( $info->{type} eq 'check_list' ) ) {
        $self->translate_legacy_built_in_list( $config_class_name, $info, $info, );
    }

    $legacy_logger->debug(
        Data::Dumper->Dump( [$info], [ 'translated_' . $elt_name ] ) 
    ) if $legacy_logger->is_debug;
    return;
}

sub translate_legacy_backend_info {
    my ( $self, $config_class_name, $model ) = @_;

    # trap multi backend and change array spec into single spec
    foreach my $config (qw/read_config write_config/) {
        my $ref = $model->{$config};
        if ($ref and ref($ref) eq 'ARRAY') {
            if (@$ref == 1) {
                $model->{$config} = $ref->[0];
            }
            elsif (@$ref > 1){
                $self->show_legacy_issue("$config_class_name $config: multiple backends are obsolete. You now must use only one backend.", 'die');
            }
        }
    }

    # move read_config spec in re_config
    if ($model->{read_config}) {
        $self->show_legacy_issue("$config_class_name: read_config specification is deprecated, please move in rw_config", 'warn');
        $model->{rw_config} = delete $model->{read_config};
    }

    # merge write_config spec in rw_config
    if ($model->{write_config}) {
        $self->show_legacy_issue("$config_class_name: write_config specification is deprecated, please merge with read_config and move in rw_config", 'warn');
        foreach (keys %{$model->{write_config}}) {
            $model->{rw_config}{$_} = $model->{write_config}{$_}
        }
        delete $model->{write_config};
    }

    my $ref = $model->{'rw_config'} || return;

    die "undefined backend in rw_config spec of class $config_class_name\n" unless $ref->{backend} ;

    if ($ref->{backend} eq 'custom') {
        my $msg = "$config_class_name: custom read/write backend is obsolete."
            ." Please replace with a backend inheriting Config::Model::Backend::Any";
        $self->show_legacy_issue( $msg, 'die');
    }

    if ( $ref->{backend} =~ /^(perl|ini|cds)$/ ) {
        my $backend = $ref->{backend};
        $self->show_legacy_issue("$config_class_name: deprecated backend '$backend'. Should be '$ {backend}_file'", 'warn');
        $ref->{backend} .= "_file";
    }

    if ( defined $ref->{allow_empty} ) {
        $self->show_legacy_issue("$config_class_name: backend $ref->{backend}: allow_empty is deprecated. Use auto_create", 'warn');
        $ref->{auto_create} = delete $ref->{allow_empty};
    }
    return;
}

sub translate_cargo_info {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;

    my $c_type = delete $info->{cargo_type};
    return unless defined $c_type;
    $self->show_legacy_issue("$config_class_name->$elt_name: parameter cargo_type is deprecated.");
    my %cargo;

    if ( defined $info->{cargo_args} ) {
        %cargo = %{ delete $info->{cargo_args} };
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter cargo_args is deprecated.");
    }

    $cargo{type} = $c_type;

    if ( defined $info->{config_class_name} ) {
        $cargo{config_class_name} = delete $info->{config_class_name};
        $self->show_legacy_issue([
            "$config_class_name->$elt_name: parameter config_class_name is ",
            "deprecated. This one must be specified within cargo. ",
            "Ie. cargo=>{config_class_name => 'FooBar'}"
        ]);
    }

    $info->{cargo} = \%cargo;
    $legacy_logger->debug( 
        Data::Dumper->Dump( [$info], [ 'translated_' . $elt_name ] ) 
    ) if $legacy_logger->is_debug;
    return;
}

sub translate_id_names {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;
    $self->translate_name( $config_class_name, $elt_name, $info, 'allow',      'allow_keys',       'die' );
    $self->translate_name( $config_class_name, $elt_name, $info, 'allow_from', 'allow_keys_from',  'die' );
    $self->translate_name( $config_class_name, $elt_name, $info, 'follow',     'follow_keys_from', 'die' );
    return;
}

sub translate_name {
    my ($self, $config_class_name, $elt_name, $info, $from, $to, $legacy) = @_;

    if ( defined $info->{$from} ) {
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter $from is deprecated in favor of $to",
            $legacy
        );
        $info->{$to} = delete $info->{$from};
    }
    return;
}

sub translate_allow_compute_override {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;

    if ( defined $info->{allow_compute_override} ) {
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter allow_compute_override is deprecated in favor of compute -> allow_override"
        );
        $info->{compute}{allow_override} = delete $info->{allow_compute_override};
    }
    return;
}

sub translate_compute_info {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;
    my $old_name          = shift;
    my $new_name          = shift || $old_name;

    if ( ref( $info->{$old_name} ) eq 'ARRAY' ) {
        my $compute_info = delete $info->{$old_name};
        $legacy_logger->debug(
            "translate_compute_info $elt_name input:\n",
            Data::Dumper->Dump( [$compute_info], [qw/compute_info/] )
        ) if $legacy_logger->is_debug;

        $self->show_legacy_issue([ "$config_class_name->$elt_name: specifying compute info with ",
            "an array ref is deprecated" ]);

        my ( $user_formula, %var ) = @$compute_info;
        my $replace_h;
        foreach ( keys %var ) { $replace_h = delete $var{$_} if ref( $var{$_} ) };

        # cleanup user formula
        $user_formula =~ s/\$(\w+)\{/\$replace{/g;

        # cleanup variable
        foreach ( values %var ) { s/\$(\w+)\{/\$replace{/g };

        # change the hash *in* the info structure
        $info->{$new_name} = {
            formula   => $user_formula,
            variables => \%var,
        };
        $info->{$new_name}{replace} = $replace_h if defined $replace_h;

        $legacy_logger->debug(
            "translate_warp_info $elt_name output:\n",
            Data::Dumper->Dump( [ $info->{$new_name} ], [ 'new_' . $new_name ] )
        ) if $legacy_logger->is_debug;
    }
    return;
}

sub translate_id_class {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;


    $legacy_logger->debug(
        "translate_id_class $elt_name input:\n",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $class_overide_param = $info->{type}.'_class';
    my $class_overide = $info->{$class_overide_param};
    if ($class_overide) {
        $info->{class} = $class_overide;
        $self->show_legacy_issue([
            "$config_class_name->$elt_name: '$class_overide_param' is deprecated, ",
            "Use 'class' instead."
        ]);
    }

    $legacy_logger->debug(
        "translate_id_class $elt_name output:",
        Data::Dumper->Dump( [$info], [qw/new_info/])
    ) if $legacy_logger->is_debug;
    return;
}

# internal: translate default information for id element
sub translate_id_default_info {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    $legacy_logger->debug(
        "translate_id_default_info $elt_name input:\n",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $warn = "$config_class_name->$elt_name: 'default' parameter for list or "
        . "hash element is deprecated. ";

    my $def_info = delete $info->{default};
    if ( ref($def_info) eq 'HASH' ) {
        $info->{default_with_init} = $def_info;
        $self->show_legacy_issue([ $warn, "Use default_with_init" ]);
    }
    elsif ( ref($def_info) eq 'ARRAY' ) {
        $info->{default_keys} = $def_info;
        $self->show_legacy_issue([ $warn, "Use default_keys" ]);
    }
    else {
        $info->{default_keys} = [$def_info];
        $self->show_legacy_issue([ $warn, "Use default_keys" ]);
    }

    $legacy_logger->debug( 
        "translate_id_default_info $elt_name output:",
        Data::Dumper->Dump( [$info], [qw/new_info/])
    ) if $legacy_logger->is_debug;
    return;
}

# internal: translate auto_create information for id element
sub translate_id_auto_create {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    $legacy_logger->debug(
        "translate_id_auto_create $elt_name input:",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $warn = "$config_class_name->$elt_name: 'auto_create' parameter for list or "
        . "hash element is deprecated. ";

    my $ac_info = delete $info->{auto_create};
    if ( $info->{type} eq 'hash' ) {
        $info->{auto_create_keys} =
            ref($ac_info) eq 'ARRAY' ? $ac_info : [$ac_info];
        $self->show_legacy_issue([ $warn, "Use auto_create_keys" ]);
    }
    elsif ( $info->{type} eq 'list' ) {
        $info->{auto_create_ids} = $ac_info;
        $self->show_legacy_issue([ $warn, "Use auto_create_ids" ]);
    }
    else {
        die "Unexpected element ($elt_name) type $info->{type} ", "for translate_id_auto_create";
    }

    $legacy_logger->debug(
        "translate_id_default_info $elt_name output:\n",
        Data::Dumper->Dump( [$info], [qw/new_info/] )
    ) if $legacy_logger->is_debug;
    return;
}

sub translate_id_min_max {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    foreach my $bad (qw/min max/) {
        next unless defined $info->{$bad};

        $legacy_logger->debug( "translate_id_min_max $elt_name $bad:")
            if $legacy_logger->is_debug;

        my $good = $bad . '_index';
        my $warn = "$config_class_name->$elt_name: '$bad' parameter for list or "
            . "hash element is deprecated. Use '$good'";

        $info->{$good} = delete $info->{$bad};
    }
    return;
}

sub translate_warped_node_info {
    my ( $self, $config_class_name, $elt_name, $type, $info ) = @_;

    $legacy_logger->debug(
        "translate_warped_node_info $elt_name input:\n",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    # type may not be defined when translating class snippet used to augment a class
    my $elt_type = $info->{type} ;
    foreach my $parm (qw/follow rules/) {
        next unless $info->{$parm};
        next if defined $elt_type and $elt_type ne 'warped_node';
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: using $parm parameter in "
            ."warped node is deprecated. $parm must be specified in a warp parameter."
        );
        $info->{warp}{$parm} = delete $info->{$parm};
    }

    $legacy_logger->debug(
        "translate_warped_node_info $elt_name output:\n",
        Data::Dumper->Dump( [$info], [qw/new_info/] )
    ) if $legacy_logger->is_debug;
    return;
}

# internal: translate warp information into 'boolean expr' => { ... }
sub translate_warp_info {
    my ( $self, $config_class_name, $elt_name, $type, $warp_info ) = @_;

    $legacy_logger->debug(
        "translate_warp_info $elt_name input:\n",
        Data::Dumper->Dump( [$warp_info], [qw/warp_info/] )
    ) if $legacy_logger->is_debug;

    my $follow = $self->translate_follow_arg( $config_class_name, $elt_name, $warp_info->{follow} );

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}
    my @warper_items = values %$follow;

    my $multi_follow = @warper_items > 1 ? 1 : 0;

    my $rules =
        $self->translate_rules_arg( $config_class_name, $elt_name, $type, \@warper_items,
        $warp_info->{rules} );

    $warp_info->{follow} = $follow;
    $warp_info->{rules}  = $rules;

    $legacy_logger->debug(
        "translate_warp_info $elt_name output:\n",
        Data::Dumper->Dump( [$warp_info], [qw/new_warp_info/] )
    ) if $legacy_logger->is_debug;
    return;
}

# internal
sub translate_multi_follow_legacy_rules {
    my ( $self, $config_class_name, $elt_name, $warper_items, $raw_rules ) = @_;
    my @rules;

    # we have more than one warper_items

    for ( my $r_idx = 0 ; $r_idx < $#$raw_rules ; $r_idx += 2 ) {
        my $key_set = $raw_rules->[$r_idx];
        my @keys = ref($key_set) ? @$key_set : ($key_set);

        # legacy: check the number of keys in the @rules set
        if ( @keys != @$warper_items and $key_set !~ /\$\w+/ ) {
            Config::Model::Exception::ModelDeclaration->throw( error => "Warp rule error in "
                    . "'$config_class_name->$elt_name'"
                    . ": Wrong nb of keys in set '@keys',"
                    . " Expected "
                    . scalar @$warper_items
                    . " keys" );
        }

        # legacy:
        # if a key of a rule (e.g. f1 or b1) is an array ref, all the
        # values passed in the array are considered as valid.
        # i.e. [ [ f1a, f1b] , b1 ] => { ... }
        # is equivalent to
        # [ f1a, b1 ] => { ... }, [  f1b , b1 ] => { ... }

        # now translate [ [ f1a, f1b] , b1 ] => { ... }
        # into "( $f1 eq f1a or $f1 eq f1b ) and $f2 eq b1)" => { ... }
        my @bool_expr;
        my $b_idx = 0;
        foreach my $key (@keys) {
            if ( ref $key ) {
                my @expr = map { "\$f$b_idx eq '$_'" } @$key;
                push @bool_expr, "(" . join( " or ", @expr ) . ")";
            }
            elsif ( $key !~ /\$\w+/ ) {
                push @bool_expr, "\$f$b_idx eq '$key'";
            }
            else {
                push @bool_expr, $key;
            }
            $b_idx++;
        }
        push @rules, join( ' and ', @bool_expr ), $raw_rules->[ $r_idx + 1 ];
    }
    return @rules;
}

sub translate_follow_arg {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $raw_follow        = shift;

    if ( ref($raw_follow) eq 'HASH' ) {

        # follow is { w1 => 'warp1', w2 => 'warp2'}
        return $raw_follow;
    }
    elsif ( ref($raw_follow) eq 'ARRAY' ) {

        # translate legacy follow arguments ['warp1','warp2',...]
        my $follow = {};
        my $idx    = 0;
        foreach ( @$raw_follow ) { $follow->{ 'f' . $idx++ } = $_ } ;
        return $follow;
    }
    elsif ( defined $raw_follow ) {

        # follow is a plain string
        return { f1 => $raw_follow };
    }
    else {
        return {};
    }
}

sub translate_rules_arg {
    my ( $self, $config_class_name, $elt_name, $type, $warper_items, $raw_rules ) = @_;

    my $multi_follow = @$warper_items > 1 ? 1 : 0;
    my $follow = @$warper_items;

    # $rules is either:
    # { f1 => { ... } }  (  may be [ f1 => { ... } ] ?? )
    # [ 'boolean expr' => { ... } ]
    # legacy:
    # [ f1, b1 ] => {..} ,[ f1,b2 ] => {...}, [f2,b1] => {...} ...
    # foo => {...} , bar => {...}
    my @rules;
    if ( ref($raw_rules) eq 'HASH' ) {

        # transform the hash { foo => { ...} }
        # into array ref [ '$f1 eq foo' => { ... } ]
        my $h = $raw_rules;
        @rules = $follow ? map { ( "\$f1 eq '$_'", $h->{$_} ) } keys %$h : keys %$h;
    }
    elsif ( ref($raw_rules) eq 'ARRAY' ) {
        if ($multi_follow) {
            push @rules,
                $self->translate_multi_follow_legacy_rules( $config_class_name, $elt_name,
                $warper_items, $raw_rules );
        }
        else {
            # now translate [ f1a, f1b]  => { ... }
            # into "$f1 eq f1a or $f1 eq f1b " => { ... }
            my @raw_rules = @{$raw_rules};
            for ( my $r_idx = 0 ; $r_idx < $#raw_rules ; $r_idx += 2 ) {
                my $key_set   = $raw_rules[$r_idx];
                my @keys      = ref($key_set) ? @$key_set : ($key_set);
                my @bool_expr = $follow ? map { /\$/ ? $_ : "\$f1 eq '$_'" } @keys : @keys;
                push @rules, join( ' or ', @bool_expr ), $raw_rules[ $r_idx + 1 ];
            }
        }
    }
    elsif ( defined $raw_rules ) {
        Config::Model::Exception::ModelDeclaration->throw(
                  error => "Warp rule error in element "
                . "'$config_class_name->$elt_name': "
                . "rules must be a hash ref. Got '$raw_rules'" );
    }

    for ( my $idx = 1 ; $idx < @rules ; $idx += 2 ) {
        next unless ( ref $rules[$idx] eq 'HASH' );    # other cases are illegal and trapped later
        $self->handle_experience_permission( $config_class_name, $rules[$idx] );
        next unless defined $type and $type eq 'leaf';
        $self->translate_legacy_builtin( $config_class_name, $rules[$idx], $rules[$idx] );
    }

    return \@rules;
}

sub translate_legacy_builtin {
    my ( $self, $config_class_name, $model, $normalized_model ) = @_;

    my $raw_builtin_default = delete $normalized_model->{built_in};
    return unless defined $raw_builtin_default;

    $legacy_logger->debug( 
        Data::Dumper->Dump( [$normalized_model], ['builtin to translate'] )
    ) if $legacy_logger->is_debug;

    $self->show_legacy_issue([ "$config_class_name: parameter 'built_in' is deprecated "
            . "in favor of 'upstream_default'" ]);

    $model->{upstream_default} = $raw_builtin_default;

    $legacy_logger->debug( Data::Dumper->Dump( [$model], ['translated_builtin'] )) 
        if $legacy_logger->is_debug;
    return;
}

sub translate_legacy_built_in_list {
    my ( $self, $config_class_name, $model, $normalized_model ) = @_;

    my $raw_builtin_default = delete $normalized_model->{built_in_list};
    return unless defined $raw_builtin_default;

    $legacy_logger->debug( 
        Data::Dumper->Dump( [$normalized_model], ['built_in_list to translate'] )
    ) if $legacy_logger->is_debug;

    $self->show_legacy_issue([ "$config_class_name: parameter 'built_in_list' is deprecated "
            . "in favor of 'upstream_default_list'" ]);

    $model->{upstream_default_list} = $raw_builtin_default;

    $legacy_logger->debug( Data::Dumper->Dump( [$model], ['translated_built_in_list'] ))
        if $legacy_logger->is_debug;
    return;
}

sub include_class {
    my $self         = shift;
    my $class_name   = shift || croak "include_class: undef includer";
    my $target_model = shift || die "include_class: undefined target_model";

    my $include_class = delete $target_model->{include};

    return () unless defined $include_class;

    my $include_after = delete $target_model->{include_after};

    my @includes = ref $include_class ? @$include_class : ($include_class);

    # use reverse because included classes are *inserted* in front
    # of the list (or inserted after $include_after
    foreach my $inc ( reverse @includes ) {
        $self->include_one_class( $class_name, $target_model, $inc, $include_after );
    }
    return;
}

sub include_one_class {
    my $self          = shift;
    my $class_name    = shift || croak "include_class: undef includer";
    my $target_model  = shift || croak "include_class: undefined target_model";
    my $include_class = shift || croak "include_class: undef include_class param";
    my $include_after = shift;

    get_logger('Model')->debug("class $class_name includes $include_class");

    if (    defined $include_class
        and defined $self->{included_class}{$class_name}{$include_class} ) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "Recursion error ? $include_class has "
                . "already been included by $class_name." );
    }
    $self->{included_class}{$class_name}{$include_class} = 1;

    # takes care of recursive include, because get_model will perform
    # includes (and normalization). Is already a dclone
    my $included_model = $self->get_model_clone($include_class);

    # now include element in element_list (special treatment because order is
    # important)
    my $target_list   = $target_model->{element_list};
    my $included_list = $included_model->{element_list};
    my $splice_idx    = 0;
    if ( defined $include_after and defined $included_model->{element} ) {
        my $idx = 0;
        my %elt_idx = map { ( $_, $idx++ ); } @$target_list;

        if ( not defined $elt_idx{$include_after} ) {
            my $msg =
                  "Unknown element for 'include_after': "
                . "$include_after, expected "
                . join( ' ', sort keys %elt_idx );
            Config::Model::Exception::ModelDeclaration->throw( error => $msg );
        }

        # + 1 because we splice *after* $include_after
        $splice_idx = $elt_idx{$include_after} + 1;
    }

    splice( @$target_list, $splice_idx, 0, @$included_list );
    get_logger('Model')->debug("class $class_name new elt list: @$target_list");

    # now actually include all elements
    my $target_element = $target_model->{element} ||= {};
    foreach my $included_elt (@$included_list) {
        if ( not defined $target_element->{$included_elt} ) {
            get_logger('Model')->debug("class $class_name includes elt $included_elt");
            $target_element->{$included_elt} = $included_model->{element}{$included_elt};
        }
        else {
            Config::Model::Exception::ModelDeclaration->throw(
                error => "Cannot clobber element '$included_elt' in $class_name"
                    . " (included from $include_class)" );
        }
    }
    get_logger('Model')->debug("class $class_name include $include_class done");
    return;
}

sub find_model_file_in_dir ($model_name, $model_path) {
    foreach my $ext (qw/yml yaml pl/) {
        my $sub_path = $model_name =~ s!::!/!rg;
        my $path_load_file = $model_path->child($sub_path . '.' . $ext);
        return $path_load_file if $path_load_file->exists;
    }
    return;
}

sub find_model_file_in_inc {
    my ($self, $model_name, $load_file) = @_;

    my $path_load_file ;

    if ($load_file and $load_file =~ m!^/! ) {
        # load_file is absolute, do not search in @INC
        $path_load_file = $load_file;
    } elsif ($self->model_dir and $self->model_dir =~ m!^/!) {
        # model_dir is absolute, do not search in @INC
        my $model_path = path($self->model_dir);
        $path_load_file = find_model_file_in_dir ($model_name, $model_path);
        Config::Model::Exception::ModelDeclaration->throw(
            error => "Cannot find $model_name file in $model_path"
        ) unless $path_load_file;
    }
    else {
        foreach my $inc_str (@INC) {
            my $inc_path = path($inc_str);
            if ($load_file) {
                $path_load_file = $inc_path->child($load_file);
            }
            else {
                my $sub_path = $model_name =~ s!::!/!rg;
                my $model_path = $inc_path->child($self->model_dir);
                foreach my $ext (qw/yml yaml pl/) {
                    $path_load_file = $model_path->child($sub_path . '.' . $ext);
                    last if $path_load_file->exists;
                }
            }
            last if $path_load_file->exists;
        }
    }

    Config::Model::Exception::ModelDeclaration->throw(
        error => "Cannot find $model_name file in \@INC"
    ) unless $path_load_file;

    $loader_logger->debug("model $model_name from file $path_load_file");

    return $path_load_file;
}

sub load_model_plugins {
    my ($self, @model_names) = @_;

    # look for additional model information
    my %model_graft_by_name;
    my %done;  # avoid loading twice the same snippet (where system version may clobber dev version)

    foreach my $inc_str (@INC) {
        foreach my $name ( @model_names ) {
            my $snippet_path = $name;
            $snippet_path =~ s/::/\//g;
            my $snippet_dir = path($inc_str)->absolute->child($self->model_dir)->child($snippet_path . '.d');
            $loader_logger->trace("looking for snippet in $snippet_dir");
            if ( $snippet_dir->is_dir ) {
                my $iter = $snippet_dir->iterator({ recurse => 1 });

                while ( my $snippet_file = $iter->() ) {
                    next unless $snippet_file =~ /\.pl$/;

                    # $snippet_file (Path::Tiny object) was
                    # constructed from @INC content (i.e. $inc_str)
                    # and contains an absolute path. Since
                    # _load_model_in_hash uses 'do' (which may search
                    # in @INC), the file path passed to
                    # _load_model_in_hash must be either absolute or
                    # relative to $inc_str
                    my $snippet_file_rel = $snippet_file->relative($inc_str);

                    my $done_key = $name . ':' . $snippet_file_rel;
                    next if $done{$done_key};
                    $loader_logger->info("Found snippet $snippet_file in $inc_str dir");
                    my $snippet_model = $self->_load_model_file($snippet_file);

                    $self->_merge_model_in_hash( \%model_graft_by_name, $snippet_model, $snippet_file_rel);
                    $done{$done_key} = 1;
                }
            }
        }
    }
    return %model_graft_by_name;
}

# load a model from file. See comments around raw_models attribute for explanations
sub load {
    my $self       = shift;
    my $model_name = shift;    # model name like Foo::Bar
    my $load_file  = shift;    # model file (override model name), used for tests

    $loader_logger->debug("called on model $model_name");
    my $path_load_file = $self->find_model_file_in_inc($model_name, $load_file);

    my %models_by_name;

    # Searches $load_file in @INC and returns an array containing the
    # names of the loaded classes
    my $model = $self->_load_model_file($path_load_file->absolute);
    my @loaded_classes = $self->_merge_model_in_hash( \%models_by_name, $model, $path_load_file );

    $self->store_raw_model( $model_name, dclone( \%models_by_name ) );

    foreach my $name ( keys %models_by_name ) {
        my $data = $self->normalize_class_parameters( $name, $models_by_name{$name} );
        $loader_logger->debug("Store normalized model $name");
        $self->store_normalized_model( $name, $data );
    }

    my %model_graft_by_name = $self->load_model_plugins(sort keys %models_by_name);

    # store snippet. May be used later
    foreach my $name (keys %model_graft_by_name) {
        # store snippet for later usage
        $loader_logger->trace("storing snippet for model $name");
        $self->add_snippet($model_graft_by_name{$name});
    }

    # check if a snippet is available for this class
    foreach my $snippet ( $self->all_snippets ) {
        my $class_to_merge = $snippet->{name};
        next unless $models_by_name{$class_to_merge};
        $self->augment_config_class_really( $class_to_merge, $snippet );
    }

    # return the list of classes found in $load_file. Respecting the order of the class
    # declaration is important for Config::Model::Itself so the class are written back
    # in the same order.
    return @loaded_classes;
}

# New subroutine "_load_model_in_hash" extracted - Fri Apr 12 17:29:56 2013.
#
sub _merge_model_in_hash {
    my ( $self, $hash_ref, $model, $load_file ) = @_;

    my @names;
    foreach my $config_class_info (@$model) {
        my %data =
              ref $config_class_info eq 'HASH'  ? %$config_class_info
            : ref $config_class_info eq 'ARRAY' ? @$config_class_info
            :   croak "load $load_file: config_class_info is not a ref";
        my $config_class_name = $data{name}
            or croak "load: missing config class name in $load_file";

        # check config class parameters and fill %model
        $hash_ref->{$config_class_name} = \%data;
        push @names, $config_class_name;
    }

    return @names;
}

sub _load_model_file {
    my ( $self, $load_file ) = @_;

    $loader_logger->info("load model $load_file");

    my $err_msg = '';
    # do searches @INC if the file path is not absolute
    my $model   = do $load_file;

    unless ($model) {
        if    ($@)                   { $err_msg = "couldn't parse $load_file: $@"; }
        elsif ( not defined $model ) { $err_msg = "couldn't do $load_file: $!" }
        else                         { $err_msg = "couldn't run $load_file"; }
    }
    elsif ( ref($model) ne 'ARRAY' ) {
        $model = [$model];
    }

    Config::Model::Exception::ModelDeclaration->throw( message => "load error: $err_msg" )
        if $err_msg;

    return $model;
}

sub augment_config_class {
    my ( $self, %augment_data ) = @_;

    # %args must contain existing class name to augment

    # plus other data to merge to raw model
    my $config_class_name = delete $augment_data{name}
        || croak "augment_config_class: missing class name";

    $self->augment_config_class_really( $config_class_name, \%augment_data );
    return;
}

sub augment_config_class_really {
    my ( $self, $config_class_name, $augment_data ) = @_;

    my $orig_model = $self->normalized_model($config_class_name);
    croak "unknown class to augment: $config_class_name" unless defined $orig_model;

    my $model_addendum = $self->normalize_class_parameters( $config_class_name, dclone($augment_data) );

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    my $new_model = $merge->merge( $orig_model, $model_addendum );

    # remove duplicates in element_list and accept_list while keeping order
    foreach my $list_name (qw/element_list accept_list/) {
        my %seen;
        my @newlist;
        foreach my $elt ( @{ $new_model->{$list_name} } ) {
            push @newlist, $elt unless $seen{$elt};
            $seen{$elt} = 1;
        }

        $new_model->{$list_name} = \@newlist;
    }

    $self->store_normalized_model( $config_class_name => $new_model );
    return;
}

sub model {
    my $self              = shift;
    my $config_class_name = shift
        || die "Model::get_model: missing config class name argument";

    $self->load($config_class_name)
        unless $self->normalized_model_exists($config_class_name);

    if ( not $self->model_defined($config_class_name) ) {
        $loader_logger->debug("creating model $config_class_name");

        my $model = $self->merge_included_class($config_class_name);
        $self->_store_model( $config_class_name, $model );
    }

    return $self->_get_model($config_class_name)
        || croak "get_model error: unknown config class name: $config_class_name";

}

sub get_model {
    my ($self,$model) = @_;
    carp "get_model is deprecated in favor of get_model_clone";
    return $self->get_model_clone($model);
}

sub get_model_clone {
    my ($self,$model) = @_;
    return dclone($self->model($model));
}

# internal
sub get_model_doc {
    my ( $self, $top_class_name, $done ) = @_;

    $done //= {};
    if ( not defined $self->normalized_model($top_class_name) ) {
        eval { $self->model($top_class_name); };
        if ($@) {
            my $e = $@;
            if ($e->isa('Config::Model::Exception::ModelDeclaration')) {
                Config::Model::Exception::Fatal->throw(
                    message => "Unknown configuration class : $top_class_name ($@)"
                );
            }
            else {
                $e->rethrow;
            }
        }
    }

    my @classes = ($top_class_name);
    my %result;

    while (@classes) {
        my $class_name = shift @classes;
        next if $done->{$class_name} ;

        my $c_model = $self->model($class_name)
            || croak "get_model_doc model error : unknown config class name: $class_name";

        my $full_name = "Config::Model::models::$class_name";

        my %see_also;

        my @pod = (

            # Pod::Weaver compatibility
            "# PODNAME: $full_name",
            "# ABSTRACT:  Configuration class " . $class_name, '',

            # assume utf8 for all docs
            "=encoding utf8", '',

            # plain old pod compatibility
            "=head1 NAME",                                     '',
            "$full_name - Configuration class " . $class_name, '',

            "=head1 DESCRIPTION",                             '',
            "Configuration classes used by L<Config::Model>", ''
        );

        my %legalese;

        my $i = 0;

        my $class_desc = $c_model->{class_description};
        push @pod, $class_desc, '' if defined $class_desc;

        my @elt = ( "=head1 Elements", '' );
        foreach my $elt_name ( @{ $c_model->{element_list} } ) {
            my $elt_info = $c_model->{element}{$elt_name};
            my $summary = $elt_info->{summary} || '';
            $summary &&= " - $summary";
            push @elt, "=head2 $elt_name$summary", '';
            push @elt, $self->get_element_description($elt_info), '';

            foreach ( $elt_info, $elt_info->{cargo} ) {
                if ( my $ccn = $_->{config_class_name} ) {
                    push @classes, $ccn;
                    $see_also{$ccn} = 1;
                }
                if ( my $migr = $_->{migrate_from} ) {
                    push @elt, $self->get_migrate_doc( $elt_name, 'is migrated with', $migr );
                }
                if ( my $migr = $_->{migrate_values_from} ) {
                    push @elt, "Note: $elt_name values are migrated from '$migr'", '';
                }
                if ( my $comp = $_->{compute} ) {
                    push @elt, $self->get_migrate_doc( $elt_name, 'is computed with', $comp );
                }
            }
        }

        foreach my $what (qw/author copyright license/) {
            my $item = $c_model->{$what};
            push @{ $legalese{$what} }, $item if $item;
        }

        my @end;
        foreach my $what (qw/author copyright license/) {
            next unless @{ $legalese{$what} || [] };
            push @end, "=head1 " . uc($what), '', '=over', '',
                ( map { ( "=item $_", '' ); } map { ref $_ ? @$_ : $_ } @{ $legalese{$what} } ),
                '', '=back', '';
        }

        my @see_also = (
            "=head1 SEE ALSO",
            '',
            "=over",
            '',
            "=item *",
            '',
            "L<cme>",
            '',
            ( map { ( "=item *", '', "L<Config::Model::models::$_>", '' ); } sort keys %see_also ),
            "=back",
            ''
        );

        $result{$full_name} = join( "\n", @pod, @elt, @see_also, @end, '=cut', '' ) . "\n";
        $done->{$class_name} = 1;
    }
    return \%result;
}

#
# New subroutine "get_migrate_doc" extracted - Tue Jun  5 13:31:20 2012.
#
sub get_migrate_doc {
    my ( $self, $elt_name, $desc, $migr ) = @_;

    my $mv    = $migr->{variables};
    my $mform = $migr->{formula};

    if ( $mform =~ /\n/) { $mform =~ s/^/ /mg; $mform = "\n\n$mform\n\n"; }
    else                 { $mform = "'C<$mform>' " }

    my $mdoc = "Note: $elt_name $desc ${mform}and with: \n\n=over\n\n=item *\n\n"
        . join( "\n\n=item *\n\n", map { qq!C<\$$_> => C<$mv->{$_}>! } sort keys %$mv );
    if ( my $rep = $migr->{replace} ) {
        $mdoc .= "\n\n=item *\n\n"
            . join( "\n\n=item *\n\n", map { qq!C<\$replace{$_}> => C<$rep->{$_}>! } sort keys %$rep );
    }
    $mdoc .= "\n\n=back\n\n";

    return ( $mdoc, '' );
}

sub get_element_description {
    my ( $self, $elt_info ) = @_;

    my $type  = $elt_info->{type};
    my $cargo = $elt_info->{cargo};
    my $vt    = $elt_info->{value_type};

    my $of         = '';
    my $cargo_type = $cargo->{type};
    my $cargo_vt   = $cargo->{value_type};
    $of = " of " . ( $cargo_vt or $cargo_type ) if defined $cargo_type;

    my $ccn = $elt_info->{config_class_name} || $cargo->{config_class_name};
    $of .= " of class L<$ccn|Config::Model::models::$ccn> " if $ccn;

    my $desc = $elt_info->{description} || '';
    if ($desc) {
        $desc .= '.' if $desc =~ /\w$/;
        $desc .= ' ' unless $desc =~ /\s$/;
    }

    if ( my $status = $elt_info->{status} ) {
        $desc .= 'B<' . ucfirst($status) . '> ';
    }

    my $info = $elt_info->{mandatory} ? 'Mandatory. ' : 'Optional. ';

    $info .= "Type " . ( $vt || $type ) . $of . '. ';

    foreach my $name (qw/choice/) {
        my $item = $elt_info->{$name};
        next unless defined $item;
        $info .= "$name: '" . join( "', '", @$item ) . "'. ";
    }

    my @default_info = ();
    # assemble in over item for string value_type
    foreach my $name (qw/default upstream_default/) {
        my $item = $elt_info->{$name};
        next unless defined $item;
        push @default_info, [$name, $item] ;
    }

    my $elt_help = $self->get_element_value_help($elt_info);

    # breaks pod if $info is multiline
    my $ret = $desc . "I< $info > ";

    if (@default_info) {
        $ret .= "\n\n=over 4\n\n";
        for ( @default_info) { $ret .= "=item $_->[0] value :\n\n$_->[1]\n\n"; }
        $ret .= "=back\n\n";
    }

    $ret.= $elt_help;
    return $ret;
}

sub get_element_value_help {
    my ( $self, $elt_info ) = @_;

    my $help = $elt_info->{help};
    return '' unless defined $help;

    my $help_text = "\n\nHere are some explanations on the possible values:\n\n=over\n\n";
    foreach my $v ( sort keys %$help ) {
        $help_text .= "=item '$v'\n\n$help->{$v}\n\n";
    }

    return $help_text . "=back\n\n";
}

sub generate_doc {
    my ( $self, $top_class_name, $dir_str, $done ) = @_;

    $done //= {} ;
    my $res = $self->get_model_doc($top_class_name, $done);

    if ( defined $dir_str and $dir_str ) {
        foreach my $class_name ( sort keys %$res ) {
            my $dir = path($dir_str);
            $dir->mkpath() unless $dir->exists;
            my $file_path = $class_name;
            $file_path =~ s!::!/!g;
            my $pl_file  = $dir->child("$file_path.pl");
            $pl_file->parent->mkpath unless $pl_file->parent->exists;
            my $pod_file = $dir->child("$file_path.pod");

            my $old = '';
            if ($pod_file->exists ) {
                $old = $pod_file->slurp_utf8;
            }
            if ( $old ne $res->{$class_name} ) {
                $pod_file->spew_utf8( $res->{$class_name} );
                say "Wrote documentation in $pod_file";
            }
        }
    }
    else {
        foreach my $class_name ( sort keys %$res ) {
            print "########## $class_name ############ \n\n";
            print $res->{$class_name};
        }
    }
    return;
}

sub get_element_model {
    my $self              = shift;
    my $config_class_name = shift
        || die "Model::get_element_model: missing config class name argument";
    my $element_name = shift
        || die "Model::get_element_model: missing element name argument";

    my $model = $self->model($config_class_name);

    my $element_m = $model->{element}{$element_name}
        || croak "get_element_model error: unknown element name: $element_name";

    return dclone($element_m);
}

# returns a hash ref containing the raw model, i.e. before expansion of
# multiple keys (i.e. [qw/a b c/] => ... )
# internal. For now ...
sub get_normalized_model {
    my $self              = shift;
    my $config_class_name = shift;

    $self->load($config_class_name)
        unless defined $self->normalized_model($config_class_name);

    my $normalized_model = $self->normalized_model($config_class_name)
        || croak "get_normalized_model error: unknown config class name: $config_class_name";

    return dclone($normalized_model);
}

sub get_element_name ($self, %args) {
    my $class = $args{class}
        || croak "get_element_name: missing 'class' parameter";

    if (delete $args{for}) {
        carp "get_element_name: 'for' parameter is deprecated";
    }

    my $model = $self->model($class);
    my @result;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt ( @{ $model->{element_list} } ) {
        my $elt_data = $model->{element}{$elt};
        my $l = $elt_data->{level} || get_default_property('level');
        push @result, $elt if $l ne 'hidden' ;
    }

    return wantarray ? @result : join( ' ', @result );
}

sub get_element_property ($self, %args) {
    my $elt = $args{element}
        || croak "get_element_property: missing 'element' parameter";
    my $prop = $args{property}
        || croak "get_element_property: missing 'property' parameter";
    my $class = $args{class}
        || croak "get_element_property:: missing 'class' parameter";

    my $model = $self->model($class);

    # must take into account 'accept' model parameter
    if ( not defined $model->{element}{$elt} ) {
        $logger->debug("test accept for class $class elt $elt prop $prop");
        foreach my $acc_re ( @{ $model->{accept_list} } ) {
            return $model->{accept}{$acc_re}{$prop} || get_default_property($prop)
                if $elt =~ /^$acc_re$/;
        }
    }

    return $self->model($class)->{element}{$elt}{$prop}
        || get_default_property($prop);
}

sub list_class_element {
    my $self = shift;
    my $pad = shift || '';

    my $res = '';
    foreach my $class_name ( $self->normalized_model_names ) {
        $res .= $self->list_one_class_element($class_name);
    }
    return $res;
}

sub list_one_class_element {
    my $self       = shift;
    my $class_name = shift;
    my $pad        = shift || '';

    my $res     = $pad . "Class: $class_name\n";
    my $c_model = $self->normalized_model($class_name);
    my $elts    = $c_model->{element_list};               # array ref

    return $res unless defined $elts and @$elts;

    foreach my $elt_name (@$elts) {
        my $type = $c_model->{element}{$elt_name}{type};
        $res .= $pad . "  - $elt_name ($type)\n";
    }
    return $res;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: a framework to validate, migrate and edit configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model - a framework to validate, migrate and edit configuration files

=head1 VERSION

version 2.155

=head1 SYNOPSIS

=head2 Perl program to use an existing model

 use Config::Model qw(cme);
 # load, modify and save popcon configuration file
 cme('popcon')->modify("PARTICIPATE=yes");

=head2 Command line to use an existing model

 # with App::Cme
 cme modify popcon 'PARTICIPATE=yes'

=head2 Perl program with a custom model

 use Config::Model;

 # create new Model object
 my $model = Config::Model->new() ; # Config::Model object

 # create config model. A more complex model should be stored in a
 # file in lib/Config/Model/models. Then, run cme as explained below
 $model ->create_config_class (
   name => "MiniModel",
   element => [ [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' }, ],
   rw_config => { backend => 'IniFile', auto_create => 1,
                  config_dir => '.', file => 'mini.ini',
                }
 ) ;

 # create instance (Config::Model::Instance object)
 my $instance = $model->instance (root_class_name => 'MiniModel');

 # get configuration tree root
 my $cfg_root = $instance -> config_root ; # C::M:Node object

 # load some dummy data
 $cfg_root -> load("bar=BARV foo=FOOV baz=BAZV") ;

 # write new ini file
 $instance -> write_back;

 # now look for new mini.ini file un current directory

=head2 Create a new model file and use it

 $ mkdir -p lib/Config/Model/models/
 $ echo "[ { name => 'MiniModel', \
             element => [ [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' }, ], \
             rw_config => { backend => 'IniFile', auto_create => 1, \
                            config_dir => '.', file => 'mini.ini', \
                          } \
           } \
         ] ; " > lib/Config/Model/models/MiniModel.pl
 # require App::Cme
 $ cme modify -try MiniModel -dev bar=BARV foo=FOOV baz=BAZV
 $ cat mini.ini

Note that model creation is easier running C<cme meta edit> with
L<App::Cme> and L<Config::Model::Itself>.

=head1 DESCRIPTION

Config::Model enables a project developer to provide an interactive
configuration editor (graphical, curses based or plain terminal) to
users.

To provide these tools, Config::Model needs:

=over

=item *

A description of the structure and constraints of the project's configuration
(fear not, a GUI is available with L<App::Cme>)

=item *

A module to read and write configuration data (aka a backend class).

=back

With the elements above, Config::Model generates interactive
configuration editors (with integrated help and data validation).
These editors can be graphical (with L<Config::Model::TkUI>), curses
based (with L<Config::Model::CursesUI>) or based on ReadLine.

Smaller models targeted for configuration upgrades can also be created:

=over

=item *

only upgrade and migration specifications are required

=item *

unknown parameters can be accepted

=back

A command line is provided to perform configuration upgrade with a
single command.

=head2 How does this work ?

Using this project, a typical configuration editor/validator/upgrader
is made of 3 parts :

  GUI <--------> |---------------|
  CursesUI <---> | |---------|   |
                 | | Model   |   |
  ShellUI <----> | |---------|   |<-----read-backend------- |-------------|
                 |               |----write-backend-------> | config file |
  FuseUI <-----> | Config::Model |                          |-------------|
                 |---------------|

=over

=item 1.

A reader and writer that parse the configuration file and transform its data
into a tree representation within Config::Model. The values contained in this
configuration tree can be written back in the configuration file(s).

=item 2.

A validation engine which is in charge of validating the content and
structure of configuration stored in the configuration tree. This
validation engine follows the structure and constraint declared in
a configuration model. This model is a kind of schema for the
configuration tree.

=item 3.

A user interface to modify the content of the configuration tree. A
modification is validated immediately by the validation engine.

=back

The important part is the configuration model used by the validation
engine. This model can be created or modified with a graphical editor
(Config::Model::Iself).

=head1 Question you may ask yourself

=head2 Don't we already have some configuration validation tools ?

You're probably thinking of tools like webmin. Yes, these tools exist
and work fine, but they have their set of drawbacks.

Usually, the validation of configuration data is done with a script
which performs semantic validation and often ends up being quite
complex (e.g. 2500 lines for Debian's xserver-xorg.config script which
handles C<xorg.conf> file).

In most cases, the configuration model is expressed in instructions
(whatever programming language is used) and interspersed with a lot of
processing to handle the actual configuration data.

=head2 What's the advantage of this project ?

Config::Model projects provide a way to get a validation engine where
the configuration model is completely separated from the actual
processing instructions.

A configuration model can be created and modified with the graphical
interface provide by L<Config::Model::Itself>. The model is saved in a
declarative form (currently, a Perl data structure). Such a model is
easier to maintain than a lot of code.

The model specifies:

=over

=item *

The structure of the configuration data (which can be queried by
generic user interfaces)

=item *

The properties of each element (boundaries check, integer or string,
enum like type, default value ...)

=item *

The targeted audience (beginner, advanced, master)

=item *

The on-line help

=back

So, in the end:

=over

=item *

Maintenance and evolution of the configuration content is easier

=item *

User sees a *common* interface for *all* programs using this
project.

=item *

Upgrade of configuration data is easier and sanity check is
performed during the upgrade.

=item *

Audit of configuration is possible to check what was modified by the
user compared to default values

=back

=head2 What about the user interface ?

L<Config::Model> interface can be:

=over

=item *

a shell-like interface (plain or based on Term::ReadLine).

=item *

Graphical with L<Config::Model::TkUI> (Perl/Tk interface).

=item *

based on curses with L<Config::Model::CursesUI>. This interface can be
handy if your X server is down.

=item *

Through a virtual file system where every configuration parameter is mapped to a file.
(Linux only)

=back

All these interfaces are generated from the configuration model.

And configuration model can be created or modified with a graphical
user interface (with C<cme meta edit> once L<Config::Model::Itself> is
installed)

=head2 What about configuration data storage ?

Since the syntax of configuration files vary wildly form one application
to another, people who want to use this framework may have to
provide a dedicated parser/writer.

To help with this task, this project provides writer/parsers for common
format: INI style file and perl file. With the additional
Config::Model::Backend::Augeas, Augeas library can be used to read and
write some configuration files. See http://augeas.net for more
details.

=head2 Is there an example of a configuration model ?

The "example" directory contains a configuration model example for
C</etc/fstab> file. This example includes a small program that use
this model to show some ways to extract configuration information.

=head1 Mailing lists

For more question, please send a mail to:

 config-model-users at lists.sourceforge.net

=head1 Suggested reads to start

=head2 Beginners

=over

=item *

L<Config::Model::Manual::ModelCreationIntroduction>

=item *

L<Config::Model::Cookbook::CreateModelFromDoc>

=back

=head2 Advanced

=over

=item *

L<Config::Model::models::Itself::Class>: This doc and its siblings
describes all parameters available to create a model. These are the
parameters available in the GUI launched by C<cme meta edit> command.

=item *

L<Config::Model::Manual::ModelCreationAdvanced>

=back

=head2 Masters

use the source, Luke

=head1 STOP

The documentation below is quite detailed and is more a reference doc regarding
C<Config::Model> class.

For an introduction to model creation, please check:
L<Config::Model::Manual::ModelCreationIntroduction>

=head1 Storage backend, configuration reader and writer

See L<Config::Model::BackendMgr> for details

=head1 Validation engine

C<Config::Model> provides a way to get a validation engine from a set
of rules. This set of rules is called the configuration model.

=head1 User interface

The user interface uses some parts of the API to set and get
configuration values. More importantly, a generic user interface
needs to analyze the configuration model to be able to generate at
run-time relevant configuration screens.

A command line interface is provided in this module. Curses and Tk
interfaces are provided by L<Config::Model::CursesUI> and
L<Config::Model::TkUI>.

=head1 Constructor

 my $model = Config::Model -> new ;

creates an object to host your model.

=head2 Constructor parameters

=over

=item log_level

Specify minimal log level. Default is C<WARN>. Can be C<INFO>,
C<DEBUG> or C<TRACE> to get more logs. Can also be C<ERROR> to get
less traces.

This parameter is used to override the log level specified in log
configuration file.

=back

=head1 Configuration Model

To validate a configuration tree, we must create a configuration model
that defines all the properties of the validation engine you want to
create.

The configuration model is expressed in a declarative form (i.e. a
Perl data structure which should be easier to maintain than a lot of
code)

Each configuration class may contain a set of:

=over

=item *

node elements that refer to another configuration class

=item *

value elements that contain actual configuration data

=item *

list or hash elements that also contain several node or value elements

=back

The structure of your configuration tree is shaped by the a set of
configuration classes that are used in node elements,

The structure of the configuration data must be based on a tree
structure. This structure has several advantages:

=over

=item *

Unique path to get to a node or a leaf.

=item *

Simpler exploration and query

=item *

Simple hierarchy. Deletion of configuration items is simpler to grasp:
when you cut a branch, all the leaves attached to that branch go down.

=back

But using a tree has also some drawbacks:

=over 4

=item *

A complex configuration cannot be mapped on a tree.  Some more
relation between nodes and leaves must be added.

=item *

A configuration may actually be structured as a graph instead as a tree (for
instance, any configuration that maps a service to a
resource). The graph relation must be decomposed in a tree with
special I<reference> relations that complete the tree to form a graph.
See L<Config::Model::Value/Value Reference>

=back

Note: a configuration tree is a tree of objects. The model is declared
with classes. The classes themselves have relations that closely match
the relation of the object of the configuration tree. But the class
need not to be declared in a tree structure (always better to reuse
classes). But they must be declared as a DAG (directed acyclic graph).
See also
L<Directed acyclic graph on Wikipedia|http://en.wikipedia.org/wiki/Directed_acyclic_graph">More on DAGs>

Each configuration class declaration specifies:

=over

=item *

The C<name> of the class (mandatory)

=item *

A C<class_description> used in user interfaces (optional)

=item *

Optional include specification to avoid duplicate declaration of elements.

=item *

The class elements

=back

Each element specifies:

=over

=item *

Most importantly, the type of the element (mostly C<leaf>, or C<node>)

=item *

The properties of each element (boundaries, check, integer or string,
enum like type ...)

=item *

The default values of parameters (if any)

=item *

Whether the parameter is mandatory

=item *

Targeted audience (beginner, advance, master), i.e. the level of
expertise required to tinker a parameter (to hide expert parameters
from newbie eyes)

=item *

On-line help (for each parameter or value of parameter)

=back

See L<Config::Model::Node> for details on how to declare a
configuration class.

Example:

 $ cat lib/Config/Model/models/Xorg.pl
 [
   {
     name => 'Xorg',
     class_description => 'Top level Xorg configuration.',
     include => [ 'Xorg::ConfigDir'],
     element => [
                 Files => {
                           type => 'node',
                           description => 'File pathnames',
                           config_class_name => 'Xorg::Files'
                          },
                 # snip
                ]
   },
   {
     name => 'Xorg::DRI',
     element => [
                 Mode => {
                          type => 'leaf',
                          value_type => 'uniline',
                          description => 'DRI mode, usually set to 0666'
                         }
                ]
   }
 ];

=head1 Configuration instance methods

A configuration instance is created from a model and is the starting
point of a configuration tree.

=head2 instance

An instance must be created with a model name (using the root class
name) or an application name (as shown by "L<cme> C<list>" command).

For example:

 my $model = Config::Model->new() ;
 $model->instance( application => 'approx');

Or:

 my $model = Config::Model->new() ;
 # note that the model class is slightly different compared to
 # application name
 $model->instance( root_class_name => 'Approx');

A custom configuration class can also be used with C<root_class_name> parameter:

 my $model = Config::Model->new() ;
 # create_config_class is described below
 $model ->create_config_class (
   name => "SomeRootClass",
   element => [ ...  ]
 ) ;

 # instance name is 'default'
 my $inst = $model->instance (root_class_name => 'SomeRootClass');

You can create several separated instances from a model using
C<name> option:

 # instance name is 'default'
 my $inst = $model->instance (
   root_class_name => 'SomeRootClass',
   name            => 'test1'
 );

Usually, model files are loaded automatically using a path matching
C<root_class_name> (e.g. configuration class C<Foo::Bar> is stored in
C<Foo/Bar.pl>. You can choose to specify the file containing
the model with C<model_file> parameter. This is mostly useful for
tests.

The C<instance> method can also retrieve an instance that has already
been created:

 my $inst = $model->instance( name => 'test1' );

=head2 get_instance

Retrieve an existing instance using its name.

 my $inst = $model->get_instance('test1' );

=head2 has_instance

Check if an instance name already exists

  my $maybe = $model->has_instance('test1');

=head2 cme

This method is syntactic sugar for short program. It creates a new
C<Config::Model> object and returns a new instance.

C<cme> arguments are passed to L</instance> method, except
C<force-load>.

Like L<cme> command, C<cme> functions accepts C<force-load>
parameters. When this argument is true, the instance is created with
C<<check => 'no'>>. Hence bad values are stored in C<cme> and must be
corrected before saving back the data.

=head1 Configuration class

A configuration class is made of series of elements which are detailed
in L<Config::Model::Node>.

Whatever its type (node, leaf,... ), each element of a node has
several other properties:

=over

=item level

Level is C<important>, C<normal> or C<hidden>.

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements are shown to the user no
matter what. C<hidden> elements are well, hidden. Their purpose is
explained with the I<warp> notion.

=item status

Status is C<obsolete>, C<deprecated> or C<standard> (default).

Using a deprecated element raises a warning. Using an obsolete
element raises an exception.

=item description

Description of the element. This description is used while
generating user interfaces.

=item summary

Summary of the element. This description is used while generating
a user interfaces and may be used in comments when writing the
configuration file.

=item class_description

Description of the configuration class. This description is used
while generating user interfaces.

=item generated_by

Mention with a descriptive string if this class was generated by a
program.  This parameter is currently reserved for
L<Config::Model::Itself> model editor.

=item include

Include element description from another class.

  include => 'AnotherClass' ,

or

  include => [qw/ClassOne ClassTwo/]

In a configuration class, the order of the element is important. For
instance if C<foo> is warped by C<bar>, you must declare C<bar>
element before C<foo>.

When including another class, you may wish to insert the included
elements after a specific element of your including class:

  # say AnotherClass contains element xyz
  include => 'AnotherClass' ,
  include_after => "foo" ,
  element => [ bar => ... , foo => ... , baz => ... ]

Now the element of your class are:

  ( bar , foo , xyz , baz )

Note that include may not clobber an existing element.

=item include_backend

Include read/write specification from another class.

  include_backend => 'AnotherClass' ,

or

  include_backend => [qw/ClassOne ClassTwo/]

=back

Note that include may not clobber an existing read/write specification.

=head2 create_config_class

This method creates configuration classes. The parameters are
described above and are forwarded to L<Config::Model::Node>
constructor. See
L<Config::Model::Node/"Configuration class declaration">
for more details on configuration class parameters.

Example:

  my $model = Config::Model -> new ;

  $model->create_config_class
  (
   config_class_name => 'SomeRootClass',
   description       => [ X => 'X-ray' ],
   level             => [ 'tree_macro' => 'important' ] ,
   class_description => "SomeRootClass description",
   element           => [ ... ]
  ) ;

For convenience, C<level> and C<description> parameters
can also be declared within the element declaration:

  $model->create_config_class
  (
   config_class_name => 'SomeRootClass',
   class_description => "SomeRootClass description",
   'element'
   => [
        tree_macro => { level => 'important'},
        X          => { description => 'X-ray', } ,
      ]
  ) ;

=head1 Load predeclared model

You can also load predeclared model.

=head2 load( <model_name> )

This method opens the model directory and execute a C<.pl>
file containing the model declaration,

This perl file must return an array ref to declare models. E.g.:

 [
  [
   name => 'Class_1',
   element => [ ... ]
  ],
  [
   name => 'Class_2',
   element => [ ... ]
  ]
 ];

do not put C<1;> at the end or C<load> will not work

When a model name contain a C<::> (e.g C<Foo::Bar>), C<load> looks for
a file named C<Foo/Bar.pl>.

This method also searches in C<Foo/Bar.d> directory for additional model information.
Model snippet found there are loaded with L<augment_config_class>.

Returns a list containing the names of the loaded classes. For instance, if
C<Foo/Bar.pl> contains a model for C<Foo::Bar> and C<Foo::Bar2>, C<load>
returns C<( 'Foo::Bar' , 'Foo::Bar2' )>.

=head2 augment_config_class (name => '...', class_data )

Enhance the feature of a configuration class. This method uses the same parameters
as L</create_config_class>. See
L<Config::Model::Manual::ModelCreationAdvanced/"Model Plugin">
for more details on creating model plugins.

=head1 Model query

=head2 model

Returns a hash containing the model declaration of the passed model
name. Do not modify the content of the returned data structure.

 my $cloned = $model->model('Foo');

=head2 get_model_clone

Like C<model>, returns a hash containing the model declaration of the passed model
name, this time in a deep clone of the data structure.

 my $cloned = $model->get_model_clone('Foo');

=head2 generate_doc ( top_class_name , directory , [ \%done ] )

Generate POD document for configuration class top_class_name and all
classes used by top_class_name, and write them in specified directory.

C<\%done> is an optional reference to a hash used to avoid writing
twice the same documentation when this method is called several times.

=head2 get_element_model( config_class_name , element)

Return a hash containing the model declaration for the specified class
and element.

=head2 get_element_name( class => Foo )

Get all names of the elements of class C<Foo>.

=head2 get_element_property

Returns the property of an element from the model.

Parameters are:

=over

=item class

=item element

=item property

=back

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=head1 Error handling

Errors are handled with an exception mechanism.

When a strongly typed Value object gets an authorized value, it raises
an exception. If this exception is not caught, the programs exits.

See L<Config::Model::Exception|Config::Model::Exception> for details on
the various exception classes provided with C<Config::Model>.

=head1 Logging

See L<cme/Logging>

=head2 initialize_log4perl

This method can be called to load L<Log::Log4perl> configuration from
C<~/.log4config-model>, or from C</etc/log4config-model.conf> files or from
L<default configuration|https://github.com/dod38fr/config-model/blob/master/lib/Config/Model/log4perl.conf>.

Accepts C<verbose> parameter with a list of log classes that are added
to the log4perl configuration read above.

For instance, with C<< verbose => 'Loader' >>, log4perl is initialised with

 log4perl.logger.Verbose.Loader = INFO, PlainMsgOnScreen

Likewise, with C<< verbose => [ 'Loader', 'Foo' ] >>,
log4perl is initialised with:

 log4perl.logger.Verbose.Loader = INFO, PlainMsgOnScreen
 log4perl.logger.Verbose.Foo    = INFO, PlainMsgOnScreen

Currently, this module supports only C<Loader> as verbose parameters.

=head1 BUGS

Given Murphy's law, the author is fairly confident that you will find
bugs or miss some features. Please report them to
https://github.com/dod38fr/config-model/issues
The author will be notified, and then you'll automatically be
notified of progress on your bug.

=head1 FEEDBACK

Feedback from users are highly desired. If you find this module useful, please
share your use cases, success stories with the author or with the config-model-
users mailing list.

=head1 PROJECT FOUNDER

Dominique Dumont, "ddumont@cpan.org"

=head1 CREDITS

Contributors to this project are listed in alphabetical order:

  Harley Pig

  Ilya Arosov

  Jose Luis Perez Diez

  Krzysztof Tyszecki

  Mathieu Arnold

  Mohammad S Anwar

  Topi Miettinen

Many thanks for your help

=head1 SEE ALSO

L<Config::Model::Instance>,

L<https://github.com/dod38fr/config-model/wiki>

L<https://github.com/dod38fr/config-model/wiki/Creating-models>

=head2 Model elements

The arrow shows inheritance between classes

=over

=item *

L<Config::Model::Node> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::HashId> <- L<Config::Model::AnyId> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::ListId> <- L<Config::Model::AnyId> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::Value> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::CheckList> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::WarpedNode> <- L<Config::Model::AnyThing>

=back

=head2 command line

L<cme>.

=head2 Read and write backends

=over

=item *

L<Config::Model::Backend::Fstab> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::IniFile> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::PlainFile> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::ShellVar> <- L<Config::Model::Backend::Any>

=back

=head2 Model utilities

=over

=item *

L<Config::Model::Annotation>

=item *

L<Config::Model::BackendMgr>: Used by C<Config::Model::Node> object

=item *

L<Config::Model::Describe>

=item *

L<Config::Model::Dumper>

=item *

L<Config::Model::DumpAsData>

=item *

L<Config::Model::IdElementReference>

=item *

L<Config::Model::Iterator>

=item *

L<Config::Model::Loader>

=item *

L<Config::Model::ObjTreeScanner>

=item *

L<Config::Model::Report>

=item *

L<Config::Model::Searcher>: Search element in configuration model.

=item *

L<Config::Model::SimpleUI>

=item *

L<Config::Model::TreeSearcher>: Search string or regexp in configuration tree.

=item *

L<Config::Model::TermUI>

=item *

L<Config::Model::Iterator>

=item *

L<Config::Model::ValueComputer>

=item *

L<Config::Model::Warper>

=back

=head2 Test framework

=over

=item *

L<Config::Model::Tester>

=back

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Config-Model>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model>

  git clone git://github.com/dod38fr/config-model.git

=cut
