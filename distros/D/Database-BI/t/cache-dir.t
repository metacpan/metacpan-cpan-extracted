#!/usr/bin/env perl

# Where a cache keeps its files: Database::BI::CacheDir::resolve and the
# objects that ask it (Geocode->new, the app's table cache).

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Mojo;
use Test::Most;

use Database::BI::CacheDir;

# Nothing from this machine's settings: no CACHEDIR, no Object::Configure
# environment variables, no config file in the current folder.
delete local @ENV{qw(CACHEDIR CACHE_DIR Database__BI__Model__Geocode__cache_dir Database__BI__cache_dir Database__BI__Extract__cache_dir)};
my $cwd_dir = tempdir(CLEANUP => 1);
local $ENV{MOJO_CONFIG} = File::Spec->catfile($cwd_dir, 'none.conf');

my $R = \&Database::BI::CacheDir::resolve;
my $G = 'Database::BI::Model::Geocode';

subtest 'the order: Object::Configure, CACHEDIR, CACHE_DIR, config, default' => sub {
	my %base = (class => 'Local::Cached', config => { cache_dir => '/from/config' }, home => '/home', default => '/the/default');

	is $R->(%base, config => {}), '/the/default', 'nothing set: the default';
	is $R->(%base), '/from/config', 'config before the default';

	local $ENV{CACHE_DIR} = '/from/cache_dir';
	is $R->(%base), '/from/cache_dir', 'CACHE_DIR before config';

	local $ENV{CACHEDIR} = '/from/cachedir';
	is $R->(%base), '/from/cachedir', 'CACHEDIR before CACHE_DIR';

	is $R->(%base, params => { cache_dir => '/from/new' }), '/from/new',
		'a cache_dir given to new() goes through Object::Configure, before the environment';

	local $ENV{Local__Cached__cache_dir} = '/from/object-configure';
	is $R->(%base, params => { cache_dir => '/from/new' }), '/from/object-configure',
		"Object::Configure's own environment variable wins over the argument, as it always does";

	local $ENV{CACHEDIR} = '';
	local $ENV{CACHE_DIR} = '';
	delete local $ENV{Local__Cached__cache_dir};
	is $R->(%base), '/from/config', 'an empty variable is not set';
};

subtest 'a relative cache_dir in the config is under the home' => sub {
	is $R->(config => { cache_dir => 'cache' }, home => '/srv/bi'),
		File::Spec->catdir('/srv/bi', 'cache'), 'relative: under home';
	is $R->(config => { cache_dir => '/abs' }, home => '/srv/bi'), '/abs', 'absolute: as given';
};

subtest 'no default and nothing set: undef' => sub {
	is $R->(class => 'Local::Cached', config => {}), undef, 'undef';
};

subtest 'without a config, database_bi.conf is read' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'database_bi.conf');
	open my $fh, '>', $file or die "$file: $!";
	print {$fh} "{ cache_dir => 'kept' }\n";
	close $fh;

	local $ENV{MOJO_CONFIG} = $file;
	is $R->(class => 'Local::Cached'), Mojo::File->new($dir, 'kept')->to_string,
		'MOJO_CONFIG names the file; a relative cache_dir is beside it';
	is $R->(class => 'Local::Cached', config => undef, default => '/d'), '/d',
		'a config given (even undef) is used instead of the file';
};

subtest 'Geocode->new keeps its answers where resolve says' => sub {
	require Database::BI::Model::Geocode;

	my $model = tempdir(CLEANUP => 1);
	my $geo   = $G->new(model_dir => $model, config => {});
	is $geo->{cache_dir}, File::Spec->catdir($model, 'geocode-cache'), 'default: <model_dir>/geocode-cache';
	isa_ok $geo->{cache}, 'CHI::Driver', 'a CHI cache';
	$geo->{cache}->set(k => 'v');
	ok -d $geo->{cache_dir}, 'its files are there';

	my $env = tempdir(CLEANUP => 1);
	local $ENV{CACHEDIR} = $env;
	$geo = $G->new(model_dir => $model, config => {});
	is $geo->{cache_dir}, $env, 'CACHEDIR before the default';

	my $oc = tempdir(CLEANUP => 1);
	local $ENV{Database__BI__Model__Geocode__cache_dir} = $oc;
	is $G->new(model_dir => $model)->{cache_dir}, $oc, 'Object::Configure first';

	my $mine = { };
	$geo = $G->new(cache => $mine, model_dir => $model);
	is $geo->{cache}, $mine, 'a cache given is used as it is';
	is $geo->{cache_dir}, undef, 'and no directory is chosen';

	delete local @ENV{qw(CACHEDIR Database__BI__Model__Geocode__cache_dir)};
	$geo = $G->new(config => {});
	is $geo->{cache_dir}, undef, 'nothing set and no model_dir: no directory';
	is $geo->{cache}, undef, '... and the process-wide memory cache is used';
};

subtest "the map page's geocoder reads cache_dir from database_bi.conf" => sub {
	my $model = tempdir(CLEANUP => 1);
	my $kept  = tempdir(CLEANUP => 1);
	my $t     = Test::Mojo->new('Database::BI', { model_dir => $model, cache_dir => $kept });
	my $c     = Database::BI::Controller::Dashboard->new(app => $t->app);

	local $ENV{HARNESS_ACTIVE} = 1;
	my $geo = Database::BI::Controller::Dashboard::_map_geocoder($c, 1);
	is $geo->{cache_dir}, $kept, 'config cache_dir';

	$t = Test::Mojo->new('Database::BI', { model_dir => $model });
	$geo = Database::BI::Controller::Dashboard::_map_geocoder(Database::BI::Controller::Dashboard->new(app => $t->app), 1);
	is $geo->{cache_dir}, File::Spec->catdir($model, 'geocode-cache'), 'else <model_dir>/geocode-cache, as before';
};

subtest 'a table cache on disc is given a directory' => sub {
	my $model = tempdir(CLEANUP => 1);
	my $t     = Test::Mojo->new('Database::BI', { model_dir => $model });
	my @args  = Database::BI::_table_cache_root($t->app, { driver => 'File' });
	is_deeply \@args, [ root_dir => Mojo::File->new($model, 'cache')->to_string ], 'File: <model_dir>/cache';

	my $kept = tempdir(CLEANUP => 1);
	local $ENV{CACHE_DIR} = $kept;
	is_deeply [ Database::BI::_table_cache_root($t->app, { driver => 'File' }) ], [ root_dir => $kept ],
		'CACHE_DIR before it';
	is_deeply [ Database::BI::_table_cache_root($t->app, { driver => 'File', root_dir => '/r' }) ], [ root_dir => '/r' ],
		'cache => { root_dir } names it outright';
	is_deeply [ Database::BI::_table_cache_root($t->app, {}) ], [], 'Memory: no directory';
};

subtest 'extracts: in <model_dir>/extracts, or database-bi-extracts in the cache directory' => sub {
	require Database::BI::Extract;
	my $X     = 'Database::BI::Extract';
	my $model = tempdir(CLEANUP => 1);

	is $X->new(model_dir => $model, config => {})->dir, Mojo::File->new($model, 'extracts')->to_string,
		'nothing set: <model_dir>/extracts, as before';

	my $conf = tempdir(CLEANUP => 1);
	is $X->new(model_dir => $model, config => { cache_dir => $conf })->dir,
		Mojo::File->new($conf, 'database-bi-extracts')->to_string, 'config cache_dir: a folder of its own in it';

	my $env = tempdir(CLEANUP => 1);
	local $ENV{CACHE_DIR} = $env;
	my $x = $X->new(model_dir => $model, config => { cache_dir => $conf });
	is $x->dir, Mojo::File->new($env, 'database-bi-extracts')->to_string, 'CACHE_DIR before config';

	# evict() removes every .db where the extracts are: never another program's.
	my $theirs = File::Spec->catfile($env, 'theirs.db');
	open my $fh, '>', $theirs or die "$theirs: $!";
	close $fh;
	my $p = $x->put('table:t', 1, 1, 'bytes');
	ok -f $p, 'an extract is written';
	is $x->get('table:t', 1, 1), $p, 'and found';
	is $x->evict, 1, 'evict removes the extract';
	ok -f $theirs, "and leaves the cache directory's other files alone";

	my $oc = tempdir(CLEANUP => 1);
	local $ENV{Database__BI__Extract__cache_dir} = $oc;
	is $X->new(model_dir => $model)->dir, Mojo::File->new($oc, 'database-bi-extracts')->to_string,
		'Object::Configure first';

	delete local @ENV{qw(CACHE_DIR Database__BI__Extract__cache_dir)};
	throws_ok { $X->new(config => {}) } qr/model_dir is required/, 'no model_dir and nothing set: refused';
	is $X->new(config => { cache_dir => $conf })->dir, Mojo::File->new($conf, 'database-bi-extracts')->to_string,
		'a cache directory needs no model_dir';

	my $t = Test::Mojo->new('Database::BI', { model_dir => $model, cache_dir => $conf });
	is Database::BI::Controller::Dashboard::_extract_store($t->app)->dir,
		Mojo::File->new($conf, 'database-bi-extracts')->to_string, "the app's store reads its config";

	my $data = tempdir(CLEANUP => 1);
	$t = Test::Mojo->new('Database::BI', { data_dir => $data, model_dir => $model, cache_dir => "$data/cache" });
	my @warned;
	local $SIG{__WARN__} = sub { push @warned, @_ };
	is Database::BI::Controller::Dashboard::_extract_store($t->app)->dir, Mojo::File->new($model, 'extracts')->to_string,
		'a cache directory inside data_dir: the extracts stay in model_dir, where the home page does not list them';
	like "@warned", qr/inside data_dir/, 'and it says so';
};

subtest 'the page cache: page_cache_dir turns it on; a cache directory set places it' => sub {
	my $pages = tempdir(CLEANUP => 1);
	my $t     = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1), page_cache_dir => $pages });
	$t->get_ok('/tutorial')->status_is(200);
	ok -d File::Spec->catdir($pages, 'Database+3a+3aBI+3a+3aPages'), 'nothing else set: in page_cache_dir';

	my $kept = tempdir(CLEANUP => 1);
	my $other = tempdir(CLEANUP => 1);
	$t = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1), page_cache_dir => $other, cache_dir => $kept });
	$t->get_ok('/tutorial')->status_is(200);
	ok -d File::Spec->catdir($kept, 'Database+3a+3aBI+3a+3aPages'), 'cache_dir places it';
	ok !-e File::Spec->catdir($other, 'Database+3a+3aBI+3a+3aPages'), 'and page_cache_dir is not used';

	my $none = tempdir(CLEANUP => 1);
	local $ENV{CACHEDIR} = $none;
	$t = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1) });
	$t->get_ok('/tutorial')->status_is(200);
	is scalar(() = glob(File::Spec->catfile($none, '*'))), 0, 'without page_cache_dir, CACHEDIR does not turn it on';
};

done_testing();
