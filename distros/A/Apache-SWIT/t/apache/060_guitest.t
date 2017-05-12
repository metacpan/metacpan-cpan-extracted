use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use Apache::SWIT::Test::Utils;
use Encode;

BEGIN { use_ok('T::Test');
	use_ok('T::DBPage');
}

T::Test->make_aliases(db_page => 'T::DBPage', upload => 'T::Upload');
is($ENV{SWIT_HAS_APACHE}, 1);

my $t;
eval { $t = T::Test->new_guitest; };

SKIP: {
	skip "Unable to load guitest", 18 unless $t;

is($ENV{MOZ_NO_REMOTE}, 1); # or else there are coredumps sometimes
$t->ok_ht_db_page_r(base_url => '/test/db_page/r', ht => {
	val => ''
});

my $cla = $t->mech->get_html_element_by_id("cla");
ok($cla);

$t->mech->x_click($cla, 5, 5);
my $pa = $t->mech->pull_alerts;
like($pa, qr/Clicked/) or ASTU_Wait;
unlike($pa, qr/\w+=\w+/) or ASTU_Wait;

$t->mech->run_js("return form_submit()");
is_deeply($t->mech->console_messages, []);

my $b = 'баба';
$t->content_like(qr/$b/);

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
{
use utf8;
is_deeply($dbh->selectcol_arrayref("select val from dbp"), [ 'баба' ]);
};

ASTU_Reset_Table("dbp");

is_deeply($dbh->selectcol_arrayref("select * from dbp"), []);

$t->ok_ht_db_page_r(base_url => '/test/db_page/r', ht => {
	val => ''
});

$t->ht_db_page_u(ht => { val => 'hoho' });
$t->ok_ht_db_page_r(ht => { val => 'hoho', HT_SEALED_id => 1 });

ASTU_Reset_Table("dbp");

$t->ok_ht_upload_r(base_url => '/test/upload/r', ht => { the_upload => ''
			, HT_SEALED_loid =>  '' });
my @res = $t->ht_upload_u(ht => { the_upload => '/etc/passwd' }
		, button => [ 0 ]);
my ($enc_loid) = ($res[0] =~ /loid=(\w+)/);
isnt($enc_loid, undef) or exit 1;

my $loid = HTML::Tested::Seal->instance->decrypt($enc_loid);
cmp_ok($loid, '>', 0) or exit 1;

my $uri = $t->mech->uri;
$t->ok_follow_link(text => 'Get Plain');
$t->with_or_without_mech_do(2, sub {
	is($t->mech->content, read_file('/etc/passwd'));
	is($t->mech->ct, 'text/plain');
});

$t->mech->get($uri);
my @al1 = ASTU_Read_Access_Log();

$t->ok_follow_link(text => 'Get Plain');
my @al2 = ASTU_Read_Access_Log();
is_deeply(\@al2, \@al1);
};
