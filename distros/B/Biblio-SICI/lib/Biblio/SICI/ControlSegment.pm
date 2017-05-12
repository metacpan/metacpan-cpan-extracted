
package Biblio::SICI::ControlSegment;
{
  $Biblio::SICI::ControlSegment::VERSION = '0.04';
}

# ABSTRACT: The control segment of a SICI

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Biblio::SICI;
with 'Biblio::SICI::Role::ValidSegment', 'Biblio::SICI::Role::RecursiveLink';


has 'dpi' => (
	is        => 'rw', lazy => 1,
	trigger   => 1,
	default   => quote_sub(q{ 0 }),
	predicate => 1,
	clearer   => 1,
);

sub _trigger_dpi {
	my ( $self, $newVal ) = @_;

	if ( not( "$newVal" eq "0" or "$newVal" eq "1" or "$newVal" eq "2" or "$newVal" eq "3" ) ) {
		$self->log_problem_on( 'dpi' => ['value not in allowed range (0|1|2|3)'] );
	}
	else {
		$self->clear_problem_on('dpi');
	}

	return;
}


has 'mfi' => (
	is        => 'rw', lazy => 1,
	trigger   => 1,
	default   => quote_sub(q{ "ZU" }),
	predicate => 1,
	clearer   => 1,
);

sub _trigger_mfi {
	my ( $self, $newVal ) = @_;

	if ( $newVal !~ /\A(?:C[DFOT]|H[DE]|SC|T[BHLSX]|VX|Z[NUZ])\Z/ ) {
		$self->log_problem_on( 'mfi' => ['unknown identifier'] );
	}
	else {
		$self->clear_problem_on('mfi');
	}

	return;
}


has 'version' => (
	is        => 'rw', lazy => 1,
	trigger   => 1,
	default   => quote_sub(q{ 2 }),
	predicate => 1,
	clearer   => 1,
);

sub _trigger_version {
	my ( $self, $newVal ) = @_;

	if ( $newVal != 2 ) {
		$self->log_problem( 'version' => ['unsupported version number (i.e. not "2")'] );
	}
	else {
		$self->clear_problem_on('version');
	}

	return;
}


sub csi {
	my $self = shift;

	if ( $self->_sici()->contribution()->has_localNumber() ) {
		return 3;
	}

	if (   $self->_sici()->contribution()->has_location()
		or $self->_sici()->contribution()->has_titleCode() )
	{
		return 2;
	}

	return 1;
}


sub to_string {
	my $self = shift;

	# Every attribute in this class has a default value
	return sprintf( '%s.%s.%s;%s', $self->csi(), $self->dpi(), $self->mfi(), $self->version() );
}


sub reset {
	my $self = shift;
	$self->clear_dpi();
	$self->clear_problem_on('dpi');
	$self->clear_mfi();
	$self->clear_problem_on('mfi');
	$self->clear_version();
	$self->clear_problem_on('version');
	return;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI::ControlSegment - The control segment of a SICI

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  my $sici = Biblio::SICI->new();

  $sici->control->csi(2);

=head1 DESCRIPTION

I<Please note:> You are expected to not directly instantiate objects of this class!

The control segment of a SICI describes various aspects of the I<thing> referenced
by the SICI using pre-defined codes.
The segment also contains some meta-information about the SICI itself. 

=head1 ATTRIBUTES

For each attribute, clearer ("clear_") and predicate ("has_") methods
are provided.

=over 4

=item C<dpi>

The I<Derivative Part Identifier> tells us, what kind of I<thing> is described
by the SICI. It can take one of four different values:

B<0> => SICI describes Serial Item or Contribution itself
B<1> => SICI describes ToC of Serial Item or Contribution
B<2> => SICI describes Index of Serial Item or Contribution
B<3> => SICI describes Abstract of Serial Item or Contribution

The default value is B<0>.

=item C<mfi>

The I<Medium / Format Identifier> can take one of these codes:

B<CD> => Computer-readable optical media (CD-ROM)
B<CF> => Computer-readable magnetic disk media
B<CO> => Online (remote)
B<CT> => Computer-readable magnetic tape media
B<HD> => Microfilm
B<HE> => Microfiche
B<SC> => Sound recording
B<TB> => Braille
B<TH> => Printed text, hardbound
B<TL> => Printed text, looseleaf
B<TS> => Printed text, softcover
B<TX> => Printed text
B<VX> => Video recording
B<ZN> => Multiple physical forms
B<ZU> => Physical form unknown
B<ZZ> => Other physical form 

The default value is B<ZU>.

=item C<version>

The number of the standards version to which the SICI should adhere.
The default is B<2> (which means Z39.56-1996), since that is also 
the only currently supported version.

=back

=head1 METHODS

=over 4

=item C<csi>

The I<Code Structure Identifier> tells something about which parts of the
SICI carry values.
It can take one of three values:

B<1> => SICI for Serial Item
B<2> => SICI for Serial Contribution
B<3> => SICI for Serial Contribution "with obscure numbering"

This method automatically derives the correct value from the presence
of the respective data elements in the item and contribution segments.
If no data is present in the contribution segment the final default is B<1>.

=item STRING C<to_string>()

Returns a stringified representation of the data in the
control segment.

Please note that the check digit is I<not> considered to be a
part of the control segment (but the "-" preceding it in the SICI
string is).

=item C<reset>()

Resets all attributes to their default values.

=item BOOL C<is_valid>()

Checks if the data for the control segment conforms
to the standard.

=back

=head1 SEE ALSO

L<Biblio::SICI::Role::ValidSegment>

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
