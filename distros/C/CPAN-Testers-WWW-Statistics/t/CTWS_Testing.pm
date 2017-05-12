package CTWS_Testing;

use strict;
use warnings;

#----------------------------------------------------------------------------
# Library Modules

use lib qw(./lib);

use CPAN::Testers::WWW::Statistics;
use CPAN::Testers::WWW::Statistics::Pages;
use CPAN::Testers::WWW::Statistics::Graphs;

use File::Basename;
use File::Find;
use File::Path;
use File::Spec;
use File::Temp;
use IO::File;
use Test::More;

#----------------------------------------------------------------------------
# Variables

my $parent;
my $config      = 't/_DBDIR/test-config.ini';
my $dbconfig    = 't/_DBDIR/databases.ini';

my $config_dir  = 't/_DBDIR';

$ENV{TZ} = 'GMT';

#----------------------------------------------------------------------------
# Core Object Methods

sub getObj {
    my %opts = @_;
    $opts{directory} ||= File::Spec->catfile('t','_TMPDIR');
    $opts{config}    ||= $config;

    _cleanDir( $opts{directory} ) or return;

    eval { $parent = CPAN::Testers::WWW::Statistics->new(%opts); };
    diag($@)    if($@);
    return $parent;
}

sub getPages {
    my $obj = CPAN::Testers::WWW::Statistics::Pages->new(parent => $parent);
    return $obj;
}

sub getGraphs {
    my $obj = CPAN::Testers::WWW::Statistics::Graphs->new(parent => $parent);
    return $obj;
}

#----------------------------------------------------------------------------
# File & Directory Methods

sub create_config {
    my $file1 = shift;
    my $file2 = join('/', dirname($dbconfig), basename($file1));

    my $fh1 = IO::File->new($file1,'r')     or die "cannot open file [$file1]: $!\n";
    my $fh2 = IO::File->new($file2,'w+')    or die "cannot write to file [$file2]: $!\n";
    while(<$fh1>) { print $fh2 $_; }
    $fh1->close;

    $fh1 = IO::File->new($dbconfig,'r')     or die "cannot open file [$dbconfig]: $!\n";
    while(<$fh1>) { print $fh2 $_; }
    $fh1->close;
    $fh2->close;

    return $file2;
}

sub has_environment {
    return 0    unless(-f $config);
    return 1;
}

sub _cleanDir {
  my $dir = shift;
  if( -d $dir ){ rmtree($dir) or return; }
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
  if( -d $dir ){ rmtree($dir) or return; }
  return 1;
}

sub listFiles {
  my $dir = shift;
  my @files;
  find({ wanted => sub { push @files, File::Spec->abs2rel($File::Find::name,$dir) if -f $_ } }, $dir)
      if(-d $dir);
  return sort @files;
}

sub saveFiles {
    my $dir = shift;

    mkpath("$dir/stats");
    mkpath("$dir/rates");

    my $fh = IO::File->new("$dir/stats/build1.txt",'w+');
    print $fh "#DATE,REQUESTS,PAGES,REPORTS\n20090715,32167,4304,21943\n20090716,43144,6573,16277\n20090717,37462,5942,21923\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats1.txt",'w+');
    print $fh "#DATE,UPLOADS,REPORTS,PASS,FAIL\n200810,2,0,0,0\n200811,3,4,0,4\n200812,1,2,2,0\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats2.txt",'w+');
    print $fh "#DATE,TESTERS,PLATFORMS,PERLS\n200810,0,0,0\n200811,3,4,2\n200812,2,1,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats3.txt",'w+');
    print $fh "#DATE,FAIL,NA,UNKNOWN\n200810,0,0,0\n200811,4,0,0\n200812,0,0,0\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats4.txt",'w+');
    print $fh "#DATE,ALL,FIRST,LAST\n200810,0,0,0\n200811,3,2,3\n200812,2,2,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats6.txt",'w+');
    print $fh "#DATE,AUTHORS,DISTROS\n200810,2,2\n200811,3,3\n200812,1,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats12.txt",'w+');
    print $fh "#DATE,AUTHORS,DISTROS\n200810,0,0\n200811,1,1\n200812,0,0\n";
    $fh->close;

    $fh = IO::File->new("$dir/rates/submit1.txt",'w+');
    print $fh "#INDEX,EXCLUSIVE,INCLUSIVE\n1,10,11\n2,11,12\n3,12,15\n4,11,12\n5,12,12\n6,14,14\n7,16,16\n8,17,17\n9,13,13\n10,14,14\n11,11,11\n12,15,15\n";
    $fh->close;

    $fh = IO::File->new("$dir/rates/submit2.txt",'w+');
    print $fh "#INDEX,EXCLUSIVE,INCLUSIVE\n1,10,11\n2,10,12\n3,10,13\n4,11,11\n5,11,11\n6,11,11\n7,11,11\n";
    $fh->close;

    $fh = IO::File->new("$dir/rates/submit3.txt",'w+');
    print $fh "#INDEX,EXCLUSIVE,INCLUSIVE\n1,10,11\n2,10,12\n3,10,13\n4,11,11\n5,11,11\n6,11,11\n7,11,11\n8,10,11\n9,10,12\n10,10,13\n11,10,11\n12,10,12\n13,10,13\n14,11,11\n15,11,11\n16,11,11\n17,11,11\n18,10,11\n19,10,12\n20,10,13\n21,10,11\n22,10,12\n23,10,13\n24,11,11\n25,11,11\n26,11,11\n27,11,11\n28,10,11\n29,10,12\n30,10,13\n31,10,11\n";
    $fh->close;

    $fh = IO::File->new("$dir/rates/submit4.txt",'w+');
    print $fh "#INDEX,EXCLUSIVE,INCLUSIVE\n1,10,11\n2,10,12\n3,10,13\n4,11,11\n5,11,11\n6,11,11\n7,11,11\n8,10,11\n9,10,12\n10,10,13\n11,10,11\n12,10,12\n13,10,13\n14,11,11\n15,11,11\n16,11,11\n17,11,11\n18,10,11\n19,10,12\n20,10,13\n21,10,11\n22,10,12\n23,10,13\n";
    $fh->close;
}

1;
