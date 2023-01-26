package App::SeismicUnixGui::sunix::plot::psbbox;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 PSBBOX - change BoundingBOX of existing PostScript file	



 psbbox < PostScriptfile [optional parameters] > PostScriptfile



 Optional Parameters:						

 llx=		new llx						

 lly=		new lly						

 urx=		new urx						

 ury=		new ury						

 verbose=1	=1 for info printed on stderr (0 for no info)	



=head2 User's notes (Juan Lorenzo)
untested

=cut

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $psbbox = {
	_llx     => '',
	_lly     => '',
	_urx     => '',
	_ury     => '',
	_verbose => '',
	_Step    => '',
	_note    => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$psbbox->{_Step} = 'psbbox' . $psbbox->{_Step};
	return ( $psbbox->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$psbbox->{_note} = 'psbbox' . $psbbox->{_note};
	return ( $psbbox->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$psbbox->{_llx}     = '';
	$psbbox->{_lly}     = '';
	$psbbox->{_urx}     = '';
	$psbbox->{_ury}     = '';
	$psbbox->{_verbose} = '';
	$psbbox->{_Step}    = '';
	$psbbox->{_note}    = '';
}

=head2 sub llx 


=cut

sub llx {

	my ( $self, $llx ) = @_;
	if ( $llx ne $empty_string ) {

		$psbbox->{_llx}  = $llx;
		$psbbox->{_note} = $psbbox->{_note} . ' llx=' . $psbbox->{_llx};
		$psbbox->{_Step} = $psbbox->{_Step} . ' llx=' . $psbbox->{_llx};

	}
	else {
		print("psbbox, llx, missing llx,\n");
	}
}

=head2 sub lly 


=cut

sub lly {

	my ( $self, $lly ) = @_;
	if ( $lly ne $empty_string ) {

		$psbbox->{_lly}  = $lly;
		$psbbox->{_note} = $psbbox->{_note} . ' lly=' . $psbbox->{_lly};
		$psbbox->{_Step} = $psbbox->{_Step} . ' lly=' . $psbbox->{_lly};

	}
	else {
		print("psbbox, lly, missing lly,\n");
	}
}

=head2 sub urx 


=cut

sub urx {

	my ( $self, $urx ) = @_;
	if ( $urx ne $empty_string ) {

		$psbbox->{_urx}  = $urx;
		$psbbox->{_note} = $psbbox->{_note} . ' urx=' . $psbbox->{_urx};
		$psbbox->{_Step} = $psbbox->{_Step} . ' urx=' . $psbbox->{_urx};

	}
	else {
		print("psbbox, urx, missing urx,\n");
	}
}

=head2 sub ury 


=cut

sub ury {

	my ( $self, $ury ) = @_;
	if ( $ury ne $empty_string ) {

		$psbbox->{_ury}  = $ury;
		$psbbox->{_note} = $psbbox->{_note} . ' ury=' . $psbbox->{_ury};
		$psbbox->{_Step} = $psbbox->{_Step} . ' ury=' . $psbbox->{_ury};

	}
	else {
		print("psbbox, ury, missing ury,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$psbbox->{_verbose} = $verbose;
		$psbbox->{_note} = $psbbox->{_note} . ' verbose=' . $psbbox->{_verbose};
		$psbbox->{_Step} = $psbbox->{_Step} . ' verbose=' . $psbbox->{_verbose};

	}
	else {
		print("psbbox, verbose, missing verbose,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 4;

	return ($max_index);
}

1;
