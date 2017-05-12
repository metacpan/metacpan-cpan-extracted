#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use App::Sv;


subtest 'basic constructor' => sub {
	my $sm;

	is(exception { $sm = App::Sv->new({ run => { a => 'a' } }) },
		undef, 'new() lives with a simple command');
	ok($sm, '... got something back');
	is(ref($sm), 'App::Sv', '... of the proper type');
	cmp_deeply(
		$sm->{run}, 
		{
			a => {
				cmd => 'a',
				name => 'a',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1
			}
		},
		'... with the expected command list'
	);

	is(exception { $sm = App::Sv->new({ run => { a => [qw(a b c)] } }) },
		undef, 'new() lives with a simple array command');
	ok($sm, '... got something back');
	is(ref($sm), 'App::Sv', '... of the proper type');
	cmp_deeply(
		$sm->{run}, 
		{
			a => {
				cmd => ['a', 'b', 'c'],
				name => 'a',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1
			}
		},
		'... with the expected command list'
	);
	
	is(exception { $sm = App::Sv->new({
		run => { a => 'a', b => { cmd => 'b' } } }) },
		undef, 'new() lives with two commands, one simple, one complex');
	ok($sm, '... got something back');
	is(ref($sm), 'App::Sv', '... of the proper type');
	cmp_deeply($sm->{run},
		{
			a => {
				cmd => 'a',
				name => 'a',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1,
			},
			b => {
				cmd => 'b',
				name => 'b',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1
			}
		},
		'... with the expected command list'
	);
	
	my $a = sub {1};
	is(exception { $sm = App::Sv->new({ run => { a => $a } }) },
		undef, 'new() lives with a simple code ref');
	ok($sm, '... got something back');
	is(ref($sm), 'App::Sv', '... of the proper type');
	cmp_deeply(
		$sm->{run}, 
		{
			a => {
				code => $a,
				name => 'a',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1
			}
		},
		'... with the expected command list'
	);
	
	is(exception { $sm = App::Sv->new({ run => { a => [$a, 'b', 'c'] } }) },
		undef, 'new() lives with a array code ref');
	ok($sm, '... got something back');
	is(ref($sm), 'App::Sv', '... of the proper type');
	cmp_deeply(
		$sm->{run}, 
		{
			a => {
				code => [$a, 'b', 'c'],
				name => 'a',
				start_retries => 8,
				restart_delay => 1,
				start_wait => 1,
				stop_wait => 0,
				setsid => 1
			}
		},
		'... with the expected command list'
	);

	like(exception { App::Sv->new },
		qr{^Commands must be passed as a hash ref.*},
		'new() dies with no cmds list');
	like(exception { App::Sv->new(run => undef) },
		qr{^Commands must be passed as a hash ref.*},
		'new() dies with undef cmds list');
	like(exception { App::Sv->new({run => {}}) },
		qr{^Missing command list.*},
		'new() dies with empty run hash as hash');
	like(exception { App::Sv->new(run => {}) },
		qr{^Missing command list.*},
		'new() dies with empty run hash as list');
	like(exception { App::Sv->new(run => 'run', 'global') },
		qr{^Odd number of arguments to.*},
		'new() dies with odd number of args');
	like(exception { App::Sv->new(run => { a => undef }) },
		qr{^Missing command for 'a'.*},
		'new() dies with undef run key');
	like(exception { App::Sv->new(run => { a => [] }) },
		qr{^Missing command for 'a'.*},
		'new() dies with undef run list');
	like(exception { App::Sv->new(run => { a => { b => 'c' } }) },
		qr{^Missing command for 'a'.*},
		'new() dies with no cmd or code keys');
	my $b = 'c';
	$a = \$b;
	like(exception { App::Sv->new(run => { a => $a }) },
		qr{^Missing command for 'a'.*},
		'new() dies with bogus run hash');
};

done_testing();
