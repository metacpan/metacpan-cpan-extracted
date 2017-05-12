# $Id: SQL.pm,v 1.1.1.1 2004/06/28 19:24:28 veselosky Exp $
package CGI::Builder::Auth::GroupAdmin::SQL;
use strict;
use DBI;
use Carp ();
use vars qw(@ISA $VERSION);
@ISA = qw(CGI::Builder::Auth::GroupAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

my %Default = (
	       HOST => "",                  #server hostname
               PORT => "",                  #server port
	       DB => "",                    #database name
	       USER => "", 	            #database login name	    
	       AUTH => "",                  #database login password
	       DRIVER => "mSQL",            #driver for DBI
	       GROUPTABLE => "",             #table with field names below
	       NAMEFIELD => "user",         #field for the name
	       GROUPFIELD => "group",       #field for the group
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_check(qw(DRIVER DB GROUPTABLE)); 
    if(!defined $self->{'DBH'}) { $self->db($self->{DB}) }
    else { $self->{'_DBH'} = $self->{'DBH'}; };
    return $self;
}

sub DESTROY {
    my($self) = @_;
    #Don't disconnect if you didn't make it.
    $self->{'_DBH'}->disconnect if(!defined $self->{'DBH'});
}

sub db {
    my($self,$db) = @_;
    my $old = $self->{DB};
    return $old unless $db;
    $self->{DB} = $db; 

    if(defined $self->{'_DBH'}) {
	$self->{'_DBH'}->disconnect;
    }

    my $source = sprintf("dbi:%s:%s",@{$self}{qw(DRIVER DB)});
    $source .= ":$self->{HOST}" if $self->{HOST};
    $source .= ":$self->{PORT}" if $self->{HOST} and $self->{PORT};
    $self->{'_DBH'} = DBI->connect($source,@{$self}{qw(USER AUTH)} ) 
	|| Carp::croak($DBI::errstr);
    return $old;
}

package CGI::Builder::Auth::GroupAdmin::SQL::_generic;
use vars qw(@ISA);
@ISA = qw(CGI::Builder::Auth::GroupAdmin::SQL);

sub create { return shift->add(@_); }


sub add {
	my $self = shift;
    my($groupname,$username) = @_;
    my $statement;
    #This function is sometimes called to create a group.  So it has to be able to accept only a group name, and no username.     #It will then create a placeholder that has no username, but a groupname.
    #return(0, "add_group: no user name!") unless $username;  
    if(defined $username) {
    return(0, "add_group: no group!") unless $groupname;
    return(0, "user '$username' already exists in group '$groupname'") 
	if $self->exists($groupname,$username);

    $statement = 
	$self->{GROUPTABLE} ne $self->{USERTABLE} ?
	    sprintf("INSERT into %s (%s,%s)\n VALUES (?,?)\n",
		    @{$self}{ qw(GROUPTABLE NAMEFIELD GROUPFIELD) })
		:
            sprintf("UPDATE %s\n SET %s=?\n WHERE %s=?\n",
		    $self->{GROUPTABLE},$self->{NAMEFIELD},
		    $self->{GROUPFIELD});
			    
    #print STDERR $statement if $self->debug;
    }
    else {
    	    return(0, "group already exists") if($self->exists($groupname));
	    $statement = sprintf("INSERT into %s (%s)\n VALUES (?)\n",
		    @{$self}{ qw(GROUPTABLE GROUPFIELD) })
   };

   my $sth = $self->{'_DBH'}->prepare($statement) || Carp::croak($DBI::errstr);
   $sth->execute(@_) || Carp::croak($DBI::errstr);
}

sub exists {
    my ($self,$groupname,$username) = @_;
    return(0, "exists: no group!") unless $groupname;
    my $select = "$self->{GROUPFIELD}=" . $self->{'_DBH'}->quote($groupname);
    $select = "$self->{GROUPFIELD} like" . $self->{'_DBH'}->quote($groupname)  if ($groupname =~ /%/);
    $select .= " AND $self->{NAMEFIELD}=" . $self->{'_DBH'}->quote($username) if defined $username;
    my $statement = 
	sprintf("SELECT DISTINCT %s FROM %s WHERE %s",
		@{$self}{qw(GROUPFIELD GROUPTABLE)},
		$select);
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement) || Carp::croak($DBI::errstr);
    $sth->execute || Carp::croak($DBI::errstr);
    my $result = $sth->rows;
    $sth->finish;
    return $result;
}

sub delete {
    my ($self,$username,$groupname) = @_;
    return(0, "delete: no username!") unless defined $username;

    # if the group table and the user table are the same, then
    # we do not remove the record -- otherwise everything else
    # disappears too!
    return 1 if $self->{GROUPTABLE} eq $self->{USERTABLE};

    $groupname = $self->{NAME} unless defined $groupname;
    my $select = "$self->{NAMEFIELD}='$username' AND $self->{GROUPFIELD}='$groupname'" if defined $groupname;
    my $statement = 
	sprintf("DELETE FROM %s WHERE %s = %s AND %s = %s",
		$self->{GROUPTABLE},
		$self->{NAMEFIELD},$self->('_DBH')->quote($username),
		$self->{GROUPFIELD},$self->{'_DBH'}->quote($groupname));
    print STDERR $statement if $self->debug;
    my $rv = $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    return $rv;
}

sub remove {
    my ($self,$groupname) = @_;
    return(0, "remove: no groupname!") unless defined $groupname;
    my $statement = 
	sprintf("DELETE FROM %s WHERE %s = %s",
		@{$self}{qw(GROUPTABLE GROUPFIELD)},$self->{'_DBH'}->quote($groupname));
    print STDERR $statement if $self->debug;
    my $rv = $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    return $rv;
}

sub list {
    my($self,$groupname) = @_;
    my $statement;
    if (defined $groupname) {
	$statement =
	    sprintf("SELECT DISTINCT %s FROM %s WHERE %s = '%s'",
		    @{$self}{qw(NAMEFIELD GROUPTABLE GROUPFIELD)},
		    $groupname);    
        if ($groupname =~ /%/)
        {
	  $statement =
	      sprintf("SELECT DISTINCT %s FROM %s WHERE %s like '%s'",
	 	    @{$self}{qw(NAMEFIELD GROUPTABLE GROUPFIELD)},
		    $groupname);    
        }
    } else {
	$statement =
	    sprintf("SELECT DISTINCT %s FROM %s",
		    @{$self}{qw(GROUPFIELD GROUPTABLE GROUPFIELD)});    
    }
    print STDERR $statement if $self->debug;

    my $sth = $self->{'_DBH'}->prepare($statement) || Carp::croak($DBI::errstr);
    $sth->execute || Carp::croak($DBI::errstr);

    my @result = ();
    while (my $a = $sth->fetchrow_arrayref) {
	push(@result,@$a);
    }
    return @result;
}

1;
