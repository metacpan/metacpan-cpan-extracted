# -*- perl -*-

# t/01_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok('Acme::Dice'); }

my $dice_roll = eval { roll_dice(); };
ok( !defined($dice_roll), 'roll_dice not imported by default' );

my $craps_roll = eval { roll_craps(); };
ok( !defined($craps_roll), 'roll_craps not imported by default' );

done_testing();

exit;
