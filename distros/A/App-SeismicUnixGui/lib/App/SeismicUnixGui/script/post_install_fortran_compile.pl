#!/bin/perl

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL SCRIPT NAME: post_install_fortran_compile.pl 
 AUTHOR: Juan Lorenzo
 DATE: October 9, 2022 

 DESCRIPTION 

 
 Help installer compile fortran programs

=cut

=head2 USE

=head3 NOTES
	
	Post-installation files are stored somewhere on the system,
	e.g., Distribution directory for SeismicUnixGui =
	/usr/local/lib/x86_64-linux-gnu/perl/5.30.0/auto/
	App/SeismicUnixGui

=head4 Examples


=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '0.0.1';
use Cwd;
use Env;
use Shell qw(echo);

my $Fortran_pathNfile;
my $pgplot_pathNfile;
my $PGPLOT_DIR_default = '/usr/local/pgplot';
my $PGPLOT_DIR         = $PGPLOT_DIR_default;
my $SeismicUnixGui;
my $default_answer = 'y';

# search for fortran and pgplot codes
my $starting_point          = '/';
my $fortran_file            = 'run_me_only.sh';
my $pgplot_file             = 'drivers.list';
my $fortran_pathNfile2find  = "*/App/SeismicUnixGui/fortran/$fortran_file";
my $pgplot_pathNfile2find   = "*/pgplot/$pgplot_file";
my $pgplot_path;

# Searching
print(" Examining the system ... for pgplot directory\n");
my $instruction = ("find $starting_point -path $pgplot_pathNfile2find -print 2>/dev/null");
#print "\t".$instruction."\n";
my @pgplot_list   = `$instruction`;
my $lengthB = scalar @pgplot_list;

print("\n Found $lengthB locations for the pgplot libraries:\n");

for ( my $i = 0 ; $i < $lengthB ; $i++ ) {
	
    $pgplot_list[$i] =~ s/$pgplot_file//;
	print("Case $i: $pgplot_list[$i]\n");

}

my $ans = 'n';
while ($ans eq 'n') {
	
	print("\nEnter the full path to pgplot libraries,\n or use the default:$pgplot_list[0]\n");
	print("Enter a different name or only Hit Return\n");
	my $answer = <STDIN>;
	chomp $answer;

	if ( length $answer ) {
		
		$pgplot_path = $answer;
		
	}
	elsif ( !( length $answer ) ) {
		
		$pgplot_path= $pgplot_list[0];
		
	}

	print("You chose: $pgplot_path\n");
	print("Is that correct? Please answer y or n  [$default_answer]\n");
	$ans = <STDIN>;
	chomp $ans;
	
}
$PGPLOT_DIR = $pgplot_path;

if (!defined($PGPLOT_DIR) or $PGPLOT_DIR eq '' ) {

	print("Warning: While running as sudo, \n");
	print("PGPLOT_DIR variable was not found.\n");
	print("You will need to install pgplot software,\n");
	print("and define PGPLOT_DIR in you environment.\n");
	print("If you want to compile FORTRAN programs, \n");
    print("you should have the \"pgplot\" libraries compiled and installed. \n\n");
    print("Please come back when you are ready, but first \n");
	print ("install pgplot and put the following line \n");
	print ("in your \".bashrc\" file:\n");
	print("      export PGPLOT=/your/path/to/pgplot \n\n");

} elsif ( defined($PGPLOT_DIR) ) {

	print("PGPLOT_DIR variable is defined\n");
	print("PGPLOT_DIR = $PGPLOT_DIR\n");

} else {
	print ("Unexpected result from fortran installation script\n");
}


print("\n Examining the system ... for fortran files\n");

my @fortran_list   = `(find $starting_point -path $fortran_pathNfile2find -print 2>/dev/null)`;
my $lengthA= scalar @fortran_list;

print("\n Found $lengthA versions of the script.\n");
print(" Hint: use one with the \"bin\" in the path name
		or \"perl5/bin\"  for the case of a local installation\)\n");

for ( my $i = 0 ; $i < $lengthA ; $i++ ) {

	print("Case $i: $fortran_list[$i]\n");

}

# reset ans
$ans = 'n';
while ($ans eq 'n') {
	
	print("\nEnter a script name (with Full Path),\n or use the default:$fortran_list[0]\n");
	print("Enter a different name or only Hit Return\n");
	my $answer = <STDIN>;
	chomp $answer;

	if ( length $answer ) {
		
		$Fortran_pathNfile = $answer;
		
	}
	elsif ( !( length $answer ) ) {
		
		$Fortran_pathNfile = $fortran_list[0];
		
	}

	print("You chose: $Fortran_pathNfile\n");
	print("Is that correct? Please answer y or n  [$default_answer]\n");
	$ans = <STDIN>;
	chomp $ans;
	
}

print("\n\tINSTALLATION OF EXTERNAL FORTRAN PROGRAMS\n\n");

print("Fortran path=$Fortran_pathNfile\n\n");

my $path = $Fortran_pathNfile; 
$path =~ s/$fortran_file//;
chomp $path;

print "Proceeding to compile\n";

system("cd $path; sudo bash run_me_only.sh $PGPLOT_DIR ");
# my $me = system("whoami");
# print("post_install_fortran_compile.pl,me=$me\n");


print("End of Fortran Installation\n");
print("Hit Enter to leave\n");
<STDIN>

