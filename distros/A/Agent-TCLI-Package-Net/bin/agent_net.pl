#!/usr/bin/perl
#
# $Id: agent_net.pl 56 2007-04-26 23:16:29Z hacker $
#
# This is a working example of a TCLI Agent program.

use warnings;
use strict;
use Pod::Usage;

=head1 NAME

agent_net - Run a TCLI Agent with the Net packages enabled.

=head1 SYNOPSIS

=over 12

=item B<agent_net>

B<username>S<=>I<username>
B<password>S<=>I<password>
B<domain>S<=>I<domain>
[B<resource>S<=>I<resource>]
[B<host>S<=>I<XMPP server>]
[B<help>]
[B<man>]
[B<verbose>]

=back

=head1 OPTIONS AND ARGUMENTS

=over 8

=item B<username>

The XMPP user the Agent will log in as, without the domain.
Required unless the script has been edited to enable a default user.

=item B<password>

The password to be used by the Agent to log in to the XMPP server.
Required unless the script has been edited to enable a default password.

=item B<domain>

The XMPP domain of the user account of the Agent.
Required unless the script has been edited to enable a default domain.

=item B<resource>

The XMPP resource. Defaults to 'tcli' if not provided.

=item B<host>

The XMPP server host, if different from the domain. Defaults to the
domain if not provided.

=item B<verbose>

The desired level of verbosity to use. Repeat for more effect.

=item B<help>

Print a brief help message and exit.

=item B<man>

Print this command's manual page and exit.

=back

=head1 DESCRIPTION

B<agent_net> will start a TCLI Agent running on the XMPP Transport
with the Net, Tail and XMPP packages loaded.

Use B<agent_net> as is or as the basis for creating Agents with different
functionaity.

=head1 SEE ALSO

L<Agent::TCLI>

L<Agent::TCLI::Package::Net>

=head1 AUTHOR

Eric Hacker E<lt>hacker at cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This script is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

# Useful for debugging or just seeing what the Agent is doing.
sub VERBOSE () { 0 }

# Process optional parameters from the command line and assign defaults.
use Getopt::Lucid qw(:all);

my ($opt, $verbose,$domain,$username,$password,$resource,$host);

eval {$opt = Getopt::Lucid->getopt([
		Param("domain|d"),
		Param("username|u"),
		Param("password|p"),
		Param("resource|r"),
		Param("host"),
		Param("master|m"),
		Counter("verbose|v"),
		Switch("help"),
		Switch("man"),
		Switch("blib|b"),
	])};

if($@)
{
	print "ERROR: $@ \n";
	pod2usage(1);
}

pod2usage(1)  if ($opt->get_help);
pod2usage(VERBOSE => 2)  if ($opt->get_man);

# Hidden switch for dev testing
if ($opt->get_blib)
{
	use lib 'blib/lib';
}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

# Optionally set default jabber/xmpp parameters to log in with
$username = $opt->get_username ? $opt->get_username : 'agent';
$password = $opt->get_password ? $opt->get_password : 'agent';
$resource = $opt->get_resource ? $opt->get_resource : 'tcli';
$domain = $opt->get_domain ? $opt->get_domain : 'example.com';
$host = $opt->get_host ? $opt->get_host : $domain;

# Error if options not set and not provided.
pod2usage(1) if ($username eq 'agent' or $domain eq 'example.com');

# Load required modules

use POE;						# POE is required for all Agents
use Agent::TCLI::User;			# TCLI users will have to be defined for each Agent

use Agent::TCLI::Transport::XMPP;	# A TCLI transport
use Net::XMPP::JID;					# Required for XMPP transport


# Optional Packages, without some, a bot is useless
use Agent::TCLI::Package::XMPP;		# Not required, but very useful to manage Transport::XMPP
									# especially if you want a graceful shutdown. :)

use Agent::TCLI::Package::Net::SMTP;
use Agent::TCLI::Package::Net::HTTP;
use Agent::TCLI::Package::Net::HTTPD;
use Agent::TCLI::Package::Net::Ping;
use Agent::TCLI::Package::Net::Traceroute;
use Agent::TCLI::Package::Tail;

# An alias is mostly useful when debugging, and must be unique within
# active POE::Sessions
my $alias = 'agent.net';

# Create new package objects to load for each package.
# Some packages may require extra parameters.

my @packages = (
	Agent::TCLI::Package::XMPP->new(
	     'verbose'    => \$verbose ,	# Optionally set verbosity for the package
	     								# by using a reference, we can later
	     								# change globally while running
	),
	Agent::TCLI::Package::Net::Ping->new(
	     'verbose'    => \$verbose ,
	),
	Agent::TCLI::Package::Net::Traceroute->new(
	     'verbose'    => \$verbose ,
	),
	Agent::TCLI::Package::Tail->new(
	     'verbose'    => \$verbose ,
	),
	Agent::TCLI::Package::Net::HTTP->new(
	     'verbose'    => \$verbose ,
	),
	Agent::TCLI::Package::Net::HTTPD->new(
	     'verbose'    => \$verbose ,
	),
	Agent::TCLI::Package::Net::SMTP->new(
	     'verbose'    => \$verbose ,
	),
);

# Define the authorized users of the Agent.

my @users = (
	# If the Tail agent is to be controlled by a test script, then the user the
	# test script will be run as has to be a user here.
	# It is OK to use the same XMPP user as long as the resource is different.
	Agent::TCLI::User->new(
		'id'		=> $username.'@'.$domain,
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
	defined ($opt->get_master) ?
	Agent::TCLI::User->new(
		'id'		=> $opt->get_master,
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	) : undef,
#	Agent::TCLI::User->new(
#		'id'		=> 'user2@'.$domain,
#		'protocol'	=> 'xmpp',
#		'auth'		=> 'master',
#	),

# xmpp_groupchat users will cause an Agent to join the groupchat MUC

#	Agent::TCLI::User->new(
#		'id'		=> 'conference_room@conference'.$domain,
#		'protocol'	=> 'xmpp_groupchat',
#		'auth'		=> 'master',
#	),
);

Agent::TCLI::Transport::XMPP->new(
     'jid'		=> Net::XMPP::JID->new($username.'@'.$domain.'/'.$resource),
     'jserver'	=> $host,
	 'jpassword'=> $password,
	 'peers'	=> \@users,

     'verbose'    => \$verbose,        # Verbose sets level or warnings

     'control_options'	=> {
	     'packages' 		=> \@packages,
     },
);

print "Starting ".$alias unless $verbose;

# Required to start the Agent
POE::Kernel->run();

print" FINISHED\n";

exit;

