use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

use B 'svref_2object';

BEGIN {
    package P1;
    sub new { bless {}, shift }
    sub m1 { 'P1/m1' }

    package P2;
    our @ISA = 'P1';
    use Class::Method::Modifiers 'fresh';

    sub m6 { 'P2/m6' }

    fresh m2 => sub { 'P2/m2' };

    fresh [qw(m3 m4)] => sub { 'P2/m3/m4' };

    my $closee = 'closee';
    fresh m5 => sub { "P2/m5/$closee" };
}

BEGIN {
    package P3;                 # like P2, but using install_modifier
    our @ISA = 'P1';

    sub m6 { 'P3/m6' }

    package main;
    use Class::Method::Modifiers 'install_modifier';

    install_modifier P3 => fresh =>     m2      => sub { 'P3/m2' };
    install_modifier P3 => fresh => [qw(m3 m4)] => sub { 'P3/m3/m4' };

    my $closee = 'closee';
    install_modifier P3 => fresh =>     m5      => sub { "P3/m5/$closee" };
}

can_ok(P2->new, @$_) for [
    qw(m2),                     # single-name call to fresh
    qw(m3 m4),                  # multi-name call
    qw(m5),                     # code ref is closure
];

is(P2->new->m5, 'P2/m5/closee', 'closure works');

can_ok(P3->new, qw(m2 m3 m4 m5));
is(P3->new->m5, 'P3/m5/closee', 'closure works with install_modifier');

for my $class (qw(P2 P3)) {
    my $method = $class->can('m5');
    is(svref_2object($method)->GV->STASH->NAME, $class,
       "method installed in $class has correct stash name");
}

{
    package P2;

    ::like(::exception { fresh m1 => sub {} },
           qr/^Class P2 already has a method named 'm1'/,
           'fresh: exception when inherited method exists');

    ::like(::exception { fresh m6 => sub {} },
           qr/^Class P2 already has a method named 'm6'/,
           'fresh: exception when local method exists');

    ::like(::exception { fresh '=:=' => sub {} },
           qr/^Invalid method name '=:='/,
           'fresh: exception when name invalid');
}

like(exception { install_modifier P3 => fresh => m1 => sub {} },
     qr/^Class P3 already has a method named 'm1'/,
     'install_modifier: exception when inherited method exists');

like(exception { install_modifier P3 => fresh => m6 => sub {} },
     qr/^Class P3 already has a method named 'm6'/,
     'install_modifier: exception when local method exists');

like(exception { install_modifier P3 => fresh => '=:=' => sub {} },
     qr/^Invalid method name '=:='/,
     'install_modifier: exception when name invalid');

done_testing;
