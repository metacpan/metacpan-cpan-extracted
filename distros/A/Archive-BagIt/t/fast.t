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
use File::Temp qw(tempdir tempfile);
use File::Slurp qw( read_file write_file);

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


##
# prepare tempfile
use_ok('Archive::BagIt::Plugin::Algorithm::MD5');
use_ok('Archive::BagIt::Plugin::Algorithm::SHA512');
my $obj2 = new_ok('Archive::BagIt::Fast');
my $digest_obj_md5 = new_ok('Archive::BagIt::Plugin::Algorithm::MD5', [ bagit => $obj2 ]);
my $digest_obj_sha = new_ok('Archive::BagIt::Plugin::Algorithm::SHA512', [ bagit => $obj2 ]);

my $tempdir =tempdir(CLEANUP => 1);
{
    my $filename = "$tempdir/emptyfile";
    write_file($filename, "");
    open my $fh, "<:raw", "$filename" or die "could not open $filename, $!";
    use_ok('Archive::BagIt::Fast');
    is(Archive::BagIt::Fast::sysread_based_digest($digest_obj_md5, $fh, 0), 'd41d8cd98f00b204e9800998ecf8427e', '_small_digest, empty, md5');
    is(Archive::BagIt::Fast::sysread_based_digest($digest_obj_sha, $fh, 0), 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', '_small_digest, empty, sha');
    is(Archive::BagIt::Fast::mmap_based_digest($digest_obj_md5, $fh, 0), 'd41d8cd98f00b204e9800998ecf8427e', '_large_digest, empty, md5');
    is(Archive::BagIt::Fast::mmap_based_digest($digest_obj_sha, $fh, 0), 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', '_large_digest, empty, sha');
    close($fh);
}
{
    my $filename = "$tempdir/5bytefile";
    write_file($filename, "hello");
    open my $fh, "<:raw", "$filename" or die "could not open $filename, $!";
    seek($fh, 0, 0);
    is(Archive::BagIt::Fast::sysread_based_digest($digest_obj_md5, $fh, 5), '5d41402abc4b2a76b9719d911017c592', '_small_digest, 5bytes, md5');
    seek($fh, 0, 0);
    is(Archive::BagIt::Fast::sysread_based_digest($digest_obj_sha, $fh, 5), '9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043', '_small_digest, 5byts, sha');
    seek($fh, 0, 0);
    is(Archive::BagIt::Fast::mmap_based_digest($digest_obj_md5, $fh, 5), '5d41402abc4b2a76b9719d911017c592', '_large_digest, 5bytes, md5');
    seek($fh, 0, 0);
    is(Archive::BagIt::Fast::mmap_based_digest($digest_obj_sha, $fh, 5), '9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043', '_large_digest, 5bytes, sha');
    seek($fh, 0, 0);
    is($digest_obj_md5->get_hash_string($fh), '5d41402abc4b2a76b9719d911017c592', 'get_hash_string, 5bytes, md5');
    seek($fh, 0, 0);
    is($digest_obj_sha->get_hash_string($fh), '9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043', 'get_hash_string, 5bytes, sha512');
    close($fh);
}
done_testing();

__END__
