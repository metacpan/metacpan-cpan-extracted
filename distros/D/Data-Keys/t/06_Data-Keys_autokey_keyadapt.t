#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 6;
use Test::NoMalware;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use IO::Any;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Key::Auto') or exit;
	use_ok('Data::Keys::E::Dir::Auto') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );

	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::Auto', 'Key::Adapt', 'Key::Auto'],
	);

	# first two letters are the folder
	$ts->key_adapt(sub {
		my $key = shift;
		$key =~ s{/}{_}g;
		return File::Spec->catfile(substr($key, 0, 2), substr($key, 2));
	});

	# auto key
	is($ts->set(undef, '123'), '40/bd001563085fc35165329ea1ff5c5ecbdbbeef', 'auto key for set');
	is($ts->get('40bd001563085fc35165329ea1ff5c5ecbdbbeef'), '123', 'get the auto key');
	ok(-f File::Spec->catfile($tmp_folder, '40', 'bd001563085fc35165329ea1ff5c5ecbdbbeef'), 'first two letters are the folder, the rest is filename');
			
	return 0;
}

