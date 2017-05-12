#!/usr/bin/perl

use strict;
use warnings;

use Test::Most qw/no_plan die/;
use Class::Sniff;

{

    package Parent;

    sub new { bless {} => shift }
    sub foo { }
    sub bar { }
    sub baz { }

    package Child;
    our @ISA = 'Parent';
    sub new { shift->SUPER::new }
}

# The eval'ing a string require regrettably creates a symbol table entry for
# the non-existent module and any parent stashes:
# There::Is::No::
# There::Is::
# There::
# We need to trap this entry.
eval "require There::Is::No::Spoon";

ok !Class::Sniff->new_from_namespace({
    namespace => qr/There/,
    universal => 1,
}), 'New from namespace should not find packages which did not load';

Child->new;   # force that SUPER call
ok my $graph = Class::Sniff->graph_from_namespace({
    namespace => qr/Child|Parent/,
    universal => 1,
    clean     => 1,
}), 'We should be able to request "clean" packages';
unlike $graph->as_ascii, qr/::SUPER/,
    '... and the ::SUPER pseudo-package should not show up';
