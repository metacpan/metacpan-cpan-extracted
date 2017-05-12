# -*- perl -*- from Devel::BeginLift
use strict;
use warnings;
use Test::More tests => 1;
use B::Generate;
use B qw(SVf_IOK SVf_READONLY);

CHECK {
  # Note: This creates a new const op for every invocation of foo, it does not replace it.
  # perl does a bit better for constants via use constant foo => 42;
  sub foo {
    my $op = B::SVOP->new("const", SVf_IOK+SVf_READONLY, 42);
    # diag $op->dump;
    # diag $op->sv;
    $op->sv->IVX;
  }
}

sub bar { 7 + foo() }
is( bar(), 49, "B::SVOP->new const" );
