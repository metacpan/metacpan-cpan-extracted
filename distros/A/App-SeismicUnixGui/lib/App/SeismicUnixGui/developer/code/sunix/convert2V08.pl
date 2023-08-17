
=head2 SYNOPSIS

PERL PROGRAM NAME: convert2V07

AUTHOR:  

DATE: Jun 15 2022

DESCRIPTION: Convert perl gui scripts
by including full path to modules
Version: 0.1
V 0.2 August 4, 2022
V 0.3 Dec. 2022 

=head2 USE

=head3 NOTES

Before conversion: use L_SU_global_constants:
After conversion:  use App:SeismicUnixGui::misc::SeismicUnixGui::misc::L_SU_global_constants;

V0.2 adapted to use App:SeismicUnixGui::misc::SeismicUnixGui
first, change use module; to use aliased 'App::SeismicUnixGui::path::to::module
next,change new module(); to module->new(); 

V 0.3 use search_directories.pm instead of L_SU_global_constants.pm

=head4 Examples

=head2 SYNOPSIS

changed files: 

configs:


correct oop_text
oop_run_flows


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::dirs';
use Carp;

my $L_SU_global_constants = L_SU_global_constants->new();
my $manage_files_by2      = manage_files_by2->new();
my $dirs                  = dirs->new();

=head2 Define

local variables

=cut

my ( @INBOUND, @SUBDIR );
my @directories;
my @line;
my @path4gui;
my @file4gui;
my @path4su;
my @file4su;
my @path4gen;
my @file4gen;

my $line2find_use = '\s*use\s';
my $line2find_new = '\s=\snew\s';
my $line2find_App = 'use\ App::';
my $line2find_SeismicUnix = 'SeismicUnix\ qw';

my $ans = 'n';

print("Enter file name to convert\n");
my $file_name = <>;
chomp $file_name;

print("You entered $file_name. Correct? y/n\n");
$ans = <>;
chomp $ans;

while ( ( $ans eq 'N' ) or ( $ans eq 'n' ) ) {

	print("Enter file name again\n");
	$file_name = <>;
	chomp $file_name;

	print("You entered $file_name. Correct? y/n\n");
	$ans = <>;
	chomp $ans;

}

print "OK, correct file name is $file_name\n";

#my $file_name = 'test_file.pl';
#print("parent_directory_gui_number_of=$parent_directory_gui_number_of\n");
#print("child_directory_gui_number_of=$child_directory_gui_number_of\n");

=head2 private shared hash

=cut

my $convert2V07 = {

	_file_name => '',

};

=head2 CASE # 1A 1B

when only use module;
 is present
 
 use SeismicUnix qw ()

=cut

$manage_files_by2->set_file_in($file_name);
$manage_files_by2->set_directory('./');
my $slurp_ref = manage_files_by2->get_whole($file_name);

my @slurp           = @$slurp_ref;
my $length_of_slurp = scalar @slurp;

for ( my $j = 0 ; $j < $length_of_slurp ; $j++ ) {

	my $raw_string = $slurp[$j];
	chomp $raw_string;    # remove all newlines
	my @temp_string;

	if ( $raw_string =~ m/$line2find_use/ ) {

		my $module_name;
		my $string = $raw_string;

		$string =~ s/;//;
		$string =~ s/\(\)//;
		@temp_string = split( /\s+/, $string );
		my $line = $j + 1;

		if ( $temp_string[1] eq 'use' ) {

			$module_name = $temp_string[2];

			print(
"Cases 1A or 1B for:use, convert2V07, module name with $module_name...\n"
			);

			if (    $module_name ne 'Moose'
				and $module_name ne 'SeismicUnix'
				and $module_name ne 'aliased'
				and length $module_name
				and $module_name ne ''
				and $module_name ne 'null' )
			{

				# CASE 1B looking for use model
#				print("line to substitute=$slurp[$j]\n");
				my $var        = $L_SU_global_constants->var();
				my $separation = $var->{_SeismicUnixGui};

				my $module_name_pm = $module_name . '.pm';

				# print("module name_pm=$module_name_pm\n");

				$dirs->set_file_name($module_name_pm);
				my $path = $dirs->get_path4convert_file();

				if ( length $path ) {

					my $pathNmodule_pm = $path . '/' . $module_name_pm;
					my @next_string    = split( $separation, $pathNmodule_pm );

#					print("Case 1A: convert2V07, 'b4:' . $next_string[0]\n");
#					print("'After:' . $next_string[1]\n");
#					print("segment3: $next_string[2]\n");

					# substitute "/" with ":"
					$next_string[2] =~ s/(\/)+/::/g;
					$next_string[2] =~ s/.pm//g;
					$next_string[2] = "\t"
					  . 'use aliased \'App::'
					  . $var->{_SeismicUnixGui}
					  . $next_string[2] . '\';';

					#	warn 'After...' . $next_string[1];
					$raw_string = $next_string[2];
					$slurp[$j] = $raw_string;

					print("substituted line=$slurp[$j]\n");

				}
				else {
					warn 'Warning: variable missing';
					print 'path=' . $path . "\n";
					print("module name_pm=$module_name_pm\n\n");
				}
			}
			elsif ( $module_name eq 'SeismicUnix'
				and $module_name ne 'Moose'
				and length $module_name
				and $module_name ne ''
				and $module_name ne 'null' )
			{
				# CASE 1B looking for use SeismicUnix qw ( ...)
				# When bad module names are avoided
#				print("line to substitute=$slurp[$j]\n");
				my $separation_qw      = 'qw';
				my @for_variables_only = split( $separation_qw, $slurp[$j] );
#				print(
#"Case 1B, convert2V07,for_variables_only 'b4:'$for_variables_only[0]\n"
#				);
#				print(
#"Case 1B, convert2V07,for_variables_only 'After4:'$for_variables_only[1]\n"
#				);

				my $var                   = $L_SU_global_constants->var();
				my $separation            = $var->{_SeismicUnixGui};

				my $module_name_pm = $module_name . '.pm';

				# print("module name_pm=$module_name_pm\n");

				$dirs->set_file_name($module_name_pm);
				my $slash_path =
				  $dirs->get_path4convert_file();

				if ( length $slash_path ) {

					my $slash_pathNmodule_pm =
					  $slash_path . '/' . $module_name_pm;
					my @next_string =
					  split( $separation, $slash_pathNmodule_pm );

#					print("Case 1B, convert2V07, 'b4:' . $next_string[0]\n");
#					print("'After:' . $next_string[1]\n");
#					print("next_string[3]: $next_string[2]\n");

					# substitute "/" with ":"
					$next_string[2] =~ s/(\/)+/::/g;
					$next_string[2] =~ s/.pm//g;
					$next_string[2] = 'use App::'
					  . $var->{_SeismicUnixGui}
					  . $next_string[2] . ' qw'
					  . $for_variables_only[1];

#					warn 'After...' . $next_string[1];
					$raw_string = $next_string[2];
					$slurp[$j] = $raw_string;

					print("substituted line=$slurp[$j]\n");

				}
				else {
					warn 'Warning: variable missing';
					print 'slash_path=' . $slash_path . "\n";
					print("module name_pm=$module_name_pm\n\n");
				}

			}
			else {
				print("convert2V07, bad module: $module_name avoided\n");
			}

		}
		elsif ( $temp_string[0] eq 'use' ) {

			# Catches cases of strange modules

			#		$module_name = $temp_string[1];
			#		print("module name within $file_name=$module_name...\n");
			print("use is in unexpected location WARNING...\n");

		}
		else {
			# CATCH the UNUSUAL
			my $string_number_of = scalar @temp_string;
			print("convert2V07, unexpected module name\n");
			print("\nconvert2V07, string=$string \n");
			print("convert2V07, string_number_of=$string_number_of\n");
			print("convert2V07, temp_string=@temp_string \n");
			print("convert2V07, temp_string[0]=$temp_string[0] \n");
			print("convert2V07, temp_string[1]=$temp_string[1] \n");
			$module_name = 'null';
		}

	}
	else {    # for each line containing "use"
			  # print("convert2V07, skip line\n");
	}

}    # for each line in a slurped file

=head2 Write out 

the corrected or uncorrected file

=cut

my $outbound = $file_name;

print("Case 1 for 'use' only, writing to $outbound\n");
#print("Case 1 number of lines in output file = $length_of_slurp\n");

if ( $length_of_slurp == 0 ) {

	print("convert2V07, unexpected empty file\n");
	print("Hit Enter to continue\n");
	<STDIN>;

}
elsif ( $length_of_slurp > 0 ) {

#	print "Press Writing a new file with a changed line";
#	<STDIN>;

	open( OUT, ">$outbound" )
	  or die("File $file_name not found");

	# add \n!!!!
	for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

		print OUT $slurp[$i] . "\n";

		#		print $slurp[$i] . "\n";
	}

	close(OUT);
}

=head2 CASE #2

re-arrange new

=cut

$manage_files_by2->set_file_in($file_name);
$manage_files_by2->set_directory('./');
$slurp_ref = manage_files_by2->get_whole($file_name);

@slurp           = @$slurp_ref;
$length_of_slurp = scalar @slurp;

for ( my $j = 0 ; $j < $length_of_slurp ; $j++ ) {

	my $raw_string = $slurp[$j];
	chomp $raw_string;    # remove all newlines
	my @temp_string;

	if ( $raw_string =~ m/$line2find_new/ ) {

		my $module_name;
		my $string = $raw_string;
#		print("Case 2, B4:$raw_string\n");
		$string =~ s/\(\);//;
		@temp_string = split( 'new ' , $string );
#		print ("temp string is $temp_string[0]\n");
#		print ("temp string is $temp_string[1]\n");				
		#		my $line = $j + 1;
		my $new_line = $temp_string[0] . $temp_string[1] . '->new();';
#		print("After:$new_line\n");
		$slurp[$j] = $new_line;

	}
	else {    # for each line containing "new"
#		print print("convert2V07, skip line\n");
	}

}    # for each line in a slurped file

# write out the corrected or uncorrected file

$outbound = $file_name;

print("Case 2 for 'new'; writing to $outbound\n");
#print("number of lines in output file = $length_of_slurp\n");

if ( $length_of_slurp == 0 ) {

	print("convert2V07, unexpected empty file\n");
	print("Hit Enter to continue\n");
	<STDIN>;

}
elsif ( $length_of_slurp > 0 ) {

#	print "Press Writing a new file with a changed line\n";
	#	    <STDIN>;

	open( OUT, ">$outbound" )
	  or die("File $file_name not found");

	# add \n!!!!
	for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

		print OUT $slurp[$i] . "\n";
	}

	close(OUT);
}

=head3 CASE#3

convert use App:: to
use aliased 'App::

except for the case of SeismicUnix

=cut

$manage_files_by2->set_file_in($file_name);
$manage_files_by2->set_directory('./');
$slurp_ref = manage_files_by2->get_whole($file_name);

@slurp           = @$slurp_ref;
$length_of_slurp = scalar @slurp;

for ( my $j = 0 ; $j < $length_of_slurp ; $j++ ) {

	my $raw_string = $slurp[$j];
	chomp $raw_string;    # remove all newlines
	my @temp_string;

	if (    $raw_string =~ m/$line2find_App/
		and $raw_string !~ m/SeismicUnix\ qw/ )
	{

		my $module_name;
		my $string = $raw_string;
#		print("Case3, B4:$raw_string\n");
		$string =~ s/use\ App/use\ aliased\ 'App/;
		$string =~ s/;/';/;

		#		my $line = $j + 1;
		my $new_line = $string;
#		print("After:$new_line\n\n");
		$slurp[$j] = $new_line;

	}
	else {    # for each line containing "use"
			  # print("convert2V07, skip line\n");
	}

}    # for each line in a slurped file

# write out the corrected or uncorrected file

$outbound = $file_name;

print("Case 3 for 'aliased'; writing to $outbound\n");
#print("number of lines in output file = $length_of_slurp\n");

if ( $length_of_slurp == 0 ) {

	print("convert2V07, unexpected empty file\n");
	print("Hit Enter to continue\n");
	<STDIN>;

}
elsif ( $length_of_slurp > 0 ) {

#	print "Press Writing a new file with a changed line";
	#	    <STDIN>;

	open( OUT, ">$outbound" )
	  or die("File $file_name not found");

	# add \n!!!!
	for ( my $i = 0 ; $i < $length_of_slurp ; $i++ ) {

		print OUT $slurp[$i] . "\n";
	}

	close(OUT);
}
