#!/usr/bin/perl

use Test;
BEGIN { plan tests => 9 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

my $record_class = $sqldb->record_class('foo', 'My::Foo', 'Accessors');
ok( $record_class eq 'My::Foo' );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Base') );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Accessors') );

########################################################################

my $record = My::Foo->new_with_values( 'foo' => 'Foozle' );
ok( $record->foo(), 'Foozle' );

$record->bar('Basil');
ok( $record->bar(), 'Basil' );

########################################################################

ok( $record->get_values('bar'), 'Basil' );

$record->change_values('bar', 'Beserk' );
ok( $record->get_values('bar'), 'Beserk' );

########################################################################

1;
