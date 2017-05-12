###########################################################
# CGI::Session::Auth::DBI
# Authenticated sessions for CGI scripts
###########################################################
#
# $Id: DBI.pm 25 2006-02-21 12:07:26Z geewiz $
#

package CGI::Session::Auth::DBI;
use base qw(CGI::Session::Auth);

use 5.008;
use strict;
use warnings;
use Carp;
use DBI;

our $VERSION = do { q$Revision: 25 $ =~ /Revision: (\d+)/; sprintf "1.%03d", $1; };

###########################################################
###
### general methods
###
###########################################################

###########################################################

sub new {
    
    ##
    ## build new class object
    ##
    
    my $class = shift;
    my ($params) = shift;
    
    $class = ref($class) if ref($class);
    
    # initialize parent class
    my $self = $class->SUPER::new($params);
    
    #
    # class specific parameters
    #

	# parameter 'DBHandle': use an initialized DBI database handle
    if ($params->{DBHandle}) {
      $self->{dbh} = $params->{DBHandle};
    } else {
      # parameter 'DSN': DBI data source name
      my $dsn = $params->{DSN} || croak("No DSN parameter");
      # parameter 'DBUser': database connection username
      my $dbuser = $params->{DBUser} || '';
      # parameter 'DBPasswd': database connection password
      my $dbpasswd = $params->{DBPasswd} || "";
      # parameter 'DBAttr': optional database connection attributes
      my $dbattr = $params->{DBAttr} || {};
      # database handle
      $self->{dbh} = DBI->connect($dsn, $dbuser, $dbpasswd, $dbattr) or croak("DB error: " . $DBI::errstr);
    }
    
    # parameter 'EncryptPW': passwords are MD5-encrypted (default 0)
    $self->{encryptpw} = $params->{EncryptPW} || 0;
    # parameter 'UserTable': name of user data table
    $self->{usertable} = $params->{UserTable} || 'auth_user';
    $self->{usernamefield} = $params->{UsernameField} || 'username';
    $self->{passwordfield} = $params->{PasswordField} || 'passwd';
    $self->{useridfield} = $params->{UserIDField} || 'userid';
    # parameter 'GroupTable': name of user data table
    $self->{grouptable} = $params->{GroupTable} || 'auth_group';
    $self->{groupfield} = $params->{GroupField} || 'groupname';
    $self->{groupuseridfield} = $params->{GroupUserIDField} || 'userid';
    # parameter 'IPTable': name of ip network table
    $self->{iptable} = $params->{IPTable} || 'auth_ip';
    $self->{ipuseridfield} = $params->{IPUserIDField} || 'userid';
    $self->{ipaddressfield} = $params->{IPAddressField} || 'network';
    $self->{ipmaskfield} = $params->{IPNetMaskField} || 'netmask';
    
    #
    # class members
    #
    
    # blessed are the greek
    bless($self, $class);
    
    return $self;
}

###########################################################
###
### backend specific methods
###
###########################################################

###########################################################

sub _login {
    
    ##
    ## check username and password
    ##
    
    my $self = shift;
    my ($username, $password) = @_;
    
    $self->_debug("username: $username, password: $password");

    if ($self->{encryptpw}) {
		$password = $self->_encpw($password);
		$self->_debug("Encrypted password: $password");
	}

    my $result = 0;
    
    my $query = sprintf(
        "SELECT * FROM %s WHERE %s = ? AND %s = ?",
        $self->{usertable},
        $self->{usernamefield},
        $self->{passwordfield},
    );
    $self->_debug("query: $query");
    # search for username
    my $sth = $self->_dbh->prepare($query);
    $sth->execute($username, $password) or croak $self->_dbh->errstr;
    if (my $rec = $sth->fetchrow_hashref) {
        $self->_debug("found user entry");
        $self->_extractProfile($rec);
        $result = 1;
        $self->_info("user '$username' logged in");
    }
    $sth->finish;
    
    return $result;
}

###########################################################

sub _ipAuth {
    
    ##
    ## authenticate by the visitors IP address
    ##
    
    my $self = shift;
    
    require NetAddr::IP;
    
    my $remoteip = new NetAddr::IP($self->_cgi->remote_host);
    $self->_debug("checking remote IP $remoteip");
    
    my $result = 0;
    
    my $query = sprintf(
        "SELECT %s, %s, %s FROM %s",
        $self->{ipuseridfield},
        $self->{ipaddressfield},
        $self->{ipmaskfield},
        $self->{iptable}
    );
    $self->_debug("query: $query");
    
    # search for username
    my $sth = $self->_dbh->prepare($query);
    $sth->execute or croak $self->_dbh()->errstr;
    while (my $rec = $sth->fetchrow_hashref) {
        
        $self->_debug("compare IP network ", $rec->{$self->{ipaddressfield}}, "/", $rec->{$self->{ipmaskfield}});
        
        if ($remoteip->within(new NetAddr::IP( $rec->{$self->{ipaddressfield}}, $rec->{$self->{ipmaskfield}}))) {
            $self->_debug("we have a winner!");
            # get user record
            my $user = $self->_getUserRecord($rec->{$self->{ipuseridfield}});
            $self->_extractProfile($user);
            $result = 1;
            last;
        }
        else {
            $self->_debug("no member of this network");
        }
        
    }
    $sth->finish;
    
    return $result;
}

###########################################################

sub _loadProfile {
    
    ##
    ## get user profile from database by userid
    ##
    
    my $self = shift;
    my ($userid) = @_;
    
    my $query = sprintf(
        "SELECT * FROM %s WHERE %s = ?",
        $self->{usertable},
        $self->{useridfield}
    );
    $self->_debug("query: $query");
    my $sth = $self->_dbh->prepare($query);
    $sth->execute($userid) or croak $self->_dbh()->errstr;
    if (my $rec = $sth->fetchrow_hashref) {
        $self->_debug("Found user entry");
        $self->_extractProfile($rec);
    }
    $sth->finish;
}

###########################################################

sub saveProfile {

    ##
    ## save probably modified user profile
    ##

    my $self = shift;
    
    my $query = "UPDATE " . $self->{usertable} . " SET ";
    my @values;
    my $first = 1;
	foreach (keys %{$self->{profile}}) {
		if ($_ ne $self->{useridfield}) {
			$query .= (($first) ? '' : ', ') . $_ . " = ?";
			push @values, $self->{profile}{$_};
			$first = 0;
		}
	}
	$query .= " WHERE " . $self->{useridfield} . " = ?";
	$self->_debug("update query: ", $query);

    my $sth = $self->_dbh()->prepare($query);
    $sth->execute(@values, $self->{userid}) or croak $self->_dbh()->errstr;
	    
}

###########################################################

sub isGroupMember {
    
    ##
    ## check if user is in given group
    ##
    
    my $self = shift;
    my ($group) = @_;
    
    $self->_debug("group: $group");
    
    my $result = 0;
    
    my $query = sprintf(
        "SELECT * FROM %s WHERE %s = ? AND %s = ?",
        $self->{grouptable},
        $self->{groupuseridfield},
        $self->{groupfield}
    );
    $self->_debug("query: $query");
    $self->_debug("values: $self->{userid}, $group");
    # search for username
    my $sth = $self->_dbh->prepare($query);
    $sth->execute($self->{userid}, $group) or croak $self->_dbh->errstr;
    if (my $rec = $sth->fetchrow_hashref) {
        $self->_debug("found group entry");
        $result = 1;
    }
    $sth->finish;
    
    return $result;
}

###########################################################
###
### internal methods
###
###########################################################

###########################################################

sub _dbh {
    
    ##
    ## return database handle
    ##
    
    my $self = shift;
    
    return $self->{dbh};
}

###########################################################

sub _extractProfile {
    
    ##
    ## get user profile from database record
    ##
    
    my $self = shift;
    my ($rec) = @_;
    
    $self->{userid} = $rec->{$self->{useridfield}};
    foreach ( keys %$rec ) {
        $self->{profile}{$_} = $rec->{$_};
    }
};

###########################################################

sub _getUserRecord {
    
    ##
    ## get user data by user id
    ##
    
    my $self = shift;
    my ($userid) = @_;
    
    $self->_debug("get data for userid: ", $userid);
    
    my $query = sprintf(
        "SELECT * FROM %s WHERE %s = ?",
        $self->{usertable},
        $self->{useridfield}
    );
    $self->_debug("query: $query");
    # search for username
    my $sth = $self->_dbh->prepare($query);
    $sth->execute($userid) or croak $self->_dbh->errstr;
    
    return $sth->fetchrow_hashref;
}

###########################################################
###
### end of code, module documentation below
###
###########################################################

1;
__END__

=head1 NAME

CGI::Session::Auth::DBI - Authenticated sessions for CGI scripts

=head1 SYNOPSIS

  use CGI;
  use CGI::Session;
  use CGI::Session::Auth::DBI;

  my $cgi = new CGI;
  my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});
  my $auth = new CGI::Session::Auth::DBI({
      CGI => $cgi,
      Session => $session,
      DSN => 'dbi:mysql:host=localhost,database=cgiauth',
  });
  $auth->authenticate();
  
  if ($auth->loggedIn) {
      showSecretPage;
  }
  else {
      showLoginPage;
  }



=head1 DESCRIPTION

CGI::Session::Auth::DBI is a subclass of L<CGI::Session::Auth>. It uses a
relational database for storing the authentication data, using the L<DBI> module
as database interface.

=head2 Database setup

Use your favourite database administration tool to create
and populate the database:

CREATE TABLE auth_user (
    userid CHAR(32) NOT NULL,
    username VARCHAR(30) NOT NULL,
    passwd VARCHAR(32) NOT NULL default '',
    PRIMARY KEY (userid),
    UNIQUE username (username)
);

INSERT INTO auth_user VALUES ( '325684ec1b028eaf562dd484c5607a65', 'admin', 'qwe123' );
INSERT INTO auth_user VALUES ( 'ef19a80d627b5c48728d388c11900f3f', 'guest', 'guest' );

CREATE TABLE auth_group (
    groupname VARCHAR(30) NOT NULL,
    userid CHAR(32) NOT NULL,
    PRIMARY KEY (groupname)
);

CREATE TABLE auth_ip (
    network char(15) NOT NULL,
    netmask char(15) NOT NULL,
    userid char(32) NOT NULL,
    PRIMARY KEY (network, netmask)
);

INSERT INTO auth_ip VALUES ('127.0.0.1', '255.0.0.0',  'ef19a80d627b5c48728d388c11900f3f' );

Mandatory columns in C<auth_user> are C<userid>, C<username> and C<passwd>.
All additional columns will also be stored and accessible as user profile fields.

C<userid> is a 32-character string and can be generated randomly by

perl -MCGI::Session::Auth -e 'print CGI::Session::Auth::uniqueUserID("myname"), "\n";'

The C<auth_ip> table is used for IP address based authentication. Every row combines a pair of network
address and subnet mask (both in dotted quad notation) with a user ID. The C<userid> column
is used as a foreign key into the C<auth_user> table.


=head2 Constructor parameters

Additional to the standard parameters used by the C<new> constructor of
all CGI::Session::Auth classes, CGI::Session::Auth::DBI understands the following parameters:

=over 1

=item B<DBHandle>: Active database handle.  For an explanation, see the L<DBI> documentation.

=item B<DSN>: Data source name for the database connection.
For an explanation, see the L<DBI> documentation.

=item B<DBUser>: Name of the user account used for the database connection. (Default: none)

=item B<DBPasswd>: Password of the user account used for the database connection. (Default: none)

=item B<DBAttr>: Optional attributes used for the database connection. (Default: none)

=item B<UserTable>: Name of the table containing the user authentication data and profile. (Default: 'auth_user')

=item B<UserIDField>: Name of the column for the user id key. (Default: 'userid')

=item B<UsernameField>: Name of the column for the user name. (Default: 'username')

=item B<PasswordField>: Name of the column for the user password. (Default: 'passwd')

=item B<GroupTable>: Name of the table containing user group relations. For every user that belongs to a group, there is a record with the group name and the user's id. (Default: 'auth_group')

=item B<GroupField>: Name of the column for the group name. (Default: 'groupname')

=item B<GroupUserIDField>: Name of the column for the user id. (Default: 'userid')

=item B<IPTable>: Name of the table containing the by-IP authentication data. (Default: 'auth_ip')

=item B<IPUserIDField>: Name of the column for the user id. (Default: 'userid')

=item B<IPAddressField>: Name of the column for the IP address. (Default: 'network')

=item B<IPNetMaskField> Name of the column for the IP network mask. (Default: 'netmask')

=back



=head1 SEE ALSO

L<CGI::Session::Auth>



=head1 AUTHOR

Jochen Lillich, E<lt>geewiz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2010 by Jochen Lillich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
