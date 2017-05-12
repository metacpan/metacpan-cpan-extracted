#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 7;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use IO::Any;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Dir::Auto') or exit;
	use_ok('Data::Keys::E::Key::Adapt') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );

	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::Auto', 'Key::Adapt'],
	);

	# auto folder create
	$ts->key_adapt(sub {
		my $key = shift;
		$key =~ s{/}{_}g;
		return File::Spec->catfile(substr($key, 0, 2), substr($key, 2));
	});
	my $filename_with_folder = File::Spec->catfile('ab', 'cd');
	is($ts->set('abcd', 123), $filename_with_folder, 'auto folder set name');
	ok(-d File::Spec->catdir($tmp_folder, 'ab'), 'folder created');
	ok(-f File::Spec->catfile($tmp_folder, $filename_with_folder), 'file inside created');
	is($ts->get('abcd'), '123', 'auto folder name content check');
			
	return 0;
}

