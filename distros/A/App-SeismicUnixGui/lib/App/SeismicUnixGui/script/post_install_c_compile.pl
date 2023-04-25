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
use Shell qw(echo find);

my $C_pathNfile;
my $SeismicUnixGui;
my $ans            = 'n'."\n";
my $default_answer = 'y';
my $choice         = 1;
my $repeat         = 1;

# search for c libraries
my $starting_point = '/';
my $file           = 'run_me_only.sh';
my $pathNfile2find = "*c/synseis/$file";

print(" Looking for script on the system...\n");

my @list   = `(find $starting_point -path $pathNfile2find -print 2>/dev/null)`;
my $length = scalar @list;

print(" Found $length versions of the script:\n");
print \(" Hint: use one with the \"perl\" in the path name\)\n");

for ( my $i = 0 ; $i < $length ; $i++ ) {

	print("Case $i: $list[$i]\n");

}

while ($ans eq 'n'."\n") {
	
	print("\nEnter a script name (with Full Path),\n or use the default:$list[0]\n");
	print("Enter a different name or only Hit Return\n");
	my $answer = <STDIN>;
	chomp $answer;

	if ( length $answer ) {
		
		$C_pathNfile = $answer;
		
	}
	elsif ( !( length $answer ) ) {
		
		$C_pathNfile = $list[0];
		
	}

	print("You chose: $C_pathNfile\n");
	print("Is that correct? Please answer y or n  [$default_answer]\n");
	$ans = <STDIN>;
	chomp $ans;
}

my $path = $C_pathNfile; 
$path =~ s/$file//;
chomp $path;
print("path and file: $path$file\n");

print("\n\tINSTALLATION OF EXTERNAL C PROGRAMS\n");
print("\nC_PATH=$C_pathNfile\n");

print "Proceeding to compile\n";
chdir "$path";
system("sudo bash $file");

print("Hit Enter to leave\n");
<STDIN>
