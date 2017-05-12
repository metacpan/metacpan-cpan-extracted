package CGI::FileManager::Auth;

use strict;
use warnings;
use Carp qw(croak);

use FindBin qw($Bin);
use Unix::PasswdFile;

=head1 SYNOPIS

 my $auth = CGI::FileManager::Auth->new();
 if ($auth->verify($username, $password)) {
   # Valid user
 } else {
   $ Invalid username/password pair
 }

 Currently username/password pairs are hard coded and clear text. Just for testing.
 Later we expect to have Authentication plugins to the system and this module will probably
 hide them from the real module.

=cut


=head2 new

 my $auth = CGI::FileManager::Auth->new;

 Does nothing

=cut
sub new {
	my $class   = shift;
	my $args    = shift;
	if (not $args or ref $args ne "HASH" or not defined $args->{PASSWD_FILE}) {
		croak __PACKAGE__ . " needs a PASSWD_FILE to work with";
	}

=pod

	my $self    = {
		users => {
			gabor => {
				password => 'nincs',
				home     => "$Bin/../dir",
				#home     => '/home/gabor/work/gabor/dev/CGI-FileManager/dir',
			}
		},
	};
	bless $self, $class;
	
=cut

	bless $args, $class;
}

=head2 home

Return the home directory of the given user
=cut
sub home {
	my ($self, $username) = @_;

	my $pw = new Unix::PasswdFile $self->{PASSWD_FILE};
	return $pw->home($username); 

	
#	return if not defined $self->{users};
#	return if not defined $self->{users}->{$username};
#	return if not defined $self->{users}->{$username}->{home};

#	return $self->{users}->{$username}->{home};
}

=head2 verify

verify username password

=cut
sub verify {
	my ($self, $username, $password) = @_;

	my $pw = new Unix::PasswdFile $self->{PASSWD_FILE};

	return 0 if not $pw->user($username); 
	
	my $saved_pw = $pw->passwd($username);
	return crypt($password, substr($saved_pw,0,2)) eq $saved_pw ? 1 : 0;


#	return 0 if not defined $self->{users};
#	return 0 if not defined $self->{users}->{$username};
#	return 0 if not defined $self->{users}->{$username}->{password};
#	return 1 if $self->{users}->{$username}->{password} eq $password;

#	return 0;
}

1;

			
