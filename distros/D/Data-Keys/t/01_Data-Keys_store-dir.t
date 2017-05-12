#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 13;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use IO::Any;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Store::Dir') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );

	throws_ok { Data::Keys->new('extend_with' => ['Store::Dir'],) } qr/mandatory/, 'base_dir is mandatory argument';

	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir',],
	);

	# get from empty folder
	is($ts->get('abcd'),   (), 'no file so far');
	is($ts->get('a/b\cd'), (), 'no file so far');

	# set
	is($ts->set('a-b-c-d', 123), 'a-b-c-d', 'set file');
	ok(-f File::Spec->catfile($tmp_folder, 'a-b-c-d'), 'new file created');
	is(IO::Any->slurp([$tmp_folder, 'a-b-c-d']), '123', 'new file content');
	is($ts->get('a-b-c-d'), '123', 'now with get');

	# delete
	ok($ts->set('a-b-c-d', undef), 'delete the file via setting undef');
	ok(!-f File::Spec->catfile($tmp_folder, 'a-b-c-d'), 'new file created');
	ok($ts->set('a-b-c-d'), 'delete the non-existing file is fine too');
	is($ts->get('a-b-c-d'), (), 'no value');
		
	return 0;
}

