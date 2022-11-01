package App::Config::Chronicle;
# ABSTRACT: Provides Data::Chronicle-backed configuration storage

use strict;
use warnings;
use Time::HiRes qw(time);
use List::Util  qw(any pairs pairmap);

=head1 NAME

App::Config::Chronicle - An OO configuration module which can be changed and stored into chronicle database.

=cut

our $VERSION = '0.07';

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
        refresh:
          description: "System refresh rate"
          isa: Num
          default: 10
          global: 1
        admins:
          description: "Are we on Production?"
          isa: ArrayRef
          default: []

Every attribute is very intuitive. If an item is global, you can change its value and the value will be stored into chronicle database by calling the method C<save_dynamic>.

=head1 SUBROUTINES/METHODS (LEGACY)

=cut

use Moose;
use namespace::autoclean;
use YAML::XS qw(LoadFile);

use App::Config::Chronicle::Attribute::Section;
use App::Config::Chronicle::Attribute::Global;
use Data::Hash::DotNotation;

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;
use Data::Chronicle::Subscriber;

=head2 REDIS_HISTORY_TTL

The maximum length of time (in seconds) that a cached history entry will stay in Redis.

=cut

use constant REDIS_HISTORY_TTL => 7 * 86400;    # 7 days

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
    is  => 'rw',
    isa => 'Data::Chronicle::Writer',
);

=head2 chronicle_subscriber

The chronicle connection that can notify via callbacks when particular configuration items have a new value set. It should be an instance of L<Data::Chronicle::Subscriber>.

=cut

has chronicle_subscriber => (
    is  => 'ro',
    isa => 'Data::Chronicle::Subscriber'
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

Checks at most every C<refresh_interval> unless forced with
a truthy first argument

=cut

sub check_for_update {
    my ($self, $force) = @_;

    return unless $force or $self->_has_refresh_interval_passed();
    $self->_updated_at(Time::HiRes::time());

    # do check in Redis
    my $data_set     = $self->data_set;
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

Save dynamic settings into chronicle db

=cut

sub save_dynamic {
    my $self = shift;
    my ($package, $filename, $line) = caller;
    warnings::warnif deprecated => "Deprecated call used (save_dynamic). Called from package: $package | file: $filename | line: $line";
    return $self->_save_dynamic();
}

sub _save_dynamic {
    my $self     = shift;
    my $settings = $self->chronicle_reader->get($self->setting_namespace, $self->setting_name) || {};

    #Cleanup globals
    my $global = Data::Hash::DotNotation->new();
    foreach my $key (keys %{$self->dynamic_settings_info->{global}}) {
        if ($self->data_set->{global}->key_exists($key)) {
            $global->set($key, $self->data_set->{global}->get($key));
        }
    }

    $settings->{global} = $global->data;
    $settings->{_rev}   = Time::HiRes::time();
    $self->chronicle_writer->set($self->setting_namespace, $self->setting_name, $settings, Date::Utility->new);

    # since we now have the most recent data, we better set the
    # local version as well.
    $self->data_set->{version} = $settings->{_rev};
    $self->_updated_at($settings->{_rev});

    return 1;
}

=head2 current_revision

Loads setting from chronicle reader and returns the last revision

It is more likely that you want L</loaded_revision> in regular use

=cut

sub current_revision {
    my $self     = shift;
    my $settings = $self->chronicle_reader->get($self->setting_namespace, $self->setting_name);
    return $settings->{_rev};
}

=head2 loaded_revision

Returns the revision loaded and served by this instance

This may not reflect the latest stored version in the Chronicle persistence.
However, it is the revision of the data which will be returned when
querying this instance

=cut

sub loaded_revision {
    my $self = shift;

    return $self->data_set->{version};
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
        $data_set->{global}  = Data::Hash::DotNotation->new(data => $app_settings->{global});
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

    $self->dynamic_settings_info           = {} unless ($self->dynamic_settings_info);
    $self->dynamic_settings_info->{global} = {} unless ($self->dynamic_settings_info->{global});

    $self->dynamic_settings_info->{global}->{$path} = {
        type        => $definition->{isa},
        default     => $definition->{default},
        description => $definition->{description}};

    return;
}

=head1 SUBROUTINES/METHODS
######################################################
###### Start new API
######################################################

=head2 local_caching

If local_caching is set to the true then key-value pairs stored in Redis will be cached locally.

Calling update_cache will update the local cache with any changes from Redis.
refresh_interval defines (in seconds) the minimum time between seqequent updates.

Calls to get on this object will only ever access the cache.
Calls to set on this object will immediately update the values in the local cache and Redis.

=cut

has local_caching => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
);

=head2 update_cache

Loads latest values from data chronicle into local cache.
Calls to this method are rate-limited by C<refresh_interval>.

=cut

sub update_cache {
    my $self = shift;
    die 'Local caching not enabled' unless $self->local_caching;

    return unless $self->_has_refresh_interval_passed();
    $self->_updated_at(Time::HiRes::time());

    return unless $self->_is_cache_stale();

    my $keys        = [$self->dynamic_keys(), '_global_rev'];
    my @all_entries = $self->_retrieve_objects_from_chron($keys);
    $self->_store_objects_in_cache({map { $keys->[$_] => $all_entries[$_] } (0 .. $#$keys)});

    return 1;
}

sub _has_refresh_interval_passed {
    my $self                   = shift;
    my $now                    = Time::HiRes::time();
    my $prev_update            = $self->_updated_at;
    my $time_since_prev_update = $now - $prev_update;
    return ($time_since_prev_update >= $self->refresh_interval);
}

sub _is_cache_stale {
    my $self      = shift;
    my @rev_cache = $self->_retrieve_objects_from_cache(['_global_rev']);
    my @rev_chron = $self->_retrieve_objects_from_chron(['_global_rev']);
    return !($rev_cache[0] && $rev_chron[0] && $rev_cache[0]->{data} eq $rev_chron[0]->{data});
}

=head2 global_revision

Returns the global revision version of the config chronicle.
This will correspond to the last time any of values were changed.

=cut

sub global_revision {
    my $self = shift;
    return $self->get('_global_rev');
}

=head2 set

Takes a hashref of key->value pairs and atomically sets them in config chronicle

Example:
    set({key1 => 'value1', key2 => 'value2', key3 => 'value3',...});

=cut

sub set {
    my ($self, $pairs) = @_;

    die 'cannot set when $self->chronicle_writer is undefined' unless $self->chronicle_writer;

    my $rev_obj   = Date::Utility->new;
    my $rev_epoch = $rev_obj->{epoch};

    $self->_key_is_dynamic($_) or die "Cannot set with key: $_ | Key must be defined with 'global: 1'" foreach keys %$pairs;

    $pairs->{_global_rev} = $rev_epoch;
    my %key_objs_hash = pairmap {
        $a => {
            data       => $b,
            _local_rev => $rev_epoch
        } } %$pairs;
    $self->_store_objects(\%key_objs_hash, $rev_obj);

    ######
    # Temporary adapter code
    ######
    $self->data_set->{global}->set($_, $pairs->{$_}) foreach keys %$pairs;
    $self->_save_dynamic();

    return 1;
}

sub _store_objects {
    my ($self, $key_objs_hash, $date_obj, $optional_chron_args) = @_;
    $self->_store_objects_in_chron($key_objs_hash, $date_obj, $optional_chron_args);
    $self->_store_objects_in_cache($key_objs_hash) if $self->local_caching;
    return 1;
}

sub _store_objects_in_cache {
    my ($self, $key_objs_hash) = @_;
    $self->{$_->key} = $_->value foreach (pairs %$key_objs_hash);
    return 1;
}

sub _store_objects_in_chron {
    my ($self, $key_objs_hash, $date_obj, $optional_chron_args) = @_;
    my @atomic_write_pairs = pairmap { [$self->setting_namespace, $a, $b] } %$key_objs_hash;
    $self->chronicle_writer->mset(\@atomic_write_pairs, $date_obj, @$optional_chron_args);
    return 1;
}

=head2 get

Takes either
    - an arrayref of keys, gets them atomically, and returns a hashref of key->values,
    including the global_revision under the key '_global_rev'.
    - a single key (as a string), gets the value, and returns it directly.
If a key has an empty value, it will return with undef.

For convenience a get with just a key string will return the value only.

Example:
    get(['key1','key2','key3',...]);
Returns:
    {'key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3',..., '_global_rev' => '<number>'}

Example:
    get(['key1']);
Returns:
    {'key1' => 'value1', '_global_rev' => '<number>'}

Example:
    get('key1');
Returns:
    'value1'

=cut

sub get {
    my ($self, $keys) = @_;
    my $single_get;

    unless (ref $keys) {
        $keys       = [$keys];
        $single_get = 1;
    }

    $self->_key_exists($_) or die "Cannot get with key: $_ | Key must be defined" foreach @$keys;

    push @$keys, '_global_rev' unless $single_get;

    my @result_objs = $self->_retrieve_objects($keys);

    if ($single_get) {
        return $result_objs[0] ? $result_objs[0]->{data} : $self->get_default($keys->[0]);
    } else {
        return {map { $keys->[$_] => $result_objs[$_] ? $result_objs[$_]->{data} : $self->get_default($keys->[$_]) } (0 .. scalar @$keys - 1)};
    }
}

sub _retrieve_objects {
    my ($self, $keys) = @_;
    return $self->_retrieve_objects_from_cache($keys) if $self->local_caching;
    return $self->_retrieve_objects_from_chron($keys);
}

sub _retrieve_objects_from_cache {
    my ($self, $keys) = @_;
    return map { $self->{$_} } @$keys;
}

sub _retrieve_objects_from_chron {
    my ($self, $keys) = @_;
    my @atomic_read_pairs = map { [$self->setting_namespace, $_] } @$keys;
    return $self->chronicle_reader->mget(\@atomic_read_pairs);
}

=head2 get_history

Retreives a past revision of an app config entry, where $rev is the number of revisions in the past requested.
If the optional third argument is true then result of the query will be cached in Redis. This is useful if a certain
    revision will be needed repeatedly, to avoid excessive database access. By default this argument is 0.
All cached revisions will become stale if the key is set with a new value.

Example:
    get_history('system.email', 0); Retrieves current version
    get_history('system.email', 1); Retreives previous revision
    get_history('system.email', 2); Retreives version before previous

=cut

sub get_history {
    my ($self, $key, $rev, $cache) = @_;
    $cache //= 0;

    die "Cannot get history of key: $key | Key must be dynamic" unless $self->_key_is_dynamic($key);

    my ($curr_obj, $hist_obj) = $self->_retrieve_objects([$key, $key . '::' . $rev]);

    # If no cache, or cache is stale, get from db
    unless ($hist_obj && $hist_obj->{_local_rev} == $curr_obj->{_local_rev}) {
        $hist_obj = $self->chronicle_reader->get_history($self->setting_namespace, $key, $rev);

        $hist_obj->{_local_rev} = $curr_obj->{_local_rev} if $hist_obj;
        $self->_store_objects(
            {$key . '::' . $rev => $hist_obj},
            Date::Utility->new,
            [
                0,                    #<-- IMPORTANT: disables archiving
                0,                    #<-- IMPORTANT: supresses publication
                REDIS_HISTORY_TTL,    #<-- ttl = 7 days so that stale histories don't stay indefinitely.
            ]) if $hist_obj && $cache;
    }
    return $hist_obj->{data} if $hist_obj;
    return undef;
}

=head2 subscribe

Subscribes to changes for the specified $key with the sub $subref called when a new value is set.
The chronicle_writer must have publish_on_set enabled.

=cut

sub subscribe {
    my ($self, $key, $subref) = @_;
    die 'Cannot subscribe without chronicle_subscriber' unless $self->chronicle_subscriber;
    return $self->chronicle_subscriber->subscribe($self->setting_namespace, $key, $subref);
}

=head2 unsubscribe

Stops the sub $subref from being called when $key is set with a new value.
The chronicle_writer must have publish_on_set enabled.

=cut

sub unsubscribe {
    my ($self, $key) = @_;
    die 'Cannot unsubscribe without chronicle_subscriber' unless $self->chronicle_subscriber;
    return $self->chronicle_subscriber->unsubscribe($self->setting_namespace, $key);
}

has _keys_schema => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 all_keys

Returns a list containing all keys in the config chronicle schema

=cut

sub all_keys {
    my $self = shift;
    return grep { not $self->_key_is_internal($_) } keys %{$self->_keys_schema};
}

=head2 dynamic_keys

Returns a list containing only the dynamic keys in the config chronicle schema

=cut

sub dynamic_keys {
    my $self = shift;
    return grep { $self->_key_is_dynamic($_) } keys %{$self->_keys_schema};
}

=head2 static_keys

Returns a list containing only the static keys in the config chronicle schema

=cut

sub static_keys {
    my $self = shift;
    return grep { $self->_key_is_static($_) } keys %{$self->_keys_schema};
}

=head2 get_data_type

Returns the data type associated with a particular key

=cut

sub get_data_type {
    my ($self, $key) = @_;
    return unless $self->_key_exists($key);
    return $self->_keys_schema->{$key}->{data_type};
}

=head2 get_default

Returns the default value associated with a particular key

=cut

sub get_default {
    my ($self, $key) = @_;
    return unless $self->_key_exists($key);
    return $self->_keys_schema->{$key}->{default};
}

=head2 get_description

Returns the default value associated with a particular key

=cut

sub get_description {
    my ($self, $key) = @_;
    return unless $self->_key_exists($key);
    return $self->_keys_schema->{$key}->{description};
}

=head2 get_key_type

Returns the key type associated with a particular key

=cut

sub get_key_type {
    my ($self, $key) = @_;
    return unless $self->_key_exists($key);
    return $self->_keys_schema->{$key}->{key_type};
}

sub _key_exists {
    my ($self, $key) = @_;
    return exists $self->_keys_schema->{$key};
}

sub _key_is_dynamic {
    my ($self, $key) = @_;
    return exists $self->_keys_schema->{$key} && $self->_keys_schema->{$key}->{key_type} eq 'dynamic';
}

sub _key_is_static {
    my ($self, $key) = @_;
    return exists $self->_keys_schema->{$key} && $self->_keys_schema->{$key}->{key_type} eq 'static';
}

sub _key_is_internal {
    my ($self, $key) = @_;
    return exists $self->_keys_schema->{$key} && $self->_keys_schema->{$key}->{key_type} eq 'internal';
}

sub _initialise {
    my ($self, $keys, $path) = @_;

    foreach my $key (keys %{$keys}) {
        my $def                  = $keys->{$key};
        my $fully_qualified_path = $path ? $path . '.' . $key : $key;

        if ($def->{isa} eq 'section') {
            $self->_initialise($def->{contains}, $fully_qualified_path);
        } else {
            $self->_keys_schema->{$fully_qualified_path} = {
                key_type    => $def->{global} ? 'dynamic' : 'static',
                data_type   => $def->{isa},
                default     => $def->{default},
                description => $def->{description},
            };
        }
    }
    $self->_keys_schema->{_global_rev} = {
        key_type  => 'internal',
        data_type => 'Num',
        default   => 0,
    };
    return 1;
}

######################################################
###### End new API
######################################################

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    $self->_build_class;
    $self->_initialise($self->_defdb, '');

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
