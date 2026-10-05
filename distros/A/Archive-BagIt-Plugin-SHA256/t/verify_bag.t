# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }
use strict;
use warnings;
use utf8;
use lib '../lib';
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 22;
use Test::Exception;
use File::Spec;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);

## tests
# verify incorrect manifest or tagmanifest-checksums

my @alg = qw(sha256);
my @prefix_manifestfiles = qw(tagmanifest manifest);

sub _prepare_bag {
    my ($bag_dir) = @_;
    mkpath($bag_dir . "/data");
    write_file("$bag_dir/data/payload1.txt", "PAYLOAD1" );
    write_file("$bag_dir/data/payload2.txt", "PAYLOAD2" );
    write_file("$bag_dir/data/payload3.txt", "PAYLOAD3" );
    return;
}

sub _modify_bag { # writes invalid checksum to a manifestfile
    my ($file_to_modify) = @_;
    my ($tm, $invalid_checksum);
    $tm = read_file($file_to_modify);
    $invalid_checksum = "0" x 32;
    $tm =~ s/^([\S]+)/$invalid_checksum/;
    write_file($file_to_modify, $tm);
    return;
}

### TESTS
note "base tests";
my $Class_base = 'Archive::BagIt';
use_ok($Class_base);
use_ok('Archive::BagIt::Plugin::Algorithm::SHA256');
foreach my $prefix (@prefix_manifestfiles) {
    foreach my $alg (@alg) {
        # preparation tests
        my $bag_dir = File::Temp::tempdir(CLEANUP => 1);
        _prepare_bag($bag_dir);
        my $bag_ok = Archive::BagIt->make_bag($bag_dir, {
            use_plugins => qw(Archive::BagIt::Plugin::Manifest::SHA256)
        });
        isa_ok($bag_ok, 'Archive::BagIt', "create new valid IE bagit");
        ok($bag_ok->verify_bag(), "check if bag is verified correctly");
        my $bag_ok2 = Archive::BagIt->make_bag("$bag_dir/",  {
            use_plugins => qw(Archive::BagIt::Plugin::Manifest::SHA256)
        }); #add slash at end of $bag_dir
        isa_ok($bag_ok2, 'Archive::BagIt', "create new valid IE bagit (with slash)");
        ok($bag_ok2->verify_bag(), "check if bag is verified correctly (with slash)");
        _modify_bag("$bag_dir/$prefix-$alg.txt");
    }

    # special test to ensure that return_all_errors work as expected
    note "return_all_errors tests";
    {
        my $bag_dir = File::Temp::tempdir(CLEANUP => 1);
        _prepare_bag($bag_dir);
        SKIP: {
        skip "skipped because testbag could not created", 1 unless -d $bag_dir;
        my $bag_ok = Archive::BagIt->make_bag($bag_dir, {
            use_plugins => qw(Archive::BagIt::Plugin::Manifest::SHA256)
        });
        isa_ok($bag_ok, 'Archive::BagIt', "create new valid IE bagit");
        ok($bag_ok->verify_bag(), "check if bag is verified correctly");
        write_file("$bag_dir/data/payload1.txt", "PAYLOAD_MODIFIED1");
        # write_file("$bag_dir/data/payload2.txt", "PAYLOAD2" );
        write_file("$bag_dir/data/payload3.txt", "PAYLOAD3_MODIFIED3");
        _modify_bag("$bag_dir/tagmanifest-sha256.txt");
        my $bag_invalid1 = new_ok("Archive::BagIt" => [ bag_path => $bag_dir, use_plugins => qw(Archive::BagIt::Plugin::Manifest::SHA256) ]);
        throws_ok(
            sub {
                $bag_invalid1->verify_bag()
            },
            qr{file.*'data/payload1.txt'.* invalid, digest.*'}s,
            "check if bag fails verification of broken fixity for payload (all errors)"
        );
        my $bag_invalid2 = new_ok("Archive::BagIt" => [ bag_path => $bag_dir, use_plugins => qw(Archive::BagIt::Plugin::Manifest::SHA256) ]);
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
}
1;
