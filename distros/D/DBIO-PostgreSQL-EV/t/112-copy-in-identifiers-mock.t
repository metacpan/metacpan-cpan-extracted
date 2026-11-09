use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k101: copy_in writes its table and column names
# as identifiers, whatever the schema's quote_names says.
#
# WHY: the names go into the COPY statement, which runs as one statement over
# the simple protocol. A name written raw is SQL: it can end the column list and
# start another clause. A name is one identifier -- plain lower case stays bare,
# anything else is double-quoted with its quotes doubled; a dot in the table
# name separates schema and table, each part its own identifier.
#
# Claims, on the statement EV::Pg is given:
#   1. quote_names => 0 does not unquote the names;
#   2. a table name with a blank, or with SQL in it, stays one quoted identifier;
#   3. the default connection writes the same statement;
#   4. a plain lower-case name is bare, as the server writes it.
#
# THE ONE SUBSTITUTION is EV::Pg: a fake that answers COPY_IN and records the
# statement. The storage is the real one, built through a schema connect with
# { async => 'ev' } so that it has the owning sync storage and its quoting.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @DATA;    # every chunk put_copy_data was given

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, conn => 0, queue => [] }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{conn} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{conn} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub error_message { undef }
  sub finish        { $_[0]{conn} = 0; return }

  our @SQL;
  sub query {
    my ($self, $sql, $cb) = @_;
    push @SQL, $sql;
    $self->{cb} = $cb;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->('COPY_IN') });
    return;
  }

  sub put_copy_data { push @DATA, $_[1]; return 1 }

  sub put_copy_end {
    my ($self) = @_;
    my $cb = $self->{cb};
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->(scalar @DATA) });
    return 1;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::Schema;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::EV::Storage;

{
  package DBIO::Test::K101CopyIn;
  $INC{'DBIO/Test/K101CopyIn.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

alarm 60;

sub statement {
  my ($attrs, $table, @columns) = @_;
  my $schema  = DBIO::Test::K101CopyIn->connect('dbi:Pg:dbname=x', 'u', 'p', { async => 'ev', %$attrs });
  my $storage = $schema->storage->async;
  @EV::Pg::SQL = ();
  my $f = $storage->copy_in($table, \@columns, sub { $_[0]->([ ('v') x @columns ]) });
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog\n") unless $f->is_ready });
  $dog->keepalive(0);
  $f->get;
  $storage->disconnect;
  return $EV::Pg::SQL[0];
}

my $evil = 'artist (name) FROM PROGRAM $$id > /tmp/x$$ --';

is statement({ quote_names => 0 }, 'thing', qw( a b )),
  'COPY thing (a, b) FROM STDIN', 'a plain name is bare';
is statement({ quote_names => 0 }, 'my thing', 'a b', 'C'),
  'COPY "my thing" ("a b", "C") FROM STDIN', 'quote_names => 0: blanks and capitals are quoted';
is statement({ quote_names => 0 }, $evil, 'name'),
  'COPY "artist (name) FROM PROGRAM $$id > /tmp/x$$ --" (name) FROM STDIN',
  'quote_names => 0: SQL in the table name stays inside one identifier';
is statement({ quote_names => 0 }, 'thing', 'x) FROM PROGRAM $$id$$ --'),
  'COPY thing ("x) FROM PROGRAM $$id$$ --") FROM STDIN', '... also in a column name';
is statement({ quote_names => 0 }, 'a"b', 'c"d'),
  'COPY "a""b" ("c""d") FROM STDIN', 'a double quote in a name is doubled';
is statement({}, $evil, 'name'),
  'COPY "artist (name) FROM PROGRAM $$id > /tmp/x$$ --" (name) FROM STDIN',
  'the default connection writes the same statement';
is statement({ quote_names => 0 }, 'public.thing', 'a'),
  'COPY public.thing (a) FROM STDIN', 'a dot separates schema and table';
is statement({ quote_names => 0 }, 'my schema.my thing', 'a'),
  'COPY "my schema"."my thing" (a) FROM STDIN', '... each part quoted on its own';

done_testing;
