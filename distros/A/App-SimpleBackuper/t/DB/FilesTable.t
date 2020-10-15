#!/usr/bin/perl

use strict;
use warnings;
use Test::Spec;
use App::SimpleBackuper::DB::FilesTable;
use Const::Fast;

describe FilesTable => sub {
	it pack_unpack => sub {
		
		const my $file => {
			parent_id	=> 555,
			id			=> 666,
			name		=> 'MyFile.JPG',
			versions	=> [
				{
					backup_id_min	=> 5,
					backup_id_max	=> 6,
					uid				=> 111,
					gid				=> 112,
					size			=> 9999999,
					mode			=> 1234,
					mtime			=> time,
					block_id		=> 222,
					symlink_to		=> '/path/to/target',
					parts			=> [
						{
							hash		=> 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e',
							size		=> 888,
							aes_key		=> pack("C32", map {int rand 256} 1..32),
							aes_iv		=> pack("C16", map {int rand 256} 1..16),
							block_id	=> 222,
						},
						{
							hash		=> '40b244112641dd78dd4f93b6c9190dd46e0099194d5a44257b7efad6ef9ff4683da1eda0244448cb343aa688f5d3efd7314dafe580ac0bcbf115aeca9e8dc114',
							size		=> 777,
							aes_key		=> pack("C32", map {int rand 256} 1..32),
							aes_iv		=> pack("C16", map {int rand 256} 1..16),
							block_id	=> 222,
						},
					],
				}
			],
		};
		is_deeply( App::SimpleBackuper::DB::FilesTable->unpack( App::SimpleBackuper::DB::FilesTable->pack($file) ), $file);
		
		const my $file2 => {
			'name' => '.gnupg',
			'parent_id' => 2,
			'versions' => [
				{
					'uid' => 2,
					'parts' => [],
					'size' => 4096,
					'backup_id_min' => 1,
					'backup_id_max' => 1,
					'symlink_to' => undef,
					'block_id' => 0,
					'mode' => 16832,
					'mtime' => 1596767600,
					'gid' => 2
				},
				{
					'size' => 4096,
					'uid' => 2,
					'parts' => [],
					'backup_id_max' => 2,
					'backup_id_min' => 2,
					'block_id' => 0,
					'symlink_to' => undef,
					'gid' => 2,
					'mtime' => 1598206902,
					'mode' => 16832
				}
			],
			'id' => 7077
        };
		is_deeply( App::SimpleBackuper::DB::FilesTable->unpack( App::SimpleBackuper::DB::FilesTable->pack($file2) ), $file2);
	};
};

runtests unless caller;
