use strict;
use warnings;
use Test::More tests => 1;

use App::Sysadmin::Log::Simple;
use Test::Output;
use Path::Tiny 0.015; # touchpath

$ENV{'App::Sysadmin::Log::Simple::File under test'} = 1;
my $tmpdir = Path::Tiny->tempdir;
my $log = App::Sysadmin::Log::Simple->new(
    logdir  => $tmpdir,
    date    => '2011/02/19',
);

my $should = do { local $/; <DATA> };
path($tmpdir, qw/ 2011 2 19.log/)->touchpath->spew_utf8($should);

stdout_is sub { $log->run('view') }, $should, 'Reads the file ok';

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello
