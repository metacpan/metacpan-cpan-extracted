use lib './t';
use BlatteTestHarness;

&blatte_test([7, '{\\add 3 4}'],
             [12, '{\\multiply 3 4}'],
             [0.75, '{\\divide 3 4}'],
             [-1, '{\\subtract 3 4}']);
