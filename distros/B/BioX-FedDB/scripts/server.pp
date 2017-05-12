#!/usr/bin/perl

use BioX::FedDB;

my $servers    = [ 'bioinformatics.ualr.edu/catalyst/', 'bioinformatics.ualr.edu/catalyst/' ];
my $connection = { database => 'feddb',
		   host     => 'localhost',
		   user     => 'root',
		   pass     => 'binf.452e' };

my $server = BioX::FedDB->new({ mode => 'Server', connection => $connection, servers => $servers });

print $server->version(), "\n";

print $server->query_count( 'AA123456' ), "\n\n";

print $server->subject( 'AA123456' ), "\n\n";

exit;

