#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;


my $eav = DBIx::EAV->connect('dbi:SQLite:database=:memory:', undef, undef, { RaiseError => 1 }, { tenant_id => 42 });

isa_ok $eav, 'DBIx::EAV';
isa_ok $eav->dbh, 'DBI::db';
is $eav->dbh->{RaiseError}, 1, 'DBI attrs';

done_testing;
