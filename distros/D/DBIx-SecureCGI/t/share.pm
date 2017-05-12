package t::share;
use 5.010001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;
use Test::Database;
use DBI;
use DBIx::SecureCGI;
use AnyEvent::DBI::MySQL;
use Data::Dumper;

our $PK = 'INT NOT NULL AUTO_INCREMENT PRIMARY KEY';

sub import {
    warnings->import;
    strict->import;
    utf8->import;
    feature->import(':5.10');
    my $pkg = caller();
    eval "
    package $pkg;
    Test::More->import;
    Test::Exception->import;
    Data::Dumper->import;
    ";
    no strict 'refs';
    *{$pkg.'::'.$_} = \&$_ for qw( new_dbh new_adbh new_table );
    *{$pkg.'::'.$_} = \$$_ for qw( PK );
}

my $h = Test::Database->handle('mysql') or plan skip_all => '~/.test-database not configured';
my $dbh = new_dbh();
my @new_tables;

sub new_dbh {
    my ($attr) = @_;
    return DBI->connect($h->connection_info, $attr);
}

sub new_adbh {
    my ($attr) = @_;
    return AnyEvent::DBI::MySQL->connect($h->connection_info, $attr);
}

sub new_table {
    my ($sql) = @_;
    state $n = 1;
    my $table = sprintf 'DBIx_SecureCGI_t_%d_%d', $$, $n++;
    $dbh->do('DROP TABLE IF EXISTS '.$table);
    $dbh->do(sprintf 'CREATE TABLE %s (%s)', $table, $sql) or return;
    push @new_tables, $table;
    return $table;
}

END {
    $dbh->do('DROP TABLE IF EXISTS '.$_) for @new_tables;
}


1;
