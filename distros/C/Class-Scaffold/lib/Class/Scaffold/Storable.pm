use 5.008;
use warnings;
use strict;

package Class::Scaffold::Storable;
BEGIN {
  $Class::Scaffold::Storable::VERSION = '1.102280';
}

# ABSTRACT: Base class for all framework classes that support a storage.
use parent 'Class::Scaffold::Base';
__PACKAGE__->mk_scalar_accessors(qw(storage_type))
  ->mk_hash_accessors(qw(storage_info));

# Don't store the storage object itself, store the method we need to call on
# the delegate to get the storage object. This is just a little overhead, but
# saves us from a lot of headache when serializing and deserializing objects
# with Storable's freeze() and thaw(), because storage objects can't be
# deserialized properly.
#
# Impose a certain order on how the constructor args are processed. We want
# the storage to be set first, because other properties could be defined using
# mk_framework_object_accessors(). Now if the args were set in an arbitrary
# order, the framework_object-properties could be processed before the storage
# is set, which would cause an error, because the storage wouldn't be set yet,
# so it can't be asked to make an object.
#
# We can't have storage_type as a key within the storage_info hash, because we
# want to be able to set it directly if passed as an argument to the
# constructor; we also need to be able to prefer it in
# Class::Scaffold::Storable::FIRST_CONSTRUCTOR_ARGS().
#
# We use the storage's signature as the id key, i.e. to find the id of the
# object within the storage. It would not be sufficient to use the storage's
# package name as the hash key because we can think of a multiplex storage
# that multiplexes onto two file system paths. In that case each of the
# multiplexed storages would have the same package name. And we can't use the
# storage's memory address (0x012345678) because different stages can be run
# within different processes and on different machines.
#
# For example, the attributes of an object of this class might look like:
# storage_type: core_storage
# storage_info:
#   id:
#     'Registry::NICAT::Storage::DBI::Oracle::NICAT,dbname=db.test,dbuser=nic': id12345
#     'Some::File::Storage,fspath=/path/to/storage/root': id45678
# This example assumes that the core storage is multiplexing on a DBI storage
# and a file system storage.
use constant FIRST_CONSTRUCTOR_ARGS => ('storage_type');
use constant SKIP_COMPARABLE_KEYS   => (qw/storage_type storage_info/);
use constant HYGIENIC               => (qw/storage storage_type/);

sub MUNGE_CONSTRUCTOR_ARGS {
    my ($self, @args) = @_;

    # needed in order to mix object creation of a given class with and without
    # explicitly setting the storage object for it (Erik P. Ostlyngen, NORID):
    if (@args % 2 == 0) {
        my %args = @args;
        return %args if $args{storage_type};
    }

    # The superclass does nothing, so we'll skip this for performance reasons
    # - this method is called very often.
    # @args = $self->SUPER::MUNGE_CONSTRUCTOR_ARGS(@args);
    our %cache;
    my $extra_args;
    unless ($extra_args = $cache{ ref $self }) {
        my $object_type = $self->get_my_factory_type;
        if (defined $object_type) {
            my $storage_type =
              $self->delegate->get_storage_type_for($object_type);
            $self->delegate->$storage_type->lazy_connect;

            # storage will be disconnected in Class::Scaffold::App->app_finish
            $extra_args = $cache{ ref $self } =
              [ storage_type => $storage_type ];
        } else {
            $extra_args = $cache{ ref $self } = [];
        }
    }
    (@args, @$extra_args);
}

sub storage {
    my $self   = shift;
    my $method = $self->storage_type;
    if ($method) {
        $self->delegate->$method;
    } else {
        local $Error::Depth = $Error::Depth + 1;
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
              "can't find method to get storage object from delegate");
    }
}

sub id {
    my $self    = shift;
    my $storage = shift;
    if (@_) {
        my $id = shift;
        $self->storage_info->{id}{ $storage->signature } = $id;
    } else {
        $self->storage_info->{id}{ $storage->signature };
    }
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Storable - Base class for all framework classes that support a storage.

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 id

FIXME

=head2 storage

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

