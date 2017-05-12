#!/usr/bin/perl

use Test;
BEGIN { plan tests => 22 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

my $record_class = $sqldb->record_class('foo', 'My::Foo', 'Hooks');
ok( $record_class eq 'My::Foo' );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Base') );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Hooks') );

########################################################################

# Confirm it doesn't have "Extras" trait
ok( ! eval { local $SIG{__DIE__}; My::Foo->demand_table } );
ok( ! My::Foo->can('fetch_records') );
ok( ! My::Foo->can('refetch_record') );

########################################################################

# The record interface requires information about the columns, which isn't 
# available in our bogus NullP environment, so we'll define them explicitly.

My::Foo->columnset( 
  DBIx::SQLEngine::Schema::ColumnSet->new(  
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'bar' ),
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'buz' ),
  ) 
);

########################################################################

my $total_count = 0;
My::Foo->install_hooks( 
  post_new    => sub { $total_count ++ },
  post_fetch  => sub { $total_count ++ },
  pre_destroy => sub { $total_count -- },
);

{ 
  my $record = My::Foo->new_with_values( 'foo' => 'bar' );
  ok( $total_count, 1 );
  {
    my $other = My::Foo->new_with_values( 'baz' => 'bill' );
    ok( $total_count, 2 );
  }
}
ok( $total_count, 0 );

########################################################################

My::Foo->fetch_select( );
ok( $sqldb->last_query, 'select * from foo' );

My::Foo->fetch_select( criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ?/Baz' );

My::Foo->select_record( 'Baz' );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

My::Foo->select_record( { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

########################################################################

my $inserts;
my $updates;
My::Foo->install_hooks( 
  post_insert  => sub { $inserts ++ },
  post_update  => sub { $updates ++ },
);

My::Foo->new_and_save( buz => 'Baz' );
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (NULL, ?)/Baz' );
ok( $inserts, 1 );

My::Foo->new_with_values( bar => 'Baz', buz => 'Blee' )->insert_record;
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (?, ?)/Baz/Blee' );
ok( $inserts, 2 );

My::Foo->new_with_values( bar => 'Baz', buz => 'Blee' )->update_record;
ok( $sqldb->last_query, 'update foo set bar = ?, buz = ? where bar = ?/Baz/Blee/Baz' );
ok( $updates, 1 );

My::Foo->new_with_values( bar => 'Baz' )->delete_record();
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );

########################################################################

1;
