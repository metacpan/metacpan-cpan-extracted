package Class::Mite;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.1.1');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Class::Mite - A minimal, integrated Class and Role system for Perl

=head1 VERSION

Version v0.1.1

=head1 SYNOPSIS

This distribution provides two separate, complementary modules:

=over 4

=item * L<Role> - For defining and consuming methods with requirements and conflict resolution.

=item * L<Class> - A base class providing a default constructor (C<new>) with a post-construction hook (C<BUILD>).

=back

You use them together like this:

    package Loggable;

    use Role;
    requires qw/id name/;

    sub log {
        my ($self) = @_;
        return "[" . $self->id . "]: " . $self->name;
    }

    package User;

    use Class;
    with qw/Loggable/;

    sub id   { shift->{id}   }
    sub name { shift->{name} }

    package main;

    my $user = User->new(id => 1, name => 'Alice');
    print $user->log, "\n";

=head1 DESCRIPTION

C<Class::Mite> bundles a very minimal, high-speed approach to object-oriented
programming in Perl. It borrows best practices from systems like L<Moo> and L<Role::Tiny>
while keeping external dependencies and boilerplate code to an absolute nothing.

=head1 MODULES IN THIS DISTRIBUTION

=over 4

=item * L<Role>

The core role composition engine. Provides C<requires>, C<excludes>, C<with>,
and method conflict detection.

=item * L<Class>

The base class provider. Provides a default, hash-based C<new> constructor that
automatically calls a user-defined C<BUILD> method if one is present. It also
ensures the C<with> function from L<Role> is available to simplify consumption
syntax.

=item * L<Class::More>

A fast, lightweight class builder for Perl.

=item * L<Class::Clone>

Add clone method to Class-based classes.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Class-Mite>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Class-Mite/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Mite

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Class-Mite/issues>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF    MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Class::Mite
