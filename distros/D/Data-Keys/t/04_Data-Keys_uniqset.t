#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 10;
use Test::NoMalware;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use JSON::Util;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Dir::Lock') or exit;
	use_ok('Data::Keys::E::UniqSet') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );
	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::Lock', 'UniqSet'],
	);

	is($ts->get('abcd'), (), 'get non-existing file');
	is($ts->set('abcd', 123), 'abcd', 'set');
	is_deeply(IO::Any->slurp([$tmp_folder, 'abcd']), 123, 'read the file directly');	
	
	throws_ok { $ts->set('abcd', 456) } qr/abcd .+ already \s exists/xms, 'setting second time should make an exception';

	is($ts->set('abcde', 321), 'abcde', 'another set');
	throws_ok { $ts->set('abcde', 456) } qr/abcde .+ already \s exists/xms, 'setting second time should make an exception again';
	is($ts->get('abcde'), 321, 'get and test the value');
	
	return 0;
}

