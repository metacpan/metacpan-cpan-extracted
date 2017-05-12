# Copyright (c) 2008 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;
use Exception::Class::TryCatch qw/try catch/;
use File::Basename qw/basename/;
use File::Find qw/find/;
use IO::CaptureOutput 1.0801 qw/capture/;
use IO::File;
use Path::Class;
use File::Temp 0.20 qw/tempdir tmpnam/;
use Test::More 0.62;

plan tests => 30;

require_ok('App::CPAN::Mini::Visit');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $exe = basename $0;
my ( $stdout, $stderr );
my $tempdir    = tempdir( CLEANUP => 1 );
my $minicpan   = dir(qw/t CPAN/);
my $archive_re = qr{\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|zip|pm\.gz)$}i;

my @files;
find(
    {
        follow   => 0,
        no_chdir => 1,
        wanted   => sub { push @files, $_ if -f && /\.tar\.gz$/ },
    },
    dir( $minicpan, qw/ authors id / )->absolute
);
@files = sort @files;

sub _create_minicpanrc {
    my $rc_fh = IO::File->new( file( $tempdir, '.minicpanrc' ), ">" );
    print {$rc_fh} "$_[0]\n" || "\n";
    close $rc_fh;
}

#--------------------------------------------------------------------------#
# Option: version
#--------------------------------------------------------------------------#

for my $opt (qw/ --version -V /) {
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run($opt);
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    is( $stderr, "$exe: $App::CPAN::Mini::Visit::VERSION\n", "[$opt] correct" )
      or diag $err;
}

#--------------------------------------------------------------------------#
# Option: help
#--------------------------------------------------------------------------#

for my $opt (qw/ --help -h /) {
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run($opt);
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    like( $stderr, qr/^Usage:/, "[$opt] correct" ) or diag $err;
}

#--------------------------------------------------------------------------#
# minicpan -- no minicpanrc and no --minicpan should fail with error
#--------------------------------------------------------------------------#

# homedir for testing
local $ENV{HOME} = $tempdir;

# should have error here
{
    my $label = "no minicpan config";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run();
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    like( $stderr, qr/^No minicpan configured/, "[$label] error message correct" )
      or diag $err;
}

# missing minicpan directory should have error
my $bad_minicpan = 'doesntexist';
_create_minicpanrc("local: $bad_minicpan");
{
    my $label = "missing minicpan dir";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run();
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    like(
        $stderr,
        qr/^Directory '$bad_minicpan' does not appear to be a CPAN repository/,
        "[$label] error message correct"
    ) or diag $err;
}

# badly structured minicpan directory should have error
$bad_minicpan = dir( $tempdir, 'CPAN' );
mkdir $bad_minicpan;
_create_minicpanrc("local: $bad_minicpan");
{
    my $label = "bad minicpan dir";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run();
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    like(
        $stderr,
        qr/^Directory '\Q$bad_minicpan\E' does not appear to be a CPAN repository/,
        "[$label] error message correct"
    ) or diag $err;
}

# good minicpan directory (from options -- overrides bad config)
for my $opt (qw/ --minicpan -m /) {
    my $label = "good $opt=...";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run("$opt=$minicpan");
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    is( $stderr, "", "[$label] no error message" ) or diag $err;
}

# good minicpan directory (from config only)
_create_minicpanrc("local: $minicpan");
{
    my $label = "good minicpan from config";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run();
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    is( $stderr, "", "[$label] no error message" ) or diag $err;
}

# bad minicpan directory (from options -- overrides bad config)
{
    my $label = "bad -m=...";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run("-m=$bad_minicpan");
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    like(
        $stderr,
        qr/^Directory '\Q$bad_minicpan\E' does not appear to be a CPAN repository/,
        "[$label] error message correct"
    ) or diag $err;
}

#--------------------------------------------------------------------------#
# default behavior -- list files
#--------------------------------------------------------------------------#

{
    my $label = "list files";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run();
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    my @found = split /\n/, $stdout;
    is_deeply( \@found, \@files, "[$label] listing correct" );
}

#--------------------------------------------------------------------------#
# run program
#--------------------------------------------------------------------------#

{
    my $label = "pwd";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run( "--", $^X, '-e',
                'use Cwd qw/abs_path/; print abs_path(".") . "\n"' );
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    my @found =
      map { dir($_)->relative( dir($_)->parent ) } split /\n/, $stdout;
    my @expect = map {
        my $base = file($_)->basename;
        $base =~ s{$archive_re}{};
        $base;
    } @files;
    ok( length $stdout, "[$label] got stdout" ) or diag $err;
    is_deeply( \@found, \@expect, "[$label] listing correct" )
      or diag "STDOUT:\n$stdout\nSTDERR:\n$stderr\n";
}

#--------------------------------------------------------------------------#
# run perl -e
#--------------------------------------------------------------------------#

{
    my $label = "perl-e";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run( '-e',
                'use Cwd qw/abs_path/; print abs_path(".") . "\n"' );
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    my @found =
      map { dir($_)->relative( dir($_)->parent ) } split /\n/, $stdout;
    my @expect = map {
        my $base = file($_)->basename;
        $base =~ s{$archive_re}{};
        $base;
    } @files;
    ok( length $stdout, "[$label] got stdout" ) or diag $err;
    is_deeply( \@found, \@expect, "[$label] listing correct" )
      or diag "STDOUT:\n$stdout\nSTDERR:\n$stderr\n";
}

#--------------------------------------------------------------------------#
# run perl -E
#--------------------------------------------------------------------------#

{
    my $label = "perl-E";
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run( '-E',
                'use Cwd qw/abs_path/; print abs_path(".") . "\n"' );
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    my @found =
      map { dir($_)->relative( dir($_)->parent ) } split /\n/, $stdout;
    my @expect = map {
        my $base = file($_)->basename;
        $base =~ s{$archive_re}{};
        $base;
    } @files;
    ok( length $stdout, "[$label] got stdout" ) or diag $err;
    is_deeply( \@found, \@expect, "[$label] listing correct" )
      or diag "STDOUT:\n$stdout\nSTDERR:\n$stderr\n";
}

#--------------------------------------------------------------------------#
# --append path
#--------------------------------------------------------------------------#

{
    my $label = "path";
    for my $opt (qw/ --append -a /) {
        try eval {
            capture sub {
                App::CPAN::Mini::Visit->run( "$opt=path", "--", $^X, '-e',
                    'print shift(@ARGV) . "\n"' );
              } => \$stdout,
              \$stderr;
        };
        catch my $err;
        my @found = split /\n/, $stdout;
        my @expect = @files;
        ok( length $stdout, "[$label] ($opt) got stdout" ) or diag $err;
        is_deeply( \@found, \@expect, "[$label] ($opt) listing correct" )
          or diag "STDOUT:\n$stdout\nSTDERR:\n$stderr\n";
    }
}

#--------------------------------------------------------------------------#
# --append dist
#--------------------------------------------------------------------------#

{
    my $label = "dist";
    for my $opt (qw/ --append -a /) {
        try eval {
            capture sub {
                App::CPAN::Mini::Visit->run( "$opt=dist", "--", $^X, '-e',
                    'print shift(@ARGV) . "\n"' );
              } => \$stdout,
              \$stderr;
        };
        catch my $err;
        my @found = split /\n/, $stdout;
        my $prefix = dir( $minicpan, qw/ authors id / )->absolute;
        my @expect = map {
            ( my $file = $_ ) =~ s{$prefix[/\\].[/\\]..[/\\]}{};
            $file;
        } @files;
        ok( length $stdout, "[$label] ($opt) got stdout" ) or diag $err;
        is_deeply( \@found, \@expect, "[$label] ($opt) listing correct" )
          or diag "STDOUT:\n$stdout\nSTDERR:\n$stderr\n";
    }
}

#--------------------------------------------------------------------------#
# --output file
#--------------------------------------------------------------------------#

{
    my $label    = "output";
    my $tempfile = tmpnam();
    try eval {
        capture sub {
            App::CPAN::Mini::Visit->run("--output=$tempfile");
          } => \$stdout,
          \$stderr;
    };
    catch my $err;
    ok( -f $tempfile, "[$label] output file created" );
    my @found = map { chomp; $_ } do { local @ARGV = ($tempfile); <> };
    is( $stdout, '', "[$label] saw no output on terminal" );
    is_deeply( \@found, \@files, "[$label] listing correct" );
}

