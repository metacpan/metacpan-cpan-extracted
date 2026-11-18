#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec;
use FindBin;
use B ();
use Package::Stash;

# Every class of the generated type model, loaded and asked what it
# registered. The suite otherwise exercises a handful of them by name, so a
# class that failed to compile, or that declared an attribute the registry
# never heard of, would sit in lib/ unnoticed until a caller found it.
#
# Nothing here opens a socket or reaches a daemon, in either mode.

my $LIB  = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..', 'lib'));
my $ROOT = File::Spec->catdir($LIB, 'API', 'Docker', 'Type');
plan skip_all => 'no generated type model in this distribution' unless -d $ROOT;

my @classes;
find(
  { no_chdir => 1, wanted => sub {
      return unless /\.pm\z/;
      my $rel = File::Spec->abs2rel($File::Find::name, $LIB);
      $rel =~ s{\.pm\z}{};
      push @classes, join '::', File::Spec->splitdir($rel);
    } },
  $ROOT,
);
@classes = sort @classes;
cmp_ok scalar @classes, '>=', 200, 'the model is all there';

my (@failed, @empty, @bad_wire, @bad_type, @unloadable_target);
for my $class (@classes) {
  unless (eval "require $class; 1") { push @failed, "$class: $@"; next }
  my $registry = $class->docker_attributes;
  push @empty, $class unless %$registry;
  for my $name (sort keys %$registry) {
    my $info = $registry->{$name};
    push @bad_wire, "$class.$name" unless defined $info->{wire} && length $info->{wire};
    push @bad_type, "$class.$name" unless ref $info->{type} eq 'HASH' && $info->{type}{kind};
    # Every class an attribute names must exist, or the first hashref a
    # caller hands that field dies inside the coercion rather than here.
    my $target = $info->{type};
    $target = $target->{inner} while $target->{inner};
    next unless $target->{kind} eq 'object';
    push @unloadable_target, "$class.$name -> $target->{class}"
      unless eval "require $target->{class}; 1";
  }
}

is_deeply \@failed,  [], 'every class compiles';
is_deeply \@empty,   [], 'every class registered at least one attribute';
is_deeply \@bad_wire, [], 'every attribute carries a wire name';
is_deeply \@bad_type, [], 'every attribute carries a parsed type descriptor';
is_deeply \@unloadable_target, [], 'every class an attribute points at is loadable';

subtest 'the whole model round-trips an empty object' => sub {
  # TO_JSON walks the registry rather than the object, so an attribute the
  # DSL half-registered would show up here as a key with no value rather
  # than as an absent field.
  my @noisy = grep { keys %{ $_->new->TO_JSON } } @classes;
  is_deeply \@noisy, [],
    'a class with nothing set serialises to an empty structure';
};

subtest 'no generated class leaks the DSL sugar' => sub {
  # `use API::Docker::Type` imports Moo, the type vocabulary and the two DSL
  # keywords into the class so its body can be written; none of them is part
  # of the class's runtime surface, and every generated class ends its body
  # with `use namespace::clean` to strip them (karr k105). Before that line
  # was added every one of these leaked onto all 201 classes -- the same shape
  # API::Docker::Role::Type's own namespace::clean closed for the role in k82,
  # left open on the classes the role is composed onto. So this asserts the
  # absence by name, over every class, and it is red on any class that has not
  # had the cleanup applied.
  #
  # `docker`/`docker_extends` and the `Str`/`Int`/... a class body calls are
  # gone from the symbol table yet still fired at load time, because Perl
  # bound their CV into each call site at compile time; the DSL keeps `has`
  # and `extends` reachable across the same cleanup by capturing them at
  # import (see API::Docker::Type). The point of this test is the leak, not
  # the mechanism: what a caller can reach through the object is what matters,
  # and none of these should be it.
  my @sugar = qw( has with extends docker docker_extends Str Int Bool around );
  my %leaked;
  for my $class (@classes) {
    $leaked{$_}++ for grep { $class->can($_) } @sugar;
  }
  is_deeply \%leaked, {},
    'no generated class answers to a Moo keyword, a type or a DSL keyword';
};

subtest 'a generated class holds its fields and the documented roster' => sub {
  # What survives on a class once its own `use namespace::clean` has run is a
  # fixed set: everything composing API::Docker::Role::Type contributes, and
  # nothing else. The imported Moo keywords, the type vocabulary and the two
  # DSL keywords are gone -- namespace::clean strips them at the end of the
  # class's compilation, while the accessors `docker` builds and the role it
  # composes are installed at runtime, after that cleanup, and stay. The
  # subtest below asserts the stripping by name; here the surviving surface is
  # stated positively. Measured over all 201 classes it is the same 20 names
  # every time, so a generated class answers to its registry attributes plus
  # this roster, and nothing else.
  #
  # Stated that way on purpose. The assertion here used to be a list of two
  # forbidden names, croak and blessed, which leaked onto every class until
  # API::Docker::Role::Type gained its namespace::clean (karr k82). Half of
  # it went vacuous the moment the blessed import was dropped from that role
  # (karr k87): the name could no longer arrive, so forbidding it proved
  # nothing, and nobody could tell by reading it. A roster cannot go vacuous
  # -- it fails on a name that appears and on one that disappears -- and it
  # names the leak without anyone having thought of it first.
  #
  # It is a name roster rather than a check on where each sub was compiled
  # because a name is what collides: these classes are generated from a
  # specification that grows fields without asking, and a field the swagger
  # one day spells `Has` or `New` would quietly take the place of what is
  # here.
  #
  # This holds while nothing under lib/API/Docker/Type/ pulls in an entity
  # role -- API::Docker::Role::Entity::* attaches itself to its classes when
  # the ROLE is loaded, and this file loads only the model. A class that
  # gained ->start or ->remove that way would be reported here by name; that
  # is a deliberate change to the surface and belongs in the roster.
  my @roster = (
    # what composing API::Docker::Role::Type leaves behind: its two
    # attributes, all of its methods -- the private ones included, Role::Tiny
    # composes every sub the role has -- and the new, BUILDARGS and DOES that
    # the composition itself generates. The imported Moo sugar (has, with,
    # extends, around, before, after), the type vocabulary (Any, Bool, Int,
    # Num, Str) and the two DSL keywords (docker, docker_extends) are not on
    # this list: `use namespace::clean` in each class removes them, and the
    # 'no generated class leaks the DSL sugar' subtest below holds that.
    qw( new BUILDARGS DOES
        unknown_fields rejected_fields
        from_data from_json TO_JSON to_json
        docker_attributes docker_attribute_order
        _fits _entity_attribute_index
        _docker_attr_registry _merge_registry
        _docker_attr_order _merge_order _append_order
        _docker_wire_index _invalidate_docker_cache ),
  );
  my %roster = map { ($_ => 1) } @roster;

  # Counted by name rather than collected per class: a leak out of the role
  # or the DSL is on all 201 at once, and `{ croak => 201 }` says that in one
  # line where 201 strings would bury it.
  my (%extra, %absent);
  for my $class (@classes) {
    my $fields = $class->docker_attributes;
    my %have = map { ($_ => 1) }
      Package::Stash->new($class)->list_all_symbols('CODE');
    $extra{$_}++  for grep { !$fields->{$_} && !$roster{$_} } keys %have;
    $absent{$_}++ for grep { !$have{$_} } @roster;
  }
  is_deeply \%extra, {},
    'no generated class answers to a name outside its fields and the roster';
  is_deeply \%absent, {},
    'every generated class answers to the whole roster';
};

subtest 'the DSL package holds nothing it did not compile itself' => sub {
  # API::Docker::Type is imported from, never composed or inherited, so
  # nothing it holds reaches the generated classes -- but it is still a
  # namespace that should be its own subs and no one else's. Without
  # `use namespace::clean` after its imports it answers to ->blessed,
  # ->croak, ->use_module and the nine Types::Standard names (karr k89).
  #
  # Asked as an origin and not as a list of names it must not have, for the
  # reason the subtest above exists: a forbidden name stops proving anything
  # the day the import behind it is dropped, and says so to nobody. Every sub
  # Perl compiled in this file reports API::Docker::Type as its stash; an
  # imported one reports where it was written. That stays true through a
  # rename, a new helper and an import nobody has thought of yet.
  require API::Docker::Type;
  my $stash = Package::Stash->new('API::Docker::Type');
  my @subs  = sort $stash->list_all_symbols('CODE');
  my @foreign;
  for my $name (@subs) {
    my $gv = B::svref_2object($stash->get_symbol("&$name"))->GV;
    my $from = ref($gv) eq 'B::SPECIAL' ? '(unknown)' : $gv->STASH->NAME;
    push @foreign, "$name (compiled in $from)"
      unless $from eq 'API::Docker::Type';
  }
  is_deeply \@foreign, [], 'every sub in API::Docker::Type was written there';
  # So that an empty or renamed package cannot pass the assertion above by
  # having nothing to check. The DSL has 13 subs; the bound is loose because
  # the count is not the claim.
  cmp_ok scalar @subs, '>=', 10, 'and there were subs there to check';
};

done_testing;
