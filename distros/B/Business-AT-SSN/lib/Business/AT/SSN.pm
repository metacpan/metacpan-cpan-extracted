package Business::AT::SSN;

use Moose;
use DateTime;
use Try::Tiny;
our $VERSION = '0.92';

# ABSTRACT: verify Austrian Social Securtiy numbers

has 'ssn'            => (isa => 'Str', is => 'rw');
has 'date_of_birth'  => (isa => 'DateTime', is => 'rw', clearer => 'clear_dob',);
has 'error_messages' => (isa => 'ArrayRef', is => 'rw', clearer => 'clear' );


# this is the rare case where an example may be used as is
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( ssn => $_[0] );
  }
  else {
      return $class->$orig(@_);
  }
};

__PACKAGE__->meta->make_immutable;

sub checksum {
  my $self = shift;
  my @multiplicators = (3,7,9,0,5,8,4,2,1,6);
  my @num = split('', $self->ssn);
  my $i = 0;
  my $sum = 0;
  foreach my $d (@multiplicators) {
    last unless defined $num[$i];
    $sum += $d * $num[$i++];
  }
  return 1 unless $sum%11 == $num[3];
}

sub get_dob {
  my $self = shift;
  my ($d, $m, $y) = $self->ssn =~ /^\d{4}(\d{2})(\d{2})(\d{2})$/;
  my $now = DateTime->now;
  # guess a year
  $y = (($now->year) - ($y + 1900) < 100) ? $y + 1900 : $y + 2000;
  try {
     my $dt = DateTime->new(year => $y, month => $m, day => $d);
     $self->date_of_birth( $dt );
     return 1;
  } catch {
    $self->clear_dob;
    return 0;
  };
}

sub is_valid {
  my $self = shift;
  die 'ssn not not set' unless $self->ssn;
  my @error_messages;
  push(@error_messages, 'Wrong length') if length($self->ssn) != 10;
  push(@error_messages, 'Invalid characters') if $self->ssn =~ /\D/;  
  $self->error_messages(\@error_messages);
  return 0 unless scalar @error_messages == 0;
  # calculate checksum only if nothing else fails
  $self->error_messages(\@error_messages);
  push(@error_messages, 'Wrong checksum') if $self->checksum != 1;
  return 0 unless scalar @error_messages == 0;
  $self->get_dob;
  return 1;
}



1;
__END__

=encoding utf-8

=head1 NAME

Business::AT::SSN

=head1 SYNOPSIS

  use Business::AT::SSN;

=head1 DESCRIPTION

Business::AT::SSN checks Austrian social security numbers (Sozialversicherungsnummer) 
for wellformed-ness according to 
https://www.sozialversicherung.at/portal27/portal/ecardportal/content/contentWindow?&contentid=10008.551806&action=b&cacheability=PAGE

if possible (not all SSNs contain a valid date) it also creates a DateTime Object with the 
date of birth

=head1 METHODS
 
=over 4
 
=item my $obj = Business::AT::SSN->new([$ssn])
 
The new constructor optionally takes a ssn number
 
=item $obj->ssn([$ssn])
 
if no argument is given, it returns the current ssn number.
if an argument is provided, it will set the ssn number.
 
=item $obj->is_valid()
 
Returns true if the ssn number is valid.
 
=item $obj->date_of_birth

Returns the date of birth as a DateTime object

=item $array_ref = $obj->error_messages

Returns a array ref of error messages after calling is_valid

=back
 
=head1 AUTHOR

Mark Hofstetter E<lt>mark@hofstetter.atE<gt>

=head1 COPYRIGHT

Copyright 2014- Mark Hofstetter

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
