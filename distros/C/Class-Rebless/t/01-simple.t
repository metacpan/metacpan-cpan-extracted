#!/usr/bin/env perl -w
use strict;

use Test::More;
use Data::Dumper;
use Scalar::Util qw(blessed);

unless (eval "use Test::NoWarnings; 1") {
  diag 'Please consider installing Test::NoWarnings for an additional test';
}

#################### prepare some subs

# object is "in sin", that is, not blessed.
sub in_sin($;$) {
  my ($obj, $comment) = @_;
  my $t = Test::More->builder;
  $t->ok(! blessed($obj), $comment);
}

sub create_beat {
  open my $fh, "<", "Makefile.PL" or die "Could not open Makefile.PL for testing";
  return bless({
            one => bless({
                    hey => 'ho',
                  }, 'AOne'),
            two => bless({
                    list => [
                      bless({ three => 3 }, 'AThree'),
                      bless({ four  => 4 }, 'AFour'),
                      5,
                     "this is just noise",
                    ],
                  }, 'ATwo'),
            six => {
              seven => bless({ __VALUE__ => 7}, 'ASeven'),
              eight => bless({ __VALUE__ => 8}, 'AnEight'),
            },
            func => sub { 100; },
            funcy => bless(sub { 42; }, 'AFunc'),
            deep => bless({
                      deeper => bless({
                                  deepest => bless({ field => "value" }, "Deepest"),
                      }, "Deeper"),
            }, "Deep"),
            #fh => bless $fh, "FileHandler",
            none => undef,
         }, 'AOne');
}


################################## Now let's start the tests

require_ok 'Class::Rebless';

{
  # rebase simple HASH
  my $empty = {};
  Class::Rebless->rebase($empty, 'Full');
  ok   ! UNIVERSAL::isa($empty, 'Full'), 'rebasing HASH does not do anything';

  # rebase simple HASH based class
  $empty = bless({}, 'Empty');
  isa_ok $empty, 'Empty', 'Before rebasing Empty';
  Class::Rebless->rebase($empty, 'Not');
  isa_ok $empty, 'Not::Empty', 'After rebasing Empty';
}

# rebasing nonblessed scalar reference
{
  my $foo = "bar";
  my $moo = \$foo;
  is     $foo, "bar";
  isa_ok $moo, "SCALAR";
  in_sin $moo;
  is     $$moo, "bar";

  Class::Rebless->rebase($moo, "And");
  isa_ok $moo, "SCALAR";
  in_sin $moo;
  is     $$moo, "bar";

  Class::Rebless->rebless($moo, "Else");
  isa_ok $moo, "SCALAR";
  in_sin $moo;
  is     $$moo, "bar";
}

# rebasing and reblessing blessed scalar reference
{
  my $foo = "Foo";
  my $moo = bless \$foo, "Foo";
  isa_ok $moo, "SCALAR";
  isa_ok $moo, "Foo";
  #is     $$moo, "bar"; #TODO

  Class::Rebless->rebase($moo, "And");
  isa_ok $moo, "SCALAR";
  isa_ok $moo, "And::Foo";
  #is     $$moo, "bar"; #TODO

  Class::Rebless->rebless($moo, "Else");
  isa_ok $moo, "SCALAR";
  isa_ok $moo, "Else";
  #is     $$moo, "bar"; #TODO
}

{
  open my $fh, "<", "Makefile.PL" or die;
  bless $fh, "FileHandler";
  isa_ok $fh, "GLOB";
  isa_ok $fh, "FileHandler";

  eval{Class::Rebless->rebase($fh, "And");};
  ok !$@, "rebase on filehandles lives";
  diag $@ if $@;

  isa_ok $fh, "GLOB";
  isa_ok $fh, "And::FileHandler";

  eval{Class::Rebless->rebless($fh, "NewFileHandler");};
  ok !$@, "rebless on filehandles lives";
  diag $@ if $@;

  isa_ok $fh, "GLOB";
  isa_ok $fh, "NewFileHandler";
}

{
  no strict;
  $foo = 42;
  @foo = (19, 23);
  %foo = (field => "value");
  my $bar = \*foo;
  bless $bar, "Bar";
  isa_ok $bar, "GLOB";
  isa_ok $bar, "Bar";
  is_deeply \@$$bar, [19, 23];
  is_deeply \%$$bar, {field => "value"};
  is $$$bar, 42, "sanity, got back 42 from GLOB";

  Class::Rebless->rebase($bar, 'And');

  isa_ok $bar, "GLOB";
  isa_ok $bar, "And::Bar";
  is $$$bar, 42, "got back 42 from GLOB";
  is_deeply \@$$bar, [19, 23];
  is_deeply \%$$bar, {field => "value"};
}


{
  my $beat = create_beat();

  # before changing
  isa_ok $beat, "AOne";
  isa_ok $beat->{one}, "AOne";
  isa_ok $beat->{two}, "ATwo";
  isa_ok $beat->{func}, "CODE";
  in_sin $beat->{func};
  isa_ok $beat->{funcy}, "CODE";
  isa_ok $beat->{funcy}, "AFunc";
  is     $beat->{func}->(), 100, "hundred";
  is     $beat->{funcy}->(), 42, "the answer";

  isa_ok $beat->{deep}, "HASH";
  isa_ok $beat->{deep}, "Deep";
  isa_ok $beat->{deep}{deeper}, "HASH";
  isa_ok $beat->{deep}{deeper}, "Deeper";
  isa_ok $beat->{deep}{deeper}{deepest}, "HASH";
  isa_ok $beat->{deep}{deeper}{deepest}, "Deepest";
  is     $beat->{deep}{deeper}{deepest}{field}, "value";
  in_sin $beat->{deep}{deeper}{deepest}{field};

  #isa_ok $beat->{fh}, "GLOB";
  #isa_ok $beat->{fh}, "FileHandler";
  #diag Dumper $beat;

  Class::Rebless->rebase($beat, 'And');
  #diag Dumper $beat;
  isa_ok $beat, "And::AOne";
  isa_ok $beat->{one}, "And::AOne";
  isa_ok $beat->{two}, "And::ATwo";
  in_sin $beat->{two}{list}, "two-list not blessed";

  isa_ok $beat->{two}{list}[0], "And::AThree";
  isa_ok $beat->{two}{list}[1], "And::AFour";
  in_sin $beat->{two}{list}[2], "two list 2 is not blessed";
  in_sin $beat->{two}{list}[3], "two list 3 is not blessed";

  in_sin $beat->{six}, "six is not blessed";

  isa_ok $beat->{six}{seven}, "And::ASeven";
  isa_ok $beat->{six}{eight}, "And::AnEight";

  in_sin $beat->{func};
  isa_ok $beat->{funcy}, "And::AFunc";

  isa_ok $beat->{deep}, "And::Deep";
  isa_ok $beat->{deep}{deeper}, "And::Deeper";
  isa_ok $beat->{deep}{deeper}{deepest}, "And::Deepest";
  in_sin $beat->{deep}{deeper}{deepest}{field};

  is_deeply($beat, create_beat(), "structure is the same");
}

# rebless complex structure
{
  my $beat = create_beat();

  Class::Rebless->rebless($beat, 'Beatless');
  #diag Dumper $beat;
  isa_ok $beat, "Beatless";
  isa_ok $beat->{one}, "Beatless";
  isa_ok $beat->{two}, "Beatless";
  in_sin $beat->{two}{list}, "two-list not blessed";

  isa_ok $beat->{two}{list}[0], "Beatless";
  isa_ok $beat->{two}{list}[1], "Beatless";
  in_sin $beat->{two}{list}[2], "two list 2 is not blessed";
  in_sin $beat->{two}{list}[3], "two list 3 is not blessed";

  in_sin $beat->{six}, "six is not blessed";

  isa_ok $beat->{six}{seven}, "Beatless";
  isa_ok $beat->{six}{eight}, "Beatless";

  in_sin $beat->{func};
  isa_ok $beat->{funcy}, "Beatless";

  isa_ok $beat->{deep}, "Beatless";
  isa_ok $beat->{deep}{deeper}, "Beatless";
  isa_ok $beat->{deep}{deeper}{deepest}, "Beatless";
  in_sin $beat->{deep}{deeper}{deepest}{field};

  is_deeply($beat, create_beat(), "structure is the same");
}

{
  my $beat = create_beat();

  Class::Rebless->custom($beat, 'Custom', { editor => \&my_custom_editor });

  isa_ok $beat, "Custom::AOne";
  isa_ok $beat->{one}, "Custom::AOne";
  isa_ok $beat->{two}, "Custom::ATwo";
  in_sin $beat->{two}{list}, "two-list not blessed";

  isa_ok $beat->{two}{list}[0], "Custom::Three3::AThree";
  isa_ok $beat->{two}{list}[1], "Custom::Four4::AFour";
  in_sin $beat->{two}{list}[2], "two list 2 is not blessed";
  in_sin $beat->{two}{list}[3], "two list 3 is not blessed";

  in_sin $beat->{six}, "six is not blessed";

  isa_ok $beat->{six}{seven}, "Custom";
  isa_ok $beat->{six}{eight}, "Custom::AnEight";

  in_sin $beat->{func};
  isa_ok $beat->{funcy}, "Custom::AFunc";

  isa_ok $beat->{deep}, "Deep"; # PRUNELESS
  isa_ok $beat->{deep}{deeper}, "Custom::Deeper";
  isa_ok $beat->{deep}{deeper}{deepest}, "Custom::Deepest";
  in_sin $beat->{deep}{deeper}{deepest}{field};

  is_deeply($beat, create_beat(), "structure is the same");
}

{
  my $beat = create_beat();

  ok !Class::Rebless->prune(), "no prune yet";
  Class::Rebless->prune("__MYPRUNE__");
  is Class::Rebless->prune(), "__MYPRUNE__", "we have prune now";
  Class::Rebless->custom($beat, 'Custom', { editor => \&my_custom_editor });

  isa_ok $beat, "Custom::AOne";
  isa_ok $beat->{one}, "Custom::AOne";
  isa_ok $beat->{two}, "Custom::ATwo";
  in_sin $beat->{two}{list}, "two-list not blessed";

  isa_ok $beat->{two}{list}[0], "Custom::Three3::AThree";
  isa_ok $beat->{two}{list}[1], "Custom::Four4::AFour";
  in_sin $beat->{two}{list}[2], "two list 2 is not blessed";
  in_sin $beat->{two}{list}[3], "two list 3 is not blessed";

  in_sin $beat->{six}, "six is not blessed";

  isa_ok $beat->{six}{seven}, "Custom";
  isa_ok $beat->{six}{eight}, "Custom::AnEight";

  in_sin $beat->{func};
  isa_ok $beat->{funcy}, "Custom::AFunc";

  # difference from previous because of prune:
  isa_ok $beat->{deep}, "Deep";
  isa_ok $beat->{deep}{deeper}, "Deeper";
  isa_ok $beat->{deep}{deeper}{deepest}, "Deepest";
  in_sin $beat->{deep}{deeper}{deepest}{field};

  is_deeply($beat, create_beat(), "structure is the same");
}

{
  my $structure = [ 1, [ 2, [ 3, ] ] ];

  {
    local $Class::Rebless::MAX_RECURSE = 3;
    local $@;
    my $ok = eval { Class::Rebless->rebless($structure, 'Bogus'); 1 };
    ok($ok, "we can recurse up to MAX_RECURSE times") or diag "error: $@";
  }

  {
    local $Class::Rebless::MAX_RECURSE = 2;
    local $@;
    my $ok = eval { Class::Rebless->rebless($structure, 'Bogus'); 1 };
    like $@, qr/maximum recursion level exceeded/, "...but no more";
  }
}

{
  my $obj_1 = bless {} => 'X';
  my $obj_2 = bless {} => 'X';

  $obj_1->{obj_2} = $obj_2;
  $obj_2->{obj_1} = $obj_1;

  Class::Rebless->rebless($obj_1, 'Foo');
}

# in an END{} because there's a previously-registered END{} for
# Test::NoWarnings, potentially -- rjbs, 2011-03-21
END { done_testing; }

sub my_custom_editor {
  my ($obj, $namespace) = @_;
  return bless $obj, $namespace . '::Three3::' . ref $obj if "AThree" eq ref $obj;
  return bless $obj, $namespace . '::Four4::' . ref $obj if "AFour" eq ref $obj;
  return bless $obj, $namespace if "ASeven" eq ref $obj;
  return "__MYPRUNE__" if "Deep" eq ref $obj;
  return bless $obj, $namespace . '::' . ref $obj;
}

