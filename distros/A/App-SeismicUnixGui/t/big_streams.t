
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

my $root= 'lib/App/SeismicUnixGui/big_streams';

$test->all_files_ok($root);

$test->done_testing();