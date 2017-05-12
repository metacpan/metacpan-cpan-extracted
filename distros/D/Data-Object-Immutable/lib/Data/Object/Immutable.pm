# ABSTRACT: Immutable Object for Perl 5
package Data::Object::Immutable;

use 5.14.0;
use strict;
use warnings;

use Data::Object;
use Data::Object::Signatures;
use Readonly;

our $VERSION = '0.08'; # VERSION

method new ($data) {

    $self = Data::Object->new($data);

    Readonly::Hash   %$self => %$self if UNIVERSAL::isa $self, 'HASH';
    Readonly::Array  @$self => @$self if UNIVERSAL::isa $self, 'ARRAY';
    Readonly::Scalar $$self => $$self if UNIVERSAL::isa $self, 'SCALAR';

    return $self;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Immutable - Immutable Object for Perl 5

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Data::Object::Immutable;

    my $object = Data::Object::Immutable->new([1..9]);

    $object->isa('Data::Object::Array'); # 1
    $object->count; # 9

    $object->[0]++; # fatal ... modification of a read-only value attempted

=head1 DESCRIPTION

Data::Object::Immutable provides a mechanism for making any L<Data::Object>
data type object immutable. An immutable object is an object whose state cannot
be modified after it is created; Immutable objects are often useful because
they are inherently thread-safe, easier to reason about, and offer higher
security than mutable objects.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 CONTRIBUTOR

=for stopwords Developer

Developer <dev@example.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
