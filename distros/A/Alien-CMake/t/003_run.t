
use Test::More;
use Alien::CMake;
use File::Spec;

plan tests => 1;

Alien::CMake->set_path;
my $devnull = File::Spec->devnull();
my $ver     = `cmake --version 2> $devnull`;

ok( $ver =~ /cmake version ([\d\.]+)/, "cmake version is $1" );
