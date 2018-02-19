use strict;
use warnings;

use Config::Dot;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $c = Config::Dot->new;
my $ret = $c->parse(<<'END');

# comment
=value
key=value
END
is_deeply(
	$ret,
	{
		'key' => 'value',
	},
	'Parse simple key, value pair.',
);

# Test.
$c->reset;
$ret = $c->parse(['key1=value1', 'key2=value2']);
is_deeply(
	$ret,
	{
		'key1' => 'value1',
		'key2' => 'value2',
	},
	'Parse key, value pairs from array reference.',
);

# Test.
$c->reset;
eval {
	$c->parse(';=');
};
is($EVAL_ERROR, "Bad key ';' in string ';=' at line '1'.\n",
	'Bad key.');
clean();

# Test.
$c->reset;
my $conflict = <<'END';
key=value
key=value
END
eval {
	$c->parse($conflict);
};
is($EVAL_ERROR, "Conflict in 'key'.\n",
	'Conflict in key \'key\', \'set_conflict\' = 1.');
clean();

# Test.
$c = Config::Dot->new(
	'set_conflicts' => 0,
);
is_deeply(
	$c->parse($conflict),
	{
		'key' => 'value',
	},
	'Conflict in key \'key\', \'set_conflict\' = 0.',
);

# Test.
$c = Config::Dot->new(
	'callback' => sub {
		my (undef, $val) = @_;
		if ($val == 1) {
			return 'XXX',
		}
		return $val;
	}
);
$ret = $c->parse(['key1=1', 'key2=2']);
is_deeply(
	$ret,
	{
		'key1' => 'XXX',
		'key2' => '2',
	},
	'Parsing with callback.',
);
