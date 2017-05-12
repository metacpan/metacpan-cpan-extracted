#!perl -T
##########################################################################
# This is a test to check that when the user_agent attribute ie changed  #
# the handlers are correctly added and removed from the user agents.     #
##########################################################################

use strict;
use warnings;

use Test::More;

use Authen::CAS::External;
use LWP::UserAgent;
use URI;

##########################################################################
# CREATE TWO USER AGENT OBJECTS
my $user_agent_1 = LWP::UserAgent->new;
my $user_agent_2 = LWP::UserAgent->new;

##########################################################################
# CREATE A NEW OBJECT
my $authen = Authen::CAS::External->new(
	cas_url    => URI->new('https://cas.example.net'),
	user_agent => $user_agent_1,
);

##########################################################################
# TEST VARIABLES
my %handler_matches = (
	request_prepare => {
		m_host => $authen->cas_url->host,
		owner  => $authen->_handler_owner_name,
	},
	response_redirect => {
		m_host => $authen->cas_url->host,
		owner  => $authen->_handler_owner_name,
	},
	response_done => {
		m_host => $authen->cas_url->host,
		owner  => $authen->_handler_owner_name,
	},
);

##########################################################################
# PLAN TESTS
plan tests => 5 * scalar keys %handler_matches;

##########################################################################
# TEST THE USER AGENT HAS TRIGGERS
{
	foreach my $phase (sort keys %handler_matches) {
		ok(defined $authen->user_agent->get_my_handler(
			$phase,
			%{$handler_matches{$phase}},
		), "$phase is present in current user agent");
	}
}

##########################################################################
# TEST THE USER AGENT HAS TRIGGERS
{
	foreach my $phase (sort keys %handler_matches) {
		ok(defined $user_agent_1->get_my_handler(
			$phase,
			%{$handler_matches{$phase}},
		), "$phase is present in current user agent 1");
	}
}

##########################################################################
# CHANGE THE USER AGENT
$authen->user_agent($user_agent_2);

##########################################################################
# TEST THE USER AGENT HAS TRIGGERS
{
	foreach my $phase (sort keys %handler_matches) {
		ok(defined $authen->user_agent->get_my_handler(
			$phase,
			%{$handler_matches{$phase}},
		), "$phase is present in current current user agent");
	}
}

##########################################################################
# TEST THE USER AGENT HAS TRIGGERS
{
	foreach my $phase (sort keys %handler_matches) {
		ok(!defined $user_agent_1->get_my_handler(
			$phase,
			%{$handler_matches{$phase}},
		), "$phase is not present in current user agent 1");
	}
}

##########################################################################
# TEST THE USER AGENT HAS TRIGGERS
{
	foreach my $phase (sort keys %handler_matches) {
		ok(defined $user_agent_2->get_my_handler(
			$phase,
			%{$handler_matches{$phase}},
		), "$phase is present in current user agent 2");
	}
}
