#!perl
# t/199-util.t - tests of App::hopen::Util
use rlib 'lib';
use HopenTest;
use Test::Deep;
use Path::Class;

use App::hopen::Util ':all';

ok isMYH('MY.hopen.pl'), 'MY.hopen.pl is MYH';
ok !isMYH('foo'), 'foo is not MYH';

ok(isMYH, 'MY.hopen.pl is MYH ($_)') for 'MY.hopen.pl';
ok(!isMYH, 'foo is not MYH ($_)') for 'foo';

done_testing();
