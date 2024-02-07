package App::SeismicUnixGui::sunix::header::sushw;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUSHW - Set one or more Header Words using trace number, mod and	
 
AUTHOR: Juan Lorenzo (Perl module only)

 DATE:   
 
 DESCRIPTION:
 
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUSHW - Set one or more Header Words using trace number, mod and	
	 integer divide to compute the header word values or input	
	 the header word values from a file				

 ... compute header fields						
   sushw <stdin >stdout key=cdp,.. a=0,..  b=0,.. c=0,.. d=0,.. j=..,..

 ... or read headers from a binary file				
   sushw <stdin > stdout  key=key1,..    infile=binary_file		


 Required Parameters for setting headers from infile:			
 key=key1,key2 ... is the list of header fields as they appear in infile
 infile= 	binary file of values for field specified by		
 		key1,key2,...						

 Optional parameters ():						
 key=cdp,...			header key word(s) to set 		
 a=0,...			value(s) on first trace			
 b=0,...			increment(s) within group		
 c=0,...			group increment(s)	 		
 d=0,...			trace number shift(s)			
 j=ULONG_MAX,ULONG_MAX,...	number of elements in group		

 Notes:								
 Fields that are getparred must have the same number of entries as key	
 words being set. Any field that is not getparred is set to the default
 value(s) above. Explicitly setting j=0 will set j to ULONG_MAX.	

 The value of each header word key is computed using the formula:	
 	i = itr + d							
 	val(key) = a + b * (i % j) + c * (int(i / j))			
 where itr is the trace number (first trace has itr=0, NOT 1)		

 Examples:								
 1. set every dt field to 4ms						
 	sushw <indata key=dt a=4000 |...				
 2. set the sx field of the first 32 traces to 6400, the second 32 traces
    to 6300, decrementing by -100 for each 32 trace groups		
   ...| sushw key=sx a=6400 c=-100 j=32 |...				
 3. set the offset fields of each group of 32 traces to 200,400,...,6400
   ...| sushw key=offset a=200 b=200 j=32 |...				
 4. perform operations 1., 2., and 3. in one call			
  ..| sushw key=dt,sx,offset a=4000,6400,200 b=0,0,200 c=0,-100,0 j=0,32,32 |

 In this example, we set every dt field to 4ms.  Then we set the first	
 32 shotpoint fields to 6400, the second 32 shotpoint fields to 6300 and
 so forth.  Next we set each group of 32 offset fields to 200, 400, ...,
 6400.									

 Example of a typical processing sequence using suchw:			
  sushw <indata key=dt a=4000 |					
  sushw key=sx a=6400 c=-100 j=32 |					
  sushw key=offset a=200 b=200 j=32 |			     		
  suchw key1=gx key2=offset key3=sx b=1 c=1 |		     		
  suchw key1=cdp key2=gx key3=sx b=1 c=1 d=2 >outdata	     		

 Again, it is possible to eliminate the multiple calls to both sushw and
 sushw, as in Example 4.						

 Reading header values from a binary file:				
 If the parameter infile=binary_file is set, then the values that are to
 be set for the fields specified by key=key1,key2,... are read from that
 file. The values are read sequentially from the file and assigned trace
 by trace to the input SU data. The infile consists of C (unformated)	
 binary floats in the form of an array of size (nkeys)*(ntraces) where	
 nkeys is the number of floats in the first (fast) dimension and ntraces
 is the number of traces.						

 Comment: 								
 Users wishing to edit one or more header fields (as in geometry setting)
 may do this via the following sequence:				
     sugethw < sudata output=geom  key=key1,key2 ... > hdrfile 	
 Now edit the ASCII file hdrfile with any editor, setting the fields	
 appropriately. Convert hdrfile to a binary format via:		
     a2b < hdrfile n1=nfields > binary_file				
 Then set the header fields via:					
     sushw < sudata infile=binary_file key=key1,key2,... > sudata.edited

 Caveat: 								
 If the (number of traces)*(number of key words) exceeds the number of	
 values in the infile then the user may still set a single header field
 on the remaining traces via the parameters key=keyword a,b,c,d,j.	

 Example:								
    sushw < sudata=key1,key2 ... infile=binary_file [Optional Parameters]

 Credits:
	SEP: Einar Kajartansson
	CWP: Jack K. Cohen
      CWP: John Stockwell, added multiple fields and infile= options

 Caveat:
	All constants are cast to doubles.

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sushw = {
    _a      => '',
    _b      => '',
    _c      => '',
    _d      => '',
    _infile => '',
    _j      => '',
    _key    => '',
    _Step   => '',
    _note   => '',
};

# define a value
my $newline = '
';

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sushw->{_Step} = 'sushw' . $sushw->{_Step};
    return ( $sushw->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sushw->{_note} = 'sushw' . $sushw->{_note};
    return ( $sushw->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sushw->{_a}      = '';
    $sushw->{_b}      = '';
    $sushw->{_c}      = '';
    $sushw->{_d}      = '';
    $sushw->{_infile} = '';
    $sushw->{_j}      = '';
    $sushw->{_key}    = '';
    $sushw->{_Step}   = '';
    $sushw->{_note}   = '';
}

=head2 sub a 

 subs a,first_value
 handles first value of the trace

=cut

sub a {

    my ( $self, $a ) = @_;
    if ( $a ne $empty_string ) {

        $sushw->{_a}    = $a;
        $sushw->{_note} = $sushw->{_note} . ' a=' . $sushw->{_a};
        $sushw->{_Step} = $sushw->{_Step} . ' a=' . $sushw->{_a};

    }
    else {
        print("sushw, a, missing a,\n");
    }
}

=head2 sub b 

 Increment between traces within a single
 gather; this increment is assigned when moving on to
 a subsequent gather.

=cut

sub b {

    my ( $self, $b ) = @_;
    if ( $b ne $empty_string ) {

        $sushw->{_b}    = $b;
        $sushw->{_note} = $sushw->{_note} . ' b=' . $sushw->{_b};
        $sushw->{_Step} = $sushw->{_Step} . ' b=' . $sushw->{_b};

    }
    else {
        print("sushw, b, missing b,\n");
    }
}

=head2 sub c 

 Increment assigned to all traces within a single
 gather; this increment is assigned when moving on to
 a subsequent gather.

=cut

sub c {

    my ( $self, $c ) = @_;
    if ( $c ne $empty_string ) {

        $sushw->{_c}    = $c;
        $sushw->{_note} = $sushw->{_note} . ' c=' . $sushw->{_c};
        $sushw->{_Step} = $sushw->{_Step} . ' c=' . $sushw->{_c};

    }
    else {
        print("sushw, c, missing c,\n");
    }
}

=head2 sub d 

 value to add to words 

=cut

sub d {

    my ( $self, $d ) = @_;
    if ( $d ne $empty_string ) {

        $sushw->{_d}    = $d;
        $sushw->{_note} = $sushw->{_note} . ' d=' . $sushw->{_d};
        $sushw->{_Step} = $sushw->{_Step} . ' d=' . $sushw->{_d};

    }
    else {
        print("sushw, d, missing d,\n");
    }
}

#=head4
#
# sub first_val
# handles first value of the trace
#
#=cut
#
#sub first_val{
#    my (@first_val)         = @_;
#    $sushw->{_first_val}  = @first_val if @first_val;
#
#    # get possible array length
#    my $first_val_num     = scalar($sushw->{_first_val})-1;
#
#    # first case
#    $sushw->{_note}   = $sushw->{_note}.' a='.$first_val[1];
#    $sushw->{_Step}   = $sushw->{_Step}.' a='.$first_val[1];
#
#    # if there is more than a single key name word
#    for (my $i=2; $i<=$first_val_num; $i++) {
#       $sushw->{_note}     = $sushw->{_note}.','.$first_val[$i];
#       $sushw->{_Step}     = $sushw->{_Step}.','.$first_val[$i];
#  }
#}

=head2 sub first_val 

 subs a,first_value
 handles first value of the trace

=cut

sub first_val {

    my ( $self, $a ) = @_;
    if ( $a ne $empty_string ) {

        $sushw->{_a}    = $a;
        $sushw->{_note} = $sushw->{_note} . ' a=' . $sushw->{_a};
        $sushw->{_Step} = $sushw->{_Step} . ' a=' . $sushw->{_a};

    }
    else {
        print("sushw, first_val, missing first_value,\n");
    }
}

=head2 sub first_value 

 subs a,first_value
 handles first value of the trace

=cut

sub first_value {

    my ( $self, $a ) = @_;
    if ( $a ne $empty_string ) {

        $sushw->{_a}    = $a;
        $sushw->{_note} = $sushw->{_note} . ' a=' . $sushw->{_a};
        $sushw->{_Step} = $sushw->{_Step} . ' a=' . $sushw->{_a};

    }
    else {
        print("sushw, first_value, missing first_value,\n");
    }
}

=head2 sub gather_size 

 how many traces are in  gather
 or group of traces of interest 

=cut

sub gather_size {

    my ( $self, $j ) = @_;
    if ( $j ne $empty_string ) {

        $sushw->{_j}    = $j;
        $sushw->{_note} = $sushw->{_note} . ' j=' . $sushw->{_j};
        $sushw->{_Step} = $sushw->{_Step} . ' j=' . $sushw->{_j};

    }
    else {
        print("sushw, gather_size, missing gather_size,\n");
    }
}

=head2 sub header_bias 

 value to add to words 

=cut

sub header_bias {

    my ( $self, $d ) = @_;
    if ( $d ne $empty_string ) {

        $sushw->{_d}    = $d;
        $sushw->{_note} = $sushw->{_note} . ' d=' . $sushw->{_d};
        $sushw->{_Step} = $sushw->{_Step} . ' d=' . $sushw->{_d};

    }
    else {
        print("sushw, header_bias, missing header_bias,\n");
    }
}

=head2 sub headerwords 

 subs name, key  select the names to change

=cut

sub headerwords {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $sushw->{_key}  = $key;
        $sushw->{_note} = $sushw->{_note} . ' key=' . $sushw->{_key};
        $sushw->{_Step} = $sushw->{_Step} . ' key=' . $sushw->{_key};

    }
    else {
        print("sushw, headerwords, missing headerwords,\n");
    }
}

=head2 sub infile 


=cut

sub infile {

    my ( $self, $infile ) = @_;
    if ( $infile ne $empty_string ) {

        $sushw->{_infile} = $infile;
        $sushw->{_note}   = $sushw->{_note} . ' infile=' . $sushw->{_infile};
        $sushw->{_Step}   = $sushw->{_Step} . ' infile=' . $sushw->{_infile};

    }
    else {
        print("sushw, infile, missing infile,\n");
    }
}

=head2 sub inter_gather_inc 

 Increment assigned to all traces within a single
 gather; this increment is assigned when moving on to
 a subsequent gather.

=cut

sub inter_gather_inc {

    my ( $self, $c ) = @_;
    if ( $c ne $empty_string ) {

        $sushw->{_c}    = $c;
        $sushw->{_note} = $sushw->{_note} . ' c=' . $sushw->{_c};
        $sushw->{_Step} = $sushw->{_Step} . ' c=' . $sushw->{_c};

    }
    else {
        print("sushw, inter_gather_inc, missing inter_gather_inc,\n");
    }
}

=head2 sub intra_gather_inc 

 Increment between traces within a single
 gather; this increment is assigned when moving on to
 a subsequent gather.

=cut

sub intra_gather_inc {

    my ( $self, $b ) = @_;
    if ( $b ne $empty_string ) {

        $sushw->{_b}    = $b;
        $sushw->{_note} = $sushw->{_note} . ' b=' . $sushw->{_b};
        $sushw->{_Step} = $sushw->{_Step} . ' b=' . $sushw->{_b};

    }
    else {
        print("sushw, intra_gather_inc, missing intra_gather_inc,\n");
    }
}

=head2 sub j 

 how many traces are in  gather
 or group of traces of interest 

=cut

sub j {

    my ( $self, $j ) = @_;
    if ( $j ne $empty_string ) {

        $sushw->{_j}    = $j;
        $sushw->{_note} = $sushw->{_note} . ' j=' . $sushw->{_j};
        $sushw->{_Step} = $sushw->{_Step} . ' j=' . $sushw->{_j};

    }
    else {
        print("sushw, j, missing j,\n");
    }
}

=head2 sub key 

 subs name, key  select the names to change 

=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $sushw->{_key}  = $key;
        $sushw->{_note} = $sushw->{_note} . ' key=' . $sushw->{_key};
        $sushw->{_Step} = $sushw->{_Step} . ' key=' . $sushw->{_key};

    }
    else {
        print("sushw, key, missing key,\n");
    }
}

#=head2 subroutine name
#
# select the names to change
#
#=cut
#
#sub name {
#   my (@names)         = @_;
#   $sushw->{_names}   = @names if @names;
#
#   #get possible array length
#   my $hdr_num       = scalar($sushw->{_names})-1;
#
#   # first case
#   $sushw->{_note}   = $sushw->{_note}.' key='.$names[1];
#   $sushw->{_Step}   = $sushw->{_Step}.' key='.$names[1];
#
#   # if there is more than a single key name word
#   for (my $i=2; $i<=$hdr_num; $i++) {
#       $sushw->{_note}     = $sushw->{_note}.','.$names[$i];
#       $sushw->{_Step}     = $sushw->{_Step}.','.$names[$i];
#   }
#}

=head2 sub name 

 subs name, key select the names to change 

=cut

sub name {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $sushw->{_key}  = $key;
        $sushw->{_note} = $sushw->{_note} . ' key=' . $sushw->{_key};
        $sushw->{_Step} = $sushw->{_Step} . ' key=' . $sushw->{_key};

    }
    else {
        print("sushw, name, missing name,\n");
    }
}

=head4 sub sample_interval_s

 In clase that you only want to 
 change a single value
 in all the traces


=cut

=head2 sub sudata 


=cut

sub sample_interval_s {
    my ( $test, $sample_interval_s ) = @_;

    if ( $sample_interval_s ne $empty_string ) {

        #print("num sample interval in s is $sample_interval_s\n\n");
        #print("test is $test\n\n");
        # convert to microseconds
        $sushw->{_sample_interval_s} = ( $sample_interval_s * 1000000 )
          if defined($sample_interval_s);

        #print("num sample interval in us is $sushw->{_sample_interval_s}\n\n");
        $sushw->{_Step} =
          $sushw->{_Step} . ' key=dt a=' . $sushw->{_sample_interval_s};
        $sushw->{_note} =
          $sushw->{_note} . ' key=dt a=' . $sushw->{_sample_interval_s};

    }
    else {
        print("sushw, sample_interval_s, missing sample_interval_s\n");
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
