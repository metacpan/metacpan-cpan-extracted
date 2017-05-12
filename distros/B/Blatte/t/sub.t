use lib './t';
use BlatteTestHarness;

&blatte_test(['z', '{{\\lambda {\\x} \\x} z}'],
             ['b  a', '{\\define {\\r \\x \\y} {\\y  \\x}}', '{\\r a b}'],
             ['a 1 b 2 c 3',
              '{\\define {\\f \\=a \\=b \\c} {a \\a b \\b c \\c}}',
              '{\\f 3 \\a=1 \\b=2}'],
             ['y z x',
              '{\\define {\\f2 \\a \\&b} {\\b \\a}}',
              '{\\f2 x y z}']);
