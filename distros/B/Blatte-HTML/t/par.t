use lib './t';
use BlatteTestHarness;

&blatte_test(['a

<p>b',
              '{a

b}'],
             ['a

b',
              '{\html_p_no a

b}'],
             ['a

<p>b</p>',
              '{a

{\p b}}'],

['<b>a

<p>b</p></b>',
 '{\b a

b}'],
    ['a

<p><b>b</b></p>

<p><b>c</b>',
     '{a

{\b b

c}}']);
