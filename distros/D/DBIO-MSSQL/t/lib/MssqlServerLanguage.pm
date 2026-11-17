package MssqlServerLanguage;
# Test helper: the language the server reports in.
#
# SQL Server writes its messages in the language of the session (SET LANGUAGE,
# the login's default, the server's default). DBIO_TEST_SERVER_LANGUAGE
# chooses it for a whole live run:
#
#   unset / empty   the default of the login (nothing is sent)
#   de              SET LANGUAGE German   (Deutsch)
#   fr              SET LANGUAGE French   (Français)
#
# The names of the languages are the aliases in sys.syslanguages, which are
# ASCII; they select the same language as 'Deutsch' and 'Français'. The
# language brings its own DATEFORMAT and DATEFIRST (German and French: dmy),
# as the login of a real German or French user has: the driver writes dates in
# a form no DATEFORMAT changes (t/133). Loading
# this module wraps DBI->connect of the test process: every connection to
# SQL Server it makes -- the storage's, a raw DBI->connect of a test, the
# throwaway database of a deploy, a reconnect -- gets the SET LANGUAGE right
# after the connect. Neither the login nor the server is changed; the setting
# belongs to the session. A test that reads an English wording of the server
# reads the English wording of the server and says so:
#
#   use MssqlServerLanguage 'english';   # the sessions of this test report in us_english
#
# whatever DBIO_TEST_SERVER_LANGUAGE says (t/131 names its languages itself, by
# on_connect_do).

use strict;
use warnings;
use DBI ();

my %LANGUAGE = (de => 'German', fr => 'French');

sub language {
  my $key = lc( $ENV{DBIO_TEST_SERVER_LANGUAGE} // '' );
  return undef unless length $key;
  die "DBIO_TEST_SERVER_LANGUAGE must be empty, 'de' or 'fr', not '$key'\n"
    unless $LANGUAGE{$key};
  return $LANGUAGE{$key};
}

our $language = language();

sub import {
  my ($class, @args) = @_;
  for my $arg (@args) {
    die "MssqlServerLanguage: unknown import '$arg'\n" unless $arg eq 'english';
    # only when the run asks for another language: nothing is sent otherwise
    $language = 'us_english' if defined $language;
  }
}

unless ($DBI::connect::{_mssql_server_language_wrapped}) {
  no warnings 'redefine';
  my $connect = \&DBI::connect;
  *DBI::connect = sub {
    my $dbh = $connect->(@_);
    if (defined $language and $dbh and ref $dbh
        and $dbh->{Driver}->{Name} =~ /\A(?:ODBC|Sybase)\z/) {
      local ($dbh->{RaiseError}, $dbh->{PrintError}, $dbh->{HandleError}) = (0, 0, undef);
      $dbh->do("SET LANGUAGE $language");
    }
    return $dbh;
  };
  $DBI::connect::{_mssql_server_language_wrapped} = 1;
}

1;
