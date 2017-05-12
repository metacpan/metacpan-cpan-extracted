#!perl

use Test::More tests => 14;
#use Test::More qw/no_plan/;
use Test::Exception;
use lib 't/lib';

use Class::CGI handlers => {
    customer => 'Class::CGI::Customer',
    sales    => 'Class::CGI::SyntaxError',
};

my $CGI = 'Class::CGI';
can_ok $CGI, 'new';

my $params = { customer => 2, email => 'some@example.com' };

# test that basic functionality works

ok my $cgi = $CGI->new($params), '... and calling it should succeed';
isa_ok $cgi, $CGI, '... and the object it returns';

can_ok $cgi, 'param';
ok my $customer = $cgi->param('customer'),
  '... and calling it should succeed';
isa_ok $customer, 'Example::Customer', '... and the object it returns';
is $customer->id,    2,         '... with the correct ID';
is $customer->first, 'Corinna', '... and the correct first';

$params = {
    first => 'Bertrand',
    last  => 'Russel',
};
$cgi = $CGI->new($params);

ok $customer = $cgi->param('customer'),
  '... and calling it should succeed';
isa_ok $customer, 'Example::Customer', '... and the object it returns';
ok !defined $customer->id, '... with an undefined customer id';
is $customer->first, 'Bertrand', '... and the correct first name';
is $customer->last,  'Russel',   '... and the correct last name';
ok ! defined $cgi->raw_param('customer'),
  '... even though we never had an actual "customer" parameter';
