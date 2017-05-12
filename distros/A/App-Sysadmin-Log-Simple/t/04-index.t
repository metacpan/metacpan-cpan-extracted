use strict;
use warnings;

use Path::Tiny;
use IO::Scalar;
use Test::More tests => 5;
use Test::Output;
use App::Sysadmin::Log::Simple;
use App::Sysadmin::Log::Simple::File;

my $rand = rand;
my $logentry = IO::Scalar->new(\$rand);
my $date = '2013/8/14';

my $tmpdir = Path::Tiny->tempdir;
my $log = new_ok('App::Sysadmin::Log::Simple' => [
    logdir      => $tmpdir,
    read_from   => $logentry,
    date        => $date,
]);

my $file_logger = new_ok('App::Sysadmin::Log::Simple::File' => [logdir => $tmpdir]);
$file_logger->_generate_index();

my $idx_old = path($tmpdir, 'index.log')->slurp_utf8;
stdout_like
    sub { $log->run() }, # will read from $logentry
    qr/Log entry:/,
    'log ok';
my $idx_new = path($tmpdir, 'index.log')->slurp_utf8;

isnt $idx_old, $idx_new, 'The index did change';
like $idx_new, qr{\Q($date)\E}, 'The date we wanted appears in the index';
