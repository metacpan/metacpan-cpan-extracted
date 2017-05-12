#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

my $NUM_TESTS = 10000;
my $NUM_SAMPLES = 100;

main();
exit(0);


#   _val_numeric 
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
    test_numeric_int($hd);
    test_numeric_float($hd);

    $dbh->disconnect();

    done_testing();
}


#  test_int 
#    scale = 0
sub test_numeric_int {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_numeric_int (
            value numeric(3,0) not null
        )
    });

    my $col_def = $hd->_table_def('test_numeric_int')->column_def('value');

    my @sample = ();
    my @failed = ();
    for ( 1..$NUM_TESTS ) {
        my $ret = $hd->_val_numeric($col_def);
        push @failed, $ret unless $ret =~ m/^[1-9][0-9]?[0-9]?$/ or $ret eq '0' or @failed > $NUM_SAMPLES;
        push @sample, $ret if $_ <= $NUM_SAMPLES;
    }
    my $message = (@failed) ? "numeric(3,0) failed = " . (join ', ', @failed)
                            : "numeric(3,0) samples = " . (join ', ', @sample)
                            ;
    is(scalar(@failed), 0, $message);
}


#  test_int 
#    scale = 0
sub test_numeric_float {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{
        CREATE TABLE test_numeric_float (
            value numeric(4,2) not null
        )
    });

    my $col_def = $hd->_table_def('test_numeric_float')->column_def('value');

    my @sample = ();
    my @failed = ();
    for ( 1..$NUM_TESTS ) {
        my $ret = $hd->_val_numeric($col_def);
        push @failed, $ret unless $ret =~ m/^[1-9]?[0-9]\.[0-9][1-9]?$/ or @failed > $NUM_SAMPLES;
        push @sample, $ret if $_ <= $NUM_SAMPLES;
    }
    my $message = (@failed) ? "numeric(4,2) failed = " . (join ', ', @failed)
                            : "numeric(4,2) samples = " . (join ', ', @sample)
                            ;
    is(scalar(@failed), 0, $message);
}

    


