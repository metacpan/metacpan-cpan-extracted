#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 21;
use strict;
use warnings;

# Tests for transactions

BEGIN {
    use_ok 'DBIx::Mint';
}

SKIP: {
    eval { require Test::Warn };
    skip "Test::Warn required to test transactions", 11 
        if $@;

    {
        package Bloodbowl::Coach; use Moo;
        with 'DBIx::Mint::Table';
        
        has id           => ( is => 'rw', predicate => 1 );
        has name         => ( is => 'rw' );
        has email        => ( is => 'rw' );
        has password     => ( is => 'rw' );
    }

	my $mint = Test::DB->connect_db;
	isa_ok( $mint, 'DBIx::Mint');

    my $schema = $mint->schema;
    isa_ok( $schema, 'DBIx::Mint::Schema');

    $schema->add_class(
        class    => 'Bloodbowl::Coach',
        table    => 'coaches',
        pk       => 'id',
        auto_pk  => 1
    );


    # Test failed transaction with AutoCommit => 1 (the default for Test::DB)
    {
        my $transaction = sub {
            # This is the transaction
            my $coach = Bloodbowl::Coach->find(1);
            $coach->name('user x');
            $coach->update;
            
            my $test = Bloodbowl::Coach->find(1);
            is($test->name, 'user x',  'Record updated within transaction');
            
            die "Abort transaction";
        };

        my $res;
        &Test::Warn::warning_is(
            sub { $res = $mint->do_transaction( $transaction ) },
            "Transaction failed: Abort transaction",
            'Failed transactions emit a warning');
            
        is $res, undef, 'Failed transactions return undef';

        my $coach = Bloodbowl::Coach->find(1);
        isnt $coach->name, 'user x',   'Failed transactions are rolled back successfuly';
        is   $coach->name, 'julio_f',  'Record was not changed by a rolled back transaction';
    }

    # Test failed transaction with AutoCommit => 0
    {
        $mint->dbh->{AutoCommit} = 0;
        my $transaction = sub {
            # This is the transaction
            my $coach = Bloodbowl::Coach->find(1);
            $coach->name('user x');
            $coach->update;
            
            my $test = Bloodbowl::Coach->find(1);
            is($test->name, 'user x',  'Record updated within transaction');
            
            die "Abort transaction";
        };

        my $res;
        &Test::Warn::warning_is(
            sub { $res = $mint->do_transaction( $transaction ) },
            "Transaction failed: Abort transaction",
            'Failed transactions emit a warning (with AutoCommit initially off)');
            
        is $res, undef, 'Failed transactions return undef (AutoCommit off)';

        my $coach = Bloodbowl::Coach->find(1);
        isnt $coach->name, 'user x',   'Failed transactions are rolled back successfuly';
        is   $coach->name, 'julio_f',  'Record was not changed by a rolled back transaction';
        $mint->dbh->{AutoCommit} = 1;
    }

    # Test commited transaction
    {
        my $transaction = sub {
            # This is the transaction
            my $coach = Bloodbowl::Coach->find(1);
            $coach->name('user x');
            $coach->update;
            
            my $test = Bloodbowl::Coach->find(1);
            is($test->name, 'user x',  'Record updated within transaction');
        };

        my $res;
        &Test::Warn::warning_is(
            sub { $res = $mint->do_transaction( $transaction ) },
            undef,
            'Successful transactions do not emit warnings');
            
        is $res, 1, 'Successful transactions return the one true value';

        my $coach = Bloodbowl::Coach->find(1);
        is $coach->name, 'user x',   'Successful transactions are commited';
    }

    # Test commited transaction (AutoCommit = 0)
    {
        $mint->dbh->{AutoCommit} = 0;
        my $transaction = sub {
            # This is the transaction
            my $coach = Bloodbowl::Coach->find(1);
            $coach->name('user y');
            $coach->update;
            
            my $test = Bloodbowl::Coach->find(1);
            is($test->name, 'user y',  'Record updated within transaction (AutoCommit off)');
        };

        my $res;
        &Test::Warn::warning_is(
            sub { $res = $mint->do_transaction( $transaction ) },
            undef,
            'Successful transactions do not emit warnings (AutoCommit off)');
            
        is $res, 1, 'Successful transactions return the one true value (AutoCommit off)';

        my $coach = Bloodbowl::Coach->find(1);
        is $coach->name, 'user y',   'Successful transactions are commited (AutoCommit off)';
    }
}

done_testing();
