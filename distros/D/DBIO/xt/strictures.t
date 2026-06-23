use warnings;
use strict;

use Test::More;
use File::Find;
use File::Spec;
use Config;

require DBIO;
unless ( DBIO::Optional::Dependencies->req_ok_for ('test_strictures') ) {
  my $missing = DBIO::Optional::Dependencies->req_missing_for ('test_strictures');
  $ENV{RELEASE_TESTING}
    ? die ("Failed to load release-testing module requirements: $missing")
    : plan skip_all => "Test needs: $missing"
}

use File::Find;

# The rationale is - if we can load all our optdeps
# that are related to lib/ - then we should be able to run
# perl -c checks (via syntax_ok), and all should just work
my $missing_groupdeps_present = grep
  { ! DBIO::Optional::Dependencies->req_ok_for($_) }
  grep
    { $_ !~ /^ (?: test | rdbms | dist ) _ /x }
    keys %{DBIO::Optional::Dependencies->req_group_list}
;

# don't test syntax when RT#106935 is triggered (mainly CI)
# FIXME - remove when RT is resolved
my $tainted_relpath = (
  length $ENV{PATH}
    and
  ${^TAINT}
    and
  grep
    { ! File::Spec->file_name_is_absolute($_) }
    split /\Q$Config{path_sep}/, $ENV{PATH}
) ? 1 : 0;

find({
  wanted => sub {
    -f $_ or return;
    m/\.(?: pm | pl | t )$ /ix or return;

    return if m{^(?:
      lib/DBIO/Test/Util/OverrideRequire.pm            # no strictures by design (load order sensitive)
    )$}x;

    my $f = $_;

    Test::Strict::strict_ok($f);
    Test::Strict::warnings_ok($f);

    Test::Strict::syntax_ok($f) if (
      ! $tainted_relpath
        and
      ! $missing_groupdeps_present
        and
      $f =~ /^ (?: lib  )/x
    );
  },
  no_chdir => 1,
}, (qw(lib t examples)) );

done_testing;
