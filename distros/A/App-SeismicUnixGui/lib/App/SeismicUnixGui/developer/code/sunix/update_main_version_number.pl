use Moose;

=head2 SYNOPSIS

PERL PROGRAM NAME: update_main_version_number.pl

AUTHOR:  

DATE: V 0.1 May 3 2023

DESCRIPTION: replace version number in key files

Version: 0.1


=head2 USE

=head3 NOTES



=head4 Examples

=head2 SYNOPSIS
    
=head2 CHANGES and their DATES

Sep 25 2023
Also change name of the InstallationGuide

=cut

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use Cwd;

my $manage_files_by2 = manage_files_by2->new();

my ( @file, @file_bck );
my $path;
my @path2file;
my @inbound;
my @outbound_bck;
my @outbound;
my ( @line2find, @replacement );
my $max_num_files = 6;   # +1!

my $up3dirs = '/../../..';
my $up4dirs = '/../../../..';

=head2 set replacement text
and file

=cut

my $local       = getcwd();
my $old_version = '0.87.2';
my $new_version = '0.87.3';

my $i = 0;
$line2find[$i]   = ("L_SUV$old_version.pl");
#print("line2find   = $line2find[$i]\n");
$replacement[$i] = ("L_SUV$new_version.pl");
#print("replacement = $replacement[$i]\n");
$file[$i]        = 'L_SU.pl';
$path2file[$i]   = $local . $up3dirs . '/script';

$i = 1;
$line2find[$i] = "VERSION = '$old_version';";
#print("line2find   = $line2find[$i]\n");
$replacement[$i] = "VERSION = '$new_version';";
#print("replacement = $replacement[$i]\n");
$file[$i]      = 'About.pm';
$path2file[$i] = $local . $up3dirs . '/messages';

$i = 2;
$line2find[$i] =
  "_program_title                 => 'SeismicUnixGui V$old_version',";
#print("line2find   = $line2find[$i]\n");
$replacement[$i] =
  "_program_title                 => 'SeismicUnixGui V$new_version',";
#print("replacement = $replacement[$i]\n");
$file[$i]      = 'L_SU_global_constants.pm';
$path2file[$i] = $local . $up3dirs . '/misc';

$i = 3;
$line2find[$i] = "VERSION = '$old_version';";
#print("line2find   = $line2find[$i]\n");
$replacement[$i] = "VERSION = '$new_version';";
#print("replacement = $replacement[$i]\n");
$file[$i]      = 'SeismicUnixGui.pm';
$path2file[$i] = $local . $up4dirs;

$i = 4;
$line2find[$i]     = "'SeismicUnixGuiInstallationGuide$old_version.pdf';";
print("line2find   = $line2find[$i]\n");
$replacement[$i] = "'SeismicUnixGuiInstallationGuide$new_version.pdf';";
print("replacement = $replacement[$i]\n");
$file[$i]         = 'help_button_messages.pm';
$path2file[$i]    = $local . $up3dirs . '/messages';

$i = 5;
$line2find[$i]     = "'SeismicUnixGuiTutorial$old_version.pdf';";
print("line2find   = $line2find[$i]\n");
$replacement[$i] = "'SeismicUnixGuiTutorial$new_version.pdf';";
print("replacement = $replacement[$i]\n");
$file[$i]         = 'help_button_messages.pm';
$path2file[$i]    = $local . $up3dirs . '/messages';

=head2 Set files and paths

=cut

for ( my $count = 0 ; $count < $max_num_files; $count++ ) {

#for ( my $count = 2 ; $count < 3; $count++ ) {
	
	$file_bck[$count] = $file[$count] . '_bck';
	
	$inbound[$count]      = $path2file[$count] . '/' . $file[$count];
	$outbound[$count]     = $path2file[$count] . '/' . $file[$count];
	$outbound_bck[$count] = $path2file[$count] . '/archive/' . $file_bck[$count];

	# save a backup file
	system("cp $inbound[$count] $outbound_bck[$count]");

	# slurp every file
	$manage_files_by2->set_pathNfile( $inbound[$count] );
	my $slurp_ref = manage_files_by2->get_whole();

	my @slurp           = @$slurp_ref;
	my $length_of_slurp = scalar @slurp;

	for ( my $line_idx = 0 ; $line_idx < $length_of_slurp ; $line_idx++ ) {

		# CASE within each *.pm file
		my $string = $slurp[$line_idx];

		#  chomp $string;    # remove all newlines
		if ( $string =~ m/$line2find[$count]/) {
			
			$string =~ s/$line2find[$count]/$replacement[$count]/;
			print(" substitution successful: $string\n");
			print(" in file: $file[$count]\n");
			
		}

#		print(" string: $string\n");
		$slurp[$line_idx] = $string;

	}

	open( OUT, ">","$outbound[$count]" )
	  or die("File $outbound[$count] not found");

#     open( OUT, ">","junk" )
#	  or die("File junk not found");

	foreach my $text (@slurp) {

		print OUT $text . "\n";

#		print("$text \n");
	}
	close(OUT);

}

print("Do not forget to update the internal name of the SeismicUnixGuiInstallationGuide \n
       and SeismicUnixTutorial too.\n
	   As well, update other contents of the file as necessary");
