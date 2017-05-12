use lib './t';
use BlatteTestHarness;

&blatte_test(['a', 'a'],
             ['a b', '\\"a b\\"'],
             ['a\\b', 'a\\\\b']);
