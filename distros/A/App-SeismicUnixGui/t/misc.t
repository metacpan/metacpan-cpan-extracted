
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 121 tests for configs

=cut

=head1 Test for misc modules

ok tests if modules compile well

=cut

use Test::Compile::Internal tests => 122;

my $test=Test::Compile::Internal->new();
my $root='lib/App/SeismicUnixGui/misc/';
#my $inbound = 't/misc_files.txt';
#my $inbound = 't/misc_files2.txt';
#open (IN,'<',$inbound) or die $!;
#
#	my $line;
#	my $i=0;
#	my @only_these1;
#	# read contents of file
#	while ( $line = <IN> ) {
#
##		print("\n$line");
#		chomp($line);
#		push @only_these1,$root.$line;
#	#	print("$only_these1[$i]\n");	
#		$i++;
#		
#	}
#
#	close(IN);
#	
#	print("@only_these1\n");	

my $excluded_directory_name1 = ".vscode"; 
my $excluded_directory_name2 = "archive"; 

opendir my $dh, $root or die "Cannot open directory $root: $!";

 my @filenames = grep {
    !/^\.{1,2}$/ && # Exclude . and ..
    $_ ne $excluded_directory_name1 &&
    $_ ne $excluded_directory_name2 # Exclude the specifically named directory
 } readdir $dh;

closedir $dh;

my @only_these;
foreach my $filename (@filenames) {

    chomp  $filename;
    #print "2.$filename\n";
    push @only_these,$root.$filename;
}
$test->all_files_ok(@only_these);

#$test->all_files_ok($root);

$test->done_testing();
