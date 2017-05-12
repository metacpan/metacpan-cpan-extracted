package Class::DOES;

use 5.006001;

=head1 NAME

Class::DOES - Provide a simple ->DOES override

=head1 SYNOPSIS

    package My::Class;

    use Class::DOES qw/Some::Role/;

    if (My::Class->DOES("Some::Role")) {
        #...
    }

=cut

use strict;
use warnings;
use warnings::register;

use Scalar::Util qw/blessed/;

our $VERSION = "1.01";

sub warnif {
    if (warnings::enabled()) {
        warnings::warn($_[0]);
    }
}

sub get_mro;
sub get_mro {
    my ($class) = @_;

    defined &mro::get_linear_isa
        and return @{ mro::get_linear_isa($class) };

    no strict "refs";
    my @mro = $class;
    for (@{"$class\::ISA"}) {
        push @mro, get_mro $_;
    }
    return @mro;
}

sub import {
    my (undef, @roles) = @_;
    my $pkg = caller;

    my $meth;
    $meth = $pkg->can("DOES")
        and $meth != \&DOES
        and $meth != (UNIVERSAL->can("DOES") || 0)
        and warnif "$pkg has inherited an incompatible ->DOES";

    $meth = $pkg->can("isa")
        and $meth != UNIVERSAL->can("isa")
        and warnif "$pkg doesn't use \@ISA for inheritance";

    my %does = map +($_, 1), @roles;

    no strict "refs";

    *{"$pkg\::DOES"} = \%does;
    *{"$pkg\::DOES"} = \&DOES;
}

sub DOES {
    my ($obj, $role) = @_;

    my $class = blessed $obj;
    defined $class or $class = $obj;

    my %mro;
    # Yes, this is a list. Shut up with your 'better written as
    # $mro{}' nonsense.
    @mro{ (), get_mro $class } = ();
    for (keys %mro) {
        no strict "refs";
        if (exists ${"$_\::DOES"}{$role}) {
            my $rv = ${"$_\::DOES"}{$role};
            unless ($rv) {
                warnif "\$$_\::DOES{$role} is false, returning 1";
                return 1;
            }
            return $rv;
        }
    }

    return $obj->isa($role);
}

=head1 DESCRIPTION

Perl 5.10 introduced a new method in L<UNIVERSAL|UNIVERSAL>: C<DOES>.
This was added to support the concept of B<roles>. A role is an
interface (a set of methods, with associated semantics) that a class or
an object can implement, without necessarily inheriting from it. A class
declares that it implements a given role by overriding the C<< ->DOES >>
method to return true when passed the name of the role.

This is all well and flexible, allowing advanced object systems like
L<Moose|Moose> to implement the C<< ->DOES >> override as they see fit,
but what about ordinary classes that just want to declare they support a
known interface? That's what this module is for: you pass it a list of
roles on the C<use> line, and it gives you a C<< ->DOES >> override that
returns true for

=over 4

=item - any role in the supplied list;

=item - any class you inherit from; 

=item - any role supported by any class you inherit from.

=back

It makes the following assumptions:

=over 4

=item - All your inheritance happens through C<@ISA>.

That is, you haven't overridden C<< ->isa >>.

=item - Noone else has given you a C<< ->DOES >> method.

That is, none of your superclasses have their own C<< ->DOES >> override
(other than one provided by this module).

=back

If it detects either of these at C<use> time, it will issue a warning.

=head2 Setting C<%DOES> directly.

This module stores the roles you support in the C<%DOES> hash in your
package. If you want C<< ->DOES >> to return something other that C<1>
for a role you support, you can make an entry in your C<%DOES> hash
yourself and it will be picked up.

You should not make entries with false values, as this would be very
confusing. If you do, then when C<< ->DOES >> is called it will return
C<1> instead of the given value, and will issue a warning.

=head2 DIAGNOSTICS

All of these can be disabled with

    no warnings "Class::DOES";

=over 4

=item %s has inherited an incompatible ->DOES

You have issued C<use Class::DOES> from a class that already has a C<<
->DOES >> method. This inherited method will be completely ignored, so
any roles it claims to support will be lost.

=item %s doesn't use @ISA for inheritance

You have issued C<use Class::DOES> from a class with an overriden C<<
->isa >>. Since the exported C<< ->DOES >> method uses C<@ISA> to
determine inheritance, any extra classes C<< ->isa >> claims to inherit
from will not be checked for the requested role.

=item $%s::DOES{%s} is false, returning 1

C<< ->DOES >> has found a false entry in a C<%DOES> hash, and is
returning C<1> instead to indicate the role is supported.

=back

=head1 AUTHOR

Copyright 2009 Ben Morrow <ben@morrow.me.uk>.

This program is licensed under the same terms as Perl.

=head1 BUGS

Please send bug reports to <bug-Class-DOES@rt.cpan.org>.

=cut

1;

