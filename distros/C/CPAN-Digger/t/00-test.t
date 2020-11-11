use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec ();
use Capture::Tiny qw(capture);


subtest recent_in_memory => sub {
    my ($out, $err, $exit) = capture {
        system($^X, '-Ilib', 'bin/cpan-digger', '--recent', '2', '--log', 'OFF');
    };

    is $exit, 0;
    is $err, '';
    is $out, '';
};

subtest author_in_memory => sub {
    my ($out, $err, $exit) = capture {
        system($^X, '-Ilib', 'bin/cpan-digger', '--author', 'SZABGAB', '--log', 'OFF');
    };

    is $exit, 0;
    is $err, '';
    is $out, '';
};

subtest author_in_file => sub {
    my $tempdir = tempdir( CLEANUP => 1 );
    my $db_file = File::Spec->join($tempdir, 'cpandigger');

    my ($out, $err, $exit) = capture {
        system($^X, '-Ilib', 'bin/cpan-digger', '--db', $db_file, '--author', 'SZABGAB', '--log', 'OFF');
    };

    ok -e $db_file;
    is $exit, 0;
    is $err, '';
    is $out, '';

    # run it again
    ($out, $err, $exit) = capture {
        system($^X, '-Ilib', 'bin/cpan-digger', '--db', $db_file, '--author', 'SZABGAB', '--log', 'OFF');
    };

    is $exit, 0;
    is $err, '';
    is $out, '';
};




done_testing();
