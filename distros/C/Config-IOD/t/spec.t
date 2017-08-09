#!perl

use 5.010;
use strict;
use warnings;

use Config::IOD;
use File::ShareDir::Tarball qw(dist_dir);
use File::Slurper 'read_text';
use Test::Differences;
use Test::Exception;
use Test::More 0.98;

my $dir = dist_dir('IOD-Examples');
diag ".IOD files are at $dir";

my $iod = Config::IOD->new(
    enable_expr => 1,
    expr_vars => {
        a => 2,
        b => 3,
        bar => 'baz',
    },
);

my @files = (glob("$dir/examples/*.iod"), glob("$dir/examples/expr/*.iod"));
diag explain \@files;

for my $file (@files) {
    next if $file =~ /TODO-/;

    # skip some files, because raw parsing in ciod doesn't check valid encoding
    next if $file =~ m![/\\](
                           invalid-encoding|
                           invalid-encoding-json|
                           invalid-encoding-unknown
                       )\.iod$!x;

    subtest "file $file" => sub {
        if ($file =~ /invalid-/) {
            dies_ok { $iod->read_file($file) } "dies";
        } else {
            my $orig_content = read_text($file);
            my $doc;
            lives_ok { $doc = $iod->read_file($file) } "lives"
                or return;
            #is $doc->as_string, $orig_content, "round-trip";
            eq_or_diff $doc->as_string, $orig_content, "round-trip";
        };
    }
}

DONE_TESTING:
done_testing;
