#!/usr/bin/perl

use strict;
use warnings;
use Test::Most tests => 2;

use App::Prove::Plugin::TraceUse;

my $t = Tree::Simple->new( [], Tree::Simple->ROOT );

$t->addChildren(
                Tree::Simple->new([qw/Test::Most 0.25/]),
                Tree::Simple->new([qw/App::Prove 3.23/]),
               );

cmp_deeply(
           App::Prove::Plugin::TraceUse::_find_dependent_modules($t),
           bag( [qw/App::Prove 3.23/], [qw/Test::Most 0.25/] ),
           "simple dependencies"
          );

my $m_name = "Foo::Bar::THIS::ISNT::INSTALLED::" . unpack "H*", pack "d", rand;

SKIP: {

    eval "require $m_name";

    skip "bogus module name happened to be installed - this never never never happens",
      1, if not $@;

    my $m2 = Tree::Simple->new( [qw/$m_name 0.999/] );
    $m2->addChild( Tree::Simple->new( [qw/warnings 0.999/] ) );

    $t->addChild($m2);

    # use Data::Dumper;
    # note Dumper App::Prove::Plugin::TraceUse::_find_dependent_modules($t);

    cmp_deeply(
               App::Prove::Plugin::TraceUse::_find_dependent_modules($t),
               bag( [qw/warnings 0.999/], [qw/App::Prove 3.23/], [qw/Test::Most 0.25/] ),
               "complex dependencies"
              );

};

done_testing();
