use strict;
use warnings FATAL => 'all';

use utf8;
use Test::More tests => 11;
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Session;
use Carp;
use HTML::Tested::Test::DateTime;

BEGIN { use_ok('T::Test');
	use_ok('T::DBPage');
	$SIG{__WARN__} = sub { diag(Carp::longmess(@_)); };
	# $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); exit; };
}

T::Test->make_aliases(db_page => 'T::DBPage');
is($ENV{SWIT_HAS_APACHE}, 1);

my $t = T::Test->new;
$t->ok_ht_db_page_r(base_url => '/test/db_page/r', ht => {
	HT_SEALED_id => '', val => '',
});

$t->ht_db_page_u(ht => { val => 'дед' });
my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
my $arr = $dbh->selectcol_arrayref("select val from dbp");
{
is_deeply($arr, [ 'дед' ]) or ASTU_Wait;
};

$t->ok_ht_db_page_r(ht => {
	HT_SEALED_id => '1', val => 'дед',
}) or ASTU_Wait;
like($t->mech->content, qr/дед/);

my $c = $arr->[0];
$c =~ s/\W/m/g;
is($c, $arr->[0]);

ASTU_Reset_Table("dbp");

$ENV{SWIT_HAS_APACHE} = 0;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });

$t->ht_db_page_u(ht => { HT_SEALED_id => 1, val => 'дед' });
$t->ok_ht_db_page_r(param => { HT_SEALED_id => 1 }, ht => {
	HT_SEALED_id => '1', val => 'дед',
	, arr => [ { val => 'дед' } ]
	, sel => [ [ 1, 'дед' ], [ 2, 'baba', 1 ] ]
	, dt => HTML::Tested::Test::DateTime->now(10)
});
ASTU_Reset_Table("dbp");

$ENV{SWIT_HAS_APACHE} = 1;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });

$t->ok_ht_db_page_r(base_url => '/test/db_page/r', ht => {
	HT_SEALED_id => '', val => '',
});
$t->ht_db_page_u(ht => { val => 'дед' });
$t->ok_ht_db_page_r(ht => {
	HT_SEALED_id => '1', val => 'дед',
});
