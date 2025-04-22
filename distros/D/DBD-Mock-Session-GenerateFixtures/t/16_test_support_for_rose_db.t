use strict;
use warnings;

use Test2::V0;
use lib        qw(lib t);
use MyDatabase qw(build_tests_db populate_test_db);
use DB;
use DBD::Mock::Session::GenerateFixtures;

use Sub::Override;
use Rose::DB::Object;
use File::Path qw(rmtree);
use Rose::DB::Object::Loader;


my $db = DB->new(
	domain => 'development',
	type   => 'main'
);

build_tests_db($db->dbh);
populate_test_db($db->dbh);

my $loader = Rose::DB::Object::Loader->new(
	db           => $db,
	class_prefix => 'DB'
) or die "Failed to create loader: $@";

$loader->make_modules(module_dir => './t') or die 'Failed to make classes:';

my $expected_rows = [{
		'license_id'        => 1,
		'id'                => 1,
		'allows_commercial' => 1,
		'location'          => '/data/images/anne_fronk_stamp.jpg',
		'license_name'      => 'Public Domain',
		'media_type'        => 'image',
		'attribution'       => 'Deutsche Post',
		'media_type_id'     => 3
	},
	{
		'location'          => '/data/music/claire_de_lune.ogg',
		'id'                => 2,
		'allows_commercial' => 1,
		'license_id'        => 1,
		'attribution'       => 'Schwarzer Stern',
		'media_type_id'     => 2,
		'media_type'        => 'audio',
		'license_name'      => 'Public Domain'
	},
];

subtest 'mock data from a real dbh to collect data' => sub {

	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({dbh => $db->dbh()});

	my $num_rows_updated = DB::Media::Manager->update_media(
		set => {
			location => '/data/music/claire_de_lune.ogg',
		},
		where => [
			id => 2,
		],
	);

	is($num_rows_updated, 1, 'update media table is ok');

	note 'Mock an select using an Rose::DB::Object::Manager get method and a real dbh';

	my $media = DB::Media::Manager->get_media(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC',
	);


	my $got_rows = [];
	foreach my $media (@$media) {

		my $got = {};

		$got->{id}                = $media->id();
		$got->{media_type_id}     = $media->media_type()->id();
		$got->{media_type}        = $media->media_type()->media_type();
		$got->{license_id}        = $media->license()->id();
		$got->{location}          = $media->location();
		$got->{attribution}       = $media->attribution();
		$got->{license_name}      = $media->license()->name();
		$got->{allows_commercial} = $media->license()->allows_commercial();
		push @{$got_rows}, $got;
	}

	is($got_rows,           $expected_rows, 'DB::Media::Manager->get_media works ok');
	is(scalar @{$got_rows}, 2,              'DB::Media::Manager->get_media method fetched two rows is ok');

	note 'Mock an select using an Rose::DB::Object::Manager iterator method and a real dbh';

	my $iterator = DB::Media::Manager->get_media_iterator(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC',
	);

	my $iterator_rows = [];

	while (my $media_row = $iterator->next) {
		my $got = {};

		$got->{id}                = $media_row->id();
		$got->{media_type_id}     = $media_row->media_type()->id();
		$got->{media_type}        = $media_row->media_type()->media_type();
		$got->{license_id}        = $media_row->license()->id();
		$got->{location}          = $media_row->location();
		$got->{attribution}       = $media_row->attribution();
		$got->{license_name}      = $media_row->license()->name();
		$got->{allows_commercial} = $media_row->license()->allows_commercial();
		push @{$iterator_rows}, $got;
	}

	is($got_rows,          $expected_rows, 'DB::Media::Manager->get_media_iterator works ok');
	is($iterator->total(), 2,              'count with total is ok');


	note 'Mock an count using an Rose::DB::Object::Manager count method and a real dbh';

	my $count = DB::Media::Manager->get_media_count(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC'
	);

	is($count, 2, 'count wiht select count(*) is ok');

	my $media_obj = DB::Media->new(
		name          => 'test',
		location      => 'test',
		source        => 'test',
		attribution   => 'test',
		media_type_id => 2,
		license_id    => 2,
	);

	$media_obj->save();
	is($media_obj->id, 3, 'last inserted id is ok');

	my $media_obj_2 = DB::Media->new(
		name          => 'test',
		location      => 'test',
		source        => 'test',
		attribution   => 'test',
		media_type_id => 3,
		license_id    => 3,
	);

	$media_obj_2->save();

	is($media_obj_2->id, 4, 'last inserted id incremented with one');

	my $num_rows_deleted = DB::Media::Manager->delete_media(
		where => [
			name => 'test',

		]
	);

	is($num_rows_deleted, 2, 'DB::Media::Manager->delete_media works ok');

	$db->dbh->disconnect();

};

subtest 'use a mocked dbh to test rose db support' => sub {

	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new();

	my $override = Sub::Override->new();
	my $dbh      = $mock_dumper->get_dbh();
	$dbh->{mock_start_insert_id} = 3;

	$override->replace('Rose::DB::dbh' => sub {return $dbh});
	$override->inject('DBD::Mock::db::last_insert_rowid', sub {$dbh->{mock_last_insert_id}});


	my $num_rows_updated = DB::Media::Manager->update_media(
		set => {
			location => '/data/music/claire_de_lune.ogg',
		},
		where => [
			id => 2,
		],
	);

	is($num_rows_updated, 1, 'update media table is ok');

	note 'Mock an select using an Rose::DB::Object::Manager get method and a mocked dbh';


	my $media = DB::Media::Manager->get_media(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC',
	);


	my $got_rows = [];
	foreach my $media (@$media) {

		my $got = {};

		$got->{id}                = $media->id();
		$got->{media_type_id}     = $media->media_type()->id();
		$got->{media_type}        = $media->media_type()->media_type();
		$got->{license_id}        = $media->license()->id();
		$got->{location}          = $media->location();
		$got->{attribution}       = $media->attribution();
		$got->{license_name}      = $media->license()->name();
		$got->{allows_commercial} = $media->license()->allows_commercial();
		push @{$got_rows}, $got;
	}

	is($got_rows,           $expected_rows, 'DB::Media::Manager->get_media works ok');
	is(scalar @{$got_rows}, 2,              'DB::Media::Manager->get_media method fetched two rows is ok');

	note 'Mock an select using an Rose::DB::Object::Manager iterator method and a mocked dbh';

	my $iterator = DB::Media::Manager->get_media_iterator(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC'
	);

	my $iterator_rows = [];

	while (my $media_row = $iterator->next) {
		my $got = {};

		$got->{id}                = $media_row->id();
		$got->{media_type_id}     = $media_row->media_type()->id();
		$got->{media_type}        = $media_row->media_type()->media_type();
		$got->{license_id}        = $media_row->license()->id();
		$got->{location}          = $media_row->location();
		$got->{attribution}       = $media_row->attribution();
		$got->{license_name}      = $media_row->license()->name();
		$got->{allows_commercial} = $media_row->license()->allows_commercial();
		push @{$iterator_rows}, $got;
	}

	is($got_rows,          $expected_rows, 'DB::Media::Manager->get_media_iterator works ok');
	is($iterator->total(), 2,              'count with total is ok');


	note 'Mock an count using an Rose::DB::Object::Manager count method and a mocked dbh';

	my $count = DB::Media::Manager->get_media_count(
		with_objects => ['media_type', 'license'],
		query        => [
			't1.id' => [1, 2, 3, 1000],
		],
		sort_by => 't1.id ASC'
	);

	is($count, 2, 'count wiht select count(*) is ok');

	my $media_obj = DB::Media->new(
		name          => 'test',
		location      => 'test',
		source        => 'test',
		attribution   => 'test',
		media_type_id => 2,
		license_id    => 2,
	);

	$media_obj->save();
	is($media_obj->id, 3, 'last inserted id is ok');

	my $media_obj_2 = DB::Media->new(
		name          => 'test',
		location      => 'test',
		source        => 'test',
		attribution   => 'test',
		media_type_id => 3,
		license_id    => 3,
	);

	$media_obj_2->save();

	is($media_obj_2->id, 4, 'last inserted id incremented with one');

	my $num_rows_deleted = DB::Media::Manager->delete_media(
		where => [
			name => 'test',

		]
	);

	is($num_rows_deleted, 2, 'DB::Media::Manager->delete_media works ok');

	$override->restore('Rose::DB::dbh');
	$override->restore('DBD::Mock::db::last_insert_rowid');
};

done_testing();
