#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader;
use Parallel::ForkManager;
use Test::More tests => 104;
use t::lib::functions;


Log::Log4perl->get_logger("")->level("TRACE");

{

    my $test_dir = scratch_dir();

    my $repo = Data::Downloader::Repository->new(
        name           => "throttle",
        storage_root   => "$test_dir/root",
        cache_strategy => "LRU",
        cache_max_size => 1024 * 2,
        linktrees      => [
			   { root          => "$test_dir/trees", 
			     condition     => undef, 
			     path_template => "all" }
			   ],
    );

    $repo->save or BAIL_OUT $repo->error;
    $repo->load or BAIL_OUT $repo->error;
    is($repo->name, 'throttle', "made throttle repo");
    my $repo_id = $repo->id;
    ok($repo_id, "New repo id is $repo_id");

    ok(my $db = $repo->init_db, "Initialize DB") or BAIL_OUT $repo->error;

    my $pm = Parallel::ForkManager->new(20);

    for (1..50) {
        $pm->start and next;
        my $tmpfile = File::Temp->new;
        print $tmpfile "$_" x 1024;
        close $tmpfile or BAIL_OUT $!;

        my $file = Data::Downloader::File->new(
            filename   => "somefilename$_",
            on_disk    => 1,
            repository => $repo_id,
            url        => "file://$tmpfile",
        );
        eval {
            $file->download;
        };
        open my $fp, ">$test_dir/results.$_";
        print $fp "$@";
        close $fp;
        #print !$@ ? "ok $next\n" : "not ok $next# $@\n";
        #ok(!$@, "Downloaded file $_") or diag $@;
        $pm->finish;
    }

    $pm->wait_all_children;

    for (1..50) {
        my $file = "$test_dir/results.$_";
        ok(-e $file, "test ran");
        ok(-z $file, "Test produced no errors");
        next if (-z $file);
        diag "contents : ";
        open my $fp, "<$file";
        diag $_ for <$fp>;
        close $fp;
    }

    ok(test_cleanup($test_dir), "Test clean up");

}

1;

