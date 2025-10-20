# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Spec;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);
use Test::More tests => 71;
use Test::File;
use Test::Warnings;
use lib '../lib';

my $special = '#--Ä--ä--Ö--ö--Ü--ü--ß--.[{!}].--$';
my $special_re = qr|#--Ä--ä--Ö--ö--Ü--ü--ß--\.\[\{!\}\]\.--\$|;

use_ok('Archive::BagIt');

{
    note("simple bag");
    my $dir = tempdir(CLEANUP => 1);
    mkdir(File::Spec->catdir($dir, "data"));
    write_file(File::Spec->catfile($dir, "data", "1.txt"), "1");
    ok(Archive::BagIt->make_bag($dir), "make_bag()");
    file_exists_ok(File::Spec->catfile($dir, "bag-info.txt"));
    file_exists_ok(File::Spec->catfile($dir, "bagit.txt"));
    file_exists_ok(File::Spec->catfile($dir, "data", "1.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-sha512.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-sha512.txt"));
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^BagIt-Version: 1.0$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^Tag-File-Character-Encoding: UTF-8$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bagging-Date: \d\d\d\d-\d\d-\d\d$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Software-Agent: Archive::BagIt}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Payload-Oxum: 1\.1$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Size: 1 B$}m);
}

{
    note ("bag with special filenames");
    my $dir = tempdir(CLEANUP => 1);
    mkdir(File::Spec->catdir($dir, "data"));
    my $subdir = File::Spec->catdir($dir, "data", $special);
    mkdir($subdir);
    my $datafile2 = File::Spec->catfile($dir, "data", "${special}1.txt");
    write_file(File::Spec->catfile($subdir, "1.txt"), "1");
    write_file($datafile2, "1");
    mkdir(File::Spec->catdir($dir, "meta"));
    write_file(File::Spec->catfile($dir, "meta", "rights.xml"));
    my $bag;
    my $warning = Test::Warnings::warning { $bag = Archive::BagIt->make_bag($dir) };
    like (
        $warning->[0] ,
        qr/possible non portable pathname detected/s,
        'Got expexted warning from make_bag()',
    ) or diag 'got unexpected warnings:' , explain($warning);
    like (
        $warning->[1] ,
        qr/possible non portable pathname detected/s,
        'Got expexted warning from make_bag()',
    ) or diag 'got unexpected warnings:' , explain($warning);
    isnt($bag->force_utf8(), 1, "force_utf8 set");
    isa_ok($bag, 'Archive::BagIt', "make_bag(), force_utf8");
    file_exists_ok(File::Spec->catfile($dir, "bag-info.txt"));
    file_exists_ok(File::Spec->catfile($dir, "bagit.txt"));
    file_exists_ok(File::Spec->catfile($subdir, "1.txt"));
    file_exists_ok($datafile2);
    file_exists_ok(File::Spec->catfile($dir, "manifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-sha512.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-sha512.txt"));
    file_contains_utf8_like(File::Spec->catfile($dir, "manifest-md5.txt"), $special_re );
    file_contains_utf8_like(File::Spec->catfile($dir, "manifest-sha512.txt"), $special_re );
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^BagIt-Version: 1.0$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^Tag-File-Character-Encoding: UTF-8$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bagging-Date: \d\d\d\d-\d\d-\d\d$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Software-Agent: Archive::BagIt}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Payload-Oxum: 2\.2$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Size: 2 B$}m);
}
{
    note ("bag with meta/ dir");
    my $dir = tempdir(CLEANUP => 1);
    mkdir(File::Spec->catdir($dir, "data"));
    my $subdir = File::Spec->catdir($dir, "data", $special);
    mkdir($subdir);
    my $datafile2 = File::Spec->catfile($dir, "data", "${special}1.txt");
    write_file(File::Spec->catfile($subdir, "1.txt"), "1");
    write_file($datafile2, "1");
    mkdir(File::Spec->catdir($dir, "meta"));
    write_file(File::Spec->catfile($dir, "meta", "rights.xml"));
    my $bag = Archive::BagIt->make_bag($dir, {force_utf8 => 1});
    isa_ok($bag, 'Archive::BagIt', "make_bag(), force_utf8");
    is($bag->force_utf8(), 1, "force_utf8 set");
    file_exists_ok(File::Spec->catfile($dir, "bag-info.txt"));
    file_exists_ok(File::Spec->catfile($dir, "bagit.txt"));
    file_exists_ok(File::Spec->catfile($subdir, "1.txt"));
    file_exists_ok($datafile2);
    file_exists_ok(File::Spec->catfile($dir, "manifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-sha512.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-sha512.txt"));
    file_contains_utf8_like(File::Spec->catfile($dir, "manifest-md5.txt"), $special_re );
    file_contains_utf8_like(File::Spec->catfile($dir, "manifest-sha512.txt"), $special_re );
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^BagIt-Version: 1.0$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^Tag-File-Character-Encoding: UTF-8$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bagging-Date: \d\d\d\d-\d\d-\d\d$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Software-Agent: Archive::BagIt}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Payload-Oxum: 2\.2$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Size: 2 B$}m);
}

{   # bag with 0-byte files
    note ("bag with empty payload file");
    my $dir = tempdir(CLEANUP => 1);
    mkdir(File::Spec->catdir($dir, "data"));
    write_file(File::Spec->catfile($dir, "data", "1.txt"), '');
    my $bag;
    my $warning = Test::Warnings::warning { $bag = Archive::BagIt->make_bag($dir) };
    like (
        $warning->[0] ,
        qr/empty file .* detected/,
        'Got expected warning from make_bag()',
    ) or diag 'got unexpected warnings:' , explain($warning);
    like (
        $warning->[1] ,
        qr/empty file .* detected/,
        'Got expected warning from make_bag()',
    ) or diag 'got unexpected warnings:' , explain($warning);
    ok ($bag,       "Object created");
    isa_ok ($bag, 'Archive::BagIt');
    file_exists_ok(File::Spec->catfile($dir, "bag-info.txt"));
    file_exists_ok(File::Spec->catfile($dir, "bagit.txt"));
    file_exists_ok(File::Spec->catfile($dir, "data", "1.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-md5.txt"));
    file_exists_ok(File::Spec->catfile($dir, "manifest-sha512.txt"));
    file_exists_ok(File::Spec->catfile($dir, "tagmanifest-sha512.txt"));
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^BagIt-Version: 1.0$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bagit.txt"), qr{^Tag-File-Character-Encoding: UTF-8$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bagging-Date: \d\d\d\d-\d\d-\d\d$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Software-Agent: Archive::BagIt}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Payload-Oxum: 0\.1$}m);
    file_contains_utf8_like(File::Spec->catfile($dir, "bag-info.txt"), qr{^Bag-Size: 0 B$}m);
}

1;
