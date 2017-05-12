#!perl

use Test::More tests => 38;

#use Test::More qw/no_plan/;
use Test::Exception;
use lib 't/lib';

use Class::CGI profiles => 't/data/profiles.cfg',
  use                   => [qw/customer order_date date/];

my $CGI = 'Class::CGI';

my $params = {
    first       => 'John',
    last        => 'Public',
    birth_day   => 1,
    birth_month => 2,
    birth_year  => 1980,
    order_day   => 4,
    order_month => 5,
    order_year  => 2006,
    day         => 9,
    month       => 10,
    year        => 1999,       # party!
};

# test that basic functionality works

ok my $cgi = $CGI->new($params),
  'We should be able to create Class::CGI object from config file profiles';

ok !$cgi->param('birth_date'),
  'Calling a param that we did not ask for should return false';

ok my $order = $cgi->param('order_date'),
  'Calling a reused handler param should succeed';
isa_ok $order, 'Example::Date', '... and the object it returns';
is $order->day,   4,    '... and it should have the correct day';
is $order->month, 5,    '... and it should have the correct month';
is $order->year,  2006, '... and it should have the correct year';

ok my $date = $cgi->param('date'),
  'Calling a reused handler param should succeed';
isa_ok $date, 'Example::Date', '... and the object it returns';
is $date->day,   9,    '... and it should have the correct day';
is $date->month, 10,   '... and it should have the correct month';
is $date->year,  1999, '... and it should have the correct year';

is $cgi->param('day'),   9,    'But the base params should remain correct';
is $cgi->param('month'), 10,   'But the base params should remain correct';
is $cgi->param('year'),  1999, 'But the base params should remain correct';

# test that 'use => $handlers' can accept a scalar (and not just an arrayref)

Class::CGI->_clear_global_handlers;    # undocumented testing hook
Class::CGI->import(
    profiles => 't/data/profiles.cfg',
    use      => 'order_date'
);

ok $cgi = $CGI->new($params),
  'Specifying profiles should allow a single handler to be used';

ok !$cgi->param('birth_date'),
  'Calling a param that we did not ask for should return false';

ok $order = $cgi->param('order_date'),
  'Calling a reused handler param should succeed';
isa_ok $order, 'Example::Date', '... and the object it returns';
is $order->day,   4,    '... and it should have the correct day';
is $order->month, 5,    '... and it should have the correct month';
is $order->year,  2006, '... and it should have the correct year';

ok !$cgi->param('date'), '... and unused handlers should not trigger';

# test non-existent profile file

eval "use Class::CGI profiles => 't/data/no_such_file'";
ok $@,   'Trying to load a non-existent profile file should fail';
like $@, qr{Can't find profile file 't/data/no_such_file'},
  '... telling us it cannot find the file';

# test instance profiles

can_ok $cgi, 'profiles';
$cgi->profiles( 't/data/profiles.cfg', 'date' );

ok !$cgi->param('order_date'),
  'Calling a reused handler param should succeed';

ok $date = $cgi->param('date'),
  'Calling a reused handler param should succeed';
isa_ok $date, 'Example::Date', '... and the object it returns';
is $date->day,   9,    '... and it should have the correct day';
is $date->month, 10,   '... and it should have the correct month';
is $date->year,  1999, '... and it should have the correct year';

# test loading all profiles

ok $cgi->profiles('t/data/profiles.cfg'),
  'Loading all handlers from a profile file should succeed';
my %expected = (
    customer   => 'Class::CGI::Customer',
    sales      => 'Class::CGI::SyntaxError',
    birth_date => 'Class::CGI::Date',
    order_date => 'Class::CGI::Date',
    date       => 'Class::CGI::Date',
);
is_deeply $cgi->handlers, \%expected,
  '... and the correct handlers should be loaded';

Class::CGI->import(
    profiles => 't/data/profiles.cfg',
    handlers => {
        customer => 'Class::CGI::Customer2',
    },
);
$cgi = Class::CGI->new;
$expected{customer} = 'Class::CGI::Customer2';
is_deeply $cgi->handlers, \%expected,
  '... and manually specified handlers should override profile handlers';

# More sanity testing

throws_ok {
    Class::CGI->import(
        profiles => 't/data/profiles.cfg',
        use      => 'no_such_profile'
    );
  }
  qr/No handler found for parameter 'no_such_profile'/,
  '... and trying to use a non-existing parameter should fail (class)';

throws_ok { $cgi->profiles( 't/data/profiles.cfg','no_such_profile' ) }
  qr/No handler found for parameter 'no_such_profile'/,
  '... and trying to use a non-existing parameter should fail (instance)';

throws_ok { $cgi->profiles( 't/data/no_such_profile.cfg' ) }
  qr{Can't find profile file 't/data/no_such_profile.cfg'},
  '... and trying to use a non-existing profile file should fail (instance)';
