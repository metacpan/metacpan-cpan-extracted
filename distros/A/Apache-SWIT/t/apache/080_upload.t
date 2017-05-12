use strict;
use warnings FATAL => 'all';

use Test::More tests => 20;
use Data::Dumper;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok('T::Test');
	use_ok('T::Upload');
	use_ok('T::Empty');
};

T::Test->make_aliases(upload => 'T::Upload', empty => 'T::Empty');

my $td = tempdir('/tmp/lo_test_XXXXXXXX', CLEANUP => 1);
my $t = T::Test->new;
$t->ok_ht_upload_r(base_url => '/test/upload/r', ht => { the_upload => ''
			, HT_SEALED_loid =>  '' });
my @res = $t->ht_upload_u(ht => { the_upload => '/etc/passwd' });
my ($enc_loid) = ($res[0] =~ /loid=(\w+)/);
isnt($enc_loid, undef) or exit 1;

my $loid = HTML::Tested::Seal->instance->decrypt($enc_loid);
cmp_ok($loid, '>', 0) or exit 1;

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
$dbh->begin_work;
$dbh->func($loid, "$td/passwd", 'lo_export')
	or die "# Unable to export $loid!";
$dbh->commit;
is(read_file("$td/passwd"), read_file('/etc/passwd'));

$t->ok_follow_link(text => 'Get Plain');
$t->with_or_without_mech_do(2, sub {
	is($t->mech->content, read_file('/etc/passwd'));
	is($t->mech->ct, 'text/plain');
});

$t->ok_ht_upload_r(base_url => '/test/upload/r', ht => { the_upload => ''
			, HT_SEALED_loid =>  '' });
$t->ht_upload_u(ht => { mime_upload => '/etc/passwd' });
$t->ok_follow_link(text => 'Get Mime');
is($t->mech->content, read_file('/etc/passwd'));
is($t->mech->ct, 'text/plain');

$t->ok_ht_empty_r(base_url => '/test/empty/r', ht => { first => '' });
$t->ht_empty_u(ht => {});
$t->ok_ht_empty_r(ht => { first => '' });

$t->ok_ht_upload_r(base_url => '/test/upload/r', ht => { the_upload => ''
			, HT_SEALED_loid =>  '' });
$t->ht_upload_u(ht => { the_upload => '/etc/passwd', val => 'failv' });
$t->ok_ht_upload_r(ht => { the_upload => '', val => 'failv'
			, HT_SEALED_loid =>  '' });

$t->ok_ht_upload_r(base_url => '/test/upload/r', ht => { the_upload => '' });
$t->ht_upload_u(ht => { the_upload => '/bin/ls' });
$t->ok_ht_upload_r(ht => { the_upload => '', val => 'too_big'
			, HT_SEALED_loid =>  '' });
