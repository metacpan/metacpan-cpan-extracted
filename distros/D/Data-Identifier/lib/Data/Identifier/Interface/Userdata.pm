# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Interface::Userdata;

use v5.20;
use strict;
use warnings;

use Carp;

our $VERSION = v0.14;


sub userdata {
    my ($self, $package, $key, $value) = @_;
    my $userdata = $self->_userdata_provider;
    $userdata->{$package} //= {};
    return $userdata->{$package}{$key} = $value // $self->{userdata}{$package}{$key};
}


sub _userdata_provider {
    my ($self) = @_;
    return $self->{userdata} //= {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Interface::Userdata - format independent identifier object

=head1 VERSION

version v0.14

=head1 SYNOPSIS

    use parent 'Data::Identifier::Interface::Userdata';

(since v0.14, experimental)

Interface for modules implementing C<userdata()>.

B<Note:>
This interface is experimental. Details may change or it may be removed completely.

=head1 METHODS

=head2 userdata

    my $value = $obj->userdata(__PACKAGE__, $key);
    $obj->userdata(__PACKAGE__, $key => $value);

Get or set user data to be used with this object. The data is stored using the given C<$key>.
The package of the caller is given to provide namespaces for the userdata, so two independent packages
can use the same C<$key>.

The meaning of C<$key>, and C<$value> is up to C<__PACKAGE__>.

The default implementation uses L</_userdata_provider> as a backend for storage.

=head2 _userdata_provider

    my $userdata = $obj->_userdata_provider;

This method is used by the default implementation of L</userdata>.
It provides the backend storage for userdata.

For every passed object it returns an instance of a hashref (initially empty) that is kept inside the object.

The default implementation expects the object to be a (blessed) hashref. It uses the key C<userdata> to store the hashref.
It is equivalent to:

    return $obj->{userdata} //= {};

If L</userdata> is overridden this method can stay unimplemented.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
