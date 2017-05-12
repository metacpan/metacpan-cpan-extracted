use strict;
use warnings;
use Test::More tests => 9;

sub foo { 42 }

my $i;
BEGIN { $i = 0; }

sub callback {
    my ($cv, $op) = @_;

    is($cv->(), 42, 'we god the right coderef');
    isa_ok($op, 'B::OP');
    is($op->name, 'entersub', 'op looks sane');

    $i++;
}

use B::Hooks::OP::Check::EntersubForCV
    \&foo => \&callback,
    \&foo => \&callback,
    \&callback => sub {};

BEGIN { is($i, 0) }

foo();

BEGIN { is($i, 2) }

no B::Hooks::OP::Check::EntersubForCV \&foo;

BEGIN { is($i, 2) }
