#!/usr/bin/perl

use strict;
use warnings;
use Test::Spec;
use App::SimpleBackuper::DB::BackupsTable;
use Const::Fast;

describe BackupsTable => sub {
	it pack_unpack => sub {
		const my $backup => {
			id				=> 33,
			files_cnt		=> 8888,
			max_files_cnt	=> 99999,
			is_done			=> 1,
			name			=> 'test',
		};
		
		is_deeply( App::SimpleBackuper::DB::BackupsTable->unpack( App::SimpleBackuper::DB::BackupsTable->pack($backup) ), $backup);
	};
};

runtests unless caller;
