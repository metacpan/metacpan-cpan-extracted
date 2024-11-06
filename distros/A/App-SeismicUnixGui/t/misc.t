
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
my $inbound = 't/misc_files.txt';
open (IN,'<',$inbound) or die $!;

	my $line;
	my $i=0;
	my @only_these;
	# read contents of file
	while ( $line = <IN> ) {

		# print("\n$line");
		chomp($line);
		push @only_these,$root.$line;
#		print("$only_these[$i]\n");	
		$i++;
		
	}

	close(IN);
	

$test->all_files_ok(@only_these);

$test->done_testing();
