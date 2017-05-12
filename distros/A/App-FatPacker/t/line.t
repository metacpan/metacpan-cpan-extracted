use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use File::Temp qw/tempdir/;
use File::Spec;

use App::FatPacker;

chdir 't/line';

my $fp = App::FatPacker->new;
my $temp_fh = File::Temp->new;
select $temp_fh;
$fp->script_command_file([ 'line-test.pl' ]);
select STDOUT;
close $temp_fh;

# make sure we don't pick up things from our created dir
chdir File::Spec->tmpdir;

# Packed, now try using it. This should run the tests inside t/line/a.pm
do $temp_fh;
