use lib './t';
use BlatteTestHarness;

&blatte_test(['c', '{\\aref {a b c d e} 2}'],
             ['x 2 3 4',
              '{\\define \\a {1 2 3 4}}',
              '{\\aset \\a 0 x}',
              '\\a'],
             ['1 2 3',
              '{\\let {{\\a {1 2}}} {\\push \\a 3}}'],
             ['4 1 2 3',
              '{\\let* {{\\a {1 2 3 4}} {\\b {\\pop \\a}}} {\\b \\a}}'],
             ['1 2 3',
              '{\\list 1 2 3}']);
