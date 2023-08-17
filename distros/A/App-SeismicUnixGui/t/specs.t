
=head2 import modules

=cut

use strict;
use warnings;

=head2 Important definitions

 297 tests for specs

=cut

=head1 Test for specs modules

ok tests if modules compile well

=cut

my $SeismicUnixGui;
use Test::Compile::Internal tests => 303;

my $test=Test::Compile::Internal->new();

my $root= 'lib/App/SeismicUnixGui/specs';

$test->all_files_ok($root);

$test->done_testing();