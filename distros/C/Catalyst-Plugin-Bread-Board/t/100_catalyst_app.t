#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Path::Class;

use Test::More;
use Test::Exception;
use Test::Moose;

use lib
    "$FindBin::Bin/lib",
    "$FindBin::Bin/apps/Test-App/lib";

use Test::App::Schema::DB;

my $app_root = dir("$FindBin::Bin/apps/Test-App/");
my $db_file  = $app_root->file(qw[ root db ]);

$db_file->remove if -e $db_file;

my $s = Test::App::Schema::DB->connect(
    'dbi:SQLite:dbname=' . $db_file
);
$s->storage->dbh_do( sub {
        my ($storage, $dbh) = @_;
        $dbh->do(q{
            CREATE TABLE artist (
              id   NOT NULL,
              name NOT NULL,
              PRIMARY KEY (id)
            )
        })
    }
);

my $artists = $s->resultset('Artist');

my @artist = (
    $artists->create( { id => 1, name => 'Willem de Kooning' } ),
    $artists->create( { id => 2, name => 'Mark Rothko'       } ),
    $artists->create( { id => 3, name => 'Jackson Pollock'   } ),
    $artists->create( { id => 4, name => 'Franz Kline'       } ),
);

## ---------------------- Catalyst Test -----------------------------

use Catalyst::Test 'Test::App';

ok( request('/')->is_success, '... request succeeded' );

my $content = get('/');

like( $content, qr/<h1>Artist Listing<\/h1>/, '... got value we expected' );
like( $content, qr/<li>Willem de Kooning<\/li>/, '... got value we expected' );
like( $content, qr/<li>Mark Rothko<\/li>/, '... got value we expected' );
like( $content, qr/<li>Jackson Pollock<\/li>/, '... got value we expected' );
like( $content, qr/<li>Franz Kline<\/li>/, '... got value we expected' );

done_testing;