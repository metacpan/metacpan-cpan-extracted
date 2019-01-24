# $Id: 07download.t 73 2019-01-23 22:29:38Z stro $

use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec::Functions;
use File::Path;
use FindBin;
use lib "$FindBin::Bin/lib", 'lib', '../lib';
use TestShell;

use CPAN::SQLite::Index;

plan tests => 4;

my $cwd      = getcwd;
my $db_dir   = catdir $cwd, 't', 'cpan-t-07';
my $CPAN     = $db_dir;
my $log_dir  = $db_dir;
my $filename = 'cpansql.db';
my $filepath = catfile $db_dir, $filename;

unlink $filepath if -e $filepath;
mkdir $db_dir;

ok(-d $CPAN);
ok(-d $db_dir);

my $info = CPAN::SQLite::Index->new(
  'CPAN'    => $CPAN,
  'db_dir'  => $db_dir,
  'db_name' => $filename,
  'urllist' => ['http://search.cpan.org/CPAN/'],
);

isa_ok($info, 'CPAN::SQLite::Index');

SKIP: {
  $ENV{'CPAN_SQLITE_DOWNLOAD'}     = 1;
  $ENV{'CPAN_SQLITE_DOWNLOAD_URL'} = 'http://cpansqlite.trouchelle.com/';
  my $rv = $info->download_index();
  skip 'Potential connection problems', 1 unless $rv;
  ok(-e $filepath);
}

