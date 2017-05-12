#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 7;
use Test::Differences;
use Test::Exception;
use File::Temp 'tempdir';
use Path::Class;

BEGIN {
	use_ok ( 'App::Stash' ) or exit;
}

exit main();

sub main {
	my $tmpdir = tempdir( CLEANUP => 1 );
	
	my $stash_filename = file($tmpdir, '01.json')->stringify;
	non_existing_stash: {
		lives_ok {
			my $stash  = App::Stash->new({'stash_filename' => $stash_filename});
			$stash->data->{'test'} = 1;
			$stash->save;
			$stash = undef;
		} 'test save()';
		ok(-f $stash_filename, 'stash file created');
	};
		
	read_existing_stash: {
		my $stash  = App::Stash->new({'stash_filename' => $stash_filename});
		is($stash->data->{'test'}, 1, 'check stored value');
	};

	remove_clear_stash: {
		my $stash  = App::Stash->new({'stash_filename' => $stash_filename});
		lives_ok {
			$stash->clear;
		} 'test clear()';
		ok(!-f $stash_filename, 'no file after clear');
		eq_or_diff($stash->data, {}, 'no data after clear');
	};
	
	return 0;
}

