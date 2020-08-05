#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile catdir rel2abs splitdir);

use Test::More tests => 9;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

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

    my $data_ok = {one => 1, two=> 2, three => 3, four => 4};
    while (my ($name, $value) = each %$data_ok) {
        App::Followme::Initialize::write_var($name, $value);
    }

    my $data = {};
    foreach my $name (keys %$data_ok) {
        $data->{$name} = App::Followme::Initialize::read_var($name);
    }

    is_deeply($data, $data_ok, "read and write vars"); # test 3

    my $config_lines = <<'EOQ';
# modules
run_before = App::Followme::FormatPage
run_before = App::Followme::ConvertPage
# test data
one = 1
two = 2
three = 3
four = 4
EOQ

    $data = {};
    my @lines = map {"$_\n"} split("\n", $config_lines);
    my $parser = App::Followme::Initialize::parse_configuration(\@lines);
    while (my ($name, $value) = &$parser()) {
        $data->{$name} = $value;
    }

    is_deeply($data, $data_ok, "parse configuration"); # test 4

    my $val = App::Followme::Initialize::read_configuration(\@lines, 'three');
    is($val, 3, "read configuration"); # test 5
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
    my $lines = App::Followme::Initialize::read_file($file);
    is_deeply($lines, \@ok_lines, "write text file"); # test 6

    $text = <<'EOQ';
# modules
run_before = App::Followme::FormatPage
run_before = App::Followme::ConvertPage
# version
version = 1
# test data
one = 1
two = 2
three = 3
four = 4
EOQ

    @ok_lines = map {"$_\n"} split("\n", $text);
    $type = 'configuration';
    $file = 'followme.cfg';
    my $version = 1;

    App::Followme::Initialize::write_file(\@ok_lines, $type, $file, $version);
    $lines = App::Followme::Initialize::read_file($file);
    is_deeply($lines, \@ok_lines, "write configuration file"); # test 7

    App::Followme::Initialize::write_file(\@ok_lines, $type, $file, $version);
    $lines = App::Followme::Initialize::read_file($file);
    is_deeply($lines, \@ok_lines, "rewrite configuration file"); # test 8

    $text = <<'EOQ';
R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7
EOQ

    my @lines = map {"$_\n"} split("\n", $text);
    $type = 'binary';
    $file = 'transparent.gif';
    App::Followme::Initialize::write_file(\@lines, $type, $file);

    ok(-e $file, 'write binary file'); # test 9
};
