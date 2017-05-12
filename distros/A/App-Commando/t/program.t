use strict;
use warnings;

use Test::Fatal;
use Test::More;

BEGIN { use_ok('App::Commando::Program'); }

my $program = App::Commando::Program->new('foo');
isa_ok $program, 'App::Commando::Program', '$program';

is $program->name, 'foo', 'Program name is correct';

like exception { $program->go([ qw( --bad ) ]) },
    qr/Unknown option: bad/, 'Exception is thrown for an unknown option';

done_testing;
