use Test::More;

use Amazon::Sites;

ok(my $sites = Amazon::Sites->new, 'Got an object');
isa_ok($sites, 'Amazon::Sites');

ok(my @sites = $sites->sites, 'Got some sites');
ok(my %sites = $sites->sites_hash, 'sites_hash() gives a hash');
isa_ok($sites{UK}, 'Amazon::Site');
is($sites{UK}->tldn, 'co.uk', 'Correct tldn');
ok(my $site  = $sites->site('UK'), 'site() gives a hash ref');
is($site->tldn, 'co.uk', 'Correct tldn');
is($site->domain, 'amazon.co.uk', 'Correct domain');

my @codes = $sites->codes;
is_deeply(\@codes, [qw(AE AU BE BR CA CN DE EG ES FR IN IT JP MX NL PL SA SE SG TR UK US)]);

done_testing;
