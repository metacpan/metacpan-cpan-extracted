
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 12 tests for configs

=cut

=head1 Test for configs modules

ok tests if modules compile well

=cut

my $SeismicUnixGui;
use Test::Compile::Internal tests => 11;

my $test=Test::Compile::Internal->new();

my $root='lib/App/SeismicUnixGui/configs/';
$test->all_files_ok($root);

$test->done_testing();