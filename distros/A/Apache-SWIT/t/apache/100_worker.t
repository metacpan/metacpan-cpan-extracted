use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;
use Apache::SWIT::Test::Utils;
use File::Slurp;

BEGIN { use_ok('T::Test');
	use_ok('Apache::SWIT::Session');
	use_ok('T::WorkPage');
};

unlink('/tmp/swit_worker.res');

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
$dbh->do("set client_min_messages to warning");
T::WorkPage::Worker->create_table($dbh);

T::Test->make_aliases(work => 'T::WorkPage');
my $t = T::Test->new;
$t->root_location('/test');
$t->work_r(make_url => 1);
like($t->mech->uri, qr#/test/swit/r#);
like($t->mech->content, qr/hello world/);
is(-f '/tmp/swit_worker.res', undef);

sleep 2;
isnt(-f '/tmp/swit_worker.res', undef);

my $rfstr = read_file('/tmp/swit_worker.res');
like($rfstr, qr/hi/);
like($rfstr, qr/bye/);
unlink('/tmp/swit_worker.res');

$ENV{SWIT_HAS_APACHE} = 0;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });

# in direct work is done synchroniously
$t->work_r(make_url => 1);
isnt(-f '/tmp/swit_worker.res', undef);
$rfstr = read_file('/tmp/swit_worker.res');
like($rfstr, qr/hi/);
like($rfstr, qr/bye/);
unlink('/tmp/swit_worker.res');

# and check that it works for update
$t->work_u(make_url => 1);
isnt(-f '/tmp/swit_worker.res', undef);
$rfstr = read_file('/tmp/swit_worker.res');
like($rfstr, qr/worku/);

unlink('/tmp/swit_worker.res');
