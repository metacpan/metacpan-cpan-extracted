#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 5;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use JSON::Util;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Value::InfDef') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );
	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Value::InfDef'],
		'inflate'     => sub { JSON::Util->decode($_[0]) },
		'deflate'     => sub { JSON::Util->encode($_[0]) },
	);

	my %some_data = (
		'a' => 'b',
		'c' => 123,
	);

	is($ts->get('abcd.json'), (), 'get non-existing file');
	is($ts->set('abcd.json', \%some_data), 'abcd.json', 'save json');
	is_deeply(JSON::Util->decode([$tmp_folder, 'abcd.json']), \%some_data, 'read the file directly');	
	
	return 0;
}

