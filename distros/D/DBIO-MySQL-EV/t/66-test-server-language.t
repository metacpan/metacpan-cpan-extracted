use strict;
use warnings;
use Test::More;

use lib 't/lib';

# WHY IT MATTERS. The live suite can run with the server reporting in German or
# French (DBIO_TEST_SERVER_LANGUAGE), to find tests that read an English server
# text, and the texts of the driver must hold no value in any language. This
# transport has no DBI handle: its connections are EV::MariaDB handles, which
# a DBI hook never sees. The hook (t/lib/DBIOMySQLEVTestLanguage.pm) therefore
# also takes the handle: it sends the SET SESSION right after the connect (and
# after every reconnect), before anything the transport queues, and again after
# COM_RESET_CONNECTION, which drops the session variables -- the pool resets a
# connection at the end of every borrow. It must change nothing when unset,
# leave the connect parameters and the callbacks of the caller alone, touch no
# other driver, and survive a refusal of the server. This file runs it against
# a fake EV::MariaDB and a fake DBI handle.

use DBIOMySQLEVTestLanguage;

is DBIOMySQLEVTestLanguage::locale_for(undef), undef, 'no language: nothing';
is DBIOMySQLEVTestLanguage::locale_for(''),    undef, 'an empty language: nothing';
is DBIOMySQLEVTestLanguage::locale_for('de'), 'de_DE', 'de';
is DBIOMySQLEVTestLanguage::locale_for('fr'), 'fr_FR', 'fr';
ok !eval { DBIOMySQLEVTestLanguage::locale_for('xx'); 1 }, 'an unknown language is refused';
like $@, qr/must be de or fr/, '... and says what is allowed';

# --- the DBI side --------------------------------------------------------------
{
  package FakeDbh;
  sub new { my ($class, %h) = @_; bless { Active => 1, RaiseError => 1, PrintError => 1, done => [], %h }, $class }
  sub do { my $s = shift; push @{ $s->{done} }, @_; die "refused\n" if $s->{refuse}; 1 }
}
sub fake { FakeDbh->new(Driver => { Name => $_[0] }, @_[1 .. $#_]) }

for my $driver (qw(mysql MariaDB)) {
  my $dbh = fake($driver);
  DBIOMySQLEVTestLanguage::set_session_language($dbh, 'de_DE');
  is_deeply $dbh->{done}, ["SET SESSION lc_messages = 'de_DE'"], "$driver: the session language is set";
  is "$dbh->{RaiseError}$dbh->{PrintError}", '11', "$driver: RaiseError and PrintError are what they were";
}
{
  my $dbh = fake('SQLite');
  DBIOMySQLEVTestLanguage::set_session_language($dbh, 'de_DE');
  is_deeply $dbh->{done}, [], 'another driver is left alone';
}
{
  my $dbh = fake('mysql', refuse => 1);
  ok eval { DBIOMySQLEVTestLanguage::set_session_language($dbh, 'de_DE'); 1 }, 'a refusal of the server is passed over';
}

# --- the EV::MariaDB side, against a fake handle, in a process of its own ----------
{
  my $out = `$^X -Ilib -It/lib t/lib/ev-language-fake-check.pl 2>&1`;
  my $status = $?;
  my @bad = grep { /^not ok/ } split /\n/, $out;
  is $status, 0, 'the EV::MariaDB hook checks pass against a fake handle'
    or diag $out;
  my ($count) = $out =~ /^1\.\.(\d+)/m;
  ok $count && $count > 10, '... and they ran';
}

# --- the module as prove loads it into a test process ----------------------------
sub connect_is_wrapped {
  my ($language) = @_;
  local $ENV{DBIO_TEST_SERVER_LANGUAGE} = $language;
  my $code = q{use DBI; my $before = \&DBI::connect; require DBIOMySQLEVTestLanguage; print \&DBI::connect == $before ? 'same' : 'wrapped'};
  return `$^X -It/lib -e '$code' 2>&1`;
}
is connect_is_wrapped(''),   'same',    'unset: DBI->connect is the original';
is connect_is_wrapped('de'), 'wrapped', 'de: DBI->connect is wrapped';

sub ev_is_wrapped {
  my ($language) = @_;
  local $ENV{DBIO_TEST_SERVER_LANGUAGE} = $language;
  my $code = q{BEGIN { package EV::MariaDB; sub new {} sub reset_connection {} $INC{"EV/MariaDB.pm"} = 1 } my $before = \&EV::MariaDB::new; require DBIOMySQLEVTestLanguage; print \&EV::MariaDB::new == $before ? "same" : "wrapped"};
  return `$^X -It/lib -e '$code' 2>&1`;
}
is ev_is_wrapped(''),   'same',    'unset: EV::MariaDB->new is the original';
is ev_is_wrapped('fr'), 'wrapped', 'fr: EV::MariaDB->new is wrapped';

# The real EV::MariaDB is wrapped when it is loaded, and not loaded by the hook:
# an offline test that stands a fake class in its place must not find the XS
# class under it (a fake object would meet the real DESTROY).
{
  local $ENV{DBIO_TEST_SERVER_LANGUAGE} = 'de';
  my $out = `$^X -It/lib -e 'use DBIOMySQLEVTestLanguage; print \$INC{"EV/MariaDB.pm"} ? "loaded" : "not loaded"' 2>&1`;
  is $out, 'not loaded', 'the hook does not load EV::MariaDB itself';

  SKIP: {
    skip 'EV::MariaDB is not installed', 1 unless eval { require EV::MariaDB; 1 };
    my $code = q{use B (); use DBIOMySQLEVTestLanguage; require EV::MariaDB; print B::svref_2object(\&EV::MariaDB::new)->XSUB ? "xs" : "wrapped"};
    is `$^X -It/lib -e '$code' 2>&1`, 'wrapped', 'the real EV::MariaDB->new is wrapped once it is loaded';
  }
}

done_testing;
