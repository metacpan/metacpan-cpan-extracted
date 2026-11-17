package LibpqEnglish;
use strict;
use warnings;
use POSIX ();

# A test that compares libpq's own wording (its reasons for a refused
# connection, the "LINE 1:" context of an error, a URI it cannot read) loads
# this first.
#
# WHY: libpq translates its messages through gettext, by the locale of the
# process, and perl takes that locale from the environment when it starts. On
# a machine set to de_DE the text reads "ZEILE 1:", not "LINE 1:", and the
# pattern fails although the password is masked just the same. So the message
# locale is C, for this process and, through the environment, for any child:
#   * LC_ALL beats LC_MESSAGES, so it is set to C, not only LC_MESSAGES;
#   * GNU gettext reads LANGUAGE while the locale is not C, so it goes.
# The test then still claims libpq's own words; none of it is skipped or loosened.
#
# On Windows POSIX does not define LC_MESSAGES: POSIX::LC_MESSAGES() dies
# there with "Your vendor has not defined POSIX macro LC_MESSAGES". The
# setlocale call is therefore in an eval, and the environment does the work.
# libpq does not call setlocale; it translates through dgettext (fe-misc.c,
# libpq_gettext) and libintl takes the language from LANGUAGE, LC_ALL,
# LC_MESSAGES and LANG. Caveat: perl sets %ENV on Windows with
# SetEnvironmentVariableA (win32.c, win32_putenv), not in the CRT's environ,
# and what libpq reads in the process is the environment taken over at start.
# So the assignment reaches child processes and the Win32 environment; that
# it reaches libpq's gettext in this very process is not established here.

BEGIN {
  eval { POSIX::setlocale(POSIX::LC_MESSAGES(), 'C'); 1 };
  $ENV{LC_ALL} = $ENV{LC_MESSAGES} = 'C';
  delete $ENV{LANGUAGE};
}

1;
