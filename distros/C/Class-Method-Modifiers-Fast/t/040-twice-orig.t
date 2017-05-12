#!perl -T
use strict;
use warnings;
use Test::More tests => 1;
my @seen;

eval { ChildCMM->new->orig() };
is_deeply(\@seen, ["orig", "orig"], "CMM: calling orig twice in one around works");

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig { push @seen, "orig" }

    package ChildCMM;
    our @ISA = 'Parent';
    use Class::Method::Modifiers::Fast;
    around 'orig' => sub { my $orig = shift; $orig->(); $orig->(); };
}

