use strict;
use warnings FATAL => 'all';

use Test::More tests => 20;
use Apache::SWIT::Session;
use Apache::SWIT::Test::Utils;
use Data::Dumper;

BEGIN { use_ok('T::Test');
	use_ok('T::TransFailure');
};

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
ok($dbh->do(<<ENDS));
set client_min_messages to error;
create table trans (a smallint not null check (a > 10) primary key);
create table t2 (b smallint primary key references trans(a)
		initially deferred);
ENDS

$ENV{SWIT_HAS_APACHE} = 0;
T::Test->make_aliases(trans_fail => 'T::TransFailure');

my $t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
eval { $t->ht_trans_fail_u(ht => {}); };
like($@, qr/check constraint/); 
like($@, qr/fail\/u/); 
is_deeply($dbh->selectall_arrayref("select * from trans"), []);

# check that swit_die works on commit
eval { $t->ht_trans_fail_u(ht => { fail_on_commit => 1 }); };
like($@, qr/fail_on_commit/); 

ok($t->ht_trans_fail_u(ht => { rollback => 1 }));
ok(-f 't/templates/2mb.tt');
cmp_ok(-s 't/templates/2mb.tt', '>', 2 * 1024 * 64);

my @ap_pids = ASTU_Apache_Pids();
cmp_ok(@ap_pids, '>=', 2);

my @mem = ASTU_Mem_Stats(@ap_pids);
is(@mem, @ap_pids);

$ENV{SWIT_HAS_APACHE} = 1;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
$t->ok_get('/test/huge');
my $cnt = $t->mech->content;
like($cnt, qr/xxxxxxx/);
like($cnt, qr/world/);

my @pids;
for (1 .. 5) {
	my $pid = fork();
	if ($pid) {
		push @pids, $pid;
	} else {
		$t->mech_get_base('/test/huge');
		exit;
	}
}
waitpid($_, 0) for @pids;

my @ap2 = ASTU_Apache_Pids();
cmp_ok(@ap2, '>=', @ap_pids);
@ap2 = @ap_pids;

my @mem2 = ASTU_Mem_Stats(@ap_pids);
is(@mem2, @ap_pids);

my $priv1 = 0;
$priv1 += $_ for map { $_->[2] } @mem;

my $priv2 = 0;
$priv2 += $_ for map { $_->[2] } @mem2;
cmp_ok(($priv2 - $priv1) / @ap_pids, '<', 5000) or ASTU_Wait(ASTU_Mem_Report());

like(ASTU_Mem_Report(), qr/$priv2/);

chdir('/');
is_deeply([ ASTU_Apache_Pids() ], \@ap_pids);
