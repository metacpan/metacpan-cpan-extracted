use Test::More;
use Test::Compile;


=head1 Test for messages modules

require_ok tests if a module or file loads successfully

=cut


=head2 Important definitions

5 tests for geopsy

=cut

my $SeismicUnixGui='./lib/App/SeismicUnixGui';
print("configs.t,SesmicUnixGui=$SeismicUnixGui\n");

=head2 import modules

=cut

use strict;
use warnings;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 Instantiation 

=cut

my $L_SU_global_constants = L_SU_global_constants->new();
my $test = Test::Compile->new();

my @dirs = ("$SeismicUnixGui/geopsy");
#print @dirs;
$test->all_files_ok(@dirs);
done_testing();
