use strict;
use warnings;
use Test::More;

# The EV::MariaDB side of t/66-test-server-language.t, run in a process of its
# own (the parent runs under the hook, with the real EV::MariaDB loaded and
# wrapped; this one defines a fake EV::MariaDB and wraps that).
BEGIN { delete $ENV{DBIO_TEST_SERVER_LANGUAGE} }
use DBIOMySQLEVTestLanguage;

# --- the EV::MariaDB side -------------------------------------------------------
{
  package EV::MariaDB;
  our @LOG;
  sub new {
    my ($class, %args) = @_;
    push @LOG, [ new => { %args, on_connect => $args{on_connect} ? 'cb' : undef } ];
    return bless { args => \%args, sent => [] }, $class;
  }
  sub connect_now { my $s = shift; $s->{args}{on_connect}->() if $s->{args}{on_connect} }
  sub query {
    my ($s, $sql, $cb) = @_;
    die "queue refused\n" if $s->{refuse};
    push @{ $s->{sent} }, $sql;
    push @{ $s->{pending} }, $cb;
    return 1;
  }
  sub reset_connection {
    my ($s, $cb) = @_;
    push @{ $s->{sent} }, 'RESET';
    $cb->($s->{reset_fails} ? (undef, 'reset failed') : (1));
  }
}
DBIOMySQLEVTestLanguage::install_ev('fr_FR');

{
  my @theirs;
  my $mdb = EV::MariaDB->new(host => 'h', user => 'u', password => 'p', on_connect => sub { push @theirs, [ @{ $_[0] // [] } ]; 'theirs' });
  is_deeply $mdb->{sent}, [], 'a handle that is not connected has sent nothing';
  is $mdb->{args}{host}, 'h', 'the connect parameters are what they were';
  $mdb->connect_now;
  is_deeply $mdb->{sent}, ["SET SESSION lc_messages = 'fr_FR'"], 'connected: the session language is set';
  is scalar(@theirs), 0, '... the caller\'s on_connect waits for the answer';
  (shift @{ $mdb->{pending} })->();
  is scalar(@theirs), 1, '... and runs once the server answered';
  $mdb->connect_now;
  is scalar(@{ $mdb->{sent} }), 2, 'a reconnect sets it again';
  (shift @{ $mdb->{pending} })->();

  $mdb->{sent} = [];
  my @answer;
  $mdb->reset_connection(sub { push @answer, [ @_, scalar @{ $mdb->{sent} } ] });
  is_deeply $mdb->{sent}, ['RESET', "SET SESSION lc_messages = 'fr_FR'"], 'a reset is followed by the language';
  is scalar(@answer), 0, '... the reset callback waits for the answer to it';
  (shift @{ $mdb->{pending} })->();
  is_deeply $answer[0], [1, 2], '... and runs then, with its answer';

  $mdb->{sent} = []; $mdb->{reset_fails} = 1; @answer = ();
  $mdb->reset_connection(sub { push @answer, [ @_ ] });
  is_deeply $mdb->{sent}, ['RESET'], 'a failed reset sends nothing more';
  is_deeply $answer[0], [undef, 'reset failed'], '... and passes its failure on';
}
{
  my $ran = 0;
  my $mdb = EV::MariaDB->new(host => 'h', on_connect => sub { $ran++ });
  $mdb->{refuse} = 1;
  ok eval { $mdb->connect_now; 1 }, 'a handle that refuses the statement is passed over';
  is $ran, 1, '... and the caller\'s on_connect runs';
}
{
  my $mdb = EV::MariaDB->new;
  is_deeply $mdb->{args}, {}, 'an inert handle (no parameters) is made as it was';
}


done_testing;
