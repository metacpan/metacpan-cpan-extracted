package App::SeismicUnixGui::developer::code::sunix::update;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PROGRAM NAME:  update.pm							

 AUTHOR: Juan Lorenzo
 DATE:   September 4 2021 V 0.1
 DESCRIPTION: minor changes to 
 program_config.pm
 program_spec.pm
 and program.pm files

=head2 USE

=head3 NOTES

=head4 Examples

=head3 NOTES

 	Program group array and the directory names:
 		
$developer_sunix_categories[0]  = 'data';
$developer_sunix_categories[1]  = 'datum';
$developer_sunix_categories[2]  = 'plot';
$developer_sunix_categories[3]  = 'filter';
$developer_sunix_categories[4]  = 'header';
$developer_sunix_categories[5]  = 'inversion';
$developer_sunix_categories[6]  = 'migration';
$developer_sunix_categories[7]  = 'model';
$developer_sunix_categories[8]  = 'NMO_Vel_Stk';
$developer_sunix_categories[9]  = 'par';
$developer_sunix_categories[10] = 'picks';
$developer_sunix_categories[11] = 'shapeNcut';
$developer_sunix_categories[12] = 'shell';
$developer_sunix_categories[13] = 'statsMath';
$developer_sunix_categories[14] = 'transform';
$developer_sunix_categories[15] = 'well';
$developer_sunix_categories[16] = '';
  	
 	QUESTION 1:
Which group number do you want to use to update
for *.pm, *.config, and *_spec.pm files ?

e.g., for transforms use:
$group_number = 15

QUESTION 2:
Which program do you want to work on?

For example=
'sugetgthr';
'sugain';
'suputgthr';
'suifft';
'sufctanismod'
'vel2stiff
'unif2aniso'
'transp'
'suflip'


	my $program_name = 'suhistogram';

=head2 CHANGES and their DATES
Feb. 2022
V0.2
read a file with spec-file modifications:
label_number numbers and suffix_types

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 private hash

=cut

my $update = {
	_directory                   => '',
	_program_name                => '',
	_spec_changes_base_file_name => '',
	_spec_label_number_aref      => '',
	_spec_suffix_type_aref       => '',
	_group_number                => '',
	_start_binding_index_line    => '',
	_end_binding_index_line      => '',
	_start_file_dialog_type_line => '',
	_end_file_dialog_type_line   => '',
	_start_prefix_line           => '',
	_end_prefix_line             => '',
	_start_suffix_line           => '',
	_end_suffix_line             => '',
};

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($bin $dat $pl $ps $segb $segd $segy $sgy $su $suffix_bin $suffix_ps
  $suffix_segy $suffix_sgy $suffix_su $suffix_txt $txt $text);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::developer::code::sunix::prog_doc2pm';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sudoc';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package';

=head2 clean memory private hash

=cut

sub clear {

	my ($self) = @_;

	$update->{_directory}                   = '';
	$update->{_program_name}                = '';
	$update->{_spec_changes_base_file_name} = '';
	$update->{_spec_label_number_aref}      = '';
	$update->{_spec_suffix_type_aref}       = '';
	$update->{_group_number}                = '';
	$update->{_start_binding_index_line}    = '';
	$update->{_end_binding_index_line}      = '';
	$update->{_start_file_dialog_type_line} = '';
	$update->{_end_file_dialog_type_line}   = '';
	$update->{_start_prefix_line}           = '';
	$update->{_end_prefix_line}             = '';
	$update->{_start_suffix_line}           = '';
	$update->{_end_suffix_line}             = '';

}

=head2 sub _get_spec_changes

label_number values,
directory types
suffix types

=cut

sub _get_spec_changes {
	my ($self) = @_;

	if (    length $update->{_program_name} && length $update->{_group_number}
		and length $update->{_spec_changes_base_file_name} )
	{

		my $spec_changes_base_file_name =
		  $update->{_spec_changes_base_file_name};

=head2 instantiation of packages

=cut

		my $file        = manage_files_by2->new();
		my $prog_doc2pm = prog_doc2pm->new();
		my $get         = L_SU_global_constants->new();

		my $var          = $get->var();
		my $on           = $var->{_on};
		my $off          = $var->{_off};
		my $true         = $var->{_true};
		my $false        = $var->{_false};
		my $empty_string = $var->{_empty_string};
		my $path_in      = $prog_doc2pm->get_path_in();
		my $program_name = $update->{_program_name};
		my $group_number = $update->{_group_number};

=head21 Declare

variables
=cut

		my ($directory_type_aref);
		my ( @directory_type, @prefix_spec, @suffix_spec );
		$directory_type_aref = \@directory_type;
		my $inbound =
		  $path_in . '/' . $spec_changes_base_file_name . $suffix_txt;

		my $spacer            = " ";
		my $aref              = $file->read_2cols_aref( $inbound, $spacer );
		my @array             = @$aref;
		my $label_number_aref = $array[0];
		my @label_number      = @$label_number_aref;
		my $suffix_type_aref  = $array[1];
		my @suffix_type       = @$suffix_type_aref;
		my $label_number_of   = scalar @label_number;

		for ( my $i = 0 ; $i < $label_number_of ; $i++ ) {

			#			print( "update, _get_spec_changes, $suffix_spec[0] \n");
			#			print( "update, _get_spec_changes, $prefix_spec[0] \n");

			if ( $suffix_type[$i] eq $bin ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_BIN' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_bin';");

			}
			elsif ( $suffix_type[$i] eq $dat ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_DAT' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_dat';");

			}
			elsif ( $suffix_type[$i] eq $pl ) {

				$prefix_spec[$i] = (" '\$PL_SEISMIC' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '';");

			}
			elsif ( $suffix_type[$i] eq $txt ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_TXT' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_txt';");

			}
			elsif ( $suffix_type[$i] eq $text ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_TXT' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_txt';");

			}
			elsif ( $suffix_type[$i] eq $segd ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_SEGD' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_segd';");

			}
			elsif ($suffix_type[$i] eq $segy
				|| $suffix_type[$i] eq $sgy )
			{

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_SEGY' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_segy';");

			}
			elsif ( $suffix_type[$i] eq $su ) {

				$prefix_spec[$i] = (" '\$DATA_SEISMIC_SU' . \".'/'.\";");
				$suffix_spec[$i] = (" ''.'' . '\$suffix_su';");

			}

			else {
				print("update, _get_spec_changes, unexpected variable \n");
			}

		}

#		print( "update, _get_spec_changes, label_number_nos = @label_number, suffixes= @suffix_type \n"
#		);

		my $suffix_spec_aref = \@suffix_spec;
		my $prefix_spec_aref = \@prefix_spec;
		my @out_array =
		  ( $suffix_spec_aref, $prefix_spec_aref, $label_number_aref );
		my $result = \@out_array;

		return ($result);

	}
	else {
		print(
			"update, _get_spec_changes, missing program name or group number\n"
		);
	}

	return ();

}

=head2 sub set_program 

QUESTIONS:
Which group number do you want ?
What program do you want?

=cut

sub set_program {
	my ( $self, $program_name, $group_number ) = @_;

	print(
"update, set_program , group_number category=$group_number, program_name=$program_name\n"
	);

	if (   length $program_name
		&& length $group_number )
	{

		$update->{_program_name} = $program_name;
		$update->{_group_number} = $group_number;

#		print(
#"update, set_program, group_number category=$group_number, program_name=$program_name\n"
#		);

	}
	else {
		print("update, set_program, missing program name or group number\n");
	}

	return ();

}

=head2 sub set_spec_changes

label_number values,
directory types
suffix types

=cut

sub set_spec_changes {
	my ($self) = @_;

	if (    length $update->{_program_name} && length $update->{_group_number}
		and length $update->{_spec_changes_base_file_name} )
	{

		my $sudoc       = sudoc->new();
		my $prog_doc2pm = prog_doc2pm->new();

		my (@path_in4specs);
		my ( @spec_file_in, @spec_inbound );

		my $program_name = $update->{_program_name};
		my $group_number = $update->{_group_number};
		$prog_doc2pm->set_group_directory($group_number);
		$path_in4specs[0] = $prog_doc2pm->get_path_out4specs();

=head2 define

search lines

=cut

		my ( $start_binding_index_line,    $end_binding_index_line );
		my ( $start_file_dialog_type_line, $end_file_dialog_type_line );
		my ( $start_prefix_line,           $end_prefix_line );
		my ( $start_suffix_line,           $end_suffix_line );

		my $start_binding_index_line2find = '# e.g., first binding index \(index=0\)';
		my $end_binding_index_line2find   = '= 8; # outbound item is  bound';
		my $end_file_dialog_type_line2find =
		  '#	\$type\[\$index\[2\]\]	=  \$file_dialog_type->\{_Data\};';
		my $start_file_dialog_type_line2find =
		  '# bound index will look for data';
		my $start_prefix_line2find = 'sub prefix_aref \{';
		my $end_prefix_line2find =
		  '\t# label 9 in GUI is input zz_file and needs a home directory';
		my $end_suffix_line2find =
		  '#	\$suffix\[ \$index\[2\] \] = \'\'.\'\' . \'\$suffix_su\';';
		my $start_suffix_line2find = 'sub suffix_aref \{';

=head2 import 

from program_spec_changes.txt file

=cut

		my $changes_aref      = _get_spec_changes();
		my @changes           = @$changes_aref;
		my $prefix_spec_aref  = $changes[1];
		my $suffix_spec_aref  = $changes[0];
		my $label_number_aref = $changes[2];

		$spec_file_in[0] = $program_name . '_spec.pm';
		$spec_inbound[0] = $path_in4specs[0] . '/' . $spec_file_in[0];

=head2 Q. What range of lines remain to change in the spec file?

  Step A: Start by reading in package file (
 "program"_spec.pm)

=cut

		$sudoc->set_file_in_sref( \$spec_file_in[0] );
		$sudoc->set_perl_path_in( $path_in4specs[0] );

		# slurp the whole file
		$sudoc->whole();
		my $whole_aref = $sudoc->get_whole();

		my $length_of_slurp = scalar @{$whole_aref};
		my @slurp           = @{$whole_aref};

=head2 STEP B: Follow by  finding the following

  ranges of lines:
3)There are lines for prefixes
4)There are lines for suffixes
1)There are lines where there are interactive label_numbers
2) There are lines for data types

my $line_range4data_type =
my $line_range4prefix	=
my $line_range4suffix	=
my $line_range4index	=

my change4data_standard = 
my change4prefix_standard    = 
my change4suffix_standard    = 

my $additional_data_change   	=
my $additional_prefix_change   	=
my $additional_suffix_change  	=

=cut

		for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

#			print("update,All sunix documentation $slurp[$i]\n");

			my $string = $slurp[$i];

			if ( $string =~ /$start_binding_index_line2find/ ) {

				$start_binding_index_line = $i + 4;

   #		 		print("update,
   #		 a spec success at start_binding_index_line: $start_binding_index_line \n"
   #		 				);
			}

			if ( $string =~ /$end_binding_index_line2find/ ) {

				$end_binding_index_line = $i + 3;

   #	   		 				print("update,
   #	   		 a spec success at end_binding_index_line: $end_binding_index_line \n"
   #	   		 				);
			}

			if ( $string =~ /$start_file_dialog_type_line2find/ ) {

				$start_file_dialog_type_line = $i + 2;

#				print(
#"update, a spec success at start_file_dialog_type_line:$start_file_dialog_type_line \n"
#				);
			}

			if ( $string =~ /$end_file_dialog_type_line2find/ ) {

				$end_file_dialog_type_line = $i + 3;

#				print(
#"update, a spec success at end_file_dialog_type_line:$end_file_dialog_type_line \n"
#				);
			}
			if ( $string =~ /$start_prefix_line2find/ ) {

				$start_prefix_line = $i + 13;

 #						  	print(
 #						  		"update, a spec success at start_prefix_line: $start_prefix_line \n"
 #						  	);
			}

			if ( $string =~ /$end_prefix_line2find/ ) {

				$end_prefix_line = $i + 3;

				print(
"update, a spec success at end_prefix_line: $end_prefix_line \n"
				);
			}

			if ( $string =~ /$start_suffix_line2find/ ) {

				$start_suffix_line = $i + 13;

# 							print(
# 							   "update, a spec success at start_suffix_line: $start_suffix_line \n"
# 							);
			}

			if ( $string =~ /$end_suffix_line2find/ ) {

				$end_suffix_line = $i + 3;

				print(
"update, a spec success at end_suffix_line:$end_suffix_line \n"
				);
			}
		}

		my @result = (
			$start_binding_index_line,    $end_binding_index_line,
			$start_file_dialog_type_line, $end_file_dialog_type_line,
			$start_prefix_line,           $start_suffix_line,
			$end_suffix_line,             $end_prefix_line
		);

		$update->{_start_binding_index_line}    = $start_binding_index_line;
		$update->{_end_binding_index_line}      = $end_binding_index_line;
		$update->{_start_file_dialog_type_line} = $start_file_dialog_type_line;
		$update->{_end_file_dialog_type_line}   = $end_file_dialog_type_line;
		$update->{_start_prefix_line}           = $start_prefix_line;
		$update->{_start_suffix_line}           = $start_suffix_line;
		$update->{_end_suffix_line}             = $end_suffix_line;
		$update->{_end_prefix_line}             = $end_prefix_line;

		return ();

	}
	else {
		print(
			"update, set_spec_changes, missing program name or group number\n");
		return ();
	}

}

=head2 sub set_spec_changes_base_file_name

file name where the following
changes can be found:
label_number values
directory types
suffix types

=cut

sub set_spec_changes_base_file_name {
	my ( $self, $spec_changes_base_file_name ) = @_;

	if ( length $update->{_program_name} && length $update->{_group_number}
		and $spec_changes_base_file_name )
	{

		$update->{_spec_changes_base_file_name} = $spec_changes_base_file_name;

		print(
"update, set_spec_changes_base_file_name,spec_changes_base_file_name=$spec_changes_base_file_name\n"
		);

	}
	else {
		print(
"update, set_spec_changes_base_file_name, missing program name or group number\n"
		);
	}

	return ();

}

sub set_changes {

	my ($self) = @_;

	if (   length $update->{_program_name}
		&& length $update->{_group_number} )
	{

		my $get         = L_SU_global_constants->new();
		my $sudoc       = sudoc->new();
		my $package     = sunix_package->new();
		my $prog_doc2pm = prog_doc2pm->new();

		my $var   = $get->var();
		my $true  = $var->{_true};
		my $false = $var->{_false};

		my (@file_in);
		my ($i);
		my @file;
		my (
			@path_out4configs, @path_out4developer,
			@path_out4specs,   @path_out4sunix
		);
		my (
			@path_in4configs, @path_in4developer,
			@path_in4specs,   @path_in4sunix
		);
		my ( @path_in4global_constants, @path_out4global_constants );
		my $package_name;
		my (
			@config_file_in, @config_file_out, @pm_file_in,
			@pm_file_out,    @spec_file_in,    @spec_file_out
		);
		my ( @global_constants_file_in, @global_constants_file_out );
		my (
			@config_inbound, @config_outbound, @pm_inbound,
			@pm_outbound,    @spec_inbound,    @spec_outbound
		);
		my ( @global_constants_inbound,     @global_constants_outbound );
		my ( @line_global_constant_success, @line_terminator_success );
		my $whole_aref;
		my @slurp;
		my @program_list;
		my $max_index;
		my ( $index_start_extraction, $index_end_extraction );
		my $length;
		my $length_of_slurp;
		my $spec_replacement_success  = $false;
		my $sunix_replacement_success = $false;
		my $global_constant_success   = $false;
		my $terminator_match_success  = $false;
		my $L_SU_global_constants     = 'L_SU_global_constants';
		my ( $program_name, $group_number );

		$program_name = $update->{_program_name};
		$group_number = $update->{_group_number};

		$prog_doc2pm->set_group_directory($group_number);
		my @developer_sunix_category =
		  @{ $get->developer_sunix_categories_aref() };
		my $sunix_category = $developer_sunix_category[$group_number];

=head2 private values

=cut

		my $path_in     = $prog_doc2pm->get_path_in();
		my $list_length = $prog_doc2pm->get_list_length();

		$path_out4developer[0] = $prog_doc2pm->get_path_out4developer();

		$path_out4configs[0] = $prog_doc2pm->get_path_out4configs();
		$path_out4specs[0]   = $prog_doc2pm->get_path_out4specs();
		$path_out4sunix[0]   = $prog_doc2pm->get_path_out4sunix();

		$path_in4configs[0] = $prog_doc2pm->get_path_out4configs();
		$path_in4specs[0]   = $prog_doc2pm->get_path_out4specs();
		$path_in4sunix[0]   = $prog_doc2pm->get_path_out4sunix();

		$path_out4global_constants[0] =
		  $prog_doc2pm->get_path_out4global_constants();
		$path_in4global_constants[0] =
		  $prog_doc2pm->get_path_out4global_constants();

=head2 path definitions

=cut

		$package_name                 = $program_name;
		$pm_file_out[0]               = $package_name . '.pm';
		$config_file_out[0]           = $package_name . '.config';
		$spec_file_out[0]             = $package_name . '_spec.pm';
		$global_constants_file_out[0] = $L_SU_global_constants . '.pm';

		$pm_file_in[0]               = $package_name . '.pm';
		$config_file_in[0]           = $package_name . '.config';
		$spec_file_in[0]             = $package_name . '_spec.pm';
		$global_constants_file_in[0] = $L_SU_global_constants . '.pm';

		$pm_inbound[0]     = $path_in4sunix[0] . '/' . $pm_file_in[0];
		$config_inbound[0] = $path_in4configs[0] . '/' . $config_file_in[0];
		$spec_inbound[0]   = $path_in4specs[0] . '/' . $spec_file_in[0];
		$global_constants_inbound[0] =
		  $path_in4global_constants[0] . '/' . $global_constants_file_in[0];

		$pm_outbound[0] = $path_out4sunix[0] . '/' . $package_name . '.pm';
		$config_outbound[0] =
		  $path_out4configs[0] . '/' . $package_name . '.config';
		$spec_outbound[0] =
		  $path_out4specs[0] . '/' . $package_name . '_spec.pm';
		$global_constants_outbound[0] =
		  $path_out4global_constants[0] . '/' . $global_constants_file_in[0];

#$global_constants_outbound[1] = $path_out4global_constants[0] . '/' . $global_constants_file_in[0].'_2';

=head2 QUESTION 1:

What max_index value do you want to insert?
1. Read number of lines in the 
program_config.pm file

slurp config file to get the line number
where "max_index" line" is found

=cut

		open( FILE, "< $config_inbound[0]" )
		  or die "can't open $config_inbound[0]: $!";
		$length_of_slurp++ while <FILE>;
		close(FILE);

		# $count now holds the number of lines read
		print("number of lines read from config_file = $length_of_slurp \n");
		$max_index = $length_of_slurp - 1;

=cut

=head3 name definitions 
	for locating lines,
	word replacements,
	and "max_index" substitution

=cut

		my $global_constants_string_to_find =
		  ("my \@sunix_$sunix_category\_programs");
		my $terminator_to_find = '\);';

		my $spec_string_to_find = 'my \$max_index = # Insert a number here';
		my $spec_replacement_string =
		  ("my \$max_index           = $max_index;");

		my $sunix_string_to_find     = 'my \$max_index = 36;';
		my $sunix_replacement_string = ("\tmy \$max_index = $max_index;");

=head2 Updating spec_files

=cut

		if (   length $package_name
			&& ( -e $spec_inbound[0] )
			&& ( -e $spec_outbound[0] ) )
		{

		#			print("update, I am in group=$group_number \n");
		#			print("update, I am working on package =$package_name \n");
		#			print("update, updating $spec_file_out[0] in $path_out4specs[0]\n");

=head2 Read in package file (
 "program"_spec.pm)

=cut

			$sudoc->set_file_in_sref( \$spec_file_in[0] );
			$sudoc->set_perl_path_in( $path_in4specs[0] );

			# slurp the whole file
			$sudoc->whole();
			my $whole_aref = $sudoc->get_whole();

			my $length_of_slurp = scalar @{$whole_aref};

			#			print("update,num_lines in spec file= $length_of_slurp\n");
			#	for ( my $i = 0; $i < $length_of_slurp; $i++ ) {
			#		print("update,All sunix documentation @{$whole_aref}[$i]\n");
			#	}

			my @slurp = @{$whole_aref};

			for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

				#		print("update,All sunix documentation $slurp[$i]\n");

				my $string = $slurp[$i];

				# print("update, string to search:$slurp[$i]\n");

				if ( $string =~ /$spec_string_to_find/ ) {

					#					print("a spec success\n");

					$slurp[$i] = $spec_replacement_string;

					print("update, \n $slurp[$i]\n");

					$spec_replacement_success = $true;

				}

			}

			if ($spec_replacement_success) {

				#	Write out the corrected file
				print("writing out to  $spec_outbound[0]\n");

				open( OUT, ">$spec_outbound[0]" )
				  or die("File  $spec_outbound[0] not found");

				for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

					print("$slurp[$i]\n");
					print OUT $slurp[$i] . "\n";

				}
				close(OUT);

			}
			else {
				print("update, spec string replacement unsuccessful\n");
			}
			#
		}
		else {
			print "update: a \"spec\" file is missing!\n";
		}    # for a selected program name in the group

=head2 Updating sunix.pm files

=cut

		if (   length $package_name
			&& ( -e $pm_outbound[0] )
			&& ( -e $pm_inbound[0] ) )
		{

			#	print("update, I am in group=$group_number \n");
			#	print("update, I am working on package =$package_name \n");
			#	print("update, updating $pm_file_out[0] in $path_out4sunix[0]\n");

=head2 Read in package file (
 "program".pm)

=cut

			$sudoc->set_file_in_sref( \$pm_file_in[0] );
			$sudoc->set_perl_path_in( $path_in4sunix[0] );

			# slurp the whole file
			$sudoc->whole();
			my $whole_aref = $sudoc->get_whole();

			my $length_of_slurp = scalar @{$whole_aref};

			#		print("update.pl,num_lines= $length_of_slurp\n");
			#		for ( my $i = 0; $i < $length_of_slurp; $i++ ) {
			#			print("update,All sunix documentation @{$whole_aref}[$i]\n");
			#	}

			my @slurp = @{$whole_aref};

			for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

				#		print ("string to find:$sunix_string_to_find\n");
				my $string = $slurp[$i];

				#        print("update, string to search:$slurp[$i]\n");

				if ( $string =~ /$sunix_string_to_find/ ) {

					#			print("a success\n");
					$sunix_replacement_success = $true;
					$slurp[$i] = $sunix_replacement_string;

				}

			}

			if ($sunix_replacement_success) {

				#	Write out the corrected file
				#		print("writing out to  $pm_outbound[0]\n");

				open( OUT, ">$pm_outbound[0]" )
				  or die("File  $pm_outbound[0] not found");

				for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

					#			print("$slurp[$i]\n");
					print OUT $slurp[$i] . "\n";

				}
				close(OUT);

			}
			else {
				print("update, sunix string replacement unsuccessful\n");
			}

		}
		else {
			print "update: an sunix file is missing!\n";
		}    # for a selected program name in the group

=head2 update L_SU_global_constants

=cut

		if (   length $package_name
			&& ( -e $global_constants_inbound[0] )
			&& ( -e $global_constants_outbound[0] ) )
		{

			#	print("update, I am in group=$group_number \n");
			#	print("update, I am working on package =$package_name \n");
			print(
"update, updating  $global_constants_file_in[0] in $path_out4global_constants[0]\n"
			);

=head2 Read in file 
( L_SU_global_constants.pm )

=cut

			$sudoc->set_file_in_sref( \$global_constants_file_in[0] );
			$sudoc->set_perl_path_in( $path_in4global_constants[0] );

			# slurp the whole file
			$sudoc->whole();
			$whole_aref      = $sudoc->get_whole();
			@slurp           = @{$whole_aref};
			$length_of_slurp = scalar @{$whole_aref};

			#	print("update.pl,num_lines= $length_of_slurp\n");
			#	for ( my $i = 0; $i < $length_of_slurp; $i++ ) {
			#
			#		#		print("update,All sunix documentation @{$whole_aref}[$i]\n");
			#	}

  #	print("global_constants_string_to_find=$global_constants_string_to_find\n");
			my @line_success;

			my $count_global_constant = 0;
			my $count_terminator      = 0;

			# find the  starting expression
			for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

				# print("update,$slurp[$i]\n");
				my $string = $slurp[$i];

				#        print("update, string to search:$slurp[$i]\n");

				if ( $string =~ /$global_constants_string_to_find/ ) {

					#			print("a success in finding a global constant\n");
					$line_global_constant_success[$count_global_constant] = $i;
					$count_global_constant++;

					#			print("update, \n $slurp[$i]\n");
					$global_constant_success = $true;

				}

				# find the tail expression ")"
				if ( $string =~ /$terminator_to_find/ ) {

					#	print("a success in finding a terminator\n");
					$line_terminator_success[$count_terminator] = $i;
					$count_terminator++;
					$terminator_match_success = $true;
				}

			}

			my $length_line_terminator_success =
			  scalar @line_terminator_success;

  #	print("length_line_terminator_success = $length_line_terminator_success\n");
			my $length_line_global_constant_success =
			  scalar @line_global_constant_success;

#	print("length_line_global_constant_success= $length_line_global_constant_success\n");

			# find difference between start (one) and the tail ")"
			#  expressions (many)
			if (   $global_constant_success
				&& $terminator_match_success
				&& $count_global_constant == 1 )
			{

				my @differences;
				my $minimum = 1000000;    # very large number
				my $index_of_minimum;
				for ( my $i = 0 ; $i < $length_line_terminator_success ; $i++ )
				{

					$differences[$i] = $line_terminator_success[$i] -
					  $line_global_constant_success[0];

					#			print("update, differences = $differences[$i]\n");

				}

				for ( my $i = 0 ; $i < $length_line_terminator_success ; $i++ )
				{

					if ( $differences[$i] >= 0 ) {

						if ( $differences[$i] < $minimum ) {

							$minimum          = $differences[$i];
							$index_of_minimum = $i;

			#				  					print("update, minimum = $differences[$i]\n");
			#				  					print("update, index_of_minimum = $index_of_minimum\n");

						}
					}

				}

				my $first_index_of_item = $line_global_constant_success[0];
				my $last_index_of_item  = $first_index_of_item + $minimum;

		 #			   		print("update,  first_index_of_item= $first_index_of_item\n");
		 #			   		print("update,  last_index_of_item= $last_index_of_item\n");

	  #		  		for (my $i=$first_index_of_item; $i <= $last_index_of_item; $i++) {
	  #		  			print("update,  sought-after lines=...$slurp[$i]\n");
	  #		  	}

				# extract the lines between the starting and
				#  ending expressions
				$index_start_extraction = $first_index_of_item + 1;
				$index_end_extraction   = $last_index_of_item - 1;
				@program_list =
				  @slurp[ $index_start_extraction .. $index_end_extraction ];

		#			 #		print("update,  program_list= @program_list\n");
		#			 #		print( @slurp[$index_start_extraction ..$index_end_extraction]);

			}
			else {
				print("sudoc2pm, unexpected values \n");
			}

			# Remove the inverted commas around the list terms
			$length = scalar @program_list;

			for ( my $i = 0 ; $i < $length ; $i++ ) {

				# 1. replace: ",space with a space
				$program_list[$i] =~ s/",\s*/\ /g;

	#	     		print("update,  item #$i in program_list=....$program_list[$i]\n");

				# remove white space and first "
				$program_list[$i] =~ s/"//g;

				#remove first white space
				$program_list[$i] =~ s/^\s*//;

				#remove last white space
				$program_list[$i] =~ s/\s*$//;

				# remove potential newlines
				chomp $program_list[$i];

	#	     		print("update,  item #$i in program_list=....$program_list[$i]\n");

			}

			# add a program name to the end of list
			push @program_list, $program_name;

			#			print("2. update,  program_list= @program_list\n");

			# sort alphabetically
			@program_list = sort(@program_list);

			#			print("3. update,  program_list= @program_list\n");

			# prevent duplicates
			my @unique = ();
			my %seen   = ();

			foreach my $elem (@program_list) {

				next if $seen{$elem}++;
				push @unique, $elem;
			}

			my @new_program_list = @unique;

			$length = scalar @new_program_list;
			for ( my $i = 0 ; $i < $length ; $i++ ) {

			 #				print(
			 #				"4. update,  item #$i in program_list=....$program_list[$i]\n"
			 #				);
			 # add commas and inverted commas again
				$new_program_list[$i] =~ s/\ /",\ "/g;

				# put a tab and " at the start of each line
				$new_program_list[$i] = "\t\"" . $new_program_list[$i];

				# put a  ", at the end of each line
				$new_program_list[$i] = $new_program_list[$i] . '",';

			}

			#			print("5. update, new_program_list=$new_program_list[0]\n");
			#			print("5. update, new_program_list=$new_program_list[1]\n");

			# reinsurt new array back into the slurp
			# 1. split slurp into 2 arrays
			# head array
			my @slurp_b4_extraction =
			  @slurp[ 0 .. ( $index_start_extraction - 1 ) ];

			#tail array
			my @slurp_after_extraction =
			  @slurp[ ( $index_end_extraction + 1 ) .. $length_of_slurp ];

			#	print("5.1 update,  slurp_b4_extraction: @slurp_b4_extraction\n");

			# add torso to head
			push @slurp_b4_extraction, @new_program_list;
			my @digested_slurp = @slurp_b4_extraction;

			#	print("5.2 update,  digested_slurp: @digested_slurp\n");

			# add tail to (torso+head)
			push @digested_slurp, @slurp_after_extraction;

			#	print("5.3 update,  digested_slurp: @digested_slurp\n");

			#	Write out the corrected file
			#	print("writing out to  $global_constants_outbound[0] n");
			my $length_digested_slurp = scalar @digested_slurp;

			open( OUT, ">$global_constants_outbound[0] " )
			  or die("File  $global_constants_outbound[0] not found");
			for ( my $i = 0 ; $i < ( $length_digested_slurp - 1 ) ; $i++ ) {

				if ( $digested_slurp[$i] ne "\t" ) {

					#					print(" update,$digested_slurp[$i]\n");
					print OUT $digested_slurp[$i] . "\n";
				}

			}
			close(OUT);
			print(" update,  wrote out a new $global_constants_file_out[0]\n");

		}
		else {
			print "update: a global constants file is missing!\n";
		}    # for a selected global constants file

	}
	else {
		print("update, missing program name or group number\n");
	}

	return ();

}

sub spec_changes {

	my ($self) = @_;

	my $changes_aref = _get_spec_changes();

	if (    length $update->{_program_name} && length $update->{_group_number}
		and length $update->{_spec_changes_base_file_name}
		and length $changes_aref
		and length $update->{_start_binding_index_line}
		and length $update->{_start_prefix_line}
		and length $update->{_start_suffix_line}
		and length $update->{_end_suffix_line}
		and length $update->{_end_prefix_line} )

	{

		my $sudoc       = sudoc->new();
		my $prog_doc2pm = prog_doc2pm->new();
		my ( @path_in4specs, @path_out4specs );
		my ( @spec_file_in, @spec_inbound, @spec_outbound );

		my $program_name = $update->{_program_name};
		my $group_number = $update->{_group_number};
		$prog_doc2pm->set_group_directory($group_number);
		$path_in4specs[0]  = $prog_doc2pm->get_path_out4specs();
		$path_out4specs[0] = $prog_doc2pm->get_path_out4specs();

		$spec_file_in[0] = $program_name . '_spec.pm';
		$spec_inbound[0] = $path_in4specs[0] . '/' . $spec_file_in[0];

		$spec_outbound[0] =
		  $path_out4specs[0] . '/' . $program_name . '_spec.pm';

=head3 Read in 

label_number values,
directory types
suffix types

=cut

		my @changes                    = @$changes_aref;
		my $prefix_spec_aref           = $changes[1];
		my $suffix_spec_aref           = $changes[0];
		my $label_number_aref          = $changes[2];
		my @label                      = @$label_number_aref;
		my $label_number_of            = scalar @$label_number_aref;
		my @suffix_spec                = @$suffix_spec_aref;
		my @prefix_spec                = @$prefix_spec_aref;
		my $line_bump_suffix           = 0;
		my $line_bump_prefix           = 0;
		my $line_bump_binding_index    = 0;
		my $line_bump_file_dialog_type = 0;
		my $new_length_of_slurp;

		my ( @temp_array_suffix,        @temp_array_prefix );
		my ( @temp_array_binding_index, @temp_array_file_dialog_type );

		my $temp_array_length_suffix;
		my $temp_array_length_prefix;
		my $temp_array_length_binding_index;
		my $temp_array_length_file_dialog_type;

		#		print("update, spec_changes, suffix_spec:@$suffix_spec_aref\n");
		print("update, spec_changes, prefix_spec:@$prefix_spec_aref\n");
		print("update, spec_changes, label_number: @$label_number_aref\n");
		print("update, spec_changes, label_number_of: $label_number_of\n");

=head2 Reading in package file (
 "program"_spec.pm)

=cut

		$sudoc->set_file_in_sref( \$spec_file_in[0] );
		$sudoc->set_perl_path_in( $path_in4specs[0] );

		# slurp the whole file
		$sudoc->whole();
		my $whole_aref = $sudoc->get_whole();

		my $length_of_slurp = scalar @{$whole_aref};
		my @slurp           = @{$whole_aref};

=head2 include additional lines
that will allow user to interactively
click on the gui and open the 
appropraate directory in which to 
find a file.  These parameters
are written into the program_spec.pm file

In case new lines are added, keep track
of these lines.

=cut

=head2 add to

suffix_aref lines in *_spec.pm file


=cut

		print(
"1. update, spec_changes, start_suffix_line =$update->{_start_suffix_line}\n"
		);
		print(
"1. update, spec_changes, end_suffix_line =$update->{_end_suffix_line}\n"
		);

		my $start_suffix_line = $update->{_start_suffix_line} - 1;
		my $end_suffix_line   = $update->{_end_suffix_line} - 1;

=head2 save latter portion for addendum 

to suffix_aref

=cut

		$temp_array_length_suffix = $length_of_slurp - $end_suffix_line;

#		print("update,spec_changes, length_of_slurp   = $length_of_slurp\n");
#		print("update,spec_changes, temp_array_length_suffix = $temp_array_length_suffix\n");
		@temp_array_suffix[ 0 .. ( $temp_array_length_suffix - 1 ) ] =
		  @slurp[ $end_suffix_line .. $length_of_slurp ];

		#		print("update,spec_changes, temp_array = @temp_array\n");

=head2  overwrite or add new lines

to suffix_aref

=cut

		$slurp[ ($start_suffix_line) ] =
		  ("\tmy \$index_aref = get_binding_index_aref();");
		$slurp[ ( $start_suffix_line + 1 ) ] =
		  ("\tmy \@index       = \@\$index_aref;");

		# recursively modify *_spec.pm file
		for ( my $i = 0 ; $i < $label_number_of ; $i++ ) {

			#			print("label_number=$label[$i]\n");

			$slurp[ ( $start_suffix_line + ( ( $i + 1 ) * 3 ) ) ] =
			  (
"\t# label $label[$i] in GUI is input/ouput xx_file and needs a home directory"
			  );

			$slurp[ ( $start_suffix_line + ( ( $i + 1 ) * 3 ) + 1 ) ] =
			  ("\t\$suffix[ \$index[$i] ] = $suffix_spec[$i]");

			$slurp[ ( $start_suffix_line + ( ( $i + 1 ) * 3 ) + 2 ) ] = (" ");

		}

=head2 Add saved text lines

to suffix_aref
if we have more than 3 input/output interactions 

=cut			

		if ( $label_number_of > 3 ) {

			$line_bump_suffix = ( $label_number_of - 3 ) * 3;

			my $new_length_of_slurp = $length_of_slurp + $line_bump_suffix;

			my $new_end_suffix_line = $end_suffix_line + $line_bump_suffix + 1;

		  #			print(
		  #				"update, spec_changes,new_length_of_slurp=$new_length_of_slurp\n"
		  #			);
		  #			print(
		  #"update, spec_changes,new_end_suffix_line= $new_end_suffix_line\n"
		  #			);

			@slurp[ ( $new_end_suffix_line - 1 )
			  .. ( $new_length_of_slurp - 1 ) ] =
			  @temp_array_suffix[ 0 .. ( $temp_array_length_suffix - 1 ) ];
		}
		elsif ( $label_number_of <= 3 ) {

			#               NADA;
		}
		else {
			print("update, spec_changes, unexpected value \n");
		}

##########################################################################

=head2 Add lines to

prefix_aref lines in *_spec.pm file
Intentionally start from the end of the *.spec file

=cut

		print(
"update, spec_changes, start_prefix_line =$update->{_start_prefix_line}\n"
		);
		print(
"1. update, spec_changes, end_prefix_line =$update->{_end_prefix_line}\n"
		);
		my $start_prefix_line = $update->{_start_prefix_line} - 1;
		my $end_prefix_line   = $update->{_end_prefix_line} - 1;

=head2 save latter portion for addendum

to prefix_aref

If suffix does not have more than 3 entries the line_bump_* = 0

=cut

		$new_length_of_slurp = $length_of_slurp + $line_bump_suffix;

		$temp_array_length_prefix = $new_length_of_slurp - $end_prefix_line;

#		print("update,spec_changes, new_length_of_slurp   = $new_length_of_slurp\n");
#		print("update,spec_changes, prefix_aref temp_array_length_prefix = $temp_array_length_prefix\n");
		@temp_array_prefix[ 0 .. ( $temp_array_length_prefix - 1 ) ] =
		  @slurp[ $end_prefix_line .. $new_length_of_slurp ];

	  #		print("update,spec_changes, temp_array_prefix = @temp_array_prefix\n");

		$slurp[ ($start_prefix_line) ] =
		  ("\tmy \$index_aref = get_binding_index_aref();");
		$slurp[ ( $start_prefix_line + 1 ) ] =
		  ("\tmy \@index       = \@\$index_aref;");

		# recursively modify *_spec.pm file
		for ( my $i = 0 ; $i < $label_number_of ; $i++ ) {

		   #			print("update, spec_changes, L 1365, label_number=$label[$i]\n");

			$slurp[ ( $start_prefix_line + ( ( $i + 1 ) * 3 ) ) ] =
			  (
"\t# label $label[$i] in GUI is input/output xx_file and needs a home directory"
			  );

			$slurp[ ( $start_prefix_line + ( ( $i + 1 ) * 3 ) + 1 ) ] =
			  ("\t\$prefix[ \$index[$i] ] = $prefix_spec[$i]");

			$slurp[ ( $start_prefix_line + ( ( $i + 1 ) * 3 ) + 2 ) ] =
			  (" ");

		}

=head2 Add saved text lines

to prefix_aref
if we have more than 3 input/output interactions 

=cut			

		if ( $label_number_of > 3 ) {

			$line_bump_prefix = ( $label_number_of - 3 ) * 3;

			my $new_length_of_slurp =
			  $length_of_slurp + $line_bump_suffix + $line_bump_prefix;

			my $new_end_prefix_line = $end_prefix_line + $line_bump_prefix + 1;

#			print(
#				"update, spec_changes,new_length_of_slurp, prefix_aref=$new_length_of_slurp\n"
#			);
#			print(
#"update, spec_changes,new_end_prefix_line= $new_end_prefix_line\n"
#			);

			@slurp[ ( $new_end_prefix_line - 1 )
			  .. ( $new_length_of_slurp - 1 ) ] =
			  @temp_array_prefix[ 0 .. ( $temp_array_length_prefix - 1 ) ];
		}
		elsif ( $label_number_of <= 3 ) {

			#               NADA;
		}
		else {
			print("update, spec_changes, for prefix_aref unexpected value \n");
		}

###############################################################################

=head2 add to

sub file_dialog_type_aref lines in *_spec.pm file

=cut

		my $start_file_dialog_type_line =
		  $update->{_start_file_dialog_type_line};

		my $end_file_dialog_type_line = $update->{_end_file_dialog_type_line};

		print(
"update, spec_changes, start_file_dialog_type_line =$update->{_start_file_dialog_type_line}\n"
		);
		print(
"update, spec_changes, end_file_dialog_type_line =$update->{_end_file_dialog_type_line}\n"
		);

=head2 Add lines to

file_dialog_type_aref lines in *_spec.pm file
Intentionally start from the end of the *.spec file

=cut

		$start_file_dialog_type_line =
		  $update->{_start_file_dialog_type_line} - 1;
		$end_file_dialog_type_line = $update->{_end_file_dialog_type_line};

=head2 save latter portion for addendum

to file_dialog_type_aref

If file_dialog_type does not have more than 3 entries the line_bump_* = 0

=cut

		$new_length_of_slurp =
		  $length_of_slurp + $line_bump_suffix + $line_bump_prefix;

		$temp_array_length_file_dialog_type =
		  $new_length_of_slurp - $end_file_dialog_type_line;
		print(
"update,spec_changes, new_length_of_slurp   = $new_length_of_slurp\n"
		);
		print(
"update,spec_changes, file_dialog_type_aref temp_array_length_file_dialog_type = $temp_array_length_file_dialog_type\n"
		);
		@temp_array_file_dialog_type[ 0 .. (
			  $temp_array_length_file_dialog_type - 1 ) ] =
		  @slurp[ $end_file_dialog_type_line .. $new_length_of_slurp ];

#		print("update,spec_changes, temp_array_file_dialog_type = @temp_array_file_dialog_type\n");

		# recursively modify *_spec.pm file
		for ( my $i = 0 ; $i < $label_number_of ; $i++ ) {

		  #				print("update, spec_changes, L 1479, label_number=$label[$i]\n");

			$slurp[ ( $start_file_dialog_type_line + $i ) ] =
			  ("\t\$type[\$index[$i]] = \$file_dialog_type->\{_Data\};");
		}

=head2 Add saved text lines

to file_dialog_type_aref
if we have more than 3 input/output interactions 

=cut			

		if ( $label_number_of > 5 ) {

			$line_bump_file_dialog_type = ( $label_number_of - 5 );

			my $new_length_of_slurp =
			  $length_of_slurp +
			  $line_bump_suffix +
			  $line_bump_prefix +
			  $line_bump_file_dialog_type;

			my $new_end_file_dialog_type_line =
			  $end_file_dialog_type_line + $line_bump_file_dialog_type + 1;

			print(
"update, spec_changes,new_length_of_slurp, file_dialog_type_aref=$new_length_of_slurp\n"
			);
			print(
"update, spec_changes,new_end_file_dialog_type_line= $new_end_file_dialog_type_line\n"
			);

			@slurp[ ( $new_end_file_dialog_type_line - 1 )
			  .. ( $new_length_of_slurp - 1 ) ] =
			  @temp_array_file_dialog_type[ 0 .. (
				  $temp_array_length_file_dialog_type - 1 ) ];
		}
		elsif ( $label_number_of <= 5 ) {

			#               NADA;
		}
		else {
			print(
"update, spec_changes, for file_dialog_type_aref unexpected value \n"
			);
		}

#################################################################################

=head2 add to

sub binding_index_aref lines in *_spec.pm file

=cut

		my $start_binding_index_line = $update->{_start_binding_index_line};
		my $end_binding_index_line   = $update->{_end_binding_index_line};

		print(
"update, spec_changes, start_binding_index_line =$update->{_start_binding_index_line}\n"
		);

		print(
"update, spec_changes, end_binding_index_line =$update->{_end_binding_index_line}\n"
		);

=head2 Add lines to

binding_index_aref lines in *_spec.pm file
Intentionally start from the end of the *.spec file

=cut

		$start_binding_index_line = $update->{_start_binding_index_line} - 1;
		$end_binding_index_line   = $update->{_end_binding_index_line} - 1;

=head2 save latter portion for addendum

to binding_index_aref

If file_dialog_type does not have more than 3 entries the line_bump_* = 0

=cut

		$new_length_of_slurp =
		  $length_of_slurp +
		  $line_bump_suffix +
		  $line_bump_prefix +
		  $line_bump_file_dialog_type;

		$temp_array_length_binding_index =
		  $new_length_of_slurp - $end_binding_index_line;
		print(
"update,spec_changes, new_length_of_slurp   = $new_length_of_slurp\n"
		);
		print(
"update,spec_changes, binding_index_aref temp_array_length_binding_index = $temp_array_length_binding_index\n"
		);
		@temp_array_binding_index[ 0 .. ( $temp_array_length_binding_index - 1 )
		] = @slurp[ $end_binding_index_line .. $new_length_of_slurp ];

#		print("update,spec_changes, temp_array_binding_index = @temp_array_binding_index\n");

		# recursively modify *_spec.pm file
		for ( my $i = 0 ; $i < $label_number_of ; $i++ ) {

		  #				print("update, spec_changes, L 1591, label_number=$label[$i]\n");
			my $index_out = $label[$i] - 1;
			$slurp[ ( $start_binding_index_line + $i ) ] =
			  ("\t\$index[$i] = $index_out; # inbound/outbound item is bound");
		}

=head2 Add saved text lines

to binding_index_aref
if we have more than 4 input/output interactions 

=cut			

		if ( $label_number_of > 4 ) {

			$line_bump_binding_index = ( $label_number_of - 4 );

			my $new_length_of_slurp =
			  $length_of_slurp +
			  $line_bump_suffix +
			  $line_bump_prefix +
			  $line_bump_file_dialog_type +
			  $line_bump_binding_index;

			my $new_end_binding_index_line =
			  $end_binding_index_line + $line_bump_binding_index + 1;

			print(
"update, spec_changes,new_length_of_slurp, binding_index_aref=$new_length_of_slurp\n"
			);
			print(
"update, spec_changes,new_end_binding_index_line= $new_end_binding_index_line\n"
			);

			@slurp[ ( $new_end_binding_index_line - 1 )
			  .. ( $new_length_of_slurp - 1 ) ] =
			  @temp_array_binding_index[ 0 .. (
				  $temp_array_length_binding_index - 1 ) ];
		}
		elsif ( $label_number_of <= 4 ) {

			#               NADA;
		}
		else {
			print(
"update, spec_changes, for binding_index_aref unexpected value \n"
			);
		}

#################################################################################

=head2 write out

updated spec file

=cut

		open( OUT, ">$spec_outbound[0]" )
		  or die("File  $spec_outbound[0] not found");

		$length_of_slurp = scalar @slurp;

		print(
"update,writing out file, spec_changes, length_of_slurp = $length_of_slurp\n"
		);

		for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

			#				print ("$slurp[$i]\n");
			print OUT $slurp[$i] . "\n";

		}
		close(OUT);

	}
	else {
		print("update,spec_changes, a needed variable is missing\n");
		print("update,spec_changes,program_name=$update->{_program_name}\n");
		print("update,spec_changes,group_number=$update->{_group_number}\n");
		print(
"update,spec_changes,spec_changes_base_file_name=$update->{_spec_changes_base_file_name}\n"
		);
		print("update,spec_changes,$changes_aref=changes_aref\n");
		print(
"update,spec_changes,start_binding_index_line=$update->{_start_binding_index_line}\n"
		);
		print(
"update,spec_changes,start_prefix_line=$update->{_start_prefix_line}\n"
		);
		print(
"update,spec_changes,start_suffix_line=$update->{_start_suffix_line}\n"
		);
		print(
			"update,spec_changes,end_suffix_line=$update->{_end_suffix_line}\n"
		);
		print(
			"update,spec_changes,end_prefix_line=$update->{_end_prefix_line}\n"
		);

	}

	return ();
}

1;
