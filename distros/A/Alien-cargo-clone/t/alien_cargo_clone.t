use Test2::V0 -no_srand => 1;
use Alien::cargo::clone;
use Test::Alien;
use Path::Tiny ();

my $dir = Path::Tiny->tempdir;

alien_ok 'Alien::cargo::clone';

run_ok(['cargo','clone','true','--',$dir])
  ->success;

ok -f "$dir/Cargo.toml";

done_testing;


