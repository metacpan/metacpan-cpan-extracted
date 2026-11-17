package DBIOMySQLTestLanguage;

# The live suite in another language of the server. MySQL and MariaDB word
# their errors in the language of the session (lc_messages). With
# DBIO_TEST_SERVER_LANGUAGE set to de or fr, every connection that DBI makes to
# a MySQL or MariaDB server is switched to that language right after it is
# made (SET SESSION, never SET GLOBAL). The DSN and its attributes are not
# touched, so a test that builds its own DSN or sets an init_command keeps
# working. Loaded into each test process by .proverc; unset or empty changes
# nothing. A test that reads the English text of the server sets its own
# session to en_US in its on_connect_do, which runs after this.

use strict;
use warnings;
use DBI;

my %LOCALE = (de => 'de_DE', fr => 'fr_FR');

# The locale of a language, nothing for none, a refusal for one we do not know.
sub locale_for {
  my ($language) = @_;

  return undef unless defined $language && length $language;

  return $LOCALE{$language}
    // die "DBIO_TEST_SERVER_LANGUAGE must be de or fr, not '$language'\n";
}

# The session of a connected handle of the MySQL or MariaDB driver reports in
# the locale. Any failure is passed over, and the attributes of the handle are
# what they were.
sub set_session_language {
  my ($dbh, $locale) = @_;

  eval {
    my $driver = $dbh->{Driver}{Name};
    if (defined $driver && $driver =~ /\A(?:mysql|MariaDB)\z/ && $dbh->{Active}) {
      local $dbh->{RaiseError} = 0;
      local $dbh->{PrintError} = 0;
      $dbh->do("SET SESSION lc_messages = '$locale'");
    }
  };

  return $dbh;
}

sub install {
  my ($locale) = @_;

  for my $name (qw(connect connect_cached)) {
    no strict 'refs';
    no warnings 'redefine';

    my $original = \&{"DBI::$name"};
    *{"DBI::$name"} = sub {
      my @dbh = wantarray ? $original->(@_) : scalar $original->(@_);
      set_session_language($dbh[0], $locale) if ref $dbh[0];
      return wantarray ? @dbh : $dbh[0];
    };
  }
}

# The locale this process runs in, nothing when the switch is off. t/01 reads it
# to tell a run whose harness did not load the module.
our $ACTIVE = locale_for($ENV{DBIO_TEST_SERVER_LANGUAGE});
install($ACTIVE) if defined $ACTIVE;

1;
