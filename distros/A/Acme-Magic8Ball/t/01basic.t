use Test::More tests => 4;

use_ok("Acme::Magic8Ball", "ask");

ok(ask("Will this work?"), "Got an answer");
ok(ask("Will this work again?"), "Got another answer");
is("You must ask a question!",ask(),"Should catch an empty question");

