#mostly just a quick test of validate_card() as the new name for validate()
# and the :NEW import tag to bring it in

my @test_table=(
        '4111 1111 1111 1111',
        '5454 5454 5454 5454',
);

my @bad_table=(
        '4111 1111 1111 1112',
        '5454 5454 5454 5455',
);

use Test::More tests => 4; #haha no scalar(@test_table) + scalar(@bad_table);
use Business::CreditCard qw( :NEW );

foreach my $card (@test_table) {
  ok( validate_card($card), "validate_card($card)" );
}

foreach my $card (@bad_table) {
  ok( ! validate_card($card), "! validate_card($card)" );
}

1;
