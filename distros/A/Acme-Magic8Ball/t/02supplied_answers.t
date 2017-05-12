use Test::More tests => 2;

use_ok("Acme::Magic8Ball", "ask");
is("Too predictable!", ask("Pass answers", "Too predictable!"));