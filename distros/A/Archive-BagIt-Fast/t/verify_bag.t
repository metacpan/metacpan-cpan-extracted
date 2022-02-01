# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 33;
use Test::Exception;
use File::Spec;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);
use lib '../lib';

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
######## Fast

note "fast tests";
my $Class_fast = 'Archive::BagIt::Fast';
use_ok($Class_fast);
foreach my $prefix (@prefix_manifestfiles) {
  foreach my $alg (@alg) {
    # preparation tests
    my $bag_dir = File::Temp::tempdir(CLEANUP => 1);
    _prepare_bag($bag_dir);
    my $bag_ok = Archive::BagIt->make_bag($bag_dir);
    isa_ok($bag_ok, 'Archive::BagIt', "create new valid IE bagit");
    ok($bag_ok->verify_bag(), "check if bag is verified correctly");
    my $bag_ok2 = Archive::BagIt->make_bag("$bag_dir/"); #add slash at end of $bag_dir
    isa_ok($bag_ok2, 'Archive::BagIt', "create new valid IE bagit (with slash)");
    ok($bag_ok2->verify_bag(), "check if bag is verified correctly (with slash)");
    _modify_bag("$bag_dir/$prefix-$alg.txt");
    # real tests
    my $bag_invalid1 = new_ok("Archive::BagIt::Fast" => [ bag_path => $bag_dir ]);
    throws_ok(
      sub {
        $bag_invalid1->verify_bag(
          { return_all_errors => 1 }
        )
      }, qr{bag verify for bagit version '1.0' failed with invalid files}, "check if bag fails verification of broken $prefix-$alg.txt (all errors, fast)");
    my $bag_invalid2 = new_ok("Archive::BagIt::Fast" => [ bag_path => $bag_dir ]);
    throws_ok(
      sub {
        $bag_invalid2->verify_bag()
      }, qr{digest \($alg\) calculated=.*, but expected=}, "check if bag fails verification of broken $prefix-$alg.txt (first error, fast)");
  }
}

1;
