use lib './t';
use BlatteTestHarness;

&blatte_test(['foo', '{\\define \\f foo}', '\\f'],
             ['bar', '{\\define \\f foo}', '{\\set! \\f bar}', '\\f']);
