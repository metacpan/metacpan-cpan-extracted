package Business::SEDOL;

=pod

=head1 NAME

Business::SEDOL - Verify Stock Exchange Daily Official List Numbers

=head1 SYNOPSIS

  use Business::SEDOL;
  $sdl = Business::SEDOL->new('0325015');
  print "Looks good.\n" if $sdl->is_valid;

  $sdl = Business::SEDOL->new('0123457');
  $chk = $sdl->check_digit;
  $sdl->sedol($sdl->sedol.$chk);
  print $sdl->is_valid ? "Looks good." : "Invalid: ", $sdl->error, "\n";

=head1 DESCRIPTION

This module verifies SEDOLs, which are British securities identification
codes. This module cannot tell if a SEDOL references a real security, but it
can tell you if the given SEDOL is properly formatted. It handles both the
old-style SEDOLs (SEDOLs issued prior to 26 January 2004) and new-style SEDOLs.

=cut

use strict;
use vars qw($VERSION $ERROR);

$VERSION = '2.01';

# Global variables used by many.
# SEDOLs can basically be comprised of 0..9 and B..Z excluding vowels.
my %valid_chars = map {$_ => $a++} 0..9, 'A'..'Z';
delete @valid_chars{qw/A E I O U/};
my $valid_alpha = join('',grep /\w/, sort keys %valid_chars);
my @weights = (1, 3, 1, 7, 3, 9, 1);

=head1 METHODS

=over 4

=item new([SEDOL_NUMBER])

The new constructor optionally takes the SEDOL number.

=cut
sub new {
  my ($class, $sedol) = @_;
  bless \$sedol, $class;
}

=item sedol([SEDOL_NUMBER])

If no argument is given to this method, it will return the current SEDOL
number. If an argument is provided, it will set the SEDOL number and then
return the SEDOL number.

=cut
sub sedol {
  my $self = shift;
  $$self = shift if @_;
  return $$self;
}

=item series()

Returns the series number of the SEDOL.

=cut
sub series {
  my $self = shift;
  return substr($self->sedol, 0, 1);
}

sub _check_format {
  my $val = shift;

  $ERROR = undef;

  if (length($val) != 7) {
    $ERROR = "SEDOLs must be 7 characters long.";
    return '';
  }

  if ($val =~ /^\d/) {
    # assume old-style
    if ($val =~ /\D/) {
      $ERROR = "Old-style SEDOLs must contain only numerals.";
      return '';
    }
  } else {
    # assume new-style
    if ($val !~ /^[$valid_alpha]/o) {
      $ERROR = "New-style SEDOL must have alphabetic first character.";
      return '';
    } elsif ($val !~ /^.[\d$valid_alpha]{5}/o) {
      $ERROR = "New-style SEDOL must have alphanumeric characters 2-6.";
      return '';
    } elsif ($val =~ /\D$/) {
      $ERROR = "SEDOL checkdigit (character 7) must be numeric.";
      return '';
    }
  }
  return 1;
}

=item is_valid()

Returns true if the checksum of the SEDOL is correct otherwise it returns
false and $Business::SEDOL::ERROR will contain a description of the problem.

=cut
sub is_valid {
  my $self = shift;
  my $val = $self->sedol;

  return '' unless _check_format($val);

  my $c = $self->check_digit;
  if (substr($self->sedol, -1, 1) eq $c) {
    return 1;
  } else {
    $ERROR = "Check digit not correct. Expected $c.";
    return '';
  }
}

=item error()

If the SEDOL object is not valid (! is_valid()) it returns the reason it is 
not valid. Otherwise returns undef.

=cut
sub error {
  shift->is_valid;
  return $ERROR;
}

=item check_digit()

This method returns the checksum of the object. This method ignores the check
digit of the object's SEDOL number instead recalculating the check_digit each
time. If the check digit cannot be calculated, undef is returned and
$Business::SEDOL::ERROR contains the reason.

=cut
sub check_digit {
  my $self = shift;
  my $sedol = $self->sedol;
  $sedol .= "0" if length($sedol) == 6;
  return unless _check_format($sedol);

  my @val = split //, $self->sedol;
  my $sum = 0;
  for (0..5) {
    $sum += $valid_chars{$val[$_]} * $weights[$_];
  }
  return (10 - $sum % 10) % 10;
}

1;
__END__
=back

=head1 AUTHOR

This module was written by
Tim Ayers (http://search.cpan.org/search?author=TAYERS).

=head1 COPYRIGHT

Copyright (c) 2001 Tim Ayers. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
