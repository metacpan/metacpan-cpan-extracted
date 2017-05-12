use t::TestCookie;

plan tests => 1 * blocks();

#test 'CGI::Cookie';
run_tests;

__DATA__

=== TEST 1: successive =
# http://rt.cpan.org/Public/Bug/Display.html?id=34238
--- cookie
foo=ba=r
--- out
$VAR1 = {
          'foo' => [
                     'ba=r'
                   ]
        };



=== TEST 2: empty cookie
# http://rt.cpan.org/Public/Bug/Display.html?id=39120
--- cookie
--- out
$VAR1 = {};



=== TEST 3: invalid cookie (1)
# http://rt.cpan.org/Public/Bug/Display.html?id=39120
--- cookie
a
--- out
$VAR1 = {};



=== TEST 4: invalid cookie (2)
# http://rt.cpan.org/Public/Bug/Display.html?id=39120
--- cookie
this-is-not-a-cookie
--- out
$VAR1 = {};



=== TEST 5: empty values
rt.cpan.org #49302
--- cookie: lastvisit=1251731074; sessionlogin=1251760758; username=; password=; remember_login=; admin_button=
--- out
$VAR1 = {
          'admin_button' => [],
          'lastvisit' => [
                           '1251731074'
                         ],
          'password' => [],
          'remember_login' => [],
          'sessionlogin' => [
                              '1251760758'
                            ],
          'username' => []
        };

