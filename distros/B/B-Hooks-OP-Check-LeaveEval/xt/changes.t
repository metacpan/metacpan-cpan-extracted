use strict;
use warnings;
use Test::More;
 
BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }
use Test::CPAN::Changes;
use B::Hooks::OP::Check::LeaveEval;

changes_file_ok('CHANGES', {
    version => B::Hooks::OP::Check::LeaveEval->VERSION,
});

done_testing();
