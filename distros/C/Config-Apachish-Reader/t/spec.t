#!perl

use 5.010;
use strict;
use warnings;

use Config::Apachish::Reader;
use File::ShareDir::Tarball qw(dist_dir);
use JSON::MaybeXS;
use Test::Exception;
use Test::More 0.98;

my $dir = dist_dir('Apachish-Examples');
diag ".conf files are at $dir";

my $reader = Config::Apachish::Reader->new;

my $json = JSON::MaybeXS->new;

my @files = glob "$dir/examples/*.conf";
diag explain \@files;

for my $file (@files) {
    next if $file =~ /TODO-/;

    subtest "file $file" => sub {
        if ($file =~ /invalid-/) {
            dies_ok { $reader->read_file($file) } "dies";
        } else {
            my $res = $reader->read_file($file);
            my $expected = $json->decode(
                $reader->_read_file("$file.json")
            );
            is_deeply($res, $expected)
                or diag explain $res, $expected;
        };
    }
}

DONE_TESTING:
done_testing;
