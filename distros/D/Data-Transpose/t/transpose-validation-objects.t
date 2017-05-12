use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More tests => 4;


my $dtv = Data::Transpose::Validator->new();
my $form = {};

$dtv->field(email => { required => 0 });
my $result = $dtv->transpose($form);
ok $result;

diag "Testing overriding with object method";
$dtv = Data::Transpose::Validator->new();
$dtv->field(email => { required => 0 })->required(1);
ok $dtv->field('email')->required; # return true
$result = $dtv->transpose({});
ok !$result;
$result = $dtv->transpose({ email => 'hello' });
ok $result;

