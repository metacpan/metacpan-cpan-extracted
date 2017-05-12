# $Id: ACE.pm,v 1.8 1997/12/09 18:33:45 carrigad Exp $

# Copyright (C), 1997, Interprovincial Pipe Line Inc.

package Authen::ACE;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
	ACM_OK
	ACM_ACCESS_DENIED
	ACM_NEXT_CODE_REQUIRED
	ACM_NEW_PIN_REQUIRED
	ACM_NEW_PIN_ACCEPTED
	ACM_NEW_PIN_REJECTED
	CANNOT_CHOOSE_PIN
	MUST_CHOOSE_PIN
	USER_SELECTABLE
);
$VERSION = '0.90';

sub PIN {
  my $self = shift;
  my $pin = shift;
  my $canceled = shift;

  return sd_pin($pin, $canceled, $self->{"sd"});
}

sub Next {
  my $self = shift;
  my $token = shift;
  return sd_next($token, $self->{"sd"});
}

sub Auth {
  my $self = shift;
  my $username = shift;
  return sd_auth($self->{"sd"}, $username);
}

sub Check {
  my $self = shift;
  my ($passcode, $username) = @_;
  die 'usage: $ace->check(passcode, username)' if ($passcode eq "" or $username eq "");

  my @results = sd_check($passcode, $username, $self->{"sd"});
  if ($results[0] == ACM_NEW_PIN_REQUIRED()) {
    $results[1] = {"system_pin" => $results[1],
		   "min_pin_len" => $results[2],
		   "max_pin_len" => $results[3],
		   "user_selectable" => $results[4],
		   "alphanumeric" => $results[5]};
    $#results = 1;
  }
  return @results;
}

sub new {
  my $type = shift;
  my %parms = @_;
  my $self = {};

  $ENV{"VAR_ACE"} = "/var/ace" unless defined($ENV{"VAR_ACE"});
  $ENV{"VAR_ACE"} = $parms{"config"} if defined $parms{"config"};

  if (creadcfg() != 0) {
    die "Could not read ACE client configuration file in " . $ENV{"VAR_ACE"} . "\n";
  }

  $self->{"sd"} = sd_init();
  die "Failed call to sd_init\n" unless defined $self->{"sd"};

  bless $self, $type;
}

sub DESTROY {
  my $self = shift;
  if (ref($self->{"sd"}) eq "SDClientPtr") {
    sd_close();
    undef $self->{"sd"}
  }
}

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Undefined ACE macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Authen::ACE $VERSION;


1;
__END__
=pod

=head1 NAME

Authen::ACE - Perl extension for accessing a SecurID ACE server

=head1 SYNOPSIS

  use Authen::ACE;
  $ace = new Ace([config => /config/directory])
  $ace->Check(code, username);
  $ace->PIN(PIN, [cancel]);
  $ace->Next(code);
  $ace->Auth([username]);

=head1 DESCRIPTION

Authen::ACE provides a client interface to a Security Dynamics SecurID
ACE server. SecurID authentication can be added to any Perl
application using Authen::ACE.

Instantiation of an object into the Authen::ACE class will establish a
connection to the ACE server; destruction of the object will close the
connection. Programs can then use the Check/PIN/Next methods to
authorize a user. TTY programs can also use the Auth method, which
handles all authorization tasks normally done by Check/PIN/Next.

=head1 METHODS

=over 4

=item new

 $ace = new Ace(["config" => "/config/directory"])

Creates a new Authen::ACE object. The I<config> parameter specifies
the location of the F<sdconf.rec> file. It defaults to the value of
the F<VAR_ACE> environment variable, or the directory F</var/ace> if
this variable isn't set.

=item Check

 ($result,$info) = $ace->Check(code, username)

This is the primary user authentication function. I<code> is the
PIN+token (or just the token if the user has no PIN), and username is
the user's name, as it is listed in the ACE database. 

I<Check> returns a two-element list. The first element contains the
results of the check; the second element contains extra,
result-specific information.

Possible results for $result are

=over 4

=item ACM_OK

The check succeeded. $info contains the shell specified for this user. 

=item ACM_ACCESS_DENIED

The check failed. No other information is included.

=item ACM_NEXT_CODE_REQUIRED

The check succeeded, but requires a second token to finish the
authentication. $info contains the number of seconds the
server will waits for the next code. Authen::ACE::Next should be
called with the next code upon receiving this result.

=item ACM_NEW_PIN_REQUIRED

A new PIN is required. $info is a ref to an anonymous hash with the
following elements

=over 4

=item system_pin

The system generated PIN.

=item min_pin_len

The minimum PIN length.

=item max_pin_len

The maximum PIN length.

=item alphanumeric

True is the PIN is allowed to be alphanumeric

=item user_selectable

Will have one of the values I<CANNOT_CHOOSE_PIN>, I<MUST_CHOOSE_PIN>,
I<USER_SELECTABLE>, which mean that the user must accept the system
generated PIN, must choose his own PIN, or can do either.

If the user accepts the system PIN or chooses his own, then a call
should be made to Authen::ACE::PIN with the selected PIN. If the user
rejects the system PIN, then a call should be made to Authen::ACE::PIN
with the value of the I<cancel> parameter set to 1.

=back

=back

=item Next

 ($result,$info) = $ace->Next(code)

This method should be called after receiving a
I<ACM_NEXT_CODE_REQUIRED> result from I<Check>. I<code> should be the
next to display on the user's token. Return value is the same as for
Authen::ACE::Check, except that there will never be a
I<ACM_NEW_PIN_REQUIRED> or I<ACM_NEXT_CODE_REQUIRED> result.

=item PIN

 $result = $ace->PIN(pin, [cancel]);

This method should be called after receiving a I<ACM_NEW_PIN_REQUIRED>
result from I<Check>. I<pin> should be the new PIN, while I<cancel>
should be set to one if the user wishes to cancel the new PIN
operation. Authen::ACE::PIN will return a result of either
I<ACM_NEW_PIN_ACCEPTED> or I<ACM_NEW_PIN_REJECTED>. 

=item Auth

 ($result,$info) = $ace->Auth([username]);

This method is a convenience method which will handle calling
I<Check>, and reading a new PIN or requesting the next token if
required. It should only be called if the running process is attached
to a tty. I<username> will be determined by the real PID of the
process running the program if it isn't passed as a parameter.

The return value is the same as for Authen::ACE::Check, except that
there will never be a I<ACM_NEW_PIN_REQUIRED> or
I<ACM_NEXT_CODE_REQUIRED> result.

=back

=head1 AUTHOR

Dave Carrigan <Dave.Carrigan@iplenergy.com>

Copyright (C) 1997 Dave Carrigan, Interprovincial Pipe Line Inc. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), ACE/Server Administration Manual, ACE/Server Client API Guide

=cut
