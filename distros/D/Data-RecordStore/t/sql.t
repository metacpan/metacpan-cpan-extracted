#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Data::Dumper;
use Test::More;

use api;
use Data::RecordStore::SQL;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

# -----------------------------------------------------
#               init
# -----------------------------------------------------

my $factory = Factory->new;

#api->test_suite_recordstore( $factory );
#api->test_suite_objectstore( $factory );
#api->test_locks_async( $factory );
#api->test_transaction_async( $factory );
api->test_failed_async( $factory );

done_testing;

exit;
package Factory;

sub new { return bless {}, shift }

sub new_rs {
    my $init = shift;
    my $user = 'wolf';
    my $password = 'boogers';
    my $table = 'test';
    my $dbi = 'dbi:mysql:RecordStore';
    
    my $store = Data::RecordStore::SQL->open_store(
        TABLE => $table,
        DBI   => $dbi,
        USER  => $user,
        PASSWORD => $password,
        );

    return $store;
}
sub reopen {
    my( $cls, $oldstore ) = @_;
    return Data::RecordStore::SQL->open_store( %{$oldstore->{OPTIONS}} );
}

1;
