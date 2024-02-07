package App::SeismicUnixGui::sunix::statsMath::suop2;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUOP2 - do a binary operation on two data sets			
 AUTHOR: Juan Lorenzo
 DATE:   Feb. 19 2015,
 DESCRIPTION:
 Version:  0.0.1

=head2 USE
  
=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUOP2 - do a binary operation on two data sets			

 suop2 data1 data2 op=diff [trid=111] >stdout				

 Required parameters:							
 	none								

 Optional parameter:							
 	op=diff		difference of two panels of seismic data	
 			=sum  sum of two panels of seismic data		
 			=prod product of two panels of seismic data	
 			=quo quotient of two panels of seismic data	
 			=ptdiff differences of a panel and single trace	
 			=ptsum sum of a panel and single trace		
 			=ptprod product of a panel and single trace	
 			=ptquo quotient of a panel and single trace	
 			=zipper do "zipper" merge of two panels	

  trid=FUNPACKNYQ	output trace identification code. (This option  
 			is active only for op=zipper)			
			For SU version 39-43 FUNPACNYQ=111		
 			(See: sukeyword trid     for current value)	


 Note1: Output = data1 "op" data2 with the header of data1		

 Note2: For convenience and backward compatibility, this		
 	program may be called without an op code as:			

 For:  panel "op" panel  operations: 				
 	susum  file1 file2 == suop2 file1 file2 op=sum			
 	sudiff file1 file2 == suop2 file1 file2 op=diff			
 	suprod file1 file2 == suop2 file1 file2 op=prod			
 	suquo  file1 file2 == suop2 file1 file2 op=quo			

 For:  panel "op" trace  operations: 				
 	suptsum  file1 file2 == suop2 file1 file2 op=ptsum		
 	suptdiff file1 file2 == suop2 file1 file2 op=ptdiff		
 	suptprod file1 file2 == suop2 file1 file2 op=ptprod		
 	suptquo  file1 file2 == suop2 file1 file2 op=ptquo		

 Note3: If an explicit op code is used it must FOLLOW the		
	filenames.							

 Note4: With op=quo and op=ptquo, divide by 0 is trapped and 0 is returned.

 Note5: Weighted operations can be specified by setting weighting	
	coefficients for the two datasets:				
	w1=1.0								
	w2=1.0								

 Note6: With op=zipper, it is possible to set the output trace id code 
 		(See: sukeyword trid)					
  This option processes the traces from two files interleaving its samples.
  Both files must have the same trace length and must not longer than	
  SU_NFLTS/2  (as in SU 39-42  SU_NFLTS=32768).			

  Being "tr1" a trace of data1 and "tr2" the corresponding trace of
  data2, The merged trace will be :					

  tr[2*i]= tr1[i]							
  tr[2*i+1] = tr2[i]							

  The default value of output tr.trid is that used by sufft and suifft,
  which is the trace id reserved for the complex traces obtained through
  the application of sufft. See also, suamp.				

 For operations on non-SU binary files  use:farith 			

 Credits:
	SEP: Shuki Ronen
	CWP: Jack K. Cohen
	CWP: John Stockwell, 1995, added panel op trace options.
	: Fernando M. Roxo da Motta <petro@roxo.org> - added zipper op

 Notes:
	If efficiency becomes important consider inverting main loop
	and repeating operation code within the branches of the switch.
	
=head2 User's notes (Juan Lorenzo)

(old)
  $file[1] = fileA
  $file[2]= fileB
  suop2->clear();
  suop2->AminusB();
  suop2->fileA(\$file[1]);
  suop2->fileB(\$file[2]);
  $suop[1] = suop2->Step();
  
  V 0.0.3 May 2023
  You can include a list of file names

=cut

=head2 CHANGES and their DATES

	V 0.0.2 Oct 4 2018
	V 0.0.3 May 2023
	
=cut

use Moose;
our $VERSION = '0.0.1';

my $suop2 = {
    _file1 => '',
    _file2 => '',
    _file_list1 => '',
    _file_list2 => '',
    _op    => '',
    _trid  => '',
    _w1    => '',
    _w2    => '',
    _Step  => '',
    _note  => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suop2->{_Step} = 'suop2' . $suop2->{_Step} . ' op=' . $suop2->{_op};
    return ( $suop2->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suop2->{_note} = 'suop2' . $suop2->{_note} . $suop2->{_op};
    return ( $suop2->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suop2->{_Output} = '';
    $suop2->{_file1}  = '';
    $suop2->{_file2}  = '';
    $suop2->{_file_list1}  = '';
    $suop2->{_file_list2}  = '';    
    $suop2->{_op}     = '';
    $suop2->{_trid}   = '';
    $suop2->{_w1}     = '';
    $suop2->{_w2}     = '';
    $suop2->{_Step}   = '';
    $suop2->{_note}   = '';
}

=head2 subroutine AminusB 

 fis operation to be diff
 subtract one su file from another
 trace by trace

=cut

sub AminusB {

    my ($self) = @_;

    my $diff = 'diff';
    if ($diff) {

        $suop2->{_op} = $diff;

    }
    else {
        print("suop2, AminusB, missing suop2,\n");
    }

}

=head2 subroutine AplusB 

 add one su file to another
 trace by trace

=cut

sub AplusB {

    my ($self) = @_;

    my $sum = 'sum';
    if ($sum) {

        $suop2->{_op} = $sum;

    }
    else {
        print("suop2, AplusB, missing suop2,\n");
    }

}

=head2 subroutine file1 

 subs fileA and file1, first file with which to operate

=cut

sub file1 {

    my ( $self, $file1 ) = @_;

    if ($file1) {

        $suop2->{_file1} = $file1;
        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file1};
        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file1};

    }
    else {
        print("suop2, file1, first file is missing,\n");
    }

    return ();
}

=head2 subroutine file2 

 subs file2, fileB, second file with which to operate

=cut

sub file2 {

    my ( $self, $file2 ) = @_;

    if ($file2) {

        $suop2->{_file2} = $file2;
        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file2};
        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file2};

    }
    else {
        print("suop2, file2, second file is missing,\n");
    }

    return ();
}

=head2 subroutine file_list1 

 

=cut

sub file_list1 {

    my ( $self, $file_list1 ) = @_;

    if (length $file_list1) {

        $suop2->{_file_list1} = $file_list1;
#        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file1};
#        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file1};

    }
    else {
        print("suop2, file_list1, first file is missing,\n");
    }

    return ();
}

=head2 subroutine file_list2 


=cut

sub file_list2 {

    my ( $self, $file_list2 ) = @_;

    if (length $file_list2) {

        $suop2->{_file_list2} = $file_list2;
#        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file2};
#        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file2};

    }
    else {
        print("suop2, file_list2, second file is missing,\n");
    }

    return ();
}

=head2 subroutine fileA 

 subs fileA and file1, first file with which to operate

=cut

sub fileA {

    my ( $self, $ref_fileA ) = @_;

    if ($ref_fileA) {

        $suop2->{_file1} = $$ref_fileA;
        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file1};
        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file1};

    }
    else {
        print("suop2, fileA, first file is missing,\n");
    }

    return ();
}

=head2 subroutine fileB 

 subs file2, fileB, second file with which to operate

=cut

sub fileB {

    my ( $self, $ref_fileB ) = @_;

    if ($ref_fileB) {

        $suop2->{_file2} = $$ref_fileB;
        $suop2->{_note}  = $suop2->{_note} . ' ' . $suop2->{_file2};
        $suop2->{_Step}  = $suop2->{_Step} . ' ' . $suop2->{_file2};

    }
    else {
        print("suop2, fileB, second file is missing,\n");
    }

    return ();
}

=head2 sub op 


=cut

sub op {

    my ( $self, $op ) = @_;
    if ($op) {

        $suop2->{_op} = $op;

    }
    else {
        print("suop2, op, missing op,\n");
    }
}

=head2 sub trid 


=cut

sub trid {

    my ( $self, $trid ) = @_;
    if ($trid) {

        $suop2->{_trid} = $trid;
        $suop2->{_note} = $suop2->{_note} . ' trid=' . $suop2->{_trid};
        $suop2->{_Step} = $suop2->{_Step} . ' trid=' . $suop2->{_trid};

    }
    else {
        print("suop2, trid, missing trid,\n");
    }
}

=head2 sub w1 


=cut

sub w1 {

    my ( $self, $w1 ) = @_;
    if ($w1) {

        $suop2->{_w1}   = $w1;
        $suop2->{_note} = $suop2->{_note} . ' w1=' . $suop2->{_w1};
        $suop2->{_Step} = $suop2->{_Step} . ' w1=' . $suop2->{_w1};

    }
    else {
        print("suop2, w1, missing w1,\n");
    }
}

=head2 sub w2 


=cut

sub w2 {

    my ( $self, $w2 ) = @_;
    if ($w2) {

        $suop2->{_w2}   = $w2;
        $suop2->{_note} = $suop2->{_note} . ' w2=' . $suop2->{_w2};
        $suop2->{_Step} = $suop2->{_Step} . ' w2=' . $suop2->{_w2};

    }
    else {
        print("suop2, w2, missing w2,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    my $max_index = 5;

    return ($max_index);
}

1;
