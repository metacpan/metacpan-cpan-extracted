#!/usr/bin/perl
# execute in the app-shotgun root dir

use strict;
use warnings;

use App::Shotgun;

my $shotgun = App::Shotgun->new(
	source => '.',
	files => [
	      'examples/sync.pl',
	      'dist.ini',
	      'Changes',
	      'lib/App/Shotgun.pm',
	      'lib/App/Shotgun/Target/FTP.pm',
	],
	targets => [
		{
			type => 'FTP',
			path => '/1',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
		{
			type => 'FTP',
			path => '/2',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
		{
			type => 'FTP',
			path => '/3',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
		{
			type => 'SFTP',
			path => '/home/apoc/a',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
		{
			type => 'SFTP',
			path => '/home/apoc/b',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
		{
			type => 'SFTP',
			path => '/home/apoc/c',
			hostname => '192.168.0.55',
			username => 'apoc',
			password => 'apoc',
		},
	],
);

$shotgun->shot;

print "Success: ".($shotgun->success ? 'YES' : 'NO')."\n";
print "Error: ".$shotgun->error if (!$shotgun->success);
