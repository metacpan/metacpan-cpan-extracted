package Data::Random::Structure;
{
  $Data::Random::Structure::VERSION = '0.01';
}

#ABSTRACT: Generate random data structures


use warnings;
use strict;

use Data::Random qw(rand_chars);
use Carp qw(croak);

# Use grotty old style OO
# No validation, whee

sub new {
    my $class = shift;

    if ( scalar @_ % 2 != 0 ) {
        croak "Constructor requires even number of arguments.\n";
    }

    my $self = { @_ };
    bless $self, $class;

    $self->{max_depth} ||= 3;
    $self->{max_elements} ||= 6;

    $self->_init();

    return $self;
}

sub _init {
    my $self = shift;

    push @{$self->{_types}}, qw(HASH ARRAY);
    push @{$self->{_scalar_types}}, qw(string integer float bool);
}


sub max_depth {
    my $self = shift;
    my $max_depth = shift;

    if ( defined $max_depth ) {
        $self->{max_depth} = $max_depth;
    }

    return $self->{max_depth};
}


sub max_elements {
    my $self = shift;
    my $max_elements = shift;

    if ( defined $max_elements ) {
        $self->{max_elements} = $max_elements;
    }

    return $self->{max_elements};
}


sub generate {
    my ($self, $depth, $ref) = @_;

    $depth = 0 if not defined $depth;

    if ( $depth > $self->max_depth() ) {
        return $ref;
    }

    # decide what we're making
    my $type_count = scalar @{$self->{_types}};
    my $type = $self->{_types}[int(rand($type_count))];

    my $r; # this is the new thing we're going to make

    if ( $type eq 'HASH' ) {
        $r = $self->generate_hash();
    } 
    elsif ( $type eq 'ARRAY' ) {
        $r = $self->generate_array();
    }

    # connect $r to $ref
    if ( not defined $ref ) {
        $ref = $r;
    }
    elsif ( ref($ref) eq 'HASH' ) {
        # $ref is a hash, generate a random key and assign $r
        $ref->{$self->generate_scalar()} = $r;
    }
    elsif ( ref($ref) eq 'ARRAY' ) {
        push @{$ref}, $r;
    }

    # decide whether we should add a new level
    if ( rand(1) < 0.5 ) {
        $self->generate($depth+1, $ref);
    } 
    else {
        return $ref;
    }
}


sub generate_scalar {
    my $self = shift;

    my $type_count = scalar @{$self->{_scalar_types}};
    my $type = $self->{_scalar_types}[int(rand($type_count))];

    if ( $type eq 'float' ) {
        return rand(1);
    }
    elsif ( $type eq 'integer' ) {
        return int(rand(1_000_000));
    }
    elsif ( $type eq 'string' ) {
        return scalar(rand_chars( set => 'all', min => 6, max => 32 ));
    }
    elsif ( $type eq 'bool' ) {
        return (rand(1) < 0.5) ? 1 : 0;
    }
    else {
        croak "I don't know how to generate $type\n";
    }
}


sub generate_array {
    my $self = shift;

    my $ar = [];

    push @{$ar}, $self->generate_scalar() for 0 .. int(rand($self->max_elements()));

    $ar;
}


sub generate_hash {
    my $self = shift;

    my $hr = {};

    $hr->{$self->generate_scalar()} = $self->generate_scalar() for 0 .. int(rand($self->max_elements()));

    $hr;
}

1;

__END__

=pod

=head1 NAME

Data::Random::Structure - Generate random data structures

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Test::More;
  use Data::Random::Structure;
  use JSON::PP;

  my $g = Data::Random::Structure->new(
        max_depth => 2,
        max_elements => 5,
  );

  my $ref = $g->generate();

  diag explain $ref; 

  my $json = JSON::PP->new;

  print $json->pretty->encode($ref);

  ok(1);

  done_testing();

=head1 OVERVIEW

This is a library to create random Perl data structures, mostly as a means to
create input for benchmarking and testing various serialization libraries.

It uses grotty 'classic' Perl 5 OO mostly because I think having Moo as a
dependency for a testing module is pretty gross.  On the other hand, original
flavor Perl OO is pretty gross.

=head1 ATTRIBUTES

=head2 max_depth

The maximum depth to embed data structures

=head2 max_elements

The maximum number of elements (array items or hash key/value pairs) per data structure.

=head1 METHODS

=head2 new

Constructor. May optionally pass:

=over 4

=item * max_depth

=item * max_elements

=back

If not set, these default to 3 and 6 respectively. Throws an exception if the argument
list is not a multiple of 2.

=head2 generate

Recursively generate a data structure using hashes and arrays. The data structure
will not contain more than C<max_depth> nested data structures.

=head2 generate_scalar

Randomly generates one of the following scalar values:

=over 4

=item * float

=item * integer (between 0 and 999_999)

=item * string (see L<Data::Random> C<rand_chars>)

=item * bool (value based 50/50 coin toss)

=back

=head2 generate_array

Generate an arrayref and populate it with no more than C<max_element> items. May be
empty.

=head2 generate_hash

Generate a hashref and populate it with no more than C<max_element> key/value pairs.
May be empty.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
