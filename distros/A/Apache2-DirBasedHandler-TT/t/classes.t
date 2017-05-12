use strict;
use warnings FATAL => 'all';
use lib 't';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);

plan tests => 8, need_lwp;

base: {
    my $res = GET '/dbh/';
    ok( t_cmp($res->content, qq[you might want to override "root_index"], "index request - DirBasedHandler" ));
    $res = GET '/dbh/haha/funny';
    ok( t_cmp($res->content, qq[you might want to override "root_index"], "subdir request - DirBasedHandler" ));
}

thingy: {
    my $res = GET '/thingy/';
    ok( t_cmp($res->content, qq[this is the index], "index request - My::Thingy" ));
    $res = GET '/thingy/whatever_you_say/hah';
    ok( t_cmp($res->is_success, qq[], "index request - My::Thingy" ));
    $res = GET '/thingy/super/';
    ok( t_cmp($res->content,
              'this is $location/super and all it\'s contents', #'
              "sub request - My::Thingy" ));
    $res = GET '/thingy/super/hahah';
    ok( t_cmp($res->content,
              'this is $location/super and all it\'s contents', #'
              "sub request - My::Thingy" ));
    $res = GET '/thingy/super/dooper';
    ok( t_cmp($res->content,
              'this is $location/super/dooper and all it\'s contents', #'
              "sub request - My::Thingy" ));
    $res = GET '/thingy/super/dooper/lkjdflj';
    ok( t_cmp($res->content,
              'this is $location/super/dooper and all it\'s contents', #'
              "sub request - My::Thingy" ));
}

