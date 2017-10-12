use Test::More;
use Test::Alien::CPP;
plan tests => 4;
use_ok 'Alien::XInputSimulator';
alien_ok 'Alien::XInputSimulator';
diag "CFLAGS='".Alien::XInputSimulator->cflags."' LDFLAGS='".Alien::XInputSimulator->libs."'";
ok Alien::XInputSimulator->cflags, "assert Alien::XInputSimulator->cflags is non-empty";
ok Alien::XInputSimulator->libs, "assert Alien::XInputSimulator->libs is non-empty";

