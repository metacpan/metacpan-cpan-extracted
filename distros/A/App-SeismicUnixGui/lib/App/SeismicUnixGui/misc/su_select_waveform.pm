package App::SeismicUnixGui::misc::su_select_waveform;

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PERL PROGRAM NAME:select_waveform.pm
  Purpose: Simple viewing of an su file 
           to select  waveforms  
           waveforms are xtracted at a later stage
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    July 7 2016 V0.1
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

use Moose;
our $VERSION = '0.0.1';

use App::SeismicUnixGui::misc::SeismicUnix qw($on $off);

=head2 declare common variables

=cut

my @flow;

=head2 Create 

 hash of shared variables and
 subroutine to clear them

 Do not clear: absclip

=cut 

my $select = {
    _agc_gain_width => '',
    _filter_freq    => '',
    _inbound        => '',
    _outbound       => '',
    _picks_file     => 'waveform',
    _absclip        => 1,
    _window_title   => '',
    _title          => ''
};

sub clear {

    $select->{_agc_gain_width} = '';
    $select->{_filter_freq}    = '';
    $select->{_inbound}        = '';
    $select->{_outbound}       = '';
    $select->{_picks_file}     = '';
    $select->{_window_title}   = '';
    $select->{_title}          = '';
    @flow                      = ();

}

=head2 sub picks_file 

 set picks_file 
   waveform file   

=cut 

sub picks_file {
    my ( $variable, $picks_file ) = @_;
    if ($picks_file) {
        $select->{_picks_file} = $picks_file;

       # print("su_select_waveform,picks_file, file= $select->{_picks_file}\n");
    }
}

=head2 sub agc_gain_width 

 set agc_gain_width 
   waveform file   

=cut 

sub agc_gain_width {
    my ( $variable, $agc_gain_width ) = @_;
    if ($agc_gain_width) {
        $select->{_agc_gain_width} = $agc_gain_width;
    }
}

=head2 sub filter_freq 

 set filter_freq 
   waveform file   

=cut 

sub filter_freq {
    my ( $variable, $filter_freq ) = @_;
    if ($filter_freq) {
        $select->{_filter_freq} = $filter_freq;
    }
}

=head2 sub window_title 

 set window_title  for suxwigb  

=cut 

sub window_title {
    my ( $variable, $window_title ) = @_;
    if ($window_title) {
        $select->{_window_title} = $window_title;
    }
}

=head2 sub title 

 set title  for suxwigb  

=cut 

sub title {
    my ( $variable, $title ) = @_;
    if ($title) {
        $select->{_title} = $title;
    }
}

=head2 sub absclip 

 set absclip  for suxwigb  

=cut 

sub absclip {
    my ( $variable, $absclip ) = @_;
    if ($absclip) {
        $select->{_absclip} = $absclip;
        # print("su_select_waveform, absclip=$select->{_absclip}\n");
    }
}

=head2 sub inbound 

 set _inbound seismic-unix 
 -formatted file name

=cut 

sub inbound {
    my ( $variable, $inbound ) = @_;
    if ($inbound) {
        $select->{_inbound} = $inbound;
    }
}

=head2 sub Step 
     
 Selection of waveform

=cut

sub Step {

=head2 

 needed packages

=cut

    use aliased 'App::SeismicUnixGui::misc::message';
    use aliased 'App::SeismicUnixGui::misc::flow';
    use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
    use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
    use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
    use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
    use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
    use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

=pod

  1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish
     Use classes:
     flow
     log
     message
     sufilter
     sugain
     suxwigb
     suximage
     readfiles 

=cut

    my $run      = flow->new();
    my $log      = message->new();
    my $sufilter = sufilter->new();
    my $sugain   = sugain->new();
    my $suxwigb  = suxwigb->new();
    my $suximage = suximage->new();
    my $Project  = Project_config->new();

    my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=pod

  3. Declare local variables 

=cut

    my ( @suxwigb, @sufilter, @suximage );
    my ( @sugain, @items );

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
    $sugain->agc($on);
    $sugain->width_s( $select->{_agc_gain_width} );
    $sugain[2] = $sugain->Step();

=head2 Set

  filtering parameters 

=cut

    $sufilter->clear();
    $sufilter->freq( $select->{_filter_freq} );
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
    $suxwigb->xcur(3);

    #$suxwigb-> va(2.5);
    $suxwigb->n2tic(1);
    $suxwigb->d2num(20);
    $suxwigb->windowtitle( quotemeta('PICK 2 corners') );
    $suxwigb->picks( $select->{_picks_file} );
    $suxwigb->title( $select->{_title} );
    $suxwigb->xlabel('No.traces');
    $suxwigb->ylabel('TWTT\ s');
    $suxwigb->box_width(600);
    $suxwigb->box_height(500);
    $suxwigb->box_X0(350);
    $suxwigb->box_Y0(0);
    $suxwigb->absclip( $select->{_absclip} );
    $suxwigb[1] = $suxwigb->Step();

=pod

  5. set suximage parameters 
  In the perl module for suxmage we should
  have (but we do not yet) an explanation of each of
  these parameters

=cut

    $suximage->clear();
    $suximage->title( $select->{_title} );
    $suximage->xlabel('No.traces');
    $suximage->ylabel('TWTT\ s');
    $suximage->box_width(600);
    $suximage->box_height(500);
    $suximage->box_X0(975);
    $suximage->box_Y0(0);
    $suximage->legend($on);
    $suximage->absclip( $select->{_absclip} );
    $suximage->windowtitle( $select->{_window_title} );
    $suximage[1] = $suximage->Step();

=pod
 
  Standard:
  1. DEFINE FLOW(S)

=cut

    @items = (
        $sufilter[1], $in, $select->{_inbound}, $to, $sugain[2], $to,
        $suximage[1], $go
    );

    $flow[1] = $run->modules( \@items );

    @items = (
        $sufilter[1], $in, $select->{_inbound}, $to, $sugain[2], $to,
        $suxwigb[1], $go
    );

    $flow[2] = $run->modules( \@items );

=pod

  3. LOG FLOW(S)TO SCREEN AND FILE

=cut

    # print "su_select_waveform,$flow[1]\n";

    # print  "su_select_waveform,$flow[2]\n";

    return ( \@flow );

}    # end of sub Step


1;

