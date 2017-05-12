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
						  conf         => 't/ezbackup_missing_dir.conf',
						  exclude_file => 'share/ezbackup_exclude.rsync',
						  dryrun       => 1
);
die if !$ez;
system( "rm -rf " . $ez->{conf}->{dest_dir} );

ok( $ez->backup );
ok( !$ez->get_list_of_backups() );

# now run for real
$ez = Backup::EZ->new(
					conf         => 't/ezbackup_missing_dir.conf',
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


system("t/nuke.pl");
done_testing();
