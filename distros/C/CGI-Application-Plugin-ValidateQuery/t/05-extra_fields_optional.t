use FindBin '$Bin';
use lib "$Bin/../lib";
use lib "$Bin";

use Test::More 'no_plan';
use Params::Validate ':all';

use TestAppWithoutLogger;

use strict;
use warnings;

use CGI;
my $t_obj = TestAppWithoutLogger->new(
    QUERY => CGI->new(
        'one=1&two=2&three=3&four=4&five=5&five=e'
    ),
);    

# Reality Check tests for correctly set query object.
is($t_obj->query->param('one'), 1,   'Reality check: Query properly set?');
is($t_obj->query->param('two'), 2,   'Reality check: Query properly set?');
is($t_obj->query->param('three'), 3, 'Reality check: Query properly set?');
is($t_obj->query->param('four'), 4,  'Reality check: Query properly set?');
my @value = $t_obj->query->param('five');
my @test = (5,'e');
is(@value, @test, 'Reality check: Query properly set?');

$t_obj->validate_query_config(
    error_mode => 'fail_mode',
);

{
    my %before_q_vars = $t_obj->query->Vars;
    eval {
        my $output = $t_obj->validate_query(
            one => { type=>SCALAR, optional=>0 },
            extra_fields_optional => 1,
        );
    };
    my %after_q_vars = $t_obj->query->Vars;

    is_deeply(\%before_q_vars, \%after_q_vars, 'Query not clobbered?');

    unlike($@, qr/not listed in the validation options/, "Properly ignored rest of query?");
}

{
    my %before_q_vars = $t_obj->query->Vars;
    eval {
        my $output = $t_obj->validate_query(
            one => { type=>SCALAR, optional=>0 },
            allow_extra => 1,
        );
    };
    my %after_q_vars = $t_obj->query->Vars;

    is_deeply(\%before_q_vars, \%after_q_vars, 'Query not clobbered?');

    unlike($@, qr/not listed in the validation options/, "Properly ignored rest of query?");
}
