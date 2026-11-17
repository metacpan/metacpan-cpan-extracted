use strict;
use warnings;
use Test::More;
use IPC::Open3 ();

use lib 't/lib';
use DBIOMySQLTestLanguage;

# WHY IT MATTERS. The live suite can run with the server reporting in German or
# French (DBIO_TEST_SERVER_LANGUAGE), to find tests that read an English server
# text, and the texts of the driver must hold no value in any language. The
# switch is one module that sets the session language on every connection DBI
# makes to a MySQL or MariaDB server, for every test process. It must change
# nothing when unset, leave the DSN and the attributes of the handle alone (a
# test builds its own DSN and sets an init_command), touch no other driver, and
# survive a refusal of the server.

is DBIOMySQLTestLanguage::locale_for(undef), undef, 'no language: nothing';
is DBIOMySQLTestLanguage::locale_for(''),    undef, 'an empty language: nothing';
is DBIOMySQLTestLanguage::locale_for('de'), 'de_DE', 'de';
is DBIOMySQLTestLanguage::locale_for('fr'), 'fr_FR', 'fr';
ok !eval { DBIOMySQLTestLanguage::locale_for('xx'); 1 }, 'an unknown language is refused';
like $@, qr/must be de or fr/, '... and says what is allowed';

# A handle as far as the module looks at it
{
  package FakeDbh;
  sub new { my ($class, %h) = @_; bless { Active => 1, RaiseError => 1, PrintError => 1, done => [], %h }, $class }
  sub do { my $s = shift; push @{ $s->{done} }, @_; die "refused\n" if $s->{refuse}; 1 }
}

sub fake { FakeDbh->new(Driver => { Name => $_[0] }, @_[1 .. $#_]) }

for my $driver (qw(mysql MariaDB)) {
  my $dbh = fake($driver);
  DBIOMySQLTestLanguage::set_session_language($dbh, 'de_DE');
  is_deeply $dbh->{done}, ["SET SESSION lc_messages = 'de_DE'"], "$driver: the session language is set";
  is "$dbh->{RaiseError}$dbh->{PrintError}", '11', "$driver: RaiseError and PrintError are what they were";
}

{
  my $dbh = fake('SQLite');
  DBIOMySQLTestLanguage::set_session_language($dbh, 'de_DE');
  is_deeply $dbh->{done}, [], 'another driver is left alone';
}
{
  my $dbh = fake('mysql', Active => 0);
  DBIOMySQLTestLanguage::set_session_language($dbh, 'de_DE');
  is_deeply $dbh->{done}, [], 'a handle that is not connected is left alone';
}
{
  my $dbh = fake('mysql', refuse => 1);
  ok eval { DBIOMySQLTestLanguage::set_session_language($dbh, 'de_DE'); 1 }, 'a refusal of the server is passed over';
}

# The module as prove loads it into a test process: the wrapper is there when
# a language is set, and only then.
sub connect_is_wrapped {
  my ($language) = @_;
  local $ENV{DBIO_TEST_SERVER_LANGUAGE} = $language;
  # A script file and a list-form open3: on Windows perl joins the list into a
  # command line that does not escape a double quote, so no argument holds one
  # nor anything a shell would read.
  my $pid = IPC::Open3::open3(my $in, my $out_fh, undef, $^X, '-It/lib', 't/lib/connect-wrapped-probe.pl');
  close $in;
  my $out = do { local $/; <$out_fh> };
  waitpid $pid, 0;
  return $out;
}
is connect_is_wrapped(''),   'same',    'unset: DBI->connect is the original';
is connect_is_wrapped('de'), 'wrapped', 'de: DBI->connect is wrapped';

done_testing;
