BEGIN { chdir 't' if -d 't' }
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More;
use Test::Warnings;
use strict;

use lib '../lib';

use File::Spec;
use File::Path;
use File::Copy;

plan skip_all => "IO::AIO required for testing Archive::BagIt::Fast"
    unless eval "use IO::AIO; 1";


my $Class     = 'Archive::BagIt::Fast';
my $ClassBase = 'Archive::BagIt';

use_ok($Class);
use_ok($ClassBase);

my @ROOT = grep { length } 'src';

my $SRC_BAG   = File::Spec->catdir( @ROOT, 'src_bag' );
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files' );
my $DST_BAG   = File::Spec->catdir( @ROOT, 'dst_bag' );

{
    # Still using old interface
    my $bag = $Class->new($SRC_BAG);
    ok( $bag, "Object created" );
    isa_ok( $bag, $Class );

    my $result = $bag->verify_bag;
    ok( $result, "Bag verifies" );
}

{
    note "copying to $DST_BAG";
    if ( -d $DST_BAG ) {
        rmtree($DST_BAG);
    }
    mkdir($DST_BAG);
    copy( $SRC_FILES . "/1",       $DST_BAG );
    copy( $SRC_FILES . "/2",       $DST_BAG );
    copy( $SRC_FILES . "/thréê", $DST_BAG );

    note "making bag $DST_BAG";
    my $bag;
    my $warning =
        Test::Warnings::warning { $bag = $Class->make_bag($DST_BAG) };
    like(
        $warning,
        qr/no payload path/,
        'Got expected warning from make_bag()',
    ) or diag 'got unexpected warnings:', explain($warning);
    ok( $bag, "Object created" );
    isa_ok( $bag, $Class );
    my $result = $bag->verify_bag();
    ok( $result, "Bag verifies" );
    rmtree($DST_BAG);
}

{
    note "copying to $DST_BAG";
    if ( -d $DST_BAG ) {
        rmtree($DST_BAG);
    }
    mkdir($DST_BAG);
    copy( $SRC_FILES . "/1",       $DST_BAG );
    copy( $SRC_FILES . "/2",       $DST_BAG );
    copy( $SRC_FILES . "/thréê", $DST_BAG );

    note "making bag via $ClassBase at $DST_BAG";
    my $bag;
    my $warning =
      Test::Warnings::warning { $bag = $ClassBase->make_bag($DST_BAG) };
    like(
        $warning,
        qr/no payload path/,
        'Got expected warning from make_bag()',
    ) or diag 'got unexpected warnings:', explain($warning);
    ok( $bag, "Object created" );
    isa_ok( $bag, $ClassBase );
    $bag = $Class->new($DST_BAG);
    ok( $bag, "Object created" );
    isa_ok( $bag, $Class );
    my $result = $bag->verify_bag;
    ok( $result, "Bag verifies" );
    rmtree($DST_BAG);
}

done_testing();

__END__
