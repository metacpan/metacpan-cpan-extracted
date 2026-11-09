use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use DBIO::Generate;

# Sample the L</new> behavior that k178 lands on: every key in %args that
# has a matching accessor (see mk_group_accessors in DBIO::Generate) is
# assigned, including keys that were already handled by the explicit
# assignment block above the loop. The previous code asked a broken
# overridden() helper to skip such keys; the helper always returned undef
# so the assignment was always performed. Removing the helper (this
# commit) keeps the observable behavior and removes the dead check.

my $tmpdir = tempdir(CLEANUP => 1);

# Build with a value for every accessor that new() handles explicitly,
# plus a few that only the loop would reach. Each accessor must round-trip
# the value we handed in.
my $gen = DBIO::Generate->new(
  dump_directory        => $tmpdir,
  result_base_class     => 'My::Core',
  use_namespaces        => 0,
  generate_pod          => 1,
  style                 => 'vanilla',
  moniker_parts         => ['name', 'kind'],
  moniker_part_separator => '_',
  allow_extra_m2m_cols  => 1,
  quiet                 => 1,
);

is $gen->dump_directory,        $tmpdir,             'dump_directory round-trip';
is $gen->result_base_class,     'My::Core',          'result_base_class round-trip';
is $gen->use_namespaces,        0,                   'use_namespaces round-trip (falsy)';
is $gen->generate_pod,          1,                   'generate_pod round-trip (truthy)';
is $gen->style,                 'vanilla',           'style round-trip';
is_deeply $gen->moniker_parts, ['name', 'kind'],    'moniker_parts round-trip';
is $gen->moniker_part_separator, '_',                'moniker_part_separator round-trip';
is $gen->allow_extra_m2m_cols,  1,                   'allow_extra_m2m_cols round-trip (truthy)';
is $gen->quiet,                 1,                   'quiet round-trip (truthy)';

# A non-accessor key in %args is silently ignored; the constructor must
# not die, must not assign it, and must still return a usable object.
my $gen2 = DBIO::Generate->new(
  dump_directory => $tmpdir,
  style          => 'vanilla',
  not_an_accessor => 'ignored',
);
is $gen2->dump_directory, $tmpdir, 'non-accessor key ignored, object usable';
ok !$gen2->can('not_an_accessor'), 'no accessor was created for the unknown key';

# The object must be a real DBIO::Generate regardless of how mixed the
# args are.
isa_ok $gen, 'DBIO::Generate';
isa_ok $gen2, 'DBIO::Generate';

done_testing;
