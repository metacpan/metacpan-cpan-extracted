use strict;
use warnings;

use Test::More;
use File::Temp 'tempdir';
use FindBin;
use File::Spec::Functions qw/catfile catdir updir/;
use Carp;
my $mhere = catfile( $FindBin::Bin, updir, 'bin', 'mhere' );

my $dir = tempdir( CLEANUP => 1 );
local $ENV{APP_MODULES_HERE} = $dir;
my $out = `$^X $mhere strict --dry-run`;
my $dest = catfile( $dir, 'strict.pm' );
like( $out, qr/going to copy '.*strict\.pm' to '\Q$dest\E'/, 'dry-run output' );
unlike( $out, qr/copied/, 'no copied msg' );
ok( !-e catfile( $dir, 'strict.pm' ), 'strict.pm is indeed not copied' );

SKIP: {
    eval { require File::Copy::Recursive };
    skip 'need File::Copy::Recursive to use -r', 3 if $@;
    my $out = `$^X $mhere Carp -r --dry-run`;
    $dest = catfile( $dir, 'Carp' );
    like(
        $out,
        qr/going to copy '.*Carp\.pm' to '\Q$dest.pm\E'/,
        'dry-run output'
    );

    like(
        $out,
        qr/going to copy '.*Carp' to '\Q$dest\E'/,
        'dry-run output with -r'
    );
    unlike( $out, qr/copied/, 'no copied msg' );

    ok( !-e catfile( $dir, 'Carp.pm' ), 'Carp.pm is indeed not copied' );
    ok( !-e catfile( $dir, 'Carp' ),    'Carp dir is indeed not copied' );
}

done_testing();
