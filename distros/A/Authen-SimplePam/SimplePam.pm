package Authen::SimplePam;

use Authen::PAM '0.13' ;

use strict;
use warnings;

our $VERSION = '0.1.24';
our $DEBUG = 0;

#------------------------------------------------------------
#sometimes, we need to know what pam
#really wants.
#These lists pam's hardcoded messages.
#Different modules might add new messages,
#in this case, we need to expand these
#This might be the case even for
#internationalization

#known messages and meanings.
#0 => asking for the current password
#1 => asking for the new password
#2 => askng for the new password, but as a confirmation

#messages to ask for the current password.
our $PAM_MESSAGES = {
		     "(current) UNIX password: "  => 0,
		     "New UNIX password: "        => 1,
		     "Retype new UNIX password: " => 2,
		     "Password: "                 => 0,
		    };

our $PAM_ERROR_MESSAGES = {
			   "it's WAY too short"                              => 1,
			   "it is too short"                                 => 2,
			   "it does not contain enough DIFFERENT characters" => 3,
			   "it is too simplistic/systematic"                 => 4,
			   "is too similar to the old one"                   => 5,
			   "is too simple"                                   => 6,
			   "Password unchanged"                              => 7,
			  };

#==============================================================

#---------------------------------------------------
# PAM_CONSTANTS
#
# These PAM Constants are not
# defined by Authen::PAM (at least 0.13),
# so we define them here.
# These values were taken from a linux system with
# pam 0.75 from /usr/include/security/_pam_types.h
# note that pam is highly patched so, this might 
# be different in your system

sub PAM_BINARY_PROMPT      { return 7  }
sub _PAM_AUTHTOK_RECOVER_ERR { return 21 }

#
#============================


#OO interface
sub new {
  my ($proto, %args) = @_;
  my $class = ref $proto || $proto;

  my $username = _get_username();
  my $obj ={
	    #have we used the old password?
	    used_old_password => 0,

	    # our code if we get an error message
	    pam_error_message => undef,

	    # if we get an error message from pam
	    # do we abort?
	    # 0 => no
	    # 1 => yes
	    _abort_on_error => 1,

	    #conv has failed?
	    conv_failure => 0,

	    #the pam error message
	    #valid only if conv_failure == 1
	    pam_error_message => undef,
	    #our error code for this message
	    error_code => undef,

	    #data used to talk to pam
	    username => $username,
	    password => undef,
	    new_password => undef,
	    service => undef,
	    _call_type => undef,
	    _pam_result => undef,
	    _module_result => undef,
	    %args,
	   };

  bless ($obj, $class);
  return $obj;
}


#sets abort_on_error
#or return its value
sub _abort_on_error {
  my ($self, $abort) = @_ ;
  $self->{_abort_on_error} = $abort
    if (defined $abort);
  return $self->{_abort_on_error};
}


#sets the username
sub username {
  my ($self, $user) = @_;
  $self->{username} = $user
    if (defined $user);
  return $self->{username};
}

#alias for username
sub user {
  return username(@_);
}

sub name {
  return username(@_);
}

#sets the current password
sub current_password {
  my ($self, $password) = @_;
  $self->{password} = $password
    if (defined $password);
  return $self->{password};
}

#password is an alias for current_password
sub password {
  return current_password(@_);
}

#same for old_password
sub old_password {
  return current_password(@_);
}

#sets the new password
sub new_password {
  my ($self, $new_password) = @_;
  $self->{new_password} = $new_password
    if (defined $new_password);
  return $self->{new_password};
}

#sets the service to user
sub service {
  my ($self, $service) = @_;
  $self->{service} = $service
    if (defined ($service));

  return $self->{service};
}

#sets the type of coonvertion function to be used
sub _call_type {
  my ($self, $call_type) = @_;
  $self->{_call_type} = $call_type
    if (defined $call_type);
  return $self->{_call_type};
}

sub pam_result {
  my ($self) = @_;
  return $self->{_pam_result};
}

sub error_code {
  my ($self) = @_;
  return $self->{error_code};
}

sub error_message {
  my ($self) = @_;
  return $self->{pam_error_message};
}

sub auth_user {
  my ($self, $user, $password, $service) = @_;
  my ($pam, $pam_result);

  if (defined ($service))
  {
    $self->service($service);
  }

  unless ($self->service)
  {
    $self->service('login');
  }

  if (defined ($user))
  {
    $self->username($user);
  }

  if (defined ($password))
  {
    $self->password($password);
  }

  $self->_abort_on_error(1);
  $self->_call_type("authenticate");

  $self->{conv_failure} = 0;
  $pam = new Authen::PAM ($self->service,
			  $self->username,
			  sub {
			    return $self->_general_pam_conv ( @_ );
			  }
			 );

  # $pam should always return an object even if
  # the information is wrong (e.g. service)
  return 0
    unless ref($pam);

  $pam_result = $pam->pam_authenticate();
  $self->{_pam_result} = $pam_result;
  print "DEBUG: RESULT is $pam_result\n" if $DEBUG;

  $self->{_module_result} =  _pam2result($pam_result);
  return $self->{_module_result};
}

sub change_password {
  my ($self, $user, $old_password, $new_password, $service) = @_;
  my ($pam, $pam_result);

  if (defined ($service))
  {
    $self->service($service);
  }

  unless ($self->service)
  {
    $self->service('passwd');
  }

  if (defined ($user))
  {
    $self->username($user);
  }

  if (defined ($old_password))
  {
    $self->password($old_password);
  }

  if (defined ($new_password))
  {
    $self->new_password($new_password);
  }

  unless ($self->service)
  {
    $self->service('passwd');
  }

  $self->{used_old_password} = 0;
  $self->_abort_on_error(0);
  $self->_call_type("change_password");
  $self->{conv_failure} = 0;

  print "DEBUG: change_password:\n" .
    "username: " . $self->username . ", old password: " . $self->password if $DEBUG;
  print " new password: " .  $self->new_password if $DEBUG;
  print " service: " . $self->service .	"\n" if $DEBUG;

  $pam = new Authen::PAM ($self->service,
			  $self->username,
			  sub {
			    return $self->_general_pam_conv ( @_ );
			  }
			 );
  return 0
    unless ref($pam);

  $pam_result = $pam->pam_chauthtok();

  $self->{_pam_result} = $pam_result;

  print "DEBUG: RESULT is $pam_result\n" if $DEBUG;

  $self->{_module_result} =  _pam2result($pam_result);
  return $self->{_module_result};
}

sub result2string {
  my ($self, $result) = @_;
  $result = $self->{_module_result}
    unless (defined ($result));

  if    ( $result == 0  ) { return "Authen::PAM error"                       }
  elsif ( $result == 1  ) { return "success"                                 }
  elsif ( $result == 2  ) { return "failure"                                 }
  elsif ( $result == 3  ) { return "insuficient credentials"                 }
  elsif ( $result == 4  ) { return "authentication information unavailable"  }
  elsif ( $result == 5  ) { return "user unknown"                            }
  elsif ( $result == 6  ) { return "maximum tries"                           }
  elsif ( $result == 7  ) { return "unknown error"                           }
  elsif ( $result == 8  ) { return "authentication error"                    }
  elsif ( $result == 9  ) { return "authentication information cannot be recovered" }
  elsif ( $result == 10 ) { return "authentication locked busy"              }
  elsif ( $result == 11 ) { return "authentication aging disable"            }
  elsif ( $result == 12 ) { return "permission denied"                       }
  elsif ( $result == 13 ) { return "try again"                               }
  elsif ( $result == 14 ) { return "dlopen error"                            }
  elsif ( $result == 15 ) { return "symbol not found"                        }
  elsif ( $result == 16 ) { return "memory buffer error"                     }
  elsif ( $result == 17 ) { return "the password should be changed"          }
  elsif ( $result == 18 ) { return "user account has expired"                }
  elsif ( $result == 19 ) { return "cannot make/remove an entry for the specified session" }
  elsif ( $result == 20 ) { return "cannot retrieve users credentials"       }
  elsif ( $result == 21 ) { return "user credentials expired"                }
  elsif ( $result == 22 ) { return "no pam module specific data is present"  }
  elsif ( $result == 23 ) { return "conversation error"                      }
  elsif ( $result == 24 ) { return "ignore underlying account module"        }
  elsif ( $result == 25 ) { return "critical error"                          }
  elsif ( $result == 26 ) { return "user authentication has expired"         }
  elsif ( $result == 27 ) { return "pam module is unknown"                   }
  elsif ( $result == 28 ) { return "bad item passed to pam"                  }
  elsif ( $result == 29 ) { return "conversation function is event driven and data is not available yet" }
  elsif ( $result == 30 ) { return "call this function again to complete authentication stack"           }
  elsif ( $result == 31 ) { return "error in service module"                 }
  elsif ( $result == 32 ) { return "system error"                            }
  elsif ( $result == 33 ) { return "failure setting user credential"         }
  else                    { return "invalid result number: $result"          }
}


#returns the EUID that is running this module
sub _get_username {
  #we use the EFECTIVE USER ID (EUID),
  #not the REAL USER ID ( UID )
  my $name = getpwuid($<);
  return $name;
}

#checks the meaning os a message
#Returns the state of a message:
#undef means a unknown message.
#0: old password
#1: new password (1st time)
#2: new password (2nsd time)
sub _check_msg {
  my ($message) = @_;

  unless (defined ($PAM_MESSAGES->{$message})) {
    warn __PACKAGE__ . " warning!\n";
    warn "Unclassified message: '$message' .\n";
    warn "Please contact the author at <raul\@dias.com.br> in order to improve SimplePam.\n";
    warn "Version used: $VERSION .\n";
    return undef;
  }
  return $PAM_MESSAGES->{$message};
}


#Converts a error message to its code.
sub _check_error_msg {
  my ($message) = @_;

  $message =~ s/^BAD PASSWORD: //;

  unless (defined ($PAM_ERROR_MESSAGES->{$message})) {
    warn __PACKAGE__ . " warning!\n";
    warn "Unclassified error message: '$message' .\n";
    warn "Please contact the author at <raul\@dias.com.br> in order to improve this module.\n";
    warn "Version used: $VERSION .\n";
    return undef;
  }
  return $PAM_ERROR_MESSAGES->{$message};
}


#converts pam result codes to
#our own result codes
#(source is _pam_types.h)
#attention, some PAM constants are commented out, because
#they are not present in Authen::PAM module
#latest tested version: 0.11

sub _pam2result {
  my ($pam_result) = @_;
  my $result;

  if    ($pam_result == PAM_SUCCESS              ) { $result = 1; }
  elsif ($pam_result == PAM_AUTH_ERR             ) { $result = 2; }
  elsif ($pam_result == PAM_CRED_INSUFFICIENT    ) { $result = 3; }
  elsif ($pam_result == PAM_AUTHINFO_UNAVAIL     ) { $result = 4; }
  elsif ($pam_result == PAM_USER_UNKNOWN         ) { $result = 5; }
  elsif ($pam_result == PAM_MAXTRIES             ) { $result = 6; }
  elsif ($pam_result == PAM_AUTHTOK_ERR          ) { $result = 8; }
  elsif ($pam_result == _PAM_AUTHTOK_RECOVER_ERR  ) { $result = 9; }
  elsif ($pam_result == PAM_AUTHTOK_LOCK_BUSY    ) { $result = 10;}
  elsif ($pam_result == PAM_AUTHTOK_DISABLE_AGING) { $result = 11;}
  elsif ($pam_result == PAM_PERM_DENIED          ) { $result = 12;}
  elsif ($pam_result == PAM_TRY_AGAIN            ) { $result = 13;}
  elsif ($pam_result == PAM_OPEN_ERR             ) { $result = 14;}
  elsif ($pam_result == PAM_SYMBOL_ERR           ) { $result = 15;}
  elsif ($pam_result == PAM_BUF_ERR              ) { $result = 16;}
  elsif ($pam_result == PAM_NEW_AUTHTOK_REQD     ) { $result = 17;}
  elsif ($pam_result == PAM_ACCT_EXPIRED         ) { $result = 18;}
  elsif ($pam_result == PAM_SESSION_ERR          ) { $result = 19;}
  elsif ($pam_result == PAM_CRED_UNAVAIL         ) { $result = 20;}
  elsif ($pam_result == PAM_CRED_EXPIRED         ) { $result = 21;}
  elsif ($pam_result == PAM_NO_MODULE_DATA       ) { $result = 22;}
  elsif ($pam_result == PAM_CONV_ERR             ) { $result = 23;}
  elsif ($pam_result == PAM_IGNORE               ) { $result = 24;}
  elsif ($pam_result == PAM_ABORT                ) { $result = 25;}
  elsif ($pam_result == PAM_AUTHTOK_EXPIRED      ) { $result = 26;}
  elsif ($pam_result == PAM_MODULE_UNKNOWN       ) { $result = 27;}
  elsif ($pam_result == PAM_BAD_ITEM             ) { $result = 28;}
  elsif ($pam_result == PAM_CONV_AGAIN           ) { $result = 29;}
  elsif ($pam_result == PAM_INCOMPLETE           ) { $result = 30;}
  elsif ($pam_result == PAM_SERVICE_ERR          ) { $result = 31;}
  elsif ($pam_result == PAM_SYSTEM_ERR           ) { $result = 32;}
  elsif ($pam_result == PAM_CRED_ERR             ) { $result = 33;}
  else                                             { $result = 7; }

  return $result;
}


sub _general_pam_conv {
  my $self = shift;
  my ($user, $old_password, $new_password);

  #determines if something failed.
  my $failure = $self->{conv_failure};

  # call_type => The type of calling is this (required)
  # types are:
  #  authenticate => authenticates the user,
  #                  password and username required
  #  change_password => Changes the user password
  #                     username, old_password and new_password required
  #  root_change_password => root is changing password
  #                          username, new_password required
  # username  => The username to be used
  # old_password => user's old password
  # new_password => user's new password
  # password => the user's password

  unless (defined($self->_call_type)) {
    warn "\n\nATTENTION 0!!!!\n\n" . __PACKAGE__ . "::_general_pam_conv() called wrongly.\nSomething will break!\n\n";
    return (PAM_CONV_ERR, "", PAM_CONV_ERR);
  }

  #checks what we have here
  if ($self->_call_type eq "authenticate") {
    unless (
	    (defined ($self->username)) &&
	    (defined ($self->current_password))
	   ) {
      warn "\n\nATTENTION 1!!!!\n\n" . __PACKAGE__ . "::_general_pam_conv() called wrongly.\nSomething will break!\n\n";
      return (PAM_CONV_ERR, "", PAM_CONV_ERR);
    }else{
      $user         = $self->username;
      $old_password = $self->current_password;
    }
  }
  elsif ($self->_call_type eq "change_password") {
    unless (
	    (defined ($self->username))     &&
	    (defined ($self->password)) &&
	    (defined ($self->new_password))
	   ) {
      warn "\n\nATTENTION!!!!\n\n" . __PACKAGE__ . "::_general_pam_conv() called wrongly.\nSomething will break!\n\n";
      return (PAM_CONV_ERR, "", PAM_CONV_ERR);
    }else {
      $user = $self->username;
      $old_password = $self->password;
      $new_password = $self->new_password;
    }
  }
  elsif ($self->_call_type eq "root_change_password") {
    unless (
	    (defined ($self->username))     &&
	    (defined ($self->new_password))
	   ) {
      warn "\n\nATTENTION!!!!\n\n" . __PACKAGE__ . "::_general_pam_conv() called wrongly.\nSomething will break!\n\n";
      return (PAM_CONV_ERR, "", PAM_CONV_ERR);
    } else {
      $user         = $self->username;
      $new_password = $self->new_password;
    }
  }
  else {
    warn "\n\nATTENTION!!!!\n\n" . __PACKAGE__ . "::_general_pam_conv() called wrongly.\nSomething will break!\n\n";
    return (PAM_CONV_ERR, "", PAM_CONV_ERR);
  }


  my @response;

  #state controls what to do:
  # 0 => send old password
  # 1 => send new password
  # 2 => send new password (as a confirmation)
  my $state = 0;

  #done controls what stage have we done already
  #its function is to try to go blindly when
  #something goes wrong
  # 0 => nothing done yet.
  # 1 => sent old password
  # 2 => sent new password (once)
  # 3 => sent new password (twice)
  # 4 => sent new passowrd. This time we abort because there is
  #      something wrong.
  my $done = 0;

  #pass counter
  my $pass = 0;

  while ( @_ ) {
    #pam_code is the type of action PAM is asking us to do.
    my $pam_code = shift;
    #pam_message is the prompt to show the user.
    my $pam_message = shift;

    my $answer = "";
    $pass++;

    print "\n\nDEBUG: pass: $pass\n" if $DEBUG;
    print "DEBUG: code is $pam_code, PAM_MESSAGE is '$pam_message'\n" if $DEBUG;

    #we just continue if no failure has happen
    unless ($failure)
    {

      #Checks what type of code, pam replyed.
      #PAM_PROMPT_ECHO_ON,usually is the user name
      if ( $pam_code == PAM_PROMPT_ECHO_ON )
	{
	  #note that right now there is no database of setences used by
	  #PAM_PROMPT_ECHO_ON
	  #so we always assume it wants the user name.
	  #also note that the username was already given during Authen::PAM::new

	  print "DEBUG: PAM_PROMPT_ECHO_ON message '$pam_message'\n" if $DEBUG;
	  print "DEBUG: Sending the user name: $user\n" if $DEBUG;
	  $answer     = $user;
	}

      #PAM_PROMPT_ECHO_OFF usually is the new or old password.
      elsif ($pam_code == PAM_PROMPT_ECHO_OFF )
      {

	print "DEBUG: PAM_PROMPT_ECHO_OFF message '$pam_message'\n" if $DEBUG;

	#we try to verify what it wants accordinly with $pam_message

	if (defined ($state = _check_msg($pam_message)))
        {
	  print "DEBUG: PAM_PROMPT_ECHO_OFF: state: $state\n" if $DEBUG;
	  #state == 0 is the old_password
	  if ($state == 0)
	  {
	    print "DEBUG: sending the old password.\n" if $DEBUG;
	    $answer                    = $old_password;
	    $self->{used_old_password} = 1;
	    $done                      = 1;
	  }

	  #state == 1 or 2 is the new_password
	  elsif ($state == 1 || $state == 2)
	  {
	    print "DEBUG: sending the new pasword.\n" if $DEBUG;
	    $answer     = $new_password;

	    if (! $self->{used_old_password} && $done < 1)
	    {
	      print "DEBUG: The old password was not asked for (before)\n" if $DEBUG;
	      $done = 1;
	    }

	    $done++;
	  }
	  else
	  {
	    #we got an unknown state
	    #if this happens it is our fault
	    warn __PACKAGE__ . ": You seen to have found a bug in _general_pam_conv().\n";
	    warn __PACKAGE__ . ": state is $state and this is invalid.\n";
	    warn __PACKAGE__ . ": Please fill a bug report to relate this.\n";
	    warn __PACKAGE__ . ": I will try to continue, but it might not work.\n";

	    $answer     = $new_password;

	    if (! $self->{used_old_password} && $done < 1)
	    {
	      print "DEBUG: The old password was not asked for\n" if $DEBUG;
	      $done = 1;
	    }
	    $done++;
	  }
	}
	else
	{
	  # $state not defined
	  # This means that we got an unknow message.
	  # guessing blindly
	  warn "Don't know what to do about '$pam_message' .\n";
	  print "DEBUG: 'done' guess flag is $done\n";

	  if ($done == 0)
	  {
	    $answer     = $old_password;
	    warn "Trying to give the OLD password.\n";
	    $done ++;
	  }
	  elsif ($done > 0 && $done < 4)
	  {
	    $answer     = $new_password;

	    $done++;
	    warn "trying to give the NEW password.\n";
	  }
	  else
	  {
	    warn "Giving up.\n";
	  }
	}
	print "DEBUG: end of state comparation \n" if $DEBUG;
      }

      #PAM_ERROR_MSG is an error whichh we got.
      elsif ($pam_code == PAM_ERROR_MSG)
      {
	# we got some kind of error.
	my $error_message = _check_error_msg ($pam_message);

	#save the error messag
	$self->{pam_error_message} = $pam_message;
	$self->{error_code} = $error_message;

	if ($self->_abort_on_error)
	{
	  print "DEBUG: PAM_ERROR_MSG Aborting\n" if $DEBUG;
	  #advise pam about the error
	  $self->{conv_failure} = 1;
	  $failure = 1;
	  #note that this will cause PAM_CONV_ERR to be returned to the pam_function
	}
	else
	{
	  print "DEBUG: PAM_ERROR_MSG: Ignoring the error.\n" if $DEBUG;
	}
      }

      elsif ($pam_code == PAM_TEXT_INFO) {
	#Pam sent a informative message
	#for now this messages are hardcoded here
	print "DEBUG: PAM_TEXT_INFO: $pam_message\n" if $DEBUG;

	if ($pam_message =~ /^Changing password for (.*)$/)
        {
	  if (($1 ne $user) && ($self->_call_type eq "change_password"))
	  {
	    warn "Something bad is about to happen, I am trying to change";
	    warn " password for $user, howerver, the system expects $1\n";
	  }
	  else
	  {
	    print "DEBUG: PAM_TEXT_INFO: So far so good.\n" if $DEBUG;
	  }
	}
      }

      #PAM_RADIO_TYPE, multiple choose selection
      #like (yes, no,maybe).  Never seem this is use.
      elsif ($pam_code == PAM_RADIO_TYPE)
      {
	#FIX-ME
	#don't know how to deal with this
	warn __PACKAGE__ . "::change_password::conv(): Got PAM_RADIO_TYPE.\n";
	warn "Don't know what to do!\n";
	warn "Please contact the module's author to explain him how did you got";
	warn "this situation.\n";
      }

      #PAM_BINARY_PROMPT is not commonly used
      elsif ($pam_code == PAM_BINARY_PROMPT)
      {
	#FIX-ME
	#don't know how to deal with this
	warn __PACKAGE__ . "::change_password::conv(): Got PAM_BINARY_PROMPT.\n";
	warn "Don't know what to do!\n";
	warn "Please contact the module's author to explain him how did you got";
	warn "this situation.\n";
      }

      else
      {
	#got an unspecified PAM CODE
	warn __PACKAGE__ . "::change_password::conv(): Got an unexpected PAM CODE: $pam_code.\n";
	warn "Don't know what to do!\n";
      }
      push (@response, (PAM_SUCCESS, $answer));
    }
    else
    {
      push (@response, (PAM_CONV_ERR, ""));
    }
  }

  if ($failure)
  {
    push (@response, (PAM_CONV_ERR));
  }
  else
  {
    push (@response, (PAM_SUCCESS));
  }

  return @response;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Authen::SimplePam - Simple interface to PAM authentication

=head1 SYNOPSIS

  use Authen::SimplePam;
  $auth = new Authen::PAM;
  $auth->auth_user( $user, $password, $service );
  $auth->change_password ( $user, $old_password, $new_password );

=head1 DESCRIPTION

This module simplifies the use of PAM to Authenticate users.

It makes things simple so that no PAM knowledge is necessary.

=head1 API

The API is simple:

=over 4

=item * B<new>

Creates a Authen::SimplePam object.

=item * B<username ( $username ) >

If the parameter $username is set, it sets the username.
It will return the current username.

=item * B<user ( $username ) >

Same as B<username()>.

=item * B<name ( $username ) >

Same as B<username()>.

=item * B<current_password ( $password )>

The user current password.
If $password is given, the password is set.
It will return the current set password.

=item * B<password ( $password )>

Same as B<current_password()>.

=item * B<old_password( $password )>

Same as B<current_password()>.

=item * B<new_password ( $password )>

If $password is present, it will set the user new password.
It returns the current set new password.

=item * B<service ( $service )>

If $service is given, it will set the PAM service to use.
It will return the current service set.

=item * B<pam_result () >

Returns the last PAM result code.

=item * B<error_code ()>

Returns undef if no error has happened,
otherwise returns the error code.

=item * B<error_message ()>

Returns undef if no error has happened,
otherwise returns the error message.

Note that the error message is the pam
message give to a PAM_ERROR_MSG call.

Other error might have happened, but did not
set PAM_ERROR_MSG, but is in the result code
from the functions B<auth_user ()> and
B<change_password ()>.

=item * B<auth_user ($user, $password, $service)>

Authenticates a user $user, with the passwod $password agains
service $service.

Note that $user, $password and $service are optional.
If given they will overwrite any previously given one.

If no $serice has being yet specified, it will defaults
to the service 'login'.

If no $username has being yet specified, it will defaults
to the current EFECTIVE USER ID (EUID).

It will return Authen::SimplePam own result code.
If you would like to know the real PAM result code,
use B< pam_result() > to get it.

To get and string representation of the result, use
B<result2string () >.


=item * B<result2string ($result)>

Converts a result returned by B<auth_user()>
or B<change_password ()> to a string.

=back

=head1 RETURN CODES

These are the return codes returned by
B<auth_user> and B<change_password>.

=over 4

=item 0 Error using the Authen::PAM module.

Usually broken installation.

=item 1 Success.

The password match.

=item 2 Error.

The password does not match.

=item 3 Insufficient Credentials.

For some reason the application does not have enough credentials to authenticate the user.
E.g. A non-root user trying to authenticate/validate the root user password.

=item 4 Authentication information unavailable.

The modules were not able to access the authentication information. This might be due to a network or hardware failure etc.

=item 5 User Unknown.

The supplied username is not known to the authentication service

=item 6 Maximum tries.

One or more of the authentication modules has reached its limit of
tries authenticating the user. Do not try again.

=item 7 Unknown error.

Some unpredictable error happened.

=item 8 Authentication manipulation error.

Some error regarding the authentication happened.  Usually the B<service>
being used is invalid or is not well configured or requires some kind of
special behaviour from Authen::SimplePam.

=item *TODO* Finish description of return values.

=back

=head1 NOTES

=head2 MODULES

It is important to know that the way PAM will act depends on the underlying modules
being used and how they are stacked on the services.

So far, theis module has being tested with pam modules pam_pwdb.so (which is
a newer version of pam_unix.so) and pam_cracklib.so which tests the stregth
of new passwords.

Other modules might ask for different data and give different errors.

Authen::SimplePAM is written in a way that it is simple to insert this
new authentication modules.

=head2 SERVICES

Different services might have different results.

e.g. It is common to deny login to the user root if he is not using a console
if the service is 'login', however other services (like kde) might allow this.

If you use different PAM configuration and Authen::SimplePam is not working,
you can try to contact the author and provide as much information as possible
in order to let him understand what is missing and improve the module.

=head2 CHANGING PASSWORD

It is important to understand that changing passwords might not be
as simple as it seem and you probably can not do it unless you
are the root user.

The reason is simple, for most of the cases where the password is
stored in the /etc/passwd or /etc/shadow or any file in the system,
the user needs written permission to update it.
Usually only root has it.

As a side note the B<passwd> program that changes the password,
runs suid.

There is an issue (at least with pam_pwdb.so and pam_unix.so modules)
with suid.

If the UID (user id) is different from the EUID (effective user id),
and EUID is 0 (root), these modules will ask for the current password
before updating the account information.

Usually EUID == 0 and UID != EUID means that it is running in a suid
script/app, so this extra care is needed.

However if UID == EUID == 0, means that the user is really root,
so no confirmation of the current password is needed to change an
user account.

This can be done with $< = $> = 0; in a suid script, however this might be
a great security risk and I discourage that.


=head1 BUGS

Plesse report bugs, sugestions and Criticism to the AUTHOR.

=head1 LICENSE

GPL

=head1 AUTHOR

Raul Dias <raul@dias.com.br>

=head1 SEE ALSO

L<Authen::PAM>.

=cut
