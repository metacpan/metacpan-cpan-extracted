use strict;
use warnings;
use utf8;

use Acme::CoC::Types;

use Smart::Args;
use Test2::V0;


subtest 'type: Str' => sub {
    sub str_function {
        args my $param => {isa => 'Str'};
        return 1;
    }

    ok str_function(param => 'test str');
};

subtest 'type: Int' => sub {
    sub int_function {
        args my $param => {isa => 'Int'};
        return 1;
    }

    ok int_function(param => 100);
};

subtest 'type: command' => sub {
    sub command_function {
        args my $param => {isa => 'command'};
        return 1;
    }

    ok command_function(param => 'skill');
    ok command_function(param => 'Skill');
    ok command_function(param => 'cc 50');
    ok command_function(param => 'ccb 35');
    ok command_function(param => '1d100');
    ok command_function(param => '2D6');
};
done_testing;
