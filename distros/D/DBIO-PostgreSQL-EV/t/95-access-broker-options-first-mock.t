use strict;
use warnings;
use Test::More;

# OFFLINE, karr k80 (a), maintainer's decision 2026-10-09: where the broker's
# answer and the options beside it both give cause to refuse, the options are
# judged first and their message wins -- the order core holds since dbio k310
# (t/access_broker/32-dbi-broker-unapplied-options-beside.t, claim 7: "checked
# before the answer is set against the options").
#
# WHY: the caller who wrote the parameter beside the broker has the first
# thing to fix; telling them about the answer first sends them to the
# broker's side for a problem that goes on after it is fixed. Both halves of a
# schema (the owner's dbh and this transport) must name the same thing first.
#
# What this file claims, with a connection parameter (sslmode) beside the
# broker and the answer ALSO unusable or at odds with the options:
#   1. the answer's pool_size differs from the one beside the broker: the
#      parameter is named, not pool_size;
#   2. the answer names nothing: the parameter is named;
#   3. the answer is a hash whose dbname is a DSN with host beside it, a shape
#      the reader refuses: the parameter is named;
#   4. the answer is a code reference (dbh_maker), which this transport cannot
#      connect from: the parameter is named;
#   5. the same holds for every later connection: a pool spawn and a listen
#      open name the parameter, never the answer, and the broker is not asked
#      (its answer is not read) -- nothing reaches EV::Pg;
#   6. controls: without the parameter the answer's own problem is what is
#      said, so the answer's message is not lost, only second.
# Not held here, because the transport drops DBI attributes by design (k60)
# and refuses nothing new for them: a DBI attribute beside a dbh_maker answer
# is the answer's refusal alone (core refuses it there, k310).

BEGIN {
  package EV::Pg;
  our @NEW;
  sub new { my ($class, %args) = @_; push @NEW, \%args; bless {}, $class }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::PostgreSQL::EV::Storage;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

{
  package T95::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer, asked => 0 }, $class }
  sub connect_info_for { my $s = shift; $s->{asked}++; return $s->{answer} }
}

my $PARAM = qr/PostgreSQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(sslmode\)/;
my %GOOD  = ( dbname => 'd', host => 'h', user => 'u', password => 'p' );

my @CASES = (
  [ 'pool_size in the answer differs from the one beside it',
    sub { +{ %GOOD, pool_size => 2 } }, { pool_size => 3 }, qr/pool_size/ ],
  [ 'an answer that names nothing',
    sub { +{} }, {}, qr/./ ],
  [ 'a DSN as dbname with host beside it',
    sub { +{ dbname => 'dbi:Pg:dbname=x', host => 'h', user => 'u', password => 'p' } }, {}, qr/./ ],
  [ 'a code reference (dbh_maker)',
    sub { sub { 1 } }, {}, qr/./ ],
);

for my $case (@CASES) {
  my ($label, $answer, $beside, $answers_own) = @$case;

  # control: without the parameter the answer's own problem is told
  {
    my $s = $EV->new(undef);
    my $b = T95::Broker->new($answer->());
    eval { $s->connect_info([ $b, { %$beside } ]) };
    ok $@, "control, $label: refused without the parameter";
    unlike "$@", qr/does not apply connection parameter/, '... and not as a parameter beside the broker';
    like "$@", $answers_own, '... but with the answer\'s own message';
  }

  # the parameter beside it as well: its message wins
  {
    my $s = $EV->new(undef);
    my $b = T95::Broker->new($answer->());
    eval { $s->connect_info([ $b, { %$beside, sslmode => 'k80-value' } ]) };
    like "$@", $PARAM, "$label and sslmode beside the broker: the parameter is named";
    unlike "$@", qr/k80-value/, '... without a value';
    is $b->{asked}, 0, '... before the broker is asked for its answer';

    @EV::Pg::NEW = ();
    for my $attempt (
      [ pool   => sub { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed } ],
      [ listen => sub { $s->_listen_open } ],
    ) {
      my ($name, $code) = @$attempt;
      eval { $code->() };
      like "$@", $PARAM, "... $name connection: the parameter, again";
    }
    is scalar(@EV::Pg::NEW), 0, '... nothing reached EV::Pg';
    is $b->{asked}, 0, '... and the broker was never asked';
  }
}

done_testing;
