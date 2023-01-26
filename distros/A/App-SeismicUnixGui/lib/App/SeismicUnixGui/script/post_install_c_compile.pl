#!/bin/perl

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL SCRIPT NAME: post_install_c_compile.pl 
 AUTHOR: Juan Lorenzo
 DATE: July 11 2022 

 DESCRIPTION 

 
 Help installer compile C and fortran programs

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
use Shell qw(echo);

my $C_PATH;
my $SeismicUnixGui;
my $ans 	= 'n';
my $path;

# important variables defined
my $local_dir = getcwd;

$C_PATH 	= $local_dir.'/blib/lib/App/SeismicUnixGui'.'/'.'c/synseis';
print("\n\tINSTALLATION OF C PROGRAMS\n");
print("\nC_PATH=$C_PATH\n");
print("\nDo you want to compile C standalone program? (y/n)\n");
$ans = <STDIN>;
chomp $ans;

if ( ( $ans eq 'N' ) or ( $ans eq 'n' ) ) {

	print("\nOK, your answer is no.  Bye!\n");
	exit;

}
elsif ( ( $ans eq 'Y' ) or ( $ans eq 'y' ) ) {
	
	print "\nOK, Proceeding to compile\n";
	system("cd $C_PATH; bash run_me_only.sh ");
	
}
else {
	print("post_installation_c_compile.pl, unexpected answer\n");
}

print("Hit Enter to continue\n");
<STDIN>

