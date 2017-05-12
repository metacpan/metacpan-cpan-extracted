# $Id: 06retrieve.t 53 2015-07-14 23:14:34Z stro $

use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec::Functions;
use File::Path;
use CPAN::DistnameInfo;
use FindBin;
use lib "$FindBin::Bin/lib";
use CPAN::SQLite::Index;

plan tests => 5;

my $cwd = getcwd;
my $CPAN = catdir $cwd, 't', 'cpan-t-06';

mkdir $CPAN;

ok (-d $CPAN);

my $info = CPAN::SQLite::Index->new(
  'CPAN' => $CPAN,
  'db_dir' => $cwd,
  'urllist' => ['http://search.cpan.org/CPAN/'],
);

isa_ok($info, 'CPAN::SQLite::Index');

SKIP: {
  skip 'Potential connection problems', 3 unless $info->fetch_cpan_indices();

  ok(-e catfile($CPAN, 'authors', '01mailrc.txt.gz'));
  ok(-e catfile($CPAN, 'modules', '02packages.details.txt.gz'));
  ok(-e catfile($CPAN, 'modules', '03modlist.data.gz'));

};
