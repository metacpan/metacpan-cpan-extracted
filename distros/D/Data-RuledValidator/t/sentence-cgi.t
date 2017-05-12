use Test::More;

BEGIN {
  use_ok('Data::RuledValidator');
  $ENV{REQUEST_METHOD} = "GET";
  $ENV{QUERY_STRING} = "page=index&i=9&v=aaaaa&k=bbbb&m=1&m=2&m=4&m=5";
}

use CGI;

my $q = new CGI;
my $v = Data::RuledValidator->new(obj => $q, method => 'param');
ok(ref $v, 'Data::RuledValidator');
is($v->obj, $q);
is($v->method, 'param');

# correct rule
ok($v->by_sentence('page is word', 'i is num', 'v is word', 'k is word',  'i re ^\d+$', 'all = all of i, k, v', 'm has 4', 'm < 6', 'm > 0', 'all = all of-valid i, k, v'), 'by sentence');
ok($v->ok('page_is'), 'page_is');
ok($v->ok('i_is'), 'i_is');
ok($v->ok('i_re'), 'i_re');
ok($v->ok('k_is'), 'k_is');
ok($v->ok('all_of'), 'all_of');
ok($v->ok('page_valid'), 'page_valid');
ok($v->ok('i_valid'), 'i_valid');
ok($v->ok('k_valid'), 'k_valid');
ok($v->ok('all_valid'), 'all_valid');
ok($v->ok('m_has'), 'm_has');
ok($v->ok('m_<'), 'm_<');
ok($v->ok('m_>'), 'm_>');
ok($v->ok('all_of-valid'), 'all_of-valid');
ok($v->valid, 'valid');
# warn join "\n", @$v;
$v->reset;
ok(! $v, 'reseted valid; it should be undef');

# mistake rule
ok(not $v->by_sentence('page is num', 'i is num', 'v is num', 'k is num',  'v re ^\d+$', 'all = all of i, k, v, x'));
ok(not $v->ok('page_is'));
ok($v->ok('i_is'));
ok(not $v->ok('v_re'));
ok(not $v->ok('k_is'));
ok(not $v->ok('all_of'));
ok(not $v->ok('page_valid'));
ok(ok $v->ok('i_valid'));
ok(not $v->ok('k_valid'));
ok(not $v->ok('all_valid'));
ok(not $v->valid);
ok(! $v);

# create alias
Data::RuledValidator->create_alias_operator('isis', 'is');
Data::RuledValidator->create_alias_cond_operator('number2', 'num');
ok(not $v->by_sentence('page is num', 'i isis num', 'v is number2', 'k isis num', 'all = all of i, k, v, x'));
ok(not $v->ok('page_isis'));
ok($v->ok('i_isis'));
ok(not $v->ok('k_isis'));
ok(not $v->ok('all_of'));
ok(not $v->ok('page_valid'));
ok(ok $v->ok('i_valid'));
ok(not $v->ok('k_valid'));
ok(not $v->ok('all_valid'));
ok(not $v->valid);
ok(! $v);

=functions
add_operator
add_condition_operator
to_obj
id_key
result
reset
get_rule
by_rule
=cut

done_testing;
