use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::PlantUML;

use Path::Tiny;
use File::Which qw(which);

skip_all "Need Java for this test" unless which('java');

alien_diag 'Alien::PlantUML';
alien_ok 'Alien::PlantUML';

diag "Alien::PlantUML->jar_file: ", Alien::PlantUML->jar_file;

run_ok([ qw(java), '-jar', Alien::PlantUML->jar_file, '-version' ])
   ->success
   ->out_like(qr/PlantUML/);

done_testing;
