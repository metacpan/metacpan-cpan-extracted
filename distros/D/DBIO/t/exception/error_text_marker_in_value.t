# ABSTRACT: A bound value that holds the DBI appendix marker stays out of the error text
use strict;
use warnings;

use Test::More;

use DBIO::Test;

# What this file claims (ADR 0075): the text of the engine is masked whole
# and the appendix DBI writes for a handle with ShowErrorStatement is cut off
# afterwards, so a bound value that holds `[for Statement "` is masked as one
# value and no part of it is left in the exception -- also when the handle
# writes the appendix itself, and when the handle is supplied by a coderef.
#
# THE SUBSTITUTION: the mock runs no statement, so the text DBI would write is
# handed to $storage->_dbi_handle_error by hand, with the statement and values
# of a statement in flight.

my $sql = 'INSERT INTO artist (name) VALUES (?)';
my $engine = 'DBD::Stub::st execute failed: duplicate key violates constraint';

my $storage = DBIO::Test->init_schema(no_deploy => 1)->storage;

my %cases = (
  'marker at the start of the value' => q{[for Statement "geheimstart-0123456789},
  'marker in the middle of the value' => q{abcd-efgh [for Statement "geheimmitte-0123456789},
);

for my $name (sort keys %cases) {
  my $value = $cases{$name};

  # the text as the engine writes it, value inline
  {
    local $storage->{_exec_in_flight} = [ $sql, [ $value ] ];
    eval {
      $storage->_dbi_handle_error(
        "$engine on column name, value $value", { Statement => $sql, NUM_OF_PARAMS => 1 },
      );
    };
    my $text = "$@";
    like $text, qr/\Q$engine\E on column name, value \*\*\*/, "$name: the sentence of the engine is whole";
    like $text, qr/\Q[for Statement "$sql" with 1 bind value]\E/, "$name: the statement and the count follow";
    unlike $text, qr/geheim/, "$name: no part of the value is in the text";
  }

  # a handle with ShowErrorStatement on (a coderef handle) appends the values
  {
    local $storage->{_exec_in_flight} = [ $sql, [ $value ] ];
    my $quoted = $value =~ s/'/''/gr;
    eval {
      $storage->_dbi_handle_error(
        qq{$engine [for Statement "$sql" with ParamValues: 1='$quoted']},
        { Statement => $sql, NUM_OF_PARAMS => 1 },
      );
    };
    my $text = "$@";
    like $text, qr/\Q$engine\E/, "$name (ShowErrorStatement): the sentence of the engine is whole";
    like $text, qr/\Q[for Statement "$sql" with 1 bind value]\E/, "$name (ShowErrorStatement): the statement and the count follow";
    unlike $text, qr/geheim|ParamValues/, "$name (ShowErrorStatement): no part of the value is in the text";
  }
}

done_testing;
