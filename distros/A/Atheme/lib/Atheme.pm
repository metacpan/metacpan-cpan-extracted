package Atheme;
our $VERSION = '0.0001';

use strict;
use warnings;
use utf8;
use vars qw($ERROR);

use Carp;

$ERROR = '';

require RPC::XML;
require RPC::XML::Client;
use Atheme::Fault;

=head1 NAME

Atheme - Perl interface to Atheme's XML-RPC methods

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This class provides an interface to the XML-RPC methods of the Atheme IRC Services.

=head1 METHODS

These are all either virtual or helper methods. They are being implemented in
service-specific classes.

=head2 new

Services constructor. Takes a hash as argument:
   my $svs = new Atheme(url => "http://localhost:8000");

url<string>: URL to Atheme's XML-RPC server.

lang<string>: Language for result strings (en, ...).

validate<boolean>: If 1 then validation should be done in perl already, if 0
then validation is only done in atheme itself. In both cases, atheme
validates. If you choose to use the perl validation, you will get more verbose
fault messages containing an additional key 'subtype'.

=cut

sub new {
    my ($self, %arg) = @_;

    # There is no default for url
    my $url = delete $arg{url} or croak "Atheme: You need to provide an url";

    # Some default values
    my $svs = bless {
        rpc      => RPC::XML::Client->new($url),
        lang     => 'en',
        validate => 1,
        %arg,
    }, $self;

    $svs
}

=head2 return_dispatch

Handles results from RPC Calls!

Here is the list of fault types and default strings (these are likely to be
at least partially overridden by Atheme::*Serv classes.

    fault_needmoreparams = "Insufficient parameters."
    fault_badparams      = "Invalid parameters."
    fault_nosuch_source  = "No such source."
    fault_nosuch_target  = "No such target."
    fault_authfail       = "Authentication failed."
    fault_noprivs        = "Insufficient privileges."
    fault_nosuch_key     = "No such key."
    fault_alreadyexists  = "Item already exists."
    fault_toomany        = "Too many items."
    fault_emailfail      = "Email verification failed."
    fault_notverified    = "Action not verified."
    fault_nochange       = "No change."
    fault_already_authed = "You are already authenticated."
    fault_unimplemented  = "Method not implemented."
=cut

sub return_dispatch {
    my ($self, $return, @fault_strings_override) = @_;

    if(ref($return) eq "RPC::XML::fault")
    {
        my $faultcode = $return->code;

        # Default string table for the fault dispatch table (should be overridden per method)
        my @fault_strings = (
            [ "Insufficient parameters.", "fault_needmoreparams"],
            [ "Invalid parameters.", "fault_badparams"],
            [ "No such source.", "fault_nosuch_source"],
            [ "No such target.", "fault_nosuch_target"],
            [ "Authentication failed.", "fault_authfail" ],
            [ "Insufficient privileges.", "fault_noprivs" ],
            [ "No such key.", "fault_nosuch_key" ],
            [ "Item already exists.", "fault_alreadyexists" ],
            [ "Too many items.", "fault_toomany" ],
            [ "Email verification failed.", "fault_emailfail" ],
            [ "Action not verified.", "fault_notverified" ],
            [ "No change.", "fault_nochange" ],
            [ "You are already authenticated.", "fault_already_authed" ],
            [ "Method not implemented.", "fault_unimplemented" ],
        );

        @fault_strings = map { $fault_strings_override[$_] ||= $fault_strings[$_] } (0..$#fault_strings);

        return { type => $fault_strings[$faultcode-1][1], string => $fault_strings[$faultcode-1][0], code => $faultcode};
    }
    elsif(ref($return) eq "RPC::XML::string")
    {
        my $value = $return->value;
        return { type => 'success',    string => $value };
    }
    else
    {
        return { type => 'fault_http', string => "Connection refused." };
    }
}

=head2 call_svs

Method call

=cut

sub call_svs {
    my ($self, $args) = @_;

    my $result = $self->{rpc}->send_request('atheme.command', $args->{authcookie} || "x", $args->{nick} || "x", $args->{address} || "x", $args->{svs} || "x",$args->{cmd} || "x", @{$args->{params}});
    
    return $self->return_dispatch($result, ($args->{fault_overwrite} ? $args->{fault_overwrite} : {}));
}

=head2 login

A common method used to log into the services in order to execute other
methods. Every service inherits this, so you can load just Atheme::MemoServ
and log in through that.

=cut

sub login {
    my ($self, $args) = @_;

    # This method is different from all others and so has to be called separately.
    my $result = $self->{rpc}->send_request('atheme.login', $args->{nick}, $args->{pass}, $args->{address});

    my @overrides;

    $overrides[fault_needmoreparams-1] = ["Insufficient parameters.","fault_needmoreparams"];
    $overrides[fault_nosuch_source-1]  = ["The account is not registered.","fault_nosuch_source"];
    $overrides[fault_authfail-1]       = ["The password is not valid for this account.","fault_authfail"];
    $overrides[fault_noprivs-1]        = ["The account has been frozen.","fault_noprivs"];

    return $self->return_dispatch($result, @overrides);
}

=head2 logout

A common method used to log out and clean up your authcookie. This should be
done, but does not have to be done. This method is also inherited and
therefore usable in every *Serv.

=cut

sub logout {
   my ($self, $args) = @_;

   # Set required variables

   # This method is different from all others and so has to be called separately.
   my $result = $self->{rpc}->send_request('atheme.logout', $args->{authcookie}, $args->{nick});

   my @overrides;
   $overrides[Atheme::Fault::fault_nosuch_source()-1]  = ["Unknown user.","fault_nosuch_source"];
   $overrides[Atheme::Fault::fault_authfail()-1]       = ["Invalid authcookie for this account.","fault_authfail"];

   return $self->return_dispatch($result, @overrides);

}

=head1 AUTHORS

Pippijn van Steenhoven <pip88nl@gmail.com>
Stephan Jauernick <stephan@stejau.de>

=cut

1;