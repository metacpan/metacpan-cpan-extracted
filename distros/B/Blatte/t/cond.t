use lib './t';
use BlatteTestHarness;

&blatte_test([2,
              '{\\cond {{} 1} {x 2} {{} 3} {y 4}}'],
             [2,
              '{\\cond {0 1} {x 2} {y 3}}']);
