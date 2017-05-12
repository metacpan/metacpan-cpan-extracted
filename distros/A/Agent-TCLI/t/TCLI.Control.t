#!/usr/bin/env perl
# $Id: TCLI.Control.t 62 2007-05-03 15:55:17Z hacker $

use warnings;
use strict;
use Test::More tests => 402;

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
	        'name'		=> 'tshow',
	        'contexts'	=> {
				'meganat' 	=> 'tshow',
				'noresets'	=> 'tshow',
				'test1'		=> {
					'GROUP'				=> 'tshow',
					'test1.1'		=> {
						'test1.1.1'		=> 'tshow',
						'test1.1.2'		=> 'tshow',
						'test1.1.3'		=> 'tshow',
						},
					'test1.2'		=> {
						'GROUP'		=> 'tshow',
						},
					'test1.3'		=> {
						'GROUP'		=> 'tshow',
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

my $test1 = Agent::TCLI::Control->new(
	'context'	=> 'ROOT',
	'id'		=> 'test_control_1',

	'verbose'		=> \$verbose,
	# Overide normal verbose output by using diag instead of print
	'do_verbose'	=> sub { diag( @_ ) },
);

my $test2 = Agent::TCLI::Control->new(
	'id'		=> 'test_control_2',

	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
);


# Test context methods
is($test1->print_context,'ROOT', '$test1->print_context  from init args');
$test1->pop_context();
is($test1->print_context,'ROOT', '$test1->print_context  after Popping /');
is($test1->depth_context,0, '$test1->depth_context for /');
ok($test1->push_context('test'),'$test1 push context onto / ');
is($test1->depth_context,1, '$test1->depth_context for test ');
is($test1->print_context,'test', '$test1->print_context  test');
$test1->pop_context();
is($test1->print_context,'ROOT', '$test1->print_context after Popping test');
is($test1->depth_context,0, '$test1->depth_context for /');


ok($test2->context(['test']),'set $test2->context( )  ');
is_deeply($test2->context,['test'], '$test2->context accessor from Set');
is($test2->depth_context,1, '$test2->depth_context for (test)');
$test2->push_context('two');
is($test2->print_context,'test two', '$test2->print_context Pushed two');
is($test2->depth_context,2, '$test2->depth_context for (test two)');
$test2->push_context('three');
is($test2->print_context,'test two three', '$test2->context accessor Pushed three');
is($test2->depth_context,3, '$test2->depth_context for (test two three)');
$test2->pop_context();
is($test2->print_context,'test two', '$test2->context accessor Popped three');
is($test2->depth_context,2, '$test2->depth_context for (test two) again');

my (@cmds, @bad_cmds);
foreach my $cmd ( @obj_cmds )
{
	ok($test1->RegisterCommand( $cmd ),'Register Cmd '.$cmd->name );
	push( @cmds, [$cmd->name, $cmd->contexts, '',  ] );
}

my ($tcmd, $ttxt, $preargs);

$test1->Verbose(" cmd dump",3, \@cmds );
$test1->Verbose(" command dump",3, $test1->commands );

foreach my $test ( @cmds )
{
	foreach my $tcontext ( keys %{ $test->[1] } )
	{
		$test1->Verbose("# tcontext(".$tcontext.") \n");
		if (ref( $test->[1]{$tcontext} ) eq 'HASH')
		{
			foreach my $t2context ( keys %{ $test->[1]{$tcontext} } )
			{
				$test1->Verbose( "# t2context(".$t2context.") \n");
				if (ref($test->[1]{$tcontext}{$t2context}) eq 'HASH')
				{
					foreach my $t3context ( keys %{ $test->[1]{$tcontext}{$t2context} } )
					{
						if ($t3context ne 'UNIVERSAL')
						{
							$test1->context( $tcontext, $t2context, $t3context );
							($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ]);
							$test1->Verbose( "# 3 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
							is($ttxt,'', 'Found cmd '.$test->[0] );
							is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
							($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0], 'arg1' ]);
							$test1->Verbose( "# 3 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
							is($ttxt,'', 'Found cmd '.$test->[0].' arg1' );
							is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

							$test1->context( $tcontext, $t2context );
							($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $t3context, $test->[0] ]);
							$test1->Verbose( "# 3 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
							is($ttxt,'', 'Found cmd '.$t3context.' '.$test->[0] );
							is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

							$test1->context( $tcontext );
							($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $t2context, $t3context, $test->[0] ]);
							$test1->Verbose( "# 3 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
							is($ttxt,'', 'Found cmd '.$t2context.' '.$t3context.' '.$test->[0] );
							is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

							$test1->context( 'ROOT' );
							($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $t2context, $t3context, $test->[0] ]);
							$test1->Verbose( "# 3 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
							is($ttxt,'', 'Found cmd '.$tcontext.' '.$t2context.' '.$t3context.' '.$test->[0] );
							is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
						}
					}
				}
				else
				{
					if ($t2context ne 'UNIVERSAL')
					{
						$test1->context( $tcontext, $t2context );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ]);
						$test1->Verbose( "# 2 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$test->[0] );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0], 'arg1' ]);
						$test1->Verbose( "# 2 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$test->[0].' arg1' );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0], 'arg1', 'arg2' ]);
						$test1->Verbose( "# 2 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$test->[0].' arg1 arg2' );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

						$test1->context( $tcontext );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $t2context, $test->[0] ]);
						$test1->Verbose( "# 2 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$t2context.' '.$test->[0] );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $t2context, $test->[0], 'arg1' ]);
						$test1->Verbose( "# 2 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$t2context.' '.$test->[0].' arg1 ' );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

						$test1->context( 'ROOT' );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $t2context, $test->[0] ]);
						$test1->Verbose( "# 2/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$tcontext.' '.$t2context.' '.$test->[0] );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
						($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $t2context, $test->[0], 'arg1' ]);
						$test1->Verbose( "# 2/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
						is($ttxt,'', 'Found cmd '.$tcontext.' '.$t2context.' '.$test->[0].' arg1' );
						is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
					}
				}
			}
		}
		else
		{
			$test1->context( $tcontext );
			($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ]);
			$test1->Verbose( "# 1 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
			is($ttxt,'', 'Found cmd '.$test->[0]);
			is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
			($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ], 'arg1');
			$test1->Verbose( "# 1 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
			is($ttxt,'', 'Found cmd '.$test->[0].' arg1' );
			is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
			($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ], 'arg1', 'arg2');
			$test1->Verbose( "# 1 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
			is($ttxt,'', 'Found cmd '.$test->[0].' arg1 arg2' );
			is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
			($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ], 'arg1', 'arg2', 'arg3');
			$test1->Verbose( "# 1 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
			is($ttxt,'', 'Found cmd '.$test->[0].' arg1 arg2 arg3' );
			is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
			($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $test->[0] ], 'arg1', 'exit');
			$test1->Verbose( "# 1 tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
			is($ttxt,'', 'Found cmd '.$test->[0].' arg1 exit' );
			is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );

			if ( $tcontext ne 'ROOT' )
			{
				$test1->context( 'ROOT' );
				($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $test->[0] ]);
				$test1->Verbose( "# 1/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
				is($ttxt,'', 'Found cmd '.$tcontext.' '.$test->[0] );
				is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
				($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $test->[0], 'arg1' ]);
				$test1->Verbose( "# 1/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
				is($ttxt,'', 'Found cmd '.$tcontext.' '.$test->[0].' arg1' );
				is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
				($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $test->[0], 'arg1', 'arg2' ]);
				$test1->Verbose( "# 1/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
				is($ttxt,'', 'Found cmd '.$tcontext.' '.$test->[0].' arg1 arg2' );
				is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
				($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $test->[0], 'arg1', 'arg2', 'arg3' ]);
				$test1->Verbose( "# 1/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
				is($ttxt,'', 'Found cmd '.$tcontext.' '.$test->[0].' arg1 arg2 arg3' );
				is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
				($tcmd,$preargs,$ttxt) = $test1->FindCommand([ $tcontext, $test->[0], 'arg1', 'context' ]);
				$test1->Verbose( "# 1/ tcmd(".$tcmd->name.") preagrs($preargs) ttxt($ttxt) test(".$test->[0].") context(".$test1->print_context.") \n");
				is($ttxt,'', 'Found cmd '.$tcontext.' '.$test->[0].' arg1 context' );
				is($tcmd->name,$test->[0], 'Name '.$test->[0]." matches" );
			}
		}
	}
}
# Need to test show in universal locations.
my @input = (
[qw( test1 test1.1 tshow ) ],
[qw( test1 test1.2 tshow ) ],
[qw( test1 test1.3 tshow ) ],
[qw( test1 test1.1 test1.1.1 tshow ) ],
[qw( test1 test1.1 test1.1.2 tshow ) ],
[qw( test1 test1.1 test1.1.3 tshow ) ],
[qw( test1 test1.2 test1.1.1 tshow ) ],
[qw( test1 test1.2 test1.1.2 tshow ) ],
[qw( test1 test1.2 test1.1.3 tshow ) ],
);
$test1->context( 'ROOT' );
foreach my $args ( @input )
{
	my @targs = @{$args};
	($tcmd,$preargs,$ttxt) = $test1->FindCommand($args);
	$test1->Verbose( " tcmd(".$tcmd->name.") ttxt($ttxt) context(".$test1->print_context.") preargs dump \n",1,$preargs);
	is($ttxt,'', 'Found cmd '.join(' ', @targs ) );
	is($tcmd->name,'tshow', 'Name is tshow ' );
}

# Need to test exit in universally
@input = (
[qw( test1 exit ) ],
[qw( test1 test1.1 exit ) ],
[qw( test1 test1.2 exit ) ],
[qw( test1 test1.3 exit ) ],
[qw( test1 test1.1 test1.1.1 exit ) ],
);
$test1->context( 'ROOT' );
#$test1->verbose(3);
foreach my $args ( @input )
{
	my @targs = @{$args};
	($tcmd,$preargs,$ttxt) = $test1->FindCommand($args);
	$test1->Verbose( " tcmd(".$tcmd->name.") ttxt($ttxt) context(".$test1->print_context.") preargs dump \n",1,$preargs);
	is($ttxt,'', 'Found cmd '.join(' ', @targs ));
	is($tcmd->name,'exit', 'Name is exit ' );
}
#$test1->verbose(0);

# Need to test all in test_all
@input = (
[qw( test_all one ) ],
[qw( test_all two ) ],
[qw( test_all three ) ],
[qw( test_all one two) ],
[qw( test_all one two three) ],
[qw( test_all three two one) ],
);
$test1->context( 'ROOT' );
#$test1->verbose(3);
foreach my $args ( @input )
{
	my @targs = @{$args};
	($tcmd,$preargs,$ttxt) = $test1->FindCommand($args);
	$test1->Verbose( " tcmd(".$tcmd->name.") ttxt($ttxt) context(".$test1->print_context.") preargs dump \n",1,$preargs);
	is($ttxt,'', 'Found for '.join(' ', @targs ));
	is($tcmd->name,'all', 'Name is all ' );
}
#$test1->verbose(0);

# General Automethod tests

ok($test1->set_test('test'),'$test1->set_test');
is($test1->get_test,'test','$test1->get_test');

ok($test1->set_myarray(['one'] ),'$test1->set_myarray autoload ');
is_deeply($test1->get_myarray,['one'] , '$test1->get_myarray  autoload');

ok($test1->push_myarray('two','three'), '$test1->push_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', ], '$test1->get_myarray ');

ok($test1->push_myarray('four'), '$test1->push_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,4, '$test1->depth_myarray ');

is($test1->shift_myarray(),'one','$test1->shift_myarray ');
is_deeply($test1->get_myarray,[ 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,3, '$test1->depth_myarray ');
is($test1->print_myarray,'two three four', '$test1->print_myarray');

ok($test1->unshift_myarray('one'), '$test1->unshift_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,4, '$test1->depth_myarray ');

# tests for empty arrays and automethods
is($test1->get_myarray2(),undef,'$test1->get_myarray2 autoload ');
is($test1->depth_myarray2,0, '$test1->depth_myarray2 ');
is($test1->print_myarray2,'', '$test1->print_myarray2');
ok($test1->push_myarray2('two','three'), '$test1->push_myarray2 ');
is_deeply($test1->get_myarray2,[ 'two', 'three', ], '$test1->get_myarray2 ');

is($test1->get_myarray3(),undef,'$test1->get_myarray3 autoload ');
is($test1->shift_myarray3(),undef,'$test1->shift_myarray3 ');
is($test1->pop_myarray3(),undef,'$test1->pop_myarray3 ');
ok($test1->unshift_myarray3('two','three'), '$test1->push_myarray3 ');
is_deeply($test1->get_myarray3,[ 'two', 'three', ], '$test1->get_myarray3 ');


$poe_kernel->run;
