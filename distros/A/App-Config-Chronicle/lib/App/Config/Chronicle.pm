package App::Config::Chronicle;
# ABSTRACT: Provides Data::Chronicle-backed configuration storage

use strict;
use warnings;
use Time::HiRes qw(time);

=head1 NAME

App::Config::Chronicle - An OO configuration module which can be changed and stored into chronicle database.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    my $app_config = App::Config::Chronicle->new;

=head1 DESCRIPTION

This module parses configuration files and provides interface to access
configuration information.

=head1 FILE FORMAT

The configuration file is a YAML file. Here is an example:

    system:
      description: "Various parameters determining core application functionality"
      isa: section
      contains:
        email:
          description: "Dummy email address"
          isa: Str
          default: "dummy@mail.com"
          global: 1
        admins:
          description: "Are we on Production?"
          isa: ArrayRef
          default: []

Every attribute is very intuitive. If an item is global, you can change its value and the value will be stored into chronicle database by calling the method C<save_dynamic>.

=head1 SUBROUTINES/METHODS

=cut

use Moose;
use namespace::autoclean;
use YAML::XS qw(LoadFile);

use App::Config::Chronicle::Attribute::Section;
use App::Config::Chronicle::Attribute::Global;
use Data::Hash::DotNotation;

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head2 definition_yml

The YAML file that store the configuration

=cut

has definition_yml => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 chronicle_reader

The chronicle store that configurations can be fetch from it. It should be an instance of L<Data::Chronicle::Reader>.
But user is free to implement any storage backend he wants if it is implemented with a 'get' method.

=cut

has chronicle_reader => (
    is       => 'ro',
    isa      => 'Data::Chronicle::Reader',
    required => 1,
);

=head2 chronicle_writer

The chronicle store that updated configurations can be stored into it. It should be an instance of L<Data::Chronicle::Writer>.
But user is free to implement any storage backend he wants if it is implemented with a 'set' method.

=cut

has chronicle_writer => (
    is       => 'ro',
    isa      => 'Data::Chronicle::Writer',
    required => 1,
);

has setting_namespace => (
    is      => 'ro',
    isa     => 'Str',
    default => 'app_settings',
);
has setting_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'settings1',
);

=head2 refresh_interval

How much time (in seconds) should pass between L<check_for_update> invocations until
it actually will do (a bit heavy) lookup for settings in redis.

Default value is 10 seconds

=cut

has refresh_interval => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 10,
);

has _updated_at => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 0,
);

# definitions database
has _defdb => (
    is      => 'rw',
    lazy    => 1,
    default => sub { LoadFile(shift->definition_yml) },
);

has 'data_set' => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_class {
    my $self = shift;
    $self->_create_attributes($self->_defdb, $self);
    return;
}

sub _create_attributes {
    my $self               = shift;
    my $definitions        = shift;
    my $containing_section = shift;

    $containing_section->meta->make_mutable;
    foreach my $definition_key (keys %{$definitions}) {
        $self->_validate_key($definition_key, $containing_section);
        my $definition = $definitions->{$definition_key};
        if ($definition->{isa} eq 'section') {
            $self->_create_section($containing_section, $definition_key, $definition);
            $self->_create_attributes($definition->{contains}, $containing_section->$definition_key);
        } elsif ($definition->{global}) {
            $self->_create_global_attribute($containing_section, $definition_key, $definition);
        } else {
            $self->_create_generic_attribute($containing_section, $definition_key, $definition);
        }
    }
    $containing_section->meta->make_immutable;

    return;
}

sub _create_section {
    my $self       = shift;
    my $section    = shift;
    my $name       = shift;
    my $definition = shift;

    my $writer      = "_$name";
    my $path_config = {};
    if ($section->isa('App::Config::Chronicle::Attribute::Section')) {
        $path_config = {parent_path => $section->path};
    }

    my $new_section = Moose::Meta::Class->create_anon_class(superclasses => ['App::Config::Chronicle::Attribute::Section'])->new_object(
        name       => $name,
        definition => $definition,
        data_set   => {},
        %$path_config
    );

    $section->meta->add_attribute(
        $name,
        is            => 'ro',
        isa           => 'App::Config::Chronicle::Attribute::Section',
        writer        => $writer,
        documentation => $definition->{description},
    );
    $section->$writer($new_section);

    #Force Moose Validation
    $section->$name;

    return;
}

sub _create_global_attribute {
    my $self       = shift;
    my $section    = shift;
    my $name       = shift;
    my $definition = shift;

    my $attribute = $self->_add_attribute('App::Config::Chronicle::Attribute::Global', $section, $name, $definition);
    $self->_add_dynamic_setting_info($attribute->path, $definition);

    return;
}

sub _create_generic_attribute {
    my $self       = shift;
    my $section    = shift;
    my $name       = shift;
    my $definition = shift;

    $self->_add_attribute('App::Config::Chronicle::Attribute', $section, $name, $definition);

    return;
}

sub _add_attribute {
    my $self       = shift;
    my $attr_class = shift;
    my $section    = shift;
    my $name       = shift;
    my $definition = shift;

    my $fake_name = "a_$name";
    my $writer    = "_$fake_name";

    my $attribute = $attr_class->new(
        name        => $name,
        definition  => $definition,
        parent_path => $section->path,
        data_set    => $self->data_set,
    )->build;

    $section->meta->add_attribute(
        $fake_name,
        is      => 'ro',
        handles => {
            $name          => 'value',
            'has_' . $name => 'has_value',
        },
        documentation => $definition->{description},
        writer        => $writer,
    );

    $section->$writer($attribute);

    return $attribute;
}

sub _validate_key {
    my $self    = shift;
    my $key     = shift;
    my $section = shift;

    if (grep { $key eq $_ } qw(path parent_path name definition version data_set check_for_update save_dynamic refresh_interval)) {
        die "Variable with name $key found under "
            . $section->path
            . ".\n$key is an internally used variable and cannot be reused, please use a different name";
    }

    return;
}

=head2 check_for_update

check and load updated settings from chronicle db

=cut

sub check_for_update {
    my $self = shift;

    # do fast cached check
    my $now         = time;
    my $prev_update = $self->_updated_at;
    return if ($now - $prev_update < $self->refresh_interval);

    $self->_updated_at($now);
    # do check in Redis
    my $data_set = $self->data_set;
    my $app_settings = $self->chronicle_reader->get($self->setting_namespace, $self->setting_name);

    my $db_version;
    if ($app_settings and $data_set) {
        $db_version = $app_settings->{_rev};
        unless ($data_set->{version} and $db_version and $db_version eq $data_set->{version}) {
            # refresh all
            $self->_add_app_setttings($data_set, $app_settings);
        }
    }

    return $db_version;
}

=head2 save_dynamic

Save synamic settings into chronicle db

=cut

sub save_dynamic {
    my $self = shift;
    my $settings = $self->chronicle_reader->get($self->setting_namespace, $self->setting_name) || {};

    #Cleanup globals
    my $global = Data::Hash::DotNotation->new();
    foreach my $key (keys %{$self->dynamic_settings_info->{global}}) {
        if ($self->data_set->{global}->key_exists($key)) {
            $global->set($key, $self->data_set->{global}->get($key));
        }
    }

    $settings->{global} = $global->data;
    $settings->{_rev}   = time;
    $self->chronicle_writer->set($self->setting_namespace, $self->setting_name, $settings, Date::Utility->new);

    return 1;
}

=head2 current_revision

loads setting from chronicle reader and returns the last revision and drops them

=cut

sub current_revision {
    my $self = shift;
    my $settings = $self->chronicle_reader->get($self->setting_namespace, $self->setting_name);
    return $settings->{_rev};
}

sub _build_data_set {
    my $self = shift;

    # relatively small yaml, so loading it shouldn't be expensive.
    my $data_set->{app_config} = Data::Hash::DotNotation->new(data => {});

    $self->_add_app_setttings($data_set, $self->chronicle_reader->get($self->setting_namespace, $self->setting_name) || {});

    return $data_set;
}

sub _add_app_setttings {
    my $self         = shift;
    my $data_set     = shift;
    my $app_settings = shift;

    if ($app_settings) {
        $data_set->{global} = Data::Hash::DotNotation->new(data => $app_settings->{global});
        $data_set->{version} = $app_settings->{_rev};
    }

    return;
}

has dynamic_settings_info => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub _add_dynamic_setting_info {
    my $self       = shift;
    my $path       = shift;
    my $definition = shift;

    $self->dynamic_settings_info = {} unless ($self->dynamic_settings_info);
    $self->dynamic_settings_info->{global} = {} unless ($self->dynamic_settings_info->{global});

    $self->dynamic_settings_info->{global}->{$path} = {
        type        => $definition->{isa},
        default     => $definition->{default},
        description => $definition->{description}};

    return;
}

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    $self->_build_class;

    return;
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Binary.com, C<< <binary at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-config at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Config>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Config::Chronicle


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Config>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Config>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Config/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

1;    # End of App::Config::Chronicle
