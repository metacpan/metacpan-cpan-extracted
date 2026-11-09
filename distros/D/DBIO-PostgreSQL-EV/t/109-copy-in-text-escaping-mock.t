use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k98: the copy_in writer serialises a value by
# PostgreSQL's COPY text-format rules.
#
# WHY: a row goes to the server as one line, fields joined by TAB, the line
# ended by LF, NULL written \N. A value that carries one of those bytes must
# not be able to end its field or its row, nor be read as NULL; otherwise a
# value of the caller's decides how many rows and columns the COPY has.
#
# What this file claims, on the bytes the writer hands to put_copy_data:
#   1. backslash is doubled, TAB, LF and CR are written \t, \n and \r, so the
#      only TAB and LF in a row's line are its delimiters;
#   2. undef is \N, and the two characters \N in a value are \\N, which the
#      server reads as those two characters -- not as NULL;
#   3. a plain value, the empty string and a number are written as they are.
#
# THE ONE SUBSTITUTION is EV::Pg: a fake that answers COPY_IN, records what
# put_copy_data is given and answers the end of the stream.

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

  sub query {
    my ($self, $sql, $cb) = @_;
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
use DBIO::PostgreSQL::EV::Storage;

alarm 60;

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);

sub written {
  my (@rows) = @_;
  @EV::Pg::DATA = ();
  my $f = $storage->copy_in('thing', [qw( a b c )], sub {
    my ($put) = @_;
    $put->($_) for @rows;
  });
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog\n") unless $f->is_ready });
  $dog->keepalive(0);
  $f->get;
  return [ @EV::Pg::DATA ];
}

is_deeply written([ "Miles Davis\tJazz\nMallory\tAdmin", undef, "it\\N" ]),
  [ "Miles Davis\\tJazz\\nMallory\\tAdmin\t\\N\tit\\\\N\n" ],
  'TAB, LF, backslash and a literal \\N in values; undef is \\N; one line';

is_deeply written([ "a\rb", "back\\slash", "\\N" ]),
  [ "a\\rb\tback\\\\slash\t\\\\N\n" ],
  'CR is \\r, a backslash is doubled, a value that is the two characters \\N is \\\\N';

is_deeply written([ 'plain', '', 42 ], [ undef, undef, undef ]),
  [ "plain\t\t42\n", "\\N\t\\N\t\\N\n" ],
  'plain value, empty string and number as they are; undef stays \\N';

my @lines = map { split /\n/, $_, -1 } @{ written([ "x\ny\tz", "q" , "r" ]) };
is scalar(grep { length } @lines), 1, 'a value with LF is still one row';

$storage->disconnect;
done_testing;
