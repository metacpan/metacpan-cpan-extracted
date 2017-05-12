use strict;
use warnings;
use utf8;
use Test::More;

use App::LJ;

my $lj = App::LJ->new({color => 0});

is $lj->_process_line('2015-01-31 [21:06:22] +0900 keylogger: {"app":"Terminal"}'), '2015-01-31 [21:06:22] +0900 keylogger:
{
   "app" : "Terminal"
}';

is $lj->_process_line('2015-01-31 [21:06:22] +0900 keylogger:'), '2015-01-31 [21:06:22] +0900 keylogger:';
is $lj->_process_line('2015-01-31 {21:06:22} +0900 keylogger:'), '2015-01-31 {21:06:22} +0900 keylogger:';

is $lj->_process_line('2015-01-31 [21:06:22] +0900 keylogger: [{"app":"Terminal"},{"app":"Vim"}]'), '2015-01-31 [21:06:22] +0900 keylogger:
[
   {
      "app" : "Terminal"
   },
   {
      "app" : "Vim"
   }
]';

done_testing;
