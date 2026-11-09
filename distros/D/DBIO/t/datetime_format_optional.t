use strict;
use warnings;

# A bare DBIO install must carry no DateTime dependency. The driver
# datetime format base DBIO::Storage::DateTimeFormat loads
# DateTime::Format::Strptime lazily, at first parse/format, and throws a clear,
# actionable error when it is genuinely needed but absent.
#
# We simulate the absent module with an @INC coderef hook that makes exactly
# that one file unloadable — no dependency on Test::Without::Module (which is
# not a declared test dep of this dist). Everything else loads normally.
BEGIN {
  unshift @INC, sub {
    my (undef, $file) = @_;
    die "Can't locate $file in \@INC (hidden by $0)\n"
      if $file eq 'DateTime/Format/Strptime.pm';
    return;
  };
  delete $INC{'DateTime/Format/Strptime.pm'};
}

use Test::More;
use Test::Exception;

# (a) the subsystem itself still loads with DateTime::Format::Strptime absent
use_ok 'DBIO::Storage::DateTimeFormat';

# sanity: the module really is unloadable in this process
ok !eval { require DateTime::Format::Strptime; 1 },
  'DateTime::Format::Strptime is hidden for this test';

{
  package My::Optional::Format;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%dT%H:%M:%S');
}

{
  package My::Optional::Bare;
  use base 'DBIO::Storage::DateTimeFormat';
}

# (b) invoking the datetime path throws the clear error naming the missing
#     module (and pointing at the fix) rather than a bare
#     "Can't locate DateTime/Format/Strptime.pm"
throws_ok { My::Optional::Format->parse_datetime('2026-06-12T13:37:42') }
  qr/needs DateTime::Format::Strptime to parse\/format datetimes.*Install DateTime::Format::Strptime/s,
  'parse_datetime throws a clear, actionable error naming the missing module';

throws_ok { My::Optional::Format->format_datetime('whatever') }
  qr/needs DateTime::Format::Strptime to parse\/format datetimes.*Install DateTime::Format::Strptime/s,
  'format_datetime throws the same clear error';

# the missing-pattern guard fires before Strptime is ever needed, so a
# misconfigured subclass still gets its own diagnostic even absent the module
throws_ok { My::Optional::Bare->parse_datetime('x') }
  qr/defines no datetime_parse_pattern/,
  'missing-pattern guard does not require DateTime::Format::Strptime';

done_testing;
