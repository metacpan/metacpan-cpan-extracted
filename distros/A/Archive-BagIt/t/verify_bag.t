# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 117;
use Test::Exception;
use strict;


use lib '../lib';

use File::Spec;
use Data::Printer;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);

my $Class = 'Archive::BagIt::Base';
use_ok($Class);

my @ROOT = grep {length} 'src';

#warn "what is this: ".Dumper(@ROOT);


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');

## tests
# verify incorrect manifest or tagmanifest-checksums

my @alg = qw( md5 sha512);
my @prefix_manifestfiles = qw(tagmanifest manifest);

sub _prepare_bag {
    my ($bag_dir) = @_;
    mkpath($bag_dir . "/data");
    write_file("$bag_dir/data/payload1.txt", "PAYLOAD1" );
    write_file("$bag_dir/data/payload2.txt", "PAYLOAD2" );
    write_file("$bag_dir/data/payload3.txt", "PAYLOAD3" );
}

sub _modify_bag { # writes invalid checksum to a manifestfile
    my ($file_to_modify) = @_;
    my ($tm, $invalid_checksum);
    $tm = read_file($file_to_modify);
    $invalid_checksum = "0" x 32;
    $tm =~ s/^([\S]+)/$invalid_checksum/;
    write_file($file_to_modify, $tm);
}

foreach my $prefix (@prefix_manifestfiles) {
    foreach my $alg (@alg) {
        my $bag_dir = File::Temp::tempdir(CLEANUP => 1);
        _prepare_bag($bag_dir);
        SKIP: {
            skip "skipped because testbag could not created", 1 unless -d $bag_dir;
            my $bag_ok = Archive::BagIt::Base->make_bag($bag_dir);
            isa_ok($bag_ok, 'Archive::BagIt::Base', "create new valid IE bagit");
            ok($bag_ok->verify_bag(), "check if bag is verified correctly");
            my $bag_ok2 = Archive::BagIt::Base->make_bag("$bag_dir/"); #add slash at end of $bag_dir
            isa_ok($bag_ok2, 'Archive::BagIt::Base', "create new valid IE bagit (with slash)");
            ok($bag_ok2->verify_bag(), "check if bag is verified correctly (with slash)");
            _modify_bag("$bag_dir/$prefix-$alg.txt");
            my $bag_invalid1 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);
            print "----\n";
            throws_ok(
                sub {
                    $bag_invalid1->verify_bag(
                        { return_all_errors => 1 }
                    )
                }, qr{bag verify for bagit version '1.0' failed with invalid files}, "check if bag fails verification of broken $prefix-$alg.txt (all errors)");

            my $bag_invalid2 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);
            throws_ok(
                sub {
                    $bag_invalid2->verify_bag()
                }, qr{digest \($alg\) calculated=.*, but expected=}, "check if bag fails verification of broken $prefix-$alg.txt (first error)");
        }
    }
}

# special test to ensure that return_all_errors work as expected
{
    my $bag_dir = File::Temp::tempdir(CLEANUP => 1);
    _prepare_bag($bag_dir);
    SKIP: {
        skip "skipped because testbag could not created", 1 unless -d $bag_dir;
        my $bag_ok = Archive::BagIt::Base->make_bag($bag_dir);
        isa_ok($bag_ok, 'Archive::BagIt::Base', "create new valid IE bagit");
        ok($bag_ok->verify_bag(), "check if bag is verified correctly");
        write_file("$bag_dir/data/payload1.txt", "PAYLOAD_MODIFIED1");
        # write_file("$bag_dir/data/payload2.txt", "PAYLOAD2" );
        write_file("$bag_dir/data/payload3.txt", "PAYLOAD3_MODIFIED3");
        _modify_bag("$bag_dir/tagmanifest-sha512.txt");
        _modify_bag("$bag_dir/tagmanifest-md5.txt");
        my $bag_invalid1 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);
        throws_ok(
            sub {
                $bag_invalid1->verify_bag()
            },
            qr{file.*'data/payload1.txt'.* invalid, digest.*'}s,
            "check if bag fails verification of broken fixity for payload (all errors)"
        );
 my $bag_invalid2 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);

        throws_ok(
            sub {
                $bag_invalid2->verify_bag(
                    { return_all_errors => 1 }
                )
            },
            qr{bag verify for bagit version '1.0' failed with invalid files.*file.*normalized='data/payload1.txt'.*file.*normalized='data/payload3.txt'.*file.*normalized='bag-info.txt'}s,
            "check if bag fails verification of broken fixity for payload (all errors)"
        );
    }
}
# tests against bagit conformance testsuite of Library of Congress, see README.1st in t/src/bagit_conformance_suite for details
{
    my @should_fail_bags_097 = (
        [ qw(../bagit_conformance_suite/v0.97/invalid/baginfo-missing-encoding), qr{Encoding line missed} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/bom-in-bagit.txt), qr{Version string '<BOM>BagIt-Version: 0\.97'.* is incorrect} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/corrupt-data-file), qr{file '.*' \(normalized='data/bare-filename'\) invalid, digest \(md5\).*} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/corrupt-tag-file), qr{file 'bag-info\.txt' \(normalized='.*'\) invalid, digest \(md5\).*} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/extra-file-in-bag), qr{file '.*' \(normalized='data/bar'\) found, which is not in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/invalid-version-number), qr{Version string 'BagIt-Version: \.97'.* is incorrect} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/missing-baginfo), qr{file 'bag-info\.txt' NOT found, but expected via 'tagmanifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/missing-bagit.txt), qr{Cannot read.*bagit\.txt} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/out-of-scope-file-paths-using-dot-notation-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/out-of-scope-file-paths-using-dot-notation), qr{file .*\./README\.md' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/invalid/same-filename-listed-twice-with-different-hashes), qr{Manifest.*manifest-md5\.txt.*does not exist for given bagit version '0\.97'} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-absolute-path), qr{file '/tmp/foo' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-shortcut-username-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-shortcut-username), qr{file '~root/foo' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-shortcut-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-shortcut), qr{file '~/foo' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/linux-only/out-of-scope-file-paths-using-absolute-path-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-absolute-path), qr{file 'C:\\Windows\\System32\\setx\.exe' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-shortcut-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-unc), qr{file '.*UNC\\server\\Windows\\System32\\setx\.exe' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-shortcut), qr{file '%HomeDrive%\\Windows\\System32\\setx\.exe' not allowed in 'manifest-md5\.txt'} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-unc-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        [ qw(../bagit_conformance_suite/v0.97/windows-only/out-of-scope-file-paths-using-absolute-path-for-fetch), qr{Fetching via file .*fetch\.txt.*not supported} ],
        #[qw(../bagit_conformance_suite/v0.97/warning/duplicate-file-with-different-case), "FOO"],
        #[qw(../bagit_conformance_suite/v0.97/warning/relative-path), "FOO"],
        #[qw(../bagit_conformance_suite/v0.97/warning/same-filename-listed-twice-with-different-normalization), "FOO"],
        #[qw(../bagit_conformance_suite/v0.97/warning/special-system-files), "FOO"],
        [ qw(../bagit_conformance_suite/v0.97/warning/made-with-md5sum-tools), qr{file '.*' \(normalized='data/hello.txt'\) found, which is not in 'manifest-md5.txt'} ], # <-- it first checks files in data/ and later the fixity. Here the fixity for paylod not found!
        #[qw(../bagit_conformance_suite/v0.97/warning/same-filename-listed-twice-with-the-same-hash), "FOO"],

    );
    my @should_fail_bags_100 = (
        # FIXME: next testcase does not work because missing sha256-checks
        #[qw(../bagit_conformance_suite/v1.0/invalid/same-filename-listed-twice-with-different-hashes), "FOO"],
        [qw(../bagit_conformance_suite/v1.0/invalid/missing-from-manifest), qr{file '.*' \(normalized='data/missingFromManifest\.txt'\) found, which is not in 'manifest-sha512\.txt'}],
        [qw(../bagit_conformance_suite/v1.0/invalid/bagit-with-invalid-whitespace), qr{Version string 'BagIt-Version : 1.0'.* is incorrect}],
    );
    my @should_pass_bags_100 = (
        [qw(../bagit_conformance_suite/v1.0/valid/basicBag), "bagit_conformance_suite/v1.0/valid/basicBag"],
    );
    my @should_pass_bags_097 = (
        [qw(../bagit_conformance_suite/v0.97/valid/uncommon-metadata-separators), "bagit_conformance_suite/v0.97/valid/uncommon-metadata-separators"],
        [qw(../bagit_conformance_suite/v0.97/valid/minimal-bag), "bagit_conformance_suite/v0.97/valid/minimal-bag"],
        [qw(../bagit_conformance_suite/v0.97/valid/basic-bag), "bagit_conformance_suite/v0.97/valid/basic-bag"],
        [qw(../bagit_conformance_suite/v0.97/valid/duplicate-metadata-entries), "bagit_conformance_suite/v0.97/valid/duplicate-metadata-entries"],
        [qw(../bagit_conformance_suite/v0.97/valid/bag-with-escapable-characters), "bagit_conformance_suite/v0.97/valid/bag-with-escapable-characters"],
        [qw(../bagit_conformance_suite/v0.97/valid/holey-bag), "bagit_conformance_suite/v0.97/valid/holey-bag"],
        [qw(../bagit_conformance_suite/v0.97/valid/bag-with-encoded-names), "bagit_conformance_suite/v0.97/valid/bag-with-encoded-names"],
        [qw(../bagit_conformance_suite/v0.97/valid/UTF-16-encoded-tag-files), "bagit_conformance_suite/v0.97/valid/UTF-16-encoded-tag-files"],
        [qw(../bagit_conformance_suite/v0.97/valid/bag-in-a-bag), "bagit_conformance_suite/v0.97/valid/bag-in-a-bag"],
        [qw(../bagit_conformance_suite/v0.97/valid/ISO-8859-1-encoded-tag-files), "bagit_conformance_suite/v0.97/valid/ISO-8859-1-encoded-tag-files"],
        [qw(../bagit_conformance_suite/v0.97/valid/bag-with-leading-dot-slash-in-manifest), "bagit_conformance_suite/v0.97/valid/bag-with-leading-dot-slash-in-manifest"],
        [qw(../bagit_conformance_suite/v0.97/valid/bag-with-space), "bagit_conformance_suite/v0.97/valid/bag-with-space"],
    );
    note "version 0.97 conformance tests";
    
    foreach my $entry (@should_fail_bags_097) {
        my $bagdir = $entry->[0];
        my $descr = $bagdir; $descr =~ s|../bagit_conformance_suite/||;
        my $expected = $entry->[1];
        my $bag = new_ok ("Archive::BagIt::Base" => [ bag_path => $bagdir ]);
        throws_ok(sub{ $bag->verify_bag();}, $expected, "conformance v0.97, fail: $descr");
    }
    foreach my $entry ( @should_pass_bags_097) {
        my $bagdir = $entry->[0];
        my $descr = $bagdir; $descr =~ s|../bagit_conformance_suite/||;
        my $expected = $entry->[1];
        my $bag = new_ok ("Archive::BagIt::Base" => [ bag_path => $bagdir ]);
        ok(sub{ $bag->verify_bag();}, "conformance v0.97, pass: $descr");
    }

    note "version 1.0 conformance tests";
    foreach my $entry ( @should_fail_bags_100) {
        my $bagdir = $entry->[0];
        my $descr = $bagdir; $descr =~ s|../bagit_conformance_suite/||;
        my $expected = $entry->[1];
        my $bag = new_ok ("Archive::BagIt::Base" => [ bag_path => $bagdir ]);
        throws_ok(sub{ $bag->verify_bag();}, $expected, "conformance v1.0, fail: $descr");
    }
    foreach my $entry ( @should_pass_bags_100) {
        my $bagdir = $entry->[0];
        my $descr = $bagdir; $descr =~ s|../bagit_conformance_suite/||;
        my $expected = $entry->[1];

        my $bag = new_ok ("Archive::BagIt::Base" => [ bag_path => $bagdir ]);
        ok(sub{ $bag->verify_bag();}, "conformance v1.0, pass: $descr");
    }

}


1;
