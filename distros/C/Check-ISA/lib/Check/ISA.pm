package Check::ISA;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Sub::Exporter -setup => {
	exports => [qw(obj obj_does inv inv_does obj_can inv_can)],
	groups => {
		default => [qw(obj obj_does inv)],
	},
};

use constant CAN_HAS_DOES => not not UNIVERSAL->can("DOES");
use warnings::register;

our $VERSION = "0.09";

sub extract_io {
    my $glob = shift;

    # handle the case of a string like "STDIN"
    # STDIN->print is actually:
    #   const(PV "STDIN") sM/BARE
    #   method_named(PV "print")
    # so we need to lookup the glob
    if ( defined($glob) and !ref($glob) and length($glob) ) {
        no strict 'refs';
        $glob = \*{$glob};
    }

    # extract the IO
    if ( ref($glob) eq 'GLOB' ) {
        if ( defined ( my $io = *{$glob}{IO} ) ) {
            require IO::Handle;
            return $io;
        }
    }

    return;
}

sub obj ($;$); # predeclare, it's recursive

sub obj ($;$) {
    my ($object_or_filehandle, $class) = @_;

    my $object = blessed($object_or_filehandle)
        ? $object_or_filehandle
        : extract_io($object_or_filehandle) || return;

    if ( defined $class ) {
        $object->isa($class);
    } else {
        return 1; # return $object? what if it's overloaded?
    }
}

sub obj_does ($;$) {
    my ($object_or_filehandle, $class_or_role) = @_;

    my $object = blessed($object_or_filehandle)
        ? $object_or_filehandle
        : extract_io($object_or_filehandle) || return;

    if (defined $class_or_role) {
        if (CAN_HAS_DOES) {
            # we can be faster in 5.10
            $object->DOES($class_or_role);
        } else {
            my $method = $object->can("DOES") || "isa";
            $object->$method($class_or_role);
        }
    } else {
        return 1; # return $object? what if it's overloaded?
    }
}

sub inv ($;$) {
    my ( $inv, $class_or_role ) = @_;

    if (blessed($inv)) {
        return obj_does($inv, $class_or_role);
    } else {
        # we check just for scalar keys on the stash because:
        # sub Foo::Bar::gorch {}
        # Foo->can("isa") # true
        # Bar->can("isa") # false
        # this means that 'Foo' is a valid invocant, but Bar is not

        if (!ref($inv)
            and
            defined $inv
            and
            length($inv)
            and
            do { no strict 'refs'; scalar keys %{$inv . "::"} }
            ) {
            # it's considered a class name as far as gv_fetchmethod is concerned
            # even if the class def is empty
            if (defined $class_or_role) {
                if (CAN_HAS_DOES) {
                    # we can be faster in 5.10
                    $inv->DOES($class_or_role);
                } else {
                    my $method = $inv->can("DOES") || "isa";
                    $inv->$method($class_or_role);
                }
            } else {
                return 1; # $inv is always true, so not a problem, but that would be inconsistent
            }
        } else {
            return;
        }
    }
}

sub obj_can ($;$) {
    my ( $obj, $method ) = @_;
    (blessed($obj) ? $obj : extract_io($obj) || return)->can($method);
}

sub inv_can ($;$) {
    my ( $inv, $method ) = @_;
    obj_can($inv, $method) || inv($inv) && $inv->can($method);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Check::ISA - DWIM, correct checking of an object's class.

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Check::ISA;

    if (obj($foo, "SomeClass")) {
	$foo->some_method;
    }

    # instead of one of these methods:
    UNIVERSAL::isa($foo, "SomeClass") # WRONG
    ref $obj eq "SomeClass"; # VERY WRONG
    $foo->isa("SomeClass") # May die
    local $@; eval { $foo->isa("SomeClass") } # too long

=head1 DESCRIPTION

This module provides several functions to assist in testing whether a value is an
object, and if so asking about its class.

=head1 FUNCTIONS

=over 4

=item obj $thing, [ $class ]

This function tests if C<$thing> is an object.

If C<$class> is provided, it also tests tests whether C<< $thing->isa($class) >>.

C<$thing> is considered an object if it's blessed or a C<GLOB> with a valid C<IO>
slot (the C<IO> slot contains a L<FileHandle> object which is the actual invocant).
This corresponds directly to C<gv_fetchmethod>.

=item obj_does $thing, [ $class_or_role ]

Just like C<obj> but uses L<UNIVERSAL/DOES> instead of L<UNIVERSAL/isa>.

L<UNIVERSAL/DOES> is just like C<isa> except it's use is encouraged to query about
an interface, as opposed to the object structure. If C<DOES> is not overridden by
the ebject, calling it is semantically identical to calling C<isa>.

This is probably reccomended over C<obj> for interoperability but can be slower on
Perls before 5.10.

Note that L<UNIVERSAL/DOES>

=item inv $thing, [ $class_or_role ]

Just like C<obj_does>, but also returns true for classes.

Note that this method is slower, but is supposed to return true for any value
you can call methods on (class, object, filehandle, etc).

Look into L<autobox> if you would like to be able to call methods on all
values.

=item obj_can $thing, $method

=item inv_can $thing, $method

Checks if C<$thing> is an object or class, and calls C<can> on C<$thing> if
appropriate.

=back

=head1 SEE ALSO

L<UNIVERSAL>, L<Params::Util>, L<autobox>, L<Moose>, L<asa>

=head1 REPOSITORY

L<https://github.com/manwar/Check-ISA>

=head1 BUGS

Please report any bugs or feature requests to C<bug-check-isa at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Check-ISA>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Check::ISA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-ISA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Check-ISA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Check-ISA>

=item * Search CPAN

L<http://search.cpan.org/dist/Check-ISA/>

=back

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

Currently maintained by Mohammad S Anwar (MANWAR), C<< <mohammad.anwar at yahoo.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Yuval Kogman.

Copyright (c) 2016 Mohammad S Anwar.

All rights reserved. This program is free software; you can redistribute it and /
or modify it under the same terms as Perl itself.

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed  by  this License. By  using, modifying or distributing the Package, you
accept this license. Do not use, modify, or distribute the Package, if you do not
accept this license.

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
Package constitutes direct or contributory patent infringement, then this License
to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
