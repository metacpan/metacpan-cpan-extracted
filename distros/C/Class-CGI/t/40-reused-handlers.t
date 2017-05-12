#!perl

use Test::More tests => 28;

#use Test::More qw/no_plan/;
use Test::Exception;
use lib 't/lib';

use Class::CGI handlers => {
    birth_date => 'Class::CGI::Date',
    order_date => 'Class::CGI::Date',
};

my $CGI = 'Class::CGI';

my $params = {
    birth_day   => 1,
    birth_month => 2,
    birth_year  => 1980,
    order_day   => 4,
    order_month => 5,
    order_year  => 2006,
    day         => 9,
    month       => 10,
    year        => 1999,    # party!
};

# test that basic functionality works

my $cgi = $CGI->new($params);

ok my $birth = $cgi->param('birth_date'),
  'Calling a reused handler param should succeed';
isa_ok $birth, 'Example::Date', '... and the object it returns';
is $birth->day,   1,    '... and it should have the correct day';
is $birth->month, 2,    '... and it should have the correct month';
is $birth->year,  1980, '... and it should have the correct year';

ok my $order = $cgi->param('order_date'),
  'Calling a reused handler param should succeed';
isa_ok $order, 'Example::Date', '... and the object it returns';
is $order->day,   4,    '... and it should have the correct day';
is $order->month, 5,    '... and it should have the correct month';
is $order->year,  2006, '... and it should have the correct year';

is $cgi->param('day'),   9,    'But the base params should remain correct';
is $cgi->param('month'), 10,   'But the base params should remain correct';
is $cgi->param('year'),  1999, 'But the base params should remain correct';

# test that we can still use the base name

$cgi->handlers(
    birth_date => 'Class::CGI::Date',
    order_date => 'Class::CGI::Date',
    date       => 'Class::CGI::Date',
);

ok $birth = $cgi->param('birth_date'),
  'Calling a reused instance handler param should succeed';
isa_ok $birth, 'Example::Date', '... and the object it returns';
is $birth->day,   1,    '... and it should have the correct day';
is $birth->month, 2,    '... and it should have the correct month';
is $birth->year,  1980, '... and it should have the correct year';

ok $order = $cgi->param('order_date'),
  'Calling a reused instance handler param should succeed';
isa_ok $order, 'Example::Date', '... and the object it returns';
is $order->day,   4,    '... and it should have the correct day';
is $order->month, 5,    '... and it should have the correct month';
is $order->year,  2006, '... and it should have the correct year';

ok my $date = $cgi->param('date'),
  'Calling a reused instance handler param should succeed';
isa_ok $date, 'Example::Date', '... and the object it returns';
is $date->day,   9,    '... and it should have the correct day';
is $date->month, 10,   '... and it should have the correct month';
is $date->year,  1999, '... and it should have the correct year';
