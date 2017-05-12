package CGI::Lazy::DB;

use strict;

use DBI;
use CGI::Lazy::Globals;
use Carp;

#---------------------------------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->q->config;
}

#---------------------------------------------------------------------------------------
sub dbh {
	my $self = shift;

	return $self->{_dbh};
}

#---------------------------------------------------------------------------------------
sub do { #run query with no return value
	my $self = shift;
	my $query = shift;
	my @bindvars = @_;

	my $dbh = $self->dbh;
	my $sth;

	eval {
		$sth = $dbh->prepare($query);
		$sth->execute(@bindvars) or carp $!;
	};

	if ($@) {
		$self->q->errorHandler->dbError;
		return;
	} else {
		return 1;
	}
}

#---------------------------------------------------------------------------------------
sub get { #run query returning single value
	my $self = shift;
	my $query = shift;
	my @bindvars = @_;

	if (ref $bindvars[0]) {
		if (ref $bindvars[0] eq 'ARRAY') {
			@bindvars = @{$bindvars[0]};
		} else {
			$self->q->errorHandler->getWithOtherThanArray;
		}
	} 

	my $dbh = $self->dbh;
	my $sth;

	eval {
		$sth = $dbh->prepare($query);
		$sth->execute(@bindvars);
	};

	if ($@) {
		$self->q->errorHandler->dbError;
		return;
	}

	my @results = $sth->fetchrow_array;

	return $results[0];
}

#---------------------------------------------------------------------------------------
sub getarray { #run query with return value
	my $self = shift;
	my $query = shift;
	my @bindvars = @_;

	if (ref $bindvars[0]) {
		if (ref $bindvars[0] eq 'ARRAY') {
			@bindvars = @{$bindvars[0]};
		} else {
			$self->q->errorHandler->getWithOtherThanArray;
		}
	} 

	my $dbh = $self->dbh;
	my $sth;

	eval {
		$sth = $dbh->prepare($query);
		$sth->execute(@bindvars);
	};

	if ($@) {
		$self->q->errorHandler->dbError;
		return;
	}

	return $sth->fetchall_arrayref;

}

#---------------------------------------------------------------------------------------
sub gethash { #run query with return value
	my $self = shift;
	my $query = shift;
	my $key = shift;
	my @bindvars = @_;

	my $dbh = $self->dbh;
	my $sth;

	eval {
		$sth = $dbh->prepare($query);
		$sth->execute(@bindvars);
	};

	if ($@) {
		$self->q->errorHandler->dbError;
		return;
	}

	return $sth->fetchall_hashref($key);
}

#---------------------------------------------------------------------------------------
sub gethashlist { #run query with return value
	my $self = shift;
	my $query = shift;
	my @bindvars = @_;

	if (ref $bindvars[0]) {
		if (ref $bindvars[0] eq 'ARRAY') {
			@bindvars = @{$bindvars[0]};
		} else {
			$self->q->errorHandler->getWithOtherThanArray;
		}
	} 

	my $dbh = $self->dbh;
	my $sth;

	eval {
		$sth = $dbh->prepare($query);
		$sth->execute(@bindvars);
	};

	if ($@) {
		$self->q->errorHandler->dbError;
		return;
	}

	my $results = [];
	while (my $row = $sth->fetchrow_hashref) {
		push @$results, $row;
	}

	return $results;
}

#---------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = bless {_q => $q}, $class;

	if ($q->plugin->dbh) {
		my @list = split ':', $self->config->plugins->{dbh}->{dbDatasource};
		my $type = $list[1];
		$self->{_type} = $type;

		eval {
			$self->{_dbh} = DBI->connect(
					$self->config->plugins->{dbh}->{dbDatasource}, 
					$self->config->plugins->{dbh}->{dbUser}, 
					$self->config->plugins->{dbh}->{dbPasswd}, 
					$self->config->plugins->{dbh}->{dbArgs}
					) or die $!;
		};

		if ($@) {
			$q->errorHandler->dbConnectFailed;
			exit;
		}
	} else { #using dbh from somewhere else
		if ($q->vars->{dbh} ) { #if a dbh is specified on cgi creation use that one
			$self->{_dbh} = $q->vars->{dbh};
		} elsif ($q->config->dbhVar){
			{
				no strict 'vars';
				no strict 'refs';
				
				if ($self->config->plugins->{mod_perl}) {
					my $handler = $self->config->plugins->{mod_perl}->{PerlHandler};
					require Apache2::RequestUtil;
					my $r = Apache2::RequestUtil->request();
					my $mp = "$handler"->new($r);

					$self->{_dbh} = ${$mp->make_namespace."::".$self->config->dbhVar};
						
				} else {
					$self->{_dbh} = $main::{$self->config->dbhVar};

				}
			}
		} else {

		}
	}

	return $self;
}

#---------------------------------------------------------------------------------------
sub q {
	my $self = shift;
	
	return $self->{_q};
}

#---------------------------------------------------------------------------------------
sub recordset {
	my $self = shift;
	my $args = shift;

	return CGI::Lazy::DB::RecordSet->new($self, $args);

}
	
#---------------------------------------------------------------------------------------
sub type {
	my $self = shift;

	return $self->{_dbh}->{Driver}->{Name};
}
1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::DB

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/');

	my $dbh = $q->db->dbh; #just get the dbh, and use it by hand

	$q->db->do('select...."); #use the db object's abstraction for queries with no return value

	my $value = $q->db->getarray($query, @binds); #get an array of arrays.

	my $value = $q->db->gethash($query, $key, @binds); #get a hash of hashes

	my $value = $q->db->gethashlist($query, @binds); #get ordered array of hashrefs. (This is probably the most useful)

=head1 DESCRIPTION

CGI::Lazy database object.  Contains convenience methods for common db operations and holds base database handle for object.

=head1 METHODS

=head2 config ()

Returns config object.

=head2 dbh

Returns default database handle

=head2 do ( query, binds ) 

Runs a given query with bind values specified. Does not expect a return value

=head3 query

raw sql to be run

=head3 binds

array or literal values to be bound

=head2 get ( query, binds ) 

Runs a given query with bind values specified. Returns first value found.

=head3 query

raw sql to be run

=head3 binds

array ref to values to be bound or list of binds.  If first element is a reference, it will be assumed that that is an array ref and it is all of the binds

=head2 getarray ( query, binds ) 

Runs a given query with bind values specified. Returns array of arrays from DBI::fetchall_arrayref

=head3 query

raw sql to be run

=head3 binds

array ref to values to be bound or list of binds.  If first element is a reference, it will be assumed that that is an array ref and it is all of the binds

=head2 gethash ( query, key, binds ) 

Runs a given query with bind values specified. Returns hashref from DBI::fetchall_hashref

=head3 query

raw sql to be run

=head3 key

field to use as key for main hash

=head3 binds

array of values to be bound

=head2 gethashlist ( query, binds ) 

Runs a given query with bind values specified. Returns array of hashrefs

=head3 query

raw sql to be run

=head3 binds

array of values to be bound or list of binds.  If first element is a reference, it will be assumed that that is an array ref and it is all of the binds

=head2 new ( q )

Constructor.  Builds or inherits database handle and returns DB object.

Database handles may be handled in one of 3 ways:  

1) built from username, password, and connect string specified in the config file

2) build in the cgi and explicitly passed to the Lazy object on object creation.

3) a known variable that is in scope in the cgi can be specified, in which case the program will look for this variable, and pick it up.

Note:  with mod_perl option 3 is a little more hairy.  You will need to specify the mod_perl request handler being used, e.g. ModPerl::Registry  or ModPerl::PerlRun in the apache config.

=head3 q

Lazy Object

=head2 q ()

Returns CGI::Lazy object

=head2 recordset ( args )

Creates and returns a CGI::Lazy::DB::RecordSet object.

See CGI::Lazy::DB::RecordSet for more information.

=head3 args

hashref of RecordSet properties

=head2 type ()

Returns driver type from database handle object.  Necessary for specifying different behaviors dependant on databse capabilities.

=cut

