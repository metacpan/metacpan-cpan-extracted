package MyConfig;
use strict;

use Config::ENV 'FOO_ENV';
use Test::More;
use Test::Name::FromLine;
use Test::Fatal;
use Errno ();
use File::Spec;

is int(do{local ($!, $@); eval{ load('unknown_file') }; $!}), Errno::ENOENT;
like exception { load('unknown_file') }, qr{\A.+ at .* line};
like exception { load('t/data/parse_error.pl') }, qr{syntax error at .* line 2, near ";;"};
like exception { load('t/data/no_values.pl') }, qr{\At/data/no_values.pl does not return HashRef.};
is exception { load('t/data/valid.pl') }, undef;

my $rel_path = 't/data/valid.pl';
my $abs_path = File::Spec->rel2abs($rel_path);

for my $path ($rel_path, $abs_path) {
	my $config = load($path);
	is_deeply $config, { foo => 'bar' };

	common +{
		name => 'foobar',
	};
	
	config development => load('t/data/development.pl');

	config production  => {
		foo => 'XXX',
		load('t/data/test.pl'),
		bar => 'YYY',
	};

	$ENV{FOO_ENV} = 'development';

	is +MyConfig->param('test'), 'development';

	$ENV{FOO_ENV} = 'production';

	is +MyConfig->param('test'), 'test';
	is +MyConfig->param('foo'), 'foo';
	is +MyConfig->param('bar'), 'YYY';
}

done_testing;
