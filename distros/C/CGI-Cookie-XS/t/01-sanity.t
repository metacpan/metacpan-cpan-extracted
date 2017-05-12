#use CGI::Cookie::XS;

use t::TestCookie;

plan tests => 1 * blocks();

#test 'CGI::Cookie';
no_diff;

run_tests;

__DATA__

=== TEST 1: complex cookie
--- cookie
foo=a%20phrase;haha; bar=yes%2C%20a%20phrase; baz=%5Ewibble&leiyh; qux=%27
--- out
$VAR1 = {
          'bar' => [
                     'yes, a phrase'
                   ],
          'baz' => [
                     '^wibble',
                     'leiyh'
                   ],
          'foo' => [
                     'a phrase'
                   ],
          'qux' => [
                     '\''
                   ]
        };



=== TEST 2: foo=
--- cookie
foo=
--- out
$VAR1 = {
          'foo' => []
        };



=== TEST 3: foo
--- cookie
foo
--- out
$VAR1 = {};



=== TEST 4: foo bar
--- cookie
foo bar
--- out
$VAR1 = {};



=== TEST 5: &
--- cookie
&
--- out
$VAR1 = {};



=== TEST 6: ;
--- cookie
;
--- out
$VAR1 = {};



=== TEST 7: ,
--- cookie
,
--- out
$VAR1 = {};



=== TEST 8: &&
--- cookie
&&;
--- out
$VAR1 = {};



=== TEST 9: trailing spaces and leading spaces should be trimmed
--- cookie
  foo=a%3A; 
--- out
$VAR1 = {
          'foo' => [
                     'a:'
                   ]
        };



=== TEST 10: trailing spaces which should be reserved.
--- cookie
foo=a%3A 
--- out
$VAR1 = {
          'foo' => [
                     'a: '
                   ]
        };



=== TEST 11: , sperated values
--- cookie
foo=bar,foo2=bar2, foo3=bar3;foo4 =a&b&c; foo5=a;b
--- out
$VAR1 = {
          'foo' => [
                     'bar'
                   ],
          'foo2' => [
                      'bar2'
                    ],
          'foo3' => [
                      'bar3'
                    ],
          'foo4 ' => [
                       'a',
                       'b',
                       'c'
                     ],
          'foo5' => [
                      'a'
                    ]
        };



=== TEST 12: leading and trailing spaces
--- cookie
 foo = bar ; foo2  =  bar2 
--- out
$VAR1 = {
          'foo ' => [
                      ' bar '
                    ],
          'foo2  ' => [
                        '  bar2 '
                      ]
        };



=== TEST 13: encoded leading and trailing spaces
--- cookie
%20foo = bar ;%20foo2  =  bar2 
--- out
$VAR1 = {
          ' foo ' => [
                       ' bar '
                     ],
          ' foo2  ' => [
                         '  bar2 '
                       ]
        };

