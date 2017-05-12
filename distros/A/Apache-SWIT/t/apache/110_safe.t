use strict;
use warnings FATAL => 'all';

use Test::More tests => 62;
use Apache::SWIT::Session;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test');
	use_ok('T::Safe');
};

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;

T::Test->root_location('/test');
T::Test->make_aliases(safe => 'T::Safe');
my $t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
$t->ok_ht_safe_r(make_url => 1, ht => { name => '', email => ''
	, sl => [ { o => '1' }, { o => '2' } ] });
like($t->mech->content, qr/html>\n$/) or exit 1;

$t->ht_safe_u(ht => { name => 'foo', email => 'boo' });
$t->ok_ht_safe_r(ht => { name => 'foo', email => 'boo' });
unlike($t->mech->content, qr/Name cannot be empty/);
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 1 ]);

$t->ht_safe_u(ht => { name => '', email => 'fooo' });
$t->ok_ht_safe_r(ht => { name => '', email => 'fooo' });
like($t->mech->content, qr/Name cannot be empty/);
unlike($t->mech->content, qr/Email cannot be empty/);

# if we get different ending from the above it means our headers are screwed.
# We had these problems when using subrequests instead of internal redirects.
like($t->mech->content, qr/html>\n$/) or exit 1;

$t->ht_safe_u(ht => { name => '', email => '' });
$t->ok_ht_safe_r(ht => { name => '', email => '', flak => '' });
like($t->mech->content, qr/Name cannot be empty/);
like($t->mech->content, qr/Email cannot be empty/);

$t->ht_safe_u(ht => { name => 'foo', email => 'ema' });
$t->ok_ht_safe_r(ht => { name => 'foo', email => 'ema' });
like($t->mech->content, qr/This name exists already/) or ASTU_Wait;

$t->ht_safe_u(ht => { name => 'fooa', email => 'ema b' });
$t->ok_ht_safe_r(ht => { name => 'fooa', email => 'ema b' });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 1 ]);
like($t->mech->content, qr/Email is invalid/) or ASTU_Wait;

$t->ht_safe_u(ht => { name => 'hee', email => 'e@example.com', sl => [ {
	o => 10 }, { o => 'a' } ] }, error_ok => 1);
$t->ok_ht_safe_r(ht => { name => 'hee', email => 'e@example.com', sl => [ {
	o => 10 }, { o => 'a' } ], k1 => '', k2 => '' });
like($t->mech->content, qr/o integer/);

is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 1 ]);
$t->mech->reload;

$t->ht_safe_u(ht => { name => 'йойо', email => 'al@example.com'
	, k1 => 12, k2 => 13 });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 2 ]);

unlike($t->mech->content, qr/k1 uq k2/);
unlike($t->mech->content, qr/k2 uq k1/);

like($t->mech->uri, qr/s_id/);
$t->ok_ht_safe_r(ht => { name => 'йойо' }) or ASTU_Wait($t->mech->uri);

$t->ht_safe_u(ht => { email => '', k1 => 12, k2 => 13 });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 2 ]);
$t->ok_ht_safe_r(ht => { name => 'йойо' });

$t->ht_safe_u(ht => { name => 'fook', email => 'j@example.com'
	, k1 => 12, k2 => 13 });
$t->ok_ht_safe_r(ht => { name => 'fook', email => 'j@example.com'
	, k1 => 12, k2 => 13, klak => '', scol => '' });

like($t->mech->content, qr/k1 uq k2/);
like($t->mech->content, qr/k2 uq k1/);

$t->ht_safe_u(ht => { name => 'fook', email => 'j@example.com'
	, k1 => 15, k2 => 13, klak => 10 });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 3 ]);

unlike($t->mech->content, qr/k2 uq k1/);
unlike($t->mech->content, qr/klak error/);
$t->ht_safe_u(ht => { name => 'afook', email => 'sj@example.com'
	, k1 => 16, k2 => 13, klak => 10 });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 3 ]);
like($t->mech->content, qr/k2 uq k1/);
like($t->mech->content, qr/klak error/);
like($t->mech->content, qr/flak error/);
like($t->mech->content, qr/scol error/);

$t->ht_safe_u(ht => { name => 'custodie', email => 'sj@example.com'
	, k1 => 393, k2 => 19, klak => 222 });
is_deeply($dbh->selectcol_arrayref("select count(*) from safet"), [ 3 ]);
like($t->mech->content, qr/custom encode/);

ASTU_Clear_Error_Log();
unlike(ASTU_Read_Error_Log(), qr/\[error\]/);

$t->ht_safe_u(ht => { name => 'die', email => 'bye' });
is($t->mech->status, 500);

my $el = ASTU_Read_Error_Log();
like($el, qr/\[error\]/);
like($el, qr/BUGBUGBUG/);

unlike($el, qr/die1/);
unlike($el, qr/\[error\].*\[error\]/ms);

like($el, qr/In \S+ Update/);

my ($f) = ($el =~ /In (\S+)/);
like($f, qr#^/tmp/#);

my $err = read_file($f);
like($err, qr/die1/);
unlink $f;

ASTU_Clear_Error_Log();
$el = ASTU_Read_Error_Log();
unlike($el, qr/\[error\]/);
like($el, qr/110_safe/);

$ENV{SWIT_HAS_APACHE} = 0;
$t = T::Test->new({ session_class => 'Apache::SWIT::Session' });
is($t->mech, undef);

# check that we die on validation error
eval { $t->ht_safe_u(ht => { name => 'die' }); };
like($@, qr/Found errors/);

my @res = $t->ht_safe_u(ht => { name => 'die' }, error_ok => 1);
like($res[0]->[1], qr/swit_errors.*email/);

my $a = 'abc';
$a =~ /a(.)c/;
ok($1); # to catch die exception we need to have $1 defined

# check that we still die when exception is unknown
eval { $t->ht_safe_u(ht => { name => 'die', email => 'foo' }); };
like($@, qr/BUGBUGBUG/);
like($@, qr/die1/);
like($@, qr/die2/);

$t->ht_safe_u(ht => { name => 'fook', email => 'j@example.com'
	, k1 => 12, k2 => 13 }, error_ok => 1);
$t->ok_ht_safe_r(param => { boob => 1 }, ht => { name => 'fook'
	, email => 'j@example.com', referer => 'hihi.haha'
	, k1 => 12, k2 => 13, klak => '', scol => '' });

eval { $t->ht_safe_u(ht => { name => 'another_t', email => 'ja@example.com'
	, k1 => 81, k2 => 83 }); };
like($@, qr/duplicate key value violates/);
