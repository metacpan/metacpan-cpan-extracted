# $Id$
#
# BioPerl module for Bio::DB::DBI::base
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::DBI::base - base class for drivers implementing Bio::DB::DBI

=head1 DESCRIPTION

Don't instantiate this module directly. Instead instantiate one of the
derived classes.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 CONTRIBUTORS

Juguang Xiao, juguang at tll.org.sg

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

#'
# Let the code begin...


package Bio::DB::DBI::base;
use vars qw(@ISA);
use strict;
use Bio::DB::DBI;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;

@ISA = qw(Bio::Root::Root Bio::DB::DBI);

=head2 new

 Title   : new
 Usage   : 
 Function: should only be called by derived classes
 Returns : 
 Args    : named parameters with tags -dbcontext (a Bio::DB::DBContextI
           implementing object) and -sequence_name (the name of the sequence
           for PK generation)


=cut

sub new {
    my($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);
    
    my ($dbc, $seqname) = $self->_rearrange([qw(DBCONTEXT SEQUENCE_NAME)],
					    @args);

    $self->{'_dbh_pools'} = {};
    $self->{'_conn_params'} = {};
    $dbc && $self->dbcontext($dbc);
    $self->sequence_name($seqname) if defined($seqname);

    return $self;
}

=head2 sequence_name

 Title   : sequence_name
 Usage   : $obj->sequence_name($newval)
 Function: Sets/Gets the name of the sequence to be used for PK generation if
           that name is not passed to the respective method as an argument.
 Example : 
 Returns : value of sequence_name (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub sequence_name{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'sequence_name'} = $value;
    }
    return $self->{'sequence_name'};
}

=head2 build_dsn

 Title   : build_dsn
 Usage   :
 Function: Constructs the DSN string from the DBContextI object. Since this
           may be driver-specific, specific implementations may need to
           override this method.
 Example :
 Returns : a string (the DSN)
 Args    : a Bio::DB::DBContextI implementing object


=cut

sub build_dsn{
    my ($self,$dbc) = @_;

    my $dsn = $dbc->dsn();
    if (! defined($dsn)) {
        $dsn = "DBI:" . $dbc->driver() . ":database=" . $dbc->dbname();
        $dsn .= ";host=" . $dbc->host() if $dbc->host();
        $dsn .= ";port=" . $dbc->port() if $dbc->port();
    }
    return $dsn;
}

=head2 get_connection

 Title   : get_connection
 Usage   :
 Function: Obtains a connection handle to the database represented by
           the the DBContextI object, passing additional args to the
           DBI->connect() method if a new connection is created.

           Contrary to new_connection(), this method will return
           shared connections from a pool. The implementation makes
           sure though that the returned handle was opened with the
           given parameters.

           In addition, the caller must not disconnect the obtained
           handle deliberately. Instead, the implementing object will
           disconnect and dispose of open handles once it is being
           garbage collected, or once disconnect() is called with the
           same or no parameters.

           Specific drivers usually won''t need to override this
           method but rather build_dsn().

           This implementation will call new_connection() to actually
           get a new connection if needed.

 Example :
 Returns : an open DBI database handle
 Args    : A Bio::DB::DBContextI implementing object. Additional hashref
           parameter to be passed to DBI->connect().


=cut

sub get_connection{
    my ($self,$dbc,$params) = @_;
    
    # The below line is added by Juguang. 
    # Well, I cannot see why the dbc needs to be re-assigned here again.
    $dbc ||= $self->dbcontext;
    
    my @keyvalues = $params ? %$params : ("default");
    # note that in the end the key doesn't carry meaning any more; the goal is
    # rather to ensure that two invocations with the same dbcontext object and
    # a hashref containing the same keys and values result in the same key
    my $poolkey = "$dbc" . join(";", sort(@keyvalues));
    
    if(! exists($self->{'_dbh_pools'}->{$poolkey})) {
	$self->{'_dbh_pools'}->{$poolkey} = [];
    }

    my $connpool = $self->{'_dbh_pools'}->{$poolkey};
    if(! @$connpool) {
	push(@$connpool, $self->new_connection($dbc,$params));
    }
    return $connpool->[0];
}

=head2 new_connection

 Title   : new_connection
 Usage   :
 Function: Obtains a new connection handle to the database represented by the
           the DBContextI object, passing additional args to the DBI->connect()
           method.

           This method is supposed to always open a new connection. Also, the
           implementing class is expected to release proper disconnection of
           the handle entirely to the caller.

           Specific drivers usually won''t need to override this method but
           rather build_dsn().
 Example :
 Returns : an open DBI database handle
 Args    : A Bio::DB::DBContextI implementing object. Additional hashref
           parameter to pass to DBI->connect().


=cut

sub new_connection{
    my ($self,$dbc,$params) = @_;

    $self->throw("mandatory argument dbcontext not supplied (internal error?)")
	unless $dbc;
    my $dsn = $self->build_dsn($dbc);
    $self->debug("new_connection(): dsn=$dsn; user=" . (defined $dbc->username() ? $dbc->username() : 'undef') ."\n"); # undef: postgres 'ident sameuser' login

    my $dbh;
    eval {
	$dbh = DBI->connect($dsn, $dbc->username(), $dbc->password(), $params);
    };
    if ($@ || (! $dbh)) {
	$self->throw("failed to open connection: " . $DBI::errstr);
    }
    return $dbh;
}

=head2 disconnect

 Title   : disconnect
 Usage   :
 Function: Disconnects all or a certain number of connections matching the
           parameters. The connections affected are those previously obtained
           through get_connection() (shared connections from a pool).
 Example :
 Returns : none
 Args    : Optionally, a Bio::DB::DBContextI implementing object. 
           Additional hashref parameter with settings that were passed to
           get_connection().


=cut

sub disconnect{
    my ($self,$dbc,$params) = @_;
    my @connpools = ();

    if(! $dbc) {
	# disconnect all pools that we have
	map { push(@connpools, $_); } (values %{$self->{'_dbh_pools'}});
    } else {
	my @keyvalues = $params ? %$params : ("default");
	# note that in the end the key doesn't carry meaning any more; the goal
	# is rather to ensure that two invocations with the same dbcontext
	# object and a hashref containing the same keys and values result in
	# the same key
	my $poolkey = "$dbc" . join(";", sort(@keyvalues));
	if(exists($self->{'_dbh_pools'}->{$poolkey})) {
	    push(@connpools, $self->{'_dbh_pools'}->{$poolkey});
	}
    }
    # do they actual disconnection
    foreach my $cpool (@connpools) {
	while(@$cpool) {
	    my $dbh = shift(@$cpool);
	    next unless $dbh; # during DESTROY there are indeed undef values --
                              # I have no idea where they come from
	    eval {
		$self->_remove_idsths($dbh);
		$dbh->disconnect();
	    };
	    $self->warn("error while closing connection: ".$@) if $@;
	}
    }
}

=head2 conn_params

 Title   : conn_params
 Usage   : $dbi->conn_params($requestor, $newval)
 Function: Gets/sets connection parameters suitable for the specific
           driver and the specific requestor.

           A particular implementation may choose to ignore the
           requestor, but it may also use it to return different
           parameters, based on, e.g., which interface the requestor
           implements. Usually the caller will pass $self as the value
           $requestor, but an implementation is expected to accept
           a class or interface name as well.

 Example : 
 Returns : a hashref to be passed to get_connection() or new_connection()
           (which would pass it on to DBI->connect()).
 Args    : The requesting object, or alternatively its class name or
           interface.
           Optionally, on set the new value (which must be undef or a
           hashref).


=cut

sub conn_params{
    my ($self,$req,$params) = @_;
    my $reqclass = ref($req) || $req;

    if( defined $params) {
	$self->{'_conn_params'}->{$reqclass} = $params;
    } else {
	# we try the class directly first
	if(exists($self->{'_conn_params'}->{$reqclass})) {
	    $params = $self->{'_conn_params'}->{$reqclass};
	} elsif(ref($req)) {
	    # for an object, try whether we have something for an interface
	    # it implements
	    foreach my $parent (keys %{$self->{'_conn_params'}}) {
		if($req->isa($parent)) {
		    $params = $self->{'_conn_params'}->{$parent};
		    last;
		}
	    }
	}
	$params = {} unless $params; # default is empty hash
    }
    return $params;
}

=head2 _idsth

 Title   : _idsth
 Usage   : $obj->_idsth($newval)
 Function: Get/set the last/next id value statement handle from/to
           the cache.

           Consider this method 'protected' in OO-speak. I.e., call it
           from derived modules, but not from outside.

 Example : 
 Returns : a last_id_value or next_id_value prepared statement, or all
           statements cached under the database handle if the key literal
           is omitted
 Args    : the database handle for which to cache the statement,
           a key literal to distinguish between statements (e.g., 
           'last' and 'next'),
           and optionall on set the statement handle to cache


=cut

sub _idsth{
    my ($self,$dbh,$key) = @_;

    $self->{'_idsth_$dbh'} = {} unless exists($self->{'_idsth_$dbh'});
    return values %{$self->{'_idsth_$dbh'}} unless $key;
    return $self->{'_idsth_$dbh'}->{$key} = shift if @_;
    return $self->{'_idsth_$dbh'}->{$key};
}

=head2 _remove_idsths

 Title   : _remove_idsths
 Usage   :
 Function: Un-caches all prepared statement handles cached under the
           given handle.
 Example :
 Returns : the list of previously cached statement handles
 Args    : the database handle


=cut

sub _remove_idsths{
    my ($self,$dbh) = @_;

    return () unless exists($self->{'_idsth_$dbh'});
    my @sths = values %{$self->{'_idsth_$dbh'}};
    delete $self->{'_idsth_$dbh'};
    return @sths;
}

sub DESTROY {
    my ($self) = @_;

    $self->disconnect();
    $self->SUPER::DESTROY;
}

sub dbcontext {
    my $self =shift;
    $self->{_dbcontext}=shift if @_;
    return $self->{_dbcontext};
}

1;
