package Catalyst::Plugin::Authentication::Credential::CHAP;
use base qw/ Catalyst::Plugin::Authentication::Credential::Password /; 

use strict;
use vars qw/ $VERSION /;
use warnings;

$VERSION = '0.03';

use Scalar::Util ();
use Catalyst::Exception ();
use Digest ();

sub setup {

	my $c = shift;

	unless ($c->registered_plugins ('Session')) {
		my $err = "The CHAP plugin requires Catalyst::Plugin::Session to be loaded!";
		$c->log->fatal ($err);
		Catalyst::Exception->throw ($err);
	}

	# default values
	$c->config->{authentication}->{chap}->{length} ||= 40;
	$c->config->{authentication}->{chap}->{hash_algorithm} ||= 'MD5';
	$c->config->{authentication}->{chap}->{chars} = ['a'..'z', 'A'..'Z', '0'..'9'];

	$c->NEXT::setup (@_);

}


sub chap_init {
	my ($c, $force) = shift;
	$force ||= 0;
	if ($c->session->{_chap_challenge_string}) {
		return unless $force == 1;
	}
	$c->gen_challenge_string;
}

sub _generate_challenge_string {
	my $c = shift;
	my $str;
	my $length = $c->config->{authentication}->{chap}->{length};
	foreach (1..$length) {
		$str .= @{$c->config->{authentication}->{chap}->{chars}}[rand @{$c->config->{authentication}->{chap}->{chars}}];
	}
	return $str;
}

sub gen_challenge_string {
	my $c = shift;
	my $str = $c->_generate_challenge_string;
  	$c->session->{_chap_challenge_string} = $str;

}

sub get_challenge_string {
	my $c = shift;
	return $c->session->{_chap_challenge_string}; 
}

sub _check_password {
	my ($c, $user, $password) = @_;

	my $user_password;

	if ($user->supports (qw/ password clear /)) {
		$user_password = $user->password;
 	} elsif ($user->supports (qw/ password hashed /)) {
		$user_password = $user->hashed_password;
  	} else {
    		Catalyst::Exception->throw("The authentication mechanism must be either clear or hashed.");
  	}

	my $d = Digest->new($c->config->{authentication}->{chap}->{hash_algorithm});
  	$d->add ($user_password);
  	$d->add ($c->get_challenge_string);
  	my $chap_password = $d->hexdigest;

  	if ($c->debug) {
		$c->log->debug ("User stored password: $user_password");
		$c->log->debug ("User stored challenge: " . $c->get_challenge_string);
		$c->log->debug ("CHAP Hash algorithm: " . $c->config->{authentication}->{chap}->{hash_algorithm});
		$c->log->debug ("User chap password: $chap_password");
	}

  	return (($chap_password eq $password));
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Credential::CHAP - Authenticate a user
using a CHAP login system.

=head1 SYNOPSIS

    use Catalyst qw/
      Session 
      Session::Store::File 
      Session::State::Cookie
      Authentication
      Authentication::Store::Foo
      Authentication::Credential::CHAP
      /;

    __PACKAGE__->config->{authentication}->{chap} = {
        hash_algorithm => 'SHA-1',
    };

    sub begin : Private {
        my ($self, $c) = @_;
        $c->chap_init; # Generate a Challenge string and stores it in the session.
        $c->stash("challenge_string", $c->get_challenge_string);
        
    }

    package MyApp::Controller::Auth;

    # *** NOTE ***
    # if you place an action named 'login' in your application's root (as
    # opposed to inside a controller) the following snippet will recurse,
    # giving you lots of grief.
    # never name actions in the root controller after plugin methods - use
    # controllers and : Global instead.

    sub login : Local {
        my ( $self, $c ) = @_;

        $c->login( $c->req->param('username'), $c->req->param('password') );
    }


    # Template.html
    <form name="MyForm">
    <input type="password" name="form_password" onclick="sendPassword();"/>
    <input type="hidden" name="password" value="" />
    <input type="hidden" name="challenge" value="[% challenge_string %]" />
    </form>

    # Javascript (Client side)
    function sendPassword() {
        var password = document.forms['MyForm'].form_password.value
                       + document.forms['MyForm'].challenge.value;
        document.forms['MyForm'].password.value = encode_sha1(password);
        document.forms['MyForm'].form_password.value = '';
        document.forms['MyForm'].challenge.value = '';
        document.forms['MyForm'].submit();
    }


=head1 DESCRIPTION

This credential checker inherits from L<Catalyst::Plugin::Authentication::Credential::Password>.
It generates a challenge string that the user agent must concatenate to the password 
before encoding it with a hash algorithm. When logging in, this plugin will compare the
sent password to the one stored, encoded with the same challenge string saved in the session data.
It is meant to allow you to securely send passwords over a clear HTTP connection.


=over 4

=item clear text password

If the user has a clear text password it will be compared directly. You just have to 
concatenate the challenge string to the password and encode it with any of the hash methods
supported by the L<Digest> module.

=item hashed password

If the stored password is hashed, you will have to encode it in your client BEFORE concatenating
the challenge string to it, and then encode the whole string again before sending it to the server.


=item crypted password

UNIX crypt hashed password are not supported. You must store your passwords either in clear 
or hashed.

=back

=head1 REQUIREMENTS

You must use Sessions.

=head1 CONFIGURATION

=over 4

=item __PACKAGE__->config->{authentication}->{chap}->{length}

The length of the challenge string. Default is 40.


=item __PACKAGE__->config->{authentication}->{chap}->{hash_algorithm}

The hash method used to encode the password+challenge string, client-side. It can 
be any method supported by the L<Digest> module, as long as you have a way to use the
same on the client. Default is MD5. More information and javascript functions can be found
at L<http://pajhome.org.uk/crypt/md5/>.

=back

=head1 METHODS

=over 4

=item login $username, $password

Inherited from L<Catalyst::Plugin::Authentication::Credential::Password>.

Try to log a user in.

C<$username> can be a string (e.g. retrieved from a form) or an object. 
If the object is a L<Catalyst::Plugin::Authentication::User> it will be used 
as is. Otherwise C<< $c->get_user >> is used to retrieve it.

C<$password> is a hash of the password and the challenge string, encoded 
client side.

If C<$username> or C<$password> are not provided, the query parameters 
C<login>, C<user>, C<username> and C<password>, C<passwd>, C<pass> will 
be tried instead.

=item chap_init $force

Generates a challenge string for the current session. You can put it in your root's
begin/end actions if needed, the challenge string won't change until the session ends
or you call this method with C<$force> set to 1.

=item get_challenge_string

Returns the current challenge string.

=item setup

=item gen_challenge_string


=back

=head1 RELATED USAGE

After the user is logged in, the user object for the current logged in user 
can be retrieved from the context using the C<< $c->user >> method.

The current user can be logged out again by calling the C<< $c->logout >> 
method.

=head1 SUPPORTING THIS PLUGIN

See L<Catalyst::Plugin::Authentication::Credential::Password>.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authentication::Credential::Password>, 
L<Catalyst::Plugin::Session>.

=head1 AUTHOR

    Renaud Drousies.

=cut


