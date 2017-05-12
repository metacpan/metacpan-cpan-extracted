#!perl
use warnings;
use strict;
use lib 'lib';

# SQLite database for testing
use FindBin qw($Bin);
my $db = "$Bin/test.db";
unlink($db);

##################################################

package Testing;
use base qw( Class::DBI );
use Class::DBI::utf8;

__PACKAGE__->set_db( Main => "dbi:SQLite:$db", "", "");
__PACKAGE__->columns( All => qw( id text binary ));

__PACKAGE__->utf8_columns(qw( id text ));

# set up the testing table
__PACKAGE__->db_Main->do("
  CREATE TABLE testing (
    id INT NOT NULL,
    text TEXT,
    binary TEXT
  )
");

##################################################

package Testing2;
our @ISA = qw( Testing );

__PACKAGE__->columns( All => qw( id text ));

# set up the testing table
__PACKAGE__->db_Main->do("
  CREATE TABLE testing2 (
    id INT NOT NULL,
    text TEXT
  )
");

##################################################

package main;
use Encode qw( encode_utf8 decode_utf8 );
use Test::More no_plan => 1;

ok( my $test = Testing->create({ id => 1 }), "new test object" );
is( $test->id, 1, "got it" );

# ascii
ok( $test->text("foo"), "set foo" );
ok( $test->update, "Stored");
is( raw_value(1), encode_utf8("foo"), '"foo" in DB');
ok( $test->discard_changes, "loaded" );
is( $test->text, "foo", "still foo");

# simple latin 1
ok( $test->text("\x{e9}"), "set e-acute" );
ok( $test->update, "Stored");
is( raw_value(1), encode_utf8("\x{e9}"), '"\303\251" in DB');
ok( $test->discard_changes, "loaded" );
is( $test->text, "\x{e9}", "still e-acute");

is( Testing->search( text => "\x{e9}" ), 1, "got row from search" );

# upgraded latin 1
ok( $test->text( decode_utf8(encode_utf8("\x{e9}")) ), "set upgraded e-acute" );
ok( $test->update, "Stored");
is( raw_value(1), encode_utf8("\x{e9}"), '"\303\251" in DB');
ok( $test->discard_changes, "loaded" );
is( $test->text, "\x{e9}", "still e-acute");

# nasty high-bit stuff
ok( $test->text("\x{2264}"), "set less-than-or-equal-to" );
ok( $test->update, "Stored");
is( raw_value(1), encode_utf8("\x{2264}"), '"\342\211\244" in DB');
ok( $test->discard_changes, "loaded" );
is( $test->text, "\x{2264}", "still nasty char");

is( Testing->search( text => "\x{2264}" ), 1, "got row from search" );

# subclasses of a utf8 class
ok( Testing2->create({ id => 2, text => "\x{e9}" }), "create subclass" );
is( Testing2->search( text => "\x{e9}" ), 1, "got row from search" );

# it's possible to have non-utf8 columns
ok( Testing->create({ id => 3, text => "\x{2264}", binary => "\x{2264}" }) );
is( Testing->retrieve(3)->text, "\x{2264}", "text column is text" );
is( Testing->retrieve(3)->binary, "\342\211\244", "binary column is binary" );


# useful function
sub raw_value {
  my $sth = Testing->db_Main->prepare("SELECT text FROM testing WHERE id = ?");
  $sth->execute(shift);
  return $sth->fetchrow_arrayref->[0];
}
