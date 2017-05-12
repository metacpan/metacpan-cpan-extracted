use lib './t';
use BlatteTestHarness;

&blatte_test([1,
              '{\\define {\\if_foo} 1}',
              '{\\if_foo 0}']);
