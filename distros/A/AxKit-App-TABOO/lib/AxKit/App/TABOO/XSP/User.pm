package AxKit::App::TABOO::XSP::User;
use 5.6.0;
use strict;
use warnings;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO;
use AxKit::App::TABOO::Data::User;
use AxKit::App::TABOO::Data::User::Contributor;
use Session;
use Apache::Cookie;
use Crypt::GeneratePassword;
use Data::Dumper;

use vars qw/$NS/;


our $VERSION = '0.4';

# Some constants
# TODO: This stuff should go somewhere else!

use constant GUEST     => 0;
use constant NEWMEMBER => 1;
use constant MEMBER    => 2;
use constant OLDTIMER  => 3;
use constant ASSISTANT => 4;
use constant EDITOR    => 5;
use constant ADMIN     => 6;
use constant DIRECTOR  => 7;
use constant GURU      => 8;
use constant GOD       => 9;


=head1 NAME

AxKit::App::TABOO::XSP::User - User information management and authorization tag library for TABOO

=head1 SYNOPSIS

Add the user: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::User


=head1 DESCRIPTION

This XSP taglib provides a few tags to retrieve, set, modify and save
user information, as it communicates with TABOO Data objects,
particulary L<AxKit::App::TABOO::Data::User> and
<AxKit::App::TABOO::Data::User::Contributor>.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=cut

$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/User';

# Shamelessly lifted from Joergs module
sub makeSalt {
	my $result = '$1$';
	my @chars = ('.', '/', 0..9, 'A'..'Z', 'a'..'z');
	for (0..7) {
		$result .= $chars[int(rand(64))];
	}
	$result .= '$';
	return $result;
}


# This little sub takes the user name of the user we want to change 
# the authlevel of, and returns a hash with the smallest and highest 
# level we are allowed to give that user. 
sub authlevel_extremes {
    my $username = shift;
    my $r = Apache->request;
    my $session = AxKit::App::TABOO::session($r);
    my $authlevel = AxKit::App::TABOO::authlevel($session);
    my $maxlevel = ($username eq AxKit::App::TABOO::loggedin($session)) ? $authlevel : ($authlevel - 2);
    my $user = AxKit::App::TABOO::Data::User::Contributor->new();
    my $oldlevel = $user->load_authlevel($username);
    my $minlevel = ($authlevel < AxKit::App::TABOO::XSP::User::ADMIN) ? $oldlevel : 0;
    return {'minlevel' => $minlevel, 'maxlevel' => $maxlevel};
}


sub _sanatize_username {
    my $tmp = lc shift;
    $tmp =~ tr/a-z/_/cs;
    return $tmp;
}

sub _exists_check {
  my $username = shift;
  my $user = AxKit::App::TABOO::Data::User->new();
  if (($username =~ m/comment|thread|all|respond|edit/) || ($user->load_name($username)) || ($username ne _sanatize_username($username))) {
    return 1;
  } else {
    return 0;
  }
}


package AxKit::App::TABOO::XSP::User::Handlers;


=head1 Tag Reference

=head2 C<E<lt>store/E<gt>>

It will take whatever data it finds in the L<Apache::Request> object
held by AxKit, and hand it to a new L<AxKit::App::TABOO::Data::User>
object, which will use whatever data it finds useful. It may also take
C<newpasswd1> and C<newpasswd2> fields, and if they are encountered,
they will be checked if they are equal and then the password will be
encrypted before it is sent to the Data object. The Data object is
then instructed to save itself.

=cut

sub store {
    return << 'EOC';
    my %args = map { $_ => join('', $cgi->param($_)) } $cgi->param;
    my $session = AxKit::App::TABOO::session($r);
    my $editinguser = AxKit::App::TABOO::loggedin($session);
    my $authlevel = AxKit::App::TABOO::authlevel($session);
    AxKit::Debug(9, $editinguser . " logged in at level " . $authlevel);
    unless (defined($authlevel)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => AUTH_REQUIRED,
					       -text => "Not authenticated and authorized with an authlevel");
    }
    my $user = AxKit::App::TABOO::Data::User::Contributor->new();
    # Retrieve old data
    $user->load(what => '*', limit => {'username' => $args{'username'}});

    if ($args{'username'} eq 'guest') {
      throw Apache::AxKit::Exception::Retval(
					     return_code => FORBIDDEN,
					     -text => "Leave the guest user alone!");
    }
    if ($args{'username'} eq $editinguser) {
	# It is the user editing his own data
	if ($args{'authlevel'} > $authlevel) {
	    throw Apache::AxKit::Exception::Retval(
						   return_code => FORBIDDEN,
						   -text => "Can you say privilege escalation, huh?");
	}
	if (($args{'newpasswd1'}) && ($args{'newpasswd2'})) {
	    # So, we want to update password
	    if ($args{'newpasswd1'} eq $args{'newpasswd2'}) {
		$args{'passwd'} = crypt($args{'newpasswd1'}, AxKit::App::TABOO::XSP::User::makeSalt());
		delete $args{'newpasswd1'};
		delete $args{'newpasswd2'};
	    } else {
		throw Apache::AxKit::Exception::Error(-text => "Passwords don't match");
	    }
	}
    } else {
	# It is a higher privileged user editing another user's data. 
	my @changing = $user->apache_request_changed(\%args); # These are the fields sought to be changed
	AxKit::Debug(10, "Changing fields: " . join(", ", @changing));
	if ((scalar @changing == 1) && grep(/authlevel/, @changing)) {
	    # Then, it is only the authlevel that is to be changed, and OK levels are given by authlevel_extremes.
	    my $extremes = AxKit::App::TABOO::XSP::User::authlevel_extremes($args{'username'});
	    if ((${$extremes}{'minlevel'} > ${$extremes}{'maxlevel'}) 
	    || ($args{'authlevel'} > ${$extremes}{'maxlevel'})
	    || ($args{'authlevel'} < ${$extremes}{'minlevel'}))
                {
		    throw Apache::AxKit::Exception::Retval(
						       return_code => FORBIDDEN,
						       -text => "You may only set an authlevel between " . ${$extremes}{'minlevel'} . " and " . ${$extremes}{'maxlevel'} . ". Your level: " . $authlevel);
	    }
	} else {
	    # Any other fields require ADMIN privs
	    if ($authlevel < AxKit::App::TABOO::XSP::User::ADMIN) {
		throw Apache::AxKit::Exception::Retval(
						       return_code => FORBIDDEN,
						       -text => "Admin Privileges are needed to edit other user's data. Your level: " . $authlevel);
	    }
	}
    }
    $user->populate(\%args);
    $user->save();
EOC
}


=head2 C<E<lt>new-user/E<gt>>

This tag will store the contents of an Apache::Request object in the
data store, but perform little checks on the data given. The only
thing it checks is that the username isn't in use and allready. Then,
if the authlevel is different from 1, it is checked if the logged in
user is privileged to set the authlevel.

=cut

sub new_user
{
    return << 'EOC';
    my %args = map { $_ => join('', $cgi->param($_)) } $cgi->param;
    my $user = AxKit::App::TABOO::Data::User::Contributor->new();
    if($args{'username'} =~ m/comment|thread|all|respond|edit/) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => FORBIDDEN,
					       -text => "Username matching a administratively prohibited name")
	}
    if($user->load_name($args{'username'})) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => FORBIDDEN,
					       -text => "User exists allready")
	}
    my $extremes = AxKit::App::TABOO::XSP::User::authlevel_extremes('');
    if(($args{'authlevel'} > ${$extremes}{'maxlevel'}) || (! $args{'authlevel'})) {
        $args{'authlevel'} = 1;   
    }
    $args{'passwd'} = crypt($args{'passwd'}, AxKit::App::TABOO::XSP::User::makeSalt());
    $user->populate(\%args);
    AxKit::Debug(9, "Saving new user " . $args{'username'});
    $user->save();
EOC
}


=head2 C<E<lt>get-passwd username="foo"/E<gt>>

This tag will return the password of a user. The username may be given
in an attribute or child element named C<username>.

=cut

sub get_passwd : expr attribOrChild(username)
{
    return << 'EOC';
    my $user = AxKit::App::TABOO::Data::User->new();
    $user->load_passwd($attr_username); 
EOC
}



=head2 C<E<lt>get-authlevel username="foo"/E<gt>>

This tag will return the authorization level of a user, which is an
integer that may be used to grant or deny access to certain elements
or pages. The username may be given in an attribute or child element
named C<username>.

=cut


sub get_authlevel : expr attribOrChild(username)
{
    return << 'EOC';
    my $user = AxKit::App::TABOO::Data::User::Contributor->new();
    $user->load_authlevel($attr_username); 
EOC
}



=head2 C<E<lt>get-user username="foo"/E<gt>>

This tag will return and XML representation of the user
information. The username may be given in an attribute or child
element named C<username>.

=cut

sub get_user : struct attribOrChild(username)
{
    return << 'EOC';
    my $user = AxKit::App::TABOO::Data::User::Contributor->new();
    $user->load(what => '*', limit => {'username' => $attr_username}); 
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output', 'user:get-user');
    $doc->setDocumentElement($root);
    $user->write_xml($doc, $root); # Return an XML representation
EOC
}





=head2 C<E<lt>exists username="foo"/E<gt>>

This tag will check if a user allready exists. Like
C<E<lt>password-matchesE<gt>> this tag is a boolean tag, which has
child elements C<E<lt>trueE<gt>> and C<E<lt>falseE<gt>>. It takes a
username, which may be given as an attribute or a child element named
C<username>, and if the user is found in the data store, the contents
of C<E<lt>trueE<gt>> child element is included, otherwise, the
contents of C<E<lt>falseE<gt>> is included.

=cut

sub exists : attribOrChild(username) {
    return ''; # Gotta be something here
}

sub exists___true__open {
return << 'EOC';
    if (AxKit::App::TABOO::XSP::User::_exists_check($attr_username)) {
EOC
}

sub exists___true {
  return '}'
}


sub exists___false__open {
return << 'EOC';
    unless (AxKit::App::TABOO::XSP::User::_exists_check($attr_username)) {
EOC
}

sub exists___false {
  return '}'
}


=head2 C<E<lt>is-authorized authlevel="5" username="foo"E<gt>>

This is a boolean tag, which has child elements C<E<lt>trueE<gt>> and
C<E<lt>falseE<gt>>. It takes an autherization level in an attribute or
child element named C<authlevel>, and an attribute or child element
named C<username>. If the authenticated user has it least this level
I<or> the given C<username> matches the username of the authenticated
user, the contents of the C<E<lt>trueE<gt>> element will be included
in the output document. Conversely, if the user has insufficient
privileges the contents of C<E<lt>falseE<gt>> will be in the result
document.

B<NOTE:> This should I<not> be looked upon as a "security feature".
While it is possible to use it to make sure that an input control is
not shown to someone who is not authorized to modify it (and this may
indeed be its primary use), a malicious user could still insert data
to that field by supplying arguments in a POST or GET
request. Consequently, critical data must be checked for sanity before
they are passed to the Data objects. The Data objects themselves are
designed to believe anything they're fed, so it is most natural to do
it in a taglib before handing the data to a Data object. See e.g. the
internals of the C<E<lt>store/E<gt>> tag for an example.


=cut

sub is_authorized : attribOrChild(username,authlevel) {
    return ''; # Gotta be something here
} 

sub is_authorized___true__open {
return << 'EOC';
  my $session = AxKit::App::TABOO::session($r);
  my $editinguser = AxKit::App::TABOO::loggedin($session);
  my $authlevel = AxKit::App::TABOO::authlevel($session);
  AxKit::Debug(9, $editinguser . " is authorized at level " . $authlevel);
  if ((defined($editinguser))
      && (defined($authlevel))) {
    if (($attr_username eq $editinguser)
      || (($attr_authlevel) 
	  && ($attr_authlevel <= $authlevel))) # Grant access
	{
EOC
}


sub is_authorized___true {
  return '} }'
}


sub is_authorized___false__open { 
return << 'EOC'; 
  my $session = AxKit::App::TABOO::session($r);
  my $editinguser = AxKit::App::TABOO::loggedin($session);
  my $authlevel = AxKit::App::TABOO::authlevel($session);
  if ((! defined($editinguser)
       || ($attr_username ne $editinguser))
      && ((! defined($authlevel))
	  || ($attr_authlevel > $authlevel))) # Deny access
    {
EOC
}  


sub is_authorized___false {
  return '}'
}

=head2 C<E<lt>valid-authlevels/E<gt>>

This returns a list of the authorization levels that the present user
can legitimitely set. This is an ugly and temporary solution, I think
it should be worked out elsewhere than the taglib, but I couldn't find
a way to do it....

=cut

sub valid_authlevels : nodelist({http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output}level) attribOrChild(username) {
    return << 'EOC';
# my @levels = ("Guest", "New member", "Member", "Oldtimer", "Assistant", "Editor", "Administrator", "Director", "Guru", "God"); 
my $extremes = AxKit::App::TABOO::XSP::User::authlevel_extremes($attr_username);
(${$extremes}{'minlevel'} > ${$extremes}{'maxlevel'}) 
    ? () 
    : (${$extremes}{'minlevel'} .. ${$extremes}{'maxlevel'});    
EOC
}


=head2 C<E<lt>random-password/E<gt>>

Shamelessly stolen from Jörg Walter's L<AxKit::XSP::Auth> taglib, this
would generate a new random password, see his documentation for
details.

=cut

sub random_password : expr attribOrChild(lang,signs,numbers,minlen,maxlen)
{
	return 'Crypt::GeneratePassword::word(int($attr_minlen)||7,int($attr_maxlen)||7,$attr_lang,int($attr_signs),(defined $attr_numbers?int($attr_numbers):2))';
}

=head2 C<E<lt>authnuser/E<gt>>

This tag will return the username of the logged in and authenticated user.

=cut

sub authnuser : expr {
  return 'AxKit::App::TABOO::loggedin(AxKit::App::TABOO::session($r));'
}



1;

=head1 TODO

Currently, C<E<lt>existsE<gt>> checks if a user exists by checking if
the real name is defined. This is likely to change in the future. Do
not rely on this behaviour, but do make sure every-one has a real
name!


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

