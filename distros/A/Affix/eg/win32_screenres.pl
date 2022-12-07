use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Affix;
$|++;
#
sub GetSystemMetrics : Native('C:\Windows\System32\user32.dll') : Signature([Int]=>Int);
#
CORE::say 'width = ' . GetSystemMetrics(0);
CORE::say 'height = ' . GetSystemMetrics(1);
CORE::say 'number of monitors = ' . GetSystemMetrics(80);
