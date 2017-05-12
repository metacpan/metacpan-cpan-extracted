package Algorithm::Nhash;
BEGIN {
  $Algorithm::Nhash::DIST = 'Algorithm-Nhash';
}
BEGIN {
  $Algorithm::Nhash::VERSION = '0.002';
}
# ABSTRACT: Exim nhash algorithm
use warnings;
use strict;

use Carp;

use vars qw( @ISA @EXPORT_OK );
@ISA = qw( Exporter );
@EXPORT_OK = qw( nhash );


sub new {
    my($class, @div) = @_;
    return bless \@div, $class;
}


my @primes = qw( 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79
                 83 89 97 101 103 107 109 113);

sub nhash {
    my($string, @div) = @_;
    if (ref $string) {          # called as a method
        # $string is actually $self
        ($string, @div) = ($div[0], @$string);
    }

    #warn "'$string' @div";

    my($sum, $i);
    foreach my $val (split //, $string) {
        $i += 28; $i %= 29;
        $sum += $primes[$i] * ord($val);
    }

    return $sum unless @div;
    my @ret;
    while (my $div = pop @div) {
        unshift @ret, $sum % $div;
        $sum = int($sum / $div);
    }

    return wantarray ? @ret : join '/', @ret;
}


1;

__END__
=pod

=head1 NAME

Algorithm::Nhash - Exim nhash algorithm

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Procedural usage:

 use Algorithm::Nhash qw( nhash );
 # prints 228769
 print nhash('supercalifragilisticexpialidocious');
 # prints 417 (which is 228769 % 512)
 print nhash('supercalifragilisticexpialidocious', 512);
 # prints '6/33' (6*64 + 3 == 417)
 print nhash('supercalifragilisticexpialidocious', 8, 64);
 # assigns (6, 33) to @nhash
 my @nhash = nhash('supercalifragilisticexpialidocious', 8, 64);

OO usage:

 use Algorithm::Nhash;
 my $nhash = new Algorithm::Nhash 8, 64;
 # prints '6/33'
 print $nhash->nhash('supercalifragilisticexpialidocious');

And how Exim does it:

 # prints '6/33'
 exim4 -be '${nhash_8_64:supercalifragilisticexpialidocious}'
 # prints '417' (which is 6*64+33)
 exim4 -be '${nhash_512:supercalifragilisticexpialidocious}'

=head1 DESCRIPTION

This is an implementation of the Exim nhash algorithm. It also supports an
arbitrary number of divisors and not just the one or two that Exim permits.

The nash algorithm is a fast and simple hashing algorithm that attempts to
evenly-distribute values but does not attempt to avoid collisions. Thus, it
should not be used in place of a cryptographically-secure algorithm such as
Digest::SHA. It is mainly intended for hashing filenames into directories to
avoid placing too many files into a single directory.

If nhash is not given any divisors, then the hash result is returned as-is.
If one divisor is given, the hash result is given modulo that divisor. If
more than one divisor is given, the hash result is successively divided and
the modulo at each stage returned.

Since the result is typically a 20-30 bit number, the product of all the
divisors shouldn't be more than about 2**20 or the returned values will not
be evenly-distributed.

=head1 FUNCTIONS AND METHODS

=head2 new

 use Algorithm::Nhash;
 my $nhash = new Algorithm::Nhash 8, 64;

This creates a new Algorithm::Nhash object that squirrels away the divisors
for later use.

=head2 nhash

 # OO invocation
 print $nhash->nhash('supercalifragilisticexpialidocious');

 # procedural invocation
 print nhash('supercalifragilisticexpialidocious', 8, 64);

This calculates the nhash of the given string. In scalar context, it returns
the nhash values as a string with slashes separating the components, like
C<"6/33">. In list context, it returns a list of values like C<(6, 33)>.

=head1 SEE ALSO

http://www.exim.org/exim-html-current/doc/html/spec_html/ch11.html (search
for nhash.)

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

