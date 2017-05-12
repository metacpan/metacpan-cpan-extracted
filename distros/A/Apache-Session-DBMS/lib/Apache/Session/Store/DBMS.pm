#############################################################################
#
# Apache::Session::Store::DBMS
# Implements session object storage via DBMS module
# Copyright(c) 2005 Asemantics S.r.l.
# Alberto Reggiori (alberto@asemantics.com)
# Distribute under a BSD license (see LICENSE file in main dir)
#
############################################################################

package Apache::Session::Store::DBMS;

use strict;
use vars qw($VERSION);
use DBMS;

$VERSION = '0.1';

$Apache::Session::Store::DBMS::DataSource = 'sessions';
$Apache::Session::Store::DBMS::Host = 'localhost';
$Apache::Session::Store::DBMS::Port = 1234;
$Apache::Session::Store::DBMS::Mode = &DBMS::XSMODE_CREAT;
$Apache::Session::Store::DBMS::Bt_compare = 0; #none

sub connection {
	my $self    = shift;
	my $session = shift;

	return
		if(defined $self->{dbh});

	if(	(exists $session->{args}->{Handle}) &&
		(UNIVERSAL::isa( $session->{args}->{Handle}, "DBMS" )) ) {
		$self->{dbh} = $session->{args}->{Handle};
        	return;
		};

	my $mode = $session->{args}->{Mode} ||
		$Apache::Session::Store::DBMS::Mode;
	my $bt_compare = $session->{args}->{Bt_compare} ||
		$Apache::Session::Store::DBMS::Bt_compare;

	my ($datasource, $host, $port);
	if( $session->{isObjectPerKey} ) {
		if( $session->{data}->{_session_id} =~ m|^\s*dbms://([^:]+):(\d+)/([^\s]+)| ) {
			$host = $1;
			$port = $2;
			$datasource = $3;
		} elsif( $session->{data}->{_session_id} =~ m|^\s*dbms://([^/]+)/([^\s]+)| ) {
			$host = $1;
			$port = $session->{args}->{Port} ||
				$Apache::Session::Store::DBMS::Port;
			$datasource = $2;
		} else {
			die "Invalid session identifier ".$session->{data}->{_session_id};
			};
	} elsif(	( exists $session->{args}->{DataSource} ) &&
			( $session->{args}->{DataSource} =~ m|^\s*dbms://| ) ) {
		if( $session->{args}->{DataSource} =~ m|^\s*dbms://([^:]+):(\d+)/([^\s]+)| ) {
			$host = $1;
			$port = $2;
			$datasource = $3;
		} elsif( $session->{args}->{DataSource} =~ m|^\s*dbms://([^/]+)/([^\s]+)| ) {
			$host = $1;
			$port = $session->{args}->{Port} ||
				$Apache::Session::Store::DBMS::Port;
			$datasource = $2;
		} else {
			die "Invalid session identifier ".$session->{data}->{_session_id};
			};
	} else {
		$datasource = $session->{args}->{DataSource} ||
        		$Apache::Session::Store::DBMS::DataSource;
		$host = $session->{args}->{Host} ||
			$Apache::Session::Store::DBMS::Host;
		$port = $session->{args}->{Port} ||
			$Apache::Session::Store::DBMS::Port;
		};

#print "TIE: $datasource, $mode, $bt_compare, $host, $port (session_id=".$session->{data}->{_session_id}.")\n";

	$self->{dbh} = tie %{$self->{dbms}}, 'DBMS', $datasource, $mode, $bt_compare, $host, $port
		or die $DBMS::ERROR."\n";
	};

sub new {
	my $class = shift;

	return bless {dbms => {}}, $class;
	};

sub insert {
	my $self    = shift;
	my $session = shift;
    
	return
		if( $session->{isObjectPerKey} );

	$self->connection($session);

	if (exists $self->{dbms}->{$session->{data}->{_session_id}}) {
		die "Object already exists in the data store";
		};

	$self->{dbms}->{$session->{data}->{_session_id}} = $session->{serialized}; # single session-id object
	};

sub update {
	my $self = shift;
	my $session = shift;
    
	return
		if( $session->{isObjectPerKey} );

	$self->connection($session);

	$self->{dbms}->{$session->{data}->{_session_id}} = $session->{serialized}
		if(defined $session->{data}->{_session_id});
	};

sub materialize {
	my $self = shift;
	my $session = shift;
    
	return
		if( $session->{isObjectPerKey} );

	$self->connection($session);

	$session->{serialized} = $self->{dbms}->{$session->{data}->{_session_id}};

	if (!defined $session->{serialized}) {
		die "Object does not exist in data store";
		};
	};

sub remove {
	my $self = shift;
	my $session = shift;
    
	return
		if( $session->{isObjectPerKey} );

	$self->connection($session);

	delete $self->{dbms}->{$session->{data}->{_session_id}};
	};

sub DESTROY {
	my $self = shift;

	if(defined $self->{dbh}) {
		delete $self->{dbh};
		untie %{$self->{dbms}};
		};
	};

1;

=pod

=head1 NAME

Apache::Session::Store::DBMS - Use DBMS to store persistent objects

=head1 SYNOPSIS

 use Apache::Session::Store::DBMS;
 
 my $store = new Apache::Session::Store::DBMS;
 
 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of Apache::Session.  The serialized
objects are stored in a remote hashed Berkeley DB store using the DBMS Perl module.

=head1 OPTIONS

This module requires...

=head1 AUTHOR

This module was written by Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

L<Apache::Session>, L<DBMS>
http://rdfstore.sf.net/dbms.html
