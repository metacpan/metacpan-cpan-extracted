use strict;
use warnings;
use Test::More;

use_ok 'Catalyst::ActionRole::BuildDBICResult';

{
    package Test::Catalyst::ActionRole::BuildDBICResult;
    use Moose;
    with 'Catalyst::ActionRole::BuildDBICResult';
    sub name {'name'}
    sub attributes { +{}; }
    sub dispatch {}
}

ok my $defaults = Test::Catalyst::ActionRole::BuildDBICResult->new(),
  'all defaults';

is_deeply $defaults->store, {accessor=>'model_resultset'},
  'default store';

is_deeply $defaults->find_condition, [{constraint_name=>'primary'}],
  'default find_condition';

ok !$defaults->auto_stash, 'default auto_stash';

ok my $store_as_str = Test::Catalyst::ActionRole::BuildDBICResult->new(store=>'User'),
  'coerce store from string to model';

is_deeply $store_as_str->store, {model=>'User'},
  'store coerced to model=>User';

ok my $store_as_str_b = Test::Catalyst::ActionRole::BuildDBICResult->new(store=>'schema::user'),
  'coerce store from string to model';

is_deeply $store_as_str_b->store, {model=>'schema::user'},
  'store coerced to model=>schema::user';

ok my $store_as_str2 = Test::Catalyst::ActionRole::BuildDBICResult->new(store=>'user'),
  'coerce store from string to stash';

is_deeply $store_as_str2->store, {stash=>'user'},
  'store coerced to stash=>user';

ok my $store_as_str3 = Test::Catalyst::ActionRole::BuildDBICResult->new(store=>sub {'true'} ),
  'coerce store from string to stash';

my ($code, $ref) = %{$store_as_str3->store};
is $code, 'code', 'is code';
is ref($ref), 'CODE', 'is coderef';

ok my $store_as_str4 = Test::Catalyst::ActionRole::BuildDBICResult->new(store=> bless( {a=>1}, "FAKE::MOCK::BuildDBICResult") ),
  'coerce store from string to object';

my ($value, $obj) = %{$store_as_str4->store};
is $value, 'value', 'is value';
is ref($obj), 'FAKE::MOCK::BuildDBICResult', 'is object';

ok my $find_cond_as_str = Test::Catalyst::ActionRole::BuildDBICResult->new(find_condition=>'unique_email'),
  'coerce store from string';

is_deeply $find_cond_as_str->find_condition, [{constraint_name=>'unique_email'}],
  'find_condition coerced to constraint_name=>unique_email';

ok my $find_cond_as_cond = Test::Catalyst::ActionRole::BuildDBICResult->new(find_condition=>{constraint_name=>'social_security'}),
  'coerce store from string';

is_deeply $find_cond_as_cond->find_condition, [{constraint_name=>'social_security'}],
  'find_condition coerced to constraint_name=>social_security';

ok my $find_cond_as_cond2 = Test::Catalyst::ActionRole::BuildDBICResult->new(find_condition=>{columns=>['id']}),
  'coerce store from string';

is_deeply $find_cond_as_cond2->find_condition, [{columns=>['id']}],
  'find_condition coerced to columns=>id';

eval {
    Test::Catalyst::ActionRole::BuildDBICResult->new(find_condition=>{columns=>{a=>'id'}});
};

ok $@, 'got an error from columns=>HashRef as expected';

ok my $default_handler_type = Test::Catalyst::ActionRole::BuildDBICResult->new(handlers=>{found => 'fff'})->handlers,
  'Got default handlers';

is_deeply $default_handler_type, { found => { detach => "fff" } },
  'got expected coercion';

done_testing;
