package FakeNotifyServer;

# A test-only model of the notify table on a MySQL server, answering exactly
# the statements DBIO::MySQL::NotifyTable builds -- recognised by shape, their
# bind values and the integers they interpolate. What it models, because the
# emulation's correctness depends on it:
#
#   - AUTO_INCREMENT ids handed out at INSERT, rows visible only once committed
#     (insert(..., visible => 0) then commit($id)): the out-of-order commit;
#   - created_at from the server clock (a settable epoch, UTC);
#   - the channel column's utf8mb4_bin PAD SPACE comparison ('jobs' = 'jobs ',
#     but case-sensitive), so the exact matching in Perl is exercised;
#   - a missing table, and a DELETE the account may not run.
#
# The live tests are what check the real server; this model only lets the
# offline tests drive every path deterministically.

use strict;
use warnings;
use POSIX ();

sub new {
  my ($class, %args) = @_;
  return bless {
    now          => $args{now} // 1_800_000_000,
    table        => $args{table} // 'dbio_notify',
    exists       => $args{exists} // 1,
    rows         => [],
    seq          => 0,
    log          => [],
    deny_delete  => 0,
  }, $class;
}

sub now     { $_[0]{now} }
sub advance { $_[0]{now} += $_[1]; return }

sub stamp {
  my ($self, $t) = @_;
  $t //= $self->{now};
  my $sec = POSIX::floor($t);
  my $us  = int(($t - $sec) * 1_000_000 + 0.5);
  if ($us >= 1_000_000) { $sec++; $us -= 1_000_000 }
  return POSIX::strftime('%Y-%m-%d %H:%M:%S', gmtime $sec) . sprintf('.%06d', $us);
}

# A notification written by some session. visible => 0 leaves its transaction
# open; commit($id) makes it visible. Returns the id.
sub insert {
  my ($self, $channel, $payload, %opt) = @_;
  my $id = ++$self->{seq};
  push @{ $self->{rows} }, {
    id         => $id,
    channel    => $channel,
    payload    => $payload // '',
    pid        => $opt{pid} // 777,
    created_at => $self->stamp($opt{at}),
    visible    => $opt{visible} // 1,
  };
  return $id;
}

sub commit {
  my ($self, $id) = @_;
  $_->{visible} = 1 for grep { $_->{id} == $id } @{ $self->{rows} };
  return;
}

sub visible { grep { $_->{visible} } @{ $_[0]{rows} } }

# utf8mb4_bin is PAD SPACE: trailing spaces do not count, case does.
sub pad_eq {
  my ($x, $y) = @_;
  s/ +\z// for $x, $y;
  return $x eq $y;
}

sub _missing {
  my ($self) = @_;
  die "Table 'fake.$self->{table}' doesn't exist\n" unless $self->{exists};
  return;
}

# Answer one statement: { rows => [...], fields => N, rv => N, insertid => N },
# or die with the server's message.
sub answer {
  my ($self, $sql, $bind, $pid) = @_;
  $bind //= [];
  push @{ $self->{log} }, { sql => $sql, bind => [@$bind], pid => $pid };

  if ($sql =~ /\ACREATE TABLE IF NOT EXISTS `(\w+)`/) {
    $self->{exists} = 1 if $1 eq $self->{table};
    return { rows => [], fields => 0, rv => '0E0' };
  }
  if ($sql =~ /\ADROP TABLE IF EXISTS `(\w+)`/) {
    $self->{exists} = 0 if $1 eq $self->{table};
    return { rows => [], fields => 0, rv => '0E0' };
  }

  if ($sql =~ /\AINSERT INTO `(\w+)` \(`channel`, `payload`, `pid`, `created_at`\) VALUES \(\?, \?, CONNECTION_ID\(\), UTC_TIMESTAMP\(6\)\)\z/) {
    $self->_missing;
    die "Column 'payload' cannot be null\n" unless defined $bind->[1];
    my $id = $self->insert($bind->[0], $bind->[1], pid => $pid);
    return { rows => [], fields => 0, rv => 1, insertid => $id };
  }

  my ($us) = $sql =~ /INTERVAL (\d+) MICROSECOND/;

  if ($sql =~ /\ASELECT `id`, NULL, NULL, NULL, NULL FROM `\w+` WHERE `channel` = \? AND `created_at` >= UTC_TIMESTAMP\(6\) - INTERVAL \d+ MICROSECOND UNION ALL SELECT \(SELECT COALESCE\(MAX\(`id`\), 0\) FROM `\w+` WHERE `channel` = \?\), NULL, NULL, NULL, DATE_FORMAT\(UTC_TIMESTAMP\(6\) - INTERVAL \d+ MICROSECOND, '%Y-%m-%d %H:%i:%s.%f'\)\z/) {
    $self->_missing;
    my $since = $self->stamp($self->{now} - $us / 1_000_000);
    my @mine  = grep { pad_eq($_->{channel}, $bind->[0]) } $self->visible;
    my @rows  = map { [ "$_->{id}", undef, undef, undef, undef ] }
                grep { $_->{created_at} ge $since } @mine;
    my ($max) = sort { $b <=> $a } map { $_->{id} } @mine;
    push @rows, [ $max // 0, undef, undef, undef, $since ];
    return { rows => \@rows, fields => 5 };
  }

  if ($sql =~ /\ASELECT `id`, `channel`, `payload`, `pid`, NULL FROM `\w+` WHERE /) {
    $self->_missing;
    my $n = () = $sql =~ /`id` > CAST\(\? AS UNSIGNED\)/g;
    my @by_id   = @{$bind}[0 .. 2 * $n - 1];
    my @by_time = @{$bind}[2 * $n .. 4 * $n - 1];
    my @visible = $self->visible;
    my @rows;
    for my $r (@visible) {
      push @rows, [ $r->{id}, $r->{channel}, $r->{payload}, $r->{pid}, undef ]
        if grep { pad_eq($r->{channel}, $by_id[2 * $_]) && $r->{id} > $by_id[2 * $_ + 1] } 0 .. $n - 1;
    }
    for my $r (@visible) {
      push @rows, [ $r->{id}, $r->{channel}, $r->{payload}, $r->{pid}, undef ]
        if grep { pad_eq($r->{channel}, $by_time[2 * $_]) && $r->{created_at} ge $by_time[2 * $_ + 1] } 0 .. $n - 1;
    }
    push @rows, [ undef, undef, undef, undef, $self->stamp($self->{now} - $us / 1_000_000) ];
    return { rows => \@rows, fields => 5 };
  }

  if ($sql =~ /\ADELETE FROM `\w+` WHERE `created_at` < UTC_TIMESTAMP\(6\) - INTERVAL \d+ MICROSECOND LIMIT (\d+)\z/) {
    my $limit = $1;
    $self->_missing;
    die "DELETE command denied to user 'listener'\@'%' for table '$self->{table}'\n"
      if $self->{deny_delete};
    my $before = $self->stamp($self->{now} - $us / 1_000_000);
    my @gone = (grep { $_->{visible} && $_->{created_at} lt $before }
                sort { $a->{created_at} cmp $b->{created_at} } @{ $self->{rows} })[0 .. $limit - 1];
    my %gone = map { $_->{id} => 1 } grep { defined } @gone;
    $self->{rows} = [ grep { !$gone{ $_->{id} } } @{ $self->{rows} } ];
    my $count = keys %gone;
    return { rows => [], fields => 0, rv => $count || '0E0' };
  }

  die "FakeNotifyServer: unrecognised statement: $sql\n";
}

# The statements run, optionally only those matching a pattern.
sub statements {
  my ($self, $re) = @_;
  return grep { !$re || $_->{sql} =~ $re } @{ $self->{log} };
}

1;
