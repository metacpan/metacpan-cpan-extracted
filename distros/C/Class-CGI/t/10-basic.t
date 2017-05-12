#!perl

use Test::More tests => 48;
#use Test::More qw/no_plan/;
use Test::Exception;
use lib 't/lib';

use Class::CGI handlers => {
    customer => 'Class::CGI::Customer',
    sales    => 'Class::CGI::SyntaxError',
    argument => 'Class::CGI::Args',
};

my $CGI = 'Class::CGI';
can_ok $CGI, 'new';

my $params = { customer => 2, email => 'some@example.com' };

# test that basic functionality works

ok my $cgi = $CGI->new($params), '... and calling it should succeed';
isa_ok $cgi, $CGI, '... and the object it returns';

can_ok $cgi, 'handlers';
ok my $handlers = $cgi->handlers, '... and calling it should succeed';
is_deeply $handlers,
  { argument => 'Class::CGI::Args',
    customer => 'Class::CGI::Customer',
    sales    => 'Class::CGI::SyntaxError',
  },
  '... and it should return a hashref of the current handlers';

can_ok $cgi, 'param';
ok my $customer = $cgi->param('customer'),
  '... and calling it should succeed';
isa_ok $customer, 'Example::Customer', '... and the object it returns';
is $customer->id,    2,         '... with the correct ID';
is $customer->first, 'Corinna', '... and the correct first';

ok my $email = $cgi->param('email'),
  'Calling params for which we have no handler should succeed';
is $email, 'some@example.com',
  '... and simply return the raw value of the parameter';

my @params = sort $cgi->param;
is_deeply \@params, [qw/customer email/],
  'Calling param() without arguments should succeed';

can_ok $cgi, 'args';
$cgi->args( argument => [qw/foo bar/] );
ok my $args = $cgi->param('argument'),
  '... and handlers which rely on args should succeed';
is_deeply $args, [qw/bar foo/], '... and handle their arguments correctly';

# test multiple values for unhandled params

$params = { sports => [qw/ basketball soccer Scotch /] };
$cgi = $CGI->new($params);
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

# test some import errors

throws_ok { Class::CGI->import('handlers') } qr/No handlers defined/,
  'Failing to provide handlers should throw an exception';

throws_ok { Class::CGI->import( handlers => [qw/Class::CGI::Customer/] ) }
  qr/No handlers defined/,
  'Failing to provide a hashref of handlers should throw an exception';

# Note that some of the following tests are not quite necessary as the
# exception handling is up to those who implement handlers.  However, I
# include them here so folks can see how this works.

# test that we cannot use invalid ids

$params = { customer => 'Ovid' };
$cgi = $CGI->new($params);
ok !$cgi->param('customer'),
  'Trying to fetch a value with an invalid ID should fail';

can_ok $cgi, 'errors';
ok my %error_for = $cgi->errors,
  '... and it should return the generated errors';
is scalar keys %error_for, 1,
  '... and they should be the correct number of errors';
like $error_for{customer}, qr/^\QInvalid id (Ovid) for Class::CGI::Customer/,
  '... and be the errors thrown by the handlers';

# test that we cannot use a non-existent id

$params = { customer => 3 };
$cgi = $CGI->new($params);
ok !( %error_for = $cgi->errors ),
  'A brand new Class::CGI object should report no errors';
ok !$cgi->param('customer'),
  'Trying to fetch a value with a non-existent ID should fail';

ok my $error_for = $cgi->errors,
  '... and we should have the errors available';
is scalar keys %$error_for, 1,
  '... and they should be the correct number of errors';
like $error_for->{customer}, qr/^\QCould not find customer for (3)/,
  '... and the new error should be correct';

ok !$cgi->param('customer'),
  'Trying to refetch a value with a non-existent ID should fail';

ok $errors = $cgi->errors, '... and we should have the errors available';
is scalar keys %$errors, 1,
  '... and they should be the correct number of errors';
like $errors->{customer}, qr/^\QCould not find customer for (3)/,
  '... and the new error should be correct';

can_ok $cgi, 'clear_errors';
ok $cgi->clear_errors, '... and clearing the errors should be successful';
ok !( @errors = $cgi->errors ),
  '... and we should have no more errors reported';

can_ok $cgi, 'add_error';
ok $cgi->add_error( foo => 'this => that&' ),
  '... and setting an error should succeed';
my %errors = $cgi->errors;
ok my $foo_error = $errors{foo}, '... and the error should be present';
is $foo_error, 'this =&gt; that&amp;',
  '... and it should be properly encoded';

can_ok $cgi, 'error_encoding';
ok $cgi->error_encoding('<>'),
  '... and setting a new encoding should succeed';
ok $cgi->add_error( foo => 'this => that&' ),
  '... and setting an error should succeed';
%errors = $cgi->errors;
ok $foo_error = $errors{foo}, '... and the error should be present';
is $foo_error, 'this =&gt; that&',
  '... and it should respect the new encoding';
