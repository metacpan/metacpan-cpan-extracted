package Business::CUSIP;

=pod

=head1 NAME

Business::CUSIP - Verify Committee on Uniform Security Identification Procedures Numbers

=head1 SYNOPSIS

  use Business::CUSIP;
  $csp = Business::CUSIP->new('035231AH2');
  print "Looks good.\n" if $csp->is_valid;

  $csp = Business::CUSIP->new('392690QT', 1);
  $chk = $csp->check_digit;
  $csp->cusip($csp->cusip.$chk);
  print $csp->is_valid ? "Looks good." : "Invalid: ", $Business::CUSIP::ERROR, "\n";

=head1 DESCRIPTION

This module verifies CUSIPs, which are financial identifiers issued by the
Standard & Poor's Company for US and Canadian securities. This module cannot
tell if a CUSIP references a real security, but it can tell you if the given
CUSIP is properly formatted.

=cut

use strict;
use Algorithm::LUHN ();
#  Add additional characters to Algorithm::LUHN::valid_chars so CUSIPs can be
# validated. 
{
my $ct = 10;
Algorithm::LUHN::valid_chars(map {$_ => $ct++} 'A'..'Z');
}
Algorithm::LUHN::valid_chars('*',36, '@',37, '#',38);

use vars qw($VERSION $ERROR);

$VERSION = '1.03';

=head1 METHODS

=over 4

=item new([CUSIP_NUMBER[, IS_FIXED_INCOME]])

The new constructor takes two optional arguments: the CUSIP number and a Boolean
value signifying whether this CUSIP refers to a fixed income security. CUSIPs
for fixed income securities are validated a little differently than other
CUSIPs.

=cut
sub new {
  my ($class, $cusip, $fixed_income) = @_;
  bless [$cusip, ($fixed_income || 0)], $class;
}

=item cusip([CUSIP_NUMBER])

If no argument is given to this method, it will return the current CUSIP
number. If an argument is provided, it will set the CUSIP number and then
return the CUSIP number.

=cut
sub cusip {
  my $self = shift;
  $self->[0] = shift if @_;
  return $self->[0];
}

=item is_fixed_income([TRUE_OR_FALSE])

If no argument is given to this method, it will return whether the CUSIP object
is marked as a fixed income security. If an argument is provided, it will set
the fixed income property and then return the fixed income setting.

=cut
sub is_fixed_income {
  my $self = shift;
  $self->[1] = shift if @_;
  return $self->[1];
}

=item issuer_num()

Returns the issuer number from the CUSIP number.

=cut
sub issuer_num {
  my $self = shift;
  return substr($self->cusip, 0, 6);
}

=item issue_num()

Returns the issue number from the CUSIP number.

=cut
sub issue_num {
  my $self = shift;
  return substr($self->cusip, 6, 2);
}

=item is_valid()

Returns true if the checksum of the CUSIP is correct otherwise it returns
false and $Business::CUSIP::ERROR will contain a description of the problem.

=cut
sub is_valid {
  my $self = shift;
  my $val = $self->cusip;

  $ERROR = undef;

  # CUSIPs are 9 digits. Chars 1-3 are numeric. Chars 4-8 are alphanum
  # plus '@', '#', '*'. Char 9 is numeric.
  unless (length($val) == 9) {
    $ERROR = "CUSIP must be 9 characters long.";
    return '';
  }
  unless ($val =~ /^\d{3}/) {
    $ERROR = "Characters 1-3 must be numeric.";
    return '';
  }
  unless ($val =~ /^.{3}[A-Z0-9@#*]{5}/) {
    $ERROR = "Characters 4-8 must be A-Z, 0-9, @, #, *.";
    return '';
  }
  unless ($val =~ /\d$/) {
    $ERROR = "Character 9 (the check digit) must be numeric.";
    return '';
  }

  # From the CUSIP spec:
  #   To avoid confusion, the fixed income issue number assignments have
  #   omitted the alphabetic "I" and numeric "1 " as well as the alphabetic
  #   ''O'' and numeric zero.
  # The issuer number is in positions 7 & 8.
  if ($self->is_fixed_income && substr($self->cusip,6,2) =~ /[I1O0]/) {
   $ERROR="Fixed income CUSIP cannot contain I, 1, O, or 0 in the issue number.";
    return '';
  }

  my $r = Algorithm::LUHN::is_valid($self->cusip);
  $ERROR = $Algorithm::LUHN::ERROR unless $r;
  return $r;
}

=item error()

If the CUSIP object is not valid (! is_valid()) it returns the reason it is 
not valid. Otherwise returns undef.

=cut
sub error {
  shift->is_valid;
  return $ERROR;
}

=item check_digit()

This method returns the checksum of the given object. If the CUSIP number of
the object contains a check_digit, it is ignored. In other words this method
recalculates the check_digit each time.

=cut
sub check_digit {
  my $self = shift;
  my $r = Algorithm::LUHN::check_digit(substr($self->cusip(), 0, 8));
  $ERROR = $Algorithm::LUHN::ERROR unless defined $r;
  return $r;
}

1;
__END__
=back

=head1 CAVEATS

This module uses the Algorithm::LUHN module and it adds characters to the
C<valid_chars> map of Algorithm::LUHN. So if you rely on the default valid
map in the same program you use Business::CUSIP you might be surprised.

=head1 AUTHOR

This module was written by
Tim Ayers (http://search.cpan.org/search?author=TAYERS).

=head1 COPYRIGHT

Copyright (c) 2001 Tim Ayers. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

General CUSIP information may be found at http://www.cusip.com.

=cut
