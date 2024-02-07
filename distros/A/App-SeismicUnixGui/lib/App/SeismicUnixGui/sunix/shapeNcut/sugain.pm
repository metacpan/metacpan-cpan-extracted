package App::SeismicUnixGui::sunix::shapeNcut::sugain;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUGAIN - apply various types of gain				  	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUGAIN - apply various types of gain				  	

 sugain <stdin >stdout [optional parameters]			   	

 Required parameters:						  	
	none (no-op)						    	

 Optional parameters:						  	
	panel=0	        =1  gain whole data set (vs. trace by trace)	
	tpow=0.0	multiply data by t^tpow			 	
	epow=0.0	multiply data by exp(epow*t)		    	
	etpow=1.0	multiply data by exp(epow*t^etpow)	    	
	gpow=1.0	take signed gpowth power of scaled data	 	
	agc=0	   flag; 1 = do automatic gain control	     		
	gagc=0	  flag; 1 = ... with gaussian taper			
	wagc=0.5	agc window in seconds (use if agc=1 or gagc=1)  
	trap=none	zero any value whose magnitude exceeds trapval  
	clip=none	clip any value whose magnitude exceeds clipval  
	pclip=none	clip any value greater than clipval  		
	nclip=none	clip any value less than  clipval 		
	qclip=1.0	clip by quantile on absolute values on trace    
	qbal=0	  flag; 1 = balance traces by qclip and scale     	
	pbal=0	  flag; 1 = bal traces by dividing by rms value   	
	mbal=0	  flag; 1 = bal traces by subtracting the mean    	
	maxbal=0	flag; 1 = balance traces by subtracting the max 
	scale=1.0	multiply data by overall scale factor	   	
	norm=0.0	divide data by overall scale factor	     	
	bias=0.0	bias data by adding an overall bias value	
	jon=0	   	flag; 1 means tpow=2, gpow=.5, qclip=.95	
	verbose=0	verbose = 1 echoes info				
	mark=0		apply gain only to traces with tr.mark=0	
			=1 apply gain only to traces with tr.mark!=0    
	vred=0	  reducing velocity of data to use with tpow		

 	tmpdir=		if non-empty, use the value as a directory path	
			prefix for storing temporary files; else if the 
			the CWP_TMPDIR environment variable is set use  
			its value for the path; else use tmpfile()	

 Operation order:							
 if (norm) scale/norm						  	

 out(t) = scale * BAL{CLIP[AGC{[t^tpow * exp(epow * t^tpow) * ( in(t)-bias )]^gpow}]}

 Notes:								
	The jon flag selects the parameter choices discussed in		
	Claerbout's Imaging the Earth, pp 233-236.			

	Extremely large/small values may be lost during agc. Windowing  
	these off and applying a scale in a preliminary pass through	
	sugain may help.						

	Sugain only applies gain to traces with tr.mark=0. Use sushw,	
	suchw, suedit, or suxedit to mark traces you do not want gained.
	See the selfdocs of sushw, suchw, suedit, and suxedit for more	
	information about setting header fields. Use "sukeyword mark
	for more information about the mark header field.		

      debias data by using mbal=1					

      option etpow only becomes active if epow is nonzero		

 Credits:
	SEP: Jon Claerbout
	CWP: Jack K. Cohen, Brian Sumner, Dave Hale

 Note: Have assumed tr.deltr >= 0 in tpow routine.

 Technical Reference:
	Jon's second book, pages 233-236.

 Trace header fields accessed: ns, dt, delrt, mark, offset

=head2 CHANGES and their DATES

 24 parameters, max index=23

=cut

use Moose;
our $VERSION = '0.0.1';

my $sugain = {
    _panel   => '',
    _tpow    => '',
    _epow    => '',
    _etpow   => '',
    _gpow    => '',
    _agc     => '',
    _gagc    => '',
    _wagc    => '',
    _trap    => '',
    _clip    => '',
    _pclip   => '',
    _nclip   => '',
    _qclip   => '',
    _qbal    => '',
    _pbal    => '',
    _mbal    => '',
    _maxbal  => '',
    _scale   => '',
    _norm    => '',
    _bias    => '',
    _jon     => '',
    _verbose => '',
    _mark    => '',
    _vred    => '',
    _tmpdir  => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sugain->{_Step} = 'sugain' . $sugain->{_Step};
    return ( $sugain->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sugain->{_note} = 'sugain' . $sugain->{_note};
    return ( $sugain->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sugain->{_panel}   = '';
    $sugain->{_tpow}    = '';
    $sugain->{_epow}    = '';
    $sugain->{_etpow}   = '';
    $sugain->{_gpow}    = '';
    $sugain->{_agc}     = '';
    $sugain->{_gagc}    = '';
    $sugain->{_wagc}    = '';
    $sugain->{_trap}    = '';
    $sugain->{_clip}    = '';
    $sugain->{_pclip}   = '';
    $sugain->{_nclip}   = '';
    $sugain->{_qclip}   = '';
    $sugain->{_qbal}    = '';
    $sugain->{_pbal}    = '';
    $sugain->{_mbal}    = '';
    $sugain->{_maxbal}  = '';
    $sugain->{_scale}   = '';
    $sugain->{_norm}    = '';
    $sugain->{_bias}    = '';
    $sugain->{_jon}     = '';
    $sugain->{_verbose} = '';
    $sugain->{_mark}    = '';
    $sugain->{_vred}    = '';
    $sugain->{_tmpdir}  = '';
    $sugain->{_Step}    = '';
    $sugain->{_note}    = '';
}

=head2 sub panel 


=cut

sub panel {

    my ( $self, $panel ) = @_;
    if ($panel) {

        $sugain->{_panel} = $panel;
        $sugain->{_note}  = $sugain->{_note} . ' panel=' . $sugain->{_panel};
        $sugain->{_Step}  = $sugain->{_Step} . ' panel=' . $sugain->{_panel};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub tpow 


=cut

sub tpow {

    my ( $self, $tpow ) = @_;
    if ($tpow) {

        $sugain->{_tpow} = $tpow;
        $sugain->{_note} = $sugain->{_note} . ' tpow=' . $sugain->{_tpow};
        $sugain->{_Step} = $sugain->{_Step} . ' tpow=' . $sugain->{_tpow};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub tpower 


=cut

sub tpower {

    my ( $self, $tpow ) = @_;
    if ($tpow) {

        $sugain->{_tpow} = $tpow;
        $sugain->{_note} = $sugain->{_note} . ' tpow=' . $sugain->{_tpow};
        $sugain->{_Step} = $sugain->{_Step} . ' tpow=' . $sugain->{_tpow};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub epow 


=cut

sub epow {

    my ( $self, $epow ) = @_;
    if ($epow) {

        $sugain->{_epow} = $epow;
        $sugain->{_note} = $sugain->{_note} . ' epow=' . $sugain->{_epow};
        $sugain->{_Step} = $sugain->{_Step} . ' epow=' . $sugain->{_epow};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub etpow 


=cut

sub etpow {

    my ( $self, $etpow ) = @_;
    if ($etpow) {

        $sugain->{_etpow} = $etpow;
        $sugain->{_note}  = $sugain->{_note} . ' etpow=' . $sugain->{_etpow};
        $sugain->{_Step}  = $sugain->{_Step} . ' etpow=' . $sugain->{_etpow};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub gpow 


=cut

sub gpow {

    my ( $self, $gpow ) = @_;
    if ($gpow) {

        $sugain->{_gpow} = $gpow;
        $sugain->{_note} = $sugain->{_note} . ' gpow=' . $sugain->{_gpow};
        $sugain->{_Step} = $sugain->{_Step} . ' gpow=' . $sugain->{_gpow};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub agc 


=cut

sub agc {

    my ( $self, $agc ) = @_;
    if ($agc) {

        $sugain->{_agc}  = $agc;
        $sugain->{_note} = $sugain->{_note} . ' agc=' . $sugain->{_agc};
        $sugain->{_Step} = $sugain->{_Step} . ' agc=' . $sugain->{_agc};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub gagc 


=cut

sub gagc {

    my ( $self, $gagc ) = @_;
    if ($gagc) {

        $sugain->{_gagc} = $gagc;
        $sugain->{_note} = $sugain->{_note} . ' gagc=' . $sugain->{_gagc};
        $sugain->{_Step} = $sugain->{_Step} . ' gagc=' . $sugain->{_gagc};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub wagc 

	in (s)

=cut

sub wagc {

    my ( $self, $wagc ) = @_;
    if ($wagc) {

        $sugain->{_wagc} = $wagc;
        $sugain->{_note} = $sugain->{_note} . ' wagc=' . $sugain->{_wagc};
        $sugain->{_Step} = $sugain->{_Step} . ' wagc=' . $sugain->{_wagc};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub width 

	(s)

=cut

sub width {

    my ( $self, $wagc ) = @_;
    if ($wagc) {

        $sugain->{_wagc} = $wagc;
        $sugain->{_note} = $sugain->{_note} . ' wagc=' . $sugain->{_wagc};
        $sugain->{_Step} = $sugain->{_Step} . ' wagc=' . $sugain->{_wagc};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub width_s 

	(s)

=cut

sub width_s {

    my ( $self, $wagc ) = @_;
    if ($wagc) {

        $sugain->{_wagc} = $wagc;
        $sugain->{_note} = $sugain->{_note} . ' wagc=' . $sugain->{_wagc};
        $sugain->{_Step} = $sugain->{_Step} . ' wagc=' . $sugain->{_wagc};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub trap 


=cut

sub trap {

    my ( $self, $trap ) = @_;
    if ($trap) {

        $sugain->{_trap} = $trap;
        $sugain->{_note} = $sugain->{_note} . ' trap=' . $sugain->{_trap};
        $sugain->{_Step} = $sugain->{_Step} . ' trap=' . $sugain->{_trap};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub clip 


=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ($clip) {

        $sugain->{_clip} = $clip;
        $sugain->{_note} = $sugain->{_note} . ' clip=' . $sugain->{_clip};
        $sugain->{_Step} = $sugain->{_Step} . ' clip=' . $sugain->{_clip};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub pclip 


=cut

sub pclip {

    my ( $self, $pclip ) = @_;
    if ($pclip) {

        $sugain->{_pclip} = $pclip;
        $sugain->{_note}  = $sugain->{_note} . ' pclip=' . $sugain->{_pclip};
        $sugain->{_Step}  = $sugain->{_Step} . ' pclip=' . $sugain->{_pclip};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub nclip 


=cut

sub nclip {

    my ( $self, $nclip ) = @_;
    if ($nclip) {

        $sugain->{_nclip} = $nclip;
        $sugain->{_note}  = $sugain->{_note} . ' nclip=' . $sugain->{_nclip};
        $sugain->{_Step}  = $sugain->{_Step} . ' nclip=' . $sugain->{_nclip};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub qclip 


=cut

sub qclip {

    my ( $self, $qclip ) = @_;
    if ($qclip) {

        $sugain->{_qclip} = $qclip;
        $sugain->{_note}  = $sugain->{_note} . ' qclip=' . $sugain->{_qclip};
        $sugain->{_Step}  = $sugain->{_Step} . ' qclip=' . $sugain->{_qclip};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub qbal 


=cut

sub qbal {

    my ( $self, $qbal ) = @_;
    if ($qbal) {

        $sugain->{_qbal} = $qbal;
        $sugain->{_note} = $sugain->{_note} . ' qbal=' . $sugain->{_qbal};
        $sugain->{_Step} = $sugain->{_Step} . ' qbal=' . $sugain->{_qbal};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub pbal 


=cut

sub pbal {

    my ( $self, $pbal ) = @_;
    if ($pbal) {

        $sugain->{_pbal} = $pbal;
        $sugain->{_note} = $sugain->{_note} . ' pbal=' . $sugain->{_pbal};
        $sugain->{_Step} = $sugain->{_Step} . ' pbal=' . $sugain->{_pbal};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub mbal 


=cut

sub mbal {

    my ( $self, $mbal ) = @_;
    if ($mbal) {

        $sugain->{_mbal} = $mbal;
        $sugain->{_note} = $sugain->{_note} . ' mbal=' . $sugain->{_mbal};
        $sugain->{_Step} = $sugain->{_Step} . ' mbal=' . $sugain->{_mbal};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub maxbal 


=cut

sub maxbal {

    my ( $self, $maxbal ) = @_;
    if ($maxbal) {

        $sugain->{_maxbal} = $maxbal;
        $sugain->{_note}   = $sugain->{_note} . ' maxbal=' . $sugain->{_maxbal};
        $sugain->{_Step}   = $sugain->{_Step} . ' maxbal=' . $sugain->{_maxbal};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub scale 


=cut

sub scale {

    my ( $self, $scale ) = @_;
    if ($scale) {

        $sugain->{_scale} = $scale;
        $sugain->{_note}  = $sugain->{_note} . ' scale=' . $sugain->{_scale};
        $sugain->{_Step}  = $sugain->{_Step} . ' scale=' . $sugain->{_scale};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub norm 


=cut

sub norm {

    my ( $self, $norm ) = @_;
    if ($norm) {

        $sugain->{_norm} = $norm;
        $sugain->{_note} = $sugain->{_note} . ' norm=' . $sugain->{_norm};
        $sugain->{_Step} = $sugain->{_Step} . ' norm=' . $sugain->{_norm};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub bias 


=cut

sub bias {

    my ( $self, $bias ) = @_;
    if ($bias) {

        $sugain->{_bias} = $bias;
        $sugain->{_note} = $sugain->{_note} . ' bias=' . $sugain->{_bias};
        $sugain->{_Step} = $sugain->{_Step} . ' bias=' . $sugain->{_bias};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub jon 


=cut

sub jon {

    my ( $self, $jon ) = @_;
    if ($jon) {

        $sugain->{_jon}  = $jon;
        $sugain->{_note} = $sugain->{_note} . ' jon=' . $sugain->{_jon};
        $sugain->{_Step} = $sugain->{_Step} . ' jon=' . $sugain->{_jon};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ($verbose) {

        $sugain->{_verbose} = $verbose;
        $sugain->{_note} =
          $sugain->{_note} . ' verbose=' . $sugain->{_verbose};
        $sugain->{_Step} =
          $sugain->{_Step} . ' verbose=' . $sugain->{_verbose};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub mark 


=cut

sub mark {

    my ( $self, $mark ) = @_;
    if ($mark) {

        $sugain->{_mark} = $mark;
        $sugain->{_note} = $sugain->{_note} . ' mark=' . $sugain->{_mark};
        $sugain->{_Step} = $sugain->{_Step} . ' mark=' . $sugain->{_mark};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub vred 


=cut

sub vred {

    my ( $self, $vred ) = @_;
    if ($vred) {

        $sugain->{_vred} = $vred;
        $sugain->{_note} = $sugain->{_note} . ' vred=' . $sugain->{_vred};
        $sugain->{_Step} = $sugain->{_Step} . ' vred=' . $sugain->{_vred};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ($tmpdir) {

        $sugain->{_tmpdir} = $tmpdir;
        $sugain->{_note}   = $sugain->{_note} . ' tmpdir=' . $sugain->{_tmpdir};
        $sugain->{_Step}   = $sugain->{_Step} . ' tmpdir=' . $sugain->{_tmpdir};

    }
    else {
        print("sugain\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=23
    my $max_index = 23;

    return ($max_index);
}

1;
