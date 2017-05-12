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

#use Apache::forks::BerkeleyDB qw(stringify); # must be done _before_ Test::More which loads real threads.pm

my ($forks_bdb_installed, $reason);
BEGIN {
	$forks_bdb_installed = 0;
	eval {
		require forks::BerkeleyDB;
		import forks::BerkeleyDB qw(stringify);
		require forks::BerkeleyDB::shared;
		import forks::BerkeleyDB::shared;
	};
	$reason = $@ if $@;
	$forks_bdb_installed = 1 unless $@;
}

use Test::More ($forks_bdb_installed ? (tests => 2) : (skip_all => $reason));

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
