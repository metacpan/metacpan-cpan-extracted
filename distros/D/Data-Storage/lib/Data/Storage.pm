use 5.008;
use strict;
use warnings;

package Data::Storage;
BEGIN {
  $Data::Storage::VERSION = '1.102720';
}
# ABSTRACT: Base class for storages
use Class::Null;
use parent qw(
  Class::Accessor::Complex
  Class::Accessor::Constructor
);
__PACKAGE__
    ->mk_constructor
    ->mk_boolean_accessors(qw(rollback_mode))
    ->mk_abstract_accessors(qw(create initialize_data))
    ->mk_scalar_accessors(qw(log));
use constant is_abstract => 1;
use constant DEFAULTS => (log => Class::Null->new,);

sub setup {
    my $self = shift;
    $self->log->debug('creating storage schema');
    $self->create;
    $self->log->debug('populating storage with initial data');
    $self->initialize_data;
}
sub test_setup { }

# convenience method to access an object's id
sub id {
    my $self   = shift;
    my $object = shift;
    if ($@) {
        my $id = shift;
        $object->id($self, $id);
    } else {
        $object->id($self);
    }
}

# The storage object's signature is needed by Class::Scaffold::Storable to
# associate an object's id with the storage. We can't just store an id in a
# get_set_std accessor, because the business object's storage might be a
# multiplexing storage, and the object would have a different id in each
# multiplexed storage.
sub signature {
    my $self = shift;
    ref $self;
}
sub connect    { }
sub disconnect { }

# Some storage classes won't make a difference between a normal connection and
# a lazy connection - for memory storages, there is no connection anyway. But
# see Data::Storage::DBI for a way to use lazy connections.
sub lazy_connect { }
1;


__END__
=pod

=head1 NAME

Data::Storage - Base class for storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 connect

FIXME

=head2 disconnect

FIXME

=head2 id

FIXME

=head2 lazy_connect

FIXME

=head2 setup

FIXME

=head2 signature

FIXME

=head2 test_setup

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

