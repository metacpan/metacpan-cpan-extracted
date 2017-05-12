# ABSTRACT: Common Methods for Operating on Undefined Values
package Bubblegum::Object::Undef;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Class 'with';

with 'Bubblegum::Object::Role::Item';
with 'Bubblegum::Object::Role::Coercive';

our @ISA = (); # non-object

our $VERSION = '0.45'; # VERSION

sub defined {
    return 0
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Object::Undef - Common Methods for Operating on Undefined Values

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $nothing = undef;
    say $nothing->defined ? 'Yes' : 'No'; # No

=head1 DESCRIPTION

Undefined methods work on variables whose data meets the criteria for being
undefined. It is not necessary to use this module as it is loaded automatically
by the L<Bubblegum> class.

=head1 METHODS

=head2 defined

    my $nothing = undef;
    $nothing->defined ? 'Yes' : 'No'; # No

The defined method always returns false.

=head1 COERCIONS

=head2 to_array

    my $undef = undef;
    my $result = $undef->to_array; # []

The to_array method coerces a number to an array value. This method returns an
empty array reference.

=head2 to_a

    my $undef = undef;
    my $result = $undef->to_a; # []

The to_a method coerces a number to an array value. This method returns an empty
array reference.

=head2 to_code

    my $undef = undef;
    my $result = $undef->to_code; # sub { $undef }

The to_code method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_c

    my $undef = undef;
    my $result = $undef->to_c; # sub { $undef }

The to_c method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_hash

    my $undef = undef;
    my $result = $undef->to_hash; # {}

The to_hash method coerces a number to a hash value. This method returns an
empty hash reference.

=head2 to_h

    my $undef = undef;
    my $result = $undef->to_h; # {}

The to_h method coerces a number to a hash value. This method returns an empty
hash reference.

=head2 to_number

    my $undef = undef;
    my $result = $undef->to_number; # 0

The to_number method coerces a number to a number value. This method returns the
number zero.

=head2 to_n

    my $undef = undef;
    my $result = $undef->to_n; # 0

The to_n method coerces a number to a number value. This method returns the
number zero.

=head2 to_string

    my $undef = undef;
    my $result = $undef->to_string; # ""

The to_string method coerces a number to a string value. This method returns an
empty string.

=head2 to_s

    my $undef = undef;
    my $result = $undef->to_s; # ""

The to_s method coerces a number to a string value. This method returns an empty
string.

=head2 to_undef

    my $undef = undef;
    my $result = $undef->to_undef; # undef

The to_undef method coerces a number to an undef value. This method merely
returns an undef value.

=head2 to_u

    my $undef = undef;
    my $result = $undef->to_u; # undef

The to_u method coerces a number to an undef value. This method merely returns
an undef value.

=head1 SEE ALSO

=over 4

=item *

L<Bubblegum::Object::Array>

=item *

L<Bubblegum::Object::Code>

=item *

L<Bubblegum::Object::Hash>

=item *

L<Bubblegum::Object::Instance>

=item *

L<Bubblegum::Object::Integer>

=item *

L<Bubblegum::Object::Number>

=item *

L<Bubblegum::Object::Scalar>

=item *

L<Bubblegum::Object::String>

=item *

L<Bubblegum::Object::Undef>

=item *

L<Bubblegum::Object::Universal>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
