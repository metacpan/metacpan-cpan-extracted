package testdata::setup;
use strict;
use warnings;
use 5.010;

use File::Temp qw(tempdir);
use Path::Class;
use File::Copy::Recursive qw(dircopy);

sub tmpdir {
    my $tempdir = Path::Class::Dir->new(tempdir(CLEANUP=>$ENV{NO_CLEANUP} ? 0 : 1));
    return $tempdir;
}

my %runs = (
    'run_1' => 1329762000, #2012-02-20T19:20:00
    'run_2' => 1329766800, #2012-02-20T20:40:00
);

sub run {
    my ($tempdir, $run) = @_;
    my $src = Path::Class::dir(qw(t testdata),$run);

    dircopy($src,$tempdir->subdir($run)) || die $!;
    my $mtime = $runs{$run};
    utime($mtime,$mtime,$tempdir->file($run,'coverage.html')->stringify);
    return $tempdir->subdir($run);
}

1;
