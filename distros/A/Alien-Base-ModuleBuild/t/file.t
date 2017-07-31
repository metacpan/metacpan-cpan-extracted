use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::File;

my $file = Alien::Base::ModuleBuild::File->new();
isa_ok( $file, 'Alien::Base::ModuleBuild::File');

done_testing;
