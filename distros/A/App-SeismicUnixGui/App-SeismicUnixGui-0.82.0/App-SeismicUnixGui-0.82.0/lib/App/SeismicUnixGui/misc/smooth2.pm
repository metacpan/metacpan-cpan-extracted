#!/usr/bin/perl

package App::SeismicUnixGui::misc::smooth2;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: smooth2 
 AUTHOR: Juan Lorenzo
 DATE:  July 11 2016,

 DESCRIPTION: 
 Version: 0.1

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  
  SMOOTH2 --- SMOOTH a uniformly sampled 2d array of data, within a user-
		defined window, via a damped least squares technique	
									
 smooth2 < stdin n1= n2= [optional parameters ] > stdout		
									
 Required Parameters:							
 n1=			number of samples in the 1st (fast) dimension	
 n2=			number of samples in the 2nd (slow) dimension	
									
 Optional Parameters:							
 r1=0			smoothing parameter in the 1 direction		
 r2=0			smoothing parameter in the 2 direction		
 win=0,n1,0,n2		array for window range				
 rw=0			smoothing parameter for window function		
 efile=                 =efilename if set write relative error(x1) to	
				efilename				
									
 Notes:								
 Larger r1 and r2 result in a smoother data. Recommended ranges of r1 	
 and r2 are from 1 to 20.						
									
 The file verror gives the relative error between the original velocity 
 and the smoothed one, as a function of depth. If the error is		
 between 0.01 and 0.1, the smoothing parameters are suitable. Otherwise,
 consider increasing or decreasing the smoothing parameter values.	
									
 Smoothing can be implemented in a selected window. The range of 1st   
 dimension for window is from win[0] to win[1]; the range of 2nd   	
 dimension is from win[2] to win[3]. 					
									
 Smoothing the window function (i.e. blurring the edges of the window)	
 may be done by setting a nonzero value for rw, otherwise the edges	
 of the window will be sharp.						
 				
=head4 CHANGES and their DATES


=cut

=pod

=head3 Build a list or hash

  with all the possible variable
  names you may use and you can even change them

=cut

my $smooth2 = {
    _n1    => '',
    _n2    => '',
    _r1    => '',
    _r2    => '',
    _rw    => '',
    _efile => '',
    _win   => '',
    _note  => '',
    _Step  => ''
};

# define a value
my $newline = '
';

sub test {
    my ( $test, @value ) = @_;
    print(
        "\$test or the first scalar  'holds' a  HASH $test 
 that represents the name of the  
 subroutine you are trying to use and all its needed components\n"
    );
    print(
"\@value, the second scalar is something 'real' you put in, i.e., @value\n\n"
    );
    print("new line is $newline\n");

    #my ($smooth2->{_Step}) = $smooth2->{_Step} +1;
    #print("Share step is first $smooth2->{_Step}\n");
}

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $smooth2->{_n1}    = '';
    $smooth2->{_n2}    = '';
    $smooth2->{_r1}    = '';
    $smooth2->{_r2}    = '';
    $smooth2->{_rw}    = '';
    $smooth2->{_efile} = '';
    $smooth2->{_note}  = '';
    $smooth2->{_Step}  = '';
}

=head2 subroutine n1 

 number of samples in the 1st (fast) dimension

=cut

sub n1 {
    my ( $variable, $n1 ) = @_;
    $smooth2->{_n1}   = $n1 if defined($n1);
    $smooth2->{_note} = $smooth2->{_note} . ' n1=' . $smooth2->{_n1};
    $smooth2->{_Step} = $smooth2->{_Step} . ' n1=' . $smooth2->{_n1};
}

=head2 subroutine n2 

 number of samples in the 2nd (slow) dimension

=cut

sub n2 {
    my ( $variable, $n2 ) = @_;
    $smooth2->{_n2}   = $n2 if defined($n2);
    $smooth2->{_note} = $smooth2->{_note} . ' n2=' . $smooth2->{_n2};
    $smooth2->{_Step} = $smooth2->{_Step} . ' n2=' . $smooth2->{_n2};
}

=head2 subroutine r1 

   smoothing parameter in the 1 direction

=cut

sub r1 {
    my ( $variable, $r1 ) = @_;
    $smooth2->{_r1}   = $r1 if defined($r1);
    $smooth2->{_note} = $smooth2->{_note} . ' r1=' . $smooth2->{_r1};
    $smooth2->{_Step} = $smooth2->{_Step} . ' r1=' . $smooth2->{_r1};
}

=head2 subroutine r2 

   smoothing parameter in the 2 direction

=cut

sub r2 {
    my ( $variable, $r2 ) = @_;
    $smooth2->{_r2}   = $r2 if defined($r2);
    $smooth2->{_note} = $smooth2->{_note} . ' r2=' . $smooth2->{_r2};
    $smooth2->{_Step} = $smooth2->{_Step} . ' r2=' . $smooth2->{_r2};
}

=head2 subroutine rw 

   smoothing parameter for window function	

=cut

sub rw {
    my ( $variable, $rw ) = @_;
    $smooth2->{_rw}   = $rw if defined($rw);
    $smooth2->{_note} = $smooth2->{_note} . ' rw=' . $smooth2->{_rw};
    $smooth2->{_Step} = $smooth2->{_Step} . ' rw=' . $smooth2->{_rw};
}

=head2 subroutine efile 

  efilename if set write relative error(x1) to
   

=cut

sub efile {
    my ( $variable, $efile ) = @_;
    $smooth2->{_efile} = $efile if defined($efile);
    $smooth2->{_note}  = $smooth2->{_note} . ' efile=' . $smooth2->{_efile};
    $smooth2->{_Step}  = $smooth2->{_Step} . ' efile=' . $smooth2->{_efile};
}

=head2 subroutine win 

  array for window range 

=cut

sub win {
    my ( $variable, $win ) = @_;
    $smooth2->{_win}  = $win if defined($win);
    $smooth2->{_note} = $smooth2->{_note} . ' win=' . $smooth2->{_win};
    $smooth2->{_Step} = $smooth2->{_Step} . ' win=' . $smooth2->{_win};
}

sub Step {
    $smooth2->{_Step} = 'smooth2' . $smooth2->{_Step};
    return $smooth2->{_Step};
}

=head2 subroutine  

=cut

sub note {
    $smooth2->{_note} = $smooth2->{_note};
    return $smooth2->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
