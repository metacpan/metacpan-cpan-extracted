# -*- Mode: Perl; -*-

=head1 NAME

1_validate_12_change.t - Test CGI::Ex::Validate's ability to modify form fields

=cut

use strict;
use Test::More tests => 10;
use strict;

use_ok('CGI::Ex::Validate');
my $e;
my $v;
sub validate { scalar CGI::Ex::Validate::validate(@_) }


###----------------------------------------------------------------###

$v = {
  foo => {
    max_len => 10,
    replace => 's/[^\d]//g',
  },
};

$e = validate({
  foo => '123-456-7890',
}, $v);
ok(! $e, "Didn't get error");


my $form = {
  key1 => 'Bu-nch @of characte#rs^',
  key2 => '123 456 7890',
  key3 => '123',
};


$v = {
  key1 => {
    replace => 's/[^\s\w]//g',
  },
};

$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key1'}, 'Bunch of characters',  "key1 updated");

$v = {
  key2 => {
    replace => 's/(\d{3})\D*(\d{3})\D*(\d{4})/($1) $2-$3/g',
  },
};

$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key2'}, '(123) 456-7890', "Phone updated");

$v = {
  key2 => {
    replace => 's/.+//g',
    required => 1,
  },
};

$e = validate($form, $v);
ok($e, "Error");
is($form->{'key2'}, '', "All replaced");

$v = {
    key3 => {
        replace => 's/\d//',
    },
};
$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key3'}, '23', "Non-global is fine");
