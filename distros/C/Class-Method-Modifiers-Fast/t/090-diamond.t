#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my $D = D->new();
is($D->orig, "DBA", "C not called");

BEGIN
{
    package A;
    sub new { bless {}, shift }
    sub orig { "A" }

    package B;
    use Class::Method::Modifiers::Fast;
    our @ISA = ('A');
    around orig => sub { "B" . shift->() };

    package C;
    use Class::Method::Modifiers::Fast;
    our @ISA = ('A');
    around orig => sub { "C" . shift->() };

    package D;
    use Class::Method::Modifiers::Fast;
    our @ISA = ('B', 'C');
    around orig => sub { "D" . shift->() };
}

