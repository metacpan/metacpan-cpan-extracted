package Data::Decrement;

our $DATE = '2019-01-26'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use Carp;

use Exporter qw(import);
our @EXPORT_OK = qw(decr);

sub decr {
    my $val = shift;

    return -1 unless defined $val;
    return $val-1 unless $val =~ /^[a-zA-Z]*[0-9]*\z/;

    my @digits = split //, $val;
    my $carry = 0;
    for (my $i = $#digits; $i >= 0; $i--) {
        my $digit = $digits[$i];
        if ($digit eq 'a') {
            do { carp "Cannot decrement '$val'"; return $val } unless $i;
            $digit = 'z'; $carry++;
        } elsif ($digit eq 'A') {
            do { carp "Cannot decrement '$val'"; return $val } unless $i;
            $digit = 'Z'; $carry++;
        } elsif ($digit eq '0') {
            do { carp "Cannot decrement '$val'"; return $val } unless $i;
            $digit = '9'; $carry++;
        } else {
            $digit = chr(ord($digit)-1);
        }
        $digits[$i] = $digit;
        last unless $carry--;
    }

    join '', @digits;
}

1;
# ABSTRACT: Provide extra magic logic for auto-decrement

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Decrement - Provide extra magic logic for auto-decrement

=head1 VERSION

This document describes version 0.002 of Data::Decrement (from Perl distribution Data-Decrement), released on 2019-01-26.

=head1 SYNOPSIS

 use Data::Decrement 'decr';

 print decr("b00"); # prints "a99"

=head1 DESCRIPTION

Perl's auto-increment operator (C<++>) has some convenience feature built in.
Quoting L<perlop>:

 The auto-increment operator has a little extra builtin magic to it. If you
 increment a variable that is numeric, or that has ever been used in a numeric
 context, you get a normal increment. If, however, the variable has been used in
 only string contexts since it was set, and has a value that is not the empty
 string and matches the pattern "/^[a-zA-Z]*[0-9]*\z/", the increment is done as
 a string, preserving each character within its range, with carry:

  print ++($foo = "99");      # prints "100"
  print ++($foo = "a0");      # prints "a1"
  print ++($foo = "Az");      # prints "Ba"
  print ++($foo = "zz");      # prints "aaa"

 "undef" is always treated as numeric, and in particular is changed to 0 before
 incrementing (so that a post-increment of an undef value will return 0 rather
 than "undef").

 The auto-decrement operator is not magical.

This module provides the C<decr()> function to do the decrement equivalent,
although it is not exactly the reverse of the increment operation. In general,
the rule is that C<decr(++$a)> should return the same value as the original
C<$a> before the auto-increment, with a couple of exception.

=over

=item * Positive integers are decremented as string

Positive integers, including those with zero prefix, are decremented as string.

 print decr(-123);            # prints "-124", treated as number
 print decr(123);             # prints "122", treated as string
 print decr(100);             # prints "099", treated as string

"undef" like in auto-increment is treated as number 0.

 print decr(undef);            # prints "-1", treated as number

=item * Decrementing is not done when leftmost digit is already "A", "a", or 0

When carrying over to the left-most digit, and the digit is already "A", "a", or
"0", decrementing is not done. The original value is returned and a warning
"Cannot decrement '<VALUE>'" is issued. Examples:

 print decr(0);               # prints "0", warns "Cannot decrement '0'"
 print decr("a1");            # prints "a0"
 print decr("b0");            # prints "a9"
 print decr("a0");            # prints "a0", warns "Cannot decrement 'a0'"
 print decr("bZz0");          # prints "bZy9"
 print decr("bZa0");          # prints "bYz9"
 print decr("bAa0");          # prints "aZz9"
 print decr("aAa0");          # prints "aAa0", warns "Cannot decrement 'aAa0'"

=back

=head1 FUNCTIONS

=head2 decr

Usage:

 decr($val) => $dec_val

Accept a value and return decremented value. If I<$val> matches the pattern C<<
/^[a-zA-Z]*[0-9]*\z/ >>, it will decremented as a string (note that positive
integers match this pattern). Otherwise, it will be decremented numerically.
C<undef> is regarded as numeric 0.

Will return the original value and emit a warning if cannot decrement a value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Decrement>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Decrement>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Decrement>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<++> in L<perlop>

L<dec-pl> in L<App::IncrementUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
