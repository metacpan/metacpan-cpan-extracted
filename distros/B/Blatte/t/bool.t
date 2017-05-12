use lib './t';
use BlatteTestHarness;

&blatte_test([7, '{\\or {} 7}'],
             [8, '{\\or {\\and 2 {} 4} 8}']);
