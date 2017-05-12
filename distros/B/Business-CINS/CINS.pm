package Business::CINS;

=pod

=head1 NAME

Business::CINS - Verify CUSIP International Numbering System Numbers

=head1 SYNOPSIS

  use Business::CINS;
  $cn = Business::CINS->new('035231AH2');
  print "Looks good.\n" if $cn->is_valid;

  $cn = Business::CINS->new('392690QT', 1);
  $chk = $cn->check_digit;
  $cn->cins($cn->cins.$chk);
  print $cn->is_valid ? "Looks good." : "Invalid: ", $cn->error, "\n";

=head1 DESCRIPTION

This module verifies CINSes, which are financial identifiers issued by the
Standard & Poor's Company for US and Canadian securities. This module cannot
tell if a CINS references a real security, but it can tell you if the given
CINS is properly formatted.

=cut

use strict;
use Algorithm::LUHN ();
#  Add additional characters to Algorithm::LUHN::valid_chars so CUSIPs can be
# validated. 
{
my $ct = 10;
Algorithm::LUHN::valid_chars(map {$_ => $ct++} 'A'..'Z');
}
#Algorithm::LUHN::valid_chars('*',36, '@',37, '#',38);

use vars qw($VERSION $ERROR);

$VERSION = '1.13';

=head1 METHODS

=over 4

=item new([CINS_NUMBER[, IS_FIXED_INCOME]])

The new constructor takes two optional arguments: the CINS number and a Boolean
value signifying whether this CINS refers to a fixed income security. CINSes
for fixed income securities are validated a little differently than other
CINSes.

=cut
sub new {
  my ($class, $cins, $fixed_income) = @_;
  bless [$cins, ($fixed_income || 0)], $class;
}

=item cins([CINS_NUMBER])

If no argument is given to this method, it will return the current CINS
number. If an argument is provided, it will set the CINS number and then
return the CINS number.

=cut
sub cins {
  my $self = shift;
  $self->[0] = shift if @_;
  return $self->[0];
}

=item is_fixed_income([TRUE_OR_FALSE])

If no argument is given to this method, it will return whether the CINS object
is marked as a fixed income security. If an argument is provided, it will set
the fixed income property and then return the fixed income setting.

=cut
sub is_fixed_income {
  my $self = shift;
  $self->[1] = shift if @_;
  return $self->[1];
}

=item domicile_code ()

Returns the domicile code from the CINS number.

=cut
sub domicile_code {
  my $self = shift;
  return substr($self->cins, 0, 1);
}

=item issuer_num()

Returns the issuer number from the CINS number.

=cut
sub issuer_num {
  my $self = shift;
  return substr($self->cins, 1, 5);
}

=item issuer_num()

Returns the issue number from the CINS number.

=cut
sub issue_num {
  my $self = shift;
  return substr($self->cins, 6, 2);
}

=item is_valid()

Returns true if the checksum of the CINS is correct otherwise it returns
false and $Business::CINS::ERROR will contain a description of the problem.

=cut
sub is_valid {
  my $self = shift;
  my $val = $self->cins;

  $ERROR = undef;

  # The CINS number consists of nine characters. The first six (6) positions,
  # known as the issuer number, consist of a country or regional alpha code of
  # one character, plus five positions, the last of which may be alpha or
  # numeric. A two character suffix (either numeric or alphabetic or both)
  # known as the issue number follows. The ninth character is a check digit.

  unless (length($val) == 9) {
    $ERROR = "CINS must be 9 characters long.";
    return '';
  }
  unless (Business::CINS->domicile_descr($self->domicile_code)) {
    $ERROR = "First character is not a valid domicile code.";
    return '';
  }
#    unless ($val =~ /^.\d{4}/) {
#      $ERROR = "Characters 2-5 must be numeric.";
#      return '';
#    }
  unless ($val =~ /^.[A-Z0-9]{7}/) {
    $ERROR = "Characters 2-8 must be A-Z, 0-9.";
    return '';
  }
  unless ($val =~ /\d$/) {
    $ERROR = "Character 9 (the check digit) must be numeric.";
    return '';
  }

  # From the CINS spec:

  # Issue Numbers for Fixed Income Securities: The issue number assigned to an
  # issuer's fixed income securities may consist of two alphabetic characters
  # (AA, etc.), one alphabetic character followed by one digit (A2, etc.) or
  # one digit followed by one alphabetic character (2A, etc.), assigned in that
  # order. Debt securities will be sorted in order by their maturity dates.
  if ($self->is_fixed_income) {
    my $issue_num = $self->issue_num;
    if ($issue_num !~ /^[A-Z][A-Z]$/ and
        $issue_num !~ /^[A-Z][0-9]$/ and
        $issue_num !~ /^[0-9][A-Z]$/) {
      $ERROR = "Fixed income issue number must be alpha-alpha, alpha-num or num-alpha only.";
      return '';
    }
  }

  my $r = Algorithm::LUHN::is_valid($self->cins);
  $ERROR = $Algorithm::LUHN::ERROR unless $r;
  return $r;
}

=item error()

If the CINS object is not valid (! is_valid()) it returns the reason it is 
Not valid. Otherwise returns undef.

=cut
sub error {
  shift->is_valid;
  return $ERROR;
}

=item check_digit()

This method returns the checksum of the given object. If the CINS number of
the object contains a check_digit, it is ignored. In other words this method
recalculates the check_digit each time.

=cut
sub check_digit {
  my $self = shift;
  my $r = Algorithm::LUHN::check_digit(substr($self->cins(), 0, 8));
  $ERROR = $Algorithm::LUHN::ERROR unless defined $r;
  return $r;
}

=item Business::CINS->domicile_descr([CODE])

Given a domicile code it will return a description of the code. The valid 
domicile codes are

  A = Austria         J = Japan          S = South Africa
  B = Belgium         K = Denmark        T = Italy
  C = Canada          L = Luxembourg     U = United States
  D = Germany         M = Mid-East       V = Africa - Other
  E = Spain           N = Netherlands    W = Sweden
  F = France          P = South America  X = Europe-Other
  G = United Kingdom  Q = Australia      Y = Asia
  H = Switzerland     R = Norway

If no CODE is given, it will return the hash of codes.

=cut
{
my %domicile_cds =
  (A => 'Austria',        J => 'Japan',         S => 'South Africa',
   B => 'Belgium',        K => 'Denmark',       T => 'Italy',
   C => 'Canada',         L => 'Luxembourg',    U => 'United States',
   D => 'Germany',        M => 'Mid-East',      V => 'Africa - Other',
   E => 'Spain',          N => 'Netherlands',   W => 'Sweden',
   F => 'France',         P => 'South America', X => 'Europe-Other',
   G => 'United Kingdom', Q => 'Australia',     Y => 'Asia',
   H => 'Switzerland',    R => 'Norway',
);
sub domicile_descr {
  shift; # ignore the first argument.
  return (@_ ? $domicile_cds{$_[0]} : %domicile_cds);
}
}

1;
__END__
=back

=head1 CAVEATS

This module uses the Algorithm::LUHN module and it adds characters to the
C<valid_chars> map of Algorithm::LUHN. So if you rely on the default valid
map in the same program you use Business::CINS you might be surprised.

=head1 AUTHOR

This module was written by
Tim Ayers (http://search.cpan.org/search?author=TAYERS).

=head1 COPYRIGHT

Copyright (c) 2001 Tim Ayers. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

General information about CINS can be found at 
http://http://www.cusip.com/cusip/intrnal.html.

=cut
