package App::SeismicUnixGui::sunix::header::sustatic_old;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: sustatic 
AUTHOR: Juan Lorenzo (Perl module only)
 DATE: June 2 2016 
 DESCRIPTION surface consistent receiver-source static
 Version 1
 Notes: 
 Package name is the same as the file name
 Moose is a package that allows an object-oriented
 syntax to organizing your programs

=cut

=head2  Notes from Seismic Unix

 SUSTATIC - Elevation static corrections, apply corrections from	
	      headers or from a source and receiver statics file	
									
     sustatic <stdin >stdout  [optional parameters]	 		
									
 Required parameters:							
	none								
 Optional Parameters:							
	v0=v1 or user-defined	or from header, weathering velocity	
	v1=user-defined		or from header, subweathering velocity	
	hdrs=0			=1 to read statics from headers		
 				=2 to read statics from files		
				=3 to read from output files of suresstat
	sign=1			apply static correction (add tstat values)
				=-1 apply negative of tstat values	
 Options when hdrs=2 and hdrs=3:					
	sou_file=		input file for source statics (ms) 	
	rec_file=		input file for receiver statics (ms) 	
	ns=240 			number of souces 			
	nr=335 			number of receivers 			
	no=96 			number of offsets			
									
 Notes:								
 For hdrs=1, statics calculation is not performed, statics correction  
 is applied to the data by reading statics (in ms) from the header.	
									
 For hdrs=0, field statics are calculated, and				
 	input field sut is assumed measured in ms.			
 	output field sstat = 10^scalel*(sdel - selev + sdepth)/swevel	
 	output field gstat = sstat - sut/1000.				
 	output field tstat = sstat + gstat + 10^scalel*(selev - gelev)/wevel
									
 For hdrs=2, statics are surface consistently obtained from the 	
 statics files. The geometry should be regular.			
 The source- and receiver-statics files should be unformated C binary 	
 floats and contain the statics (in ms) as a function of surface location.

 For hdrs=3, statics are read from the output files of suresstat, with 
 the same options as hdrs=2 (but use no=max traces per shot and assume 
 that ns=max shot number and nr=max receiver number).			
 For each shot number (trace header fldr) and each receiver number     
 (trace header tracf) the program will look up the appropriate static  
 correction.  The geometry need not be regular as each trace is treated
 independently.							
									
 Caveat:  The static shifts are computed with the assumption that the  
 desired datum is sea level (elevation=0). You may need to shift the	
 selev and gelev header values via  suchw.				
 Example: subtracting min(selev,gelev)=25094431			
									
 suchw < CR290.su key1=selev,gelev key2=selev,gelev key3=selev,gelev \ 
            a=-25094431,-25094431 b=1,1 c=0,0 > CR290datum.su		

=cut

=head2 USAGE 1 

 Example
        $sustatic->hdr(3);
        $sustatic->Step();
=cut

my $sustatic = {
    _hdrs     => '',
    _no       => '',
    _note     => '',
    _nr       => '',
    _ns       => '',
    _rec_file => '',
    _sign     => '',
    _sou_file => '',
    _Step     => '',
    _v0       => '',
    _v1       => ''
};

=head2 Notes

   Apply statics 

=head2 sub clear:

 clean hash of its values

=cut

sub clear {
    $sustatic->{_hdrs}     = '';
    $sustatic->{_no}       = '';
    $sustatic->{_note}     = '';
    $sustatic->{_nr}       = '';
    $sustatic->{_ns}       = '';
    $sustatic->{_rec_file} = '';
    $sustatic->{_sign}     = '';
    $sustatic->{_sou_file} = '';
    $sustatic->{_Step}     = '';
    $sustatic->{_v0}       = '';
    $sustatic->{_v1}       = '';
}

=head2 subroutine  hdrs


=cut

sub hdrs {
    my ( $variable, $hdrs ) = @_;
    if ($hdrs) {
        $sustatic->{_hdrs} = $hdrs;
        $sustatic->{_Step} =
          $sustatic->{_Step} . ' hdrs=' . $sustatic->{_hdrs};
        $sustatic->{_note} =
          $sustatic->{_note} . ' hdrs=' . $sustatic->{_hdrs};
    }
}

=head2 subroutine no

=cut

sub no {
    my ( $variable, $no ) = @_;
    if ($no) {
        $sustatic->{_no}   = $no;
        $sustatic->{_Step} = $sustatic->{_Step} . ' no=' . $sustatic->{_no};
        $sustatic->{_note} = $sustatic->{_note} . ' no=' . $sustatic->{_no};
    }
}

=head2 subroutine  note

=cut

sub note {
    my ( $variable, $note ) = @_;
    $sustatic->{_note} = $note;
    return $sustatic->{_note};
}

=head2 subroutine  nr

=cut

sub nr {
    my ( $variable, $nr ) = @_;
    if ($nr) {
        $sustatic->{_nr} = $nr;

        $sustatic->{_Step} = $sustatic->{_Step} . ' nr=' . $sustatic->{_nr};
        $sustatic->{_note} = $sustatic->{_note} . ' nr=' . $sustatic->{_nr};
    }
}

=head2 subroutine rec_file 

=cut

sub rec_file {

    my ( $variable, $rec_file ) = @_;
    if ($rec_file) {
        $sustatic->{_rec_file} = $rec_file;
        $sustatic->{_Step} =
          $sustatic->{_Step} . ' rec_file=' . $sustatic->{_rec_file};
        $sustatic->{_note} =
          $sustatic->{_note} . ' rec_file=' . $sustatic->{_rec_file};
    }
}

=head2 subroutine sign 


=cut

sub sign {

    my ( $variable, $sign ) = @_;
    if ($sign) {
        $sustatic->{_sign} = $sign;
        $sustatic->{_Step} =
          $sustatic->{_Step} . ' sign=' . $sustatic->{_sign};
        $sustatic->{_note} =
          $sustatic->{_note} . ' sign=' . $sustatic->{_sign};
    }
}

=head2 subroutine sou_file

=cut

sub sou_file {
    my ( $variable, $sou_file ) = @_;
    if ($sou_file) {
        $sustatic->{_sou_file} = $sou_file;
        $sustatic->{_Step} =
          $sustatic->{_Step} . ' sou_file=' . $sustatic->{_sou_file};
        $sustatic->{_note} =
          $sustatic->{_note} . ' sou_file=' . $sustatic->{_sou_file};
    }
}

=head2 subroutine  Step

=cut

sub Step {

    $sustatic->{_Step} = 'sustatic ' . $sustatic->{_Step};
    return $sustatic->{_Step};
}

=head2 subroutine  v0

=cut

sub v0 {
    my ( $variable, $v0 ) = @_;
    if ($v0) {
        $sustatic->{_v0}   = $v0;
        $sustatic->{_Step} = $sustatic->{_Step} . ' v0='
          . $sustatic->{_source_statics_output_file};
        $sustatic->{_note} = $sustatic->{_note} . ' v0='
          . $sustatic->{_source_statics_output_file};
    }
}

=head2 subroutine  v1

=cut

sub v1 {
    my ( $variable, $v1 ) = @_;
    if ($v1) {
        $sustatic->{_v1}   = $v1;
        $sustatic->{_Step} = $sustatic->{_Step} . ' v1='
          . $sustatic->{_source_statics_output_file};
        $sustatic->{_note} = $sustatic->{_note} . ' v1='
          . $sustatic->{_source_statics_output_file};
    }
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=6
    my $max_index = 6;

    return ($max_index);
}

1;
