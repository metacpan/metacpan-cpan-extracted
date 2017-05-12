#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

my $NUM_TESTS = 1000;
my $NUM_SAMPLES = 20;

main();
exit(0);


#   _val_datetime 
#  

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);


    #  Write test code here.
    test_datetime($hd, 'datetime');
    test_datetime($hd, 'timestamp');
    test_date($hd);
    test_year($hd);

    $dbh->disconnect();

    done_testing();
}


#  test_datetime 
sub test_datetime {
    my ($hd, $type) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(qq{
        CREATE TABLE test_$type (
            value $type not null
        )
    });

    my $col_def = $hd->_table_def("test_$type")->column_def('value');

    my @sample = ();
    my @failed = ();
    for ( 1..$NUM_TESTS ) {
        my $ret = $hd->_val_datetime($col_def);
        push @failed, $ret unless $ret =~ m/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ or @failed > $NUM_SAMPLES;
        push @sample, $ret if $_ <= $NUM_SAMPLES;
    }
    my $message = (@failed) ? "$type failed = " . (join ', ', map { qq{'$_'} } @failed)
                            : "$type samples = " . (join ', ', map { qq{'$_'} } @sample)
                            ;
    is(scalar(@failed), 0, $message);
}


#  test_timestamp 
sub test_date {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_date (
            value date not null
        )
    });

    my $col_def = $hd->_table_def('test_date')->column_def('value');

    my @sample = ();
    my @failed = ();
    for ( 1..$NUM_TESTS ) {
        my $ret = $hd->_val_datetime($col_def);
        push @failed, $ret unless $ret =~ m/^\d{4}-\d{2}-\d{2}$/ or @failed > $NUM_SAMPLES;
        push @sample, $ret if $_ <= $NUM_SAMPLES;
    }
    my $message = (@failed) ? "date failed = " . (join ', ', map { qq{'$_'} } @failed)
                            : "date samples = " . (join ', ', map { qq{'$_'} } @sample)
                            ;
    is(scalar(@failed), 0, $message);
}

    
sub test_year {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_year (
            value year not null
        )
    });

    my $col_def = $hd->_table_def('test_year')->column_def('value');

    my @sample = ();
    my @failed = ();
    for ( 1..$NUM_TESTS ) {
        my $ret = $hd->_val_year($col_def);
        push @failed, $ret unless $ret =~ m/^\d{4}$/ or @failed > $NUM_SAMPLES;
        push @sample, $ret if $_ <= $NUM_SAMPLES;
    }
    my $message = (@failed) ? "year failed = " . (join ', ', map { qq{'$_'} } @failed)
                            : "year samples = " . (join ', ', map { qq{'$_'} } @sample)
                            ;
    is(scalar(@failed), 0, $message);
}


