#!perl -T

use Test::More tests => 11;

#use Test::More qw/no_plan/;
use Test::Exception;
use Scalar::Util qw/tainted/;

use Class::CGI handlers => {
    email => 'Class::CGI::Email::Valid',
};

# test that basic functionality works

my $params = { email => 'some@example.com' };

my $cgi = Class::CGI->new($params);
$cgi->required('email');
is $cgi->param('email'), 'some@example.com',
  'We should be able to fetch a valid email';
ok !$cgi->is_missing_required('email'),
  '... and it should not be reported as missing';
ok !$cgi->errors, '... and no errors should be reported';

# test a bogus email

$params = { email => 'some@example@com' };

$cgi = Class::CGI->new($params);
$cgi->required('email');
is $cgi->param('email'), 'some@example@com',
  'We should be able to fetch a bogus email';
ok !$cgi->is_missing_required('email'),
  '... and it should not be reported as missing';
ok my $error = $cgi->errors,
  '... but an invalid address should report an error';
is $error->{email}, 'The email address did not appear to be valid',
  '... with the correct error message';

# test a missing email

$cgi = Class::CGI->new({});
$cgi->required('email');
ok !defined $cgi->param('email'),
  'We should not be able to fetch a missing email';
ok $cgi->is_missing_required('email'),
  '... and it should be reported as missing';
ok $error = $cgi->errors,
  '... but an invalid address should report an error';
is $error->{email}, 'You must supply a value for email',
  '... with the correct error message';
