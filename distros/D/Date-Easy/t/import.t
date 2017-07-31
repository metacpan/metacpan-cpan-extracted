use Test::Most 0.25;


package Test::T01;
use Test::Most 0.25;

use Date::Easy;

lives_ok { today() } 'Date::Easy imports today';
lives_ok { date(time) } 'Date::Easy imports date';

lives_ok { now() } 'Date::Easy imports now';
lives_ok { datetime(time) } 'Date::Easy imports datetime';

lives_ok { seconds(), minutes(), hours(), days(), weeks(), months(), years() } 'Date::Easy imports units';


package Test::T02;
use Test::Most 0.25;

use Date::Easy::Date;

throws_ok { today() } qr/Undefined subroutine/, 'Date::Easy::Date does not import today';
throws_ok { date(time) } qr/Undefined subroutine/, 'Date::Easy::Date does not import date';


package Test::T03;
use Test::Most 0.25;

use Date::Easy::Date qw< today date >;

lives_ok { today() } 'Date::Easy::Date can import today';
lives_ok { date(time) } 'Date::Easy::Date can import date';


package Test::T04;
use Test::Most 0.25;

use Date::Easy::Datetime;

throws_ok { now() } qr/Undefined subroutine/, 'Date::Easy::Datetime does not import now';
throws_ok { datetime(time) } qr/Undefined subroutine/, 'Date::Easy::Datetime does not import datetime';


package Test::T05;
use Test::Most 0.25;

use Date::Easy::Datetime qw< now datetime >;

lives_ok { now() } 'Date::Easy::Datetime can import now';
lives_ok { datetime(time) } 'Date::Easy::Datetime can import datetime';


package Test::T06;
use Test::Most 0.25;

use Date::Easy::Units qw< :datetime >;

lives_ok { seconds() } '::Units qw<datetime> imports seconds';
lives_ok { minutes() } '::Units qw<datetime> imports minutes';
lives_ok { hours()   } '::Units qw<datetime> imports hours';
lives_ok { days()    } '::Units qw<datetime> imports days';
lives_ok { weeks()   } '::Units qw<datetime> imports weeks';
lives_ok { months()  } '::Units qw<datetime> imports months';
lives_ok { years()   } '::Units qw<datetime> imports years';


package Test::T07;
use Test::Most 0.25;

use Date::Easy::Units qw< :date >;

throws_ok { seconds() } qr/Undefined subroutine/, '::Units qw<date> imports seconds';
throws_ok { minutes() } qr/Undefined subroutine/, '::Units qw<date> imports minutes';
throws_ok { hours()   } qr/Undefined subroutine/, '::Units qw<date> imports hours';
lives_ok  { days()    } '::Units qw<date> imports days';
lives_ok  { weeks()   } '::Units qw<date> imports weeks';
lives_ok  { months()  } '::Units qw<date> imports months';
lives_ok  { years()   } '::Units qw<date> imports years';


package main;										# back to main, or else done_testing won't be found

done_testing;
