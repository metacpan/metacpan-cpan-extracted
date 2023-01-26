package App::SeismicUnixGui::sunix::shell::sugetgthr;

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
 SUGETGTHR - Gets su files from a directory and put them               
             throught the unix pipe. This creates continous data flow.
  sugetgthr  <stdin >sdout   						

 Required parameters:							

 dir=           Name of directory to fetch data from 			
 	          Every file in the directory is treated as an su file	

 Optional parameters:							
 verbose=0		=1 more chatty					
 vt=0			=1 allows gathers with variable length traces	
 			no header checking is done!			
 ns=			must be specified if vt=1; number of samples to read

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

my $sugetgthr = {
	_d       => '',
	_dir     => '',
	_dp      => '',
	_fd      => '',
	_ffname  => '',
	_fname   => '',
	_fp      => '',
	_nread   => '',
	_ns      => '',
	_verbose => '',
	_vt      => '',
	_Step    => '',
	_note    => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sugetgthr->{_Step} = 'sugetgthr' . $sugetgthr->{_Step};
	return ( $sugetgthr->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sugetgthr->{_note} = 'sugetgthr' . $sugetgthr->{_note};
	return ( $sugetgthr->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sugetgthr->{_d}       = '';
	$sugetgthr->{_dir}     = '';
	$sugetgthr->{_dp}      = '';
	$sugetgthr->{_fd}      = '';
	$sugetgthr->{_ffname}  = '';
	$sugetgthr->{_fname}   = '';
	$sugetgthr->{_fp}      = '';
	$sugetgthr->{_nread}   = '';
	$sugetgthr->{_ns}      = '';
	$sugetgthr->{_verbose} = '';
	$sugetgthr->{_vt}      = '';
	$sugetgthr->{_Step}    = '';
	$sugetgthr->{_note}    = '';
}

=head2 sub d 


=cut

sub d {

	my ( $self, $d ) = @_;
	if ( $d ne $empty_string ) {

		$sugetgthr->{_d}    = $d;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' d=' . $sugetgthr->{_d};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' d=' . $sugetgthr->{_d};

	} else {
		print("sugetgthr, d, missing d,\n");
	}
}

=head2 sub dir 


=cut

sub dir {

	my ( $self, $dir ) = @_;
	if ( $dir ne $empty_string ) {

		$sugetgthr->{_dir}  = $dir;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' dir=' . $sugetgthr->{_dir};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' dir=' . $sugetgthr->{_dir};

	} else {
		print("sugetgthr, dir, missing dir,\n");
	}
}

=head2 sub dp 


=cut

sub dp {

	my ( $self, $dp ) = @_;
	if ( $dp ne $empty_string ) {

		$sugetgthr->{_dp}   = $dp;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' dp=' . $sugetgthr->{_dp};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' dp=' . $sugetgthr->{_dp};

	} else {
		print("sugetgthr, dp, missing dp,\n");
	}
}

=head2 sub fd 


=cut

sub fd {

	my ( $self, $fd ) = @_;
	if ( $fd ne $empty_string ) {

		$sugetgthr->{_fd}   = $fd;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' fd=' . $sugetgthr->{_fd};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' fd=' . $sugetgthr->{_fd};

	} else {
		print("sugetgthr, fd, missing fd,\n");
	}
}

=head2 sub ffname 


=cut

sub ffname {

	my ( $self, $ffname ) = @_;
	if ( $ffname ne $empty_string ) {

		$sugetgthr->{_ffname} = $ffname;
		$sugetgthr->{_note}   = $sugetgthr->{_note} . ' ffname=' . $sugetgthr->{_ffname};
		$sugetgthr->{_Step}   = $sugetgthr->{_Step} . ' ffname=' . $sugetgthr->{_ffname};

	} else {
		print("sugetgthr, ffname, missing ffname,\n");
	}
}

=head2 sub fname 


=cut

sub fname {

	my ( $self, $fname ) = @_;
	if ( $fname ne $empty_string ) {

		$sugetgthr->{_fname} = $fname;
		$sugetgthr->{_note}  = $sugetgthr->{_note} . ' fname=' . $sugetgthr->{_fname};
		$sugetgthr->{_Step}  = $sugetgthr->{_Step} . ' fname=' . $sugetgthr->{_fname};

	} else {
		print("sugetgthr, fname, missing fname,\n");
	}
}

=head2 sub fp 


=cut

sub fp {

	my ( $self, $fp ) = @_;
	if ( $fp ne $empty_string ) {

		$sugetgthr->{_fp}   = $fp;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' fp=' . $sugetgthr->{_fp};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' fp=' . $sugetgthr->{_fp};

	} else {
		print("sugetgthr, fp, missing fp,\n");
	}
}

=head2 sub nread 


=cut

sub nread {

	my ( $self, $nread ) = @_;
	if ( $nread ne $empty_string ) {

		$sugetgthr->{_nread} = $nread;
		$sugetgthr->{_note}  = $sugetgthr->{_note} . ' nread=' . $sugetgthr->{_nread};
		$sugetgthr->{_Step}  = $sugetgthr->{_Step} . ' nread=' . $sugetgthr->{_nread};

	} else {
		print("sugetgthr, nread, missing nread,\n");
	}
}

=head2 sub ns 


=cut

sub ns {

	my ( $self, $ns ) = @_;
	if ( $ns ne $empty_string ) {

		$sugetgthr->{_ns}   = $ns;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' ns=' . $sugetgthr->{_ns};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' ns=' . $sugetgthr->{_ns};

	} else {
		print("sugetgthr, ns, missing ns,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$sugetgthr->{_verbose} = $verbose;
		$sugetgthr->{_note}    = $sugetgthr->{_note} . ' verbose=' . $sugetgthr->{_verbose};
		$sugetgthr->{_Step}    = $sugetgthr->{_Step} . ' verbose=' . $sugetgthr->{_verbose};

	} else {
		print("sugetgthr, verbose, missing verbose,\n");
	}
}

=head2 sub vt 


=cut

sub vt {

	my ( $self, $vt ) = @_;
	if ( $vt ne $empty_string ) {

		$sugetgthr->{_vt}   = $vt;
		$sugetgthr->{_note} = $sugetgthr->{_note} . ' vt=' . $sugetgthr->{_vt};
		$sugetgthr->{_Step} = $sugetgthr->{_Step} . ' vt=' . $sugetgthr->{_vt};

	} else {
		print("sugetgthr, vt, missing vt,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 3;

	return ($max_index);
}

1;
