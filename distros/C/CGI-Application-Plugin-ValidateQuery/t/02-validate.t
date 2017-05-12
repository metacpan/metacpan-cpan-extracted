use FindBin '$Bin';
use lib "$Bin/../lib";
use lib "$Bin";

use Test::More 'no_plan';
# For testing purposes we need to import all the P::V type functions
# into the current namespace. They are already in the name space of whatever
# cgi::app class using the plugin (and indeed could be accessed here via
# $t_obj->SCALAR and such). 
use Params::Validate ':all';

use TestAppWithLogger;

use strict;
use warnings;

use CGI;
my $t_obj = TestAppWithLogger->new(
    QUERY => CGI->new(
        'one=1&two=two&three=123&four=1da23&five=&six=1&six=2&six=3'
    ),
);

# Reality Check tests for correctly set query object.
is($t_obj->query->param('one'), 1, 'Reality check: Query properly set?');
is($t_obj->query->param('two'), 'two', 'Reality check: Query properly set?');
is($t_obj->query->param('three'), 123, 'Reality check: Query properly set?');
is($t_obj->query->param('four'), '1da23', 'Reality check: Query properly set?');
is($t_obj->query->param('five'), '', 'Reality check: Query properly set?');
my @value = $t_obj->query->param('six');
my @test = (1,2,3);
is(@value, @test, 'Reality check: Query properly set?');

$t_obj->validate_query_config(
    log_level => 'warning',
    error_mode => 'fail_mode'
);

my %before_q_vars = $t_obj->query->Vars;

my %return_hash;
eval {
    %return_hash = $t_obj->validate_query(
        one   => { type=>SCALAR, optional=>0   },
        two   => { type=>SCALAR, optional=>0   },
        three => { type=>SCALAR, optional=>0,
                   regex=>qr/^\d+$/            },
        four  => { type=>SCALAR, optional=>1,
                   regex=>qr/^[\d\w]+$/        },
        five  => { type=>SCALAR, optional=>0   },
        six   => { type=>ARRAYREF, optional=>0 }
    );
};
is($@, '', "Successful validation");
my %after_q_vars = $t_obj->query->Vars;

is_deeply(\%before_q_vars, \%after_q_vars, 'Query not clobbered?');

# Don't use query->Vars to compare with %return_hash.
# Below we ensure multivalued field shows up as hashref,
# rather than as a null separated string.
my %query_hash;
for my $p ($t_obj->query->param) {
    my @vals = $t_obj->query->param($p);
    $query_hash{$p} = scalar @vals > 1 ? \@vals : $vals[0];
}

is_deeply(\%query_hash, \%return_hash, 'Proper return?');

eval {
    $t_obj->validate_query(
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
    
# testing using default config values
$t_obj->validate_query_config();

eval {
    $t_obj->validate_query(
        one   => { type=>SCALAR, optional=>0   },
        two   => { type=>SCALAR, optional=>0   },
        three => { type=>SCALAR, optional=>0,
                   regex=>qr/^\d+$/            },
        four  => { type=>SCALAR, optional=>1,
                   regex=>qr/^[\d\w]+$/        },
        five  => { type=>SCALAR, optional=>0   },
        six   => { type=>ARRAYREF, optional=>0 }
    );
};
is($@, '', "Successful validation");

eval {
    $t_obj->validate_query(
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

$t_obj = TestAppWithLogger->new(
    QUERY => CGI->new(
        '&two=two&three=123'
    ),
);

$t_obj->validate_query(
    one   => { type=>SCALAR, default=>410 },
    two   => { type=>SCALAR, optional=>0  },
    three => { type=>SCALAR, optional=>0  }
);

is($t_obj->query()->param('one'), 410, 'Default set?');
