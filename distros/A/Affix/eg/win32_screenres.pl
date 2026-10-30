use v5.40;
use Affix;
#
affix 'user32', 'GetSystemMetrics', [Int], Int;
#
say 'width = ' . GetSystemMetrics(0);
say 'height = ' . GetSystemMetrics(1);
say 'number of monitors = ' . GetSystemMetrics(80);
