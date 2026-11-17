use strict;
use warnings;

use Test::More;
use File::Spec ();
use IPC::Open3 ();

# What this holds: the live test files and their helper t/lib/MssqlClientCharset.pm
# run on a perl without I18N::Langinfo (Strawberry Perl 5.20 for Windows:
# win32/config.gc has d_nl_langinfo='undef' and win32/FindExt.pm then leaves
# the extension out; it works on every platform from perl 5.28 on). Before,
# the helper's `use I18N::Langinfo` died at compile time, so t/76, t/80, t/82
# and t/123 ended without a plan even where they skip for want of a DSN.
# The case is put together by t/lib/NoLanginfo.pm, an @INC hook that answers
# "Can't locate" for I18N/Langinfo.pm, in a child perl. The child is started
# in list form without a shell (a backtick goes through cmd.exe on Windows,
# where '...' quotes nothing); its programs are files, not -e strings.

sub run_child {
  my ($env, @args) = @_;
  local %ENV = (%ENV, %$env);
  delete @ENV{qw(DBIO_TEST_MSSQL_DSN DBIO_TEST_MSSQL_ODBC_DSN)};
  open my $in, '<', File::Spec->devnull or die $!;
  my $pid = IPC::Open3::open3($in, my $out, undef,
    $^X, '-It/lib', '-Ilib', '-MNoLanginfo', @args);
  my $text = do { local $/; <$out> };
  waitpid $pid, 0;
  my $rc = $? >> 8;
  $text =~ s/\r\n/\n/g;
  return ($text, $rc);
}

for my $file (qw(t/76-odbc-unicode-binds-live.t t/80-server-type-live.t
                 t/82-nonascii-empty-live.t t/123-odbc-read-utf8-live.t)) {
  my ($out, $rc) = run_child({}, $file);
  like $out, qr/^1\.\.0 # SKIP/m, "$file skips without a DSN on a perl without I18N::Langinfo";
  is $rc, 0, "$file exits 0";
}

# The block below models POSIX locale names (C.UTF-8), which the Windows C
# runtime does not know; block 1 shows the Windows case there.
SKIP: {
  skip 'models POSIX locale names; on Windows the live files of block 1 show it', 3
    if $^O eq 'MSWin32';

  # the helper loads, and under a UTF-8 locale reports nothing to skip for
  my ($out) = run_child({ LC_ALL => 'C.UTF-8' }, 't/lib/charset_probe.pl', 'utf8');
  is $out, 'none|dbi:ODBC:x;ClientCharset=UTF-8', 'helper works without Langinfo under a UTF-8 locale';

  # a locale that is not UTF-8 and cannot be switched: the code set is unknown,
  # the helper does not die, a DBD::Sybase test gets a reason to skip
  my $rc;
  ($out, $rc) = run_child({ LC_ALL => 'C', LANG => 'C' }, 't/lib/charset_probe.pl', 'unknown');
  like $out, qr/character set of this host is unknown/, 'unknown character set is a reason to skip, not a death';
  is $rc, 0, 'and no failure';
}

done_testing;
