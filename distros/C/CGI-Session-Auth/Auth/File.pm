###########################################################
# CGI::Session::Auth::File
# Authenticated sessions for CGI scripts
###########################################################
#
# $Id: File.pm 11 2005-10-08 23:59:12Z jlillich $
#

package CGI::Session::Auth::File;
use base qw(CGI::Session::Auth);

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = do { q$Revision: 11 $ =~ /Revision: (\d+)/; sprintf "1.%03d", $1; };

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
    
	# parameter 'UserFile': file containing user data
	$self->{userfile}  = $params->{UserFile} || 'auth_user.txt';
	# parameter 'GroupFile': file containing group data
	$self->{groupfile} = $params->{GroupFile} || 'auth_group.txt';
	# parameter 'PreLoadFiles': do we preload the user and group files into memory?
	$self->{preloadfiles} = $params->{PreLoadFiles} || 0;
    
	#
	# class members
	#

	# hash of registered users, each key is a user name, each value is an anon hash of user attributes
	$self->{users} = {};
	# hash of groups, each key is a group name, each value an anon array of user names
	$self->{groups} = {};

	# blessed are the greek
	bless($self, $class);

	# read authentication data
	if ($self->{preloadfiles}) {
		$self->_info("Preloading user and group files");
		$self->_readUserFile();
		$self->_readGroupFile();
	}

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

	my $result = 0;

	# Get the user data
	my %user_data = $self->_getUserData($username);

	# See if the credentials are valid
	if (%user_data) {
		if (defined $user_data{password}) {
			# check against plaintext password
			$result = ($user_data{password} eq $password);
		} elsif (defined $user_data{crypt_password}) {
			# check against crypted password
			$result = (crypt($password, $user_data{crypt_password}) eq $user_data{crypt_password});
		}
	}
	if ($result) {
		$self->_info("user '$username' logged in");
		# save the user profile
		$self->{userid} = $user_data{username};
		$self->{profile} = \%user_data;
	}

	return $result;
}

###########################################################

sub _ipAuth {

	die "IP based authentication is not implemented in CGI::Session::Auth::File yet";
}

###########################################################

sub _loadProfile {
    
	##
	## get user profile userid
	##

	my $self = shift;
	my ($username) = @_;
	$self->{userid} = $username;
	$self->{profile} = {$self->_getUserData($username)};
}

###########################################################

sub isGroupMember {
    
	##
	## check if user is in given group
	##

	my $self = shift;
	my ($group) = @_;
	my @users = $self->_getGroupData($group);
	my $username = $self->{userid};

	return grep { $_ eq $username } @users;
}

###########################################################
###
### internal methods
###
###########################################################

sub _readUserFile {
	my $self = shift;
	my $username = shift;

	# See if it has already been preloaded
	return if %{ $self->{users} };

	open(my $fd, '<', $self->{userfile}) or croak "Could not open user file: $!";

	# get field names from first line
	my $fieldlist = <$fd>;
	chomp $fieldlist;
	my @fieldnames = split(':', lc $fieldlist);
	# check for required fieldnames
	croak "UserFile does not have a 'username' field" if (not grep { 'username' } @fieldnames);
	croak "UserFile does not have a 'password' or 'crypt_password' field"
		if (not grep { $_ eq 'password' || $_ eq 'crypt_password' } @fieldnames);

	if ($username) {
		# just look for this username and return its profile

		# figure out what position the username field is in the file
		my $username_index = 0;
		for ($username_index = 0; $username_index < @fieldnames; $username_index++) {
			last if $fieldnames[$username_index] eq 'username';
		}
		croak "Can't find username column in file" if $username_index >= @fieldnames;

		# search until we find the username we are looking for
		while (my $record = <$fd>) {
			next unless index($record, $username) >= 0; # the username appears somewhere in the line
			chomp $record;
			my @fields = split(':', $record);
			# Check to make sure that we actually found the right username
			next unless $fields[$username_index] eq $username;
			# store fields in hash
			my %entry = ();
			foreach (@fieldnames) {
				$entry{$_} = shift @fields;
			}
			return %entry;
		}
	} else {
		# We preload the entire file into memory
		while (my $record = <$fd>) {
			chomp $record;
			my @fields = split(':', $record);
			# store fields in hash
			my $entry = {};
			foreach (@fieldnames) {
				$entry->{$_} = shift @fields;
			}
			# store hash
			$self->{users}->{$entry->{username}} = $entry;
		}
	}
	close($fd);

	return;
}

sub _readGroupFile {
	my $self = shift;
	my $group = shift;

	# See if it has already been preloaded
	return 1 if %{ $self->{groups} };

	# Parse the group file
	# format is similar to apache htgroup files
	#     GROUPNAME: USER1,USER2,USER3
	croak "Group file doesn't exist" unless -e $self->{groupfile};

	open(my $fd, '<', $self->{groupfile}) or croak "Could not open group file: $!";

	if ($group) {
		# We just search until we find the group we are looking for
		while (my $record = <$fd>) {
			next unless $record =~ /^$group\s*:/;
			chomp $record;
			my ($groupname, $groups) = split(/\s*:\s*/, $record);
			my @users = split(/\s*,\s*/,$groups);
			return @users;
		}
	} else {
		# we preload the entire group file into memory
		while (my $record = <$fd>) {
			chomp $record;
			my ($groupname, $groups) = split(/\s*:\s*/, $record);
			my @users = split(/\s*,\s*/,$groups);
			# store array
			$self->{groups}->{$groupname} = \@users;
		}
	}
	close($fd);

	return 1;
}

###########################################################

sub _getUserData {

	##
	## get all data about a user
	##

	my $self     = shift;
	my $username = shift;

	# Get the user data
	if (! $self->{preloadfiles}) {
		# userfile hasn't been preloaded
		return $self->_readUserFile($username);
	} elsif ($self->{users}->{$username}) {
		# userfile was preloaded and username exists
		return %{ $self->{users}->{$username} };
	}
	return;
}

sub _getGroupData {

	##
	## get a list of users that belong to the given group
	##

	my $self  = shift;
	my $group = shift;

	# Get the groups
	if (! $self->{preloadfiles}) {
		# groupfile hasn't been preloaded
		return $self->_readGroupFile($group);
	} elsif ($self->{groups}->{$group}) {
		# groupfile was preloaded and the group exists
		return @{ $self->{groups}->{$group} };
	}
	return;
}

1;
__END__
