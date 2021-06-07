use Acme::Boolean;
use Test::More;

plan tests => 19;

ok !untrue;
ok !wrong;
ok !incorrect;
ok !errorneous;
ok !fallacious;
ok !untruthful;
ok !nah;
ok !&no;
ok !UNREAL;
ok !FISHY;
ok ! NO;
ok ! NO NO;
ok ! NO NO NO;
ok ! NO NO NO NO;
ok ! NO NO NO NO NO;
ok ! NO NO NO NO NO NO;
ok ! &no;
ok ! &no(&no);
ok ! NO really not fishy;
