use Test::More tests=>4;
use Acme::Tie::Formatted 'frink';


ok !exists $main::{format}, "old hash was not exported";
ok exists $main::{frink}, "new hash was exported";
can_ok 'Acme::Tie::Formatted', qw(TIEHASH FETCH);

$result = $frink{16, 1, 255, 4184, "%04x"};
is $result, "0010 0001 00ff 1058", "basic format";
