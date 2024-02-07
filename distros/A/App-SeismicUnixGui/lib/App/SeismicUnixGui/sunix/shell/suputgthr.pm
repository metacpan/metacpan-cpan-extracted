package App::SeismicUnixGui::sunix::shell::suputgthr;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:
sumute
Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUPUTGTHR - split the stdout flow to gathers on the bases of given	

 		key parameter. 						

	suputgthr <stdin   dir= [Optional parameters]			

 Required parameters:							

 dir=		Name of directory where to put the gathers		

 Optional parameters: 							

 key=ep		header key word to watch   			

 suffix=".hsu"	extension of the output files			

 verbose=0		verbose = 1 echos information			

 numlength=7		Length of numeric part of filename		



 Notes: 			    					

 The name of the file is constructed from the key parameter. Traces	

 are put into a temporary disk file, and renamed when key parameter	

 changes in the input flow to "key.suffix". The result is that the	

 directory "dir" contains separate files by "key" ensemble. 	",	



 Header field modified:  ntr  to be the number of traces in a given 	

 ensemble.								

 Related programs: sugetgthr, susplit 					



 

 Credits: Balazs Nemeth, Potash Corporation, Saskatoon Saskatchewan

 given to CWP in 2008

 Note:

	The "valxxx" subroutines are in su/lib/valpkge.c.  In particular,

	"valcmp" shares the annoying attribute of "strcmp" that

		if (valcmp(type, val, valnew) {

			...

		}

	will be performed when val and valnew are different.







=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
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

my $suputgthr = {
	_dir       => '',
	_key       => '',
	_numlength => '',
	_suffix    => '',
	_verbose   => '',
	_Step      => '',
	_note      => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$suputgthr->{_Step} = 'suputgthr' . $suputgthr->{_Step};
	return ( $suputgthr->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$suputgthr->{_note} = 'suputgthr' . $suputgthr->{_note};
	return ( $suputgthr->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$suputgthr->{_dir}       = '';
	$suputgthr->{_key}       = '';
	$suputgthr->{_numlength} = '';
	$suputgthr->{_suffix}    = '';
	$suputgthr->{_verbose}   = '';
	$suputgthr->{_Step}      = '';
	$suputgthr->{_note}      = '';
}

=head2 sub dir 


=cut

sub dir {

	my ( $self, $dir ) = @_;
	if ( $dir ne $empty_string ) {

		$suputgthr->{_dir}  = $dir;
		$suputgthr->{_note} = $suputgthr->{_note} . ' dir=' . $suputgthr->{_dir};
		$suputgthr->{_Step} = $suputgthr->{_Step} . ' dir=' . $suputgthr->{_dir};

	} else {
		print("suputgthr, dir, missing dir,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$suputgthr->{_key}  = $key;
		$suputgthr->{_note} = $suputgthr->{_note} . ' key=' . $suputgthr->{_key};
		$suputgthr->{_Step} = $suputgthr->{_Step} . ' key=' . $suputgthr->{_key};

	} else {
		print("suputgthr, key, missing key,\n");
	}
}

=head2 sub numlength 


=cut

sub numlength {

	my ( $self, $numlength ) = @_;
	if ( $numlength ne $empty_string ) {

		$suputgthr->{_numlength} = $numlength;
		$suputgthr->{_note}      = $suputgthr->{_note} . ' numlength=' . $suputgthr->{_numlength};
		$suputgthr->{_Step}      = $suputgthr->{_Step} . ' numlength=' . $suputgthr->{_numlength};

	} else {
		print("suputgthr, numlength, missing numlength,\n");
	}
}

=head2 sub suffix 


=cut

sub suffix {

	my ( $self, $suffix ) = @_;
	if ( $suffix ne $empty_string ) {

		$suputgthr->{_suffix} = $suffix;
		$suputgthr->{_note}   = $suputgthr->{_note} . ' suffix=' . $suputgthr->{_suffix};
		$suputgthr->{_Step}   = $suputgthr->{_Step} . ' suffix=' . $suputgthr->{_suffix};

	} else {
		print("suputgthr, suffix, missing suffix,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$suputgthr->{_verbose} = $verbose;
		$suputgthr->{_note}    = $suputgthr->{_note} . ' verbose=' . $suputgthr->{_verbose};
		$suputgthr->{_Step}    = $suputgthr->{_Step} . ' verbose=' . $suputgthr->{_verbose};

	} else {
		print("suputgthr, verbose, missing verbose,\n");
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
