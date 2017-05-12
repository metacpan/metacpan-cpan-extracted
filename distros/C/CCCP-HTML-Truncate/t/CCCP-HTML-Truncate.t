# Before `make install' is performed this script should be runnable with

use Test::More tests => 6;
BEGIN { 
    use_ok('CCCP::HTML::Truncate');
};

    can_ok('CCCP::HTML::Truncate', 'truncate');
    
    
    my $str = "<div>Тут могут быть <b>&mdash; разные entities и &quot; всякие</b> и,\n\n незакрытые теги <div> bla ... bla";
    
    ok( CCCP::HTML::Truncate->truncate($str,20) eq '<div>Тут могут быть <b>— раз...</b></div>','No elips, stop in tag');
    ok( CCCP::HTML::Truncate->truncate($str,20,'...конец') eq '<div>Тут могут быть <b>— раз...конец</b></div>','With elips');
    ok( CCCP::HTML::Truncate->truncate('',20,'...конец') eq '','Empty value');
    ok( CCCP::HTML::Truncate->truncate($str,105,'...конец') eq "<div>Тут могут быть <b>— разные entities и \" всякие</b> и,\n\n незакрытые теги <div> bla ... bla</div></div>",'Big value');
