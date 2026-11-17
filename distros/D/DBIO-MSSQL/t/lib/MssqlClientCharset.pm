package MssqlClientCharset;
# Test helper: the client character set of the FreeTDS drivers.
#
# A test that writes or reads text beyond ASCII needs a client character set of
# UTF-8: over DBD::ODBC (without Unicode support) the storage refuses such text
# otherwise, rather than let the driver garble it, and over DBD::Sybase the
# client library turns what it cannot convert into question marks. FreeTDS takes
# that character set from the locale of the process (LC_ALL, LANG), so a run
# under de_DE.iso88591 would get ISO-8859-1 and a run under C would get ASCII.
# A test that needs UTF-8 does not depend on the locale it is started under:
#
#   use MssqlClientCharset;        # LC_CTYPE of the process is UTF-8 from here on
#   my $dsn = MssqlClientCharset::utf8($ENV{DBIO_TEST_MSSQL_ODBC_DSN});
#
# DBD::ODBC: the DSN says it (ClientCharset=UTF-8), a DSN that names a
# ClientCharset already keeps it. DBD::Sybase has no such DSN setting that
# FreeTDS honours (charset= is ignored, measured), so loading this module
# switches LC_CTYPE of the process to a UTF-8 locale when it is not one
# already, before any connection is made; LC_CTYPE alone, the language of the
# messages is not touched. Without a UTF-8 locale on the host the load dies:
# a test that is not told what it needs must not run on a guess.
#
# A test about the refusal under another character set names that character
# set itself (MssqlClientCharset::with($dsn, 'ISO-8859-1')), for the same
# reason: the refusal must not depend on the locale either.

use strict;
use warnings;
use POSIX ();

# I18N::Langinfo is no part of every perl: Strawberry Perl 5.20 for Windows
# has none (win32/config.gc: d_nl_langinfo='undef', and win32/FindExt.pm
# leaves the extension out unless i_langinfo and d_nl_langinfo are set);
# from perl 5.28 on it works on every platform (emulated where libc lacks
# nl_langinfo). Without it the code set is read from the NAME of the locale
# (what setlocale(LC_CTYPE) answers), and when that does not say UTF-8 the
# code set is unknown -- the helper then neither dies nor guesses; a test
# that needs the locale (DBD::Sybase) asks utf8_locale_skip_reason.
my $HAVE_LANGINFO = eval { require I18N::Langinfo; 1 } ? 1 : 0;
my $SKIP_REASON;

sub _is_utf8 { defined $_[0] and $_[0] =~ /\Autf-?8\z/i }

sub _codeset { I18N::Langinfo::langinfo(I18N::Langinfo::CODESET()) }

sub _locale_is_utf8 {
  if ($HAVE_LANGINFO) { return _is_utf8(_codeset()) }
  my $name = POSIX::setlocale(POSIX::LC_CTYPE());
  return defined $name && $name =~ /utf-?8/i;
}

sub import {
  return if _locale_is_utf8();
  for my $locale (qw(C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8 de_DE.UTF-8 de_DE.utf8)) {
    POSIX::setlocale(POSIX::LC_CTYPE(), $locale) or next;
    return if _locale_is_utf8();
  }
  die "MssqlClientCharset: no UTF-8 locale on this host for the client character set\n"
    if $HAVE_LANGINFO;
  $SKIP_REASON = 'the client character set of this host is unknown '
    . '(no I18N::Langinfo, and the locale is not named as UTF-8)';
}

# undef when the process runs under a UTF-8 locale (or the code set was
# verified); otherwise the reason a test that needs it over DBD::Sybase skips.
sub utf8_locale_skip_reason { $SKIP_REASON }

sub with {
  my ($dsn, $charset) = @_;
  $dsn =~ s/;?\s*ClientCharset=[^;]*//ig;
  $dsn =~ s/;\z//;
  return "$dsn;ClientCharset=$charset";
}

sub utf8 {
  my ($dsn) = @_;
  return $dsn unless defined $dsn and $dsn =~ /\Adbi:ODBC:/i;
  return $dsn if $dsn =~ /ClientCharset=/i;
  return with($dsn, 'UTF-8');
}

1;
