# -*- Mode: Perl; -*-

=head1 NAME

1_validate_00_base.t - Test CGI::Ex::Validate's ability to compile and execute

=cut

use strict;
use Test::More tests => 5;

use_ok('CGI::Ex::Validate');

my $form = {
  user => 'abc',
  pass => '123',
};
my $val = {
  user => {
    required => 1,
  },
  pass => {
    required => 1,
  },
};

my $err_obj = CGI::Ex::Validate::validate($form, $val);
ok(! $err_obj, "Basic function works");

###----------------------------------------------------------------###

$form = {
  user => 'abc',
#  pass => '123',
};

$err_obj = CGI::Ex::Validate::validate($form,$val);

ok($err_obj, "Successfully failed");

###----------------------------------------------------------------###

eval { CGI::Ex::Validate::validate($form,undef) };
ok($@, "Needs to have a hashref");

###----------------------------------------------------------------###

$err_obj = CGI::Ex::Validate::validate($form,{});

ok(!$err_obj, "OK with empty hash");
