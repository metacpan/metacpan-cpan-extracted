#!/usr/bin/env perl
# $Id: TCLI.Package.XMPP.t 49 2007-04-25 10:32:36Z hacker $

use Test::More tests => 32;
use lib 'blib/lib';
use warnings;
use strict;

use Getopt::Lucid qw(:all);

sub VERBOSE () { 0 }

my ($opt, $verbose,$domain,$username,$password,$host, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Param("domain"),
		Param("username|u"),
		Param("password|p"),
		Param("host"),
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Counter("xmpp_debug|x"),
		Counter("verbose|v"),
	])};
if($@) {die "ERROR: $@";}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

# xmpp username/password to log in with
$username = $opt->get_username ? $opt->get_username : 'testy1';
$password = $opt->get_password ? $opt->get_password : 'testy1';
$domain = $opt->get_domain ? $opt->get_domain : 'testing.erichacker.com';
$host = $opt->get_host ? $opt->get_host : 'testing.erichacker.com';
$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use Agent::TCLI::Transport::XMPP;
use Agent::TCLI::User;
use POE;

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Package::XMPP');
use_ok('Net::XMPP::JID');

# Set up transport, otherwise commands don't work

my @packages = (
#	Agent::TCLI::Package::XMPP->new(
#	     'verbose'    => $verbose ,
#		 'do_verbose'	=> sub { diag( @_ ) },
#	),
);

my @users = (
	Agent::TCLI::User->new(
		'id'		=> 'testy2@testing.erichacker.com',
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
	Agent::TCLI::User->new(
		'id'		=> 'testy3@testing.erichacker.com',
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
#	Agent::TCLI::User->new(
#		'id'		=> 'testing@conference.jabber.erichacker.com',
#		'protocol'	=> 'xmpp_groupchat',
#		'auth'		=> 'master',
#	),
);

Agent::TCLI::Transport::XMPP->new(
     'jid'		=> Net::XMPP::JID->new($username.'@'.$domain.'/tcli'),
     'jserver'	=> $host,
#	 'jpassword'=> $password,
	 'peers'	=> \@users,

	 'xmpp_debug' 		=> 0,
	 'xmpp_process_time'=> 1,

     'verbose'    => \$verbose,        # Verbose sets level or warnings
	 'do_verbose'	=> sub { diag( @_ ) },

     'control_options'	=> {
	     'packages' 	=> \@packages,

     },
);

my $test1 = Agent::TCLI::Package::XMPP->new({
	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $test_master = Agent::TCLI::Transport::Test->new({
#	'peers'	=> \@users,

    'verbose'   	=> \$verbose,        # Verbose sets level or warnings
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	     'packages' 	=> [ $test1, ],
    },

});

my $t = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);


is($test1->name,'tcli_xmpp', '$test1->name correct');
my $test_c1 = $test1->commands();
is(ref($test_c1),'HASH', '$test1->Commands is a hash');
is($test_c1->{'xmpp'}->command,'tcli_xmpp', 'command xmpp command');
is($test_c1->{'xmpp'}->handler,'establish_context', 'command xmpp handler');
is($test_c1->{'xmpp'}->name,'xmpp', 'command xmpp name');
is($test_c1->{'xmpp'}->call_style,'session', 'command xmpp style');

$t->like_body('xmpp show group_mode',qr(named), "show group_mode");
$t->ok('xmpp change group_mode prefixed',  "change group_mode prefixed");
$t->like_body('xmpp show group_mode',qr(prefixed), "show group_mode prefixed");
$t->ok('xmpp change group_mode log', "change group_mode log ");
$t->like_body('xmpp show group_mode',qr(log), "show group_mode log ");
$t->ok('xmpp change group_mode all', "change group_mode all");
$t->like_body('xmpp show group_mode',qr(all), "show group_mode all");
$t->ok('xmpp change group_mode named', "change group_mode named ");
$t->like_body('xmpp show group_mode',qr(named), "show group_mode named");

$t->like_body('xmpp show group_prefix',qr(\:), "show group_prefix :");
$t->ok('xmpp change group_prefix $',"change group_prefix \$");
$t->like_body('xmpp show group_prefix',qr($), "show group_prefix \$");
$t->ok('xmpp change group_prefix :',"change group_prefix :");
$t->like_body('xmpp show group_prefix',qr(\:), "show group_prefix :");

$t->like_body('xmpp peer add id=testy10@testing.erichacker.com protocol=xmpp auth=master',qr(add testy10.testing.erichacker.com successful), "add peer user");
$t->like_body('xmpp show peers ',qr(^id: testy10.testing.erichacker.com$)m, "show peer users");

$t->like_body('xmpp peer add id=me@erichacker.com  auth=master',qr(Invalid Args: Required option 'protocol'), "add peer user no protocol");

$t->like_body('xmpp peer add id=testy11@testing.erichacker.com protocol=xmpp auth=master password=password',qr(add testy11.testing.erichacker.com successful), "add peer user with password");
$t->like_body('xmpp show peers ',qr(^id: testy11.testing.erichacker.com$)m, "show peer users");

$t->like_body('xmpp peer delete id=testy11@testing.erichacker.com',qr(delete testy11.testing.erichacker.com successful), "delete peer user");
$t->unlike_body('xmpp show peers ',qr(^id: testy11.testing.erichacker.com$)m, "show peer users delete");


# Need to shutdown or POE never stops.
$t->ok('xmpp shutdown');

$test_master->run;




