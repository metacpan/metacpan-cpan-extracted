package App::SeismicUnixGui::misc::su_spectral_analysis;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PERL PROGRAM NAME:su_spectral_analysis.pm
  Purpose: Spectral analysis 
           of spectral_analysised  waveforms in su format 
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    July 8 2016 V0.1
  DESCRIPTION:  

=head 2 USES

 (for subroutines) 
     manage_files_by 
     System_Variables (for subroutines)

     (for variable definitions)
     SeismicUnix (Seismic Unix modules)


=head2 NOTES 

 We are using moose 
 moose already declares that you need debuggers turned on
 so you don't need a line like the following:

 use warnings;
 
=head2 USES

 (for subroutines) 
     manage_files_by 
     System_Variables (for subroutines)

     (for variable definitions)
     SeismicUnix (Seismic Unix modules)


 use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su) ;
  
=head3 STEPS IN THE PROGRAM 

=cut

=head2 Create 

 hash of shared variables and
 subroutine to clear them

 Do not clear: absclip_phase or absclip_freq

=cut 

my $spectral_analysis = {
    _agc_gain_width => '',
    _filter_freq    => '',
    _inbound        => '',
    _outbound       => '',
    _absclip_phase  => 1,
    _absclip_freq   => 1,
    _absclip		=> 1,
    _window_title   => '',
    _title          => ''
};

sub clear {
    $spectral_analysis->{_agc_gain_width} = '';
    $spectral_analysis->{_absclip_phase}  = '',
    $spectral_analysis->{_absclip_freq}   = '';
    $spectral_analysis->{_absclip}		  = '';   
    $spectral_analysis->{_filter_freq}    = '';
    $spectral_analysis->{_inbound}        = '';
    $spectral_analysis->{_outbound}       = '';
    $spectral_analysis->{_window_title}   = '';
    $spectral_analysis->{_title}          = '';
}

=head2 sub picks_file 

 set picks_file 
   waveform file   

=cut 

sub picks_file {
    my ( $variable, $picks_file ) = @_;
    if ($picks_file) {
        $spectral_analysis->{_picks_file} = $picks_file;
    }
}

=head2 sub agc_gain_width 

 set agc_gain_width 
   waveform file   

=cut 

sub agc_gain_width {
    my ( $variable, $agc_gain_width ) = @_;
    if ($agc_gain_width) {
        $spectral_analysis->{_agc_gain_width} = $agc_gain_width;
    }
}

=head2 sub filter_freq 

 set filter_freq 
   waveform file   

=cut 

sub filter_freq {
    my ( $variable, $filter_freq ) = @_;
    if ($filter_freq) {
        $spectral_analysis->{_filter_freq} = $filter_freq;
    }
}

=head2 sub window_title 

 set window_title  for suxwigb  

=cut 

sub window_title {
    my ( $variable, $window_title ) = @_;
    if ($window_title) {
        $spectral_analysis->{_window_title} = $window_title;
    }
}

=head2 sub title 

 set title  for suxwigb  

=cut 

sub title {
    my ( $variable, $title ) = @_;
    if ($title) {
        $spectral_analysis->{_title} = $title;
    }
}

=head2 sub absclip

 set absclip  for XT data  

=cut 

sub absclip {
    my ( $variable, $absclip) = @_;
    if ($absclip) {
        $spectral_analysis->{_absclip} = $absclip;
    }
}

=head2 sub absclip_phase

 set absclip  for phase  

=cut 

sub absclip_phase {
    my ( $variable, $absclip_phase ) = @_;
    if ($absclip_phase) {
        $spectral_analysis->{_absclip_phase} = $absclip_phase;
    }
}

=head2 sub absclip_freq

 set absclip  for phase  

=cut 

sub absclip_freq {
    my ( $variable, $absclip_freq ) = @_;
    if ($absclip_freq) {
        $spectral_analysis->{_absclip_freq} = $absclip_freq;
    }
}

=head2 sub inbound 

 set _inbound seismic-unix 
 -formatted file name
 including directory path as well

=cut 

sub inbound {
    my ( $variable, $inbound ) = @_;
    if ($inbound) {
        $spectral_analysis->{_inbound} = $inbound;

        # print("inbound is $spectral_analysis->{_inbound}\n\n");
    }
}

=head2 sub Step 
     
 Selection of waveform

=cut

sub Step {

    use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

    use aliased 'App::SeismicUnixGui::misc::message';
    use aliased 'App::SeismicUnixGui::misc::flow';
    use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
    use aliased 'App::SeismicUnixGui::sunix::plot::suximage';   
    use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
    use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
    use aliased 'App::SeismicUnixGui::sunix::transform::sufft';
    use aliased 'App::SeismicUnixGui::sunix::transform::suamp';
    use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
    use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';

=pod

  1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish
     Use classes:
     
     message
     flow
     sufilter
     sugain
     suxwigb    
     suximage
     suwind
     suximage
     suamp
     sufft 

=cut

    my $log      = message->new();
    my $run      = flow->new();
    my $suxwigb  = suxwigb->new();
    my $suximage = suximage->new();
    my $suwind   = suwind->new();
    my $sufft    = sufft->new();
    my $suamp    = suamp->new();
    my $sufilter = sufilter->new();
    my $sugain   = sugain->new();
    my $Project  = Project_config->new();

    my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=pod

  3. Declare local variables 

=cut

    my (@flow);
    my ( @suxwigb, @sufilter, @suximage );
    my ( @sugain,  @items );
    my ( @suamp,   @sufft );

=head2 Declare

   file names 

=cut

=pod

  5. sugain 

 this is how to use a subroutine from the sugain 'package' 
 $on =1
 $width is the width of the window in seconds
 $sugain-> Step() generates the instructions to run this single module with 
 the correct syntax for perl

 $sugain     -> agc($on);
 $sugain     -> width_s(2.6);
 $sugain[2]   = $sugain->Step();

=cut

    $sugain->clear();
    $sugain->pbal($on);
    $sugain[1] = $sugain->Step();

    $sugain->clear();
    $sugain->agc($on);
    $sugain->width_s( $spectral_analysis->{_agc_gain_width} );
    $sugain[2] = $sugain->Step();

=head2 Set

  filtering parameters 

=cut

    $sufilter->freq( $spectral_analysis->{_filter_freq} );
    $sufilter[1] = $sufilter->Step();

=head2 Set

  5. set suxwigb parameters 
  In the perl module for suxwigb we should
  have (but we do not yet) an explanation of each  of  these parameters

=cut

    $suxwigb->clear();

    #$suxwigb-> d1(1);
    #$suxwigb-> d2(1);
    #$suxwigb-> f1(1);
    #$suxwigb-> f2(1);
    $suxwigb->xcur(1);

    #$suxwigb-> va(2.5);
    $suxwigb->n2tic(1);
    $suxwigb->d2num(20);
    $suxwigb->windowtitle( $spectral_analysis->{_window_title} );
    $suxwigb->title( $spectral_analysis->{_window_title} );
    $suxwigb->xlabel( quotemeta('No.traces') );
    $suxwigb->ylabel( quotemeta('TWTT s') );
    $suxwigb->box_width(300);
    $suxwigb->box_height(500);
    $suxwigb->box_X0(250);
    $suxwigb->box_Y0(600);
    $suxwigb->absclip( $spectral_analysis->{_absclip} );
    $suxwigb[1] = $suxwigb->Step();

=head2 Set

  suxwigb parameters 
  for Frequency spectrum

=cut

    $suxwigb->clear();

    #$suxwigb-> d1(0.5);
    $suxwigb->d2(1);
    $suxwigb->f1(0);
    $suxwigb->f2(1);
    $suxwigb->xcur(1);
    $suxwigb->n2tic(1);
    $suxwigb->d2num(20);
    $suxwigb->windowtitle( $spectral_analysis->{_window_title} );
    $suxwigb->title( $spectral_analysis->{_title} );
    $suxwigb->xlabel( quotemeta('Amplitude') );
    $suxwigb->ylabel( quotemeta('Frequency (Hz)') );
    $suxwigb->box_width(300);
    $suxwigb->box_height(500);
    $suxwigb->box_X0(575);
    $suxwigb->box_Y0(600);
    $suxwigb->absclip( $spectral_analysis->{_absclip_freq} );

    #$suxwigb-> wigclip(1);
    $suxwigb[2] = $suxwigb->Step();

=head2 Set

  suxwigb parameters 
  for phase spectrum

=cut

    $suxwigb->clear();

    #$suxwigb-> d1(0.5);
    $suxwigb->d2(1);
    $suxwigb->f1(0);
    $suxwigb->f2(1);
    $suxwigb->xcur(1);
    $suxwigb->n2tic(1);
    $suxwigb->d2num(20);
    $suxwigb->windowtitle( $spectral_analysis->{_window_title} );
    $suxwigb->title( $spectral_analysis->{_title} );
    $suxwigb->xlabel( quotemeta('Phase') );
    $suxwigb->ylabel( quotemeta('Frequency (Hz)') );
    $suxwigb->box_width(300);
    $suxwigb->box_height(500);
    $suxwigb->box_X0(900);
    $suxwigb->box_Y0(600);
    $suxwigb->absclip( $spectral_analysis->{_absclip_phase} );

    #$suxwigb-> wigclip(1);
    $suxwigb[3] = $suxwigb->Step();

=head2 fft 

   

=cut

    $sufft->clear();
    $sufft->verbose($on);
    $sufft[1] = $sufft->Step();

=head2 extract f spectra 


=cut

    $suamp->clear();
    $suamp->mode('amp');
    $suamp[1] = $suamp->Step();

=head2 extract phase spectra 


=cut

    $suamp->clear();

    # $suamp -> mode('phase');
    $suamp->mode('ouphase');
    $suamp[2] = $suamp->Step();

=head2 DEFINE FLOW(S)
 

=cut

    @items = ( $suxwigb[1], $in, $spectral_analysis->{_inbound}, $go );
    $flow[1] = $run->modules( \@items );

    @items = (
        $sufft[1], $in, $spectral_analysis->{_inbound},
        $to, $suamp[1], $to, $suxwigb[2], $go
    );
    $flow[2] = $run->modules( \@items );

    @items = (
        $sufft[1], $in, $spectral_analysis->{_inbound},
        $to, $suamp[2], $to, $suxwigb[3], $go
    );
    $flow[3] = $run->modules( \@items );

    return \@flow;

=pod LOG FLOW(S)TO SCREEN AND FILE


=cut

    #print  "$flow[1]\n";

}    # end of sub Step

=pod

  place 1; at end of a package

=cut

1;
