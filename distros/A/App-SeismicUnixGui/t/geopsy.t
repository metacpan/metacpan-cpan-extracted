
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 5 tests for geopsy

=cut

=head1 Test for geopsy modules

ok tests if modules compile well

=cut

my $SeismicUnixGui;
use Test::Compile::Internal tests => 5;

my $test=Test::Compile::Internal->new();

my $root='lib/App/SeismicUnixGui/geopsy/';
$test->all_files_ok($root);

$test->done_testing();
