#!/usr/bin/env perl
# $Id: TCLI.Control.Interactive.t 62 2007-05-03 15:55:17Z hacker $

use warnings;
use strict;
use Test::More tests => 49;
#use Test::More qw(no_plan);


# TASK Test suite is not complete. Need more testing for catching errors.

use Getopt::Lucid qw(:all);

sub VERBOSE () { 0 }

my ($opt, $verbose, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Counter("verbose|v"),
		Switch("blib|b"),
	])};
if($@) {die "ERROR: $@";}

if ($opt->get_blib)
{
	use lib 'blib/lib';
}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

# xmpp username/password to log in with
$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }

use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use POE;

BEGIN {
    use_ok('Agent::TCLI::Control');
    use_ok('Agent::TCLI::Command');
    use_ok('Agent::TCLI::User');
}

sub Init {

my @obj_cmds = (
		Agent::TCLI::Command->new(
	        'name'		=> 'meganat',
	        'contexts'	=> {'ROOT' => 'meganat'},
    	    'help' 		=> 'sets up outbound NAT table from a predefined address block',
        	'usage'		=> 'meganat add target=target.example.com',
        	'topic'		=> 'attack prep',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-pf',
	        'handler'	=> 'establish_context',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'noreset',
	        'contexts'	=> {'ROOT' => 'noreset'},
    	    'help' 		=> 'sets up outbound filters to block TCP RESETS to target',
        	'usage'		=> 'noreset add target=target.example.com',
        	'topic'		=> 'attack prep',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-pf',
	        'handler'	=> 'establish_context',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'add',
	        'contexts'	=> {
				'meganat' 	=> 'add',
				'noresets'	=> 'add',
				},
    	    'help' 		=> 'adds an address block to a table',
        	'usage'		=> 'add target=target.example.com',
        	'topic'		=> 'attack prep',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-pf',
	        'handler'	=> 'change_table',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'delete',
	        'contexts'	=> {
				'meganat' 	=> 'delete',
				'noresets'	=> 'delete',
				},
    	    'help' 		=> 'removes an address block from a table',
        	'usage'		=> 'delete target=target.example.com',
        	'topic'		=> 'attack prep',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-pf',
	        'handler'	=> 'change_table',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test_all',
	        'contexts'	=> {'ROOT' => 'test_all'},
    	    'help' 		=> 'under test_all is one handler for everything',
        	'usage'		=> 'test_all anything',
        	'topic'		=> 'all',
        	'call_style'=> 'session',
        	'command'	=> 'test_all',
	        'handler'	=> 'establish_context',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'all',
	        'contexts'	=> {'test_all' => 'ALL'},
    	    'help' 		=> 'anything in context test_all',
        	'usage'		=> 'anything',
        	'topic'		=> 'all',
        	'call_style'=> 'session',
        	'command'	=> 'test_all',
	        'handler'	=> 'all',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'show',
	        'contexts'	=> {
				'meganat' 	=> 'show',
				'noresets'	=> 'show',
				'test1'		=> {
					'GROUP'				=> 'show',
					'test1.1'		=> {
						'test1.1.1'		=> 'show',
						'test1.1.2'		=> 'show',
						'test1.1.3'		=> 'show',
						},
					'test1.2'		=> {
						'GROUP'		=> 'show',
						},
					'test1.3'		=> {
						'GROUP'		=> 'show',
						},
					},
				},
    	    'help' 		=> 'shows  tables',
        	'usage'		=> 'show',
        	'topic'		=> 'attack prep',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-pf',
	        'handler'	=> 'show',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1',
	        'contexts'	=> {'ROOT' => 'test1'},
    	    'help' 		=> 'test1 help',
        	'usage'		=> 'test1 test1.1 test 1.1.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-test',
	        'handler'	=> 'establish_context',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1.1',
	        'contexts'	=> {
	        	'test1' => ['test1.1','test1.2','test1.3',],
	        	},
    	    'help' 		=> 'test1.1 help',
        	'usage'		=> 'test1.1 test 1.1.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-test',
	        'handler'	=> 'establish_context',
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1.1.1',
	        'contexts'	=> {
	        	'test1'	=> {
		        	'test1.1' => ['test1.1.1','test1.1.2','test1.1.3'],
		        	'test1.2' => ['test1.1.1','test1.1.2','test1.1.3'],
	    	    	'test1.3' => ['test1.1.1','test1.1.2','test1.1.3'],
	        		},
	        	},
    	    'help' 		=> 'test1.1.1 help',
        	'usage'		=> 'test 1.1.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'tcli-test',
	        'handler'	=> 'establish_context',
		),
);

my @dc = (
	{ #echo
        name 		=> 'echo',
        help 	=> 'Return what was said.',
        usage 		=> 'echo <something> or /echo ...',
        topic 		=> 'general',
        command 	=> 'pre-loaded',
        contexts   	=> ['UNIVERSAL'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        name      	=> 'Hi',
        help 	=> 'Greetings',
        usage     	=> 'Hi',
        topic     	=> 'Greetings',
        command 	=> 'pre-loaded',
        contexts   	=> ['ROOT'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        name      	=> 'Hello',
        help 	=> 'Greetings',
        usage     	=> 'Hello',
        topic     	=> 'Greetings',
        command 	=> 'pre-loaded',
        contexts   	=> ['ROOT'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        name      	=> 'hello',
        help 	=> 'Greetings',
        usage     	=> 'hello',
        topic     	=> 'Greetings',
        command 	=> 'pre-loaded',
        contexts   	=> ['ROOT'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        name      	=> 'hi',
        help 	=> 'Greetings',
        usage     	=> 'hi',
        topic     	=> 'Greetings',
        command 	=> 'pre-loaded',
        contexts   	=> ['ROOT'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        name      	=> 'context',
        help 	=> "displays the current context",
        usage     	=> 'context or /context',
        topic     	=> 'general',
        command 	=> 'pre-loaded',
        contexts   	=> ['ROOT'],
        call_style     	=> 'state',
        handler		=> 'general'
    },
    {
        'name'		=> 'help',
        'help'	=> 'Display help about available commands',
        'usage'		=> 'help [ command ] or /help',
        'topic'		=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts'	=> ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'help'
    },
    {
        'help' => 'Display general CLI control status',
        'usage' 	=> 'status or /status',
        'topic' 	=> 'general',
        'name' 		=> 'status',
        'command' 	=> 'pre-loaded',
        'contexts'	=> ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'general'
    },
    {
        'name'      => 'ROOT',
        'help' => "restore root context, use '/command' for a one time switch",
        'usage'     => '/   ',
        'topic'     => 'general',
        'command'   => 'pre-loaded',
        'contexts'   => ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'exit',
    },
    {
        name      => 'load',
        help => 'Load a new control package',
        usage     => 'load < PACKAGE >',
        topic     => 'admin',
        command   =>  sub {return ("load is currently diabled")}, #\&load,
        call_style     => 'sub',
    },
    {
        'name'      => 'listcmd',
        'help' => 'Dump the registered commands in their contexts',
        'usage'     => 'listcmd (<context>)',
        'topic'     => 'admin',
        'command'   => 'pre-loaded',
        'contexts'   => ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'listcmd',
    },
    {
        'name'      => 'dumpcmd',
        'help' => 'Dump the registered command hash information',
        'usage'     => 'dumpcmd <cmd>',
        'topic'     => 'admin',
        'command'   => 'pre-loaded',
        'contexts'   => ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'dumpcmd',
    },
    {
        'name'      => 'nothing',
        'help' => 'Nothing is as it seems',
        'usage'     => 'nothing',
        'topic'     => 'general',
        'command'   => sub {return ("You said nothing, try 'help'")},
        'call_style'     => 'sub',
    },
    {
        'name'      => 'exit',
        'help' => "exit the current context, returning to previous context",
        'usage'     => 'exit or /exit',
        'topic'     => 'general',
        'command'   => 'pre-loaded',
        'contexts'   => ['UNIVERSAL'],
        'call_style'     => 'state',
        'handler'	=> 'exit',
    },
	);

	return(@obj_cmds);
}

# put in sub so I could fold it in eclipse
my (@obj_cmds) = Init();

use Agent::TCLI::Package::Base;

# Default Commands tests

# Need some module loaded
my $test_base = Agent::TCLI::Package::Base->new({
	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

# Put some extral commands in there
$test_base->AddCommands(
		Agent::TCLI::Command->new(
	        'name'		=> 'test_all',
	        'contexts'	=> {'ROOT' => 'test_all'},
    	    'help' 		=> 'under test_all is one handler for everything',
        	'usage'		=> 'test_all anything',
        	'topic'		=> 'all',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'establish_context',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'all',
	        'contexts'	=> {'test_all' => 'ALL'},
    	    'help' 		=> 'anything in context test_all',
        	'usage'		=> 'anything',
        	'topic'		=> 'all',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'settings',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'show',
	        'contexts'	=> {
				'ROOT' 	=> 'show',
				'test1'		=> {
					'GROUP'				=> 'show',
					'test1.1'		=> {
						'test1.1.1'		=> 'show',
						'test1.1.2'		=> 'show',
						'test1.1.3'		=> 'show',
						},
					'test1.2'		=> {
						'GROUP'		=> 'show',
						},
					'test1.3'		=> {
						'GROUP'		=> 'show',
						},
					},
				},
    	    'help' 		=> 'shows configuration or other information',
        	'usage'		=> 'show',
        	'topic'		=> 'general',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'show',
	        'parameters' => {
	        	'name' => 1,
	        	},
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1',
	        'contexts'	=> {'ROOT' => 'test1'},
    	    'help' 		=> 'test1 is a test command',
        	'usage'		=> 'test1 test1.1 test 1.1.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'establish_context',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1.x',
	        'contexts'	=> {
	        	'test1' => ['test1.1','test1.2','test1.3',],
	        	},
    	    'help' 		=> 'test1.x is a test command',
        	'usage'		=> 'test1.1 test 1.1.1',
        	'manual'	=> 'The test1.x series of commands are available within the test1 context and are containers for many subcommands. Their primary purpose if for testing TLCI.',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'establish_context',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1.1.y',
	        'contexts'	=> {
	        	'test1'	=> {
		        	'test1.1' => ['test1.1.1','test1.1.2','test1.1.3'],
		        	'test1.2' => ['test1.1.1','test1.1.2','test1.1.3'],
	    	    	'test1.3' => ['test1.1.1','test1.1.2','test1.1.3'],
	        		},
	        	},
    	    'help' 		=> 'test1.1.y is a test command',
        	'usage'		=> 'test 1.1.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'establish_context',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),
		Agent::TCLI::Command->new(
	        'name'		=> 'test1.2.1',
	        'contexts'	=> {
	        	'test1'	=> {
		        	'test1.1' => 'test1.2.1',
		        	'test1.2' => 'test1.2.1',
	    	    	'test1.3' => 'test1.2.1',
	        		},
	        	},
    	    'help' 		=> 'test1.2.1 is a test command',
        	'usage'		=> 'test 1.2.1',
        	'topic'		=> 'testing',
        	'call_style'=> 'session',
        	'command'	=> 'base',
	        'handler'	=> 'establish_context',
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		),

);

my $test_master = Agent::TCLI::Transport::Test->new({
    'control_options'	=> {
	     'packages' 	=> [ $test_base, ],
    },

	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});

my $t = Agent::TCLI::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);

# From here on out, verbose is either on or off because these are queued events.
#$verbose = 3;
is($test_base->name,'base', '$test_base->name ');

# are we in the right place?
$t->like_body('show name',qr(base));

#$verbose = 0;
# general tests
$t->ok('status');
$t->ok('hi');
$t->like_body('echo this',qr(this) );
$t->like_body('echo that is not this',qr(that is not this) );
$t->is_body( 'context','Context: ROOT','verify root context');
$t->ok('debug_request');
$t->ok('exit');
$t->ok('root');
$t->ok('Verbose');

#help tests
$t->is_code( 'help',200, 'help');
$t->is_code( '/',200, 'root context');
$t->is_body( 'context','Context: ROOT','verify root context');
$t->is_code( 'test1',200, 'test1 context');
$t->is_body( 'context','Context: test1','verify test1 context');
$t->like_body( 'help',qr(test1.1.*?test1.2.*?test1.3)s, "help");
$t->like_body( 'help test1.1',qr(test1.x is a test command)s, "help test1.1");
$t->is_code( 'test1.1',200, 'test1.1 context');
$t->is_body( 'context','Context: test1 test1.1','verify test1.1 context');
$t->like_body( 'help',qr(show.*?test1.1.1.*?test1.2.1)s, "help");
$t->like_body( 'help',qr(global.*?exit.*?help)s, "help with globals");
$t->like_body( 'help globals',qr(global.*?exit.*?help)s, "help globals in context");
$t->like_body( 'exit',qr(Context now: test1),"exit ok" );
$t->is_body( 'exit','Context now: ROOT', 'exit Context now: root');
$t->like_body( 'help globals',qr(global.*?exit.*?help)s, "help globals at root");

#manual tests

#$verbose = 2;
#
$t->is_code( 'manual manual',200, 'manual');
$t->is_code( '/',200, 'root context');
$t->is_body( 'context','Context: ROOT','verify root context');
$t->is_code( 'test1',200, 'test1 context');
$t->is_body( 'context','Context: test1','verify test1 context');
$t->like_body( 'manual test1.1',qr(testing TLCI)s, "manual test1.1");
$t->is_code( 'test1.1',200, 'test1.1 context');
$t->is_body( 'context','Context: test1 test1.1','verify test1.1 context');
$t->like_body( 'manual test1.1.1',qr(help for command)s, "manual gives help when not defined");
$t->like_body( 'manual manual',qr(manual command provides detailed)s, "manual for global in context");
$t->like_body( 'exit',qr(Context now: test1),"exit ok" );
$t->is_body( 'exit','Context now: ROOT', 'exit Context now: root');
$test_master->done;

# Control tests
$t->ok('Control show user');
is($t->get_param('id','',1),'test-master@localhost', 'test user check');
$t->ok('Control show auth');
is($t->get_param('auth','',1),'master', 'test auth check');
$t->ok('Control show local_address');
is($t->get_param('address','',1),'127.0.0.1', 'test local_address check');


$test_master->run;


