#!perl

# White-box tests for App::Access2CSV::Exporter::_csv_filename, which is
# protected, so access checks are bypassed explicitly

use strict;
use warnings;

use Test::Most;

use App::Access2CSV::Exporter;

$Sub::Private::BYPASS = 1;
$Sub::Protected::BYPASS = 1;

subtest 'unsafe characters become underscores and names stay unique' => sub {
	my $e = App::Access2CSV::Exporter->new();

	is($e->_csv_filename('Customer/Orders'), 'Customer_Orders.csv', 'slash replaced');
	is($e->_csv_filename('Customer:Orders'), 'Customer_Orders_2.csv', 'collision gets _2');
	is($e->_csv_filename('Customer?Orders'), 'Customer_Orders_3.csv', 'next collision gets _3');
};

subtest 'a table literally called X_2 does not overwrite a suffixed name' => sub {
	my $e = App::Access2CSV::Exporter->new();

	is($e->_csv_filename('A/B'), 'A_B.csv');
	is($e->_csv_filename('A:B'), 'A_B_2.csv');
	is($e->_csv_filename('A_B_2'), 'A_B_2_2.csv', 'real "A_B_2" table does not clash with A_B_2.csv');
};

subtest 'collisions are detected case-insensitively' => sub {
	my $e = App::Access2CSV::Exporter->new();

	is($e->_csv_filename('Orders'), 'Orders.csv');
	is($e->_csv_filename('ORDERS'), 'ORDERS_2.csv', 'differs only by case');
};

subtest 'awkward names' => sub {
	my $e = App::Access2CSV::Exporter->new();

	is($e->_csv_filename(''), 'unnamed.csv', 'empty name');
	is($e->_csv_filename('   '), 'unnamed_2.csv', 'whitespace only');
	is($e->_csv_filename('  Padded  '), 'Padded.csv', 'whitespace trimmed');
	is($e->_csv_filename('Trailing.'), 'Trailing.csv', 'trailing dot dropped');
	is($e->_csv_filename('.hidden'), '_hidden.csv', 'no hidden files');
	is($e->_csv_filename('CON'), '_CON.csv', 'Windows device name');
	is($e->_csv_filename('lpt1'), '_lpt1.csv', 'device names are case-insensitive');
	is($e->_csv_filename("Tab\tNew\nLine"), 'Tab_New_Line.csv', 'control characters');
	is($e->_csv_filename(undef), 'unnamed_3.csv', 'undef treated as empty');
};

subtest 'unicode names are kept' => sub {
	my $e = App::Access2CSV::Exporter->new();

	# As UTF-8 bytes (the form mdbtools gives) and as a character string.
	# A plain "Caf\x{e9}" is neither: Perl keeps it as the Latin-1 byte
	# E9, which is not UTF-8, so it becomes "_" (see t/domain.t)
	is($e->_csv_filename("Caf\xC3\xA9"), "Caf\xC3\xA9.csv", 'non-ASCII UTF-8 bytes are not mangled');
	my $chars = "Gr\x{fc}\x{df}e";
	utf8::upgrade($chars);
	is($e->_csv_filename($chars), "$chars.csv", 'non-ASCII characters are not mangled');
};

subtest 'the fast suffix search chooses exactly what the simple one did' => sub {
	# Reference model: the original algorithm, which tried _2, _3, ... from
	# the start every time.  The optimised version remembers where each
	# name's search ended; it must never choose a different name.
	my $reference = sub {
		my ($used, $name) = @_;
		my $file = "$name.csv";
		for(my $n = 2; exists $used->{lc $file}; $n++) {
			$file = "${name}_$n.csv";
		}
		$used->{lc $file} = 1;
		return $file;
	};

	# Random sequences built from names that collide in every way:
	# repeats, case variants, and literal names that look like suffixes
	my @pool = ('X', 'x', 'X_2', 'x_3', 'X_2_2', 'Y', 'X_10', 'X_2.csv');
	srand(20260928);
	foreach my $round (1 .. 1000) {
		my @names = map { $pool[int(rand(@pool))] } 1 .. 1 + int(rand(30));
		my $e = App::Access2CSV::Exporter->new();
		my %model;
		my @got = map { $e->_csv_filename($_) } @names;
		my @want = map { $reference->(\%model, $_) } @names;
		if(!is_deeply(\@got, \@want, "round $round")) {
			diag("names: @names");
			last;
		}
	}

	# And after a reset, the remembered positions are forgotten too
	my $e = App::Access2CSV::Exporter->new();
	$e->_csv_filename('X') for 1 .. 5;
	$e->_reset_names();
	is($e->_csv_filename('X') . ' ' . $e->_csv_filename('X'), 'X.csv X_2.csv', 'reset starts again from _2');
};

done_testing();
