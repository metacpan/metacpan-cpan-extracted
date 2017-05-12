# -*-Perl-*-
# $Id: ConPool.pm,v 1.1.1.1 2001/10/31 22:03:22 mpeppler Exp $

# Copyright (c) 2001   Michael Peppler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.


package Apache::Sybase::ConPool;

use strict;

use Sybase::CTlib;
use IPC::SysV qw(IPC_CREAT S_IRWXU SEM_UNDO IPC_NOWAIT);
use IPC::Semaphore;
use Carp;
use Sys::Hostname;

use vars qw($VERSION $Revision);

$VERSION = '1.00';
$Revision = substr(q$Revision: 1.1.1.1 $, 10);

my %config;

my %share;
my %handles;

my $verbose;

sub import {
    my $package = shift;
    my (%args) = @_;

    return if(%share);

    if(!$args{config}) {
	croak("Usage: use Apache::Sybase::ConPool (config => <config file>)");
    }

#    loadConfig($args{config});

    initialize($args{config});
}
	

sub initialize {
    my $file = shift;

    loadConfig($file);

    my $verbose = $config{'DbVerbose'};
    my $hostname = hostname;
    ($hostname) = split(/\./, $hostname);
	
    my $timeout = $config{'DbTimeout'} || 30;
    if(ct_config(CS_SET, CS_TIMEOUT, $timeout, CS_INT_TYPE) != CS_SUCCEED) {
	warn "[ConPool] ct_config(CS_TIMEOUT) failed\n";
    }   
    
    my $max_connect = $config{'DbNumConnect'} || 40;
    ct_config(CS_SET, CS_MAX_CONNECT, $max_connect, CS_INT_TYPE);
	
    for(my $i = 1; $i <= $config{DbNumPools} || 1; ++$i) {
	my $data = $config{"ConPool$i"};
	if(!$data) {
	    warn("[ConTool] Nothing found for ConPool$i\n") if $verbose;
	    last;
	}
	    
	my ($srv, $usr, $pwd, $count, $key) = split(/,\s*/, $data);
	warn "[ConPool] Connecting to $srv ($count connections)\n" if $verbose;
	$share{$srv}->{COUNT} = $count;
	$share{$srv}->{KEY} = unpack('N', $key);
	for (1 .. $count) {
	    my $dbh = 
		Sybase::CTlib->new($usr, $pwd, $srv, "(ConPool)", 
			       { CON_PROPS => { CS_HOSTNAME => $hostname }, 
				 SRV => $srv});
	    warn "[ConPool] Can't connect to $srv\n" unless $dbh;
	    $share{$srv}->{DBH}->{$_} = $dbh;
	}
	    
	$key = $share{$srv}->{KEY};
	my $sem;
	if($sem = new IPC::Semaphore($key, 0, 0666)) {
	    warn "[ConPool] Removing existing semaphore ", $sem->id(), "\n" if $verbose;
	    $sem->remove;
	}
	$sem = new IPC::Semaphore($key, $count + 1, 0666 | IPC_CREAT);
	$sem->setall ( $count, (0) x $count );
    }
}

sub loadConfig {
    my $file = shift;

#    warn "Reading $file\n";

    open(IN, $file) || croak("Can't open $file: $!");
    while(<IN>) {
	chomp;
#	warn "read $_\n";
	next if /^\s*$/;
	next if /^\s*\#/;
	my ($key, $val) = split(/\s*=\s*/, $_);
	$config{$key} = $val;
    }
    close(IN);
}


sub getDbh {
    my $srv = shift;

    print STDERR "[ConPool] getting handle for $srv\n" if $verbose;

    if(!exists($share{$srv})) {
	warn "[ConPool] No connection defined for $srv!\n";
	return undef;
    }

    my $key = $share{$srv}->{KEY};
    my $count = $share{$srv}->{COUNT};

    my $sem = new IPC::Semaphore($key, 0, 0666);
    my $r;
    my $used = 0;
    my $sleep = 0;

    my %ignore;

    my $sleepTime = $config{'DbSleepTime'} || 0.25;
    my $semTimeout = $config{'SemTimeout'} || 30;

    my $now = time;

    eval {
	my $h = Sys::Signal->set(ALRM => sub { die "Timeout\n"; } );
	alarm($semTimeout);
	$r = $sem->op(0, -1, 0);
	alarm(0);
    };
    if($@ && $@ =~ /Timeout/) {
	warn "[ConPool] semaphore timed out for $srv\n";
	return undef;
    }

    my $diff = time - $now;
    if($diff) {
	warn "[ConPool] Semaphore acquisition for $srv: $diff seconds\n";
    }

 RETRY:;
    for my $i (1 .. $count) {
	next if $ignore{$i};

	$r = $sem->op(
		      $i, 0, IPC_NOWAIT,
		      $i, 1, IPC_NOWAIT
		     );
	print STDERR "semop(get $$) (lock $i) returned $r: $!\n" if $verbose;
	if($r == 1) {
	    $used = $i;
	    last;
	}
    }
    
    # If the connection's been marked DEAD, just skip this one...
    if($used && $share{$srv}->{DBH}->{$used}->DBDEAD()) {
	warn "[ConPool] Connection $used ($srv) is dead - ignored\n";
	$ignore{$used}++;
	goto RETRY;
    }

    if(!$used) {
	print STDERR "[ConPool] No handle available for $srv - sleeping\n";
	#sleep(1);
	++$sleep;
	select(undef, undef, undef, $sleepTime);
	goto RETRY;
    }

    if($sleep) {
	print STDERR "[ConPool] Slept for $srv for ", $sleep * $sleepTime, " seconds\n";
    }
#    print STDERR "[ConPool] ($$): got handle $used\n" if $verbose;
    warn "[ConPool] ($$): got handle $used\n" if $verbose;

    $handles{$share{$srv}->{DBH}->{$used}} = $share{$srv}->{DBH}->{$used};

    $share{$srv}->{DBH}->{$used};
}

sub freeDbh {
    my $dbh   = shift;
    my $force = shift || 0;

#    print STDERR "$dbh\n";

    my $srv = $dbh->{SRV};
    
    print STDERR "[ConPool] Freeing handle for $srv (force = $force)\n" if $verbose;

    my $key = $share{$srv}->{KEY};
    my $count = $share{$srv}->{COUNT};

    my $sem = new IPC::Semaphore($key, $count, 0666 | IPC_CREAT);
    for(my $i = 1; $i <= $count; ++$i) {
	if($share{$srv}->{DBH}->{$i} == $dbh) {
	    # Clear this handle
	    my $r = $sem->op( $i, -1, $force ? 0: IPC_NOWAIT );
	    if($r == 1 && $!) {
		print STDERR "semop(free $$) ($i) returned $r: $!\n";
		last unless $force;
	    }

	    delete $handles{$dbh};

	    # add one item back to the resource count
	    $sem->op(0, 1, IPC_NOWAIT);

	    if($verbose) {
		my @a = $sem->getall();

		print STDERR "getall($$): @a\n";
	    }
	}
    }
}

sub clearAll {
    foreach (keys(%handles)) {
	warn "[ConPool] Clearing $_ from clearAll\n";
	freeDbh($handles{$_}, 1);
    }
}


1;

__END__

=head1 NAME

Apache::Sybase::ConPool - A Sybase connection pooling module for Apache/mod_perl

=head1 SYNOPSIS

Pre-load this module in your mod_perl startup script:

    use Apache::Sybase::ConPool (config => '/usr/local/apache/lib/conpool.cfg');

Then in your mod_perl scripts/handlers:

    use Apache::Sybase::ConPool;

    my $dbh = Apache::Sybase::ConPool::getDbh($server);
    .... use $dbh for some query or queries ....
    Apache::Sybase::ConPool::freeDbh($dbh);

=head1 DESCRIPTION

Apache::Sybase::ConPool allocates a pre-defined number of connections at
startup and stores them in a hash. These connections can then be shared
among the httpd child processes as needed, using System V semaphores
to syncronize access to each connection.

This module is useful if you have a large (5 or more) client web servers
that connect to the same database server, as it reduces the number of
open sockets that are needed on the database server.

I have found that allocating 10 connections for each web server works
well, but you should of course experiment with this.

The connection details are handled in a configuration file (see
sample conpool.cfg included in the package). The location of the 
configuration file is passed in when the module is I<use'd> in 
the mod_perl startup script.

Apache::Sybase::ConPool defines the following calls:

=over 4

=item $dbh = getDbh($server)

Get a connection to $server. An entry for this server has to have been 
defined in I<conpool.cfg>. This returns I<undef> if no connections are
available (under heavy load, for example).

=item freeDbh($dbh)

Release the lock on $dbh, and return it to the pool of available connections.

=item clearAll()

Force the releasing of all database connections that this process may have.
Usefull to be included in a cleanup handler to make sure that no stray locks
are kept on a connection.

=back

=head1 BUGS

The web server(s) has to be restarted if the database server goes down.

The database handles can become unusable if a child dies while holding a 
lock on the handle.

=head1 AUTHOR

Michael Peppler, mpeppler@peppler.org

=head1 COPYRIGHT

Copyright (c) 2001   Michael Peppler

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file,
with the exception that it cannot be placed on a CD-ROM or similar media
for commercial distribution without the prior approval of the author.

=head1 SEE ALSO

perl(1), Sybase::CTlib

=cut
