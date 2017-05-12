use Test::More tests => 4;

use Bio::Medpost;

$raw_sentence = 'For the purpose p-450 of experimental infection with human hepatitis B virus, 14 chimpanzees (Pan troglodytes) were delivered to the Division of Animal Research, Faculty of Medicine, University of Tokyo, Tokyo.';

ok($r = Bio::Medpost::medpost($raw_sentence));
is($r->[0][1], 'II');
is($r->[2][0], 'purpose');
is($r->[2][1], 'NN');

