#!/usr/bin/env perl
# $Id: TCLI.Package.Tail.t 49 2007-04-25 10:32:36Z hacker $

use Test::More tests => 264;
use lib 'blib/lib';
use warnings;
use strict;

use Getopt::Long;

# process options
my ($verbose,$poe_td,$poe_te);
eval { GetOptions (
  		"verbose+"		=> \$verbose,
  		"event_trace+"		=> \$poe_te,
  		"default_trace+"		=> \$poe_td,
)};
if($@) {die "ERROR: $@";}

$verbose = 0 unless defined($verbose);
$poe_td = 0 unless defined($poe_td);
$poe_te = 0 unless defined($poe_te);

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }
sub POE::Component::SimpleLog::DEBUG () { 0 }

use Agent::TCLI::Transport::Test;
use Agent::TCLI::Testee;
use POE;

use Agent::TCLI::Package::Tail;
#use_ok('Agent::TCLI::Package::Tail');


my $test1 = Agent::TCLI::Package::Tail->new({
	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
	});


my $test_master = Agent::TCLI::Transport::Test->new({
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

is($test1->name,'tcli_tail', '$test1->Name ');
my $test_c1 = $test1->commands();
is(ref($test_c1),'HASH', '$test1->Commands is a hash');
my $test_c1_0 = $test_c1->{'tail'};
is($test_c1_0->name,'tail', '$test_c1_0->name get from init args');
is($test_c1_0->usage,'tail file add file /var/log/messages', '$test_c1_0->usage get from init args');
is($test_c1_0->help,'tail a file', '$test_c1_0->help get from init args');
is($test_c1_0->topic,'testing', '$test_c1_0->topic get from init args');
is($test_c1_0->command,'tcli_tail', '$test_c1_0->command get from init args');
is($test_c1_0->handler,'establish_context', '$test_c1_0->handler get from init args');
is($test_c1_0->call_style,'session', '$test_c1_0->call_style get from init args');


my $function;
# In these tests I am mostly testing body, because I am testing the Command.
# for real test scripts using tail, testing with ok should suffice.

$t->is_body( 'tail','Context now: tail', 'Initialize context');
$t->is_body( 'file','Context now: tail file', 'tail file context');
$t->ok( 'add file README ', 'added file');
$t->like_body( 'exit',qr(Context now: tail), "Exit ok");
$t->is_body( 'test','Context now: tail test', 'tail test context');

$t->like_body( 'add like="test one" name="test one"',qr(test.*?added), 'added test like one ');
$t->like_body('', qr(ok.*?test\sone), "passed test one");
$t->like_body( 'exit',qr(Context now: tail), "Exit ok");
$t->ok( 'log "9 test one"');

$function =  "like";
$t->like_body( 'test add like="test pass" name="test pass"',qr(test.*?added), "added test pass $function");
$t->is_code('', 200, "passed test pass $function");
$t->ok( 'log "12 test pass"');

$t->ok( 'clear lines');
$t->is_code('test add like="test fail" name="test fail" max_lines=1 ', 417, "failed test fail $function");
$t->ok( 'log "15 test"');
$test_master->done(31, "finish testing $function" );

# Must clear out the line still in the cache from the prior fail.
$t->ok( 'clear lines');

$function =  "max_lines";
$t->like_body( 'test add like="test pass" name="test pass" max_lines=10',qr(test.*?added), "added test pass $function");
$t->is_code('', 200, "passed test pass $function");
$t->ok( 'log "20 test"');
$t->ok( 'log "21 test"');
$t->ok( 'log "22 test"');
$t->ok( 'log "23 test"');
$t->ok( 'log "24 test"');
$t->ok( 'log "25 test"');
$t->ok( 'log "26 test"');
$t->ok( 'log "27 test"');
$t->ok( 'log "28 test"');
$t->ok( 'log "29 test pass"');

$t->like_body( 'test add like="test fail" name="test fail" max_lines=10',qr(test.*?added), "added test fail $function");
$t->is_code('', 417, "failed test fail $function");
$t->ok( 'log "32 test"');
$t->ok( 'log "33 test"');
$t->ok( 'log "34 test"');
$t->ok( 'log "35 test"');
$t->ok( 'log "36 test"');
$t->ok( 'log "37 test"');
$t->ok( 'log "38 test"');
$t->ok( 'log "39 test"');
$t->ok( 'log "40 test"');
$t->ok( 'log "41 test"');
$test_master->done(31, "finish testing $function" );

# Must clear out the line still in the cache from the prior fail.
$t->ok( 'clear lines');

# match_times
$function =  "match_times";

$t->like_body( 'test add like="test pass" name="test pass" match_times=4 max_lines=4 ',qr(test.*?added),"added test pass $function");
$t->ok('', "passed test pass $function");
$t->ok( 'log "'.$function.' 1 test pass"');
$t->ok( 'log "'.$function.' 2 test pass"');
$t->ok( 'log "'.$function.' 3 test pass"');
$t->ok( 'log "'.$function.' 4 test pass"');
$verbose = 0;
$test_master->done(31, "finish testing $function" );
$verbose = 0;

$function =  "match_times fail";

$t->ok( 'clear lines');

$t->not_ok('test add like="test fail" name="test fail" match_times=5 max_lines=5', "failed test fail $function");
$t->ok( 'log "52 test "');
$t->ok( 'log "53 test fail"');
$t->ok( 'log "54 test fail"');
$t->ok( 'log "55 test fail"');
$t->ok( 'log "56 test fail"');
$test_master->done(31, "finish testing $function" );
#$verbose = 3;

# Must clear out the lines still in the cache from the prior fail.
$t->ok('clear lines');

$function =  "simultaneously";

$t->like_body( 'test add like="test pass" name="test pass"',qr(test.*?added), "added test pass $function");
$t->is_code('', 200, "passed test pass $function");
$t->like_body( 'test add like="test 2pass" name="test 2pass"',qr(test.*?added), "added test 2pass $function");
$t->ok('', "passed test 2pass $function");
$t->ok( 'log "'.$function.' 1 test pass"');		# 1 0
$t->ok( 'log "'.$function.' 2 test 2pass"');	#   1
$test_master->done(31, "finish testing $function" );

#$verbose = 0;
$function =  "simultaneously vice-versa";


$t->ok( 'test add like="test 2pass" name="test 2pass"',"added test 2pass $function");
$t->ok( 'test add like="test pass" name="test pass"', "added test pass $function");
$t->ok( 'log "'.$function.' 1 test 2pass"');	# 1 0
$t->ok( 'log "'.$function.' 2 test pass"');		#   1
$test_master->done(31, "finish testing $function" );
#$verbose = 0;

# fail should not suck up line
$function =  "simultaneously with fail in between";
$t->ok( 'clear lines');
$t->ok( 'test add like="test pass" name="test pass"',"passed test pass $function");
$t->not_ok( 'test add like="test fail" name="test fail" max_lines=1 ',"failed test fail $function");
$t->ok('test add like="test 2pass" name="test 2pass" ', "passed test 2pass $function");
$t->ok( 'log "'.$function.' 1 test pass"');		# 1 0 0
$t->ok( 'log "'.$function.' 2 test 2pass"');	#   1 1
$test_master->done(31, "finish testing $function" );

#$t->ok('show active');
#print $test_master->get_responses('',5);
#$t->ok('show test_queue');
#print $t->get_responses('',5);

#$verbose = 0;
# the first pass should remove 4 lines before the second sees them
$function =  "max_lines simultaneously passing, line cache";
$t->ok( 'log "'.$function.' 1 test 2pass"');	# 1 1
$t->ok( 'log "'.$function.' 2 test pass"');		# 2 1
$t->ok( 'log "'.$function.' 3 test"');			# 3 2
$t->ok( 'log "'.$function.' 4 test"');			# 4 3
$t->ok( 'log "'.$function.' 5 test pass"');		# 5 3
$t->ok( 'log "'.$function.' 6 test pass"');		# 6 3
$t->ok( 'log "'.$function.' 7 test 2pass"');	# 7 4
$t->ok( 'log "'.$function.' 8 test pass"');		# 8 4
$t->ok( 'log "'.$function.' 9 test 2pass"');	#   5

#$t->ok('show line_cache');
#print $t->get_responses('',5);

$t->ok( 'test add like="test pass" name="test pass" match_times=4 max_lines=10 ', "passed test pass $function");
$t->ok( 'test add like="test 2pass" name="test 2pass" match_times=5 max_lines=10  ', "passed test 2pass $function");
$t->ok( 'log "'.$function.' 10 test 2pass"');	#   6
$t->ok( 'log "'.$function.' 11 test"');			#   7
$t->ok( 'log "'.$function.' 12 test"');			#   8
$t->ok( 'log "'.$function.' 13 test"');			#   9
$t->ok( 'log "'.$function.' 14 test 2pass"');	#   !
$test_master->done(31, "finish testing $function" );

#$verbose = 0;

$function =  "max_lines simultaneously one failing";
# failing one should not change pass2
$t->ok('clear lines');
$t->ok( 'test add like="test pass" name="test pass" match_times=4 max_lines=10', "passed test pass $function");
$t->not_ok( 'test add like="test fail" name="test fail" match_times=5 max_lines=10', "failed test fail $function");
$t->ok( 'test add like="test 2pass" name="test 2pass" match_times=5 max_lines=10 ', "passed test 2pass $function");
# numbers are lines seen by each test in order.
$t->ok( 'log "'.$function.' 1 test 2pass"');	# 1 1 1
$t->ok( 'log "'.$function.' 2 test pass"');		# 2 1 1
$t->ok( 'log "'.$function.' 3 test pass"');		# 3 1 1
$t->ok( 'log "'.$function.' 4 test pass"');		# 4 1 1
$t->ok( 'log "'.$function.' 5 test 2pass"');	# 5 2 2
$t->ok( 'log "'.$function.' 6 test 2pass"');	# 6 3 3
$t->ok( 'log "'.$function.' 7 test fail"');		# 7 4 3
$t->ok( 'log "'.$function.' 8 test fail"');		# 8 5 4
$t->ok( 'log "'.$function.' 9 test"');			# 9 6 5
$t->ok( 'log "'.$function.' 10 test pass"');	# ! 7 6
$t->ok( 'log "'.$function.' 11 test fail"');	#   8 6
$t->ok( 'log "'.$function.' 12 test 2pass"');	#   9 7
$t->ok( 'log "'.$function.' 13 test fail"');	#   ! 7
$t->ok( 'log "'.$function.' 14 test"');			#     8
$t->ok( 'log "'.$function.' 15 test"');			#     9
$t->ok( 'log "'.$function.' 16 test 2pass"');	#     !
$test_master->done(31, "finish testing $function" );


$function =  "max_lines simultaneously one failing, line cache";
# failing one should not change pass2
$t->ok('clear lines');
$t->ok( 'log "'.$function.' 1 test 2pass"');	# 1 1 1
$t->ok( 'log "'.$function.' 2 test pass"');		# 2 1 1
$t->ok( 'log "'.$function.' 3 test pass"');		# 3 1 1
$t->ok( 'log "'.$function.' 4 test pass"');		# 4 1 1
$t->ok( 'log "'.$function.' 5 test 2pass"');	# 5 2 2
$t->ok( 'log "'.$function.' 6 test 2pass"');	# 6 3 3
$t->ok( 'log "'.$function.' 7 test fail"');		# 7 4 3
$t->ok( 'log "'.$function.' 8 test fail"');		# 8 5 4
$t->ok( 'log "'.$function.' 9 test"');			# 9 6 5

$t->ok( 'test add like="test pass" name="test pass" match_times=4 max_lines=10 ', "passed test pass $function");
$t->not_ok( 'test add like="test fail" name="test fail" match_times=5 max_lines=10 ', "failed test fail $function");
$t->ok( 'test add like="test 2pass" name="test 2pass" match_times=5 max_lines=10 ', "passed test 2pass $function");
$t->ok( 'log "'.$function.' 10 test pass"');	# ! 7 6
$t->ok( 'log "'.$function.' 11 test fail"');	#   8 6
$t->ok( 'log "'.$function.' 12 test 2pass"');	#   9 7
$t->ok( 'log "'.$function.' 13 test fail"');	#   ! 7
$t->ok( 'log "'.$function.' 14 test"');			#     8
$t->ok( 'log "'.$function.' 15 test"');			#     9
$t->ok( 'log "'.$function.' 16 test 2pass"');	#     !
$test_master->done(31, "finish testing $function" );

$verbose = 0;

$function =  "cache working";
# Must clear out the lines still in the cache from the prior tests
$t->ok('clear lines');
$verbose = 0;
$t->not_ok( 'test add like="test fail" name="test fail" match_times=5 ',"failed test fail $function");
$t->ok( 'log "150 test pass"');
$t->ok( 'log "151 test fail"');
$t->ok( 'log "152 test fail"');
$t->ok( 'log "153 test fail"');
$t->ok( 'log "154 test fail"');
$t->ok( 'log "155 test pass"');
$t->ok( 'log "156 test"');
$t->ok( 'log "157 test"');
$t->ok( 'log "158 test"');
$t->ok( 'log "159 test"');
$t->ok( 'log "160 test"');
$t->ok( 'log "161 test"');
$t->like_body( 'test add like="test pass" name="test pass 1" ',qr(test.*?added), "added test pass 1 $function");
$t->is_code('', 200, "passed test pass $function");
$t->like_body( 'test add like="test pass" name="test pass 2" ',qr(test.*?added), "added test pass 2 $function");
$t->is_code('', 200, "passed test pass $function");
$t->like_body( 'test add like="test fail" name="test fail" ',qr(test.*?added), "added test fail $function");
$t->is_code('', 417, "failed test fail $function");
$t->ok( 'log "168 test"');
$t->ok( 'log "169 test"');
$t->ok( 'log "170 test"');
$t->ok( 'log "171 test"');
$t->ok( 'log "172 test"');
$t->ok( 'log "173 test"');
$t->ok( 'log "174 test"');
$t->ok( 'log "175 test"');
$t->ok( 'log "176 test"');
$t->ok( 'log "177 test"');
$t->ok( 'log "178 test"');
$t->ok( 'log "179 test"');
$test_master->done(31, "finish testing $function" );

# It should not matter that we have extra lines in the queue for this test
# ttl no max_lines
$function =  "ttl, max_lines off";
$t->ok( 'test add like="test pass" name="test pass" max_lines=0 ttl=2',"passed test pass $function");
$t->not_ok( 'test add like="test fail" name="test fail" max_lines=0 ttl=2', "failed test fail $function");
$t->ok( 'log "'.$function.' 1 test"');
$t->ok( 'log "'.$function.' 2 test"');
$t->ok( 'log "'.$function.' 3 test"');
$t->ok( 'log "'.$function.' 4 test"');
$t->ok( 'log "'.$function.' 5 test"');
$t->ok( 'log "'.$function.' 6 test"');
$t->ok( 'log "'.$function.' 7 test"');
$t->ok( 'log "'.$function.' 8 test pass"');
$t->ok( 'log "'.$function.' 9 test"');
$t->ok( 'log "'.$function.' 10 test"');
$t->ok( 'log "'.$function.' 11 test"');
$t->ok( 'log "'.$function.' 12 test"');
$t->ok( 'log "'.$function.' 13 test"');
$t->ok( 'log "'.$function.' 14 test"');
$t->ok( 'log "'.$function.' 15 test"');
$t->ok( 'log "'.$function.' 16 test"');
$t->ok( 'log "'.$function.' 17 test"');
$t->ok( 'log "'.$function.' 18 test"');
$t->ok( 'log "'.$function.' 19 test"');
$t->ok( 'log "'.$function.' 20 test"');
$t->ok( 'log "'.$function.' 21 test"');
$t->ok( 'log "'.$function.' 22 test"');
$t->ok( 'log "'.$function.' 23 test"');
$t->ok( 'log "'.$function.' 24 test"');
$t->ok( 'log "'.$function.' 25 test"');
$t->ok( 'log "'.$function.' 26 test"');
$t->ok( 'log "'.$function.' 27 test"');
$t->ok( 'log "'.$function.' 28 test"');
$t->ok( 'log "'.$function.' 29 test"');
$t->ok( 'log "'.$function.' 30 test"');
$t->ok( 'log "'.$function.' 31 test"');
$t->ok( 'log "'.$function.' 32 test"');
$t->ok( 'log "'.$function.' 33 test"');
$t->ok( 'log "'.$function.' 34 test"');
$t->ok( 'log "'.$function.' 35 test"');
$t->ok( 'log "'.$function.' 36 test"');
$t->ok( 'log "'.$function.' 37 test"');
$t->ok( 'log "'.$function.' 38 test"');
$t->ok( 'log "'.$function.' 39 test"');
$t->ok( 'log "'.$function.' 40 test"');
$t->ok( 'log "'.$function.' 41 test"');
$t->ok( 'log "'.$function.' 42 test"');
$t->ok( 'log "'.$function.' 43 test"');
$t->ok( 'log "'.$function.' 44 test"');
$t->ok( 'log "'.$function.' 45 test"');
$t->ok( 'log "'.$function.' 46 test"');
$t->ok( 'log "'.$function.' 47 test"');
$t->ok( 'log "'.$function.' 48 test"');
$t->ok( 'log "'.$function.' 49 test"');
$t->ok( 'log "'.$function.' 50 test"');
$t->ok( 'log "'.$function.' 51 test"');
$t->ok( 'log "'.$function.' 52 test"');
$t->ok( 'log "'.$function.' 53 test"');
$t->ok( 'log "'.$function.' 54 test"');
$t->ok( 'log "'.$function.' 55 test"');
$t->ok( 'log "'.$function.' 56 test"');
$t->ok( 'log "'.$function.' 57 test"');
$t->ok( 'log "'.$function.' 58 test"');
$t->ok( 'log "'.$function.' 59 test"');
$t->ok( 'log "'.$function.' 60 test"');
$t->ok( 'log "'.$function.' 61 test"');
$t->ok( 'log "'.$function.' 62 test"');
$t->ok( 'log "'.$function.' 63 test"');
$t->ok( 'log "'.$function.' 64 test"');
$t->ok( 'log "'.$function.' 65 test"');
$t->ok( 'log "'.$function.' 66 test"');
$t->ok( 'log "'.$function.' 67 test"');
$t->ok( 'log "'.$function.' 68 test"');
$t->ok( 'log "'.$function.' 69 test"');
$t->ok( 'log "'.$function.' 70 test"');
$t->ok( 'log "'.$function.' 71 test"');
$t->ok( 'log "'.$function.' 72 test"');
$t->ok( 'log "'.$function.' 73 test"');
$t->ok( 'log "'.$function.' 74 test"');
$t->ok( 'log "'.$function.' 75 test"');
$t->ok( 'log "'.$function.' 76 test"');
$t->ok( 'log "'.$function.' 77 test"');
$t->ok( 'log "'.$function.' 78 test"');
$t->ok( 'log "'.$function.' 79 test"');
#$verbose = 0;
$test_master->done(31, "finish testing $function" );


$t->like_body( '/exit',qr(Context now: ), "Exit ok");

$test_master->run;

#$t->ok( 'log "'.$function.' 1 test"');
#$t->ok( 'log "'.$function.' 2 test"');
#$t->ok( 'log "'.$function.' 3 test"');
#$t->ok( 'log "'.$function.' 4 test"');
#$t->ok( 'log "'.$function.' 5 test"');
#$t->ok( 'log "'.$function.' 6 test"');
#$t->ok( 'log "'.$function.' 7 test"');
#$t->ok( 'log "'.$function.' 8 test"');
#$t->ok( 'log "'.$function.' 9 test"');
#$t->ok( 'log "'.$function.' 10 test"');
#$t->ok( 'log "'.$function.' 11 test"');
#$t->ok( 'log "'.$function.' 12 test"');
#$t->ok( 'log "'.$function.' 13 test"');
#$t->ok( 'log "'.$function.' 14 test"');
#$t->ok( 'log "'.$function.' 15 test"');
#$t->ok( 'log "'.$function.' 16 test"');
#$t->ok( 'log "'.$function.' 17 test"');
#$t->ok( 'log "'.$function.' 18 test"');
#$t->ok( 'log "'.$function.' 19 test"');
#$t->ok( 'log "'.$function.' 20 test"');
#$t->ok( 'log "'.$function.' 21 test"');
#$t->ok( 'log "'.$function.' 22 test"');
#$t->ok( 'log "'.$function.' 23 test"');
#$t->ok( 'log "'.$function.' 24 test"');
#$t->ok( 'log "'.$function.' 25 test"');
#$t->ok( 'log "'.$function.' 26 test"');
#$t->ok( 'log "'.$function.' 27 test"');
#$t->ok( 'log "'.$function.' 28 test"');
#$t->ok( 'log "'.$function.' 29 test"');
