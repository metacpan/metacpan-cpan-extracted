package CTDU_Testing;

use strict;
use warnings;

use CPAN::Testers::Data::Uploads;
use File::Path;

sub getObj {
  my %opts = @_;
  $opts{config} ||= \*DATA;
  $opts{update} = 1 unless(defined $opts{update});

  my $obj = CPAN::Testers::Data::Uploads->new(%opts);

  return $obj;
}

sub _cleanDir {
  my $dir = shift;
  if( -d $dir ){
    rmtree($dir) or return;
  }
  mkpath($dir) or return;
  return 1;
}

sub cleanDir {
  my $obj = shift;
  return _cleanDir( $obj->directory );
}

sub whackDir {
  my $obj = shift;
  my $dir = $obj->directory;
  if( -d $dir ){
    rmtree($dir) or return;
  }
  return 1;
}

1;

__DATA__

[MASTER]
BACKPAN=t/_DBDIR/BACKPAN/authors/id
CPAN=t/_DBDIR/CPAN/authors/id
logfile=t/_DBDIR/uploads.log
lastfile=t/_DBDIR/lastid.txt

[UPLOADS]
driver=SQLite
database=t/_DBDIR/test.db

[BACKUPS]
drivers=<<EOT
SQLite
CSV
EOT

[SQLite]
driver=SQLite
database=t/_DBDIR/uploads.db

[CSV]
driver=CSV
dbfile=t/_DBDIR/uploads.csv
