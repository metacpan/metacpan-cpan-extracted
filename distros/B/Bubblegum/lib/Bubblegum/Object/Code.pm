# ABSTRACT: Common Methods for Operating on Code References
package Bubblegum::Object::Code;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Class 'with';
use Bubblegum::Constraints -isas, -types;

with 'Bubblegum::Object::Role::Defined';
with 'Bubblegum::Object::Role::Ref';
with 'Bubblegum::Object::Role::Coercive';
with 'Bubblegum::Object::Role::Output';

our @ISA = (); # non-object

our $VERSION = '0.45'; # VERSION

sub call {
    my $self = CORE::shift;
    my @args = @_;
    return $self->(@args);
}

sub curry {
    my $self = CORE::shift;
    my @args = @_;
    return sub { $self->(@args, @_) };
}

sub rcurry {
    my $self = CORE::shift;
    my @args = @_;
    return sub { $self->(@_, @args) };
}

sub compose {
    my $self = CORE::shift;
    my $next = type_coderef CORE::shift;
    my @args = @_;
    return (sub { $next->($self->(@_)) })->curry(@args);
}

sub disjoin {
    my $self = CORE::shift;
    my $next = type_coderef CORE::shift;
    return sub { $self->(@_) || $next->(@_) };
}

sub conjoin {
    my $self = CORE::shift;
    my $next = type_coderef CORE::shift;
    return sub { $self->(@_) && $next->(@_) };
}

sub next {
    goto &call;
}

sub print {
    my $self = CORE::shift;
    return CORE::print $self->(@_);
}

sub say {
    my $self = CORE::shift;
    return print($self->(@_), "\n");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Object::Code - Common Methods for Operating on Code References

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $code = sub { shift + 1 };
    say $code->call(2); # 3

=head1 DESCRIPTION

Code methods work on code references. It is not necessary to use this module as
it is loaded automatically by the L<Bubblegum> class.

=head1 METHODS

=head2 call

    my $code = sub { (shift // 0) + 1 };
    $code->call; # 1
    $code->call(0); # 1
    $code->call(1); # 2
    $code->call(2); # 3

The call method executes and returns the result of the subject.

=head2 curry

    my $code = sub { [@_] };
    $code = $code->curry(1,2,3);
    $code->(4,5,6); # [1,2,3,4,5,6]

The curry method returns a code reference which executes the subject passing it
the arguments and any additional parameters when executed.

=head2 rcurry

    my $code = sub { [@_] };
    $code = $code->rcurry(1,2,3);
    $code->(4,5,6); # [4,5,6,1,2,3]

The rcurry method returns a code reference which executes the subject passing it
the any additional parameters and any arguments when executed.

=head2 compose

    my $code = sub { [@_] };
    $code = $code->compose($code, 1,2,3);
    $code->(4,5,6); # [[1,2,3,4,5,6]]

    # this can be confusing, here's what's really happening:
    my $listing = sub {[@_]}; # produces an arrayref of args
    $listing->($listing->(@args)); # produces a listing within a listing
    [[@args]] # the result

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the subject as it's
argument, and returns a code reference which executes the created code reference
passing it the remaining arguments when executed.

=head2 disjoin

    my $code = sub { $_[0] % 2 };
    $code = $code->disjoin(sub { -1 });
    $code->(0); # -1
    $code->(1); #  1
    $code->(2); # -1
    $code->(3); #  1
    $code->(4); # -1

The disjoin method creates a code reference which execute the subject and the
argument in a logical OR operation having the subject as the lvalue and the
argument as the rvalue.

=head2 conjoin

    my $code = sub { $_[0] % 2 };
    $code = $code->conjoin(sub { 1 });
    $code->(0); # 0
    $code->(1); # 1
    $code->(2); # 0
    $code->(3); # 1
    $code->(4); # 0

The conjoin method creates a code reference which execute the subject and the
argument in a logical AND operation having the subject as the lvalue and the
argument as the rvalue.

=head2 next

    $code->next;

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators.

=head2 print

    my $code = sub {(1234, @_)};
    $code->print; # 12345
    $code->print(6789); # 123456789

The print method prints the return value of the code reference to STDOUT, and
returns true if successful.

=head2 say

    my $code = sub {(1234, @_)};
    $code->print; # 12345\n
    $code->print(6789); # 123456789\n

The say method prints the return value of the code reference with a newline
appended to STDOUT, and returns true if successful.

=head1 COERCIONS

=head2 to_array

    my $code = sub { "foobar" };
    my $result = $code->to_array; # [sub { "foobar" }]

The to_array method coerces a number to an array value. This method returns an
array reference using the subject as the first element.

=head2 to_a

    my $code = sub { "foobar" };
    my $result = $code->to_a; # [sub { "foobar" }]

The to_a method coerces a number to an array value. This method returns an array
reference using the subject as the first element.

=head2 to_code

    my $code = sub { "foobar" };
    my $result = $code->to_code; # sub { "foobar" }

The to_code method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_c

    my $code = sub { "foobar" };
    my $result = $code->to_c; # sub { "foobar" }

The to_c method coerces a number to a code value. The code reference, when
executed, will return the subject.

=head2 to_hash

    my $code = sub { "foobar" };
    my $result = $code->to_hash; # die 'code to hash coercion n/a'

The to_hash method coerces a number to a hash value. This method will die as
uncoercible.

=head2 to_h

    my $code = sub { "foobar" };
    my $result = $code->to_h; # die 'code to hash coercion n/a'

The to_h method coerces a number to a hash value. This method will die as
uncoercible.

=head2 to_number

    my $code = sub { "foobar" };
    my $result = $code->to_number; # die 'code to number coercion n/a'

The to_number method coerces a number to a number value. This method will die as
uncoercible.

=head2 to_n

    my $code = sub { "foobar" };
    my $result = $code->to_n; # die 'code to number coercion n/a'

The to_n method coerces a number to a number value. This method will die as
uncoercible.

=head2 to_string

    my $code = sub { "foobar" };
    my $result = $code->to_string; # die 'code to string coercion n/a'

The to_string method coerces a number to a string value. This method will die as
uncoercible.

=head2 to_s

    my $code = sub { "foobar" };
    my $result = $code->to_s; # die 'code to string coercion n/a'

The to_s method coerces a number to a string value. This method will die as
uncoercible.

=head2 to_undef

    my $code = sub { "foobar" };
    my $result = $code->to_undef; # undef

The to_undef method coerces a number to an undef value. This method merely
returns an undef value.

=head2 to_u

    my $code = sub { "foobar" };
    my $result = $code->to_u; # undef

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
