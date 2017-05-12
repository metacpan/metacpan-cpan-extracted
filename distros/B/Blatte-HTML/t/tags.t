use lib './t';
use BlatteTestHarness;

&blatte_test(['<a href="http://www.blatte.org/">Blatte</a>',
              '{\\a \href=http://www.blatte.org/ Blatte}'],
             ['<img ismap>',
              '{\\img \ismap={\html_bool_yes}}'],
             ['<img>',
              '{\\img \ismap={\html_bool_no}}']);
