use Test::More tests => 16;
BEGIN { use_ok 'Acme::Opish' };

is_deeply enop('a'), 'opa',
    'single vowel word';

is_deeply enop('to'), 'topo',
    'single vowel terminating string';

is_deeply enop('bee'), 'bopee',
    'double vowel terminating string';

is_deeply enop('ye'), 'yope',
    'handle ye';

is_deeply enop('yellow'), 'yopellopow',
    'notice a non-vowel starting y';

is_deeply enop('Abc'), 'Opabc',
    'preserve ucfirst';

is_deeply enop('eg/test.txt'), 'eg/opish-test.txt',
    'convert eg/test.txt to eg/opish-test.txt';

ok -e 'eg/opish-test.txt',
    'eg/opish-test.txt was created';

is_deeply [enop('xe', 'ze')], [('xe', 'ze')],
    'notice the silent e';

my $n = no_silent_e();
ok defined $n,
    'no_silent_e succeeded';

is no_silent_e('xe', 'ze'), $n + 2,
    'added words to the OK list';

is_deeply [enop('xe', 'ze')], [('xope', 'zope')],
    'ignore the silent e';

my $m = has_silent_e('xe', 'ze');
ok $n == $m,
    'has_silent_e removed words from the OK list';

is_deeply [enop('xe', 'ze')], [('xe', 'ze')],
    'notice the silent e again';

is_deeply enop(-opish_prefix => 'ubb', 'Foo bar?'), 'Fubboo bubbar?',
    'set user defined prefix';
