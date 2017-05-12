#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use AnyEvent::DBI::MySQL;


my $dbh;
lives_ok { $dbh = AnyEvent::DBI::MySQL->connect(
    "dbi:mysql:host=127.0.0.1;port=3307;database=nosuch",
    'baduser', 'cantbethepass', {RaiseError=>0,PrintError=>0}
    ) } 'no exception';
is $dbh, undef, 'undefined $dbh';

throws_ok { AnyEvent::DBI::MySQL->connect(
    "dbi:mysql:host=127.0.0.1;port=3307;database=nosuch",
    'baduser', 'cantbethepass', {RaiseError=>1,PrintError=>0}
    ) } qr/connect/, 'got exception';


done_testing();
