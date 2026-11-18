#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Module::Runtime qw( require_module );
use API::Docker;

# The seven entity classes k84 replaced with the generated type model still
# ship, as stubs that refuse (karr k92). A module that disappears from a
# distribution does not disappear from the disks it was installed on -- the
# old file stays behind and keeps loading -- so the stub is what an upgrade
# overwrites the working copy with. Deleting the file leaves that copy in
# place; this is the same shadowing k91 measured from the other side.
#
# There is deliberately NO use_ok here, and none in t/basic.t either. These
# modules are not required to load: loading one is the failure the stub
# exists to produce, so asserting that it succeeds would assert the wrong
# thing. What is asserted instead is that the refusal HAPPENS and what it
# says.
#
# That shape also makes the test self-guarding against the very substitution
# k91 found. An installed copy (a local::lib under ~/perl5, a site dir) may
# hold the working pre-stub versions of all seven; if @INC ever resolved one of these names there
# instead of to this checkout's lib/, the require would SUCCEED and every
# subtest below would go red rather than quietly passing.
#
# Nothing here reaches a daemon or the network.

my @STUBS = (
  {
    package  => 'API::Docker::Container',
    replaces => [
      'API::Docker::Type::ContainerSummary',
      'API::Docker::Type::ContainerInspectResponse',
    ],
    role     => 'API::Docker::Role::Entity::Container',
  },
  {
    package  => 'API::Docker::Image',
    replaces => [
      'API::Docker::Type::ImageSummary',
      'API::Docker::Type::ImageInspect',
    ],
    role     => 'API::Docker::Role::Entity::Image',
  },
  {
    package  => 'API::Docker::Network',
    replaces => ['API::Docker::Type::Network'],
    role     => 'API::Docker::Role::Entity::Network',
  },
  {
    package  => 'API::Docker::Volume',
    replaces => ['API::Docker::Type::Volume'],
    role     => 'API::Docker::Role::Entity::Volume',
  },
  {
    package  => 'API::Docker::Plugin',
    replaces => ['API::Docker::Type::Plugin'],
    role     => 'API::Docker::Role::Entity::Plugin',
  },
  {
    package  => 'API::Docker::Secret',
    replaces => ['API::Docker::Type::Secret'],
    role     => 'API::Docker::Role::Entity::Secret',
  },
  {
    package  => 'API::Docker::Config',
    replaces => ['API::Docker::Type::Config'],
    role     => 'API::Docker::Role::Entity::Config',
  },
);

for my $stub (@STUBS) {
  my $package = $stub->{package};

  subtest $package => sub {

    # 1. Loading refuses, and the refusal is the stub's own, not a syntax
    #    error and not a "can't locate" -- the message has to identify it.
    my $loaded = eval { require_module($package); 1 };
    my $at_load = $@;

    ok(!$loaded, $package . ' refuses to load')
      or diag('it loaded -- either the stub works, which it must not, or '
        . '@INC resolved this name outside the checkout, which is what '
        . 't/dist_source.t exists to name');

    # 2. The refusal has to be unmistakable: a reader must come away knowing
    #    they hit a left-behind module and where to reach instead, not that
    #    they found a fault in the distribution.
    like($at_load, qr/\Q$package\E was removed in API::Docker/,
      'names itself and says it was removed');
    like($at_load, qr/\QYou have not hit a fault in the distribution\E/,
      'says it is not a fault in the distribution');
    like($at_load, qr/\Qoverwrites the working copy an earlier one left on disk\E/,
      'says why the file still ships at all');

    like($at_load, qr/\Q$_\E/, 'names ' . $_ . ' as the replacement')
      for @{ $stub->{replaces} };
    like($at_load, qr/\Q$stub->{role}\E/,
      'names ' . $stub->{role} . ' for the convenience methods');

    # 3. The classes the message points at have to be real. Without this the
    #    message is prose that can rot: rename a generated class and the
    #    stub keeps confidently naming the old one.
    ok(eval { require_module($_); 1 }, $_ . ' is loadable')
      or diag($@)
      for @{ $stub->{replaces} }, $stub->{role};

    # 4. A caller who swallowed the load error and called a convenience
    #    method anyway gets the same answer, not a bare "Can't locate object
    #    method". `remove` exists on all seven roles; `start` on none but
    #    Container's -- both have to refuse identically, since the stub
    #    holds no methods at all.
    for my $method (qw( new remove start )) {
      eval { $package->$method };
      like($@, qr/\Q$package\E was removed in API::Docker/,
        '->' . $method . ' refuses with the same message');
    }

    # 5. Rule 11: the same $VERSION literal as the rest of lib/. It is set
    #    before the croak on purpose, so a failed load still leaves it
    #    readable -- and BumpVersionAfterRelease rewrites the first
    #    `our $VERSION` in a file whether that line ever runs or not.
    no strict 'refs';
    is(${ $package . '::VERSION' }, $API::Docker::VERSION,
      'carries the same $VERSION as API::Docker');
  };
}

done_testing;
