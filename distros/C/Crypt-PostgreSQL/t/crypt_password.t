#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Simple tests => 2;

my $password = 'mypasswd€ò♠';

use Crypt::PostgreSQL;


ok( Crypt::PostgreSQL::encrypt_md5($password, 'my_user') eq 'md5e03100fa97298011533e5988437b9097', 'PSQL_PSW_MD5 password');

my $salt = '1234567890123456';
my $hash = 'SCRAM-SHA-256$4096:MTIzNDU2Nzg5MDEyMzQ1Ng==$rMjW2+IEa+iNDiek4gjmLqTVtuYdS7TLCic+EzaYHYc=:eEPIm9fRWAfZUAw1vg3Dek0HHX9U6CiO0kycRKkGHaQ=';
ok( Crypt::PostgreSQL::encrypt_scram($password, $salt) eq $hash, 'PSQL_PSW_SCRAM password');

#end test.
