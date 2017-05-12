package Aut;

# $Id: Aut.pm,v 1.23 2004/04/11 19:17:10 cvs Exp $

use 5.006;
use strict;

use Crypt::RSA;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;

use Digest::MD5 qw(md5_base64);

use Locale::Framework;

use Config::Frontend;
use Config::Backend::String;

use Aut::Crypt;
use Aut::Ticket;
use Aut::UI::Console;
use Aut::Base64;
use Aut::Backend::Conf;

our $VERSION = '0.11';

sub new {
  my $class=shift;
  my $string="";
  my $args = {
	      Backend => new Aut::Backend::Conf(
				new Config::Frontend(
					new Config::Backend::String(\$string)
						    )
					       ),
	      UI => new Aut::UI::Console(),
	      RSA_Bits => 1024,
	      Levels => [ "admin", "mutate", "view" ],
	      Adminlevel => "admin",
	      @_
	      };

  my $backend=$args->{"Backend"};
  my $ui=$args->{"UI"};
  my $bits=$args->{"RSA_Bits"};
  my $self;

  $self->{"string"}=\$string;
  $self->{"status"}="NONE";
  $self->{"errmsg"}="";

  if (not defined $backend) { die "You need to specify an Aut Backend"; }
  if (not defined $ui) { die "You need to specify an Aut user interface"; }

  $self->{"backend"}=$backend;
  $self->{"ui"}=$ui;
  $self->{"levels"}=$args->{"Levels"};
  $self->{"adminlevel"}=$args->{"Adminlevel"};
  $self->{"ui"}->initialize($self->{"levels"},$self->{"adminlevel"});
  $self->{"base64"}=new Aut::Base64();

  bless $self,$class;

  $self->initialize($bits);

return $self;
}

#####################################################################
# Initializing 
#####################################################################

# Internal function.
# Used to initialize the subsystem.

sub initialize {
  my $self=shift;
  my $bits=shift;

  if (not defined $self->{"backend"}->get_keys()) {
    my $pass=$self->{"ui"}->ask_pass($self,_T("Initializing cryptography system.\n".
					"Please provide a password for the global\n".
					"RSA key-pair. You need to keep this password\n".
					"secret and will have to remember it!"));
    if (not defined $pass) { die "Cannot continue without password"; }

    my $passagain=$self->{"ui"}->ask_pass($self,_T("Enter the RSA password again for verification."));
    if ($pass ne $passagain) { die "Cannot continue with two different passwords"; }


    $self->{"ui"}->message(_T("Generating keys, this will take some time...")."($bits bits)");
    my $rsa = new Crypt::RSA;
    my ($public,$private) =$rsa->keygen(
					Identity => 'Aut module',
					Size => $bits,
					Password => "",
					Verbosity => 0
					) or die $rsa->errstr();


    my $private_str=private_key_to_string($private);
    $private_str="private,".$private_str;

    my $cipher=new Aut::Crypt($pass);
    $private_str=$cipher->encrypt($private_str);

    my $public_str=public_key_to_string($public);

    $public_str=$self->{"base64"}->encode($public_str);
    $private_str=$self->{"base64"}->encode($private_str);

    $self->{"backend"}->set_keys($public_str,$private_str);

    $self->{"ui"}->message(_T("done."));
  }
}

#####################################################################
# Querying
#####################################################################

sub has_accounts {
  my $self=shift;
  $self->{"backend"}->has_accounts();
}

sub is_admin {
  my $self=shift;
  my $ticket=shift;
  return ($ticket->valid()) && ($ticket->rights() eq $self->{"adminlevel"});
}

sub status {
  my $self=shift;
  return $self->{"status"};
}

sub last_error {
  my $self=shift;
  return $self->{"errmsg"};
}

sub list_accounts {
  my $self=shift;
return $self->{"backend"}->get_all_accounts();
}

sub exists {
  my $self=shift;
  my $account=shift;
  return $self->{"backend"}->exists($account);
}

#####################################################################
# Bag functionality --> Backend as Configuration file
#####################################################################

sub set {
  my ($self,$ticket,$var,$val) = @_;
  $val=$ticket->encrypt($val);
  $self->{"backend"}->set($ticket->account(),$var,$val);
}

sub get {
  my ($self,$ticket,$var) = @_;
  my $val=$self->{"backend"}->get($ticket->account(),$var);
  $val=$ticket->decrypt($val);
  return $val;
}

sub del {
  my ($self,$ticket,$var) = @_;
  $self->{"backend"}->del($ticket->account(),$var);
}

#####################################################################
# status and error 
#####################################################################

### Internal Functions

sub set_status {
  my ($self,$status)=@_;
  $self->{"status"}=$status;
}

sub set_error {
  my ($self,$msg)=@_;
  $self->{"errmsg"}=$msg;
}

#####################################################################
# rsa crypting/decrypting
#####################################################################

### Internal Functions
### Using an undocumented feature here!

sub public_key_to_string {
  my $key=shift;
  return $key->serialize();
}

sub string_to_public_key {
  my $string=shift;
  my $key=new Crypt::RSA::Key::Public;
  my @pub;
  push @pub,$string;
  return $key->deserialize(String => \@pub);
}

sub private_key_to_string {
  my $key=shift;
  return $key->serialize();
}

sub string_to_private_key {
  my $string=shift;
  my $key=new Crypt::RSA::Key::Private;
  my @pub;
  push @pub,$string;
  return $key->deserialize(String => \@pub);
}
### Using an undocumented feature here!

sub rsa_crypt {
  my $self=shift;
  my $text=shift;
  my $rsa=new Crypt::RSA;

  my ($public_str,$private_str)=$self->{"backend"}->get_keys();
  my $public;

  $public_str=$self->{"base64"}->decode($public_str);
  my $public=string_to_public_key($public_str);

  $text=$rsa->encrypt(
		      Message => $text,
		      Key => $public
		     );
  if (not defined $text) { warn "cannot encrypt"; }

  $text=$self->{"base64"}->encode($text);
return $text;
}

sub rsa_decrypt {
  my $self=shift;
  my $text=shift;
  my $pass=shift;

  my $rsa=new Crypt::RSA;

  my ($public_str,$private_str)=$self->{"backend"}->get_keys();
  $private_str=$self->{"base64"}->decode($private_str);

  if (not defined $pass) {
    $pass=$self->{"ui"}->ask_pass($self,_T("Give the password for the account global RSA private key"));
  }

  if (not defined $pass) {
    return undef;
  }

  my $cipher=new Aut::Crypt($pass);
  $private_str=$cipher->decrypt($private_str);
  if (substr($private_str,0,8) ne "private,") {
    return undef;
  }
  else {

    $private_str=substr($private_str,8,length($private_str));
    my $private=string_to_private_key($private_str);

    $text=$self->{"base64"}->decode($text);
    $text=$rsa->decrypt(
			Cyphertext => $text,
			Key        => $private,
			);
    if (not defined $text) {
      warn "Unexpected! Cannot decrypt text with good private key!";
    }
    return $text;
  }
}

sub check_rsa_private_pass {
  my $self=shift;
  my $pass=shift;

  my ($public_str,$private_str)=$self->{"backend"}->get_keys();
  $private_str=$self->{"base64"}->decode($private_str);

  my $cipher=new Aut::Crypt($pass);
  $private_str=$cipher->decrypt($private_str);
  if (substr($private_str,0,8) ne "private,") {
    return 0;
  }
  else {
    return 1;
  }
}

### Internal Functions

################################################################
# Account handling
#####################################################################

sub ticket_create {
  my $self=shift;
  $self->ticket_update(@_);
}

sub ticket_update {
  my $self=shift;
  my $ticket=shift;

  my $account=$ticket->account();
  my $pass=$ticket->pass();
  my $rights=$ticket->rights();
  my $seed=$ticket->seed();

  #my $md5pass=md5_base64($pass);
  my $rsapass=$self->rsa_crypt($pass);

  my $cipher=new Aut::Crypt($pass);
  my $crypt_seed=$cipher->encrypt($seed);
  my $b64_seed=$self->{"base64"}->encode($crypt_seed);

  #$self->{"backend"}->set_md5pass($account,$md5pass);
  #$self->{"backend"}->set_pass($account,$rsapass);
  $self->{"backend"}->set_pass($account,$pass);
  $self->{"backend"}->set_rsa_pass($account,$rsapass);
  $self->{"backend"}->set_rights($account,$rights);
  $self->{"backend"}->set_seed($account,$b64_seed);

  my $to_hash="$rights$b64_seed";
  my $hash=md5_base64($to_hash);
  $self->{"backend"}->set_sr_hash($account,$hash);
}

sub ticket_get {
  my $self=shift;
  my $account=shift;
  my $pass=shift;

  if (not defined $pass) { $pass=""; }

  my $ticket=new Aut::Ticket($account,$pass);

  if (not $self->{"backend"}->exists($account)) {
    $ticket->invalidate();
    $self->set_error(_T("Account does not exist :").$account);
    $self->set_status("ENOEXIST");
    return $ticket;
  }

  #my $stored_pass=$self->{"backend"}->get_md5pass($account);
  #my $md5pass=md5_base64($pass);

  if (not $self->{"backend"}->pass_ok($account,$pass)) { 
    $ticket->invalidate();
    $self->set_error(_T("Invalid password for :").$account);
    $self->set_status("EBADPASS");
  }

  my $rights=$self->{"backend"}->get_rights($account);
  my $seed=$self->{"backend"}->get_seed($account);

  my $to_hash="$rights$seed";
  my $hash=md5_base64($to_hash);
  if (($hash ne $self->{"backend"}->get_sr_hash($account)) 
      and
      $ticket->valid()
     ) {
    $self->set_error(_T("seed or rights have been modified for account ").$account);
    $self->set_status("EBADINFO");
    $ticket->invalidate();

  }

  $seed=$self->{"base64"}->decode($seed);
  my $cipher=new Aut::Crypt($pass);
  $seed=$cipher->decrypt($seed);

  $ticket->set_rights($rights);
  $ticket->set_seed($seed);

return $ticket;
}

sub ticket_remove {
  my $self=shift;
  my $ticket=shift;
  $self->{"backend"}->del_account($ticket->account());
  $ticket->invalidate();
}

#####################################################################
# Administrator functions
#####################################################################

sub ticket_admin_get {
  my $self=shift;
  my $user_account=shift;
  my $pass=shift;

  if (not $self->{"backend"}->exists($user_account)) {
    my $ticket=new Aut::Ticket($user_account,"");
    $ticket->invalidate();
    return $ticket;
  }

  my $user_pass=$self->{"backend"}->get_rsa_pass($user_account);
  if (defined $pass) {
    $user_pass=$self->rsa_decrypt($user_pass,$pass);
  }
  else {
    $user_pass=$self->rsa_decrypt($user_pass);
  }

  if (not defined $user_pass) {
    $self->{"ui"}->message_ok(_T("With the RSA password you gave,\nthe password for account '$user_account' could not be decrypted"));
    my $ticket=new Aut::Ticket($user_account,"");
    $ticket->invalidate();
    return $ticket;
  }

  return $self->ticket_get($user_account,$user_pass);
}

sub ticket_all_admin_get {
  my $self=shift;
  my @accounts=$self->{"backend"}->get_all_accounts();
  my @tickets;

  my $pass=$self->{"ui"}->ask_pass($self,_T("Give the password for the secret RSA key"));
  if (not defined $pass) {
    $self->{"ui"}->message_ok(_T("You need to specify a password for the secret RSA key"));
    return undef;
  }
  elsif (not $self->check_rsa_private_pass($pass)) {
    $self->{"ui"}->message_ok(_T("The given password for the secret RSA key is not valid"));
    return undef;
  }

  for my $a (@accounts) {
    my $ticket=$self->ticket_admin_get($a,$pass);
    push @tickets,$ticket;
  }

return @tickets;
}

#####################################################################
# User Interface functions
#####################################################################

sub login {
  my $self=shift;
  return $self->{"ui"}->login($self,@_);
}

sub logout {
  my $self=shift;
  my $ticket=shift;
  if ($self->{"ui"}->logout($self,$ticket,@_)) {
    $ticket->invalidate();
  }
}

sub admin {
  my $self=shift;
  my $ticket=shift;
  if ($self->is_admin($ticket)) {
    $self->{"ui"}->admin($self,$ticket,@_);
  }
  else {
    $self->{"ui"}->message_ok(_T("You don't have administrator rights.\nYou cannot do administration of accounts."));
  }
}

sub change_pass {
  my $self=shift;
  my $ticket=shift;
  if ($ticket->valid()) {
    $self->{"ui"}->change_pass($self,$ticket,@_);
  }
  else {
    $self->{"ui"}->message_ok(_T("You don't have a valid ticket. You cannot change your password"));
  }
}

#####################################################################
# UI Call back support functions
#####################################################################

sub check_pass {
  my $self=shift;
  my $pass=shift;

  if (not defined $pass) { $pass=""; }

  my $status=undef;
  my $str="";

  if (length($pass) lt 6) {
    $status="EBADPASS";
    $str=return "A password must be at least 6 characters";
  }

  if (defined $status) {
    $self->set_status($status);
    $self->set_error($status);
  }

return $str;
}

1;
__END__

=head1 NAME

Aut - Authorization framework with flexible backends and UIs.

=head1 SYNOPSIS

    use Aut;
    use Aut::UI::Console;
    use Aut::Backend::Conf;
    use Config::Frontend;
    use Config::Backend::INI;

    use strict;

    my $cfg=new Config::Frontend(new Config::Backend::INI("./accounts.ini"));

    my $backend=new Aut::Backend::Conf($cfg);
    my $ui=new Aut::UI::Console();

    my $aut=new Aut( Backend => $backend, 
                     UI => $ui, 
                     RSA_Bits => 512,
                     Levels => [ "admin", "user", "guest" ],
                     Adminlevel => "admin"
                   );

    my $ticket=$aut->ticket_get("admin","testpass");
    if (not $ticket->valid()) {
      $ticket=new Aut::Ticket("admin","testpass");
      $ticket->set_rights("admin");
      $aut->ticket_create($ticket);
    }

    $ticket=$aut->login();

    print "account :",$ticket->account(),"\n";
    print "rights  :",$ticket->rights(),"\n";

    if ($ui->is_admin($ticket)) {
       $aut->admin($ticket);
    }
    else {
        $ui->message_ok(_T("You don't have administrator rights\n".
                           "You may not administer accounts."));
    }

    print "account :",$ticket->account(),"\n";
    print "rights  :",$ticket->rights(),"\n";

    $aut->change_pass($ticket);


=head1 ABSTRACT

Aut is an authorization framework that provides flexible backends
and flexible UIs (User Interfaces). It is build up around a combination
of backend hashing (see L<Aut::Backend::Conf|Aut::Backend::Conf> for an example) and RSA 
password encrypting and a ticket system and can be used to encrypt user 
data, while providing a secure escape to decrypt user data of a user whom 
lost his/hers password. 

=head1 DESCRIPTION

The goal of Aut is to provide a component that can be used to 
provide user authorization for applications. It's features are 
described in the following sections.

=head2 Flexible backends

Aut can be instantiated with your own backend. This could be a
backend that just uses e.g. the UNIX passwd system in combination
with some extra features. Or you could connect to LDAP, etc.

The backend provides the basis for security. A good backend should
be as secure as possible. The reference backend provided with this
package does not guarantee this security, because it's based on 
configuration files. Configuration files tend to be able to be
edited. So if someone wants to do harm, he/she could just delete
the RSA keys (explained later on) from the configuration file.

See L<Aut::Backend::Conf|Aut::Backend::Conf> for a reference interface.

=head2 Flexible UIs

Aut can be instantiated with your own User Interface. The reference
implementation is a Console Based one, that is clearly utterly simple.
There exists an other interface for wxPerl (L<Aut::UI::Wx|Aut::UI::Wx>).

E.g., when a user logs in using Aut, Aut will call the right UI functions
to establish the interaction with the user. See 
L<Aut::UI::Console|Aut::UI::Console> for a reference interface.

=head2 Ticket system

Aut works with a ticket system. If a user logs in, he/she gets a ticket.
This ticket gives the user his/hers rights in the context of an application.

Also a ticket is a container for other application specific things. So
an application can set() and get() all kinds of information that it needs
to provide context to a certain authorization level. E.g., an administrator
can have access to adminstration functionality through the ticket.

=head2 Encryption and decryption of user data

A default feature that is provided by the Aut framework is the possibility
to encrypt and decrypt data with the ticket. If a user has a valid ticket,
he/she can encrypt and decrypt his/hers data. This makes it possible to
use this ticket system with applications that store data that has to be
private. E.g. a patient document system.

There's a catch in such systems. If the user looses his/hers password,
he/she won't be able to decrypt his/hers data. This poses a problem
for helpdesks. The Aut systems provides the following  backup for this 
situation.

=head3 The backup system for lost passwords

If a user looses his/hers password, an administrator would normally
provide the user with a new password. However, this would mean that
the users looses all his/hers encrypted data, because his/hers password
is connected to the encrypted data by means of encryption/decryption keys.
This section describes the solution that Aut uses to address this problem.

=over 1

=item *

All data of a user is encrypted with a personal 'seed' value that is
stored with the user's account. 

=item *

This seed value is not world readable; it is encrypted with the user's 
password as key.

=item *

The user password must be hashed by the backend. L<Aut::backend::Conf|Aut::backend::Conf>
uses MD5 hashing, but a 'passwd' backend would use e.g. crypt() (and an unsafe
backend would probably store the password plaintext). As Hashes should be one way
functions (i.e. non invertable functions), the plaintext password cannot be retreived
from the  backend.

=item *

This is why the Aut system stores the user password also encrypted 
with a public RSA key. This RSA is part of the Aut framework.

=item *

The private key of the RSA keypair is stored encrypted with a single
password provided by the main administrator of the application. The 
password for this key could written down and be stored in on a physical
location, e.g. a safe in a trusted bank.

=item *

If the user looses his/hers password, a system administrator that knows
the password of the private key of the RSA keypair can reset the
user's password without loosing the seed value. With the private key,
the old RSA encrypted user password of the user is decrypted. The
seed is decrypted with the decrypted user password; and the new password
is used to re-encrypt the seed. 

=back

=head1 INTERFACE

=head2 Instantiating

=head3 C<new(Backend =E<gt> ..., UI =E<gt> ..., RSA_bits =E<gt> ..., Levels =E<gt> ..., Adminlevel =E<gt> ...) --E<gt> Aut>

=over 1

C<Backend> =E<gt> An C<Aut::Backend::...> object.

C<UI> =E<gt> an C<Aut::UI:...> object.

C<RSA_bits> =E<gt> an integer E<gt>=512.

C<Levels> E<gt> A list of application authorization levels. Defaults
to C<[ "admin", "mutate", "view" ]>.

C<AdminLevel> E<gt> the administrator authorization level (should be
an element of C<Levels>.

Instantiates a new Aut object with given paramters. This function calls
an internal initialization function, that initializes the given backend,
if this is necessary. It is necessary to initialize the backend, if there
exists no RSA keypair in the backend. If this is the case, a user interaction
follows, where the user is asked to provide a password for the RSA
keypair.

=back

=head2 Querying

=head3 C<has_accounts() --E<gt> boolean>

=over 1

Returns true, if there are accounts in the Aut system; returns false
otherwise.

=back

=head3 C<is_admin(ticket) --E<gt> boolean>

=over 1

Returns true, if the rights() method of ticket equals C<Adminlevel> and
the given ticket is valid. Returns false, otherwise.

=back 

=head3 C<status() --E<gt> string>

=over 1

Returns the current status of the Aut object. Possible states are:

=over 1

=item NONE

Nothing happened.

=item ENOEXIST

Account does not exist.

=item EBADPASS

Bad password given.

=item EBADINFO

Seed, Rights or hash of seed and rights have been modified.

=back

=back

=head3 C<last_error() --E<gt> string>

=over 1

Returns the last error message.

=back

=head3 C<exists(account) --E<gt> boolean>

=over 1

Returns true, if account exists, false otherwise.

=back

=head3 C<list_accounts() --E<gt> (list string)>

=over 1

Returns a list of all accounts that exist in the backend.

=back

=head2 Account Handling

=head3 C<ticket_create(ticket) --E<gt> void>

=over 1

Given a ticket with an account, password, seed and rights (see L<Aut::Ticket>),
this function will create a new account in the Aut Backend.

=back

=head3 C<ticket_update(ticket) --E<gt> void>

=over 1

Given a ticket with an account, password, seed and rights (see L<Aut::Ticket>),
this function will update an existing account in the Aut Backend.

=back

=head3 C<ticket_get(account,password) --E<gt> Aut::Ticket>

=over 1

Given an account and a password, this function will try to get the account
information from the backend. If the account does not exist, or the password 
isn't correct, this function will return a ticket with property 
'invalid' (see L<Aut::Ticket>). Otherwise, this function will return a valid
ticket with the rights and seed information from the backend. 
However, if seed or rights have been modified, the ticket won't be valid
anymore. All retreived information will be there. 
In case of a problem: the status of the Aut object will have been 
modified. It can be set to the following values:

=over 1

=item ENOEXIST

The (user) account does not exist in the backend.

=item EBADPASS

A bad password has been given.

=item EBADINFO

The rights and/or seed values have been modified. 

=back

=back

=head3 C<ticket_remove(ticket) --E<gt> void>

Removes the account that ticket stands for from the backend and invalidates
the ticket.

=head2 BAG related functions

These functions give the program the possibility to set, get and del 
configuration items. The items will be encrypted.

=head3 C<set(ticket,var,val) --E<gt> void>

Will set the variable 'var' in the backend configuration part to
value 'val'. 

=head3 C<get(ticket,var) --E<gt> value>

Will get the variable 'var' from the backend. The value retreived
will be decrypted.

=head3 C<del(ticket,var) --E<gt> void>

Will delete variable 'var' from the backend.

=head2 Administrator related functions

=head3 C<ticket_admin_get(user_account [, password]) --E<gt> ticket>

=over 1

This function does the same as C<ticket_get>, but from the administrators
perspective. It takes a user_account and an optional password. This password 
is the password of the private key that can be used to decypher the rsa_encrypted
variant of the user's password. With the decyphered rsa_encrypted user's password
this function just calls C<ticket_get>.

If the password for the private key is not correct, an invalid ticket will
be returned. Otherwise, the result of C<ticket_get> is returned.

=back 

=head3 C<ticket_all_admin_get([pass]) --E<gt> (list Aut::Ticket)>

=over 1

This function asks via the given User Interface Object (Aut::UI::...) the 
password for the private key that can be used to decypher the rsa_encrypted
variants of account passwords (or gets it through the optional C<pass> parameter)
and uses it to return tickets for all accounts that are reported 
through C<list_accounts()>.

Returns a list of tickets. Or, if the rsa private key could not be decrypted,
C<undef>. 

Note! If undef is returned and put into a list by assignment 
(C<@tickets=ticket_all_admin_get()>),the undef will be inside the list!

=back

=head2 User Interface related functions

=head3 C<login([Any]) --E<gt> Aut::Ticket>

=over 1

This function calls the C<login()> function of the UI, which is expected
to return an C<Aut::Ticket> object. It passes through any given argument.
Look at L<Aut::UI::Console> for an implementation.

=back 

=head3 C<logout(ticket [,Any]) --E<gt> void>

=over 1

This function calls the C<logout()> function of the UI. If this function
returns true, the ticket is invalidated..

=back

=head3 C<admin(ticket [,Any]) --E<gt> void>

=over 1

This function takes a ticket. If this ticket has administrator rights
(is_admin(ticket) equals true), it will call the C<admin()> function
of the UI, otherwise it will call the C<message_ok()> function of
the UI (see L<Aut::UI::Console>).

The admin() function is used to administer accounts.

=back

=head3 C<change_pass(ticket [,Any]) --E<gt> void>

=over 1

This function takes a ticket. If the ticket is valid, it will
call the C<change_pass()> function of the UI, which will change
the password for the account related to the given ticket. Otherwise,
it will display a message about invalidity of the given ticket.

See L<Aut::UI::Console> for an implementation of this function.

=back 

=head2 Callback functions for the user interface

=head3 C<check_pass(pass) --E<gt> string>

=over 1

This function checks if a given password is conform some standards.
At this moment the only thing checked, is the password's length 
(E<gt>=6 characters).

If you need a different implementation of this function, you may
want to derive a new package from C<Aut> and overload this function
(all perl functions are virtual).

This function returns the empty string (""), if the password
is conform the implemented standard, otherwise it returns a
(possibly localized) error message, sets the status of C<Aut> to
C<"EBADPASS"> and sets the C<last_error()> string to the returned
error string.

=back

=head1 SEE ALSO

L<Aut::Ticket|Aut::Ticket>, L<Aut::Backend::Conf|Aut::Backend::Conf>,
L<Aut::UI::Console|Aut::UI::Console>.

=head1 AUTHOR

Hans Oesterholt-Dijkema E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

(c)2004 Hans Oesterholt-Dijkema, This module is distributed
under Artistic license.

=cut

