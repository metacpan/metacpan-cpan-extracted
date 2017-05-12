#!/usr/bin/perl
use strict;
use warnings;
use lib qw(lib ../lib);
use CPAN::Search::Lite::DBI::Index;
use CPAN::Search::Lite::DBI qw($dbh $tables);
use Getopt::Long;
my ($db, $user, $passwd, $help);
my $rc = GetOptions('db=s' => \$db,
                    'user=s' => \$user,
                    'passwd=s' => \$passwd,
                    'help' => \$help);

if ($help or not ($db and $user and $passwd)) {
    print <<"END";

    Fix up CPAN::Search::Lite database
Usage: 
   $^X $0 --db database --user me --passwd qpwoeiruty
   $^X $0 --help
END
    exit(1);
}

my $cdbi = CPAN::Search::Lite::DBI::Index->new(db => $db,
                                              user => $user,
                                              passwd => $passwd);

my %tables = map {$_ =~ s/['`]//g; $_ => 1} $dbh->tables();

my $sth = $dbh->prepare(qq{LISTFIELDS dists});

unless ($sth) {
   die "Error:" . $dbh->errstr . "\n";
}
unless ($sth->execute) {
   die "Error:" . $sth->errstr . "\n";
}

my $names = $sth->{NAME};
my $numFields = $sth->{'NUM_OF_FIELDS'};
my $has_md5 = 0;
for (my $i = 0;  $i < $numFields;  $i++) {
    $has_md5 ++ if ($$names[$i] eq 'md5');
}

foreach my $table(qw(chapters reps)) {
  if ($tables{$table}) {
    print "Altering '$table' ...\n";
  }
  my $obj = $cdbi->{objs}->{$table};
  next unless my $schema = $obj->schema($tables->{$table});
  $obj->drop_table or die "Dropping table $table failed";
  $obj->create_table($schema) or die "Creating table $table failed";
  $obj->populate or die "Populating $table failed";
}

$sth->finish;
my $sql = qq{SELECT mod_name,dist_name from mods,dists} .
    qq{ WHERE mods.dist_id = dists.dist_id} .
    qq{ AND LENGTH(mod_name) = 50 };
$sth = $dbh->prepare($sql);
unless ($sth) {
   die "Error:" . $dbh->errstr . "\n";
}
unless ($sth->execute) {
   die "Error:" . $sth->errstr . "\n";
}
my %check_dists;
if ($sth->rows > 0) {
  print << "END";

**************************************************************
There were some modules found with a name of length of 50 characters.
This may represent a bug in the previous schema for the mods
table, where module names were truncated to 50 characters.
The names of the associated distributions, reported below, have 
also been recorded in a file called 'reindex.txt' - after installation 
of this package, you may want to run
    csl_index --config /path/to/cpan.conf --reindex reindex.txt
to reindex these, so as the module name gets indexed properly.

END
  while (my($mod_name, $dist_name) = $sth->fetchrow_array) {
    $check_dists{$dist_name}++;
  }
  open(my $fh, '>reindex.txt') or die "Cannot open reindex.txt: $!";
  foreach (sort keys %check_dists) {
      print "     $_\n";
      print $fh "$_\n";
  }
  close $fh;
  print "**************************************************\n\n";
}
$sth->finish;

if ($has_md5) {
   print <<"END";
The modification to the 'dists' table is already in place
  (and presumably also to the 'mods' table). I'll skip
  the rest of the alterations.

END
   exit(1);
}

my %ids = (chaps => 'chap_id',
           reqs => 'req_id',
           ppms => 'ppm_id');

foreach my $table(keys %ids) {
  my $id = $ids{$table};
  my $sql = sprintf(qq{ALTER TABLE %s ADD %s SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, ADD INDEX (%s), ADD PRIMARY KEY (%s) }, $table, $id, $id, $id);
  $dbh->do($sql) or do {
    $dbh->disconnect;
    die "$sql failed";
  };
}

$sql = q{ALTER TABLE mods MODIFY mod_name VARCHAR(70) NOT NULL};
$dbh->do($sql) or do {
  $dbh->disconnect;
  die "$sql failed";
};

$sql = q{ALTER TABLE mods ADD src BOOL};
$dbh->do($sql) or do {
  $dbh->disconnect;
  die "$sql failed";
};

$sql = q{ALTER TABLE dists ADD md5 CHAR(32)};
$dbh->do($sql) or do {
  $dbh->disconnect;
  die "$sql failed";
};

$dbh->disconnect;
