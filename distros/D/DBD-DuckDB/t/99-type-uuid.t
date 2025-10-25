#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my $uuid_invalid = 'invalid-uuid-string-1234-1234567890ab';
my $uuid_null    = '00000000-0000-0000-0000-000000000000';
my $uuid_v1      = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
my $uuid_v4      = '4ac7a9e9-607c-4c8a-84f3-843f0191e3fd';
my $uuid_v7      = '81964ebe-00b1-7e1d-b0f9-43c29b6fb8f5';

SCOPE: {

    my $sth = $dbh->prepare('SELECT ?::UUID');
    my $result;

    $sth->execute($uuid_v1);
    ($result) = $sth->fetchrow_array;
    is $result, $uuid_v1, 'Insert and retrieve UUID v1';

    $sth->execute($uuid_v4);
    ($result) = $sth->fetchrow_array;
    is $result, $uuid_v4, 'Insert and retrieve UUID v4';

    $sth->execute($uuid_v7);
    ($result) = $sth->fetchrow_array;
    is $result, $uuid_v7, 'Insert and retrieve UUID v7';

    $sth->execute($uuid_null);
    ($result) = $sth->fetchrow_array;
    is $result, $uuid_null, 'Insert and retrieve NULL UUID';

    eval { $sth->execute($uuid_invalid) };
    isnt $0, undef, 'Inserting invalid UUID raises error';

}

SCOPE: {

    my $sth = $dbh->prepare('SELECT uuid_extract_version(?::UUID)');
    my $result;

    $sth->execute($uuid_v1);
    ($result) = $sth->fetchrow_array;
    is $result, 1, 'Extract version from UUID v1';

    $sth->execute($uuid_v4);
    ($result) = $sth->fetchrow_array;
    is $result, 4, 'Extract version from UUID v4';

    $sth->execute($uuid_v7);
    ($result) = $sth->fetchrow_array;
    is $result, 7, 'Extract version from UUID v7';

}

done_testing;
