#!perl

use Test::More tests => 22;
#use Test::More qw/no_plan/;
use Test::Exception;
use strict;
use warnings;

use Class::CGI;

my $CLASS;

BEGIN {
    $CLASS = 'Class::CGI::Handler';
    use_ok $CLASS or die;
}

{

    package Faux::Handler;
    our @ISA = $CLASS;

    sub handle {
        my $self  = shift;
        my $cgi   = $self->cgi;
        my $param = $self->param;

        no warnings;
        return bless {
            $param  => $cgi->raw_param($param),
            handler => $self
          },
          'Correct';
    }
}

my $params = {
    customer => 2,
    email    => 'some@example.com',
    day      => 1,
    year     => 1999
};
my $cgi = Class::CGI->new($params);
$cgi->required(qw/date customer missing_parameter/);

# test that basic functionality works

can_ok 'Faux::Handler', 'new';
ok my $object = Faux::Handler->new( $cgi, 'customer' ),
  '... and calling the handler should succeed';
isa_ok $object, 'Correct', '... and the object it returns';

my $handler = $object->{handler};
can_ok $handler, 'cgi';
isa_ok $handler->cgi, 'Class::CGI', '... and the object it returns';
can_ok $handler, 'param';
is $handler->param, 'customer',
  '... and it should report the requested param';

can_ok $cgi, 'is_missing_required';
ok !$cgi->is_missing_required('customer'),
  '... and it should not report existing parameters as missing';
ok !$cgi->is_missing_required('unrequired_parameter'),
  '... nor should it report missing parameters if they are unrequired';
ok !$cgi->errors, '... and no errors should be reported';

can_ok $handler, 'has_virtual_param';
ok !$handler->has_virtual_param( date => qw/day month year/ ),
  '... and a virtual parameter missing a part should report itself as missing';
ok $cgi->is_missing_required('date'),
  '... and the CGI object should report it as missing';
ok my $errors = $cgi->errors, '... and we should have errors reported';
is $errors->{date}, "The &#39;date&#39; is missing values for (month)",
  '... with the correct error messages';
ok $handler->has_virtual_param( date => qw/day year/ ),
  '... and a virtual parameter with all its parts should report itself as present';

ok !( $object = Faux::Handler->new( $cgi, 'missing_parameter' ) ),
  'Trying to create an object from a missing parameter should fail';
ok $cgi->is_missing_required('missing_parameter'),
  '... and the parameter should be reported as missing';
ok $errors = $cgi->errors, '... and we should have errors reported';
is $errors->{missing_parameter},
  'You must supply a value for missing_parameter',
  '... with the correct error messages';
