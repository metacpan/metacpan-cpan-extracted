
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 45 tests for big_streams

=cut

=head1 Test for big_streams modules

ok tests if modules compile well

=cut

my $SeismicUnixGui;
use Test::Compile::Internal tests => 47;

my $test=Test::Compile::Internal->new();
my $root= 'lib/App/SeismicUnixGui/big_streams/';

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
