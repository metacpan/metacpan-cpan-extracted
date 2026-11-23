#!/usr/bin/env perl

# JSON Lines (.jsonl, .ndjson), dot-path flattening of nested objects, and the
# streaming read of a big list of objects.  DataSource writes the flat copy
# that Database::Abstraction reads, so these check what that copy holds, the
# column order, the errors, and the routes that reach it.
#
#   prove -l t/jsonl.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::JSON qw(encode_json);
use Readonly;

Readonly my $BIG_ROWS    => 20_000;	# with the padding, past the 16 MiB stream threshold
Readonly my $BIG_PADDING => 900;

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require Database::BI::Model::DataSource;
my $DS = 'Database::BI::Model::DataSource';

# one_file($name, $text) -> $dir: a folder of its own, since a stem is a table.
sub one_file {
	my ($name, $text) = @_;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new($dir, $name)->spew($text);
	return $dir;
}

sub source {
	my ($dir, $stem, %opt) = @_;
	return $DS->new(directory => $dir, table => $stem, %opt);
}

sub rows_by_id {
	my ($source) = @_;
	return { map { $_->{id} => $_ } @{ $source->fetch_all } };
}

Readonly my $PEOPLE => <<'END';
{"id":1,"name":"Ann","address":{"city":"York","geo":{"lat":1.5}},"tags":["a","b"],"ok":true}

{"id":2,"name":"Bob","address":{"city":"Leeds"},"extra":null}
END

subtest 'JSON Lines is a table' => sub {
	for my $ext (qw(jsonl ndjson)) {
		my $source = source(one_file("people.$ext", $PEOPLE), 'people');
		is_deeply($source->columns, [qw(id name address tags ok extra)], "$ext: columns in the order the lines name them");
		my $rows = rows_by_id($source);
		is(scalar keys %{$rows}, 2, "$ext: the blank line is no row");
		is($rows->{1}{name}, 'Ann', "$ext: a cell");
		is($rows->{1}{address}, '{"city":"York","geo":{"lat":1.5}}', "$ext: a nested object is its JSON text");
		is($rows->{1}{tags}, '["a","b"]', "$ext: a list is its JSON text");
		is($rows->{1}{ok}, 'true', "$ext: true is the word");
	}
};

subtest 'CRLF, a BOM, and no final newline' => sub {
	my $text = "\xEF\xBB\xBF" . join("\r\n", '{"id":1,"n":"a"}', '{"id":2,"n":"b"}');
	my $rows = rows_by_id(source(one_file('crlf.jsonl', $text), 'crlf'));
	is_deeply([ map { $rows->{$_}{n} } 1, 2 ], [qw(a b)], 'both lines read');
};

subtest 'a line that is not an object, or not JSON, is refused with its number' => sub {
	throws_ok { source(one_file('bad.jsonl', qq({"id":1}\n{"id":\n)), 'bad') }
		qr/is not valid JSON: line 2:/, 'bad JSON names the line';
	throws_ok { source(one_file('arr.jsonl', qq({"id":1}\n[1,2]\n)), 'arr') }
		qr/holds no table/, 'an array line';
	throws_ok { source(one_file('num.ndjson', qq(1\n2\n)), 'num') }
		qr/holds no table/, 'a number line';
};

subtest 'an empty or blank JSON Lines file is an empty table' => sub {
	for my $text ('', "\n  \n") {
		my $source = source(one_file('empty.jsonl', $text), 'empty');
		is_deeply($source->fetch_all, [], 'no rows');
	}
};

subtest 'a .json beside a .jsonl of the same name wins; a .csv beats both' => sub {
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new($dir, 'x.jsonl')->spew(qq({"id":1,"v":"lines"}\n));
	Mojo::File->new($dir, 'x.json')->spew('[{"id":1,"v":"json"}]');
	is(source($dir, 'x')->fetch_all->[0]{v}, 'json', '.json');
	Mojo::File->new($dir, 'x.csv')->spew("id,v\n1,csv\n");
	is(source($dir, 'x')->fetch_all->[0]{v}, 'csv', '.csv');
};

subtest 'flattening is off unless asked' => sub {
	my $source = source(one_file('people.jsonl', $PEOPLE), 'people');
	ok(!(grep { /\./ } @{ $source->columns }), 'no dotted column');
};

subtest 'dot-path flattening of JSON Lines' => sub {
	my $source = source(one_file('people.jsonl', $PEOPLE), 'people', json_flatten => 1);
	is_deeply($source->columns, [qw(id name address.city address.geo.lat tags ok extra)],
		'paths in the order the text names them; the objects that hold them are not columns');
	my $rows = rows_by_id($source);
	is($rows->{1}{'address.city'}, 'York', 'one level');
	is($rows->{1}{'address.geo.lat'}, 1.5, 'two levels');
	is($rows->{1}{tags}, '["a","b"]', 'a list stays text');
	is($rows->{2}{'address.city'}, 'Leeds', 'a row with fewer keys');
};

subtest 'flattening a .json list, an object of objects, and a list under a key' => sub {
	my $list = source(one_file('l.json', '[{"id":1,"a":{"b":2,"c":{"d":3}}}]'), 'l', json_flatten => 1);
	is_deeply($list->columns, [qw(id a.b a.c.d)], 'list of objects');
	is($list->fetch_all->[0]{'a.c.d'}, 3, 'deep value');

	my $keyed = source(one_file('k.json', '{"x":{"p":{"q":1}},"y":{"p":{"q":2}}}'), 'k', json_flatten => 1);
	is_deeply($keyed->columns, [qw(id p.q)], 'object of objects: the key column first');

	my $under = source(one_file('u.json', '{"n":1,"items":[{"id":1,"m":{"z":9}}]}'), 'u', json_flatten => 1);
	is_deeply($under->columns, [qw(id m.z)], 'list under a key');
};

subtest 'an empty object, and a key that is already a path' => sub {
	my $empty = source(one_file('e.jsonl', qq({"id":1,"o":{}}\n)), 'e', json_flatten => 1);
	is($empty->fetch_all->[0]{o}, '{}', 'an empty object is a cell of its own');

	my $clash = source(one_file('c.jsonl', qq({"id":1,"a.b":"literal","a":{"b":"nested"}}\n)), 'c', json_flatten => 1);
	my $row = $clash->fetch_all->[0];
	is_deeply([ sort grep { /^a/ } keys %{$row} ], ['a.b', 'a.b_'], 'neither cell is lost');
	is_deeply([ sort @{$row}{'a.b', 'a.b_'} ], [qw(literal nested)], 'both values kept');
};

subtest 'a big list of objects is streamed and reads the same' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = Mojo::File->new($dir, 'big.json');
	open my $fh, '>:raw', "$path" or die $!;
	print {$fh} "  [\n";
	for my $i (1 .. $BIG_ROWS) {
		# Brackets, braces, quotes and an escaped quote inside strings, to cross
		# every chunk boundary with something a bracket counter must skip.
		my $note = qq(}]{["\\\\" ) . ('x' x $BIG_PADDING);
		# Written by hand: encode_json has no key order, and the columns do.
		print {$fh} '{"id":', $i, ',"note":', encode_json($note), ',"nest":{"k":', $i, '}}', ($i < $BIG_ROWS ? ",\n" : "\n");
	}
	print {$fh} "]\n";
	close $fh;
	cmp_ok(-s "$path", '>', 16 * 1_048_576, 'the file is past the streaming size');

	my $source = source($dir, 'big', json_flatten => 1);
	is_deeply($source->columns, [qw(id note nest.k)], 'columns');
	my $rows = $source->fetch_all;
	is(scalar @{$rows}, $BIG_ROWS, 'every row');
	my %by = map { $_->{id} => $_ } @{$rows};
	is($by{$BIG_ROWS}{'nest.k'}, $BIG_ROWS, 'the last row');
	like($by{777}{note}, qr/\A\}\]\{\["\\\\" x{$BIG_PADDING}\z/, 'a note with brackets is whole');
};

subtest 'a streamed list that is not a list of objects is refused' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = Mojo::File->new($dir, 'bad.json');
	open my $fh, '>:raw', "$path" or die $!;
	print {$fh} '[', join(',', map { qq({"id":$_,"p":") . ('x' x 1000) . '"}' } 1 .. 17_000), ",5]\n";
	close $fh;
	throws_ok { source($dir, 'bad') } qr/holds no table/, 'a number in the list';
};

subtest 'a streamed list that is not closed is refused' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = Mojo::File->new($dir, 'open.json');
	open my $fh, '>:raw', "$path" or die $!;
	print {$fh} '[', join(',', map { qq({"id":$_,"p":") . ('x' x 1000) . '"}' } 1 .. 17_000), "\n";
	close $fh;
	throws_ok { source($dir, 'open') } qr/is not valid JSON: the list is not closed/, 'no closing bracket';
};

subtest 'a file with another name is told apart by its lines' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $lines = Mojo::File->new($dir, 'a.log');
	$lines->spew(qq({"id":1}\n{"id":2}\n));
	is(Database::BI::Model::DataSource::_sniff_data_ext("$lines"), 'jsonl', 'one object a line');
	my $one = Mojo::File->new($dir, 'b.log');
	$one->spew(qq({\n  "id": 1\n}\n));
	is(Database::BI::Model::DataSource::_sniff_data_ext("$one"), 'json', 'one object over lines');
	my $single = Mojo::File->new($dir, 'c.log');
	$single->spew(qq({"id":1}\n));
	is(Database::BI::Model::DataSource::_sniff_data_ext("$single"), 'json', 'a lone object');
};

subtest 'the pages open a JSON Lines file, flattened by config' => sub {
	my $dir = one_file('people.jsonl', $PEOPLE);
	my $app = Test::Mojo->new('Database::BI', {
		data_dir => $dir, model_dir => tempdir(CLEANUP => 1), json_flatten => 1,
	});
	$app->get_ok('/')->status_is(200)->content_like(qr/people/, 'the home page lists it');
	$app->get_ok('/view/people')->status_is(200)
		->content_like(qr/address\.city/, 'a dotted column')
		->content_like(qr/<td[^>]*>York<\/td>/, 'its value');
	$app->get_ok('/export?l=table:people&format=json&f=address.city:eq:Leeds')->status_is(200);
	is_deeply([ map { $_->{id} } @{ $app->tx->res->json } ], [2], 'a filter on a dotted column');

	my $plain = Test::Mojo->new('Database::BI', { data_dir => $dir, model_dir => tempdir(CLEANUP => 1) });
	$plain->get_ok('/view/people')->status_is(200)->content_unlike(qr/address\.city/, 'not flattened without the setting');
};

done_testing();
