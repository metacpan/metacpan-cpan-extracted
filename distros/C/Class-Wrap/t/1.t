use Test::More tests => 4;
use Class::Wrap;

package Foo;

sub myok { my ($self, $message) = @_; Test::More->ok($message); }
sub AUTOLOAD { my $self = shift; Test::More::ok(0, "Shouldn't call autoload"); }

package main;

Foo->myok("Calling method without wrapper");
wrap { ok(1,"Called here"); $_[0] ne "AUTOLOAD"; } "Foo";

Foo->myok("Calling method through wrapper");
Foo->bad();
