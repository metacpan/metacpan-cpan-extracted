#!perl

use strict;
use warnings;
use v5.16;

use DBI;
use CPAN::DistnameInfo;
use Data::Dumper;

my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:') or Carp::croak DBI->errstr;

my $cpan_02packages_txt_url = 'https://cpan.metacpan.org/modules/02packages.details.txt';
my $search = 'DBD::%';

my $sql = q{
SELECT string_split_regex(column0, '\s+')
  FROM read_csv(?, skip=8)
 WHERE column0 LIKE ?
};

my $sth = $dbh->prepare($sql);
$sth->execute($cpan_02packages_txt_url, $search);

my %dist = ();

while (my $row = $sth->fetchrow_arrayref) {
	my ($package_name, $version, $path) = @{$row->[0]};
	my $d = CPAN::DistnameInfo->new($path);
	push @{$dist{$d->dist}}, $package_name;
}

say Dumper(\%dist);

$dbh->disconnect;
