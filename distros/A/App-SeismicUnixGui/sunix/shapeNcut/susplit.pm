package App::SeismicUnixGui::sunix::shapeNcut::susplit;

=head2 SYNOPSIS

PERL PROGRAM NAME: susplit.pm

AUTHOR:  

DATE:
V0.2  6.19.23

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

 There are now four cases that susplit can handle:
 
 1. As in the traditional case, the split files are written to 
 the directory perl thinks the code is running .

 2. If a list of su_base_file_names is given (in $DATA_SEISMIC_TXT)
 split files are written to $DATA_SEISMIC_SU.

 3. If an su_base_file_name is given then thesplit files are written
 to $DATA_SEISMIC_SU.

 4. Cases 2 and 3 are exclusive and a warning message is given. 

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUSPLIT - Split traces into different output files by keyword value	

     susplit <stdin >stdout [options]					

 Required Parameters:							

	none								

 Optional Parameters:							

	key=cdp		Key header word to split on (see segy.h)	

	stem=split_	Stem name for output files			

	middle=key	middle of name of output files			

	suffix=.su	Suffix for output files				

	numlength=7	Length of numeric part of filename		

	verbose=0	=1 to echo filenames, etc.			

	close=1		=1 to close files before opening new ones	


 Notes:								

 The most efficient way to use this program is to presort the input data

 into common keyword gathers, prior to using susplit.			"


 Use "suputgthr" to put SU data into SU data directory format.	


 Credits:

	Geocon: Garry Perratt hacked together from various other codes

=head2 CHANGES and their DATES

V0.0.2 06.13.23

Normally susplit writes divided files into the local directory.
Now, split files are automatically moved into $the DATA_SEISMICS_SU
directory.

Normally, susplit input consists of a single file. Now, user can
enter the name of a list containing more than one file. Now,
susplit will iterate over each file with the same general instructions.

Now, there is no need to use a data_in or data_out module. Now, susplit
handles input and output internally.

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use App::SeismicUnixGui::misc::L_SU_global_constants;
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to
  $suffix_ascii $off $suffix_su $suffix_txt $txt $suffix_bin);
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use App::SeismicUnixGui::configs::big_streams::Project_config;
use Cwd;

=head2 instantiation of packages

=cut

my $get     = App::SeismicUnixGui::misc::L_SU_global_constants->new();
my $control = control->new();
my $Project = App::SeismicUnixGui::configs::big_streams::Project_config->new();
my $readfiles = readfiles->new();

my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();

#my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

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

my $susplit = {
	_close                     => '',
	_data_type                 => '',
	_inbound_list              => '',
	_inbound_su_base_file_name => '',
	_key                       => '',
	_middle                    => '',
	_numlength                 => '',
	_stem                      => '',
	_suffix                    => '',
	_verbose                   => '',
	_Step                      => '',
	_note                      => '',

};

$susplit->{_data_type} = $default;

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name
move output data into the DATA_SEISMIC_UNIX directory

=cut

sub Step {

	my ($self) = @_;

	if (    length $susplit->{_inbound_list}
		and not length $susplit->{_inbound_su_base_file_name}
		and length $susplit->{_close}
		and length $susplit->{_key}
		and length $susplit->{_numlength}
		and length $susplit->{_stem}
		and length $susplit->{_suffix}
		and length $susplit->{_verbose} )
	{
		my $file_num;
		my @step;
		my @inbound;
		my $first_step;
		my $last_step;
		my $step;

		my ( $array_ref, $num_files ) = _get_file_names();
		my @file            = @$array_ref;
		my $penultimate_idx = $num_files - 2;
		my $last_idx        = $num_files - 1;

		# print("susplit, Step, num_files=$num_files\n");
		# print("susplit, Step, names=@file\n");

		my $close     = $susplit->{_close};
		my $key       = $susplit->{_key};
		my $stem      = $susplit->{_stem};
		my $middle    = $susplit->{_middle};
		my $numlength = $susplit->{_numlength};
		my $suffix    = $susplit->{_suffix};
		my $verbose   = $susplit->{_verbose};

		# All cases when num_files >=0
		if ( $num_files >= 1 ) {

			$inbound[0] = $DATA_SEISMIC_SU . '/' . $file[0]. $suffix_su;
			print("susplit,Step,first_file=$inbound[0]\n");

			$first_step =
				" susplit close=$close "
			  . "key=$key stem=$stem middle=$middle numlength=$numlength "
			  . "suffix=$suffix verbose=$verbose < $inbound[0] ";
		}

	    if ($num_files == 2) {
	    	
	    	$inbound[1] = $DATA_SEISMIC_SU . '/' . $file[1].$suffix_su;
			# print(" last name = $inbound[1]\n");
			
			$last_step =
				" susplit close=$close "
			  . "key=$key stem=$stem middle=$middle numlength=$numlength "
			  . "suffix=$suffix verbose=$verbose < $inbound[1]";
			  
			$step = $first_step . ";" . $last_step;
	    	
	    }
	    
		if ( $num_files > 2 ) {	  
			
			my $temp_step;
					
			$inbound[$last_idx] = $DATA_SEISMIC_SU . '/' . $file[$last_idx].$suffix_su;
			# print(" last name = $inbound[$last_idx]\n");
				
			$last_step =
				" susplit close=$close "
			  . "key=$key stem=$stem middle=$middle numlength=$numlength "
			  . "suffix=$suffix verbose=$verbose < $inbound[$last_idx]";  

			for ( my $i = 1, ; $i <= $penultimate_idx ; $i++ ) {
				$inbound[$i] =
				  $DATA_SEISMIC_SU . '/' . $file[$i]. $suffix_su;
		          # print("Step, num_files>1;$inbound[$i]\n");
		          
				# for the remaining files
				$temp_step =
					$temp_step . ";"
				  . " susplit close=$close "
				  . "key=$key stem=$stem middle=$middle numlength=$numlength "
				  . "suffix=$suffix verbose=$verbose < $inbound[$i]";
			}

			$step = $first_step . $temp_step . ";" . $last_step;
		}

		if ($num_files == 1) {
			
			$step = $first_step . ";" . "mv *$stem$middle* $DATA_SEISMIC_SU ";
			
		} else{
			$step = $step . ";" . "mv *$stem$middle* $DATA_SEISMIC_SU ";
		}

		$susplit->{_Step} = $step;

		return ( $susplit->{_Step} );

	}
	elsif ( not length $susplit->{_inbound_list}
		and length $susplit->{_inbound_su_base_file_name}
		and length $susplit->{_key} )
	{

		my $name = $susplit->{_inbound_su_base_file_name};

		# CASE of a single data file without a list, and without
		# use of data_in module
		# print("CASE without data_in module\n");
		$susplit->{_Step} = 'susplit' . $susplit->{_Step} . " < $name";

		$susplit->{_Step} = $susplit->{_Step} . ";"
		  . "mv *$susplit->{_stem}$susplit->{_middle}* $DATA_SEISMIC_SU ";

		return ( $susplit->{_Step} );
	}
	elsif ( not length $susplit->{_inbound_list}
		and not length $susplit->{_inbound_su_base_file_name}
		and length $susplit->{_key} )
	{

		# traditional use, with data_in module, and outputs
		# to the current directory in perl space
		$susplit->{_Step} = 'susplit' . $susplit->{_Step};
		$susplit->{_Step} = $susplit->{_Step};

		return ( $susplit->{_Step} );

	}
	elsif ( length $susplit->{_inbound_list}
		and length $susplit->{_inbound_su_base_file_name}
		and length $susplit->{_key} )
	{

		print(
			"susplit, Step, either list or su_base_file_name are redundant \n");

	}
	else {
		print(
"susplit, Step, missing parameter(s) e.g., list,su_base_file_name,key,suffix\n"
		);
	}
}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$susplit->{_note} = 'susplit' . $susplit->{_note};
	return ( $susplit->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$susplit->{_close}        = '';
	$susplit->{_key}          = '';
	$susplit->{_inbound_list} = '',
	$susplit->{_inbound_su_base_file_name} = '',
	$susplit->{_middle} = '';
	$susplit->{_numlength} = '';
	$susplit->{_stem}      = '';
	$susplit->{_suffix}    = '';
	$susplit->{_verbose}   = '';
	$susplit->{_Step}      = '';
	$susplit->{_note}      = '';
}

=head2 _check4inbound_listNkey

=cut

sub _check4inbound_listNdata {
	my ($self) = @_;

	if (   $susplit->{_data_type} eq $txt
		&& length $susplit->{_inbound_list}
		&& length $susplit->{_inbound_su_base_file_name} )
	{
		#NADA,
		print(
			"susplit,$susplit->{_inbound_list} = $susplit->{_inbound_list}\n");
	}
	else {
		print(
			"susplit, _check4inbound_list, missing list or su_base_file_name\n"
		);
	}
	return ();
}

sub _get_file_names {
	my ($self) = @_;

	if ( length $susplit->{_inbound_list} ) {

		my $inbound_list = $susplit->{_inbound_list};

		#		$control->set_back_slashBgone($inbound_list);
		#		$inbound_list = $control->get_back_slashBgone();

		my ( $array_ref, $num_files ) = $readfiles->cols_1p($inbound_list);
		my $result_a = $array_ref;
		my $result_b = $num_files;

		#		print("_get_file_names, names=@$array_ref\n");
		return ( $result_a, $result_b );

	}
	else {
		print("_get_file_names, missing inbound\n");
		return ();
	}

}

sub _set_inbound {
	my ($self) = @_;

	if ( length $susplit->{_inbound_su_base_file_name} ) {

		my $inbound = $susplit->{_inbound_su_base_file_name};

		$control->set_back_slashBgone($inbound);
		$inbound = $control->get_back_slashBgone();
		$susplit->{_inbound} = $inbound;

		#        print("susplit,_set_inbound, susplit->{_inbound}=$inbound\n");

	}
	else {
		print("_set_inbound, missing  su_base_file_name\n");
		return ();
	}

}

sub _set_inbound_list {
	my ($self) = @_;

	if ( length $susplit->{_inbound_list} ) {

		my $inbound_list = $susplit->{_inbound_list};
		$control->set_back_slashBgone($inbound_list);
		$inbound_list = $control->get_back_slashBgone();
		$susplit->{_inbound_list} = $inbound_list;

	}
	else {
		print("_set_inbound_list, missing list\n");
		return ();
	}

}

=head2 sub close 


=cut

sub close {

	my ( $self, $close ) = @_;
	if ( $close ne $empty_string ) {

		$susplit->{_close} = $close;
		$susplit->{_note}  = $susplit->{_note} . ' close=' . $susplit->{_close};
		$susplit->{_Step}  = $susplit->{_Step} . ' close=' . $susplit->{_close};

	}
	else {
		print("susplit, close, missing close,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$susplit->{_key}  = $key;
		$susplit->{_note} = $susplit->{_note} . ' key=' . $susplit->{_key};
		$susplit->{_Step} = $susplit->{_Step} . ' key=' . $susplit->{_key};

	}
	else {
		print("susplit, key, missing key,\n");
	}
}

=head2 sub list

 list array

=cut

sub list {
	my ( $self, $list ) = @_;

	if ( length $list ) {

		$susplit->{_inbound_list} = $list;

		#		_check4inbound_list();
		_set_inbound_list();

		#		print("susplit,list; inbound list is $susplit->{_inbound_list}\n\n");

	}
	else {
		print("susplit, list, missing list,\n");
	}
	return ();
}

=head2 sub middle 


=cut

sub middle {

	my ( $self, $middle ) = @_;
	if ( $middle ne $empty_string ) {

		$susplit->{_middle} = $middle;
		$susplit->{_note} =
		  $susplit->{_note} . ' middle=' . $susplit->{_middle};
		$susplit->{_Step} =
		  $susplit->{_Step} . ' middle=' . $susplit->{_middle};

	}
	else {
		print("susplit, middle, missing middle,\n");
	}
}

=head2 sub numlength 


=cut

sub numlength {

	my ( $self, $numlength ) = @_;
	if ( $numlength ne $empty_string ) {

		$susplit->{_numlength} = $numlength;
		$susplit->{_note} =
		  $susplit->{_note} . ' numlength=' . $susplit->{_numlength};
		$susplit->{_Step} =
		  $susplit->{_Step} . ' numlength=' . $susplit->{_numlength};

	}
	else {
		print("susplit, numlength, missing numlength,\n");
	}
}

=head2 sub stem 


=cut

sub stem {

	my ( $self, $stem ) = @_;
	if ( $stem ne $empty_string ) {

		$susplit->{_stem} = $stem;
		$susplit->{_note} = $susplit->{_note} . ' stem=' . $susplit->{_stem};
		$susplit->{_Step} = $susplit->{_Step} . ' stem=' . $susplit->{_stem};

	}
	else {
		print("susplit, stem, missing stem,\n");
	}
}

=head2 sub su_base_file_name

 su_base_file_name

=cut

sub su_base_file_name {
	my ( $self, $su_base_file_name ) = @_;

	if ( length $su_base_file_name ) {

		$susplit->{_su_base_file_name} = $su_base_file_name;
		$susplit->{_note} =
			$susplit->{_note}
		  . ' su_base_file_name='
		  . $susplit->{_su_base_file_name};

		$susplit->{_inbound_su_base_file_name} = $su_base_file_name;

		#		_check4inbound_listNkey();
		#		_set_inbound();

		# print("susplit,su_base_file_name is $susplit->{_su_base_file_name}\n\n");

	}
	else {
		print("susplit, su_base_file_name, missing \n");
	}
	return ();
}

=head2 sub suffix 


=cut

sub suffix {

	my ( $self, $suffix ) = @_;
	if ( $suffix ne $empty_string ) {

		$susplit->{_suffix} = $suffix;
		$susplit->{_note} =
		  $susplit->{_note} . ' suffix=' . $susplit->{_suffix};
		$susplit->{_Step} =
		  $susplit->{_Step} . ' suffix=' . $susplit->{_suffix};

	}
	else {
		print("susplit, suffix, missing suffix,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$susplit->{_verbose} = $verbose;
		$susplit->{_note} =
		  $susplit->{_note} . ' verbose=' . $susplit->{_verbose};
		$susplit->{_Step} =
		  $susplit->{_Step} . ' verbose=' . $susplit->{_verbose};

	}
	else {
		print("susplit, verbose, missing verbose,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 8;

	return ($max_index);
}

1;
