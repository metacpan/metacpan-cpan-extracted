use strict;

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

BEGIN { 
	$ENV{MOD_PERL} = 'CGI-Perl';
	$ENV{GATEWAY_INTERFACE} = 'CGI-Perl';
};

#use Apache::forks qw(stringify); # must be done _before_ Test::More which loads real threads.pm
use forks qw(stringify);
use forks::shared;

use Test::More tests => 2;

SKIP: {
	my $thread1 = threads->new( sub { 1 });
	$thread1->join();
	is( "$thread1", $thread1->tid, "Check that stringify works" );

	my $ptid = threads->tid;
	unless (my $pid = fork) {
		threads->isthread if defined($pid);
		isnt( threads->tid, $ptid, "Check that ->isthread works");
		threads->can('exit') ? threads->exit : exit;
	}
	sleep 3; # make sure fork above has started
} 

1;
