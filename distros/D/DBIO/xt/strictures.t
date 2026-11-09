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

# Test::Strict decides from the source text: a file passes when it names a
# module known to switch strict/warnings on in its caller. DBIO's own sugar
# does that from import() -- `use DBIO 'Role'`, DBIO::Cake, DBIO::Candy,
# DBIO::Moo, DBIO::Moose -- but only the CPAN ones are on Test::Strict's list,
# so name ours as well.
#
# DBIO::Moo and DBIO::Moose need their own strict->import / warnings->import:
# they run `use Moo` / `use Moose` inside a string eval, which switches
# strictures on for that eval only, never for the file that said
# `use DBIO::Moo`.
my @dbio_strictures = qw( DBIO DBIO::Cake DBIO::Candy DBIO::Moo DBIO::Moose );

# What a probe below has to load before it can `use` the module at all.
my %probe_needs = (
  'DBIO::Moo'   => [qw( Moo )],
  'DBIO::Moose' => [qw( Moose MooseX::NonMoose )],
);

{
  no warnings 'once';  # Test::Strict is loaded at runtime, by req_ok_for
  push @Test::Strict::MODULES_ENABLING_STRICT,   @dbio_strictures;
  push @Test::Strict::MODULES_ENABLING_WARNINGS, @dbio_strictures;
}

# The list above is a claim about those modules, so check it instead of
# trusting it: if one of them stops enabling strictures, every file relying
# on it would pass above while no longer being strict.
for my $mod (@dbio_strictures) {
  if (my @missing = grep { ! eval "require $_; 1" } @{ $probe_needs{$mod} || [] }) {  ## no critic
    SKIP: { skip "probing $mod needs @missing", 2 }
    next;
  }
  (my $tag = $mod) =~ s/::/_/g;
  my ($strict, $warnings);
  eval qq{
    no strict; no warnings;
    package DBIO::XT::StricturesProbe::$tag;
    use $mod;
    BEGIN {
      my \$sbits = strict::bits(qw(refs subs vars));
      \$strict   = ( \$^H & \$sbits ) == \$sbits;
      # core categories only: warnings::register grows 'all' later on
      my \$wbits = substr( \$warnings::Bits{all}, 0, \$warnings::BYTES );
      \$warnings = ( ( \${^WARNING_BITS} // '' ) & \$wbits ) eq \$wbits;
    }
    1;
  } or die "Probing '$mod' for strictures failed: $@";
  ok( $strict,   "use $mod enables strict in the calling file" );
  ok( $warnings, "use $mod enables warnings in the calling file" );
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
        |
      t/lib/MigrationsTest/Util/OverrideRequire.pm     # same, the bare original (was t/lib/DBICTest/...)
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
