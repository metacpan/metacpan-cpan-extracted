# Child program of t/134: run with -MNoLanginfo; the first argument is the case.
use strict;
use warnings;
use POSIX ();

my $case = shift;

if ($case eq 'unknown') {
  # a locale that is not UTF-8 and cannot be switched
  BEGIN { no warnings 'redefine'; *POSIX::setlocale = sub { $_[1] ? undef : 'C' } if ($ARGV[0] // '') eq 'unknown' }
}

require MssqlClientCharset;
MssqlClientCharset->import;

if ($case eq 'unknown') {
  print MssqlClientCharset::utf8_locale_skip_reason() // 'none';
}
else {
  print defined MssqlClientCharset::utf8_locale_skip_reason() ? 'reason' : 'none';
  print '|', MssqlClientCharset::utf8('dbi:ODBC:x');
}
