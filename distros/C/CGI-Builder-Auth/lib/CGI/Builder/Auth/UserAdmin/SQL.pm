# $Id: SQL.pm,v 1.1.1.1 2004/06/28 19:24:28 veselosky Exp $
package CGI::Builder::Auth::UserAdmin::SQL;
use DBI;
use Carp ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(CGI::Builder::Auth::UserAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

my %Default = (HOST => "",                  #server hostname
	       DB => "",                    #database name
	       USER => "", 	            #database login name	    
	       AUTH => "",                  #database login password
	       DRIVER => "mSQL",            #driver for DBI
	       USERTABLE => "",             #table with field names below
	       NAMEFIELD => "user",         #field for the name
	       PASSWORDFIELD => "password", #field for the password
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_check(qw(DRIVER DB USERTABLE)); 
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

    # LS 12/1/97 -- Be sure to use Msql-modules-1.1814 (at least).
    # Do NOT  use the older DBD-mSQL-0.65.
    # The connect() method changed.
    my $source = sprintf("dbi:%s:%s",@{$self}{qw(DRIVER DB)});
    $source .= ":$self->{HOST}" if $self->{HOST};
    $source .= ":$self->{PORT}" if $self->{HOST} and $self->{PORT};
    $self->{'_DBH'} = DBI->connect($source,@{$self}{qw(USER AUTH)} ) 
	|| Carp::croak($DBI::errstr);
    return $old;
}

package CGI::Builder::Auth::UserAdmin::SQL::_generic;
use vars qw(@ISA);
@ISA = qw(CGI::Builder::Auth::UserAdmin::SQL);

sub add {
    my($self, $username, $passwd, $other) = @_;
    return(0, "add_user: no user name!") unless $username;
    return(0, "add_user: no password!") unless $passwd;
    return(0, "user '$username' already exists!") 
	if $self->exists($username);

    my(%f) = ($self->{NAMEFIELD}=>$username,
	      $self->{PASSWORDFIELD}=>$self->encrypt($passwd));
    if ($other) {
	Carp::croak('Specify other fields as a hash ref for SQL databases')
	    unless ref($other) eq 'HASH';
	  foreach (keys %{$other}) {
	      $f{$_} = $other->{$_};
	  }
    }
    my $statement = 
	sprintf("INSERT into %s (%s)\n VALUES (%s)\n",
		$self->{USERTABLE},
		join(',',keys %f),
		join(',', map {$self->{'_DBH'}->quote($f{$_})} keys %f));
#This _is_string this is silly.  It should be handled in the DBI::quote function.
#Further, if you really want to do that, the fast way is to use Scalar::Util::Numeric
		#join(',', map {$self->_is_string($_,$f{$_}) ? $self->{'_DBH'}->quote($f{$_}) : $f{$_} } keys %f));

    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    1;
}

sub exists {
    my($self, $username) = @_;
    my $statement = 
	sprintf("SELECT %s from %s WHERE %s=%s\n",
		@{$self}{qw(PASSWORDFIELD USERTABLE NAMEFIELD)}, $self->{'_DBH'}->quote($username));
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my(@row) = $sth->fetchrow;
    $sth->finish;
    return $row[0];
}

sub delete {
    my($self, $username) = @_;
    my $statement = 
	sprintf("DELETE from %s where %s=%s\n",
		@{$self}{qw(USERTABLE NAMEFIELD)}, $self->{'_DBH'}->quote($username));
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub update {
    my($self, $username, $passwd,$other) = @_;
    return 0 unless $self->exists($username);

    my(%f);
    if ($other) {
	Carp::croak('Specify other fields as a hash ref for SQL databases')
	    unless ref($other) eq 'HASH';
	  foreach (keys %{$other}) {
	      $f{$_} = $other->{$_};
	  }
    }

    $f{$self->{PASSWORDFIELD}}=$self->encrypt($passwd) if $passwd;

    my $statement = 
	sprintf("UPDATE %s SET %s\n WHERE %s = '%s'\n",
		$self->{USERTABLE},
		join(',', map {$_ . "=" . $self->{_DBH}->quote($f{$_}) } keys %f),
		#join(',', map {$_ . "=" . ($self->_is_string($_,$f{$_}) ? "'$f{$_}'" : $f{$_}) } keys %f),
		$self->{NAMEFIELD}, $username);
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub list {
    my($self) = @_;
    my $statement = 
	sprintf("SELECT %s from %s\n",
		@{$self}{qw(NAMEFIELD USERTABLE)});
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my($user,@list);
    while($user = $sth->fetchrow) {
	push(@list, $user);
    }
    $sth->finish;
    return @list;
}

sub fetch {
    my($self,$username,@fields) = @_;
    return(0, "fetch: no user name!") unless $username;
    return(0, "fetch: user '$username' doesn't exist") 
	unless $self->exists($username);
    my (@f);
    foreach (@fields) {
	push(@f,ref($_) ? @$_ : $_);
    }
    push (@f,'*') unless @f;
    my $statement = 
	sprintf("SELECT %s FROM %s WHERE %s = %s",
		join(',',@f),
		@{$self}{qw/USERTABLE NAMEFIELD/},
		$self->{'_DBH'}->quote($username));
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::errstr);
    my $result = $sth->fetchrow_hashref;
    $sth->finish;
    return $result;
}

#sub _is_string {
#    my ($self,$field_name,$field_value) = @_;
#    if ($self->{DRIVER} =~ /^msql$/i) {
#	unless ($self->{'_TYPES'}) {
#	    require Msql;
#	    my $st = $self->{'_DBH'}->prepare("LISTFIELDS $self->{USERTABLE}") 
#		|| Carp::croak($DBI::errstr);
#	    $st->execute || Carp::croak($DBI::errstr);
#	    my $types = $st->{msql_type};
#	    foreach (@{$st->{NAME}}) {
#		$self->{'_TYPES'}->{$_} = Msql::CHAR_TYPE() eq (shift @{$types});
#	    }
#	    $st->finish();
#	}
#	return $self->{'_TYPES'}->{$field_name};
#    } else {
#	return $field_value !~ /^[0-9.E-]+$/i;
#    }
#}

sub encrypt {
    my($self) = shift; 
    my($passwd) = "";
    my($scheme) = $self->{ENCRYPT} || "crypt";
    # not quite sure where we're at risk here...
    # I am.  SQL injection is possible the previous way if crypt is ever broken.  -Rusty Phillips
    # $_[0] =~ /^[^<>;|]+$/ or Carp::croak("Bad password name"); $_[0] = $&;
    if (($self->{DRIVER} =~ /^mysql$/i) && ($scheme =~ /^MySQL(:?-Password)?$/i)) {
        my $statement = "SELECT password(?)\n";
        print STDERR $statement if $self->debug;
        my $sth = $self->{'_DBH'}->prepare($statement);
        Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	    unless $sth;
        $sth->execute($_[0]) || Carp::croak($DBI::errstr);
        my(@row) = $sth->fetchrow;
        $sth->finish;
        $passwd = $row[0];
    } else {
	$passwd = $self->SUPER::encrypt(@_);
    }
    return $passwd;
}

1;

__END__

CREATE table auth_users (
    user char(40),
    password char(20)
)
   
