#!/usr/local/bin/perl -w

use DBI;
use strict;

my $dbh;
my $ins;
my $nrows;
my $upd;
my $cursor;
my $sth;
my $blob1;
my $blob2;
my $bloblen = 1000000;
my $i;

$| = 1;

my $connstr = 'ENG=asademo;DBN=asademo;DBF=asademo.db;UID=dba;PWD=sql';
print "Connecting to Database\n"; 
$dbh = DBI->connect( "DBI:ASAny:", $connstr, '', { AutoCommit => 0 } );
printf( "connected\n" );
die unless $dbh;
printf( "hi\n" );
$dbh->{"LongReadLen"} = $bloblen;
printf( "hi2\n" );

printf( "Building blob: %d bytes\n", $bloblen );
$blob1 = '';
for( $i=0; $i<$bloblen/10; $i++ ) {
    $blob1 .= substr( $i . '__________', 0, 10 );
}
$blob1 = substr( $blob1 . $i . '__________', 0, $bloblen );
printf( "Build complete\n" );

$blob2 = $blob1;
$blob2 =~ tr/_/./;

#
# Prepare the tables
#
printf( "Drop table\n" );
$dbh->{PrintError} = 0;
$dbh->do( 'drop table blobs' );
$dbh->{PrintError} = 1;
printf( "Create table\n" );
$dbh->do( 'create table blobs( a long varchar, b long binary )' );

#
# Do some inserts
#
$ins = $dbh->prepare( "insert into blobs values( ?, ? )" );

# Bind via bind_param so that we can set the type for column 'b' to binary
printf( "Insert first row\n" );
printf( "    bind 1\n" );
$ins->bind_param( 1, $blob1 );
printf( "    bind 2\n" );
$ins->bind_param( 2, $blob2, DBI::SQL_BINARY );
printf( "    execute\n" );
$ins->execute();
printf( "    commit\n" );
$dbh->commit();
printf( "    complete\n" );

# This row is inserted without bind_param. Note, therefore, that the second
# column is treated as text, not binary data
printf( "Insert second row\n" );
$ins->execute( $blob2, "jcs" ) || die( "insert failed\n" );
$dbh->commit();

# Insert the blobs in the other order
printf( "Insert third row\n" );
$ins->execute( $blob2, $blob1 ) || die( "insert failed\n" );
$dbh->commit();
if( defined( $ins->err ) && defined( $ins->errstr ) ) {
    printf( "err %d, errstr %s\n", $ins->err, $ins->errstr );
} else {
    printf( "Inserts complete\n" );
}
$ins->finish;
undef $ins;

#
# Check the inserts values by fetching the values back
#
printf( "Checking inserts\n" );
$cursor = $dbh->prepare( "select a, b from blobs" );
$cursor->execute();
$nrows = 0;
while( ($a,$b) = $cursor->fetchrow() ) {
    $nrows++;
    if( $a ne $blob1 && $a ne $blob2 ) {
	die( "******ERROR: Fetched value for column a is incorrect: %s\n", $a );
    }
    if( $b ne $blob1 && $b ne $blob2 && $b ne "jcs" ) {
	die( "******ERROR: Fetched value for column b is incorrect: %s\n", $b );
    }
}
if( defined( $cursor->err ) && defined( $cursor->errstr ) ) {
    die( "******ERROR: err %d, errstr %s\n", $cursor->err, $cursor->errstr );
} elsif( $nrows != 3 ) {
    die( "******ERROR: Incorrect number of rows fetched: %d\n", $nrows );
} else {
    printf( "Inserts OK\n" );
}
$cursor->finish();

#
# Do some updates
#
printf( "Doing updates\n" );
$upd = $dbh->prepare( 'update blobs set b=? where a=?' );
$upd->execute( $blob1, $blob1 ) || die( "update failed\n" );
$dbh->commit();
$upd->finish();

#
# Check updates
#
printf( "Checking updates\n" );
$cursor = $dbh->prepare( "select a, b from blobs" );
$cursor->execute();
$nrows = 0;
while( ($a,$b) = $cursor->fetchrow() ) {
    $nrows++;
    if( $a eq $blob1 && $b ne $blob1 ) {
	die( "******ERROR: Update didn't work correctly\n" );
    }
    if( $a ne $blob1 && $a ne $blob2 ) {
	die( "******ERROR: Fetched value for column a is incorrect\n" );
    }
    if( $b ne $blob1 && $b ne $blob2 && $b ne "jcs" ) {
	die( "******ERROR: Fetched value for column b is incorrect\n" );
    }
}
if( defined( $cursor->err ) && defined( $cursor->errstr ) ) {
    die( "******ERROR: err %d, errstr %s\n", $cursor->err, $cursor->errstr );
} elsif( $nrows != 3 ) {
    die( "******ERROR: Incorrect number of rows fetched: %d\n", $nrows );
} else {
    printf( "Updates OK\n" );
}
$cursor->finish();
$dbh->commit();
$dbh->do( 'drop table blobs' );
$dbh->disconnect();
undef $dbh;

