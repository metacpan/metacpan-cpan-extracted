#!perl

use Test::More tests => 29;

#use Test::More qw/no_plan/;
use Test::Exception;
use lib 't/lib';

use Class::CGI;
my $CGI = 'Class::CGI';
can_ok $CGI, 'new';

my $params = {
    customer => 2,
    email    => 'some@example.com',
    sports   => [qw/basketball soccer Scotch /],
};

# test that basic functionality works

ok my $cgi = $CGI->new($params), '... and calling it should succeed';
my $cgi2 = $CGI->new($params);
isa_ok $cgi, $CGI, '... and the object it returns';

can_ok $cgi, 'handlers';
throws_ok {
    $cgi->handlers(
        customer => 'Class::CGI::Customer',
        sales    => 'No::Such::Class',
    );
  }
  qr/^The following modules are not installed: \(No::Such::Class\)/,
  'Trying to use handlers which do not exist should fail';

my %handlers = (
    customer => 'Class::CGI::Customer',
    sales    => 'Class::CGI::SyntaxError',
);

ok $cgi->handlers(%handlers),
  '... and setting valid handlers on an instance should succeed';
is_deeply $cgi->handlers, \%handlers,
  '... and handlers() should report the correct handlers';

can_ok $cgi, 'param';
ok my $customer = $cgi->param('customer'),
  '... and calling it should succeed';
isa_ok $customer, 'Example::Customer', '... and the object it returns';
is $customer->id,    2,         '... with the correct ID';
is $customer->first, 'Corinna', '... and the correct first';

ok my $customer_id = $cgi2->param('customer'),
  'A separate Class::CGI instance should not have to share handlers';
is $customer_id, 2, '... and it should behave correctly';

ok my $email = $cgi->param('email'),
  'Calling params for which we have no handler should succeed';
is $email, 'some@example.com',
  '... and simply return the raw value of the parameter';

my @params = sort $cgi->param;
is_deeply \@params, [qw/customer email sports/],
  'Calling param() without arguments should succeed';

# test multiple values for unhandled params

my $sport = $cgi->param('sports');
is $sport, 'basketball',
  'Calling a multi-valued param in scalar context should return the first value';
my @sports = $cgi->param('sports');
is_deeply \@sports, [qw/ basketball soccer Scotch /],
  '... and calling it in list context should return all values';

# test bad handlers

throws_ok { $cgi->param('sales') }
  qr{^\QCould not load 'Class::CGI::SyntaxError': syntax error at},
  'Trying to fetch a param with a bad handler should fail';

# Note that the following tests are not quite necessary as the exception
# handling is up to those who implement handlers.  However, I include them
# here so folks can see how this works.

# test that we cannot use invalid ids

$params = { customer => 'Ovid' };
$cgi = $CGI->new($params);
$cgi->handlers(
    customer => 'Class::CGI::Customer',
);

ok !$cgi->param('customer'),
  'Trying to fetch a value with an invalid ID should fail';
my %errors = $cgi->errors;
like $errors{customer}, qr/^\QInvalid id (Ovid) for Class::CGI::Customer/,
  '... and we should have the correct error reported';

# test that we cannot use a non-existent id

$params = { customer => 3 };
$cgi = $CGI->new($params);
$cgi->handlers(
    customer => 'Class::CGI::Customer',
);

ok !$cgi->param('customer'),
  'Trying to fetch a value with a non-existent ID should fail';
%errors = $cgi->errors;
like $errors{customer}, qr/^\QCould not find customer for (3)/,
  '... and we should have the correct error reported';

can_ok $cgi, 'required';
ok $cgi->required(qw/customer email/),
  '... and setting required parameters should succeed';

can_ok $cgi, 'is_required';
ok $cgi->is_required('customer'),
  '... and required parameters should report true';
ok !$cgi->is_required('name'),
  '... and optional parameters should report false';
