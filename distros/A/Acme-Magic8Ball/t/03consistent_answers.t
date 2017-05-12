use Test::More tests => 2;

use_ok("Acme::Magic8Ball", "ask", ":consistent");
my $consistent = 1;
my $answer     = ask("Is this module any use whatsoever?");
for (0..1000) {
    next if ask("Is this module any use whatsoever?") eq $answer;
    $consistent = 0; 
    last;
}
ok($consistent);