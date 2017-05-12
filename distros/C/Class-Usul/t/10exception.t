use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );

use_ok 'Class::Usul::Exception';

Class::Usul::Exception->add_exception( 'A' );

my $line = __LINE__; eval { Class::Usul::Exception->throw
   ( error => 'PracticeKill', class => 'A' ) };
my $e = $EVAL_ERROR;

cmp_ok $e->time, '>', 1, 'Has time attribute';

is $e->ignore->[ 1 ], 'Class::Usul::IPC', 'Ignores class';

is $e->rv, 1, 'Returns value';

like $e, qr{ \A main \[ $line / \d+ \]: \s+ PracticeKill }mx, 'Serializes';

is $e->class, 'A', 'Exception is class A';

is $e->instance_of( 'Unexpected' ), 1,
   'Exception class inherits from Unexpected';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
