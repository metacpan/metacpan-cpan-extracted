use 5.008001;
use strict;
use warnings;

package Data::Fake::Core;
# ABSTRACT: General purpose generators

our $VERSION = '0.005';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_hash
  fake_array
  fake_flatten
  fake_pick
  fake_binomial
  fake_weighted
  fake_int
  fake_float
  fake_digits
  fake_template
  fake_join
);

our @EXPORT_OK = qw/_transform/;

use Carp qw/croak/;
use List::Util qw/sum/;

#pod =func fake_hash
#pod
#pod     $generator = fake_hash(
#pod         {
#pod             name => fake_name,
#pod             pet => fake_pick(qw/dog cat frog/),
#pod         }
#pod     );
#pod
#pod     $generator = fake_hash( @hash_or_hash_generators );
#pod
#pod The C<fake_hash> function returns a code reference that, when run,
#pod generates a hash reference.
#pod
#pod The simplest way to use it is to provide a hash reference with some values
#pod replaced with C<fake_*> generator functions.  When the generator runs, the
#pod hash will be walked recursively and any code reference found will be
#pod replaced with its output.
#pod
#pod If more than one argument is provided, when the generator runs, they will
#pod be merged according to the following rules:
#pod
#pod =for :list
#pod * code references will be replaced with their outputs
#pod * after replacement, if any arguments aren't hash references, an exception
#pod   will be thrown
#pod * hash references will be shallow-merged
#pod
#pod This merging allows for generating sections of hashes differently or
#pod generating hashes that have missing keys (e.g. using L</fake_binomial>):
#pod
#pod     # 25% of the time, generate a hash with a 'spouse' key
#pod     $factory = fake_hash(
#pod         { ... },
#pod         fake_binomial( 0.25, { spouse => fake_name() }, {} ),
#pod     );
#pod
#pod =cut

sub fake_hash {
    my (@parts) = @_;
    return sub {
        my $result = {};
        for my $next ( map { _transform($_) } @parts ) {
            croak "fake_hash can only merge hash references"
              unless ref($next) eq 'HASH';
            @{$result}{ keys %$next } = @{$next}{ keys %$next };
        }
        return $result;
    };
}

#pod =func fake_array
#pod
#pod     $generator = fake_array( 5, fake_digits("###-###-####") );
#pod
#pod The C<fake_array> takes a positive integer size and source argument and
#pod returns a generator that returns an array reference with each element built
#pod from the source.
#pod
#pod If the size is a code reference, it will be run and can set a different size
#pod for every array generated:
#pod
#pod     # arrays from size 1 to size 6
#pod     $generator = fake_array( fake_int(1,6), fake_digits("###-###-###") );
#pod
#pod If the source is a code reference, it will be run; if the source is a hash
#pod or array reference, it will be recursively evaluated like C<fake_hash>.
#pod
#pod =cut

sub fake_array {
    my ( $size, $template ) = @_;
    return sub {
        [ map { _transform($template) } 1 .. _transform($size) ];
    };
}

#pod =func fake_pick
#pod
#pod     $generator = fake_pick( qw/one two three/ );
#pod     $generator = fake_pick( @generators );
#pod
#pod Given literal values or code references, returns a generator that randomly
#pod selects one of them with equal probability.  If the choice is a code
#pod reference, it will be run; if the choice is a hash or array reference, it
#pod will be recursively evaluated like C<fake_hash> or C<fake_array> would do.
#pod
#pod =cut

sub fake_pick {
    my (@list) = @_;
    my $size = scalar @list;
    return sub { _transform( $list[ int( rand($size) ) ] ) };
}

#pod =func fake_binomial
#pod
#pod     $generator = fake_binomial(
#pod         0.90,
#pod         { name => fake_name() }, # 90% likely
#pod         {},                      # 10% likely
#pod     );
#pod
#pod     $generator = fake_binomial( $prob, $lte_outcome, $gt_outcome );
#pod
#pod The C<fake_binomial> function takes a probability and two outcomes.  The
#pod probability (between 0 and 1.0) indicates the likelihood that the return
#pod value will the first outcome.  The rest of the time, the return value will
#pod be the second outcome.  If the outcome is a code reference, it will be run;
#pod if the outcome is a hash or array reference, it will be recursively
#pod evaluated like C<fake_hash> or C<fake_array> would do.
#pod
#pod =cut

sub fake_binomial {
    my ( $prob, $first, $second ) = @_;
    croak "fake_binomial probability must be between 0 and 1.0"
      unless defined($prob) && $prob >= 0 && $prob <= 1.0;
    return sub {
        return _transform( rand() <= $prob ? $first : $second );
    };
}

#pod =func fake_weighted
#pod
#pod     $generator = fake_weighted(
#pod         [ 'a_choice',          1 ],
#pod         [ 'ten_times_likely', 10 ],
#pod         [ $another_generator,  1 ],
#pod     );
#pod
#pod Given a list of array references, each containing a value and a
#pod non-negative weight, returns a generator that randomly selects a value
#pod according to the relative weights.
#pod
#pod If the value is a code reference, it will be run; if it is a hash or array
#pod reference, it will be recursively evaluated like C<fake_hash> or C<fake_array>
#pod would do.
#pod
#pod =cut

sub fake_weighted {
    my (@list) = @_;
    return sub { }
      unless @list;

    if ( @list != grep { ref($_) eq 'ARRAY' } @list ) {
        croak("fake_weighted requires a list of array references");
    }

    # normalize weights into cumulative probabilities
    my $sum = sum( 0, map { $_->[1] } @list );
    my $max = 0;
    for my $s (@list) {
        $s->[1] = $max += $s->[1] / $sum;
    }
    my $last = pop @list;

    return sub {
        my $rand = rand();
        for my $s (@list) {
            return _transform( $s->[0] ) if $rand <= $s->[1];
        }
        return _transform( $last->[0] );
    };
}

#pod =func fake_int
#pod
#pod     $generator = fake_int(1, 6);
#pod
#pod Given a minimum and a maximum value as inputs, returns a generator that
#pod will produce a random integer in that range.
#pod
#pod =cut

sub fake_int {
    my ( $min, $max ) = map { int($_) } @_;
    croak "fake_int requires minimum and maximum"
      unless defined $min && defined $max;
    my $range = $max - $min + 1;
    return sub {
        return $min + int( rand($range) );
    };
}

#pod =func fake_float
#pod
#pod     $generator = fake_float(1.0, 6.0);
#pod
#pod Given a minimum and a maximum value as inputs, returns a generator that
#pod will produce a random floating point value in that range.
#pod
#pod =cut

sub fake_float {
    my ( $min, $max ) = @_;
    croak "fake_float requires minimum and maximum"
      unless defined $min && defined $max;
    my $range = $max - $min;
    return sub {
        return $min + rand($range);
    };
}

#pod =func fake_digits
#pod
#pod     $generator = fake_digits('###-####'); # "555-1234"
#pod     $generator = fake_digits('\###');     # "#12"
#pod
#pod Given a text pattern, returns a generator that replaces all occurrences of
#pod the sharp character (C<#>) with a randomly selected digit.  To have a
#pod literal sharp character, escape it with a backslash (do it in a
#pod single-quoted string to avoid having to double your backslash to get a
#pod backslash in the string.).
#pod
#pod Use this for phone numbers, currencies, or whatever else needs random
#pod digits:
#pod
#pod     fake_digits('###-##-####');     # US Social Security Number
#pod     fake_digits('(###) ###-####');  # (800) 555-1212
#pod
#pod =cut

my $DIGIT_RE = qr/(?<!\\)#/;

sub fake_digits {
    my ($template) = @_;
    return sub {
        my $copy = $template;
        1 while $copy =~ s{$DIGIT_RE}{int(rand(10))}e;
        $copy =~ s{\\#}{#}g;
        return $copy;
    };
}

#pod =func fake_template
#pod
#pod     $generator = fake_template("Hello, %s", fake_name());
#pod
#pod Given a sprintf-style text pattern and a list of generators, returns a
#pod generator that, when run, executes the generators and returns the string
#pod populated with the output.
#pod
#pod Use this for creating custom generators from other generators.
#pod
#pod =cut

sub fake_template {
    my ( $template, @args ) = @_;
    return sub {
        return sprintf( $template, map { _transform($_) } @args );
    };
}

#pod =func fake_join
#pod
#pod     $generator = fake_join(" ", fake_first_name(), fake_surname() );
#pod
#pod Given a character to join on a list of literals or generators, returns a
#pod generator that, when run, executes any generators and returns them concatenated
#pod together, separated by the separator character.
#pod
#pod The separator itself may also be a generator if you want that degree of
#pod randomness as well.
#pod
#pod     $generator = fake_join( fake_pick( q{}, q{ }, q{,} ), @args );
#pod
#pod =cut

sub fake_join {
    my ( $char, @args ) = @_;
    return sub {
        return join( _transform($char), map { _transform($_) } @args );
    };
}

#pod =func fake_flatten
#pod
#pod     $flatten_generator = fake_flatten( fake_array( 3, fake_first_name() ) );
#pod     @array_of_names = $flatten_generator->();
#pod
#pod Given a generator that returns an array ref (such as fake_array) or a
#pod hash ref (fake_hash), fake_flatten returns a generator that, when run,
#pod executes the generators and returns their result in a dereferenced state.
#pod
#pod This is particularly useful when the return value is used directly as
#pod input to another function, for example within a fake_join.
#pod
#pod     $generator = fake_join( " ", $flatten_generator );
#pod
#pod =cut

sub fake_flatten {
    my ($ref) = @_;

    return sub {
        my $result     = _transform($ref);
        my $result_ref = ref($result);
        if ( $result_ref eq 'ARRAY' ) {
            return @$result;
        }
        elsif ( $result_ref eq 'HASH' ) {
            return %$result;
        }

        croak "I do not know how to flatten a $result_ref";
      }
}

sub _transform {
    my ($template) = @_;

    my $type = ref($template);

    if ( $type eq 'CODE' ) {
        return $template->();
    }
    elsif ( $type eq 'HASH' ) {
        my $copy = {};
        while ( my ( $k, $v ) = each %$template ) {
            $copy->{$k} =
                ref($v) eq 'CODE'  ? $v->()
              : ref($v) eq 'HASH'  ? _transform($v)
              : ref($v) eq 'ARRAY' ? _transform($v)
              :                      $v;
        }
        return $copy;
    }
    elsif ( $type eq 'ARRAY' ) {
        my @copy = map {
                ref $_ eq 'CODE'  ? $_->()
              : ref $_ eq 'HASH'  ? _transform($_)
              : ref $_ eq 'ARRAY' ? _transform($_)
              :                     $_;
        } @$template;
        return \@copy;
    }
    else {
        # literal value
        return $template;
    }
}

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Core - General purpose generators

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Data::Fake::Core;

    $generator = fake_hash(
        {
            ssn             => fake_digits("###-##-###"),
            phrase          => fake_template(
                                "%s world", fake_pick(qw/hello goodbye/)
                               ),
            die_rolls       => fake_array( 3, fake_int(1, 6) ),
            temperature     => fake_float(-20.0, 120.0),
        }
    );

=head1 DESCRIPTION

This module provides a general-purpose set of fake data functions to generate
structured data, numeric data, structured strings, and weighted alternatives.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_hash

    $generator = fake_hash(
        {
            name => fake_name,
            pet => fake_pick(qw/dog cat frog/),
        }
    );

    $generator = fake_hash( @hash_or_hash_generators );

The C<fake_hash> function returns a code reference that, when run,
generates a hash reference.

The simplest way to use it is to provide a hash reference with some values
replaced with C<fake_*> generator functions.  When the generator runs, the
hash will be walked recursively and any code reference found will be
replaced with its output.

If more than one argument is provided, when the generator runs, they will
be merged according to the following rules:

=over 4

=item *

code references will be replaced with their outputs

=item *

after replacement, if any arguments aren't hash references, an exception will be thrown

=item *

hash references will be shallow-merged

=back

This merging allows for generating sections of hashes differently or
generating hashes that have missing keys (e.g. using L</fake_binomial>):

    # 25% of the time, generate a hash with a 'spouse' key
    $factory = fake_hash(
        { ... },
        fake_binomial( 0.25, { spouse => fake_name() }, {} ),
    );

=head2 fake_array

    $generator = fake_array( 5, fake_digits("###-###-####") );

The C<fake_array> takes a positive integer size and source argument and
returns a generator that returns an array reference with each element built
from the source.

If the size is a code reference, it will be run and can set a different size
for every array generated:

    # arrays from size 1 to size 6
    $generator = fake_array( fake_int(1,6), fake_digits("###-###-###") );

If the source is a code reference, it will be run; if the source is a hash
or array reference, it will be recursively evaluated like C<fake_hash>.

=head2 fake_pick

    $generator = fake_pick( qw/one two three/ );
    $generator = fake_pick( @generators );

Given literal values or code references, returns a generator that randomly
selects one of them with equal probability.  If the choice is a code
reference, it will be run; if the choice is a hash or array reference, it
will be recursively evaluated like C<fake_hash> or C<fake_array> would do.

=head2 fake_binomial

    $generator = fake_binomial(
        0.90,
        { name => fake_name() }, # 90% likely
        {},                      # 10% likely
    );

    $generator = fake_binomial( $prob, $lte_outcome, $gt_outcome );

The C<fake_binomial> function takes a probability and two outcomes.  The
probability (between 0 and 1.0) indicates the likelihood that the return
value will the first outcome.  The rest of the time, the return value will
be the second outcome.  If the outcome is a code reference, it will be run;
if the outcome is a hash or array reference, it will be recursively
evaluated like C<fake_hash> or C<fake_array> would do.

=head2 fake_weighted

    $generator = fake_weighted(
        [ 'a_choice',          1 ],
        [ 'ten_times_likely', 10 ],
        [ $another_generator,  1 ],
    );

Given a list of array references, each containing a value and a
non-negative weight, returns a generator that randomly selects a value
according to the relative weights.

If the value is a code reference, it will be run; if it is a hash or array
reference, it will be recursively evaluated like C<fake_hash> or C<fake_array>
would do.

=head2 fake_int

    $generator = fake_int(1, 6);

Given a minimum and a maximum value as inputs, returns a generator that
will produce a random integer in that range.

=head2 fake_float

    $generator = fake_float(1.0, 6.0);

Given a minimum and a maximum value as inputs, returns a generator that
will produce a random floating point value in that range.

=head2 fake_digits

    $generator = fake_digits('###-####'); # "555-1234"
    $generator = fake_digits('\###');     # "#12"

Given a text pattern, returns a generator that replaces all occurrences of
the sharp character (C<#>) with a randomly selected digit.  To have a
literal sharp character, escape it with a backslash (do it in a
single-quoted string to avoid having to double your backslash to get a
backslash in the string.).

Use this for phone numbers, currencies, or whatever else needs random
digits:

    fake_digits('###-##-####');     # US Social Security Number
    fake_digits('(###) ###-####');  # (800) 555-1212

=head2 fake_template

    $generator = fake_template("Hello, %s", fake_name());

Given a sprintf-style text pattern and a list of generators, returns a
generator that, when run, executes the generators and returns the string
populated with the output.

Use this for creating custom generators from other generators.

=head2 fake_join

    $generator = fake_join(" ", fake_first_name(), fake_surname() );

Given a character to join on a list of literals or generators, returns a
generator that, when run, executes any generators and returns them concatenated
together, separated by the separator character.

The separator itself may also be a generator if you want that degree of
randomness as well.

    $generator = fake_join( fake_pick( q{}, q{ }, q{,} ), @args );

=head2 fake_flatten

    $flatten_generator = fake_flatten( fake_array( 3, fake_first_name() ) );
    @array_of_names = $flatten_generator->();

Given a generator that returns an array ref (such as fake_array) or a
hash ref (fake_hash), fake_flatten returns a generator that, when run,
executes the generators and returns their result in a dereferenced state.

This is particularly useful when the return value is used directly as
input to another function, for example within a fake_join.

    $generator = fake_join( " ", $flatten_generator );

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
