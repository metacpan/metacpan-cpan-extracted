#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'DBIx::Class::EncodedColumn::Crypt::PBKDF2' );

diag( 'Testing DBIx::Class::EncodedColumn::Crypt::PBKDF2 '
            . $DBIx::Class::EncodedColumn::Crypt::PBKDF2::VERSION );
