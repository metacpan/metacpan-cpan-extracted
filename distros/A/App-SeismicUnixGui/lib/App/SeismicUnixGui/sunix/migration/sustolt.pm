package App::SeismicUnixGui::sunix::migration::sustolt;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUSTOLT - Stolt migration for stacked data or common-offset gathers	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUSTOLT - Stolt migration for stacked data or common-offset gathers	

 sustolt <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [...]		

 Required Parameters:							
 cdpmin=		  minimum cdp (integer number) in dataset	
 cdpmax=		  maximum cdp (integer number) in dataset	
 dxcdp=		  distance between adjacent cdp bins (m)	

 Optional Parameters:							
 noffmix=1		number of offsets to mix (for unstacked data only)
 tmig=0.0		times corresponding to rms velocities in vmig (s)
 vmig=1500.0		rms velocities corresponding to times in tmig (m/s)
 smig=1.0		stretch factor (0.6 typical if vrms increasing)
 vscale=1.0		scale factor to apply to velocities		
 fmax=Nyquist		maximum frequency in input data (Hz)		
 lstaper=0		length of side tapers (# of traces)		
 lbtaper=0		length of bottom taper (# of samples)		
 verbose=0		=1 for diagnostic print				
 tmpdir=		if non-empty, use the value as a directory path	
			prefix for storing temporary files; else if the	
			the CWP_TMPDIR environment variable is set use	
			its value for the path; else use tmpfile()	

 Notes:								
 If unstacked traces are input, they should be NMO-corrected and sorted
 into common-offset  gathers.  One common-offset gather ends and another
 begins when the offset field of the trace headers changes. If both	
 NMO and DMO are applied, then this is equivalent to prestack time 	
 migration (though the velocity profile is assumed v(t), only).	

 The cdp field of the input trace headers must be the cdp bin NUMBER, NOT
 the cdp location expressed in units of meters or feet.		

 The number of offsets to mix (noffmix) should be specified for	
 unstacked data only.	noffmix should typically equal the ratio of the	
 shotpoint spacing to the cdp spacing.	 This choice ensures that every	
 cdp will be represented in each offset mix.  Traces in each mix will	
 contribute through migration to other traces in adjacent cdps within	
 that mix.								

 The tmig and vmig arrays specify a velocity function of time that is	
 used to implement Stolt's stretch for depth-variable velocity.  The	
 stretch factor smig is often referred to as the "W" factor.		
 The times in tmig must be monotonically increasing.			

 Credits:
	CWP: Dave Hale c. 1990

 Trace header fields accessed:  ns, dt, delrt, offset, cdp

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sustolt = {
    _cdpmax  => '',
    _cdpmin  => '',
    _dxcdp   => '',
    _fmax    => '',
    _lbtaper => '',
    _lstaper => '',
    _noffmix => '',
    _smig    => '',
    _tmig    => '',
    _tmpdir  => '',
    _verbose => '',
    _vmig    => '',
    _vscale  => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sustolt->{_Step} = 'sustolt' . $sustolt->{_Step};
    return ( $sustolt->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sustolt->{_note} = 'sustolt' . $sustolt->{_note};
    return ( $sustolt->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sustolt->{_cdpmax}  = '';
    $sustolt->{_cdpmin}  = '';
    $sustolt->{_dxcdp}   = '';
    $sustolt->{_fmax}    = '';
    $sustolt->{_lbtaper} = '';
    $sustolt->{_lstaper} = '';
    $sustolt->{_noffmix} = '';
    $sustolt->{_smig}    = '';
    $sustolt->{_tmig}    = '';
    $sustolt->{_tmpdir}  = '';
    $sustolt->{_verbose} = '';
    $sustolt->{_vmig}    = '';
    $sustolt->{_vscale}  = '';
    $sustolt->{_Step}    = '';
    $sustolt->{_note}    = '';
}

=head2 sub cdpmax 


=cut

sub cdpmax {

    my ( $self, $cdpmax ) = @_;
    if ( $cdpmax ne $empty_string ) {

        $sustolt->{_cdpmax} = $cdpmax;
        $sustolt->{_note} =
          $sustolt->{_note} . ' cdpmax=' . $sustolt->{_cdpmax};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' cdpmax=' . $sustolt->{_cdpmax};

    }
    else {
        print("sustolt, cdpmax, missing cdpmax,\n");
    }
}

=head2 sub cdpmin 


=cut

sub cdpmin {

    my ( $self, $cdpmin ) = @_;
    if ( $cdpmin ne $empty_string ) {

        $sustolt->{_cdpmin} = $cdpmin;
        $sustolt->{_note} =
          $sustolt->{_note} . ' cdpmin=' . $sustolt->{_cdpmin};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' cdpmin=' . $sustolt->{_cdpmin};

    }
    else {
        print("sustolt, cdpmin, missing cdpmin,\n");
    }
}

=head2 sub dxcdp 


=cut

sub dxcdp {

    my ( $self, $dxcdp ) = @_;
    if ( $dxcdp ne $empty_string ) {

        $sustolt->{_dxcdp} = $dxcdp;
        $sustolt->{_note} =
          $sustolt->{_note} . ' dxcdp=' . $sustolt->{_dxcdp};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' dxcdp=' . $sustolt->{_dxcdp};

    }
    else {
        print("sustolt, dxcdp, missing dxcdp,\n");
    }
}

=head2 sub fmax 


=cut

sub fmax {

    my ( $self, $fmax ) = @_;
    if ( $fmax ne $empty_string ) {

        $sustolt->{_fmax} = $fmax;
        $sustolt->{_note} = $sustolt->{_note} . ' fmax=' . $sustolt->{_fmax};
        $sustolt->{_Step} = $sustolt->{_Step} . ' fmax=' . $sustolt->{_fmax};

    }
    else {
        print("sustolt, fmax, missing fmax,\n");
    }
}

=head2 sub lbtaper 


=cut

sub lbtaper {

    my ( $self, $lbtaper ) = @_;
    if ( $lbtaper ne $empty_string ) {

        $sustolt->{_lbtaper} = $lbtaper;
        $sustolt->{_note} =
          $sustolt->{_note} . ' lbtaper=' . $sustolt->{_lbtaper};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' lbtaper=' . $sustolt->{_lbtaper};

    }
    else {
        print("sustolt, lbtaper, missing lbtaper,\n");
    }
}

=head2 sub lstaper 


=cut

sub lstaper {

    my ( $self, $lstaper ) = @_;
    if ( $lstaper ne $empty_string ) {

        $sustolt->{_lstaper} = $lstaper;
        $sustolt->{_note} =
          $sustolt->{_note} . ' lstaper=' . $sustolt->{_lstaper};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' lstaper=' . $sustolt->{_lstaper};

    }
    else {
        print("sustolt, lstaper, missing lstaper,\n");
    }
}

=head2 sub noffmix 


=cut

sub noffmix {

    my ( $self, $noffmix ) = @_;
    if ( $noffmix ne $empty_string ) {

        $sustolt->{_noffmix} = $noffmix;
        $sustolt->{_note} =
          $sustolt->{_note} . ' noffmix=' . $sustolt->{_noffmix};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' noffmix=' . $sustolt->{_noffmix};

    }
    else {
        print("sustolt, noffmix, missing noffmix,\n");
    }
}

=head2 sub smig 


=cut

sub smig {

    my ( $self, $smig ) = @_;
    if ( $smig ne $empty_string ) {

        $sustolt->{_smig} = $smig;
        $sustolt->{_note} = $sustolt->{_note} . ' smig=' . $sustolt->{_smig};
        $sustolt->{_Step} = $sustolt->{_Step} . ' smig=' . $sustolt->{_smig};

    }
    else {
        print("sustolt, smig, missing smig,\n");
    }
}

=head2 sub tmig 


=cut

sub tmig {

    my ( $self, $tmig ) = @_;
    if ( $tmig ne $empty_string ) {

        $sustolt->{_tmig} = $tmig;
        $sustolt->{_note} = $sustolt->{_note} . ' tmig=' . $sustolt->{_tmig};
        $sustolt->{_Step} = $sustolt->{_Step} . ' tmig=' . $sustolt->{_tmig};

    }
    else {
        print("sustolt, tmig, missing tmig,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $sustolt->{_tmpdir} = $tmpdir;
        $sustolt->{_note} =
          $sustolt->{_note} . ' tmpdir=' . $sustolt->{_tmpdir};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' tmpdir=' . $sustolt->{_tmpdir};

    }
    else {
        print("sustolt, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sustolt->{_verbose} = $verbose;
        $sustolt->{_note} =
          $sustolt->{_note} . ' verbose=' . $sustolt->{_verbose};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' verbose=' . $sustolt->{_verbose};

    }
    else {
        print("sustolt, verbose, missing verbose,\n");
    }
}

=head2 sub vmig 


=cut

sub vmig {

    my ( $self, $vmig ) = @_;
    if ( $vmig ne $empty_string ) {

        $sustolt->{_vmig} = $vmig;
        $sustolt->{_note} = $sustolt->{_note} . ' vmig=' . $sustolt->{_vmig};
        $sustolt->{_Step} = $sustolt->{_Step} . ' vmig=' . $sustolt->{_vmig};

    }
    else {
        print("sustolt, vmig, missing vmig,\n");
    }
}

=head2 sub vscale 


=cut

sub vscale {

    my ( $self, $vscale ) = @_;
    if ( $vscale ne $empty_string ) {

        $sustolt->{_vscale} = $vscale;
        $sustolt->{_note} =
          $sustolt->{_note} . ' vscale=' . $sustolt->{_vscale};
        $sustolt->{_Step} =
          $sustolt->{_Step} . ' vscale=' . $sustolt->{_vscale};

    }
    else {
        print("sustolt, vscale, missing vscale,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 12;

    return ($max_index);
}

1;
