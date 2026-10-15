#!/usr/bin/perl
use strict;
use warnings;

use Test::Most;

use_ok('Database::BI::Calc');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub ok_eval {
	my ($desc, $expr, $cols, $row, $expected) = @_;
	my $c = Database::BI::Calc->new(expr => $expr, columns => $cols // []);
	if ($c->has_error) {
		# If expected is undef and the test expects an error, that's fine.
		# But if expected is a value the test is wrong -- fail it.
		ok(!defined $expected, "$desc (compile error: " . $c->error . ')');
		return;
	}
	my $got = $c->evaluate($row // {});
	if (!defined $expected) {
		ok(!defined $got, "$desc -> undef");
	} else {
		is $got, $expected, $desc;
	}
}

sub ok_error {
	my ($desc, $expr, $cols) = @_;
	my $c = Database::BI::Calc->new(expr => $expr, columns => $cols // []);
	ok $c->has_error, "$desc -- has error";
	ok defined $c->error && length($c->error), "$desc -- error is non-empty";
}

# ---------------------------------------------------------------------------
# Arithmetic
# ---------------------------------------------------------------------------

subtest 'arithmetic' => sub {
	ok_eval 'add',           '2 + 3',          [],        {}, 5;
	ok_eval 'subtract',      '10 - 4',         [],        {}, 6;
	ok_eval 'multiply',      '3 * 4',          [],        {}, 12;
	ok_eval 'divide',        '10 / 4',         [],        {}, 2.5;
	ok_eval 'precedence',    '2 + 3 * 4',      [],        {}, 14;
	ok_eval 'parens',        '(2 + 3) * 4',    [],        {}, 20;
	ok_eval 'unary minus',   '-5 + 8',         [],        {}, 3;
	ok_eval 'unary plus',    '+5',             [],        {}, 5;
	ok_eval 'nested parens', '((2 + 3)) * 2',  [],        {}, 10;
	ok_eval 'div by zero',   '1 / 0',          [],        {}, undef;
	ok_eval 'non-numeric op','1 + "hello"',    [],        {}, undef;
};

# ---------------------------------------------------------------------------
# Comparison operators
# ---------------------------------------------------------------------------

subtest 'comparison' => sub {
	ok_eval 'eq num true',    'amount = 100',    ['amount'], {amount => 100},   1;
	ok_eval 'eq num false',   'amount = 99',     ['amount'], {amount => 100},   0;
	ok_eval 'neq true',       'amount != 99',    ['amount'], {amount => 100},   1;
	ok_eval 'neq false',      'amount != 100',   ['amount'], {amount => 100},   0;
	ok_eval 'lt true',        'qty < 10',        ['qty'],    {qty => 5},         1;
	ok_eval 'lt false',       'qty < 5',         ['qty'],    {qty => 5},         0;
	ok_eval 'le true eq',     'qty <= 5',        ['qty'],    {qty => 5},         1;
	ok_eval 'le true lt',     'qty <= 6',        ['qty'],    {qty => 5},         1;
	ok_eval 'le false',       'qty <= 4',        ['qty'],    {qty => 5},         0;
	ok_eval 'gt true',        'qty > 4',         ['qty'],    {qty => 5},         1;
	ok_eval 'gt false',       'qty > 5',         ['qty'],    {qty => 5},         0;
	ok_eval 'ge true eq',     'qty >= 5',        ['qty'],    {qty => 5},         1;
	ok_eval 'ge true gt',     'qty >= 4',        ['qty'],    {qty => 5},         1;
	ok_eval 'ge false',       'qty >= 6',        ['qty'],    {qty => 5},         0;

	# String comparison (case-insensitive)
	ok_eval 'eq str ci',      'cat = "NORTH"',   ['cat'],    {cat => 'north'},   1;
	ok_eval 'lt str',         'cat < "M"',       ['cat'],    {cat => 'apple'},   1;

	# Undef operands
	ok_eval 'cmp undef lhs',  'missing = 1',     ['missing'],{missing => undef}, undef;
};

# ---------------------------------------------------------------------------
# IF (short-circuit)
# ---------------------------------------------------------------------------

subtest 'if' => sub {
	ok_eval 'if true',         'if(1, 42, 0)',           [], {}, 42;
	ok_eval 'if false',        'if(0, 42, 99)',          [], {}, 99;
	ok_eval 'if short-circuit','if(0, 1/0, 42)',         [], {}, 42;
	ok_eval 'if comparison',   'if(qty > 0, 1, 0)',   ['qty'], {qty => 3}, 1;
	ok_eval 'if cmp false',    'if(qty > 0, 1, 0)',   ['qty'], {qty => 0}, 0;
	ok_eval 'if safe div',     'if(qty > 0, amount / qty, 0)',
		['qty', 'amount'], {qty => 5, amount => 100}, 20;
	ok_eval 'if div by zero guard',
		'if(qty > 0, amount / qty, 0)',
		['qty', 'amount'], {qty => 0, amount => 100}, 0;
};

# ---------------------------------------------------------------------------
# String functions
# ---------------------------------------------------------------------------

subtest 'string functions' => sub {
	ok_eval 'upper', 'upper(name)',  ['name'], {name => 'hello'}, 'HELLO';
	ok_eval 'lower', 'lower(name)',  ['name'], {name => 'HELLO'}, 'hello';
	ok_eval 'trim',  'trim(name)',   ['name'], {name => '  hi  '}, 'hi';
	ok_eval 'len',   'len(name)',    ['name'], {name => 'hello'}, 5;
	ok_eval 'concat','concat(a,b)',  ['a','b'],{a=>'foo',b=>'bar'}, 'foobar';
	ok_eval 'substr 2-arg', 'substr(name,2)', ['name'], {name=>'hello'}, 'llo';
	ok_eval 'substr 3-arg', 'substr(name,1,3)', ['name'], {name=>'hello'}, 'ell';
};

# ---------------------------------------------------------------------------
# Numeric functions
# ---------------------------------------------------------------------------

subtest 'numeric functions' => sub {
	ok_eval 'round 0dp', 'round(3.7)',        [], {}, 4;
	ok_eval 'round 2dp', 'round(3.14159, 2)', [], {}, 3.14;
	ok_eval 'floor',     'floor(3.9)',        [], {}, 3;
	ok_eval 'ceil',      'ceil(3.1)',         [], {}, 4;
	ok_eval 'abs neg',   'abs(-5)',           [], {}, 5;
	ok_eval 'abs pos',   'abs(5)',            [], {}, 5;
};

# ---------------------------------------------------------------------------
# Null-handling functions
# ---------------------------------------------------------------------------

subtest 'null handling' => sub {
	ok_eval 'isnull defined',  'isnull(v, 99)', ['v'], {v => 7},    7;
	ok_eval 'isnull undef',    'isnull(v, 99)', ['v'], {v => undef},99;
	ok_eval 'coalesce first',  'coalesce(a,b,99)', ['a','b'], {a=>1,b=>2}, 1;
	ok_eval 'coalesce second', 'coalesce(a,b,99)', ['a','b'], {a=>undef,b=>2}, 2;
	ok_eval 'coalesce fallback','coalesce(a,b,99)',['a','b'], {a=>undef,b=>undef}, 99;
};

# ---------------------------------------------------------------------------
# Date functions (ISO-8601 YYYY-MM-DD)
# ---------------------------------------------------------------------------

subtest 'date functions' => sub {
	my $row = { d => '2026-03-15' };
	ok_eval 'year',       'year(d)',       ['d'], $row, 2026;
	ok_eval 'month',      'month(d)',      ['d'], $row, 3;
	ok_eval 'day',        'day(d)',        ['d'], $row, 15;
	ok_eval 'quarter Q1', 'quarter(d)',    ['d'], $row, 1;
	ok_eval 'quarter Q3', 'quarter(d)',    ['d'], {d=>'2026-07-01'}, 3;
	ok_eval 'quarter Q4', 'quarter(d)',    ['d'], {d=>'2026-12-31'}, 4;
	ok_eval 'month_name', 'month_name(d)', ['d'], $row, 'March';
	ok_eval 'weekday Mon','weekday(d)',    ['d'], {d=>'2026-10-12'}, 1;
	ok_eval 'weekday Sun','weekday(d)',    ['d'], {d=>'2026-10-11'}, 7;
	ok_eval 'year undef', 'year(d)',       ['d'], {d=>'not-a-date'}, undef;
	ok_eval 'month undef','month(d)',      ['d'], {d=>''},            undef;

	# now() takes no arguments and returns today as YYYY-MM-DD.
	{
		my $c = Database::BI::Calc->new(expr => 'now()', columns => []);
		ok !$c->has_error, 'now() compiles';
		my $v = $c->evaluate({});
		like $v, qr/\A\d{4}-\d\d-\d\d\z/, 'now() returns YYYY-MM-DD';
	}
};

# ---------------------------------------------------------------------------
# bin() function
# ---------------------------------------------------------------------------

subtest 'bin function' => sub {
	ok_eval 'bin integer',   'bin(250, 100)',  [], {}, '[200,300)';
	ok_eval 'bin lo=0',      'bin(50, 100)',   [], {}, '[0,100)';
	ok_eval 'bin negative',  'bin(-50, 100)',  [], {}, '[-100,0)';
	ok_eval 'bin float',     'bin(1.5, 0.5)',  [], {}, '[1.5,2)';
	ok_eval 'bin zero width','bin(5, 0)',      [], {}, undef;
	ok_eval 'bin neg width', 'bin(5, -1)',     [], {}, undef;

	# Binary-inexact widths (TODO-1 regression guard): without the %.10g
	# normalisation, 0.3/0.1 == 2.9999... floors to 2, giving [0.2,0.3).
	ok_eval 'bin 0.3/0.1',   'bin(v, 0.1)',   ['v'], {v => 0.3}, '[0.3,0.4)';
	ok_eval 'bin 0.4/0.1',   'bin(v, 0.1)',   ['v'], {v => 0.4}, '[0.4,0.5)';
	ok_eval 'bin 0.7/0.1',   'bin(v, 0.1)',   ['v'], {v => 0.7}, '[0.7,0.8)';
	ok_eval 'bin 0/0.1',     'bin(v, 0.1)',   ['v'], {v => 0},   '[0,0.1)';
	ok_eval 'bin -0.3/0.1',  'bin(v, 0.1)',   ['v'], {v => -0.3},'[-0.3,-0.2)';
	ok_eval 'bin -100/100',  'bin(v, 100)',    ['v'], {v => -100},'[-100,0)';
};

# ---------------------------------------------------------------------------
# Column reference and whitelist
# ---------------------------------------------------------------------------

subtest 'column whitelist' => sub {
	ok_eval 'direct col',      'amount * 2',      ['amount'], {amount => 5}, 10;
	ok_eval 'space alias',     'per_unit_price',  ['Per Unit Price'],
		{'Per Unit Price' => 7}, 7;
	ok_eval 'multi underscore','account_number',  ['Account Number'],
		{'Account Number' => '12345'}, '12345';

	ok_error 'unknown col',    'foo',             [];
};

# ---------------------------------------------------------------------------
# Error cases -- compile-time
# ---------------------------------------------------------------------------

subtest 'compile errors' => sub {
	ok_error 'unknown function',  'nosuch(1)',         [];
	ok_error 'double equals',     'qty == 5',          ['qty'];
	ok_error 'expr too long',     'x' x 513,           ['x'];
	ok_error 'bad char',          'qty % 2',           ['qty'];
	ok_error 'unterminated str',  '"hello',            [];
	ok_error 'trailing junk',     '1 + 2 garbage',     [];
};

# ---------------------------------------------------------------------------
# Depth limit
# ---------------------------------------------------------------------------

subtest 'depth limit' => sub {
	# 25 levels of parentheses should exceed MAX_DEPTH (20)
	my $deep = ('(' x 25) . '1' . (')' x 25);
	ok_error 'depth exceeded', $deep, [];
};

# ---------------------------------------------------------------------------
# Security: hostile inputs must error, never execute
# ---------------------------------------------------------------------------

subtest 'security' => sub {
	my @hostile = (
		'0; system("rm -rf /")',
		'`id`',
		'${\ system("id")}',
		'eval("die")',
		'require POSIX',
		'BEGIN { die }',
		'__END__',
	);
	for my $h (@hostile) {
		my $c = Database::BI::Calc->new(expr => $h, columns => []);
		ok $c->has_error, "hostile input errors: $h";
	}
	# Confirm evaluate() returns undef rather than executing anything.
	my $c = Database::BI::Calc->new(expr => '2 + 2', columns => []);
	is $c->evaluate({}), 4, 'benign expression still works after hostile test';
};

done_testing();
