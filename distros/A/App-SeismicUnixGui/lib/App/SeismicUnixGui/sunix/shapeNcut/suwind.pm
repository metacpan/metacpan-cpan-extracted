package App::SeismicUnixGui::sunix::shapeNcut::suwind;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUWIND - window traces by key word					
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:  Nov 1 2012  
 DESCRIPTION: suwind a lists of header words
 or an single value
 
 Version:  0.0.3

=head3 SEISMIC UNIX NOTES

 SUWIND - window traces by key word					

  suwind <stdin >stdout [options]					

 Required Parameters:							
  none 								

 Optional Parameters:							
 verbose=0		=1 for verbose					
 key=tracl		Key header word to window on (see segy.h)	
 min=LONG_MIN		min value of key header word to pass		
 max=LONG_MAX		max value of key header word to pass		

 abs=0			=1 to take absolute value of key header word	
 j=1			Pass every j-th trace ...			
 s=0			... based at s  (if ((key - s)%j) == 0)		
 skip=0		skip the initial N traces                       
 count=ULONG_MAX	... up to count traces				
 reject=none		Skip traces with specified key values		
 accept=none		Pass traces with specified key values(see notes)
			processing, but do no window the data		
 ordered=0		=1 if traces sorted in increasing keyword value 
			=-1  if traces are sorted in a decreasing order 

 Options for vertical windowing (time gating):				
 dt=tr.dt (from header) time sampling interval (sec)	(seismic data)	
 			 =tr.d1  (nonseismic)				
 f1=tr.delrt (from header) first sample		(seismic data)	
 			 =tr.f1  (nonseismic)				

 tmin=0.0		min time to pass				
 tmax=(from header)	max time to pass				
 itmin=0		min time sample to pass				
 itmax=(from header)   max time sample to pass				
 nt=itmax-itmin+1	number of time samples to pass			

 Notes:								
 On large data sets, the count parameter should be set if		
 possible.  Otherwise, every trace in the data set will be		
 examined.  However, the count parameter overrides the accept		
 parameter, so you can't specify count if you want true		
 unconditional acceptance.						

 The skip= option allows the user to skip over traces, which helps	
 for selecting traces far from the beginning of the dataset.		
 Caveat: skip only works with disk input.                        	

 The ordered= option will speed up the process if the data are   	
 sorted in according to the key.                                 	

 The accept option is a bit strange--it does NOT mean accept ONLY	
 the traces on the accept list!  It means accept these traces,   	
 even if they would otherwise be rejected (except as noted in the	
 previous paragraph).  To implement accept-only, you can use the 	
 max=0 option (rejecting everything).  For example, to accept    	
 only the tracl values 4, 5 and 6:					
	... | suwind max=0 accept=4,5,6 | ...		   		

 Another example is the case of suppressing nonseismic traces in 	
 a seismic data set. By the SEGY standard header field trace id, 	
 trid=1 designates traces as being seismic traces. Other traces, 	
 such as calibration traces may be designated by another value.  	

 Example:  trid=1 seismic and trid=0 is nonseismic. To reject    	
       nonseismic traces						
       ... | suwind key=trid reject=0 | ...				

 On most 32 bit machines, LONG_MIN, LONG_MAX and ULONG_MAX are   	
 about -2E9,+2E9 and 4E9, they are defined in limits.h.		

 Selecting times beyond the maximum in the data induces		
 zero padding (up to SU_NFLTS).					

 The time gating here is to the nearest neighboring sample or    	
 time value. Gating to the exact temporal value requires	 	
 resampling if the selected times fall between samples on the    	
 trace. Use suresamp to perform the time gating in this case.    	

 It doesn't really make sense to specify both itmin and tmin,		
 but specifying itmin takes precedence over specifying tmin.		
 Similarly, itmax takes precedence over tmax and tmax over nt.		
 If dt in header is not set, then dt is mandatory			


 Credits:
	SEP: Einar Kjartansson
	CWP: Shuki Ronen, Jack Cohen, Chris Liner
	Warnemuende: Toralf Foerster
	CENPET: Werner M. Heigl (modified to include well log data)

 Trace header fields accessed: ns, dt, delrt, keyword
 Trace header fields modified: ns, delrt, ntr
 
 =head2 USE

=head3 NOTES

Example:
If skip is used, s is ignored e.g. s=2 skip=1 key=tracl j=2

Example:

accept=4,9,11 max=0    (max=0 is needed)

Example: where in data, tracl=1,2,3, etc.

j=3 key=tracl,s=0, tracl's are 3, 6, 9 etc.,
j=2 key=tracl s=0, tracl's are 2, 4, 6 etc.
j=2 key=tracl s=1, tracl's are 1, 3, 5,7
j=2 key=tracl s=2, tracl's are 2, 4, 6,8 etc.,

New list option:

Include a file name conatining a single-column list of numbers which
represent trace header values. Make sure to set the header as well.


=head2 CHANGES and their DATES

V 0.0.3 May 2023
Include a file name conatining a single-column list of numbers which
represent trace header values. Make sure to set the header as well.

=cut

use Moose;
our $VERSION = '0.0.3';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::control';

my $get              = App::SeismicUnixGui::misc::L_SU_global_constants->new();
my $var              = $get->var();
my $manage_files_by2 = manage_files_by2->new();
my $control          = control->new();
my $empty_string     = $var->{_empty_string};

my $suwind = {
    _abs     => '',
    _accept  => '',
    _accept_only_list_name => '',
    _count   => '',
    _dt      => '',
    _f1      => '',
    _itmax   => '',
    _itmin   => '',
    _j       => '',
    _key     => '',
    _max     => '',
    _min     => '',
    _nt      => '',
    _ordered => '',
    _reject  => '',
    _s       => '',
    _skip    => '',
    _tmax    => '',
    _tmin    => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {
    my ( $self, $Step ) = @_;

    # print ("1. suwind, Step, $suwind->{_Step}\n");
    $suwind->{_Step} = 'suwind ' . $suwind->{_Step};

    # print ("2. suwind, Step, $suwind->{_Step}\n");
    return ( $suwind->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    my ( $self, $note ) = @_;
    $suwind->{_note} = 'suwind' . $suwind->{_note};
    return ( $suwind->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suwind->{_abs}     = '';
    $suwind->{_accept}  = '';
    $suwind->{_accept_only_list_name} = '',
    $suwind->{_count}   = '';
    $suwind->{_dt}      = '';
    $suwind->{_f1}      = '';
    $suwind->{_itmax}   = '';
    $suwind->{_itmin}   = '';
    $suwind->{_j}       = '';
    $suwind->{_key}     = '';
    $suwind->{_max}     = '';
    $suwind->{_min}     = '';
    $suwind->{_nt}      = '';
    $suwind->{_ordered} = '';
    $suwind->{_reject}  = '';
    $suwind->{_s}       = '';
    $suwind->{_skip}    = '';
    $suwind->{_tmax}    = '';
    $suwind->{_tmin}    = '';
    $suwind->{_trid}    = '';
    $suwind->{_verbose} = '';
    $suwind->{_Step}    = '';
    $suwind->{_note}    = '';
}

=head2 sub abs 


=cut

sub abs {

    my ( $self, $abs ) = @_;
    if ( $abs ne $empty_string ) {

        $suwind->{_abs}  = $abs;
        $suwind->{_note} = $suwind->{_note} . ' abs=' . $suwind->{_abs};
        $suwind->{_Step} = $suwind->{_Step} . ' abs=' . $suwind->{_abs};

    }
    else {
        print("suwind, abs, missing abs,\n");
    }
}

=head2 sub accept 


=cut

sub accept {

    my ( $self, $accept ) = @_;
    if ( $accept ne $empty_string ) {

        $suwind->{_accept} = $accept;
        $suwind->{_note}   = $suwind->{_note} . ' accept=' . $suwind->{_accept};
        $suwind->{_Step}   = $suwind->{_Step} . ' accept=' . $suwind->{_accept};

    }
    else {
        print("suwind, accept, missing accept,\n");
    }
}

#=pod sub accept_only_list 
#
# sub accept_only_list: when selecting multiple traces
#     all at once.
#     Should be used with list,setheaderword.
#     
#=cut
#
#sub accept_only_list {
#	
#    my ( $self, $ref_list ) = @_;
#    my @list = @$ref_list if defined($ref_list);
#
#    if ( $ref_list ne $empty_string ) {
#
#      # print("1. suwind, accept_only_list,suwind->{_Step},$suwind->{_Step}\n");
#      #   perl starts lists at 0
#        my $length_list = scalar(@list);
#        my $end         = $length_list;
#        my $start       = 0;
#
#        # print("suwind, accept_only_list, @list\n");
#        # print("suwind, accept_only_list,list[0], $list[0]\n");
#        # print("suwind, accept_only_list,length_list, $length_list\n");
#
#        # init
#        $suwind->{_Step} =
#          $suwind->{_Step} . ' max=0 accept=' . $list[$start];
#
#        # rest
#        for ( my $i = $start + 1 ; $i < $end ; $i++ ) {
#
#            $suwind->{_Step} = $suwind->{_Step} . ',' . $list[$i];
#            ###  print("suwind, accept_only_list,i=$i \n");
#
#        }
#
#    }
#    else {
#        print("suwind, accept_only_list, missing ref_list,\n");
#    }
#
#    # print("2. suwind, accept_only_list,suwind->{_Step},$suwind->{_Step} \n");
#
#}

=pod sub accept_only_list_name

 sub accept_only_list: when selecting multiple traces
     all at once.
     Should be used with list, setheaderword.
     
=cut

sub accept_only_list_name {

    my ( $self, $list_name ) = @_;

    if ( length $list_name) {
    	
    	$control->set_back_slashBgone($list_name);
		$list_name = $control->get_back_slashBgone();
    	
    	my ($list_ref, $num_rows) = $manage_files_by2->read_1col($list_name);	
    	my @list = @$list_ref;

        my $start       = 0;

        # print("suwind, accept_only_list_name, list[0], $list[0]\n");
        # print("suwind, accept_only_list_name, num_rows, $num_rows\n");

        # first value of list
        $suwind->{_Step} =
          $suwind->{_Step} . ' max=0 accept=' . $list[$start];

        # for the rest
        for ( my $i = $start + 1 ; $i < $num_rows ; $i++ ) {

            $suwind->{_Step} = $suwind->{_Step} . ',' . $list[$i];
            print("suwind, accept_only_list_name,i=$i \n");

        }

    }
    else {
        print("suwind, accept_only_list_name, missing ref_list,\n");
    }

    # print("2. suwind, accept_only_list,suwind->{_Step},$suwind->{_Step} \n");

}

=head2 sub accept_only_tracl

 when selecting multiple traces
 all at once
 use a list 

=cut

sub accept_only_tracl {
    my ( $self, $ref_list ) = @_;
    my @list = @$ref_list if defined($ref_list);

    if ( $ref_list ne $empty_string ) {

        #   perl starts lists at 0
        my $length_list = scalar(@list);
        my $end         = $length_list;
        my $start       = 0;

        # init
        $suwind->{_Step} =
          $suwind->{_Step} . ' max=0 accept=' . $list[$start];

        # rest
        for ( my $i = $start + 1 ; $i < $end ; $i++ ) {
            $suwind->{_Step} = $suwind->{_Step} . ',' . $list[$i];
        }

    }
    else {
        print("suwind, accept_only_tracl, missing ref_list,\n");
    }

}

=head2 sub count 


=cut

sub count {

    my ( $self, $count ) = @_;
    if ( $count ne $empty_string ) {

        $suwind->{_count} = $count;
        $suwind->{_note}  = $suwind->{_note} . ' count=' . $suwind->{_count};
        $suwind->{_Step}  = $suwind->{_Step} . ' count=' . $suwind->{_count};

    }
    else {
        print("suwind, count, missing count,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $suwind->{_dt}   = $dt;
        $suwind->{_note} = $suwind->{_note} . ' dt=' . $suwind->{_dt};
        $suwind->{_Step} = $suwind->{_Step} . ' dt=' . $suwind->{_dt};

    }
    else {
        print("suwind, dt, missing dt,\n");
    }
}

=head2 sub f1 


=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suwind->{_f1}   = $f1;
        $suwind->{_note} = $suwind->{_note} . ' f1=' . $suwind->{_f1};
        $suwind->{_Step} = $suwind->{_Step} . ' f1=' . $suwind->{_f1};

    }
    else {
        print("suwind, f1, missing f1,\n");
    }
}

sub file {
    my ( $self, $f1 ) = @_;

    if ( $f1 ne $empty_string ) {

        $suwind->{_f1}   = $f1;
        $suwind->{_note} = $suwind->{_note} . ' f1=' . $suwind->{_f1};
        $suwind->{_Step} = $suwind->{_Step} . ' f1=' . $suwind->{_f1};

        # deprecated	-legacy
        # $suwind->{_file} = ' <'.$$f1 if defined($f1);

    }
    else {
        print("suwind, f1, missing f1,\n");
    }

}

my $newline;

sub initiate {
    my ($self) = @_;
    $newline = '
';
}

=head2 sub itmax 


=cut

sub itmax {

    my ( $self, $itmax ) = @_;
    if ( $itmax ne $empty_string ) {

        $suwind->{_itmax} = $itmax;
        $suwind->{_note}  = $suwind->{_note} . ' itmax=' . $suwind->{_itmax};
        $suwind->{_Step}  = $suwind->{_Step} . ' itmax=' . $suwind->{_itmax};

    }
    else {
        print("suwind, itmax, missing itmax,\n");
    }
}

=head2 sub itmin 


=cut

sub itmin {

    my ( $self, $itmin ) = @_;
    if ( $itmin >= 0 && $itmin ne $empty_string ) {

        $suwind->{_itmin} = $itmin;
        $suwind->{_note}  = $suwind->{_note} . ' itmin=' . $suwind->{_itmin};
        $suwind->{_Step}  = $suwind->{_Step} . ' itmin=' . $suwind->{_itmin};

    }
    else {
        print("suwind, itmin, missing itmin,\n");
    }
}

=head2 sub j 


=cut

sub j {

    my ( $self, $j ) = @_;
    if ( $j ne $empty_string ) {

        $suwind->{_j}    = $j;
        $suwind->{_note} = $suwind->{_note} . ' j=' . $suwind->{_j};
        $suwind->{_Step} = $suwind->{_Step} . ' j=' . $suwind->{_j};

    }
    else {
        print("suwind, j, missing j,\n");
    }
}

=head2 sub key 

set which header word to use as the x-coordinate for plotting


=cut

sub key {

    my ( $self, $key ) = @_;

    if ( $key ne $empty_string ) {

        if ( $key eq 'time' ) {

            $suwind->{_key} = 'dt';

        }
        else {

            $suwind->{_key} = $key;
        }

        $suwind->{_note} = $suwind->{_note} . ' key=' . $suwind->{_key};
        $suwind->{_Step} = $suwind->{_Step} . ' key=' . $suwind->{_key};

    }
    else {
        print("suwind, key, missing key,\n");
    }
}

=head2 sub list

 input a list of trace numbers as a referenced array 

Example 1:
 $value[0]  = 2;
 suwind->list(\@value);
 suwind->setheaderword('tracf');
 $suwind[1] = suwind->Step();

=cut

sub list {

    my ( $self, $ref_list ) = @_;

    if ( $ref_list ne $empty_string ) {

        my @list = @$ref_list if defined($ref_list);

        #   perl starts lists at 0
        my $length_list = scalar(@list);
        my $end         = $length_list;
        my $start       = 0;

        for ( my $i = $start ; $i < $end ; $i++ ) {
            $suwind->{_Step} =
                $suwind->{_Step} . ' min='
              . $list[$i] . ' max='
              . $list[$i] . ' \\'
              . $newline;
        }

    }
    else {

        print("suwind, lsit, missing list\n");

    }

}

=head2 sub max 


=cut

sub max {

    my ( $self, $max ) = @_;
    if ( $max ne $empty_string ) {

        $suwind->{_max}  = $max;
        $suwind->{_note} = $suwind->{_note} . ' max=' . $suwind->{_max};
        $suwind->{_Step} = $suwind->{_Step} . ' max=' . $suwind->{_max};

    }
    else {
        print("suwind, max, missing max,\n");
    }
}

=head2 sub min 


=cut

sub min {

    my ( $self, $min ) = @_;
    if ( $min ne $empty_string ) {

        $suwind->{_min}  = $min;
        $suwind->{_note} = $suwind->{_note} . ' min=' . $suwind->{_min};
        $suwind->{_Step} = $suwind->{_Step} . ' min=' . $suwind->{_min};

    }
    else {
        print("suwind, min, missing min,\n");
    }
}

=head2 sub nt 


=cut

sub nt {

    my ( $self, $nt ) = @_;
    if ( $nt ne $empty_string ) {

        $suwind->{_nt}   = $nt;
        $suwind->{_note} = $suwind->{_note} . ' nt=' . $suwind->{_nt};
        $suwind->{_Step} = $suwind->{_Step} . ' nt=' . $suwind->{_nt};

    }
    else {
        print("suwind, nt, missing nt,\n");
    }
}

=head2 sub ordered 


=cut

sub ordered {

    my ( $self, $ordered ) = @_;
    if ( $ordered ne $empty_string ) {

        $suwind->{_ordered} = $ordered;
        $suwind->{_note} =
          $suwind->{_note} . ' ordered=' . $suwind->{_ordered};
        $suwind->{_Step} =
          $suwind->{_Step} . ' ordered=' . $suwind->{_ordered};

    }
    else {
        print("suwind, ordered, missing ordered,\n");
    }
}

=head2 sub reject 


=cut

sub reject {

    my ( $self, $reject ) = @_;
    if ( $reject ne $empty_string ) {

        $suwind->{_reject} = $reject;
        $suwind->{_note}   = $suwind->{_note} . ' reject=' . $suwind->{_reject};
        $suwind->{_Step}   = $suwind->{_Step} . ' reject=' . $suwind->{_reject};

    }
    else {
        print("suwind, reject, missing reject,\n");
    }
}

=head2 sub setheaderword 

set which header word to use as the x-coordinate for plotting


=cut

sub setheaderword {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        if ( $key eq 'time' ) {

            $suwind->{_key} = 'dt';

        }
        else {

            $suwind->{_key} = $key;

            #
        }

       # print(" 1. suwind,setheaderword,suwind->{_Step}:$suwind->{_Step}\n\n");
        $suwind->{_note} = $suwind->{_note} . ' key=' . $suwind->{_key};
        $suwind->{_Step} = $suwind->{_Step} . ' key=' . $suwind->{_key};

       # print(" 2. suwind,setheaderword,suwind->{_Step}:$suwind->{_Step}\n\n");

    }
    else {
        print("suwind, setheaderword, missing setheaderword\n");
    }
}

=head2 sub s 


=cut

sub s {

    my ( $self, $s ) = @_;
    if ( $s ne $empty_string ) {

        $suwind->{_s}    = $s;
        $suwind->{_note} = $suwind->{_note} . ' s=' . $suwind->{_s};
        $suwind->{_Step} = $suwind->{_Step} . ' s=' . $suwind->{_s};

    }
    else {
        print("suwind, s, missing s,\n");
    }
}

=head2 sub skip 


=cut

sub skip {

    my ( $self, $skip ) = @_;
    if ( $skip ne $empty_string ) {

        $suwind->{_skip} = $skip;
        $suwind->{_note} = $suwind->{_note} . ' skip=' . $suwind->{_skip};
        $suwind->{_Step} = $suwind->{_Step} . ' skip=' . $suwind->{_skip};

    }
    else {
        print("suwind, skip, missing skip,\n");
    }
}

=head2 sub tmax 


=cut

sub tmax {

    my ( $self, $tmax ) = @_;
    if ( $tmax ne $empty_string ) {

        $suwind->{_tmax} = $tmax;
        $suwind->{_note} = $suwind->{_note} . ' tmax=' . $suwind->{_tmax};
        $suwind->{_Step} = $suwind->{_Step} . ' tmax=' . $suwind->{_tmax};

    }
    else {
        print("suwind, tmax, missing tmax,\n");
    }
}

=head2 sub tmin 

$tmin >=0 && 

=cut

sub tmin {

    my ( $self, $tmin ) = @_;
    if ( $tmin ne $empty_string ) {

        $suwind->{_tmin} = $tmin;
        $suwind->{_note} = $suwind->{_note} . ' tmin=' . $suwind->{_tmin};
        $suwind->{_Step} = $suwind->{_Step} . ' tmin=' . $suwind->{_tmin};

    }
    else {
        print("suwind, tmin, missing tmin,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $suwind->{_verbose} = $verbose;
        $suwind->{_note} =
          $suwind->{_note} . ' verbose=' . $suwind->{_verbose};
        $suwind->{_Step} =
          $suwind->{_Step} . ' verbose=' . $suwind->{_verbose};

    }
    else {
        print("suwind, verbose, missing verbose,\n");
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
