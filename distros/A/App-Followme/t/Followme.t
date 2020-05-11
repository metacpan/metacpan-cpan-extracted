#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 9;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme;

my $test_dir = catdir(@path, 'test');
rmtree($test_dir);
mkdir $test_dir;
chmod 0755, $test_dir;
chdir $test_dir;

$test_dir = getcwd();

#----------------------------------------------------------------------
# Test set directory

do {
    my $app = App::Followme->new();

    my $config_file = catfile($test_dir, 'followme.cfg');
    $app->set_directories($config_file);

    my @dir_ok = splitdir($test_dir);
    my @base_directory = splitdir($app->{base_directory});
    my @test_directory = splitdir($app->{top_directory});

    is_deeply(\@base_directory, \@dir_ok, 'Set base directory'); # test 1
    is_deeply(\@test_directory, \@dir_ok, 'Set top directory'); # test 2
};

#----------------------------------------------------------------------
# Test run

do {
    my $app = App::Followme->new();

    chdir($test_dir);
    my $config = 'followme.cfg';
    my @config_files_ok = (catfile($test_dir, $config));

    fio_write_page($config, "remote_url = http://www.example.com\n");

    my $directory;
    foreach my $dir (qw(one two three)) {
        mkdir($dir);
        chmod 0755, $dir;
        chdir ($dir);
        $directory = getcwd();

        $config = catfile($directory, 'followme.cfg');
        push(@config_files_ok, $config);

        fio_write_page($config, "run_after = App::Followme::CreateSitemap\n");

        foreach my $file (qw(first.html second.html third.html)) {
            fio_write_page($file, "Fake data\n");
        }
    }

    my $config_files = $app->find_configuration($directory);
    is_deeply($config_files, \@config_files_ok, 'Find configuration'); # test 3
    $app->run($test_dir);

    my $count = 9;
    chdir($test_dir);
    foreach my $dir (qw(one two three)) {
        chdir ($dir);

        my $filename = rel2abs('sitemap.txt');
        ok(-e $filename, 'Ran create sitemap'); # test 4, 6, 8

        my $page = fio_read_page($filename);

        my @lines = split(/\n/, $page);
        is(@lines, $count, 'Right number of urls'); # test 5, 7, 9

        $count -= 3;
    }
};
