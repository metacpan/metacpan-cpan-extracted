#!/bin/perl

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL SCRIPT NAME: post_install_env.pl 
 AUTHOR: Juan Lorenzo
 DATE: July 11 2022 

 DESCRIPTION 
 
 Help installer set important environment variables
 needed later to run SeismicUnixGui
 
=cut

=head2 USE

=head3 NOTES
	
	Post-installation files are stored somewhere on the system,
	e.g., Distribution directory for SeismicUnixGui =
	/usr/local/lib/x86_64-linux-gnu/perl/5.30.0/auto/
	App/SeismicUnixGui

=head4 Examples


=head2 CHANGES and their DATES

V0.0.2 Feb. 2023,  uses find instead of locate.
V0.0.3 Feb. 2023,  look for scripts in / and /home 

=cut 

use Moose;
our $VERSION = '0.0.2';
use Cwd;
use Carp;
use File::Spec;
use List::Util 'first';

# important variables defined
my $null = 'null';
my $fifo ='tbd';
my $starting_points         = '/home /';
my $script_file             = 'post_install_env.pl';
my $script_path;
my $paths2find              = "*/App/SeismicUnixGui/script";
my $SeismicUnixGui;
my $default_answer          = 'y';
my $hintA                   = 'perl';
my $hintB                   = 'perl5';
my $default_hintA           = '"'.$hintA.'"';
my $default_hintB           = '"'.$hintB.'"';

$ARGV[0] = $null;
# not needed yet
# print ("argv[0]=$ARGV[0]\n");
#my $dir = getcwd;
#
print("\n\tHOW TO SET UP YOUR WORKING ENVIRONMENT\n");

# Searching
print(" Please be patient.\n");
print(" Examining the system ... for $paths2find\n");
print(" Hint: Choose a path with either $default_hintA (global) or
       $default_hintB (local installation) in its name.
       Ignore paths with \"blib\" in their name.\n");

# remove pre-existing files
unlink($fifo);

# system (" echo \"find $starting_points -path \'$paths2find\' -print 2>/dev/null > $fifo \" ");
system("find $starting_points -path \'$paths2find\' -print > $fifo 2>/dev/null & ");

# wait around until the file is populated with something inside
while (!(-e $fifo) 
		or (-e $fifo and -z $fifo)) {
	
#    print "waiting...\n";
    
}
# read file contents
open my $fh, "<", $fifo or die "Can not open '$fifo': $!";

   chomp(my @script_list = <$fh>);

close $fh;

my $length        = scalar @script_list;
print("\n Found $length locations for the script directory:\n");

for ( my $i = 0 ; $i < $length ; $i++ ) {
	
    $script_list[$i] =~ s/$script_file//;
	print("Case $i: $script_list[$i]\n");

}

my $default_script_path = first { /$hintA/ } @script_list;

my $ans = 'n';
while ($ans eq 'n') {
	
	print("\nEnter another script libraries (with full path),\n or use the default:$default_script_path \n");
	print("Enter a different name or only Hit Return\n");
	my $answer = <STDIN>;
	chomp $answer;

	if ( length $answer ) {
		
		$script_path = $answer;
		
	}
	elsif ( !( length $answer)
	and length ($default_script_path) ) {
		
		$script_path= $default_script_path;
		
	}else {
		print("error; nothing found\n");
		exit();
	}

	print("You chose: $script_path\n");
	print("Is that correct? Please answer y or n  [$default_answer]\n");
	$ans = <STDIN>;
	chomp $ans;
	
}
my $SCRIPT_PATH= $script_path;


if ( length $SCRIPT_PATH ) {
	# print "From: $SCRIPT_PATH\n";
	my @folders = File::Spec->splitdir($SCRIPT_PATH);
	# print("post_install_env.pl, @folders\n");
	my $number_of_folders = scalar @folders;
	my $all_but_last      = $number_of_folders -2;
	$SeismicUnixGui = join('/',@folders[0..$all_but_last]);
	# print("post_install_env.pl, $SeismicUnixGui\n");
	my $local = getcwd();		
	my $outbound = "$local/.temp";
#	my $bash_file2run = 'set_env_variables.sh';
	print ("Writing to: $outbound;\n");
	open( OUT, ">", $outbound )
	  or die("File $outbound error");

	printf OUT ("#!/bin/bash\n");
	printf OUT ("export SeismicUnixGui=$SeismicUnixGui\n");	
	printf OUT ("export SeismicUnixGui_script=$SCRIPT_PATH\n");
	printf OUT ("export PATH=\$PATH::\$SeismicUnixGui_script\n");
	printf OUT ("export PERL5LIB=\$PERL5LIB::\$SeismicUnixGui\n");
	close(OUT);
	system("chmod 755 $outbound");

	print(
"\nThe system path to \"SeismicUnixGui_script\" appears to be:\n $SCRIPT_PATH\n");
	print("Before running SeismicUnixGui, be sure to add the\n");
	print("following 6 lines to the end of your \".bashrc\" file\n\n");
	print("export SeismicUnixGui=$SeismicUnixGui\n");	
	print("export PERL5LIB=\$PERL5LIB:\$SeismicUnixGui\n");
	print("export SeismicUnixGui_script=\$SeismicUnixGui/script\n");	
	print("export PATH=\$PATH::\$SeismicUnixGui_script\n");	
    print("export PATH=\$PATH:\$SeismicUnixGui/fortran/bin\n");
    print("export PATH=\$PATH:\$SeismicUnixGui/App/SeismicUnixGui/c/bin\n");

	print(
		"\nHowever, for a quick BUT temporary fix, you have another option:\n");
	print("    Cut-and-paste the 6 instructions above, one at a time \n");
	print("into your command line and execute them one at a time.\n"
	);
	print("\nIn case you are unsure, this last instruction also means: \n");
	print("    copy and paste each complete line,\n");
	print("    only one single command line at a time,\n");
	print("    with each line followed by \"Enter\"\n\n");
#	print("or, B. Run the following bash instruction on a single line (!):\n");
#	chomp $SCRIPT_PATH;
#	print("    source .temp\n");
	print("\n... after which you should be able run the following instruction\n");
	print(" on the command line:\n\n");
	print("    SeismicUnixGui\n");	
	print("\n**But remember, that when you open a new command window,\n");
	print("the effect of these instructions will cease to exist.\n");
	print("Make the changes permanent in your \".bashrc\" file.\n");
	print("If you do not know how to do this, consult someone who does.\n\n");
	print("Hit Enter, to finish.\n");
	<STDIN>;

}
else {
	carp "missing directory";
}
