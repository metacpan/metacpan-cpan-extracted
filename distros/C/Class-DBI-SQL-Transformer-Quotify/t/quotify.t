#!perl

use strict;
use warnings;
use Test::More tests => 69;
$|=1;

package Test;
use base qw/Class::DBI/;
__PACKAGE__->connection('DBI:Mock:', '', '');
__PACKAGE__->db_Main->{mock_get_info}->{29} = q{"}; # SQL_IDENTIFIER_QUOTE_CHAR
__PACKAGE__->table('table name');
__PACKAGE__->sql_transformer_class('Class::DBI::SQL::Transformer::Quotify');
our @COLS = (
  # primary:
  'some id',
  # essential:
  'foo bar stuff',
  'foo bar',
  'foo',
  'bar',
  'more',
  'more stuff',
  'things',
  'other things',
);
__PACKAGE__->columns( Primary => $COLS[0]);
__PACKAGE__->columns( Essential => @COLS[1..$#COLS] );
# hack so that we get back the columns in the order specified above.
# otherwise, Class::DBI::ColumnGrouper just returns values(%somehash)
# and order is not consistent/predictable
# known order is necessary to accurately execute test cases
sub all_columns {
  my $self = shift;
  my @cols = $self->SUPER::all_columns;
  my %index;
  @index{ @COLS } = 0 .. $#COLS;
  return sort { $index{$a} <=> $index{$b} } @cols;
}

package Blah;
use base qw/Class::DBI/;
__PACKAGE__->table('blah table name');

package main;

is( Test->db_Main->get_info(29), q{"}, 'got quote char' );
is( Test->db_Main->quote_identifier('blah'), '"blah"', "quote: blah" );
is( Test->db_Main->quote_identifier(undef,undef,'blah'), '"blah"', "quote: blah" );
is( Test->db_Main->quote_identifier('blah','stuff'), '"blah"."stuff"', "quote: blah, stuff" );
is( Test->db_Main->quote_identifier(undef, 'blah','stuff'), '"blah"."stuff"', "quote: blah, stuff" );

foreach my $test (
  map {
	(
	[ $_,			qq{"$_"} ],		# as-is
	[ qq{"$_"},		qq{"$_"} ],		# pre-quoted
	[ qq{qwe $_ asd},	qq{qwe "$_" asd} ],	# in some context
	[ qq{qwe "$_" asd},	qq{qwe "$_" asd} ],	# pre-quoted in some context
	)
  }
	'some id',
	'foo bar',
	'foo',
	'bar',
	'more',
	'more stuff',
	'things',
	'other things',
	'foo bar stuff',
    ){
#next unless  $test->[0] =~ /other/;
#warn "=========== " . $test->[0];
  my $s = Test->transform_sql( '%s', $test->[0] );
  is( $s, $test->[1], "arg: ".$test->[0] );
}


foreach my $test (
  [ '__TABLE__', '"table name"' ],
  [ '__TABLE(Test)__', '"table name"' ],
  [ '__IDENTIFIER__', '"some id"=?' ],
  [ '__ESSENTIAL__', '"some id", "foo bar stuff", "foo bar", "foo", "bar", "more", "more stuff", "things", "other things"' ],
  [ '__FOO__', '__FOO__' ],
  [ '__TABLE(Blah)__', '"blah table name"'],
  [ 'blarg', 'blarg'],
  [ 'blarg(open paren', 'blarg(open paren'],
  [ 'blarg)close paren', 'blarg)close paren'],
  [ '__ESSENTIAL(Blah)__', '"Blah"."some id", "Blah"."foo bar stuff", "Blah"."foo bar", "Blah"."foo", "Blah"."bar", "Blah"."more", "Blah"."more stuff", "Blah"."things", "Blah"."other things"'],
    ){
  my $s = eval { Test->transform_sql( $test->[0], () ) };
  is( $s, $test->[1], "sql: ".$test->[0] );
}

  foreach my $test (
  map {
	(
	# all should come through verbatim
	[ $_,			"$_" ],		# as-is
	[ "qwe $_ asd",		"qwe $_ asd" ],	# in some context
	)
  }
	'__TABLE(Blah__',
	'__TABLEBlah)__',
	'__TABLEBlah__',
	'__TABLE()__', 
	'__JOIN()__',
	'__ESSENTIAL()__',
      ){
    my $s = eval { Test->transform_sql( $test->[0], () ) };
    is( $s, $test->[1], "sql: ".$test->[0] );
  }

Test->db_Main->{mock_get_info}->{29} = q{@}; # SQL_IDENTIFIER_QUOTE_CHAR
Test->db_Main->{dbi_quote_identifier_cache} = 0;  # clear it since DBI::quote_identifer() caches the quote char.
is( Test->db_Main->get_info(29), q{@}, 'got quote char' );
is( Test->db_Main->quote_identifier('blah'), '@blah@', "quote: blah" );
is( Test->db_Main->quote_identifier(undef,undef,'blah'), '@blah@', "quote: blah" );
is( Test->db_Main->quote_identifier('blah','stuff'), '@blah@.@stuff@', "quote: blah, stuff" );
is( Test->db_Main->quote_identifier(undef, 'blah','stuff'), '@blah@.@stuff@', "quote: blah, stuff" );
foreach my $test (
  [ '__ESSENTIAL(Blah)__', '@Blah@.@some id@, @Blah@.@foo bar stuff@, @Blah@.@foo bar@, @Blah@.@foo@, @Blah@.@bar@, @Blah@.@more@, @Blah@.@more stuff@, @Blah@.@things@, @Blah@.@other things@'],
    ){
  my $s = eval { Test->transform_sql( $test->[0], () ) };
  is( $s, $test->[1], "sql: ".$test->[0] );
}

exit;
