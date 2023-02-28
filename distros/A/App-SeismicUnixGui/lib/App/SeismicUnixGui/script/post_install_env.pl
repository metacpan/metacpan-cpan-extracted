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

=cut 

use Moose;
our $VERSION = '0.0.2';
use Cwd;
use Carp;

# important variables defined
my $null = 'null';
my $fifo ='tbd';
my $starting_point          = '/';
my $script_file             = 'post_install_env.pl';
my $script_path;
my $path2find               = "*/App/SeismicUnixGui/script";
my $default_answer          = 'y';

$ARGV[0] = $null;
# not needed yet
# print ("argv[0]=$ARGV[0]\n");

#my $dir = getcwd;
print("\n\tHOW TO SET UP YOUR WORKING ENVIRONMENT\n");

# Searching
print(" Please be patient.\n");
print(" Examining the system ... for $path2find\n");
print(" Hint: use the one with \"perl\". \n");

# remove pre-exisiting files
unlink($fifo);

# system (" echo \"find $starting_point -path \'$path2find\' -print 2>/dev/null > $fifo \" ");
system("find $starting_point -path \'$path2find\' -print > $fifo 2>/dev/null & ");

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
my $ans = 'n';
while ($ans eq 'n') {
	
	print("\nEnter another script libraries (with full path),\n or use the default:$script_list[0]\n");
	print("Enter a different name or only Hit Return\n");
	my $answer = <STDIN>;
	chomp $answer;

	if ( length $answer ) {
		
		$script_path = $answer;
		
	}
	elsif ( !( length $answer 
	and length $script_list[0]) ) {
		
		$script_path= $script_list[0];
		
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
	print "From: $SCRIPT_PATH\n";
		
	my $outbound = ".temp";
	my $bash_file2run = 'set_env_variables.sh';
	print ("Writing to: $outbound;\n\n");
	open( OUT, ">", $outbound )
	  or die("File $outbound error");

	printf OUT ("#!/bin/bash\n");
	printf OUT ("export SeismicUnixGui_script=$SCRIPT_PATH\n");
	printf OUT ("export PATH=\$PATH::\$SeismicUnixGui_script\n\n");
	printf OUT ("export PERL5LIB=\$SeismicUnixGui_script/../lib\n");
	close(OUT);
	system("chmod 755 $outbound");

	print(
"\n\nThe system path to \"SeismicUnixGui\" appears to be:\n $SCRIPT_PATH\n");
	print("Before running SeismicUnixGui, be sure to add the\n");
	print("following 3 lines to the end of your \".bashrc\" file\n\n");
	print("export SeismicUnixGui_script=$SCRIPT_PATH\n");
	print("export PATH=\$PATH::\$SeismicUnixGui_script\n");
	print("export PERL5LIB=\$SeismicUnixGui_script/SeismicUnixGui\n");
	print(
		"\nHowever, for a quick BUT temporary fix, you have 2 options:\n");
	print("   A. Cut-and-paste the 3 instructions above, one at a time \n");
	print("into your command line and execute them one at a time.\n"
	);
	print("\nIn case you are unsure, this last instruction also means: \n");
	print("\tcopy and paste each line,\n");
	print("\tone at a time,\n");
	print("\tinto the command line,\n");
	print("\twith each line followed by \"Enter\"\n");
	print("\n or, B. Run the following bash instruction on a single line (!):\n");
	chomp $SCRIPT_PATH;
	print("bash $SCRIPT_PATH/$bash_file2run\t\n");
	print("N.B.: The instruction must be written single line\n");
	print("\n... after which you can should be able run the following instruction\n");
	print(" on the command line:\n");
	print("\n\tSeismicUnixGui\n");	
	print("\n**But remember, that when you open a new command window,\n");
	print("the effect of these instructions will cease to exist.\n");
	print("Make the changes permanent in your \".bashrc\" file.\n");
	print("If you do not know how to do this, consult someone who does.\n\n");
	print("Hit Enter, to finish\n");
	<STDIN>;

}
else {
	carp "missing directory";
}
