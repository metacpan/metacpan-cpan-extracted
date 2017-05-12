#!perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::Exception;
use Test::More;

sub use_ {
    my $mod = shift;
    my $modpm = $mod; $modpm =~ s!::!/!g; $modpm .= ".pm";
    require $modpm;
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

lives_ok { use_ "Alt::Foo::one"  };
dies_ok  { use_ "Alt::Foo"       } "incorrect alt name -> dies";
dies_ok  { use_ "Alt::Bar::one"  } "ALT not defined -> dies";
lives_ok { use_ "Alt::Bar::two"  } "no assert";
dies_ok  { Alt::Bar::two->assert } "assert via assert()";
dies_ok  { use_ "Alt::Baz::one"  } "incorrect ALT -> dies";

done_testing;
