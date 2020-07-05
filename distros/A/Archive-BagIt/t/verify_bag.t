# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More tests => 53;
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
    write_file("$bag_dir/data/payload.txt", "PAYLOAD" );
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
            my $bag_ok3 = Archive::BagIt::Base->make_bag($bag_dir);
            ok($bag_ok3->parallel(1), "parallel => 1");
            isa_ok($bag_ok3, 'Archive::BagIt::Base', "create new valid IE bagit (parallel)");
            ok($bag_ok3->verify_bag(), "check if bag is verified correctly (parallel)");
            _modify_bag( "$bag_dir/$prefix-$alg.txt");
            my $bag_invalid1 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);
            throws_ok(
                sub {
                    $bag_invalid1->verify_bag(
                        { return_all_errors => 1 }
                    )
                }, qr{bag verify for bagit 1.0 failed with invalid files}, "check if bag fails verification of broken $prefix-$alg.txt (all errors)");
            my $bag_invalid_parallel = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir, parallel => 1 ]);
            throws_ok(
                sub {
                    $bag_invalid_parallel->verify_bag(
                        { return_all_errors => 1 }
                    )
                }, qr{bag verify for bagit 1.0 failed with invalid files}, "check if bag fails verification of broken $prefix-$alg.txt (parallel, all errors)");
            my $bag_invalid2 = new_ok("Archive::BagIt::Base" => [ bag_path => $bag_dir ]);
            throws_ok(
                sub {
                    $bag_invalid2->verify_bag()
                }, qr{digest \($alg\) calculated=.*, but expected=}, "check if bag fails verification of broken $prefix-$alg.txt (first error)");
        }
    }
}



1;