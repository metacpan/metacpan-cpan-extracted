#$Id: 01_validate.t,v 1.1 2005/11/14 03:39:09 naoya Exp $
use strict;
use Test::More tests => 9;
use Acme::Web20::Validator;
use Acme::Web20::Validator::Rule;

my $url = 'http://www.cpan.org/';

my $validator = Acme::Web20::Validator->new;
my $rule = Acme::Web20::Validator::Rule->new;
my @rules = $rule->plugins;
ok(@rules);

$validator->add_rule(@rules);
is (scalar @rules, $validator->rules_size);

my @result = $validator->validate($url);

ok(@result);
is(scalar @result, $validator->rules_size);
isa_ok($result[0], 'Acme::Web20::Validator::Rule');
ok($validator->validation_report);
ok($validator->ok_count >= 0);
ok($validator->ok_count <= $validator->rules_size);

my $v = Acme::Web20::Validator->new;
$v->set_all_rules;
ok ($v->rules_size > 0);

