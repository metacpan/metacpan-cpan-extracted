#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile catdir rel2abs splitdir);

use Test::More tests => 6;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::Initialize;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Test support functions

do {
    my $line = "#>>> copy text common followme.cfg";
    my $is = App::Followme::Initialize::is_command($line);
    is($is, " copy text common followme.cfg", "is command line"); # test 1

    $line = "run_before = App::Followme::FormatPage";
    $is = App::Followme::Initialize::is_command($line);
    is($is, undef, "is not command line"); # test 2
};

#----------------------------------------------------------------------
# Test write_file

do {
    my $text = <<EOQ;
Copyright 2015 by Bernie Simon
This file is licensed under thesame terms as Perl itself.
EOQ

    my @ok_lines = map {"$_\n"} split("\n", $text);
    my $type = 'text';
    my $file = 'license.txt';

    App::Followme::Initialize::write_file(\@ok_lines, $type, $file);
    my $page = fio_read_page($file);
    my @lines = map {"$_\n"} split("\n", $text);
    is_deeply(\@lines, \@ok_lines, "write text file"); # test 3

    $text = <<'EOQ';
# modules
run_before:
    - App::Followme::FormatPage
    - App::Followme::ConvertPage
# test data
one: 1
two: 2
three: 3
four: 4
EOQ

    @ok_lines = map {"$_\n"} split("\n", $text);
    $type = 'configuration';
    $file = 'followme.cfg';

    App::Followme::Initialize::write_file(\@ok_lines, $type, $file);
    my $page = fio_read_page($file);
    @lines = map {"$_\n"} split("\n", $text);
    is_deeply(\@lines, \@ok_lines, "write configuration file"); # test 4

    App::Followme::Initialize::write_file(\@ok_lines, $type, $file);
    $page = fio_read_page($file);
    @lines = map {"$_\n"} split("\n", $text);
    is_deeply(\@lines, \@ok_lines, "rewrite configuration file"); # test 5

    $text = <<'EOQ';
R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7
EOQ

    my @lines = map {"$_\n"} split("\n", $text);
    $type = 'binary';
    $file = 'transparent.gif';
    App::Followme::Initialize::write_file(\@lines, $type, $file);

    ok(-e $file, 'write binary file'); # test 6
};
