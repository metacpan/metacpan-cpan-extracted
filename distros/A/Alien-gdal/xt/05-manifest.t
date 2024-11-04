use Test::CheckManifest;
use Test::More;

use Cwd;
my $cwd = getcwd();

TODO: {
    ok_manifest({filter => [qr/_alien/], exclude => "$cwd/_alien"});
};
