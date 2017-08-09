#!perl

use 5.010;
use strict;
use warnings;

use Config::IOD::Reader;
use File::ShareDir::Tarball qw(dist_dir);
use Test::Exception;
use Test::More 0.98;

my $dir = dist_dir('IOD-Examples');
diag ".IOD files are at $dir";

my $reader = Config::IOD::Reader->new(
    enable_expr => 1,
    expr_vars => {
        a => 2,
        b => 3,
        bar => "baz",
    },
);

my @files = (glob("$dir/examples/*.iod"), glob("$dir/examples/expr/*.iod"));
diag explain \@files;

for my $file (@files) {
    next if $file =~ /TODO-/;
    next if $file =~ /encoding-expr\.iod$/; # old file from older version

    subtest "file $file" => sub {
        if ($file =~ /invalid-/) {
            dies_ok { $reader->read_file($file) } "dies";
        } else {
            my $res = $reader->read_file($file);
            my $expected = $reader->_decode_json(
                $reader->_read_file("$file.json")
              );
            is_deeply($res, $expected->[2])
                or diag explain $res, $expected->[2];
        };
    }
}

DONE_TESTING:
done_testing;
