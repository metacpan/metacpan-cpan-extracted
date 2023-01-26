
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 4 tests for script

=cut

=head1 Test for *.pl scripts

ok tests if modules compile well

=cut

my $SeismicUnixGui;
use Test::Compile::Internal tests => 5;

my $test=Test::Compile::Internal->new();

my $root='lib/App/SeismicUnixGui/script/';
$test->all_files_ok($root);

$test->done_testing();
