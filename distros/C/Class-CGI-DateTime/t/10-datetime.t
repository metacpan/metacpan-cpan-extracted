#!perl -T

use Test::More tests => 44;

#use Test::More qw/no_plan/;
use Test::Exception;
use Scalar::Util qw/tainted/;

use Class::CGI handlers => {
    date       => 'Class::CGI::DateTime',
    order_date => 'Class::CGI::DateTime',
};

# test that basic functionality works

my $params = {
    day   => 2,
    month => 11,
    year  => 1997,
};

my $cgi = Class::CGI->new($params);
ok my $date = $cgi->param('date'), 'Fetching the date object should succeed';
isa_ok $date, 'DateTime', '... and the object it returns';
is $date->day,   2,    '... and the day should be correct';
is $date->month, 11,   '... as should the month';
is $date->year,  1997, '... and the year';

# test that missing components are handled correctly

$params = {
    day  => 2,
    year => 1997,
};

$cgi = Class::CGI->new($params);
$cgi->required('date');
ok !( $date = $cgi->param('date') ),
  'Fetching the date object should succeed';
ok $cgi->is_missing_required('date'),
  '... and the date should be reported as missing';
ok my $errors = $cgi->errors, '... and errors should be reported';
is $errors->{date}, 'The &#39;date&#39; is missing values for (month)',
  '... with the correct error message';

# Make sure that bad dates aren't swallowed

$params = {
    day   => 2,
    month => 'foo',
    year  => 1997,
};

$cgi = Class::CGI->new($params);
ok !( $date = $cgi->param('date') ), 'Fetching invalid dates should fail';
ok my $error_for = $cgi->errors,
  '... and the cgi object should report errors';
ok exists $error_for->{date}, '... for the correct parameter';

# test that basic functionality works

$params = {
    'order_date.day'   => 2,
    'order_date.month' => 5,
    'order_date.year'  => 1997,
};

$cgi = Class::CGI->new($params);
ok $date = $cgi->param('order_date'),
  'Fetching the date object should succeed';
isa_ok $date, 'DateTime', '... and the object it returns';
is $date->day,   2,    '... and the day should be correct';
is $date->month, 5,    '... as should the month';
is $date->year,  1997, '... and the year';

# test that missing components are handled correctly

$params = {
    'order_date.day'  => 2,
    'order_date.year' => 1997,
};

$cgi = Class::CGI->new($params);
$cgi->required('order_date');
ok !( $date = $cgi->param('order_date') ),
  'Fetching the date object should succeed';
ok $cgi->is_missing_required('order_date'),
  '... and the order_date should be reported as missing';
ok $errors = $cgi->errors, '... and errors should be reported';
is $errors->{order_date},
  'The &#39;order_date&#39; is missing values for (order_date.month)',
  '... with the correct error message';

$params = {
    year       => 1964,
    month      => 10,
    day        => 16,
    hour       => 16,
    minute     => 12,
    second     => 47,
    nanosecond => 500000000,
    time_zone  => 'Asia/Taipei',
};
my @args = keys %$params;

$cgi = Class::CGI->new($params);
$cgi->args( 'date', { params => \@args } );
ok $date = $cgi->param('date'), 'Fetching the date object should succeed';
isa_ok $date, 'DateTime', '... and the object it returns';
is $date->day,   16,   '... and the day should be correct';
is $date->month, 10,   '... as should the month';
is $date->year,  1964, '... and the year';
is $date->hour,  16,   '.. .and the hour';

$params = {
    year                    => 1964,
    month                   => 10,
    day                     => 16,
    hour                    => 16,
    minute                  => 12,
    second                  => 47,
    nanosecond              => 500000000,
    time_zone               => 'Asia/Taipei',
    'order_date.year'       => 1999,
    'order_date.month'      => 10,
    'order_date.day'        => 16,
    'order_date.hour'       => 16,
    'order_date.minute'     => 2,
    'order_date.second'     => 47,
    'order_date.nanosecond' => 500000000,
    'order_date.time_zone'  => 'Asia/Taipei',
};

$cgi = Class::CGI->new($params);
$cgi->args( 'date',       { params => \@args } );
$cgi->args( 'order_date', { params => \@args } );
ok $date = $cgi->param('date'), 'Fetching the date object should succeed';
isa_ok $date, 'DateTime', '... and the object it returns';
is $date->day,   16,   '... and the day should be correct';
is $date->month, 10,   '... as should the month';
is $date->year,  1964, '... and the year';

ok $date = $cgi->param('order_date'),
  'Fetching the order date object should succeed';
isa_ok $date, 'DateTime', '... and the object it returns';
is $date->day,    16,   '... and the day should be correct';
is $date->month,  10,   '... as should the month';
is $date->year,   1999, '... and the year';
is $date->minute, 2,    '... and the correct minute';

# test untainting

$params = {
    day => 2 . ( substr $ENV{PATH}, 0, 0 ),    # tainted
    month => 11,
    year  => 1997,
};

ok tainted( $params->{day} ), 'Data we pass to Class::CGI may be tainted';
$cgi = Class::CGI->new($params);
ok $date = $cgi->param('date'),
  '... but we should still be able to fetch objects';
ok !tainted( $date->day ), '... and it should come out untainted';
is $date->day,   2,    '... and the day should be correct';
is $date->month, 11,   '... as should the month';
is $date->year,  1997, '... and the year';

