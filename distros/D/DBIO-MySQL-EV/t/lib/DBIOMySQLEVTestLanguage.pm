package DBIOMySQLEVTestLanguage;

# The live suite in another language of the server. MySQL and MariaDB word
# their errors in the language of the session (lc_messages). With
# DBIO_TEST_SERVER_LANGUAGE set to de or fr, every connection this dist makes
# to a server is switched to that language right after it is made (SET
# SESSION, never SET GLOBAL):
#
#  - the synchronous DBI side (the owning sync storage, test helpers): the
#    handle DBI->connect returns, as in dbio-mysql;
#  - every EV::MariaDB handle (pool connections, the listen connection, a
#    transaction's pinned one): EV::MariaDB->new is wrapped (when the class is
#    loaded, see install_ev_on_load) so that the
#    handle sends the SET once it is connected -- again after every reconnect
#    -- and only then calls the caller's on_connect, and COM_RESET_CONNECTION,
#    which drops the session variables with the rest of the session, is
#    followed by the same SET before its callback runs, so the statements
#    behind the reset of a borrow see the language too.
#
# Nothing in lib/ knows of this; the DSN, the connect parameters and the
# attributes are not touched. Loaded into each test process by .proverc;
# unset or empty changes nothing. A test that reads the English text of the
# server sets its own session to en_US (on_connect_do, which runs after this).

use strict;
use warnings;
use DBI;
use Scalar::Util ();

my %LOCALE = (de => 'de_DE', fr => 'fr_FR');

# A test that reads the English text of a connection it cannot reach (the
# listen connection is made by the transport) sets this to 'en_US' for the
# time the connection is made: `local $DBIOMySQLEVTestLanguage::OVERRIDE = 'en_US'`.
our $OVERRIDE;

# The locale of a language, nothing for none, a refusal for one we do not know.
sub locale_for {
  my ($language) = @_;

  return undef unless defined $language && length $language;

  return $LOCALE{$language}
    // die "DBIO_TEST_SERVER_LANGUAGE must be de or fr, not '$language'\n";
}

sub session_sql { "SET SESSION lc_messages = '$_[0]'" }

# The session of a connected DBI handle of the MySQL or MariaDB driver reports
# in the locale. Any failure is passed over.
sub set_session_language {
  my ($dbh, $locale) = @_;

  eval {
    my $driver = $dbh->{Driver}{Name};
    if (defined $driver && $driver =~ /\A(?:mysql|MariaDB)\z/ && $dbh->{Active}) {
      local $dbh->{RaiseError} = 0;
      local $dbh->{PrintError} = 0;
      $dbh->do(session_sql($locale));
    }
  };

  return $dbh;
}

# An EV::MariaDB handle sends the SET and runs $then once the server answered
# it (at once when the handle refuses the statement): the handle takes one
# operation at a time, so what the transport sends right behind the connect or
# the reset must find it idle.
sub set_handle_language {
  my ($mdb, $locale, $then) = @_;
  $locale = $OVERRIDE if defined $OVERRIDE;
  my $sent = eval { $mdb->query(session_sql($locale), sub { $then->() if $then }); 1 };
  $then->() if !$sent && $then;
  return;
}

sub install_dbi {
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

sub install_ev {
  my ($locale) = @_;

  no strict 'refs';
  no warnings 'redefine';

  my $new   = \&{'EV::MariaDB::new'};
  my $reset = \&{'EV::MariaDB::reset_connection'};

  *{'EV::MariaDB::new'} = sub {
    my ($class, %args) = @_;
    # no connect parameters: an inert handle, nothing to switch
    return $class->$new(%args) unless %args;

    my $weak;
    my $on_connect = $args{on_connect};
    $args{on_connect} = sub {
      my @args = @_;
      my $go = sub { $on_connect ? $on_connect->(@args) : () };
      return $weak ? set_handle_language($weak, $locale, $go) : $go->();
    };
    my $mdb = $class->$new(%args);
    Scalar::Util::weaken($weak = $mdb) if ref $mdb;
    return $mdb;
  };

  *{'EV::MariaDB::reset_connection'} = sub {
    my ($mdb, $cb) = @_;
    return $mdb->$reset($cb) unless $cb;
    return $mdb->$reset(sub {
      my @answer = @_;
      my ($ok, $err) = @answer;
      return $cb->(@answer) unless $ok && !$err;
      return set_handle_language($mdb, $locale, sub { $cb->(@answer) });
    });
  };
}

# EV::MariaDB is wrapped when it is loaded, not before: the offline tests
# that stand a fake EV::MariaDB in its place (they set $INC{'EV/MariaDB.pm'})
# must not get the real XS class loaded under them. An @INC hook reads the real
# EV/MariaDB.pm and appends the wrapping to its source, so the wrapper is in
# place the moment the class is.
sub install_ev_on_load {
  my ($locale) = @_;

  return install_ev($locale) if $INC{'EV/MariaDB.pm'} && defined &EV::MariaDB::new;
  return if $INC{'EV/MariaDB.pm'};

  unshift @INC, sub {
    my ($self, $file) = @_;
    return unless $file eq 'EV/MariaDB.pm';
    for my $dir (grep { !ref } @INC) {
      my $path = "$dir/$file";
      next unless -f $path;
      open my $fh, '<', $path or return;
      my $source = do { local $/; <$fh> };
      close $fh;
      $source =~ s/^__END__\n.*\z//ms;
      $source .= "\n;DBIOMySQLEVTestLanguage::install_ev('$locale');\n1;\n";
      $INC{$file} = $path;
      return \$source;
    }
    return;
  };
  return;
}

sub install {
  my ($locale) = @_;

  install_dbi($locale);
  install_ev_on_load($locale);
}

# The locale this process runs in, nothing when the switch is off. t/00 reads
# it to tell a run whose harness did not load the module.
our $ACTIVE = locale_for($ENV{DBIO_TEST_SERVER_LANGUAGE});
install($ACTIVE) if defined $ACTIVE;

1;
