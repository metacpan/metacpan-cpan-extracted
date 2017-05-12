use FindBin '$Bin';
use lib "$Bin/../lib";
use lib "$Bin";

use Test::More 'no_plan';
# For testing purposes we need to import all the P::V type functions
# into the current namespace. They are already in the name space of whatever
# cgi::app class using the plugin (and indeed could be accessed here via
# $t_obj->SCALAR and such).
use Params::Validate ':all';

use TestAppWithoutLogger;

use strict;
use warnings;

use CGI;
my $t_obj = TestAppWithoutLogger->new(
    PARAMS => {
        one   => 1,
        two   => 'two',
        three => 123,
        four  => '1da23',
        five  => '',
        six   => [1,2,3]
    }
);

# Reality Check tests for correctly set query object.
is($t_obj->param('one'), 1, 'Reality check: Query properly set?');
is($t_obj->param('two'), 'two', 'Reality check: Query properly set?');
is($t_obj->param('three'), 123, 'Reality check: Query properly set?');
is($t_obj->param('four'), '1da23', 'Reality check: Query properly set?');
is($t_obj->param('five'), '', 'Reality check: Query properly set?');
# XXX
my $value = $t_obj->param('six');
my @test = (1,2,3);
is(@$value, @test, 'Reality check: Query properly set?');

$t_obj->validate_query_config(
    error_mode => 'fail_mode',
);

eval {
    $t_obj->validate_app_params(
        one   => { type=>SCALAR, optional=>0   },
        two   => { type=>SCALAR, optional=>0   },
        three => { type=>SCALAR, optional=>0,
                   regex=>qr/^\d+$/            },
        four  => { type=>SCALAR, optional=>1,
                   regex=>qr/^[\d\w]+$/        },
        five  => { type=>SCALAR, optional=>0   },
        six   => { type=>ARRAYREF, optional=>0 },
    );
};
is($@, '', "Successful validation");

eval {
    my $output = $t_obj->validate_app_params(
        one   => { type=>SCALAR, optional=>0   },
        two   => { type=>SCALAR, optional=>0   },
        three => { type=>SCALAR, optional=>0,
                   regex=>qr/^\d\d$/            }, # error
        four  => { type=>SCALAR, optional=>1,
                   regex=>qr/^[\d\w]+$/        },
        five  => { type=>SCALAR, optional=>0   },
        six   => { type=>ARRAYREF, optional=>0 }
    );
};
like($@, qr/did not pass/, "Unsuccessful validation");
is($t_obj->error_mode(), $t_obj->{__CAP_VALQUERY_ERROR_MODE},
    'Correct error mode on fail?');

$t_obj = TestAppWithoutLogger->new(
    PARAMS => {
        two   => 'two',
        three => 123
    }
);

$t_obj->validate_app_params(
    one   => { type=>SCALAR, default=>410 },
    two   => { type=>SCALAR, optional=>0  },
    three => { type=>SCALAR, optional=>0  },
);

is($t_obj->param('one'), 410, 'Default set?');

