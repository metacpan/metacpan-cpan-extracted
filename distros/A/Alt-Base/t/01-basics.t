#!perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Module::Load;
use Test::Exception;
use Test::More 0.98;

sub use_ {
    my $mod = shift;
    load $mod;
    if (@_) {
        $mod->import(@_);
    } else {
        $mod->import;
    }
}

sub no_ {
    my $mod = shift;
    $mod->unimport;
}

lives_ok { use_ "Alt::Foo::one" };
dies_ok  { use_ "Alt::Foo"      } "check incorrect Alt name";
dies_ok  { use_ "Alt::Bar::one" } "check \$ALT defined";
lives_ok { use_ "Alt::Bar::two" } "turn check off";
dies_ok  { use_ "Alt::Baz::one" } "check correct \$ALT value";

done_testing;
