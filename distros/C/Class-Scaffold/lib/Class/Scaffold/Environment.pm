use 5.008;
use warnings;
use strict;

package Class::Scaffold::Environment;
BEGIN {
  $Class::Scaffold::Environment::VERSION = '1.102280';
}

# ABSTRACT: Base class for framework environment classes
use Error::Hierarchy::Util 'load_class';
use Class::Scaffold::Factory::Type;
use Property::Lookup;
use Data::Storage;    # for AutoPrereq
use parent 'Class::Scaffold::Base';
Class::Scaffold::Base->add_autoloaded_package('Class::Scaffold::');

# ptags: /(\bconst\b[ \t]+(\w+))/
__PACKAGE__->mk_scalar_accessors(qw(test_mode context))
  ->mk_boolean_accessors(qw(rollback_mode))
  ->mk_class_hash_accessors(qw(storage_cache multiplex_transaction_omit))
  ->mk_object_accessors(
    'Property::Lookup' => {
        slot       => 'configurator',
        comp_mthds => [
            qw(
              get_config
              core_storage_name
              core_storage_args
              memory_storage_name
              )
        ]
    },
  );
use constant DEFAULTS =>
  (test_mode => (defined $ENV{TEST_MODE} && $ENV{TEST_MODE} == 1),);
Class::Scaffold::Factory::Type->register_factory_type(
    exception_container => 'Class::Scaffold::Exception::Container',
    result              => 'Data::Storage::DBI::Result',
    storage_statement   => 'Data::Storage::Statement',
    test_util_loader    => 'Class::Scaffold::Test::UtilLoader',
);
{    # closure over $env so that it really is private
    my $env;
    sub getenv { $env }

    sub setenv {
        my ($self, $newenv, @args) = @_;
        return $env = $newenv
          if ref $newenv
              && UNIVERSAL::isa($newenv, 'Class::Scaffold::Environment');
        unless (ref $newenv) {

            # it's a string containing the class name
            load_class $newenv, 1;
            return $env = $newenv->new(@args);
        }
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => "Invalid environment specification [$newenv]",);
    }
}    # end of closure

sub setup {
    my $self = shift;
    $self->configurator->default_layer->hash(
        $self->every_hash('CONFIGURATOR_DEFAULTS'));
}

# ----------------------------------------------------------------------
# class name-related code
use constant STORAGE_CLASS_NAME_HASH => (

    # storage names
    STG_NULL     => 'Data::Storage::Null',
    STG_NULL_DBI => 'Data::Storage::DBI',    # for testing
);

sub make_obj {
    my $self = shift;
    Class::Scaffold::Factory::Type->make_object_for_type(@_);
}

sub get_class_name_for {
    my ($self, $object_type) = @_;
    Class::Scaffold::Factory::Type->get_factory_class($object_type);
}

sub isa_type {
    my ($self, $object, $object_type) = @_;
    return unless UNIVERSAL::can($object, 'get_my_factory_type');
    my $factory_type = $object->get_my_factory_type;
    defined $factory_type ? $factory_type eq $object_type : 0;
}

sub gen_class_hash_accessor (@) {
    for my $prefix (@_) {
        my $method = sprintf 'get_%s_class_name_for' => lc $prefix;
        my $every_hash_name = sprintf '%s_CLASS_NAME_HASH', $prefix;
        my $hash;    # will be cached here
        no strict 'refs';
        $::PTAGS && $::PTAGS->add_tag($method, __FILE__, __LINE__ + 1);
        *$method = sub {
            local $DB::sub = local *__ANON__ = sprintf "%s::%s", __PACKAGE__,
              $method
              if defined &DB::DB && !$Devel::DProf::VERSION;
            my ($self, $key) = @_;
            $hash ||= $self->every_hash($every_hash_name);
            $hash->{$key} || $hash->{_AUTO};
        };

        # so FOO_CLASS_NAME() will return the whole every_hash
        $method = sprintf '%s_CLASS_NAME' => lc $prefix;
        $::PTAGS && $::PTAGS->add_tag($method, __FILE__, __LINE__ + 1);
        *$method = sub {
            local $DB::sub = local *__ANON__ = sprintf "%s::%s", __PACKAGE__,
              $method
              if defined &DB::DB && !$Devel::DProf::VERSION;
            my $self = shift;
            $hash ||= $self->every_hash($every_hash_name);
            wantarray ? %$hash : $hash;
        };
        $method = sprintf 'release_%s_class_name_hash' => lc $prefix;
        $::PTAGS && $::PTAGS->add_tag($method, __FILE__, __LINE__ + 1);
        *$method = sub {
            local $DB::sub = local *__ANON__ = sprintf "%s::%s", __PACKAGE__,
              $method
              if defined &DB::DB && !$Devel::DProf::VERSION;
            undef $hash;
        };
    }
}
gen_class_hash_accessor('STORAGE');

sub load_cached_class_for_type {
    my ($self, $object_type_const) = @_;

    # Cache for efficiency reasons; the environment is the core of the whole
    # framework.
    our %cache;
    my $class = $self->get_class_name_for($object_type_const);
    unless (defined($class) && length($class)) {
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
              "Can't find class for object type [$object_type_const]",);
    }
    load_class $class, $self->test_mode;
    $class;
}

sub storage_for_type {
    my ($self, $object_type) = @_;
    my $storage_type = $self->get_storage_type_for($object_type);
    $self->$storage_type;
}

# When running class tests in non-final distributions, which storage should we
# use? Ideally, every distribution (but especially the non-final ones like
# Registry-Core and Registry-Enum) should have a mock storage against which to
# test. Until then, the following mechanism can be used:
#
# Every storage notes whether it is abstract or an implementation. Class tests
# that need a storage will skip() the tests if the storage is abstract.
# Problem: we need to ask all the object types' storages used in a test code
# block, as different objects types could use different storages. For example:
#    skip(...) unless
#        $self->delegate->all_storages_are_implemented(qw/person command .../);
sub all_storages_are_implemented {
    my ($self, @object_types) = @_;
    for my $object_type (@object_types) {
        return 0 if $self->storage_for_type($object_type)->is_abstract;
    }
    1;
}

# Have a special method for making delegate objects, because delegates will be
# cached (i.e., pseudo-singletons) and don't need storages and extra args and
# such.
sub make_delegate {
    my ($self, $object_type_const, @args) = @_;
    our %cache;
    $cache{delegate}{$object_type_const} ||=
      $self->make_obj($object_type_const, @args);
}

# ----------------------------------------------------------------------
# storage-related code
use constant STORAGE_TYPE_HASH => (_AUTO => 'core_storage',);

sub get_storage_type_for {
    my ($self, $key) = @_;
    our %cache;
    return $cache{get_storage_type_for}{$key}
      if exists $cache{get_storage_type_for}{$key};
    my $storage_type_for = $self->every_hash('STORAGE_TYPE_HASH');
    $cache{get_storage_type_for}{$key} = $storage_type_for->{$key}
      || $storage_type_for->{_AUTO};
}

sub make_storage_object {
    my $self         = shift;
    my $storage_name = shift;
    my %args =
        @_ == 1
      ? defined $_[0]
          ? ref $_[0] eq 'HASH'
              ? %{ $_[0] }
              : @_
          : ()
      : @_;
    if (my $class = $self->get_storage_class_name_for($storage_name)) {
        load_class $class, $self->test_mode;
        return $class->new(%args);
    }
    throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => "Invalid storage name [$storage_name]",);
}

sub core_storage {
    my $self = shift;
    $self->storage_cache->{core_storage} ||=
      $self->make_storage_object($self->core_storage_name,
        $self->core_storage_args);
}

sub memory_storage {
    my $self = shift;
    $self->storage_cache->{memory_storage} ||=
      $self->make_storage_object($self->memory_storage_name);
}

# Forward some special methods onto all cached storages. Some storages could
# be a bit special - we don't want to rollback or disconnect from them when
# calling the multiplexing rollback() and disconnect() methods below, so we
# ignore them when multiplexing. For example, mutex storages (see
# Data-Conveyor for the concept).
sub rollback {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->rollback;
    }
}

sub commit {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->commit;
    }
}

sub disconnect {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->disconnect;

        # remove it from the cache so we'll reconnect next time
        $self->storage_cache_delete($storage_type);
        require Class::Scaffold::Storable;
        %Class::Scaffold::Storable::cache = ();
    }
    our %cache;
    $cache{get_storage_type_for} = {};
}

# Check configuration values for consistency. Empty, but it exists so
# subclasses can call SUPER::check()
sub check { }
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Environment - Base class for framework environment classes

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 all_storages_are_implemented

FIXME

=head2 check

FIXME

=head2 commit

FIXME

=head2 core_storage

FIXME

=head2 disconnect

FIXME

=head2 gen_class_hash_accessor

FIXME

=head2 get_class_name_for

FIXME

=head2 get_storage_class_name_for

FIXME

=head2 get_storage_type_for

FIXME

=head2 getenv

FIXME

=head2 isa_type

FIXME

=head2 load_cached_class_for_type

FIXME

=head2 make_delegate

FIXME

=head2 make_obj

FIXME

=head2 make_storage_object

FIXME

=head2 memory_storage

FIXME

=head2 release_storage_class_name_hash

FIXME

=head2 rollback

FIXME

=head2 setenv

FIXME

=head2 setup

FIXME

=head2 storage_CLASS_NAME

FIXME

=head2 storage_for_type

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

