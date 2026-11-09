use strict;
use warnings;
use Test::More;

# A statement the SERVER refused fails its Future with a
# DBIO::Exception::Server carrying the SQLSTATE (core ADR 0062, karr k94); an
# error the client library raises itself stays the string it was. The line is
# drawn by the handle (sqlstate, error number range, error text), so a handle
# that holds a stale or foreign error must not turn a client text into a
# server error.

use DBIO::MySQL::EV::QueryExecutor;

{
  package FakeHandle;
  sub new { my $c = shift; bless {@_}, $c }
  sub sqlstate      { $_[0]{state} }
  sub error_number  { $_[0]{number} }
  sub error_message { $_[0]{message} }
}

my $text = "Duplicate entry 'x' for key 'artist_name'";
my $se = \&DBIO::MySQL::EV::QueryExecutor::_server_error;

my $err = $se->(FakeHandle->new(state => '23000', number => 1062, message => $text), $text);
isa_ok $err, 'DBIO::Exception::Server', 'a duplicate key (1062)';
is $err->sqlstate, '23000', '... with its SQLSTATE';
is "$err", $text, '... stringifying to the very text the Future failed with before';

isa_ok $se->(FakeHandle->new(state => '42000', number => 4025, message => 'c'), 'c'),
  'DBIO::Exception::Server', 'a MariaDB-range server error (4025)';

is $se->(FakeHandle->new(state => 'HY000', number => 2013, message => 'Lost connection'), 'Lost connection'),
  'Lost connection', 'a client library error (2013) stays the string';

is $se->(FakeHandle->new(state => '23000', number => 1062, message => $text), 'something else'),
  'something else', 'a text that is not the handle\'s error stays the string';

is $se->(FakeHandle->new(state => '00000', number => 0, message => undef), 'not connected'),
  'not connected', 'a handle without an error leaves the text alone';

my $obj = bless {}, 'Some::Error';
is $se->(FakeHandle->new(state => '23000', number => 1062, message => $text), $obj), $obj,
  'an object passes unchanged';
is $se->(FakeHandle->new(state => '23000', number => 1062, message => $text), undef), undef,
  'undef passes unchanged';
is $se->(bless({}, 'NoSuchHandle'), $text), $text, 'a handle that cannot answer leaves the text alone';

done_testing;
