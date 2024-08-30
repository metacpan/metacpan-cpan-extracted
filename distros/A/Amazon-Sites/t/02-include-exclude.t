use strict;
use warnings;

use Test::More import => [qw( done_testing is_deeply ok )];
use Test::Exception;

use Amazon::Sites;

throws_ok { Amazon::Sites->new( include => [ 'UK' ], exclude => [ 'US' ]) }
  qr[You can't specify both include and exclude],
  'Can\'t specify both include and exclude';

my $sites = Amazon::Sites->new(exclude => [ 'US' ]);
my $az_us = $sites->site('US');
ok(! $az_us, 'US is excluded');
my $az_uk = $sites->site('UK');
ok($az_uk, 'UK is included');
is_deeply([ $sites->codes ],
  [ qw(AE AU BE BR CA CN DE EG ES FR IN IT JP MX NL PL SA SE SG TR UK) ],
  'Correct codes are included');

$sites = Amazon::Sites->new(include => [ 'UK' ]);
$az_us = $sites->site('US');
ok(! $az_us, 'US is excluded');
$az_uk = $sites->site('UK');
ok($az_uk, 'UK is included');
is_deeply([ $sites->codes ],
  [ qw(UK) ],
  'Correct code is included');

done_testing;