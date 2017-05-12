use Test::More tests => 9;

package Pronk;
use Class::Role;

sub foo { 10 }
sub bar { 20 }
sub baz { 30 }
sub fru { 50 }
sub foz { my ($self) = @_; $self->PARENTCLASS::foz * 1000 }

package Whiff;

sub foo { 1 }
sub bar { 2 }
sub baz { 3 }
sub foz { 4 }

package Splort;
use base Whiff;
use Class::Role Pronk, -excludes => [qw{ bar }];

sub foo { 100 }

sub new { bless {} => shift }

package Spoole;
use Class::Role;
use Class::Role Pronk;

sub rab { 31 }
sub bar { 13 }

package Birre;

sub foz { 19 }

package Niphth;
use base Birre;
use Class::Role Spoole;

sub new { bless {} => shift }

package main;

my $splort = Splort->new;
my $niphth = Niphth->new;

ok($splort->foo == 100,     "override");
ok($splort->bar == 2,       "exclude");
ok($splort->baz == 30,      "role override");
ok($splort->foz == 4000,    "PARENTCLASS");
ok($splort->fru == 50,      "role");
ok($niphth->rab == 31,      "role.. again");
ok($niphth->foo == 10,      "composing roles");
ok($niphth->bar == 13,      "overriding composed roles");
ok($niphth->foz == 19000,   "PARENTCLASS in composed roles");

# vim: ft=perl:
