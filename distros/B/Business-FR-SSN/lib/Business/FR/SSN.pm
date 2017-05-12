package Business::FR::SSN;

use strict;
use warnings;

our $VERSION = '1.00';

sub _check_ssn {
	my ($class, $ssn) = @_;

	$ssn =~ s#\s+##g;

	# SSN are 15 \d
	return '' if ($ssn !~ /^\d{15}$/);

	# SSN begins with 1 or 2
	return '' if ($ssn !~ /^(1|2)/);

	# SSN contains birth month (1 > 12)
	my $birth = substr($ssn, 3, 2);
	return '' if (($birth > 12) or ($birth == 0));

	return $ssn;
}

sub new {
	my ($class, $ssn) = @_;

	my $self = bless \$ssn, $class;

	$ssn ||= '';
	$ssn = $self->_check_ssn($ssn);

	$self;
}

sub is_valid {
	my $self = shift;
	my $ssn = shift;

	$$self = $self->_check_ssn($ssn) if ($ssn);

	(substr($$self, 13, 2) == (97 - (substr($$self, 0, 13) % 97))) ? return 1 : return 0;
}

sub ssn {
	my $self = shift;
	my $ssn = shift;

	$$self = $self->_check_ssn($ssn) if ($ssn);

	return $$self;
}

sub get_sex {
	my $self = shift;

	return substr($$self, 0, 1);
}

sub get_birth_year {
	my $self = shift;

	return substr($$self, 1, 2);
}

sub get_birth_month {
	my $self = shift;

	return substr($$self, 3, 2);
}

sub get_birth_department {
	my $self = shift;

	return substr($$self, 5, 2);
}

1;

__END__

=head1 NAME

Business::FR::SSN - Verify French SSN (Social Security Number / Numéro de Sécurité Sociale)

=head1 SYNOPSIS

  use Business::FR::SSN;

=head1 DESCRIPTION

This module verifies SSN (numéro de sécurité sociale), which are french people identification.
This module cannot tell if a SS references a real person, but it 
can tell you if the given SS is properly formatted.

=head1 METHODS

=over 4

=item my $obj = Business::FR::SSN->new([$ssn])

The new constructor optionally takes a ss number.

=item $obj->ssn([$ssn])

if no argument is given, it returns the current ssn number.
if an argument is provided, it will set the ssn number and return it.

=item $obj->is_valid([$ssn])

Returns true if the ssn number is valid.

=item $obj->get_sex()

Returns 1 for a male, 2 for a female.

=item $obj->get_birth_year()

Returns the person year of birth.

=item $obj->get_birth_month()

Returns the person month of birth.

=item $obj->get_birth_department()

Returns the person department of birth.

=back

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Business-FR-SSN\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-FR-SSN is the RT queue for Business::FR::SSN.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2004

Fabien Potencier, fabpot@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1).

=cut
