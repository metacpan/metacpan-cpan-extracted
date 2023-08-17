use Test::More;

use DBIx::SQLstate;

$DBIx::SQLstate::CONST_PREFIX = 'TEST';


is( DBIx::SQLstate->token("HY017"),
    'InvalidUseOfAutomaticallyAllocatedDescriptorHandle',
    "Got the right token for [HY017]"
);

is( DBIx::SQLstate->const("0N000"),
    'TEST_SQL_XML_MAPPING_ERROR',
    "Got the right token for [0N000]"
);

done_testing;

__END__
