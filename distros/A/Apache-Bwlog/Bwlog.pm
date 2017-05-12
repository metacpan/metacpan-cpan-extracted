package Apache::Bwlog;

use 5.008;
use strict;
use warnings;
use DBI;
use Apache::Constants qw(OK);
use Apache::File ();
use IPC::ShareLite;
require Exporter;

our $db_conn;

my %shared_hash;

my $share_sem = new IPC::ShareLite( -key     => 'BWLG',
                                -create  => 'yes',
                                -destroy => 'no' );

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::Bwlog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';

sub handler
{
	my $r = shift;
	my $bw_threshold;
	my $s = $r->server;
	my $vhost = $s->server_hostname;
	my $bw_on = $r->dir_config("Bwlog");
	if(!$bw_on)
	{
		return OK;
	}
	elsif($bw_on eq "active")
	{
		$bw_threshold = $r->dir_config("Bwlog_threshold");
		if(!$bw_threshold)
		{
			## If the user has not defined a threshold for byte logging, we will set it to 100000.  
			$bw_threshold = 100000;
		}		
	}
	else
	{
		## shouldn't ever get here... unless the user puts in an invalid value.  Lets log to the error log.
		$r->log_error("Invalid value for Bwlog. ($bw_on)");
		return OK;
	}

	## Get the log type
	
	my $log_type = $r->dir_config("Bwlog_logtype");
	if(!$log_type)
	{
		$log_type = "file";
	}
	
	## Get the log dir
	
	my $log_dir = $r->dir_config("Bwlog_logdir");
	if(!$log_dir)
	{
		$log_dir = "/usr/local/apache/logs";
	}	
	
	my $bytes_sent = $r->bytes_sent;
	
	read_shm_hash();
	if(!$shared_hash{"$vhost"})
	{
		$shared_hash{"$vhost"} = $bytes_sent;
		write_shm_hash();
	}
	else
	{
		$shared_hash{"$vhost"} = $shared_hash{"$vhost"} + $bytes_sent;
		write_shm_hash();
	}

	if($log_type eq "file")
	{
		##my $fh = Apache::File->new(">>$log_dir/$vhost");
		my $fh = Apache::File->new(">>$log_dir/$vhost");		
		#$fh->open(">>$log_dir/$vhost");
		if(!$fh)
		{
			$r->log_error("Couldn't open ($log_dir/$vhost)!  Does the directory ($log_dir) exist?");
			return OK;
		}
		if($shared_hash{"$vhost"} > $bw_threshold)
		{
			print $fh "$vhost,$shared_hash{ $vhost }\n";
		}
		return OK;
	}
	if($log_type eq "mysql")
	{
		$db_conn = db_connect($r);
		if(!$db_conn)
		{
			$r->log_error("Could not connect to the mysql database");
			return OK;
		}
		if($shared_hash{"$vhost"} > $bw_threshold)
		{
			my $ins_vhost = lc($vhost);
			my $table_name = $r->dir_config("Bwlog_mysql_tablename");
			if(!$db_conn)
			{
				$r->log_error("Lost handle to mysql.  Sleeping for 30 seconds and Re-connecting...");
				sleep 30;
				$db_conn =  db_connect($r);
			}
			my $insert_query = $db_conn->prepare("insert into $table_name (vhost, bytes_sent) VALUES(?,?)");
			$insert_query->execute($ins_vhost, $shared_hash{"$vhost"});
			$shared_hash{"$vhost"} = 0;
			write_shm_hash();
		}
		return OK;
	}
		
}

sub db_connect
{
	my $r = shift;
	my $Bwlog_mysql_database = $r->dir_config("Bwlog_mysql_database");
	my $Bwlog_mysql_server = $r->dir_config("Bwlog_mysql_server");
	my $Bwlog_mysql_user = $r->dir_config("Bwlog_mysql_user");
	my $Bwlog_mysql_password = $r->dir_config("Bwlog_mysql_password");
	
	return DBI->connect("DBI:mysql:$Bwlog_mysql_database:$Bwlog_mysql_server", $Bwlog_mysql_user, $Bwlog_mysql_password);
}

sub read_shm_hash
{
	## Since the sharelite module doesn't support var types, we are going to store a structure to read/write our hash back and forth.
	my $sem_data = $share_sem->fetch();
	my @conv_array = split(/&/, $sem_data);
	my $inc = 0;
	my ($k, $v);
	while($conv_array[$inc])
	{
		($k, $v) = split(/=/, $conv_array[$inc]);
		$shared_hash{ "$k" } = $v;
		$inc++;
	}
}	
sub write_shm_hash
{
	my($k, $v) = each(%shared_hash);
	my $shm_buffer;
	while($k)
	{
		$shm_buffer = $shm_buffer . "$k=$v&";
		($k, $v) = each(%shared_hash);
	}
	$share_sem->store("$shm_buffer");
}
	
	
	
# Preloaded methods go here.

1;
__END__


=head1 Apache::Bwlog

Apache::Bwlog - Vhost bandwidth logger for mod_perl.

=head1 SYNOPSIS

  Place this in the httpd.conf file :
  
  PerlLogHandler Apache::Bwlog

  Apache Directives
  
=item *  PerlSetVar Bwlog active
  
  	This value is required if plan to use the module at all.  This can be placed globally
	to effect all virtual hosts on the machine, or in a single VirtualHost context which 
	only activates logging for that host
	
  
=item *  PerlSetVar Bwlog_threshold <bytes>
  
  	Set the "bitbucket" maximum before purging the current counter.  Be aware that setting
	this value to low can add a lot of disk I/O, and or CPU time.  For a high volume site 
	a large number is recommended here.  Defaults to 100,000 bytes.
	
=item *  PerlSetVar Bwlog_logtype <type>
  	
  	Valid types are currently "file" and "mysql".  The mysql portion requires the directives
	described below.
  
=item * PerlSetVar Bwlog_mysql_user

=item * PerlSetVar Bwlog_mysql_password

=item * PerlSetVar Bwlog_mysql_server

=item * PerlSetVar Bwlog_mysql_database

=item * PerlSetVar Bwlog_mysql_tablename
  


=item * PerlSetVar Bwlog_logdir <directory>

	Resets the value for where your vhost bwlogs are stored if the file option is chosen. 
	This option defaults to : /usr/local/apache/logs

=head1 Table Create Syntax For mysql driver

	The following create will work for the mysql database :
	
	CREATE TABLE `bw_log` (
	  `bw_id` bigint(20) NOT NULL auto_increment,
	  `vhost` varchar(100) NOT NULL default '',
	  `bytes_sent` bigint(20) NOT NULL default '0',
	  `time_stamp` timestamp(14) NOT NULL,
	  PRIMARY KEY (`bw_id`)
	) 	
	
	
	
=head1 ABSTRACT

	httpd.conf Example.

	PerlLogHandler Apache::Bwlog

	PerlSetVar Bwlog_mysql_user bw_user
	PerlSetVar Bwlog_mysql_password bw_password
	PerlSetVar Bwlog_mysql_server 127.0.0.1
	PerlSetVar Bwlog_mysql_database bw_logger
	PerlSetVar Bwlog_mysql_tablename bw_log
	
	PerlSetVar Bwlog active
	PerlSetVar Bwlog_threshold 100000
	PerlSetVar Bwlog_logtype mysql
 
 

=head1 DESCRIPTION

  This module will do per virtual host bandwidth logging.  Fun fun fun.

=head2 EXPORT

None by default.



=head1 SEE ALSO

 mod_perl, perl, apache
 
=head1 AUTHOR

Lloyd Richardson lloyd@drlabs.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Lloyd Richardson <lloyd@drlabs.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
