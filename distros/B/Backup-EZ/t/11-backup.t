#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;


###### NUKE AND PAVE ######

system("t/nuke.pl");
system("t/pave.pl");

###### RUN TESTS ######

# verify dryrun actually works
my $ez = Backup::EZ->new(
						  conf         => 't/ezbackup.conf',
						  exclude_file => 'share/ezbackup_exclude.rsync',
						  dryrun       => 1
);
die if !$ez;
system( "rm -rf " . $ez->{conf}->{dest_dir} );

ok( $ez->backup );
ok( !$ez->get_list_of_backups() );

# now run for real
$ez = Backup::EZ->new(
					conf         => 't/ezbackup.conf',
					exclude_file => 'share/ezbackup_exclude.rsync',
					dryrun       => 0
);
die if !$ez;

ok( $ez->backup );
my @list = $ez->get_list_of_backups();
ok( @list == 1 );

ok( sleep 1 && $ez->backup );
@list = $ez->get_list_of_backups();
ok( @list == 2 ) or print Dumper \@list;

my $host = $ez->get_backup_host;
ok($host);

$ez = Backup::EZ->new(
					   conf         => 't/ezbackup_min.conf',
					   exclude_file => 'share/ezbackup_exclude.rsync',
					   dryrun       => 0
);
die if !$ez;

ok( sleep 1 && $ez->backup );
@list = $ez->get_list_of_backups();
ok( @list == 3 ) or print STDERR Dumper \@list;

my $cmd = sprintf( "touch %s/junk", $ez->get_dest_dir() );
system($cmd);
die if $?;

@list = $ez->get_list_of_backups();
ok( @list == 3 );

# cleanup
$cmd = sprintf( "rm -rf %s", $ez->get_dest_dir() );
system($cmd);


system("t/nuke.pl");
done_testing();
