package App::SeismicUnixGui::sunix::shapeNcut::sukill;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version: 0.0.2   1.30.23

=head2 USE

Usage 1:
To kill an array of trace numbers

Example:
       $sukill->tracl(\@array);
       $sukill->Steps()

Usage 2:
To kill a single of trace number
count=1 (default if omitted)

Example:
       $sukill->min('2');
       $sukill->Step()

If you read the file directly into sukill then also
us sukill->file('name')

Usage 3:
      $sukill->list(list_of_traces_to_kill)
      $sukill->su_base_file_name(file_in_seismic_unix_format)

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUKILL - zero out traces					

 sukill <stdin >stdout [optional parameters]			

 Optional parameters:						

	key=trid	header name to select traces to kill	

	a=2		header value identifying traces to kill

 or

 	min= 		first trace to kill (one-based)		

 	count=1		number of traces to kill 		


 Notes:							

	If min= is set it overrides selecting traces by header.	


 Credits:

	CWP: Chris Liner, Jack K. Cohen

	header-based trace selection: Florian Bleibinhaus


 Trace header fields accessed: ns


=head2 CHANGES and their DATES

 JML V0.0.2, 1.30.23

 Normally, sukill can kill contiguous traces
 To kill while skipping traces requires
 iteration over the same file.
 
 In V0.0.2 I wrap an extension to process an arbitrary
 list of trace numbers . I automate the iteration by including
 two additional parameters: list and su_base_file_name
 
 The parameter "list" is the name of a text file.
 The file is automatically bound to the SEIMICS_DATA_TXT 
 directory path.
 
 "list" is the name of a file containing a numeric list
 of trace numbers of type "key" that are to be deleted:
 
 An example list
 file contains values, one per line.
    1 
    3 
    5

  "list" = a file name (in directory path: DATA_SEISMICS_TXT)
  
  su_base_file_name =   e.g., 1001 (in directory path: DATA_SEISMIC_SU)
  
  Notes:
  If list is used then su_base_file_name and key MUST be used
  If list is used ONLY su_base_file_name and key CAN be used

  Within code herein, the imported "list" includes path and name,
  hence its name: _inbound_list.
  
  But user only enters a list name in GUI using the mouse <MB3>.

=cut

use Moose;
our $VERSION = '0.0.2';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $out $suffix_su $suffix_txt $txt $suffix_bin $to);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::readfiles';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $control          = control->new();
my $readfiles        = readfiles->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};
my $default      = $txt;

=head2 Encapsulated
hash of private variables

=cut

my $sukill = {
	_a                         => '',
	_count                     => '',
	_inbound_su_base_file_name => '',
	_key                       => '',
	_inbound_list              => '',
	_min                       => '',
	_Step                      => '',
	_note                      => '',

};

$sukill->{_data_type} = $default;

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	my ($self) = @_;

	if (    length $sukill->{_inbound_list}
		and length $sukill->{_key}
		and length $sukill->{_inbound}
		and not length $sukill->{_min}
		and not length $sukill->{_count}
		and not length $sukill->{_a} )
	{

		my $trace_num;
		my $temp_outbound = '.temp';
		my @Step;

		my ( $array_ref, $num_gathers ) = _get_trace_numbers();
		my $inbound = _get_inbound();

		# print("sukill, num_gathers=$num_gathers\n");
		# print("sukill, values=@$array_ref\n");

	    # All cases when num_traces >=0
		$trace_num = @$array_ref[0];
		my $step =
		  "sukill key=$sukill->{_key} count=1 min=$trace_num < $inbound ";
		my $temp_inbound = $temp_outbound;

		my $penultimate_idx = $num_gathers - 2;
		my $last_idx        = $num_gathers - 1;

		
		if ( $last_idx >= 2 ) {
			
			# number of kills >=3
			for ( my $i = 1 ; $i < $last_idx ; $i++ ) {

				$trace_num = @$array_ref[$i];
				$step =
					$step
				  . $to 
				  . "\n"
				  . "sukill key=$sukill->{_key} "
				  . "count=1 min=$trace_num ";

			}

			# For last
			$trace_num = @$array_ref[$last_idx];
			$step =
				$step
			  . $to
			  . "sukill key=$sukill->{_key} "
			  . "count=1 min=$trace_num";
			  
			 $sukill->{_Step} = $step;

		}
		elsif ( $last_idx == 1 ) {
			
			# number of kills = 2
			# For 2nd-to-last trace
			# print("sukill, last_idx = 1\n");	
			
			$step =
				$step
			  . $to
			  . "sukill key=$sukill->{_key} "
			  . "count=1 min=@$array_ref[$last_idx] ";
	  
			$sukill->{_Step} = $step;

		}
		elsif ( $last_idx == 0 ) {

			$sukill->{_Step} = $step;
			
		}
		elsif ( not length $sukill->{_inbound_list} ) {

			$sukill->{_Step} = 'sukill' . $sukill->{_Step};
			return ( $sukill->{_Step} );

		}
		else {
			print(
"sukill, Step, Only key and su_base_file_name must accompany list\n"
			);
			print(
"sukill, Step,key: $sukill->{_key}, file:$sukill->{inbound_su_base_file_name}\n"
			);
			print("sukill, Step,list: $sukill->{_inbound_list}\n");
			return ();
		}

	}
}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sukill->{_note} = 'sukill' . $sukill->{_note};
	return ( $sukill->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sukill->{_a}                        = '';
	$sukill->{_count}                    = '';
	$sukill->{_key}                      = '';
	$sukill->{_inbound_list}             = '';
	$sukill->{_min}                      = '';
	$sukill->{inbound_su_base_file_name} = '';
	$sukill->{_Step}                     = '';
	$sukill->{_note}                     = '';
}

sub _get_inbound {
	my ($self) = @_;

	if ( length $sukill->{_inbound} ) {

		my $inbound = $sukill->{_inbound};

		# print("_get_inbound: $inbound\n");
		return ($inbound);

	}
	else {
		print("_get_inbound_list, missing su_base_file_name\n");
		return ();
	}

}

sub _get_inbound_list {
	my ($self) = @_;

	if ( length $sukill->{_inbound_list} ) {

		my $inbound_list = $sukill->{_inbound_list};
		my ( $array_ref, $num_gathers ) = $readfiles->cols_1p($inbound_list);
		my $result_a = $array_ref;
		my $result_b = $num_gathers;

		print("_get_inbound_list, values=@$array_ref\n");
		return ( $result_a, $result_b );

	}
	else {
		print("_get_inbound_list, missing inbound\n");
		return ();
	}

}

sub _get_trace_numbers {
	my ($self) = @_;

	if ( length $sukill->{_inbound_list} ) {

		my $inbound_list = $sukill->{_inbound_list};
		$control->set_back_slashBgone($inbound_list);
		$inbound_list = $control->get_back_slashBgone();

		my ( $array_ref, $num_gathers ) = $readfiles->cols_1p($inbound_list);
		my $result_a = $array_ref;
		my $result_b = $num_gathers;

		# print("_get_trace_numbers, values=@$array_ref\n");
		return ( $result_a, $result_b );

	}
	else {
		print("_get_trace_numbers, missing inbound\n");
		return ();
	}

}

=head2 _check4inbound_listNkey

=cut

sub _check4inbound_listNkey {
	my ($self) = @_;

	if ( $sukill->{_data_type} =
		   $txt
		&& length $sukill->{_inbound_list}
		&& length $sukill->{_key} )
	{

		#NADA, $sukill->{_inbound_list} = $sukill->{_inbound_list};

	}
	else {
		print(
"sukill, _check4inbound_listNkey, improper type, missing list or key\n"
		);
	}
	return ();
}

sub _set_inbound {
	my ($self) = @_;

	if ( length $sukill->{_inbound_su_base_file_name} ) {

		my $inbound = $sukill->{_inbound_su_base_file_name};

		$control->set_back_slashBgone($inbound);
		$inbound = $control->get_back_slashBgone();
		$sukill->{_inbound} = $inbound;

		#        print("sukill,_set_inbound, sukill->{_inbound}=$inbound\n");

	}
	else {
		print("_set_inbound, missing  su_base_file_name\n");
		return ();
	}

}

sub _set_inbound_list {
	my ($self) = @_;

	if ( length $sukill->{_inbound_list} ) {

		my $inbound_list = $sukill->{_inbound_list};
		$control->set_back_slashBgone($inbound_list);
		$inbound_list = $control->get_back_slashBgone();
		$sukill->{_inbound_list} = $inbound_list;

	}
	else {
		print("_set_inbound_list, missing list\n");
		return ();
	}

}

=head2 sub a 


=cut

sub a {

	my ( $self, $a ) = @_;
	if ( $a ne $empty_string ) {

		$sukill->{_a}    = $a;
		$sukill->{_note} = $sukill->{_note} . ' a=' . $sukill->{_a};
		$sukill->{_Step} = $sukill->{_Step} . ' a=' . $sukill->{_a};

	}
	else {
		print("sukill, a, missing a,\n");
	}
}

=head2 sub count 


=cut

sub count {

	my ( $self, $count ) = @_;
	if ( $count ne $empty_string ) {

		$sukill->{_count} = $count;
		$sukill->{_note}  = $sukill->{_note} . ' count=' . $sukill->{_count};
		$sukill->{_Step}  = $sukill->{_Step} . ' count=' . $sukill->{_count};

	}
	else {
		print("sukill, count, missing count,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {
		$sukill->{_key}  = $key;
		$sukill->{_note} = $sukill->{_note} . ' key=' . $sukill->{_key};
		$sukill->{_Step} = $sukill->{_Step} . ' key=' . $sukill->{_key};

	}
	else {
		print("sukill, key, missing key,\n");
	}
}

=head2 sub list

 list array

=cut

sub list {
	my ( $self, $list ) = @_;

	if ( length $list ) {

		$sukill->{_inbound_list} = $list;

		# print("$list\n\n");
		_check4inbound_listNkey();
		_set_inbound_list();

		#		print("sukill,list is $sukill->{_inbound_list}\n\n");

	}
	else {
		print("sukill, list, missing list,\n");
	}
	return ();
}

=head2 sub min 


=cut

sub min {

	my ( $self, $min ) = @_;
	if ( $min ne $empty_string ) {

		$sukill->{_min}  = $min;
		$sukill->{_note} = $sukill->{_note} . ' min=' . $sukill->{_min};
		$sukill->{_Step} = $sukill->{_Step} . ' min=' . $sukill->{_min};

	}
	else {
		print("sukill, min, missing min,\n");
	}
}

=head2 sub su_base_file_name

 su_base_file_name

=cut

sub su_base_file_name {
	my ( $self, $su_base_file_name ) = @_;

	if ( length $su_base_file_name ) {

		$sukill->{_inbound_su_base_file_name} = $su_base_file_name;
		_check4inbound_listNkey();
		_set_inbound();

#		print("sukill,su_base_file_name is $sukill->{inbound_su_base_file_name}\n\n");

	}
	else {
		print("sukill, su_base_file_name, missing \n");
	}
	return ();
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
