package Agent::TCLI;
#
# $Id: TCLI.pm 64 2007-05-03 18:05:09Z hacker $
#
=head1 NAME

Agent::TCLI - Transactional Contextual Line Interface

=head1 VERSION

This document describes Agent::TCLI::Base version 0.02

TCLI is currently alpha. While most things work, not everything
has been tested. Many revisions to the API have been made already
and it is hoped that nothing major needs to be changed to get to a 1.0
release. Additions are anticipated.

The documentation still needs much more improvement.

=cut

our $VERSION = '0.032';

=head1 SYNOPSIS

This is a documentation and version only module. A simple Agent script
enabling the Tail command package is installed with this module.
See L<tail_agent> or run:

	tail_agent man

=head1 DESCRIPTION

TCLI is an acronym for Transactional Contextual command Line
Interface. Optionally it may stand for Tester's Command Line
Interface.

TCLI supports the writing of agents (Agents) that interact with their
host operating system or the network with a current focus on
supporting functional testing.

TCLI supports the writing of TAP compliant L<http://testanything.org/> test
scripts that control the agents. The tests pass or fail depending on
the responses from the agents.

TCLI is designed to be network protocol agnostic. It currently
supports a Jabber/XMPP Transport as a module that ships with the
core. An HTTP transport is planned. Transports may support both a
human interface (the CLI) and an RPC interface. The RPC interface
supports the testing capability, but could also be used to interact
in a client server like manner with a GUI or other application.

TLCI is designed to allow new commands to be added
through additional modules in collections called packages.
TCLI attempts to make writing these
modules easier by providing Base classes that offer much of the
needed functionality to support the standardized, easy to learn human
interface. The goal is to allow users to add new functionality without
having then spend a lot of time learning the particular syntax of a
new tool.

=head1 GETTING STARTED

The quickest way to start running an agent is to run the provided Tail Agent:

	tail_agent user=<user> password=<example> domain=<example.com>

One must fist have created a Jabber/XMPP account for the agent to log in to.
One can then log in with a Jabber client using the same user ID and password
and communicate with the Agent. The Agnet will be logged in using the
resource 'tcli'. Jabber clients vary in how to start a chat with onself
at a different resource, so please see your Jabber client documentation
for details.

=head1 COMPONENTS

The following modules make up the core of the TCLI system.

=head2 Agent::TCLI::Control

The L<Agent::TCLI::Control> is the key broker between the Transports and the
Command Packages. It routes the command to the appropriate package. Control
also implements the a few of the required commands such as help. Controls
are spawned for each user, although currently Package state is not maintained
per user.

=head2 Agent::TCLI::Transport

Transports provide the human and the automated interfaces to TCLI. Currently
there is a Jabber/XMPP Transport and the special case Test transport.

=head2 Agent::TCLI::Package

Packages are collections of commands that implement some funtionality.
Packages may be entirely Perl, or may interface with a command line
application. Packages maintain a parameter session state using defaults.

=head2 Agent::TCLI::Command

L<Agent::TCLI::Command> is used by Packages to define the components of a
command. It includes the necessary parameters, the manual and help text, as
well and the context information for the Control to use.

=head2 Agent::TCLI::Parameter

L<Agent::TCLI::Parameter> is used in Packages and Commands to define the
parameters that commands accept. It includes help and manual text,
validation constraints and other information to make processing consitent.

=head2 Agent::TCLI::Request

L<Agent::TCLI::Request> is used internally in the TCLI system to describe
the user's request and route it between components. Transports may serialize
requests and send them between agents just use them locally to interact
with the Control.

=head2 Agent::TCLI::Response

L<Agent::TCLI::Response> is used internally in the TCLI system to describe
the response(s) to a user's request. It is a subclass of Request.

=head2 Agent::TCLI::User

L<Agent::TCLI::User> is used to define the users that will be allowed
to access an agent. They are defined in the agent script and loaded into
the transport.

=cut

'The end';
#__END__

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

Test scripts not thorough enough.

Probably many many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
