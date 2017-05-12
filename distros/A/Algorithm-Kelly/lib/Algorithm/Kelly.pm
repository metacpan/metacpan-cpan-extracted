use strict;
use warnings;
package Algorithm::Kelly;
$Algorithm::Kelly::VERSION = '0.03';
# ABSTRACT: calculates the fraction of a bankroll to bet using the Kelly formula

BEGIN
{
  require Exporter;
  use base 'Exporter';
  our @EXPORT = 'optimal_f';
}



sub optimal_f
{
  my ($probability, $payoff) = @_;

  unless (defined $probability
          && $probability >= 0
          && $probability <= 1
          && $payoff
          && $payoff > 0)
  {
    die "optimal_f() requires 2 args: probability (0-1) and payoff\n";
  }

  ($probability * $payoff - (1 - $probability)) / $payoff;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Kelly - calculates the fraction of a bankroll to bet using the Kelly formula

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Algorithm::Kelly;
    use feature 'say';

    say optimal_f(0.5, 2); # 0.25

=head1 FUNCTIONS

=head2 optimal_f ($probability, $payoff)

Returns the optimal L<fraction|https://en.wikipedia.org/wiki/Kelly_criterion> of bankroll to wager, using the Kelly Criterion, given the C<$probability> and C<$payoff>. Payoff should be the net odds of the wager, so the value of 3-to-1 would be 3. The C<optimal_f()> sub is exported by default.

=head1 CONVERTING ODDS

Odds are usually presented in one of three styles: decimal, fraction or American. The C<optimal_f> sub requires the net decimal odds. These odds are all equal:

    Type      Example    Net Odds
    ----      --------   --------
    Decimal   4.0        3.0
    Fraction  3/1        3.0
    American  +300       3.0

The different odds representations are also explained L<here|http://www.olbg.com/school/lesson10.htm>.

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
