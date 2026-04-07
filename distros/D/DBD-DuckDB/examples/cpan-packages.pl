#!perl

use strict;
use warnings;
use v5.16;

use DBI;
use CPAN::DistnameInfo;
use Data::Dumper;

my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:') or Carp::croak DBI->errstr;

my $cpan_02packages_txt_url = 'https://cpan.metacpan.org/modules/02packages.details.txt';

my $search = shift || 'DBD::%';

my $sql = <<'SQL';
WITH lines AS (
  SELECT string_split_regex(column0, '\s+') AS parts
  FROM read_csv(?, skip=8)
) SELECT
  parts[1] AS package_name,
  parts[2] AS version,
  parts[3] AS path
FROM lines
WHERE package_name LIKE ?
ORDER BY package_name
SQL

my $sth = $dbh->prepare($sql);
$sth->execute($cpan_02packages_txt_url, $search);

my %dist = ();

while (my $row = $sth->fetchrow_hashref) {
    my $d = CPAN::DistnameInfo->new($row->{path});
    push @{$dist{$d->dist}}, $row;
}

for my $distname (sort keys %dist) {
    say "$distname:";
    for my $pkg (@{$dist{$distname}}) {
        say "  - $pkg->{package_name} ($pkg->{version})";
    }
    say "\n";
}

$dbh->disconnect;
