use Test::Modern;

{ package
    MyParser;
  use List::Objects::WithUtils 'array';
  use Moo;
  has subject_list => (
    is => 'ro',
    builder => sub {
      array('nic base', 'flavor')
    },
  );
  with 'App::vaporcalc::Role::UI::ParseCmd';
}

my $cmdeng = MyParser->new;

my $res = $cmdeng->parse_cmd('view nic base');
cmp_ok $res->subject, 'eq', 'nic base', '2 word subj parsed ok';
cmp_ok $res->verb, 'eq', 'view', 'leading verb ok (2 word subj)';
ok $res->params->is_empty, 'params empty ok (2 word subj)';

$res = $cmdeng->parse_cmd('set nic base 100 foo');
cmp_ok $res->subject, 'eq', 'nic base', '2 word subj with params ok';
cmp_ok $res->verb, 'eq', 'set', 'leading verb ok (2 word subj with params)';
is_deeply 
  [ $res->params->all ],
  [ 100, 'foo' ],
  'params ok (2 word subj with params)';

$res = $cmdeng->parse_cmd('nic base view');
cmp_ok $res->subject, 'eq', 'nic base', '2 word subj with trailing verb ok';
cmp_ok $res->verb, 'eq', 'view', 'trailing verb ok (2 word subj)';
ok $res->params->is_empty, 'params empty ok (2 word subj with trailing verb)';

$res = $cmdeng->parse_cmd('nic base set 100 "foo"');
cmp_ok $res->subject, 'eq', 'nic base', 
  '2 word subj with trailing verb and params ok';
cmp_ok $res->verb, 'eq', 'set',
  'trailing verb ok (2 word subj with params)';
is_deeply
  [ $res->params->all ],
  [ 100, 'foo' ],
  'quoted params ok (2 word subj with trailing verb)';

$res = $cmdeng->parse_cmd('set flavor 100');
cmp_ok $res->subject, 'eq', 'flavor', 
  '1 word subj with leading verb and params ok';
cmp_ok $res->verb, 'eq', 'set', 'leading verb ok (1 word subj)';
is_deeply
  [ $res->params->all ],
  [ 100 ],
  'params ok (1 word subj with leading verb)';

$res = $cmdeng->parse_cmd('flavor set 100');
cmp_ok $res->subject, 'eq', 'flavor',
  '1 word subj with trailing verb and params ok';
cmp_ok $res->verb, 'eq', 'set', 'trailing verb ok (1 word subj)';
is_deeply
  [ $res->params->all ],
  [ 100 ],
  'params ok (1 word subj with trailing verb)';

$res = $cmdeng->parse_cmd('flavor');
cmp_ok $res->subject, 'eq', 'flavor',
  '1 word subj with no verb or params ok';
ok ! defined $res->verb, 'no verb defined ok';
ok $res->params->is_empty, 'params empty ok (no verb)';

$res = $cmdeng->parse_cmd('nic base');
cmp_ok $res->subject, 'eq', 'nic base',
  '2 word subj with no verb or params ok';
ok ! defined $res->verb, 'no verb defined ok';
ok $res->params->is_empty, 'params empty ok (no verb)';

like exception {; $cmdeng->parse_cmd('bar') },
  qr/No subject/, 
  'no subject dies ok';

like exception {; $cmdeng->parse_cmd('.nic base ') },
  qr/No subject/, 
  'leading garbage dies ok';

like exception {; $cmdeng->parse_cmd('nic base.') },
  qr/No subject/, 
  'trailing garbage dies ok';

done_testing;
