package Business::FR::SIRET;

use strict;
use warnings;
use Algorithm::LUHN;

our $VERSION = '0.01';

sub _check_siret {
	my ($class, $siret) = @_;

	$siret =~ s#\s+##g;

	my $nb_max = ref($class) =~ /T$/ ? 14 : 9;

	return '' if ($siret !~ /^\d{$nb_max}$/);

	return $siret;
}

sub new {
	my ($class, $siret) = @_;

	my $self = bless \$siret, $class;

	$siret ||= '';
	$siret = $self->_check_siret($siret);

	$self;
}

sub siren {
	my $self = shift;
	my $siret = shift;

	return $self->siret($siret);
}

sub siret {
	my $self = shift;
	my $siret = shift;

	$$self = $self->_check_siret($siret) if ($siret);

	return $$self;
}

sub is_valid {
	my $self = shift;
	my $siret = shift;

	$$self = $self->_check_siret($siret) if ($siret);

	return Algorithm::LUHN::is_valid($self->siret);
}

1;

__END__

=head1 NAME

Business::FR::SIRET - Verify French Companies SIRET

=head1 SYNOPSIS

  use Business::FR::SIRET;
  $c = Business::FR::SIRET->new('00011122233344');
  print $c->siret()." looks good\n" if $c->is_valid();

  $c = Business::FR::SIRET->new();
  $c->siret('00011122233344');
  print "looks good\n" if $c->is_valid();

  print "looks good\n" if $c->is_valid('00011122233344');

=head1 DESCRIPTION

This module verifies SIRETs, which are french companies identification.
This module cannot tell  if a SIRET references a real company, but it 
can tell you if the given SIRET  is properly formatted.

=head1 METHODS

=over 4

=item new([$siret])

The new constructor optionally takes a SIRET number.

=item siret([$siret])

if no argument is given, it returns the current SIRET number.
if an argument is provided, it will set the SIRET number and return it.

=item is_valid([$siret])

Returns true if the SIRET number is valid.

=back

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Business-FR-SIRET\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-FR-SIRET is the RT queue for Business::FR::SIRET.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2004

Fabien Potencier, fabpot@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1), Algorithm::LUHN.

=cut
