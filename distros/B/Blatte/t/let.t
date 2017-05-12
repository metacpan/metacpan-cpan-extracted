use lib './t';
use BlatteTestHarness;

&blatte_test([17, '{\\let {{\\x 17}} \\x}'],
             [1, '{\\let {{\\a 1}} {\\let {{\\a 2} {\\b \\a}} \\b}}'],
             [2, '{\\let* {{\\a 2} {\\b \\a}} \\b}']);
