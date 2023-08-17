package App::SeismicUnixGui::misc::su_xtract_waveform;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PERL PROGRAM NAME: xract_waveform.pl
  Purpose: Simple viewing of an su file 
           to extract waveforms  
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    July 7 2016 V0.1
  DESCRIPTION:  based upon non-oop Xtract.pl  

=head2 USES

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
  
=head2 STEPS IN THE PROGRAM 

=cut

=head2 Create 

 hash of shared variables and
 subroutine to clear them

 Do not clear: absclip

=cut 

my $xtract = {
    _inbound          => '',
    _outbound         => '',
    _ref_picks_file   => '',
    _ref_indices      => '',
    _file_out         => '',
    _header_word      => 'tracf',
    _absclip          => 1,
    _waveform_tmin    => '',
    _waveform_tmax    => '',
    _waveform_key_max => '',
    _waveform_key_min => '',
    _window_title     => ''
};

sub clear {
    $xtract->{_key}              = '';
    $xtract->{_inbound}          = '';
    $xtract->{_ref_indices}      = '';
    $xtract->{_outbound}         = '';
    $xtract->{_ref_picks_file}   = '';
    $xtract->{_file_out}         = '';
    $xtract->{_header_word}      = '';
    $xtract->{_window_title}     = '';
    $xtract->{_waveform_tmin}    = '';
    $xtract->{_waveform_tmax}    = '';
    $xtract->{_waveform_key_max} = '';
    $xtract->{_waveform_key_min} = '';
}

=head2 sub inbound 

 set inbound seismic-unix 
 -formatted file name

=cut 

sub inbound {
    my ( $variable, $inbound ) = @_;
    if ($inbound) {
        $xtract->{_inbound} = $inbound;

        #print("inbound is $xtract->{_inbound}\n\n");
    }
}

=head2 sub absclip 

 set absclip for suxwigb  
 

=cut 

sub absclip {
    my ( $variable, $absclip ) = @_;
    if ($absclip) {
        $xtract->{_absclip} = $absclip;
    }
}

=head2 sub  sorted_indices

  for sorting indices 

=cut 

sub sorted_indices {
    my (@unsorted) = @_;
    my @idx = sort { $unsorted[$a] <=> $unsorted[$b] } 0 .. $#unsorted;
    $xtract->{_ref_indices} = \@idx;

    #print ("indices are @idx\n\n");
    #print("unsorted is @unsorted\n\n");
}

=head2 sub file_out 

 set name of output file
 using both ref_picks_file that 
 is used to select a single waveform 
 and the seismic unix file containing all the data   

=cut 

sub file_out {
    my ( $variable, $ref_picks_file, $inbound ) = @_;

=head2  Read 
       
        the picked 'waveform' file 
        assume local directory

=cut

    if ( $ref_picks_file && $inbound ) {

        use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_su);
        use aliased 'App::SeismicUnixGui::misc::readfiles';

        my $read = readfiles->new();
        my ( $ref_time, $ref_key, $max_index ) =
          $read->cols_2p($ref_picks_file);

=head2  Sort 
       
        the picked 'waveform' file

=cut

        #print("keys are @$ref_key\n");
        #print("times are @$ref_time\n");
        my $idx         = sorted_indices(@$ref_key);
        my @sorted_key  = @$ref_key[@$idx];
        my @sorted_time = @$ref_time[@$idx];

        print("sorted keys are @sorted_key\n\n");
        print("sorted times are @sorted_time\n\n");

        $xtract->{_waveform_tmin}    = $sorted_time[0];
        $xtract->{_waveform_tmax}    = $sorted_time[$max_index];
        $xtract->{_waveform_key_max} = $sorted_key[$max_index];
        $xtract->{_waveform_key_min} = $sorted_key[0];

        $xtract->{_file_out} =
            $$ref_picks_file . '_'
          . $xtract->{_waveform_tmin} . 's_'
          . $xtract->{_waveform_tmax} . 's'
          . $suffix_su;
        print("su_xtract_waveform,file out: $xtract->{_file_out}\n\n");

=head2 Error

 Message

=cut

        if ( $xtract->{_waveform_key_min} <= 1 ) {
             # print("su_xtract_waveform,file outsmallest key is $xtract->{_waveform_key_min}\n");
             # print("su_xtract_waveform,file outupdated to 1 \n");
            $xtract->{_waveform_key_min} = 1;
        }

        if ( $xtract->{_waveform_key_max} <= 1 ) {
            # print("su_xtract_waveform,file outlsu_xtract_waveform,file outargest key is $xtract->{_waveform_key_max}\n");
            # print("su_xtract_waveform,file outupdated to 1 \n");
            $xtract->{_waveform_key_max} = 1;

#$xtract->{_file_out} = ${$xtract->{_ref_picks_file}}.'_'.$waveform_tmin.'s_'.$waveform_tmax.'s'.$suffix_su;     #print("picks file is ${$xtract->{_file_out}} \n\n");
        }

        return $xtract->{_file_out};
    }

}    # end of sub file_out

=head2 sub  

 set ref_picks_file 
 waveform file   

=cut 

sub ref_picks_file {
    my ( $variable, $ref_picks_file ) = @_;
    if ($ref_picks_file) {
        $xtract->{_ref_picks_file} = $ref_picks_file;

        #print("picks file is ${$xtract->{_ref_picks_file}} \n\n");
    }
}

=head2 sub header_word 

 set header_word for suwind  
 
=cut 

sub header_word {
    my ( $variable, $header_word ) = @_;
    if ($header_word) {
        $xtract->{_header_word} = $header_word;
    }
}

=head2 sub window_title 

 set window_title  for suxwigb  

=cut 

sub window_title {
    my ( $variable, $window_title ) = @_;
    if ($window_title) {
        $xtract->{_window_title} = $window_title;
    }
}

=head2 sub Step 
     
 Extraction of waveform

=cut

sub Step {

    use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
    use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
    use aliased 'App::SeismicUnixGui::misc::message';
    use aliased 'App::SeismicUnixGui::misc::flow';
    use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
    use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';

=head2 Instantiate classes

  1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish
     Use classes:
     flow
     log
     message
     suxwigb
     suwind

=cut

    my $Project = Project_config->new();
    my $log     = message->new();
    my $run     = flow->new();
    my $suxwigb = suxwigb->new();
    my $suwind  = suwind->new();

=head2 Declare

  local variables 

=cut

    my ( @flow, @sufile_out );
    my (@suxwigb);
    my ( @suwind, @items );
    my (@read);

    my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=head2  Set
  
  Only for debugging
  set suxwigb parameters 
  In the perl module for suxwigb we should
  have (but we do not yet) an explanation of each  of  these parameters

 $suxwigb-> clear();
 $suxwigb-> d1(1); 
 $suxwigb-> d2(1); 
 $suxwigb-> f1(1); 
 $suxwigb-> f2(1); 
 $suxwigb-> xcur(1);
 $suxwigb-> n2tic(1);
 $suxwigb-> d2num(20);
 $suxwigb-> windowtitle($xtract->{_window_title});
 #$suxwigb-> title($xtract->{_window_title}); 
 $suxwigb-> xlabel($xtract->{_header_word});  
 suxwigb-> ylabel('TWTT\ s'); 
 $suxwigb-> box_width(300); 
 $suxwigb-> box_height(500); 
 $suxwigb-> box_X0(0); 
 $suxwigb-> box_Y0(0); 
 $suxwigb-> absclip($xtract->{_absclip});
 $suxwigb[1]  = $suxwigb->Step();

 @items   = ($suwind[1],$in,$xtract->{_inbound},$to,
             $suwind[2],$to,$suxwigb[1],$go);
 $flow[1] = $run->modules(\@items);

=cut

=head2 QC-Extract

 	the selected waveform
        to a file 
=cut

    $xtract->{_outbound} = $DATA_SEISMIC_SU . '/' . $xtract->{_file_out};

=head2 Window by

  trace 

=cut

    $suwind->clear();
    $suwind->key( $xtract->{_header_word} );
    $suwind->min( $xtract->{_waveform_key_min} );
    $suwind->max( $xtract->{_waveform_key_max} );
    $suwind[1] = $suwind->Step();

=head2 Window by 

  time 

=cut

    $suwind->clear();
    $suwind->tmin( $xtract->{_waveform_tmin} );
    $suwind->tmax( $xtract->{_waveform_tmax} );
    $suwind[2] = $suwind->Step();

=head2 DEFINE FLOW(S)
 
  Save a copy of extracted file

=cut

    @items = (
        $suwind[1], $in, $xtract->{_inbound}, $to,
        $suwind[2], $out, $xtract->{_outbound}, $go
    );
    $flow[1] = $run->modules( \@items );

    #print ("flow is $flow[1]\n\n");
    #print ("flow is $flow[2]\n\n");

    return \@flow;

}    # end of sub Step


1;
