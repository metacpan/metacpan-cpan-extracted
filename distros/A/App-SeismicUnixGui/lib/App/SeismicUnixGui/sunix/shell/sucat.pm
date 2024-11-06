package App::SeismicUnixGui::sunix::shell::sucat;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PROGRAM NAME: sucat
AUTHOR: Juan Lorenzo (Perl module only)
 DATE: May 25 2016
 DESCRIPTION concatenate a list of files
 Version 1
         1.01 June 23 2016
 Variable suffix changed to input_suffix 
 Notes: 
 Package name is the same as the file name
 Moose is a package that allows an object-oriented
 syntax to organizing your programs

=cut

=head2 USAGE 1 (todo)

 To cat an array of trace numbers
 Example
       $sucat->tracl(\@array);
       $sucat->Steps()

=head2 USAGE 2

   To cat a defined range of numerically-named
files

 Example:
       $sucat->first_file_number_in('1000');
       $sucat->last_file_number_in('1001');
       $sucat->number_of_files_in('2');
       $sucat->Step();
=cut

=head2 import packages

=cut

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::misc::manage_files_by';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($itop_mute $ibot_mute $ivpicks_sorted_par_ $ep $fldr
  $cdp $mute $su $suffix_su $suffix_txt $velan);

=head2 instantiate new variables

=cut

my $get             = L_SU_global_constants->new();
my $Project         = Project_config->new();
my $manage_files_by = manage_files_by->new();

my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();    # output seismic data directory
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();   # output list directory

=head2 declare local variables

=cut

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 newline:

 is a special character

=cut

my $newline = '
';

=head2 list:

 an empty list array 

=cut

my (@list);

=head2 sucat:
is a hash of important variables

=cut

my $sucat = {
	_first_file_number_in => '',
	_gather_type          => '',
	_inbound_directory    => '',
	_input_suffix         => '',
	_input_name_extension => '',
	_input_name_prefix    => '',
	_outbound_directory   => '',
	_last_file_number_in  => '',
	_list_aref            => '',
	_list_directory       => '',
	_number_of_files_in   => '',
	_input_suffix         => '',
	_data_type            => '',
	_output_file_name     => '',
	_outbound             => '',
	_velan_data           => '',
	_Step                 => ''
};

=head2 sub clear:

 clean hash of its values

=cut

sub clear {
	my ($self) = @_;
	$sucat->{_first_file_number_in} = '';
	$sucat->{_gather_type}          = '';
	$sucat->{_inbound_directory}    = '';
	$sucat->{_input_name_extension} = '';
	$sucat->{_input_suffix}         = '';
	$sucat->{_outbound_directory}   = '';
	$sucat->{_last_file_number_in}  = '';
	$sucat->{_list_array}           = '';
	$sucat->{_list_directory}       = '';
	$sucat->{_data_type}            = '';
	$sucat->{_number_of_files_in}   = '';
	$sucat->{_input_suffix}         = '';
	$sucat->{_output_file_name}     = '';
	$sucat->{_outbound}             = '';
	$sucat->{_Step}                 = '';
}

=head2 _get_data_type

=cut

sub _get_data_type {
	my ($self) = @_;

	if (    $sucat->{_list_directory} ne $empty_string
		and $sucat->{_list} ne $empty_string )
		
	{

		# my $velan = $ivpicks_sorted_par_;

=head2 instantiate packages

=cut

		my $read = readfiles->new();

=head2 declare local variables

=cut

		my @data_type;
		my $data_type;

		my $inbound_list =
		  $sucat->{_list_directory} . '/' . $sucat->{_list} . $suffix_txt;

		my ( $array_ref, $num_gathers ) = $read->cols_1p($inbound_list);

		for ( my $i = 0 ; $i < $num_gathers ; $i++ ) {

			my $file_name = @$array_ref[$i];

			if (   $file_name =~ m/$itop_mute/
				or $file_name =~ m/$ibot_mute/ )
			{

				#CASE 1 for mute-type files

				$data_type[$i] = $mute;

				#				print("sucat,_get_data_type, success, matched mute\n");

			}
			elsif ( $file_name =~ m/$ivpicks_sorted_par_/ ) {

				#CASE 2 for velan-type files

				# print("success, matched velan\n");
				$data_type[$i] = $velan;

			}
			elsif ( $file_name =~ m/$suffix_su/ ) {

				# print("success, matched $su\n");
				$data_type[$i] = $su;

			}
			else {
				print("sucat,_get_data_type, mismatch\n");
				$data_type[$i] = $empty_string;
			}

		}

		# all data types must be the same
		$data_type = $data_type[0];

		for ( my $i = 0 ; $i < $num_gathers ; $i++ ) {

			if ( $data_type[0] eq $data_type[$i] ) {

				# print("sucat,_get_data_type, data_type is consistent NADA\n");

			}
			elsif ( $data_type[0] ne $data_type[$i] ) {

				$data_type = $empty_string;

				# print("sucat,_get_data_type,failed\ test\n");

			}
			else {
				print("sucat,_get_data_type_unexpected result\n");
				$data_type = $empty_string;
			}
		}

		my $result = $data_type;
		return ($result);

	}
	else {
		print("sucat,_get_data_type,missing list and its directory\n");
	}
}

=head2 _get_gather_type

=cut

sub _get_gather_type {
	my ($self) = @_;

	if (
			length $sucat->{_list_directory}
		and length $sucat->{_list}
		and ( ( $sucat->{_data_type} eq $velan )
			 or $sucat->{_data_type} eq $mute )
	  )
	{

=head2 instantiate packages

=cut

		my $read = readfiles->new();

=head2 declare local variables

=cut

		my @gather_type;
		my $gather_type;

		my $inbound_list =
		  $sucat->{_list_directory} . '/' . $sucat->{_list} . $suffix_txt;

		my ( $array_ref, $num_gathers ) = $read->cols_1p($inbound_list);

		for ( my $i = 0 ; $i < $num_gathers ; $i++ ) {

			my $file_name = @$array_ref[$i];

			if (   $file_name =~ m/$fldr/
				or $file_name =~ m/$cdp/ )
			{

				#CASE 1 for field record gathers

				$gather_type[$i] = 'fldr';

				print("sucat,_get_gather_type, success, matched fldr\n");

			}
			elsif ( $file_name =~ m/$ep/ ) {

				#CASE 2 for velan-type files

				# print("success, matched velan\n");
				$gather_type[$i] = $ep;

			}
			else {
				print("sucat,_get_gather_type, mismatch\n");
			}
		}

		# all gather types must be the same
		$gather_type = $gather_type[0];

		for ( my $i = 0 ; $i < $num_gathers ; $i++ ) {

			if ( $gather_type[0] eq $gather_type[$i] ) {

			# print("sucat,_get_gather_type, gather_type is consistent NADA\n");

			}
			elsif ( $gather_type[0] ne $gather_type[$i] ) {

				$gather_type = $empty_string;

				# print("sucat,_get_gather_type,failed\ test\n");

			}
			else {
				print("sucat,_get_gather_type_unexpected result\n");
				$gather_type = $empty_string;
			}
		}

		my $result = $gather_type;
		return ($result);

	}
	else {
#		print("sucat,_get_gather_type, missing list and its directory NADA\n");
	}
}

=head2 sub _set_data_type

 set_data_type can be velan,su,txt, cat

=cut

sub _set_data_type {
	my ($data_type) = @_;

	if ( $data_type ne $empty_string ) {

		$sucat->{_data_type} = $data_type;

#		print("sucat, _set_data_type, data_type = $sucat->{_data_type}\n");

	}
	else {
		print("sucat, _set_data_type, missing data_type\n");
	}

}

=head2 sub _set_gather_type

 set_gather_type can be cdp,ep,fldr

=cut

sub _set_gather_type {

	my ($gather_type) = @_;

	if ( $gather_type ne $empty_string ) {

		$sucat->{_gather_type} = $gather_type;

	 # print("sucat, _set_gather_type, gather_type = $sucat->{_gather_type}\n");

	}
	else {
		print("sucat, _set_gather_type, missing data_type\n");
	}

}

=head2 sub data_type

 data_type can be velan,su,txt,mute

=cut

sub data_type {
	my ($self) = @_;

	if (    $sucat->{_list_directory} ne $empty_string
		and $sucat->{_list} ne $empty_string )
	{

=head2 bring in packages

=cut

=head2 instantiate packages

=cut

		my $read    = readfiles->new();
		my $control = control->new();

=head2 Declare local variables

=cut		

		my $par_file;
		my ( @result_t, @result_v );
		my @gather_number;
		my ( $values_aref, $ValuesPerRow_aref );
		my $rows;

		my $data_type = _get_data_type();
		_set_data_type($data_type);
		my $gather_type = _get_gather_type();

#		print("sucat, data_type, data_type=---$data_type---\n\n");

		if (
			$data_type ne $empty_string
			&& (   $data_type eq $velan
				or $data_type eq $mute )
		  )
		{

			my $inbound_list =
			  $sucat->{_list_directory} . '/' . $sucat->{_list}. $suffix_txt;
			my ( $ref_array, $num_gathers ) = $read->cols_1p($inbound_list);

			my $DIR_OUT = $sucat->{_list_directory};

#			print("sucat,data_type,num_gathers: $num_gathers\n");

=head2

 1.Read a list of file names
 2.Read contents of each file in the list
 into arrays.
 
 3. Each line of the list uses a file name that indicates
 gather number and the other file name in which to find
 velocity picks.
 
 4. Sort the cdp or gather number into monotonically increasing
 values and rearrange the pick pairs accordingly.
 
=cut

			for (
				my $file_number = 0, my $line = 0 ;
				$file_number < $num_gathers ;
				$file_number++, $line++
			  )
			{

				my $file_name_complete = @$ref_array[$file_number];
				my $inbound =
				  $sucat->{_list_directory} . '/' . $file_name_complete;

				my $gather_name = @$ref_array[$file_number];

				print("sucat,reading gather: $gather_name\n");

				# read number only after last underscore
				my @splits = split( /_/, $gather_name );

				print("sucat, splits are:: @splits\n");
				my $last_split_index = $#splits;

				my $last_split = $splits[$last_split_index];

				# print("sucat, last split is:: $last_split\n");
				$last_split =~ s/[^0-9]*//g;
				$gather_number[$file_number] = $last_split;

				# read values for each gather, one at a time
				( $values_aref, $ValuesPerRow_aref ) =
				  $manage_files_by->read_par( \$inbound );

# print("sucat,data_type,reading gather_number: $gather_number[$file_number]\n");
# print("sucat,data_type,ValuesPerRow : @$ValuesPerRow_aref\n");

=head2 Place contents 

of each file in the list
into an array.

=cut

				$result_t[$line] = @$values_aref[0];
				$result_v[$line] = @$values_aref[1];

#				print("sucat,data_type,t: $result_t[$line]\n");
#				print("sucat,data_type,v/x: $result_v[$line]\n");

			}    # end repeat over all mute- or velan-type files

=head2 sort by gather number

=cut

			my @sorted_indices =
			  sort { $gather_number[$a] <=> $gather_number[$b] }
			  0 .. $#gather_number;
			my @sorted_gather_number = sort { $a <=> $b } @gather_number;

		  # print("sucat, data_type, sorted indices: @sorted_indices \n");
		  # print("sucat, data_type, unsorted indices: 0 .. $#gather_number\n");

			my ( @sorted_result_v, @sorted_result_t );
			my $number_of_gathers = scalar @sorted_gather_number;

			for ( my $i = 0 ; $i < $number_of_gathers ; $i++ ) {

				$sorted_result_v[$i] = $result_v[ $sorted_indices[$i] ];
				$sorted_result_t[$i] = $result_t[ $sorted_indices[$i] ];

 # print("sucat, data_type, sorted_gather_number: $sorted_gather_number[$i]\n");
 # print("sucat, data_type, unsorted_gather_number: $gather_number[$i]\n");

			}

			if ( $data_type eq $velan ) {

				$manage_files_by->write_cdp( \@sorted_gather_number, $DIR_OUT );
				$manage_files_by->write_tnmo_vnmo( \@sorted_gather_number,
					\@sorted_result_t, \@sorted_result_v, $DIR_OUT );

			}
			elsif ( $data_type eq $mute ) {
				
				# print("sucat,data_type. Data types are mute.\n\n");
				$manage_files_by->write_gather( \@sorted_gather_number,
					$DIR_OUT, $gather_type );
				$manage_files_by->write_tmute_xmute( \@sorted_gather_number,
					\@sorted_result_t, \@sorted_result_v, $DIR_OUT );

			}

			else {
				print("sucat, data_type, unrecognized data_type\n");
			}

		}
		else {
			#			print(
			#				"sucat,data_type. Data types are not:  mute or velan.
			#Ignore special formats. Using simple cat. NADA\n\n"
			#			);
		}
	}
}

=head2 sub get_outbound

=cut

sub get_outbound {

	my ($variable) = @_;

	if (    length $sucat->{_outbound}
		and length $sucat->{_data_type} 
		and length $sucat->{_output_file_name})
		
	{
		# CASE of list
		if ( $sucat->{_data_type} eq $su ) {

			my $result = $sucat->{_outbound} . $suffix_su;
			return ($result);
			
		}elsif( $sucat->{_data_type} eq $mute ) {
			
			my $result = $DATA_SEISMIC_TXT . '/'. $sucat->{_output_file_name}. $suffix_txt;
			return ($result);
		}
		else {
			my $result = $sucat->{_outbound};    # no change
			return ($result);
		}

	}elsif (  length $sucat->{_outbound}
		and not length $sucat->{_data_type} 
		and length $sucat->{_output_file_name}){
			
			# CASE of no list
			my $result = $sucat->{_outbound};    # no change
			return ($result);
	}
	else {
		print("sucat,get_outbound: missing parameter\n");
		print("outbound=$sucat->{_outbound}\n");
		print("data_type=$sucat->{_data_type}\n");		
		print("output_file_name=$sucat->{_output_file_name}\n");		
	}

}

=head2 sub first_file_number_in:

 for first_file_number_in numerical file name

=cut

sub first_file_number_in {
	my ( $variable, $first_file_number_in ) = @_;
	if ( $first_file_number_in ne $empty_string ) {
		$sucat->{_first_file_number_in} = $first_file_number_in;
	}
	else {

		# print("sucat,first_file_number_in: NADA\n");
	}

#	print(
#		"sucat, first_file_number_in, first_file_number_in=---$sucat->{_first_file_number_in}---\n\n"
#	);
}

=head2 sub inbound_directory:

 for inbound directory name

=cut

sub inbound_directory {
	my ( $variable, $inbound_directory ) = @_;

	if ( $inbound_directory ne $empty_string ) {
		$sucat->{_inbound_directory} = $inbound_directory;
	}
	else {
		# print("sucat,inbound_directory: NADA\n");
	}

}

=head2 sub input_name_extension 

 use after names and numbers
 
 e.g., gather_100_input_name_extension.su

=cut

sub input_name_extension {
	my ( $variable, $input_name_extension ) = @_;

	if ( $input_name_extension ne $empty_string ) {
		
		$sucat->{_input_name_extension} = $input_name_extension;
		
	}
	else {

		# print("sucat,input_name_extension: NADA\n");
	}
}

=head2 sub input_name_prefix 

 use before names and numbers
 input_prefix_100.su

=cut

sub input_name_prefix {
	my ( $variable, $input_name_prefix ) = @_;

	if ( $input_name_prefix ne $empty_string ) {
		$sucat->{_input_name_prefix} = $input_name_prefix;
	}
	else {

		# print("sucat,input_input_name_prefix: NADA\n");
	}
}

=head2 sub input_suffix 

 use after dot for all names
 e.g., .su

=cut

sub input_suffix {
	my ( $variable, $input_suffix ) = @_;

	if ( $input_suffix ne $empty_string ) {
		$sucat->{_input_suffix} = $input_suffix;
	}
	else {

		# print("sucat,input_suffix: NADA\n");
	}

}

=head2 sub last_file_number_in:

 for last_file_number_in numerical file name 

=cut

sub last_file_number_in {
	my ( $variable, $last_file_number_in ) = @_;

	if ( $last_file_number_in ne $empty_string ) {
		$sucat->{_last_file_number_in} = $last_file_number_in;
	}
	else {

		# print("sucat,last_file_number_in: NADA\n");
	}

#	print(
#		"sucat,last_file_number_in, last_file_number_in: $sucat->{_last_file_number_in}  \n\n"
#	);
}

=head2 sub list:

 for list directory name

=cut

sub list {
	my ( $variable, $list ) = @_;

	if ( $list ne $empty_string ) {
		$sucat->{_list} = $list;

		# print("sucat,list is $sucat->{_list}\n");
	}
	else {

		# print("sucat,list is empty NADA\n");
	}

}

=head2 sub list_directory:

 for list directory name

=cut

sub list_directory {
	my ( $variable, $list_directory ) = @_;

	if ( $list_directory ne $empty_string ) {

		$sucat->{_list_directory} = $list_directory;

	}

	else {
		# print("sucat,list_directory: NADA\n");
	}

}

=head2 sub number_of_files_in:

 for number_of_files_in

=cut

=head2 sub number_of_files_in:

 for number of files to concatenate

=cut

sub number_of_files_in {
	my ( $variable, $number_of_files_in ) = @_;

	if ( $number_of_files_in ne $empty_string ) {
		$sucat->{_number_of_files_in} = $number_of_files_in;
	}
	else {

		# print("sucat,number_of_files_in: NADA\n");
	}

}

=head2 sub outbound_directory:

 for outbound directory name

=cut

sub outbound_directory {
	my ( $variable, $outbound_directory ) = @_;

	if ( $outbound_directory ne $empty_string ) {
		
		$sucat->{_outbound_directory} = $outbound_directory;
		
	}
	else {
		# print("sucat,outbound_directory: NADA\n");
	}

}

=head2 sub output_file_name:

 for number of files to concatenate

=cut

sub output_file_name {
	my ( $variable, $output_file_name ) = @_;

	if ( $output_file_name ne $empty_string ) {
		
		$sucat->{_output_file_name} = $output_file_name;
		
	}
	else {
		# print("sucat,output_file_name: NADA\n");
	}

}

=head2 sub set_ist_aref

 list array

=cut

sub set_list_aref {
	my ( $variable, $list_aref ) = @_;

	if ( $list_aref ne $empty_string ) {
		
		$sucat->{_list_aref} = $list_aref;
		
	}
	else {
		# print("sucat,set_list_aref: NADA\n");
	}

	# print("sucat, list_aref, list=---@$list_aref--\n");
	$sucat->{_number_of_files_in} = scalar @$list_aref;

  #print(
  #	"sucat, set_list_aref, number_of_files_in=$sucat->{_number_of_files_in}\n\n"
  #);
}

=head2 sub set_outbound

=cut

sub set_outbound {
	my ( $variable, $outbound ) = @_;

	if ( length $outbound ) {

		$sucat->{_outbound} = $outbound;
	}
	else {
		print("sucat,set_outbound: missing parameter\n");
	}

}

=head2 subroutine Step  

 builds array to concatenate
 first_file_number_in line ,
 output contacts program name,
 successive lines
 final output name is provided by user name
 add new file names

=cut

sub Step {

	my $file;

	# CASE 1: there is a list
	if ( $sucat->{_list_aref} ne $empty_string ) {

		$sucat->{_Step} = ' cat ';

		# CASE 1A- without data type
		if ( $sucat->{_data_type} eq $empty_string ) {

			print(" sucat, Step, no list with data_type: $sucat->{_Step}\n\n");

			for ( my $i = 0 ; $i < $sucat->{_number_of_files_in} ; $i++ ) {

				# CASE 1A-1 : there is an input suffix specified by user
				if ( $sucat->{_input_suffix} ne $empty_string ) {
					print(
						"Warning: Incorrect settings. Either \n
\t 1) Use a list and output without file name. But, exclude values for first 6 parameters. \n
\t (The alternative directories are optional).\n
\t That is, when you use a list, the values of the prior\n
\t 6 parameters remain blank.\n
\t 2) Do NOT use a list. Include values for at least the first 3 \n
\t parameters. The output file name is allowed. Suffix,prefix and file name extensions
\t are optional. But do not use a \n
\t the list.  See help for examples. (sucat, Step Case 1A-1)\n"
					);
				}

				# CASE 1A-2 : there is no input sufffix specified by user
				elsif ( $sucat->{_input_suffix} eq $empty_string ) {
					$sucat->{_Step} =
						$sucat->{_Step}
					  . $sucat->{_inbound_directory} . '/'
					  . @{ $sucat->{_list_aref} }[$i] . ' \\'
					  . $newline;

				}
				else {
					print("sucat,Step, unexpected input_suffix \n");
				}

				# print("i=$i\n\n");
				# print(" list_directory is $sucat->{_list_directory}\n\n");
				# print(" 1. list is $sucat->{_Step}\n");
			}
		}    # end CASE 1A no data type

		# CASE 1B: data_type does exist
		elsif ( $sucat->{_data_type} ne $empty_string ) {

			if ( $sucat->{_data_type} eq $velan ) {

				$sucat->{_Step} =
					$sucat->{_Step}
				  . $sucat->{_list_directory} . '/' . '.cdp '
				  . $sucat->{_list_directory} . '/' . '.tv' . '\\'
				  . $newline;

				print(
					"sucat,Step, case of velan,sucat->{_Step}=$sucat->{_Step}\n"
				);

			}
			elsif ( $sucat->{_data_type} eq $mute ) {

				$sucat->{_Step} =
					$sucat->{_Step}
				  . $sucat->{_list_directory} . '/'
				  . '.gather '
				  . $sucat->{_list_directory} . '/' . '.tx ' . '\\'
				  . $newline;

			}
			elsif ( $sucat->{_data_type} eq $su ) {

				for ( my $i = 0 ; $i < $sucat->{_number_of_files_in} ; $i++ ) {

					$sucat->{_Step} =
						$sucat->{_Step}
					  . $DATA_SEISMIC_SU . '/'
					  . @{ $sucat->{_list_aref} }[$i] . ' \\'
					  . $newline;

				}

			}

			else {
				print(" sucat,Step,unexpected data_type\n\n");
			}
		}
		else {
			print(" list sucat,Step,unexpected situation \n\n");
		}
	}    #END CASE 1: with list

	# CASE 2: there is no list
	elsif ( $sucat->{_list_aref} eq $empty_string ) {
		$sucat->{_Step} = ' cat ';

		# print(" 2. sucat,Step, list is $sucat->{_Step}\n\n");

		# CASE 2A: the nos. increase monotonically
		if ( $sucat->{_first_file_number_in} <= $sucat->{_last_file_number_in} )
		{
			for (
				my $file = $sucat->{_first_file_number_in} ;
				$file <= $sucat->{_last_file_number_in} ;
				$file++
			  )
			{

				# CASE 2A-1 there is an input suffix specified by user
				if ( $sucat->{_input_suffix} ne $empty_string ) {

					$sucat->{_Step} =
						$sucat->{_Step} . ' '
					  . $sucat->{_inbound_directory} . '/'
					  . $sucat->{_input_name_prefix}
					  . $file
					  . $sucat->{_input_name_extension} . '.'
					  . $sucat->{_input_suffix};
				}

				# CASE 2A-2 there is no input suffix specified by user
				elsif ( $sucat->{_input_suffix} eq $empty_string ) {

					$sucat->{_Step} =
						$sucat->{_Step} . ' '
					  . $sucat->{_inbound_directory} . '/'
					  . $sucat->{_input_name_prefix}
					  . $file
					  . $sucat->{_input_name_extension};

				}
				else {
					print(" sucat,Step, unexpected input, growing numbers\n");
				}

			}    # end for loop
		}

		# CASE 2B: nos. decrease monotonically
		elsif (
			$sucat->{_first_file_number_in} > $sucat->{_last_file_number_in} )
		{
			print("2. sucat, Step, reverse order assumed\n");

			for (
				my $file = $sucat->{_first_file_number_in} ;
				$file >= $sucat->{_last_file_number_in} ;
				$file = ( $file - 1 )
			  )
			{

				# CASE 2B-1  there is an input suffix specified by user
				if ( $sucat->{_input_suffix} ne $empty_string ) {

					$sucat->{_Step} =
						$sucat->{_Step} . ' '
					  . $sucat->{_inbound_directory} . '/'
					  . $sucat->{_input_name_prefix}
					  . $file
					  . $sucat->{_input_name_extension} . '.'
					  . $sucat->{_input_suffix};
					print("2A-1 sucat,Step,file=$file\n");
				}

				# CASE 2A-2 there is no input suffix specified by user
				elsif ( $sucat->{_input_suffix} eq $empty_string ) {

					$sucat->{_Step} =
						$sucat->{_Step} . ' '
					  . $sucat->{_inbound_directory} . '/'
					  . $sucat->{_input_name_prefix}
					  . $file
					  . $sucat->{_input_name_extension};
					print("2A-2 sucat,Step,file=$file\n");

				}
				else {
					print(
"sucat,Step, unexpected input suffix, decreasing number, case 2A\n"
					);
				}

			}    # end for loop

		}
		else {
			print(
"sucat,Step,case 2B nos. neither increase nor decrease monotnically\n"
			);
		}
	}
	else {
		print("sucat,Step, unexpected list CASES 1 and 2\n");
	}

	return $sucat->{_Step};
}

1;
