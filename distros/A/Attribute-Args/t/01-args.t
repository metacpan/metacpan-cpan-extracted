#!perl

use strict;
use Test::More qw/no_plan/;
use Attribute::Args;

sub t {
	my ($def, $par) = @_;
	eval { Attribute::Args::check($def, $par) };
	return $@;
}

ok !t [], [];
ok !t ['any'], [0];
ok !t ['scalar'], [0];
ok !t ['null'], [undef];
ok !t ['list'], [0];
ok !t ['HASH'], [{}];
ok !t ['scalar?'], [];
ok !t ['hash'], [0 => 0];
ok !t ['Attribute::Args'], [__PACKAGE__];

ok t [], [0];
ok t ['scalar'], [];
ok t ['scalar'], [{}];
ok t ['null'], [0];
ok t ['hash'], [0];
ok t ['foo'], [0];
ok t ['null', 'null'], [undef];

eval { sub foo :ARGS {} }; ok !$@;
eval { foo() }; ok !$@;
eval 'my $baz = sub :ARGS {}; &$baz();'; ok $@, $@;
eval { Attribute::Args::ARGS(__PACKAGE__, \*foo, \&foo, undef, 'null') }; ok !$@;
eval { Attribute::Args::ARGS(__PACKAGE__, \*foo, \&foo, undef, ['null']) }; ok !$@;
