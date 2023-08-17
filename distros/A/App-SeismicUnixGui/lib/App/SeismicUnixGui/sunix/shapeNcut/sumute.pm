package App::SeismicUnixGui::sunix::shapeNcut::sumute;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUMUTE - MUTE above (or below) a user-defined polygonal curve with	", 

	   the distance along the curve specified by key header word 	



 sumute <stdin >stdout xmute= tmute= [optional parameters]		



 Required parameters:							

 xmute=		array of position values as specified by	

 			the `key' parameter				

 tmute=		array of corresponding time values (sec)	

 			in case of air wave muting, correspond to 	

 			air blast duration				

  ... or input via files:						

 nmute=		number of x,t values defining mute		

 xfile=		file containing position values as specified by	

 			the `key' parameter				

 tfile=		file containing corresponding time values (sec)	

  ... or via header:							

 hmute=		key header word specifying mute time		



 Optional parameters:							

 key=offset		Key header word specifying trace offset 	

 				=tracl  use trace number instead	

 ntaper=0		number of points to taper before hard		

			mute (sine squared taper)			

 mode=0	   mute ABOVE the polygonal curve			

		=1 to zero BELOW the polygonal curve			

		=2 to mute below AND above a straight line. In this case

		 	xmute,tmute describe the total time length of   

			the muted zone as a function of xmute the slope 

			of the line is given by the velocity linvel=	

	 	=3 to mute below AND above a constant velocity hyperbola

			as in mode=2 xmute,tmute describe the total time

			length of the mute zone as a function of xmute,  

			the velocity is given by the value of linvel=	

 		=4 to mute below AND above a user defined polygonal line

			given by xmute, tmute pairs. The widths in time ", 

			of the muted zone are given by the twindow vector

 linvel=330   		constant velocity for linear or hyperbolic mute	

 tm0=0   		time shift of linear or hyperbolic mute at	

			 \'key\'=0					

 twindow=	vector of mute zone widths in time, operative only in mode=4

  ... or input via file:						

 twfile= 								



 Notes: 								

 The tmute interpolant is extrapolated to the left by the smallest time

 sample on the trace and to the right by the last value given in the	

 tmute array.								



 The files tfile and xfile are files of binary (C-style) floats.	



 In the context of this program "above" means earlier time and	

 "below" means later time (above and below as seen on a seismic section.



 The mode=2 option is intended for removing air waves. The mute is	

 is over a narrow window above and below the line specified by the	

 the line specified by the velocity "linvel". Here the values of     

 tmute, xmute or tfile and xfile define the total time width of the mute.



 If data are spatial, such as the (z-x) output of a migration, then    

 depth values are used in place of times in tmute and tfile. The value 

 of the depth sampling interval is given by the d1 header field	

 You must use the option key=tracl in sumute in this case.		



 Caveat: if data are seismic time sections, then tr.dt must be set. If 

 data are seismic depth sections, then tr.trid must be set to the value

 of TRID_DEPTH and the tr.d1 header field must be set.			

 To find the value of TRID_DEPTH:  					

 type: 								

     sukeyword trid							

	and look for the entry for "Depth-Range (z-x) traces





 Credits:



	SEP: Shuki Ronen

	CWP: Jack K. Cohen, Dave Hale, John Stockwell

	DELPHI: Alexander Koek added airwave mute.

      CWP: John Stockwell added modes 3 and 4

	USBG: Florian Bleibinhaus added hmute + some range checks on mute times

 Trace header fields accessed: ns, dt, delrt, key=keyword, trid, d1

 Trace header fields modified: muts or mute



=head2 User's notes (Juan Lorenzo)

V 0.0.2

Normally, sumute can only apply one set muting coordinates to one gather
at a time.
In this manner you would use a 
"par_file" e.g.,

tmute=0.128544,0.245747
xmute=73.2464,95.6714

In this particular case, the mute pick coordinates
in the "x" direction are tracr values.

sumute sp_fldr4.su par=par_file key=tracr mode=0 | 
sugain agc=1 wagc=0.1 | suxwigb clip=1.5 &


We have added some options to allow the user to mute a file
that contains many gathers at one time. You will need to supply 
a "multi-gather", mute-type parameter file.

That is, sumute.pm can use a concatenated 
collection of the contents of these individual parfiles.
The name of this file is called the "multi-par-file.

Generate the "parfiles" (x,t values in SUnix "par" format) 
using the iTopMute Tool. iTopMute saves the picked values 
into individual "parfiles" named according to
their corresponding gather.

We now have added the following options
to sumute:

gather_type           = ep (shotpoint),cdp (cdp gathers),fldr(field data gathers)
multi_gather_par_file = a concatenated file of the individual parfiles
multi_gather_su_file  = the su file which was muted interactively to create each of the parfiles
using the Tool: iTop_Mute 

A multi-parameter-file looks as follows:
cdp=1,2
tmute=0.141777,0.251418
xmute=73,96
tmute=0.131777,0.241418
xmute=85,96

To create a multi-gather parameter file 
this composite "parfile"" can be concatenated using the Tool: Sucat

Internally, sumute uses "susplit" to break a large multi-gather file into individual
shotpoint gathers (ep), or cdp gathers or fldr (gathers) according to Segy
key header words. 

An example:

Data consists of a single CDP gather, digitized in iTopMute as a function
of tracr (x-co-ordinate)

The parameter values in sumute are:
gather_type=cdp
header-word=tracr
multi_gather_par_file=list
multi_gather_su_file=sp_fldr4

the file "list" is as follows:
cdp=1
tmute=0.141777,0.251418
xmute=73,96


=cut

=head2 CHANGES and their DATES

Nov. 2022, V 0.0.2
June 2023, split files are read from DATA_SEISMIC_SU directory

=cut

use Moose;
our $VERSION = '0.0.2';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($go $in $itop_mute_par_ $ibot_mute_par_ $off $on $out $ps $to $suffix_ascii $suffix_bin
  $suffix_ps $suffix_segy $suffix_su $tmute $xmute);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::susplit';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::message';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();
my $PL_SEISMIC       = $Project->PL_SEISMIC();
my $PS_SEISMIC       = $Project->PS_SEISMIC();
my $log              = message->new();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

my ($imute_par_);
my ( @tmute, @xmute, @output, @Steps, @gather_number, @par_file );

=head2 Encapsulated
hash of private variables

=cut

my $sumute = {
	_par_gather_number_aref => '',
	_gather_type            => '',
	_hmute                  => '',
	_key                    => '',
	_linvel                 => '',
	_multi_gather_par_file  => '',
	_multi_gather_su_file   => '',
	_mode                   => '',
	_nmute                  => '',
	_ntaper                 => '',
	_par                    => '',
	_par_directory          => '',
	_susplit_stem           => 'split4sumute',
	_tfile                  => '',
	_tm0                    => '',
	_tmute                  => '',
	_twindow                => '',
	_xfile                  => '',
	_xmute                  => '',
	_Step                   => '',
	_note                   => '',

};

=head2 sub _get_par_sets

=cut

sub _get_par_sets {

	my (@self) = @_;

	if (    $sumute->{_multi_gather_par_file} ne $empty_string
		and $sumute->{_gather_type} ne $empty_string )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 private definitions

=cut

		my ( @time_picks_aref2, @x_picks_aref2 );
		my @par_gather;
		my $multi_par_file_w_path;
		my $row = 0;
		my $inbound;
		my @time_picks_aref;
		my $par_gather_number;
		my $par_gather_count;

		$multi_par_file_w_path = $sumute->{_multi_gather_par_file};
		$inbound               = $multi_par_file_w_path;

		#		 print("sumute,_get_par_sets, inbound=$inbound\n");

=head2 read i/p file

=cut

		$control->set_back_slashBgone($inbound);
		$inbound = $control->get_back_slashBgone();

		# open multi-gather_par_file
		# which contains a list of the
		# individual par files
		my $ref_file_name = \$inbound;
		my ( $items_aref2, $numberOfItems_aref ) =
		  $files->read_par($ref_file_name);

	# print("multi-gather-parameter file #0 contains: @{@{$items_aref2}[0]}\n");

		# first array member is gather name
		# ,e.g. 'cdp' or 'tmute=', or or just 'gather'
		# and a list of par_gather numbers
		@par_gather = @{ @{$items_aref2}[0] };
		my $gather_type = $par_gather[0];
		# print("sumute, _get_par_sets, gather_type=--$gather_type\n");

=head2 capture errors

=cut

		if ( length $gather_type
			&& $gather_type eq $sumute->{_gather_type} )
		{

# print("sumute, _get_par_sets, gather type=$gather_type and $sumute->{_gather_type}\n");
# print("sumute, _get_par_sets, gather type OK\n");

		}
		else {
			print(
				"sumute, _get_par_sets, gather type missing in 1 or 2 places\n"
			);
			print(
"sumute, _get_par_sets, gather=--$gather_type-- versus --$sumute->{_gather_type}--\n"
			);
		}

=head2 share values with namespace
Use splice to remove the first element (index =0)
which is not a number but a gather type of 
gather name, e.g. cdp or ep or gather

=cut

		my $number_of_par_gathers = ( scalar @par_gather ) - 1;
		my $last_par_index        = ( scalar @par_gather ) - 1;
		my @number_of_picks       = @$numberOfItems_aref;

# print("sumute, _get_par_sets,last_par_index=$last_par_index\n");
# print("sumute, _get_par_sets,number_of_par_gathers=$number_of_par_gathers\n");
# print("sumute, _get_par_sets,old par_gather=@par_gather\n");

		my @new_par_gather = @par_gather[ 1 .. $last_par_index ];
		$sumute->{_par_gather_number_aref} = \@new_par_gather;

	# print("sumute, _get_par_sets,new_par_gather=@new_par_gather\n");
	# print("sumute, _get_par_sets,gather_type=$gather_type\n");
	# print("sumute, _get_par_sets,number_of_gathers=$number_of_par_gathers\n");

=head2 collect tmute and xmute
for each gather 

=cut

		for (
			my $par_gather_count = 1, my $i = 0 ;
			$par_gather_count <= $number_of_par_gathers ;
			$par_gather_count++, $i++
		  )
		{

		 # print("sumute,_get_par_sets, par_gather_count: $par_gather_count\n");
			$par_gather_number = $par_gather[$par_gather_count];

	   # print("sumute,_get_par_sets, par_gather_number: $par_gather_number\n");
			$row = ( $par_gather_count * 2 ) - 1;

			# print("sumute,_get_par_sets, row: $row\n");

			my $last_sample_index =
			  scalar @{ @{$items_aref2}[ ( $row + 1 ) ] } - 1;

			my @new_x_picks =
			  @{ @{$items_aref2}[ ( $row + 1 ) ] }[ 1 .. $last_sample_index ];

# print("sumute,_get_par_sets, new_x_picks:@new_x_picks,last_sample_index:$last_sample_index\n");
			$x_picks_aref2[$i] = \@new_x_picks;

			my @new_time_picks =
			  @{ @{$items_aref2}[ ($row) ] }[ 1 .. $last_sample_index ];

# print("sumute,_get_par_sets, new_time_picks:@new_time_picks,last_sample_index:$last_sample_index\n");
			$time_picks_aref2[$i] = \@new_time_picks;

		}    # no. gathers with parameter sets

		# remove fist item of the time and x picks which,
		# when read from the multu-par_file is actually
		# a string linke tmute or xmute
		# Actual first = 'tmute' and 'xmute'-- not numbers
		# last 2 returns are string arrays

		return ( \@time_picks_aref2, \@x_picks_aref2, $tmute, $xmute );

	}
	else {
		print(
			"sumute,_get_par_sets, missing multi_gather_par_file or
		missing definition of gather type\n"
		);
		return ();
	}

}

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

Keeps track of actions for execution in the system
collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {
	my ($self) = @_;

	my $result;

=head2 CASE 

with multi_gather_su_file

=cut

	if (   $sumute->{_multi_gather_par_file} ne $empty_string
		&& $sumute->{_multi_gather_su_file} ne $empty_string
		&& $sumute->{_par_gather_number_aref} ne $empty_string
		&& $sumute->{_gather_type} ne $empty_string )
	{

=head2 local definitions

=cut			

		my $inbound = $sumute->{_multi_gather_su_file};

=head2 get modules

=cut

=head2 instantiate modules

=cut	

		my $susplit = susplit->new();
		my $run     = flow->new();
		my $control = control->new();

=head2 declare local variables

=cut

		my @susplit;
		my @flow;
		my @split_file_matches;
		my @muted_output;
		my $number_of_split_files = 0;
		my ( @time_picks_aref2, @x_picks_aref2 );
		my ( $time_picks_aref2, $x_picks_aref2, $first_name, $second_name );

=head2 Set up
			
	susplit parameter values

=cut
#		print("sumute, inbound= $inbound\n");
		$susplit->clear();
		$susplit->close( quotemeta(1) );
		$susplit->su_base_file_name($inbound);
		$susplit->key( $sumute->{_gather_type} );
		$susplit->stem( $sumute->{_susplit_stem} );
		$susplit->verbose( quotemeta(1) );
		$susplit->suffix($suffix_su);
		$susplit[0] = $susplit->Step();

=head2 clear past temporary, past

single-gather split from composite su file

=cut

#		my $delete_files = '.split_' . '*';
#		system("rm -rf $delete_files");

=head2 DEFINE

Collect FLOW(s)
Run flow in system independently of sumute 


=cut

		my @items = ( $susplit[0]);
		$flow[0] = $run->modules( \@items );

=head2 RUN FLOW(s)

=cut

		$run->flow( \$flow[0] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		$log->screen( $flow[0] );
		my $time = localtime;
		$log->time();
		$log->file( $flow[0] );

=head2 collect output split file names from the DATA_SU_SEISMIC directory

=cut

		opendir( my $dh, $DATA_SEISMIC_SU, );
		my $search = $sumute->{_susplit_stem};
		my @split_file_names = grep( /$search/, readdir($dh) );
		closedir($dh);

		$number_of_split_files = scalar @split_file_names;

#		print("2. sumute,Step,list length = $number_of_split_files\n");
#		print("2. sumute,Step,list[0] $split_file_names[0]\n");

		# print("2. sumute,Step,list[1] $split_file_names[1]\n");
#		print("2. sumute,Step,split_files = @split_file_names\n");

=head2 prepare sumute with split files

=cut

=head2 local error check

=cut

		my $number_of_par_sets = scalar @{ $sumute->{_par_gather_number_aref} };

		if ( $number_of_split_files ne $number_of_par_sets ) {

			print(
"\n sumute, Step,N.B.:    # of split files (= $number_of_split_files)\n"
			);
			print(
" may not equal         # of par files   (= $number_of_par_sets) \n"
			);

		}
		elsif ($sumute->{_multi_gather_par_file} eq $empty_string
			&& $sumute->{_multi_gather_su_file} eq $empty_string )
		{

			print(" sumute,Step, case2 \n");
			$result = 'sumute' . $sumute->{_Step};
			return ($result);

		}
		else {

			# NADA
		}

=head2 get the temporary single-gather 
parameter files
that match split data files

=cut

		( $time_picks_aref2, $x_picks_aref2, $first_name, $second_name ) =
		  _get_par_sets();

		my @par_gather_number = @{ $sumute->{_par_gather_number_aref} };

		if ( $number_of_split_files >= 0 ) {

			for ( my $i = 0 ; $i < $number_of_par_sets ; $i++ ) {

				# match on par file gather number
				my $par_gather_number =
				  '0' . $par_gather_number[$i] . $suffix_su;

				my @matches = grep { /$par_gather_number/ } @split_file_names;

			   # print("2 sumute,Step,gather_number= $par_gather_number[$i]\n");
			   # print("2 sumute,Step,matches = @matches\n");
				my $length = scalar @matches;

				# print("2 sumute,Step,mo. matches = $length\n");

=head2  error check
get match to an 
existing split files

=cut

				if ( $length > 1 ) {

				# print("sumute,Step,match error Only one file SHOULD exist\n");
				# print("sumute,Step,But matches= @matches\n");

				}
				elsif ( ( scalar @matches ) == 1 ) {

					$split_file_matches[$i] = $matches[0];

		# print("sumute,Step,split_file_matches[$i]=$split_file_matches[$i]\n");

				}
				elsif ( ( scalar @matches ) == 0 ) {

					print(
"sumute,Step,match error At least one file SHOULD exist\n"
					);

				}
				else {
					print("sumute,Step,error check\n");
				}

			}    # for all parameter sets

		}    # if split files exist

=head2 First case
i=0

=cut

		my $number_of_split_file_matches = scalar @split_file_matches;

		if ( $number_of_split_file_matches > 0 ) {

			$muted_output[0] = $split_file_matches[0];
			$muted_output[0] =~ s/.su//;
			$muted_output[0] =
			  $DATA_SEISMIC_SU . '/' . $muted_output[0] . '_mute' . $suffix_su;

			my @time_picks = @{ @{$time_picks_aref2}[0] };
			my @x_picks    = @{ @{$x_picks_aref2}[0] };

			my $time_picks_w_commas = $control->commify( \@time_picks );
			my $x_picks_w_commas    = $control->commify( \@x_picks );

	 # print("2 sumute,Step,time_picks_aref2[0]=@time_picks\n");
	 # print("sumute,Step,muted_output: $muted_output[0], case 0 \n");
	 # print("sumute,Step,split_file_match: $split_file_matches[0], case 0 \n");
	 # print("1 sumute,Step,time_picks_aref2[0]=@{@{$time_picks_aref2}[0]}\n");
	 # print("1 sumute,Step,x_picks_w_commas=$x_picks_w_commas\n");
	 # print("1 sumute,Step,time_picks_w_commas=$time_picks_w_commas\n");

			$result =
				' sumute'
			  . $in
			  . $DATA_SEISMIC_SU . '/'
			  . $split_file_matches[0]
			  . $out
			  . $muted_output[0]
			  . $sumute->{_Step}
			  . ' tmute='
			  . $time_picks_w_commas
			  . ' xmute='
			  . $x_picks_w_commas . "\n";

			# print("A sumute,Step,result so far \n$result\n");

=head2 intermediate muting cases

=cut

			for ( my $i = 1 ; $i < ( $number_of_par_sets - 1 ) ; $i++ ) {

				$muted_output[$i] = $split_file_matches[$i];

		   # print("2 sumute,Step,muted_output: $muted_output[$i] case i=$i\n");
				$muted_output[$i] =~ s/.su//;
				$muted_output[$i] =
					$DATA_SEISMIC_SU . '/'
				  . $muted_output[$i] . '_mute'
				  . $suffix_su;

				my @time_picks = @{ @{$time_picks_aref2}[$i] };
				my @x_picks    = @{ @{$x_picks_aref2}[$i] };

				my $time_picks_w_commas = $control->commify( \@time_picks );
				my $x_picks_w_commas    = $control->commify( \@x_picks );

				$result =
					$result
				  . ' sumute'
				  . $in
				  . $DATA_SEISMIC_SU . '/'
				  . $split_file_matches[$i]
				  . $out
				  . $muted_output[$i]
				  . $sumute->{_Step}
				  . ' tmute='
				  . $time_picks_w_commas
				  . ' xmute='
				  . $x_picks_w_commas . "\n";

			}    # for all parameter sets

=head2 last case

=cut

			my $last_case = $number_of_par_sets - 1;

			$muted_output[$last_case] = $split_file_matches[$last_case];

# print("2 sumute,Step,muted_output: $muted_output[$last_case] case i=$last_case\n");
			$muted_output[$last_case] =~ s/.su//;
			$muted_output[$last_case] =
				$DATA_SEISMIC_SU . '/'
			  . $muted_output[$last_case] . '_mute'
			  . $suffix_su;

			@time_picks = @{ @{$time_picks_aref2}[$last_case] };
			@x_picks    = @{ @{$x_picks_aref2}[$last_case] };

			$time_picks_w_commas = $control->commify( \@time_picks );
			$x_picks_w_commas    = $control->commify( \@x_picks );

			$result =
				$result
			  . ' sumute'
			  . $in
			  . $DATA_SEISMIC_SU . '/'
			  . $split_file_matches[$last_case]
			  . $out
			  . $muted_output[$last_case]
			  . $sumute->{_Step}
			  . ' tmute='
			  . $time_picks_w_commas
			  . ' xmute='
			  . $x_picks_w_commas . "\n";

			# print("2 sumute,Step,result for everything\n$result\n");

=head2  concatenate muted results
create concatenated output file name

=cut

			my $string = $sumute->{_multi_gather_su_file};
			$string =~ s/.su//;
			my $outbound_concatenated_mute_file =
			  $DATA_SEISMIC_SU . '/' . $string . '_mute' . $suffix_su;

# print(" sumute,Step, concatenated_mute_file: $outbound_concatenated_mute_file \n");

=head2 cat first case
	and then the rest in a loop

=cut

			$result = $result . 'cat' . ' ' . $muted_output[0] . ' ';

			for ( my $i = 1 ; $i < $number_of_par_sets ; $i++ ) {

				$result = $result . $muted_output[$i] . ' ';

			}

=head2 finish concatenation

=cut

			#			$result = $result
			#				. $out
			#				. $outbound_concatenated_mute_file;
			# print("4. sumute,Step,result=$result \n");
			return ($result);

		}
		else {
			print("sumute,Step,unexpected number_of_split_file_matches \n");
			return ();
		}    # split_file matches exist

	}
	elsif ($sumute->{_multi_gather_par_file} eq $empty_string
		&& $sumute->{_multi_gather_su_file} eq $empty_string )
	{

		# print(" sumute,Step, case2 \n");
		$result = 'sumute' . $sumute->{_Step};
		return ($result);

	}
	else {
		print(" sumute, Step, unexpected value\n");
		print(
" sumute, Step,multi_gather_par_file=$sumute->{_multi_gather_par_file} \n"
		);
		print(
" sumute, Step,multi_gather_su_file=$sumute->{_multi_gather_su_file} \n"
		);
		print(
" sumute, Step,par_gather_number_aref=$sumute->{_par_gather_number_aref} \n"
		);
		print(" sumute, Step,gather_type=$sumute->{_gather_type} \n");
		return ();

	}    # sub pre-conditions

	print("sumute,Step,result=$result \n");

}

=head2 Subroutine Steps

       Keeps track of actions for execution in the system
       when more that one gather is being processed in the flow
       at a time
       Place contents of each line of the mute tables (t and index) 
       array into either a tmute or an xmute array for each file

 print("$output[$line]\n\n");
 print ("tmute is $sumute->{_tmute}\n\n");
 print ("$sumute->{_Steps}\n\n");
            #print (" sub Steps shows: $sumute->{_Steps_array}[$i]\n\n");

=cut

sub Steps {

	use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $to $suffix_su);
	use App::SeismicUnixGui::misc::flow;

	my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
	my $run = flow->new();
	my ( @items, @outbound );

	for ( my $i = 1 ; $i <= $sumute->{_number_of_par_files} ; $i++ ) {
		tmute( $sumute->{_tmute_array}[$i] );
		xmute( $sumute->{_xmute_array}[$i] );

		$outbound[$i] =
			$DATA_SEISMIC_SU . '/'
		  . $sumute->{_file_in} . '_'
		  . $sumute->{_gather_type}
		  . $sumute->{_gather_number_array}[$i]
		  . $suffix_su;

		@items = (
			'suwind key='
			  . $sumute->{_gather_type} . ' min='
			  . $sumute->{_gather_number_array}[$i] . ' max='
			  . $sumute->{_gather_number_array}[$i],
			$in,  $DATA_SEISMIC_SU . '/' . $sumute->{_file_in} . $suffix_su,
			$to,  ' sumute ' . $sumute->{_Steps},
			$out, $outbound[$i]
		);

		$sumute->{_Steps_array}[$i] = $run->modules( \@items );

		print(" sub Steps shows: $sumute->{_Steps_array}[$i]\n\n");

	}    # for many parameter files

	return (
		$sumute->{_Steps_array},
		$sumute->{_number_of_par_files},
		$sumute->{_gather_number_array}, \@outbound
	);
}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sumute->{_note} = 'sumute' . $sumute->{_note};
	return ( $sumute->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sumute->{_par_gather_number_aref} = '';
	$sumute->{_gather_type}            = '';
	$sumute->{_hmute}                  = '';
	$sumute->{_key}                    = '';
	$sumute->{_linvel}                 = '';
	$sumute->{_mode}                   = '';
	$sumute->{_multi_gather_par_file}  = '';
	$sumute->{_multi_gather_su_file}   = '';
	$sumute->{_nmute}                  = '';
	$sumute->{_ntaper}                 = '';
	$sumute->{_par}                    = '',
	$sumute->{_susplit_stem}           = 'split4sumute',    # maintain, do not clear
	$sumute->{_par_directory}          = '', $sumute->{_tfile} = '';
	$sumute->{_tm0}     = '';
	$sumute->{_tmute}   = '';
	$sumute->{_twindow} = '';
	$sumute->{_xfile}   = '';
	$sumute->{_xmute}   = '';
	$sumute->{_Step}    = '';
	$sumute->{_note}    = '';

}

=head2 sub gather_type

for example, can be ep cdp 
and refers to the types of gathers that
are being muted.

=cut

sub gather_type {

	my ( $self, $gather_type ) = @_;
	if ( $gather_type ne $empty_string ) {

		$sumute->{_gather_type} = $gather_type;

	}
	else {
		print("sumute, gather_type, missing gather_type,\n");
	}
}

=head2 sub header_word_mute


=cut

sub header_word_mute {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$sumute->{_key}  = $key;
		$sumute->{_note} = $sumute->{_note} . ' hmute=' . $sumute->{_key};
		$sumute->{_Step} = $sumute->{_Step} . ' hmute=' . $sumute->{_key};

	}
	else {
		print("sumute, header_word, missing key,\n");
	}
}

=head2 sub hmute 


=cut

sub hmute {

	my ( $self, $hmute ) = @_;
	if ( $hmute ne $empty_string ) {

		$sumute->{_hmute} = $hmute;
		$sumute->{_note}  = $sumute->{_note} . ' hmute=' . $sumute->{_hmute};
		$sumute->{_Step}  = $sumute->{_Step} . ' hmute=' . $sumute->{_hmute};

	}
	else {
		print("sumute, hmute, missing hmute,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$sumute->{_key}  = $key;
		$sumute->{_note} = $sumute->{_note} . ' key=' . $sumute->{_key};
		$sumute->{_Step} = $sumute->{_Step} . ' key=' . $sumute->{_key};

	}
	else {
		print("sumute, key, missing key,\n");
	}
}

=head2 sub linvel 


=cut

sub linvel {

	my ( $self, $linvel ) = @_;
	if ( $linvel ne $empty_string ) {

		$sumute->{_linvel} = $linvel;
		$sumute->{_note}   = $sumute->{_note} . ' linvel=' . $sumute->{_linvel};
		$sumute->{_Step}   = $sumute->{_Step} . ' linvel=' . $sumute->{_linvel};

	}
	else {
		print("sumute, linvel, missing linvel,\n");
	}
}

=head2 sub mode 


=cut

sub mode {

	my ( $self, $mode ) = @_;
	if ( $mode ne $empty_string ) {

		$sumute->{_mode} = $mode;
		$sumute->{_note} = $sumute->{_note} . ' mode=' . $sumute->{_mode};
		$sumute->{_Step} = $sumute->{_Step} . ' mode=' . $sumute->{_mode};

	}
	else {
		print("sumute, mode, missing mode,\n");
	}
}

=head2 sub multi_gather_par_file

sumute can only handle one
set of mute picks per file
so a multi-gather file has to be
split.

A multi-gather par file for muting
assembles these picks into one file
using the same format as sunmo
par files.

However, currently sumute can not
read multi-gather-par files.
The user is unaware of this in SeismicUnixGui

multi-gather_par_files are 
written like sunmo files with cdp numbers on the first line
and tnmo and vnmo alternating on successive lines

=cut

sub multi_gather_par_file {

	my ( $self, $multi_gather_par_file ) = @_;

	if ( $multi_gather_par_file ne $empty_string ) {

=head2 instantiate classes

=cut

		my $files = manage_files_by2->new();

=head2 module definitions

$sumute->{_par_gather_number_aref}

=cut

		my ( @time_picks_aref2, @x_picks_aref2 );

		$sumute->{_multi_gather_par_file} = $multi_gather_par_file;

		my ( $time_picks_aref2, $x_picks_aref2, $first_name, $second_name ) =
		  _get_par_sets();

		# collect single-gather mute paramters (tmut and xmute3)
		# write tmute and xmute in successive lines

		# run _get_par_sets previously
		my $number_of_gathers = scalar @{ $sumute->{_par_gather_number_aref} };

# print("sumute,multi_gather_par_file, number_of_gathers=$number_of_gathers\n");

		for ( my $i = 0 ; $i < $number_of_gathers ; $i++ ) {

			my $time_picks_ref = @{$time_picks_aref2}[$i];
			my $x_picks_ref    = @{$x_picks_aref2}[$i];

	   # print("sumute,multi_gather_par_file, time_picks=@{$time_picks_ref}\n");
	   # print("sumute,multi_gather_par_file, x_picks=@{$x_picks_ref}\n");

		}

	}
	else {
		print("sumute,multi_gather_par_file, missing mult-gather-par file\n");
		return ();
	}
	return ();
}

=head2 sub multi_gather_su_file 


=cut

sub multi_gather_su_file {

	my ( $self, $multi_gather_su_file ) = @_;
	if ( $multi_gather_su_file ne $empty_string ) {

		$sumute->{_multi_gather_su_file} = $multi_gather_su_file;

		# print("sumute, multi_gather_su_file=$multi_gather_su_file\n");

	}
	else {
		print("sumute, multi_gather_su_file, missing multi_gather_su_file,\n");
	}
}

=head2 sub nmute 


=cut

sub nmute {

	my ( $self, $nmute ) = @_;
	if ( $nmute ne $empty_string ) {

		$sumute->{_nmute} = $nmute;
		$sumute->{_note}  = $sumute->{_note} . ' nmute=' . $sumute->{_nmute};
		$sumute->{_Step}  = $sumute->{_Step} . ' nmute=' . $sumute->{_nmute};

	}
	else {
		print("sumute, nmute, missing nmute,\n");
	}
}

=head2 sub ntaper 


=cut

sub ntaper {

	my ( $self, $ntaper ) = @_;
	if ( $ntaper ne $empty_string ) {

		$sumute->{_ntaper} = $ntaper;
		$sumute->{_note}   = $sumute->{_note} . ' ntaper=' . $sumute->{_ntaper};
		$sumute->{_Step}   = $sumute->{_Step} . ' ntaper=' . $sumute->{_ntaper};

	}
	else {
		print("sumute, ntaper, missing ntaper,\n");
	}
}

=head2 sub offset_word 


=cut

sub offset_word {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$sumute->{_key}  = $key;
		$sumute->{_note} = $sumute->{_note} . ' key=' . $sumute->{_key};
		$sumute->{_Step} = $sumute->{_Step} . ' key=' . $sumute->{_key};

	}
	else {
		print("sumute, offset_word, missing key,\n");
	}
}

=head2 sub par 


=cut

sub par {

	my ( $self, $par ) = @_;
	if ( $par ne $empty_string ) {

		$sumute->{_par} = $par;
		$sumute->{_note} =
			$sumute->{_note} . ' par='
		  . $sumute->{_par_directory} . '/'
		  . $sumute->{_par};
		$sumute->{_Step} =
			$sumute->{_Step} . ' par='
		  . $sumute->{_par_directory} . '/'
		  . $sumute->{_par};

	}
	else {
		print("sumute, par, missing par,or par_directory\n");
	}
}

=head2 sub par_directory

 selection of arbitrary
 parfile directory


=cut

sub par_directory {

	my ( $self, $par_directory ) = @_;

	if ( $par_directory ne $empty_string ) {

		if ( $par_directory eq 'DATA_SEISMIC_TXT' ) {

			$par_directory = $DATA_SEISMIC_TXT;
			$sumute->{_par_directory} = $par_directory;

		}
		else {
			print("sumute, par_directory, unexpected par_directory,\n");
		}

	}
	else {
		print("sumute, par_directory, missing par_directory,\n");
	}
}

=head2 sub par_file 


=cut

sub par_file {

	my ( $self, $par ) = @_;

	if ( length $par ) {

		$sumute->{_par} = $par;
		$sumute->{_note} =
			$sumute->{_note} . ' par='
		  . $sumute->{_par_directory} . '/'
		  . $sumute->{_par};
		$sumute->{_Step} =
			$sumute->{_Step} . ' par='
		  . $sumute->{_par_directory} . '/'
		  . $sumute->{_par};

	}
	else {
		print("sumute, par_file, missing par or par_directory,\n");
	}
}

=head2 sub tfile 


=cut

sub tfile {

	my ( $self, $tfile ) = @_;
	if ( $tfile ne $empty_string ) {

		$sumute->{_tfile} = $tfile;
		$sumute->{_note}  = $sumute->{_note} . ' tfile=' . $sumute->{_tfile};
		$sumute->{_Step}  = $sumute->{_Step} . ' tfile=' . $sumute->{_tfile};

	}
	else {
		print("sumute, tfile, missing tfile,\n");
	}
}

=head2 sub tm0 


=cut

sub tm0 {

	my ( $self, $tm0 ) = @_;
	if ( $tm0 ne $empty_string ) {

		$sumute->{_tm0}  = $tm0;
		$sumute->{_note} = $sumute->{_note} . ' tm0=' . $sumute->{_tm0};
		$sumute->{_Step} = $sumute->{_Step} . ' tm0=' . $sumute->{_tm0};

	}
	else {
		print("sumute, tm0, missing tm0,\n");
	}
}

=head2 sub tmute 


=cut

sub tmute {

	my ( $self, $tmute ) = @_;
	if ( $tmute ne $empty_string ) {

		$sumute->{_tmute} = $tmute;
		$sumute->{_note}  = $sumute->{_note} . ' tmute=' . $sumute->{_tmute};
		$sumute->{_Step}  = $sumute->{_Step} . ' tmute=' . $sumute->{_tmute};

	}
	else {
		print("sumute, tmute, missing tmute,\n");
	}
}

=head2 sub twindow 


=cut

sub twindow {

	my ( $self, $twindow ) = @_;
	if ( $twindow ne $empty_string ) {

		$sumute->{_twindow} = $twindow;
		$sumute->{_note} = $sumute->{_note} . ' twindow=' . $sumute->{_twindow};
		$sumute->{_Step} = $sumute->{_Step} . ' twindow=' . $sumute->{_twindow};

	}
	else {
		print("sumute, twindow, missing twindow,\n");
	}
}

=head2 sub type 


=cut

sub type {

	my ( $self, $mode ) = @_;

	if ( $mode ne $empty_string ) {

		if ( $mode eq 'top' ) {
			$mode       = 0;
			$imute_par_ = $itop_mute_par_;

		}

		if ( $mode eq 'bottom' ) {
			$mode       = 1;
			$imute_par_ = $ibot_mute_par_;
		}

		$sumute->{_mode} = $mode;
		$sumute->{_note} = $sumute->{_note} . ' mode=' . $sumute->{_mode};
		$sumute->{_Step} = $sumute->{_Step} . ' mode=' . $sumute->{_mode};

	}
	else {
		print("sumute, type, missing mode,\n");
	}
}

=head2 sub xfile 


=cut

sub xfile {

	my ( $self, $xfile ) = @_;
	if ( $xfile ne $empty_string ) {

		$sumute->{_xfile} = $xfile;
		$sumute->{_note}  = $sumute->{_note} . ' xfile=' . $sumute->{_xfile};
		$sumute->{_Step}  = $sumute->{_Step} . ' xfile=' . $sumute->{_xfile};

	}
	else {
		print("sumute, xfile, missing xfile,\n");
	}
}

=head2 sub xmute 


=cut

sub xmute {

	my ( $self, $xmute ) = @_;
	if ( $xmute ne $empty_string ) {

		$sumute->{_xmute} = $xmute;
		$sumute->{_note}  = $sumute->{_note} . ' xmute=' . $sumute->{_xmute};
		$sumute->{_Step}  = $sumute->{_Step} . ' xmute=' . $sumute->{_xmute};

	}
	else {
		print("sumute, xmute, missing xmute,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 16;

	return ($max_index);
}

1;
