package App::SeismicUnixGui::sunix::model::sufdmod1;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUFDMOD1 - Finite difference modelling (1-D first order) for the	
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUFDMOD1 - Finite difference modelling (1-D 1rst order) for the	
 acoustic wave equation						"

 sufdmod1 <vfile >sfile nz= tmax= sz= [optional parameters]		

 Required parameters :
 L_SU checks to make sure only  <vfile and >sfile=is used						
 <vfile binary file containing velocities[nz]		
 >sfile SU file containing seimogram[nt]		
 nz=		 number of z samples				   	
 tmax=		maximum propagation time				
 sz=		 z coordinate of source					

 Optional parameters :							
 dz=1	   z sampling interval						
 fz=0.0	 first depth sample					
 rz=1	   coordinate of receiver					
 sz=1	   coordinate of source						
 dfile=	 binary input file containing density[nz]		
 wfile=	 output file for wave field (snapshots in a SU trace panel)
 abs=0,1	absorbing conditions on top and bottom			
 styp=0	 source type (0: gauss, 1: ricker 1, 2: ricker 2)	
 freq=15.0	approximate source center frequency (Hz)		
 nt=1+tmax/dt   number od time samples (dt determined for numerical	
 stability)								
 zt=1	   trace undersampling factor for trace and snapshots	 	
 zd=1	   depth undersampling factor for snapshots		   	
 press=1	to record the pressure field; 0 records the particle	
		velocity						
 verbose=0	=1 for diagnostic messages

 Notes :								
  This program uses a first order explicit velocity/pressure  finite	
  difference equation.							
  The source function is applied on the pressure component.		
  If no density file is given, constant density is assumed	 	
  Wavefield  can be easily viewed with suximage, user must provide f2=0
  to the ximage program in order to  get correct time labelling	
  Seismic trace is shifted in order to get a zero phase source		
  Source begins and stop when it's amplitude is 10^-4 its maximum	
  Time and depth undersampling only modify the output trace and snapshots.
  These parameters are useful for keeping snapshot file small and	
  the number of samples under SU_NFLTS.				


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::specs::model::sufdmod1_spec';

my $get           = L_SU_global_constants->new();
my $sufdmod1_spec = sufdmod1_spec->new();

my $specs 		= $sufdmod1_spec->variables();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sufdmod1 = {
	_abs     => '',
	_dfile   => '',
	_dz      => '',
	_freq    => '',
	_fz      => '',
	_nt      => '',
	_nz      => '',
	_press   => '',
	_rz      => '',
	_sfile   => '',
	_styp    => '',
	_sz      => '',
	_tmax    => '',
	_verbose => '',
	_vfile   => '',
	_wfile   => '',
	_zd      => '',
	_zt      => '',
	_Step    => '',
	_note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sufdmod1->{_Step} = 'sufdmod1' . $sufdmod1->{_Step};
	return ( $sufdmod1->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sufdmod1->{_note} = 'sufdmod1' . $sufdmod1->{_note};
	return ( $sufdmod1->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sufdmod1->{_abs}     = '';
	$sufdmod1->{_dfile}   = '';
	$sufdmod1->{_dz}      = '';
	$sufdmod1->{_freq}    = '';
	$sufdmod1->{_fz}      = '';
	$sufdmod1->{_nt}      = '';
	$sufdmod1->{_nz}      = '';
	$sufdmod1->{_press}   = '';
	$sufdmod1->{_rz}      = '';
	$sufdmod1->{_sfile}   = '';
	$sufdmod1->{_styp}    = '';
	$sufdmod1->{_sz}      = '';
	$sufdmod1->{_tmax}    = '';
	$sufdmod1->{_verbose} = '';
	$sufdmod1->{_vfile}   = '';
	$sufdmod1->{_wfile}   = '';
	$sufdmod1->{_zd}      = '';
	$sufdmod1->{_zt}      = '';
	$sufdmod1->{_Step}    = '';
	$sufdmod1->{_note}    = '';
}

=head2 sub abs 

boundary conditions

=cut

sub abs {

	my ( $self, $abs ) = @_;
	if ( $abs ne $empty_string ) {

		$sufdmod1->{_abs}  = $abs;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' abs=' . $sufdmod1->{_abs};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' abs=' . $sufdmod1->{_abs};

	}
	else {
		print("sufdmod1, abs, missing abs,\n");
	}
}

=head2 sub boundary_conditions 

boundary conditions

=cut

sub boundary_conditions {

	my ( $self, $abs ) = @_;
	if ( $abs ne $empty_string ) {

		$sufdmod1->{_abs}  = $abs;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' abs=' . $sufdmod1->{_abs};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' abs=' . $sufdmod1->{_abs};

	}
	else {
		print("sufdmod1, abs, missing abs,\n");
	}
}

=head2 sub density_file_bin 


=cut

sub density_file_bin {

	my ( $self, $dfile ) = @_;
	if ( $dfile ne $empty_string ) {

		my $data_suffix_in = $specs->{_data_suffix_in};

		if ( $dfile =~ /$data_suffix_in/ ) {    # check extension '.bin'

			$sufdmod1->{_dfile} = $dfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' dfile=' . $sufdmod1->{_dfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' dfile=' . $sufdmod1->{_dfile};

		}
		else {
			$dfile = $dfile . $data_suffix_in;
			$sufdmod1->{_dfile} = $dfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' dfile=' . $sufdmod1->{_dfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' dfile=' . $sufdmod1->{_dfile};
		}
	}
	else {
		print("sufdmod1, dfile, missing dfile,\n");
	}
}

=head2 sub dfile 


=cut

sub dfile {

	my ( $self, $dfile ) = @_;
	if ( $dfile ne $empty_string ) {

		my $data_suffix_in  = $specs->{_data_suffix_in};

		if ( $dfile =~ /$data_suffix_in/ ) {    # check extension '.bin'

			$sufdmod1->{_dfile} = $dfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' dfile=' . $sufdmod1->{_dfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' dfile=' . $sufdmod1->{_dfile};

		}
		else {
			$dfile = $dfile . $data_suffix_in;
			$sufdmod1->{_dfile} = $dfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' dfile=' . $sufdmod1->{_dfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' dfile=' . $sufdmod1->{_dfile};
		}
	}
	else {
		print("sufdmod1, dfile, missing dfile,\n");
	}
}

=head2 sub dz 


=cut

sub dz {

	my ( $self, $dz ) = @_;
	if ( $dz ne $empty_string ) {

		$sufdmod1->{_dz}   = $dz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' dz=' . $sufdmod1->{_dz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' dz=' . $sufdmod1->{_dz};

	}
	else {
		print("sufdmod1, dz, missing dz,\n");
	}
}

=head2 sub freq 


=cut

sub freq {

	my ( $self, $freq ) = @_;
	if ( $freq ne $empty_string ) {

		$sufdmod1->{_freq} = $freq;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' freq=' . $sufdmod1->{_freq};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' freq=' . $sufdmod1->{_freq};

	}
	else {
		print("sufdmod1, freq, missing freq,\n");
	}
}

=head2 sub fz 


=cut

sub fz {

	my ( $self, $fz ) = @_;
	if ( $fz ne $empty_string ) {

		$sufdmod1->{_fz}   = $fz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' fz=' . $sufdmod1->{_fz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' fz=' . $sufdmod1->{_fz};

	}
	else {
		print("sufdmod1, fz, missing fz,\n");
	}
}

=head2 sub nt 


=cut

sub nt {

	my ( $self, $nt ) = @_;
	if ( $nt ne $empty_string ) {

		$sufdmod1->{_nt}   = $nt;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' nt=' . $sufdmod1->{_nt};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' nt=' . $sufdmod1->{_nt};

	}
	else {
		print("sufdmod1, nt, missing nt,\n");
	}
}

=head2 sub nz 


=cut

sub nz {

	my ( $self, $nz ) = @_;
	if ( $nz ne $empty_string ) {

		$sufdmod1->{_nz}   = $nz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' nz=' . $sufdmod1->{_nz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' nz=' . $sufdmod1->{_nz};

	}
	else {
		print("sufdmod1, nz, missing nz,\n");
	}
}

=head2 sub press 


=cut

sub press {

	my ( $self, $press ) = @_;
	if ( $press ne $empty_string ) {

		$sufdmod1->{_press} = $press;
		$sufdmod1->{_note} =
			$sufdmod1->{_note} . ' press=' . $sufdmod1->{_press};
		$sufdmod1->{_Step} =
			$sufdmod1->{_Step} . ' press=' . $sufdmod1->{_press};

	}
	else {
		print("sufdmod1, press, missing press,\n");
	}
}

=head2 sub receiver_depth 


=cut

sub receiver_depth {

	my ( $self, $rz ) = @_;
	if ( $rz ne $empty_string ) {

		$sufdmod1->{_rz}   = $rz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' rz=' . $sufdmod1->{_rz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' rz=' . $sufdmod1->{_rz};

	}
	else {
		print("sufdmod1, rz, missing rz,\n");
	}
}

=head2 sub rz 


=cut

sub rz {

	my ( $self, $rz ) = @_;
	if ( $rz ne $empty_string ) {

		$sufdmod1->{_rz}   = $rz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' rz=' . $sufdmod1->{_rz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' rz=' . $sufdmod1->{_rz};

	}
	else {
		print("sufdmod1, rz, missing rz,\n");
	}
}

=head2 sub source_depth 


=cut

sub source_depth {

	my ( $self, $sz ) = @_;
	if ( $sz ne $empty_string ) {

		$sufdmod1->{_sz}   = $sz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' sz=' . $sufdmod1->{_sz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' sz=' . $sufdmod1->{_sz};

	}
	else {
		print("sufdmod1, sz, missing sz,\n");
	}
}

=head2 sub seismogram_out 


=cut

sub seismogram_out {

	my ( $self, $sfile ) = @_;
	if ( $sfile ne $empty_string ) {

		$sufdmod1->{_sfile} = $sfile;
		$sufdmod1->{_note} =
			$sufdmod1->{_note} . ' sfile=' . $sufdmod1->{_sfile};
		$sufdmod1->{_Step} =
			$sufdmod1->{_Step} . ' sfile=' . $sufdmod1->{_sfile};

	}
	else {
		print("sufdmod1, sfile, missing sfile,\n");
	}
}

=head2 sub sfile 


=cut

sub sfile {

	my ( $self, $sfile ) = @_;
	if ( $sfile ne $empty_string ) {

		$sufdmod1->{_sfile} = $sfile;
		$sufdmod1->{_note} =
			$sufdmod1->{_note} . ' sfile=' . $sufdmod1->{_sfile};
		$sufdmod1->{_Step} =
			$sufdmod1->{_Step} . ' sfile=' . $sufdmod1->{_sfile};

	}
	else {
		print("sufdmod1, sfile, missing sfile,\n");
	}
}

=head2 sub source_type 


=cut

sub source_type {

	my ( $self, $styp ) = @_;
	if ( $styp ne $empty_string ) {

		$sufdmod1->{_styp} = $styp;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' styp=' . $sufdmod1->{_styp};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' styp=' . $sufdmod1->{_styp};

	}
	else {
		print("sufdmod1, styp, missing styp,\n");
	}
}

=head2 sub styp 


=cut

sub styp {

	my ( $self, $styp ) = @_;
	if ( $styp ne $empty_string ) {

		$sufdmod1->{_styp} = $styp;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' styp=' . $sufdmod1->{_styp};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' styp=' . $sufdmod1->{_styp};

	}
	else {
		print("sufdmod1, styp, missing styp,\n");
	}
}

=head2 sub sz 


=cut

sub sz {

	my ( $self, $sz ) = @_;
	if ( $sz ne $empty_string ) {

		$sufdmod1->{_sz}   = $sz;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' sz=' . $sufdmod1->{_sz};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' sz=' . $sufdmod1->{_sz};

	}
	else {
		print("sufdmod1, sz, missing sz,\n");
	}
}

=head2 sub tmax 


=cut

sub tmax {

	my ( $self, $tmax ) = @_;
	if ( $tmax ne $empty_string ) {

		$sufdmod1->{_tmax} = $tmax;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' tmax=' . $sufdmod1->{_tmax};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' tmax=' . $sufdmod1->{_tmax};

	}
	else {
		print("sufdmod1, tmax, missing tmax,\n");
	}
}

=head2 sub velocity_file_bin 


=cut

sub velocity_file_bin {

	my ( $self, $vfile ) = @_;
	if ( $vfile ne $empty_string ) {

		my $data_suffix_in = $specs->{_data_suffix_in};
		print("velocity_file_bin, mad it sufdmod1\n");

		if ( $vfile =~ /$data_suffix_in/ ) {    # check extension '.bin'

			$sufdmod1->{_vfile} = $vfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' vfile<' . $sufdmod1->{_vfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' vfile<' . $sufdmod1->{_vfile};

		}
		else {
			$vfile = $vfile . $data_suffix_in;
			$sufdmod1->{_vfile} = $vfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' vfile<' . $sufdmod1->{_vfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' vfile<' . $sufdmod1->{_vfile};
		}
	}
	else {
		print("sufdmod1, vfile, missing vfile,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$sufdmod1->{_verbose} = $verbose;
		$sufdmod1->{_note} =
			$sufdmod1->{_note} . ' verbose=' . $sufdmod1->{_verbose};
		$sufdmod1->{_Step} =
			$sufdmod1->{_Step} . ' verbose=' . $sufdmod1->{_verbose};

	}
	else {
		print("sufdmod1, verbose, missing verbose,\n");
	}
}

=head2 sub vfile 


=cut

=head2 sub vfile


=cut

sub vfile {

	my ( $self, $vfile ) = @_;
	if ( $vfile ne $empty_string ) {

		my $data_suffix_in = $specs->{_data_suffix_in};

		if ( $vfile =~ /$data_suffix_in/ ) {    # check extension '.bin'

			$sufdmod1->{_vfile} = $vfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' vfile<' . $sufdmod1->{_vfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' vfile<' . $sufdmod1->{_vfile};

		}
		else {
			$vfile = $vfile . $data_suffix_in;
			$sufdmod1->{_vfile} = $vfile;
			$sufdmod1->{_note} =
				$sufdmod1->{_note} . ' vfile<' . $sufdmod1->{_vfile};
			$sufdmod1->{_Step} =
				$sufdmod1->{_Step} . ' vfile<' . $sufdmod1->{_vfile};
		}
	}
	else {
		print("sufdmod1, vfile, missing vfile,\n");
	}
}

=head2 sub wfile 


=cut

sub wfile {

	my ( $self, $wfile ) = @_;
	if ( $wfile ne $empty_string ) {

		$sufdmod1->{_wfile} = $wfile;
		$sufdmod1->{_note} =
			$sufdmod1->{_note} . ' wfile=' . $sufdmod1->{_wfile};
		$sufdmod1->{_Step} =
			$sufdmod1->{_Step} . ' wfile=' . $sufdmod1->{_wfile};

	}
	else {
		print("sufdmod1, wfile, missing wfile,\n");
	}
}

=head2 sub zd 


=cut

sub zd {

	my ( $self, $zd ) = @_;
	if ( $zd ne $empty_string ) {

		$sufdmod1->{_zd}   = $zd;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' zd=' . $sufdmod1->{_zd};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' zd=' . $sufdmod1->{_zd};

	}
	else {
		print("sufdmod1, zd, missing zd,\n");
	}
}

=head2 sub zt 


=cut

sub zt {

	my ( $self, $zt ) = @_;
	if ( $zt ne $empty_string ) {

		$sufdmod1->{_zt}   = $zt;
		$sufdmod1->{_note} = $sufdmod1->{_note} . ' zt=' . $sufdmod1->{_zt};
		$sufdmod1->{_Step} = $sufdmod1->{_Step} . ' zt=' . $sufdmod1->{_zt};

	}
	else {
		print("sufdmod1, zt, missing zt,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 17;

	return ($max_index);
}

1;
