package Test::DBIx::EAV;

use strict;
use warnings;
use DBI;
use FindBin;
use parent qw(Exporter);
use Test2::Bundle::Extended;
use Data::Dumper;
use lib 'lib';
use DBIx::EAV;
use YAML;

our @EXPORT = (
    @Test2::Bundle::Extended::EXPORT,
    qw/ Dumper get_test_dbh empty_database read_file read_yaml_file /
);

our @EXPORT_OK = (
    @Test2::Bundle::Extended::EXPORT_OK,
    qw/  /
);


sub import {
    my ($pkg) = @_;

    # modern perl
    $_->import for qw(strict warnings utf8);
    feature->import(':5.10');

    # our stuff, via Exporter::export_to_level
    $pkg->export_to_level(1, @_);
}


sub empty_database {
    my $eav = shift;
    $eav->table('entity_relationships')->delete;
    $eav->table('value_'.$_)->delete for @{$eav->schema->data_types};
    $eav->table('entities')->delete;
}


sub get_test_dbh {
    my (%options) = @_;
    my $driver = $ENV{TEST_DBIE_MYSQL} ? 'mysql' : 'SQLite';
    my $dbname = $driver eq 'mysql' ? $ENV{TEST_DBIE_MYSQL} : ':memory:';

    my $dbh = DBI->connect("dbi:$driver:dbname=$dbname",
        $ENV{TEST_DBIE_MYSQL_USER},
        $ENV{TEST_DBIE_MYSQL_PASSWORD});

    $dbh->{sqlite_see_if_its_a_number} = 1;

    $dbh;
}

sub read_file {
    my $filename = shift;
    open my $fh, '<', $filename or die "$!";
    return join '', <$fh>;
}

sub read_yaml_file {
    Load(read_file(shift))
}




1;
