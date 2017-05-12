# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $c = Config::Dot::Array->new;
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

# Test.
clean();
$c->reset;
my $multiple = <<'END';
key=value1
key=value2
END
$ret = $c->parse($multiple);
is_deeply(
	$ret,
	{
		'key' => ['value1', 'value2'],
	},
);

# Test.
$c = Config::Dot::Array->new(
	'callback' => sub {
		my (undef, $val) = @_;
		if ($val == 1) {
			return 'XXX',
		}
		return $val;
	}
);
$ret = $c->parse(['key1=1', 'key2=2', 'key2=1']);
is_deeply(
	$ret,
	{
		'key1' => 'XXX',
		'key2' => ['2', 'XXX'],
	},
	'Parsing with callback.',
);
