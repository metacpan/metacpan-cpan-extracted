
use Test::More tests => 8;

BEGIN { use_ok('Data::Template'); }

# SYNOPSIS

$dt = Data::Template->new();
ok($dt, "new() works");

is($dt->process('foo'), 'foo', 'strings pass through');
is($dt->process_s('To ${who}', { who => 'you' }), 'To you', 'simple interpolation');
is($dt->process_s('= x*y'), '= x*y', 'escaping prefix');

$tt = {
  who => 'me',
  to => '${a}',
  subject => 'Important - trust me',
        body => <<'BODY',

        When I was ${b}, I realized that
        I had not ${c}. Do you?
BODY
};
$vars = { a => 'someone', b => 'somewhere', c => '$100' };

$data = $dt->process($tt, $vars);
$expected = {
  who => 'me',
  to => 'someone',
  subject => 'Important - trust me',
        body => <<'BODY',

        When I was somewhere, I realized that
        I had not $100. Do you?
BODY
};
is_deeply($data, $expected);

$tt = {
  who => 'me',
  to => '${a}',
  subject => 'Important - trust me',
        body => <<'BODY',

        When I was ${b}, I realized that
        I had not ${c}. Do you?
BODY
};
$vars = { a => 'someone', b => 'somewhere', c => '$100' };

is_deeply($dt->process([ 1, 2, 3]), [ 1, 2, 3], 'raw arrays work');
is_deeply($dt->process([ qw(${foo} bar =tru) ], { foo => 'FOO', bar => 'BAR', true => 'TRU' }), 
          [ qw(FOO bar =tru) ], 
          'simple arrays work');
