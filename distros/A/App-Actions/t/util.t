use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use Test::Most;

use App::Actions::Util qw(load_yaml_mapping mapping normalize_step stringify trim);

delete local $ENV{ACTION_RUN_LANG};

my $dir = tempdir(CLEANUP => 1);

# _write
# Purpose:     Write a file into the test directory.
# Entry:       $name - the file name; $text - its contents.
# Exit status: Returns the path.
# Side effects: Creates the file.
sub _write {
	my ($name, $text) = @_;

	my $path = File::Spec->catfile($dir, $name);
	open my $handle, '>', $path or die "$path: $!";
	print {$handle} $text;
	close $handle;

	return $path;
}

subtest 'stringify writes values as a workflow sees them' => sub {
	is(stringify(undef), '', 'undef is empty');
	is(stringify('5.38'), '5.38', 'a string is itself');
	is(stringify(0), '0', 'zero is 0, not false');
	is(stringify(JSON::PP::true()), 'true', 'a JSON true is true');
	is(stringify(JSON::PP::false()), 'false', 'a JSON false is false');
	is(stringify({ b => 1, a => [ 2 ] }), '{"a":[2],"b":1}', 'a structure is canonical JSON');

	SKIP: {
		skip 'core booleans need Perl 5.36', 2 if $] < 5.036;
		is(stringify(!!1), 'true', 'a core true is true');
		is(stringify(!!0), 'false', 'a core false is false, not the empty string');
	}
};

subtest 'trim' => sub {
	is(trim("  a b \n"), 'a b', 'leading and trailing space goes');
	is(trim(undef), '', 'undef is empty');
	my $original = ' x ';
	trim($original);
	is($original, ' x ', 'the argument is not changed');
};

subtest 'mapping copies or refuses' => sub {
	my $source = { A => 1 };
	my $copy = mapping($source, ['where.workflow_env']);
	$copy->{B} = 2;
	is_deeply($source, { A => 1 }, 'the copy is a new hash');
	is_deeply(mapping(undef, ['where.workflow_env']), {}, 'undef is an empty mapping');
	throws_ok { mapping([1], ['where.job_env', { job => 'test' }]) }
		qr/^env of job 'test' must be a mapping/, 'a list is refused, naming the place';
	throws_ok { mapping('x', 'the thing') } qr/^the thing must be a mapping/, 'a place may be plain words';
};

subtest 'normalize_step checks the shape of a step' => sub {
	my $step = normalize_step({ run => 'make' }, ['where.job', { job => 'build' }]);
	is_deeply($step, { run => 'make', env => {}, with => {} }, 'env and with are always hashes');

	throws_ok { normalize_step('make', ['where.job', { job => 'build' }]) }
		qr/^A step in job 'build' is not a mapping/, 'a scalar step is refused';
	throws_ok { normalize_step({ run => 'x', env => [] }, ['where.job', { job => 'build' }]) }
		qr/^env of a step in job 'build' must be a mapping/, 'the nested place is rendered';
	throws_ok { normalize_step({ run => { oops => 1 } }, ['where.file', { file => 'a.yml' }]) }
		qr/^Step field 'run' in 'a\.yml' must be a string/, 'a nested run is refused';
	throws_ok { normalize_step({ if => [] , run => 'x' }, ['where.job', { job => 'j' }]) }
		qr/Step field 'if'/, 'if is checked for workflows too';
	throws_ok { normalize_step({ name => 'n' }, ['where.job', { job => 'j' }]) }
		qr/has neither 'run' nor 'uses'/, 'a step must do something';
};

subtest 'load_yaml_mapping' => sub {
	my $good = _write('good.yml', "a: 1\nb: 2\n");
	is_deeply(load_yaml_mapping($good, 'workflow'), { a => 1, b => 2 }, 'a mapping is returned');

	throws_ok { load_yaml_mapping(undef, 'workflow') } qr/^No workflow file given/, 'no path';
	throws_ok { load_yaml_mapping(undef, 'action') } qr/^No action metadata file given/, 'no path, action wording';
	throws_ok { load_yaml_mapping("$dir/absent.yml", 'workflow') } qr/^Workflow file '.*absent\.yml' does not exist/,
		'a missing file';
	throws_ok { load_yaml_mapping(_write('bad.yml', "a: [\n"), 'action') } qr/^Unable to parse action metadata/,
		'a parse error';
	throws_ok { load_yaml_mapping(_write('empty.yml', ''), 'workflow') } qr/^Workflow '.*' is empty/, 'an empty file';
	throws_ok { load_yaml_mapping(_write('list.yml', "- a\n"), 'workflow') } qr/must contain a YAML mapping/,
		'a list';
	throws_ok { load_yaml_mapping($good, 'recipe') } qr/^Invalid arguments to App::Actions::Util::load_yaml_mapping/,
		'an unknown kind is a programming error';
};

done_testing();
