use lib './t';
use BlatteTestHarness;

&blatte_test(['a &amp; b', '{a & b}'],
             ['a & b', '{\html_ent_no a & b}']);
