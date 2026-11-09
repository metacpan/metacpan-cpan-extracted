use strict;
use warnings;

use Test::More;
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;

# karr k74 -- how the live tests drop the databases they make
# (t/lib/AseDatabase.pm).
#
# A live run died at a DROP DATABASE the server refused once:
#
#   Msg 3702: Cannot drop or replace the database 'dbio_k52_196448_c2' because
#   it is currently in use.
#
# ASE says that while anything at all is in the database, and what is in it
# need not be the test's: the server's own checkpoint process was seen inside a
# database no client was connected to. It goes away by itself. So the drop is
# repeated -- on that message and on no other -- a fixed number of times, and
# what the server said last comes back as a value: the file that called goes on
# and fails one test by name.
#
# Fully offline: the handle here answers a list of refusals and then takes the
# statement, and it dies of a refusal while RaiseError is on, as a DBI handle
# does. t/66-drop-database-in-use-live.t asks the server.

my $IN_USE = [ 3702, q{Server message number=3702 severity=16 state=4 line=1 }
                   . q{server=MYSYBASE text=Cannot drop or replace the database }
                   . q{'dbio_x' because it is currently in use.} ];
my $ABSENT = [ 3701, q{Server message number=3701 severity=11 state=1 line=1 }
                   . q{server=MYSYBASE text=Cannot drop the database 'dbio_x', }
                   . q{because it doesn't exist in the system catalogs.} ];

my $SAID_IN_USE = q{Msg 3702: Cannot drop or replace the database 'dbio_x' }
                . q{because it is currently in use.};

{
  package K74::Dbh;
  sub new {
    my ($class, @refusals) = @_;
    return bless {
      refusals => [@refusals], sent => [], RaiseError => 1, PrintError => 0,
    }, $class;
  }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{sent} }, $sql;
    my $refusal = shift @{ $self->{refusals} };
    @$self{qw(err errstr)} = $refusal ? @$refusal : ();
    return '0E0' unless $refusal;
    die "DBD::Sybase::db do failed: $refusal->[1]\n" if $self->{RaiseError};
    return undef;
  }
  sub err    { $_[0]{err} }
  sub errstr { $_[0]{errstr} }
}

# The waits, instead of waiting them.
my @slept;
{
  no warnings 'redefine';
  *Time::HiRes::sleep = sub (;@) { push @slept, $_[0] };
}

sub dropping {
  my ($dbh, @options) = @_;
  @slept = ();
  my $said;
  my $lived = eval { $said = AseDatabase::drop($dbh, 'dbio_x', @options); 1 };
  return $lived ? $said : "DIED: $@";
}

# --- taken at once -----------------------------------------------------------
{
  my $dbh = K74::Dbh->new;

  is dropping($dbh), '', 'a database nothing is in: dropped, nothing to say';
  is_deeply $dbh->{sent}, [ 'drop database dbio_x' ], '... with one statement';
  is_deeply \@slept, [], '... and no wait';
}

# --- in use for a moment: waited for -----------------------------------------
{
  my $dbh = K74::Dbh->new($IN_USE, $IN_USE);

  is dropping($dbh), '',
    'in use at the first two tries: the drop is repeated until it is taken';
  is scalar @{ $dbh->{sent} }, 3, '... at the third';
  is_deeply \@slept, [ 0.25, 0.25 ], '... a quarter of a second apart';
  is $dbh->{RaiseError}, 1, '... and the handle dies of an error again afterwards';
}

# --- in use for good: given up, by name, alive -------------------------------
{
  my $dbh = K74::Dbh->new( ($IN_USE) x 100 );

  is dropping($dbh), $SAID_IN_USE,
    'in use for good: the drop gives up and returns what the server said -- '
    . 'it does not die';
  is scalar @{ $dbh->{sent} }, 40, '... after 40 tries, a fixed number';
  is scalar @slept, 39, '... with a wait between two tries and none after the last';
}

{
  my $dbh = K74::Dbh->new( ($IN_USE) x 100 );

  is dropping($dbh, tries => 3, wait => 0.1), $SAID_IN_USE,
    'tries and wait are the caller\'s to set: given up the same way';
  is scalar @{ $dbh->{sent} }, 3, '... after 3 tries';
  is_deeply \@slept, [ 0.1, 0.1 ], '... a tenth of a second apart';
}

# --- any other refusal: not waited for ---------------------------------------
{
  my $dbh = K74::Dbh->new( ($ABSENT) x 100 );

  is dropping($dbh),
    q{Msg 3701: Cannot drop the database 'dbio_x', because it doesn't exist }
    . q{in the system catalogs.},
    'another refusal is returned as it is';
  is scalar @{ $dbh->{sent} }, 1, '... at once: only Msg 3702 is repeated';
  is_deeply \@slept, [], '... without a wait';
}

{
  my $dbh = K74::Dbh->new($IN_USE, $ABSENT, $IN_USE);

  like dropping($dbh), qr/\AMsg 3701: /,
    'another refusal after an "in use" ends the tries too';
  is scalar @{ $dbh->{sent} }, 2, '... there';
}

# --- an error that is no server message --------------------------------------
{
  my $dbh = K74::Dbh->new(
    [ 63, "OpenClient message: LAYER = (1) ORIGIN = (1) SEVERITY = (1) NUMBER = (63)\n"
        . 'Message String: ct_cmd_alloc(): the connection has been marked dead.' ],
  );

  is dropping($dbh),
    'OpenClient message: LAYER = (1) ORIGIN = (1) SEVERITY = (1) NUMBER = (63) '
    . 'Message String: ct_cmd_alloc(): the connection has been marked dead.',
    'what is no server message comes back on one line, and is not waited for';
  is scalar @{ $dbh->{sent} }, 1, '... one statement';
}

done_testing;
