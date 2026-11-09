use strict;
use warnings;

use Test::More;
use mro;

# The stacked declaration form, driver side (karr k55):
#
#   package MyApp::Schema;
#   use base qw( DBIO::PostgreSQL DBIO::PostgreSQL::Age DBIO::Schema );
#
# Seven test files across dbio-postgresql-age and dbio-postgresql-postgis
# declare their schemas this way, so it is a real contract of THIS component --
# but until now it was tested only in those repos. An @ISA change to
# DBIO::PostgreSQL made here would ship green and break downstream. This file
# is the missing local half; it is documented in DBIO::PostgreSQL under
# "=head2 Connecting".
#
# OFFLINE: pure class/linearisation assertions. No DBI, no DSN, no server, and
# no dependency on either extension distribution -- the extension component is
# synthesised here in the shape the real ones have (a plain component on
# DBIO::Base, which is what all four extension components in the family carry
# since dbio-postgresql-age karr k9).
#
# METHOD, and why it is not the obvious one: `use base` does NOT compute the C3
# linearisation. A bare `eval "package T; use base qw(...); 1"` therefore
# reports success even for a stack that can never resolve -- that false green
# has already misled two agents in the dbio-postgresql-age k8 postmortem. Every
# check below forces the merge through mro::get_linear_isa($pkg, 'c3'), which
# is where an unsatisfiable hierarchy actually dies. The last block asserts
# that difference directly, so a future rewrite cannot quietly regress to the
# weaker probe.

use DBIO::Test;
use DBIO::PostgreSQL;
use DBIO::Schema;

# --- the synthetic extension component: same shape as the real ones ----------
{
  package T::Stack::Ext;
  use base 'DBIO::Base';
}

ok !T::Stack::Ext->isa('DBIO::PostgreSQL'),
  'precondition: the extension component does NOT inherit the driver component';

# Builds $pkg with the given bases and forces the C3 merge. Returns the
# linearisation as an arrayref, or dies -- which is the point.
sub linearise {
  my ($pkg, @bases) = @_;
  eval "package $pkg; use base qw( @bases ); 1"
    or die "use base failed for $pkg: $@";
  return mro::get_linear_isa($pkg, 'c3');
}

# --- 1. both stacking orders linearise --------------------------------------

my $forward = eval { linearise('T::Stack::Forward',
  qw( DBIO::PostgreSQL T::Stack::Ext DBIO::Schema )) };
ok $forward, 'driver-first stacking linearises: DBIO::PostgreSQL, ext, DBIO::Schema'
  or diag "died: $@";

my $reverse = eval { linearise('T::Stack::Reverse',
  qw( T::Stack::Ext DBIO::PostgreSQL DBIO::Schema )) };
ok $reverse, 'extension-first stacking linearises: ext, DBIO::PostgreSQL, DBIO::Schema'
  or diag "died: $@";

# The order between driver and extension is free, so the two linearisations are
# genuinely different sequences -- not the same list reached twice. Asserting
# that is what makes "the order is free" a claim rather than a coincidence.
SKIP: {
  skip 'a stacking order failed to linearise', 3 unless $forward && $reverse;

  for my $case ([ 'driver-first', $forward ], [ 'extension-first', $reverse ]) {
    my ($name, $lin) = @$case;
    my %seen = map { $_ => 1 } @$lin;
    ok $seen{'DBIO::PostgreSQL'} && $seen{'T::Stack::Ext'} && $seen{'DBIO::Schema'},
      "$name linearisation contains driver, extension and DBIO::Schema";
  }

  isnt join('|', @$forward), join('|', @$reverse),
    'the two orders really are two different linearisations';
}

# DBIO::Schema is named last, and nothing in the stack may push it ahead of a
# component: a component that lands BEHIND DBIO::Schema can no longer override
# anything the schema base defines, which is the whole reason to stack at all.
SKIP: {
  skip 'driver-first stacking failed to linearise', 1 unless $forward;
  my %pos; $pos{ $forward->[$_] } = $_ for 0 .. $#$forward;
  ok $pos{'DBIO::PostgreSQL'} < $pos{'DBIO::Schema'}
     && $pos{'T::Stack::Ext'} < $pos{'DBIO::Schema'},
    'both components precede DBIO::Schema in the linearisation';
}

# --- 2. the classic form is unaffected --------------------------------------

{
  package T::Stack::Classic;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

ok( T::Stack::Classic->isa('DBIO::PostgreSQL'),
  'the classic load_components form still composes the driver component' );

# --- 3. the documented failure: an extension inheriting the driver ----------
#
# ADR 0032 section 7 (addendum 2026-08-07) / dbio-postgresql-age karr k8. This
# is not a limit of the stacked form; it is what a mis-declared extension does
# to it. Pinned here because the trap is asymmetric -- ONE order dies -- so a
# reviewer who tries the other order concludes the extension is fine.
{
  package T::Stack::BadExt;
  use base 'DBIO::PostgreSQL';
}

my $bad_forward = eval { linearise('T::Stack::BadForward',
  qw( DBIO::PostgreSQL T::Stack::BadExt DBIO::Schema )) };
my $bad_forward_err = $@;

ok !$bad_forward,
  'an extension inheriting the driver makes driver-first stacking unsatisfiable';
like $bad_forward_err, qr/Inconsistent hierarchy/,
  '... and it fails as a C3 merge conflict, not some later symptom';

my $bad_reverse = eval { linearise('T::Stack::BadReverse',
  qw( T::Stack::BadExt DBIO::PostgreSQL DBIO::Schema )) };
ok $bad_reverse,
  '... while the reverse order still linearises -- the asymmetry that hides it'
  or diag "died: $@";

# --- 4. why this file forces the merge --------------------------------------
#
# The broken stack from block 3, probed the naive way. If this ever starts
# failing, `use base` has gained an eager linearisation step and the warnings
# above (and in the POD) can be relaxed -- but until then, a probe that does
# not call get_linear_isa proves nothing.
my $naive = eval q{
  package T::Stack::NaiveProbe;
  use base qw( DBIO::PostgreSQL T::Stack::BadExt DBIO::Schema );
  1;
};
ok $naive,
  'use base alone reports success for the stack that cannot resolve (hence get_linear_isa)';

done_testing;
