package LibpqCLocale;

use strict;
use warnings;

use POSIX ();

# libpq translates its own messages (gettext) into the locale of the process:
# under LC_ALL=de_DE.utf8 it answers "ein anderer Befehl ist bereits in
# Ausführung" where a test reads "another command is already in progress".
# A test that holds libpq's own wording -- what the password mask keeps, what
# libpq says of a bad conninfo, of a refused connect -- loads this first
# (`use LibpqCLocale;` before anything calls into libpq) so that it runs the
# same in every locale. Nothing is relaxed: the test still reads libpq's text.
#
# The message locale goes to C in this process (setlocale) and in the
# environment, for the child processes a test starts. LC_ALL in the
# environment beats LC_MESSAGES, and GNU gettext reads LANGUAGE for as long
# as the locale is not C, so LC_ALL is set and LANGUAGE dropped.
#
# Windows has no POSIX::LC_MESSAGES ("Your vendor has not defined POSIX macro
# LC_MESSAGES"), and libpq calls no setlocale there either: it asks libintl,
# which reads the environment (LANGUAGE, LC_ALL, LC_MESSAGES, LANG). So the
# environment is the way to C on that platform, and setlocale is only called
# where the constant exists (t/123).
BEGIN {
  $ENV{LC_ALL} = 'C';
  delete $ENV{LANGUAGE};
  delete $ENV{LC_MESSAGES};
  my $lc_messages = eval { POSIX::LC_MESSAGES() };
  POSIX::setlocale($lc_messages, 'C') if defined $lc_messages;
}

1;
