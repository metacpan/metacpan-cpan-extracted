# Use a require override instead of @INC munging (less common)
# Do the override as early as possible so that CORE::require doesn't get compiled away

use Test::More;
BEGIN { plan skip_all => 'Lean startup test needs to be rewritten for DBIO dependency changes' }

my ($initial_inc_contents, $expected_dbic_deps, $require_sites);
BEGIN {
  # these envvars *will* bring in more stuff than the baseline
  delete @ENV{qw(
    DBIO_TEST_SWAPOUT_SQLAC_WITH
    DBIO_TEST_SQLT_DEPLOY
    DBIO_TRACE
  )};

  # make sure extras do not load even when this is set
  $ENV{PERL_STRICTURES_EXTRA} = 1;

  unshift @INC, 't/lib';
  require DBIO::Test::Util::OverrideRequire;

  DBIO::Test::Util::OverrideRequire::override_global_require( sub {
    my $res = $_[0]->();

    my $req = $_[1];
    $req =~ s/\.pm$//;
    $req =~ s/\//::/g;

    my $up = 0;
    my @caller;
    do { @caller = caller($up++) } while (
      @caller and (
        # exclude our test suite, known "module require-rs" and eval frames
        $caller[1] =~ /^ t [\/\\] /x
          or
        $caller[0] =~ /^ (?: base | parent | Class::C3::Componentised | Module::Inspector | Module::Runtime ) $/x && $caller[3] !~ m/::BEGIN$/
          or
        $caller[3] eq '(eval)',
      )
    );

    push @{$require_sites->{$req}}, "$caller[1] line $caller[2]"
      if @caller;

    return $res if $req =~ /^DBIO|^DBIO::Test::/;

    # exclude everything where the current namespace does not match the called function
    # (this works around very weird XS-induced require callstack corruption)
    if (
      !$initial_inc_contents->{$req}
        and
      !$expected_dbic_deps->{$req}
        and
      @caller
        and
      $caller[0] =~ /^DBIO/
        and
      (caller($up))[3] =~ /\Q$caller[0]/
    ) {
      CORE::require('Test/More.pm');
      Test::More::fail ("Unexpected require of '$req' by $caller[0] ($caller[1] line $caller[2])");

      if ( $ENV{TEST_VERBOSE} or ! $ENV{DBIO_PLAIN_INSTALL} ) {
        CORE::require('DBIO/Test/Util.pm');
        Test::More::diag( 'Require invoked' .  DBIO::Test::Util::stacktrace() );
      }
    }

    return $res;
  });
}

use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'A defined PERL5OPT may inject extra deps crashing this test'
    if $ENV{PERL5OPT};

  plan skip_all => 'Dependency load patterns are radically different before perl 5.10'
    if "$]" < 5.010;

  # these envvars *will* bring in more stuff than the baseline
  delete @ENV{qw(
    DBIO_TRACE
    DBIO_SHUFFLE_UNORDERED_RESULTSETS
    DBIO_TEST_SQLT_DEPLOY
    DBIO_TEST_SQLITE_REVERSE_DEFAULT_ORDER
    DBIO_TEST_VIA_REPLICATED
    DBIO_TEST_DEBUG_CONCURRENCY_LOCKS
  )};

  $ENV{DBIO_TEST_ANFANG_DEFANG} = 1;

  # make sure extras do not load even when this is set
  $ENV{PERL_STRICTURES_EXTRA} = 1;

  # add what we loaded so far
  for (keys %INC) {
    my $mod = $_;
    $mod =~ s/\.pm$//;
    $mod =~ s!\/!::!g;
    $initial_inc_contents->{$mod} = 1;
  }
}

BEGIN {
  delete $ENV{$_} for qw(
    DBIO_TEST_DEBUG_CONCURRENCY_LOCKS
  );
}

#######
### This is where the test starts
#######

# checking base schema load, no storage no connection
{
  register_lazy_loadable_requires(qw(
    B
    constant
    overload

    base
    Devel::GlobalDestruction
    mro

    Carp
    namespace::clean
    Try::Tiny
    Sub::Name
    Sub::Defer
    Sub::Quote

    Hash::Merge
    Scalar::Util
    Storable

    Class::Accessor::Grouped
    Class::C3::Componentised
    SQL::Abstract::Util
  ));

  require DBIO::Test::Schema;
  assert_no_missing_expected_requires();
}

# check schema/storage instantiation with no connect
{
  register_lazy_loadable_requires(qw(
    Context::Preserve
  ));

  my $s = DBIO::Test::Schema->clone;
  $s->storage_type('DBIO::Test::Storage');
  $s = $s->connect(sub {});
  ok (! $s->storage->_fake_connected, 'no connection');
  $s->storage->_fake_connected(0);
  assert_no_missing_expected_requires();
}

# Real DB operations (deploy, insert, populate) moved to DBIO::SQLite test suite

done_testing;

sub register_lazy_loadable_requires {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  for my $mod (@_) {
    (my $modfn = "$mod.pm") =~ s!::!\/!g;
    fail(join "\n",
      "Module $mod already loaded by require site(s):",
      (map { "\t$_" } @{$require_sites->{$mod}}),
      '',
    ) if $INC{$modfn} and !$initial_inc_contents->{$mod};

    $expected_dbic_deps->{$mod}++
  }
}

# check if anything we were expecting didn't actually load
sub assert_no_missing_expected_requires {
  my $nl;
  for my $mod (keys %$expected_dbic_deps) {
    (my $modfn = "$mod.pm") =~ s/::/\//g;
    unless ($INC{$modfn}) {
      my $err = sprintf "Expected DBIO core dependency '%s' never loaded - %s needs adjustment", $mod, __FILE__;
      if ($ENV{DBIO_CI} or $ENV{AUTHOR_TESTING}) {
        fail ($err)
      }
      else {
        diag "\n" unless $nl->{$mod}++;
        diag $err;
      }
    }
  }
  pass(sprintf 'All modules expected at %s line %s loaded by DBIO: %s',
    __FILE__,
    (caller(0))[2],
    join (', ', sort keys %$expected_dbic_deps ),
  ) unless $nl;
}
