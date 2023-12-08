use Test::More ;
use Test::Differences;
use Test::Log::Log4perl;
use Config::Model 2.137;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use YAML::PP qw/LoadFile/;
use Hash::Merge qw/merge/;

use Config::Model::Tk::Filter qw/apply_filter/;

use strict;
use warnings;


my ($model, $trace, $args) = init_test('show','filter=s');

my $wr_root = setup_test_dir;
my $cmu ;

my @element = (
    # Value constructor args are passed in their specific array ref
    cargo => {
        type       => 'leaf',
        value_type => 'string',
    },
);

$model->create_config_class(
    name    => "TwoStrings",
    element => [
        str_a => {
            type       => 'leaf',
            value_type  => 'string',
        },
        str_b => {
            type       => 'leaf',
            value_type  => 'string',
        },
    ]
);

$model->create_config_class(
    name    => "HashAndCheckList",
    element => [
        hash_a => {
            type       => 'hash',
            index_type  => 'string',
            @element
        },
        check_list => {
            type       => 'check_list',
            choice  => [qw/A B C D/],
        },
    ]
);

$model->create_config_class(
    name    => "HashAndDefaultCheckList",
    element => [
        hash_a => {
            type       => 'hash',
            index_type  => 'string',
            @element
        },
        hash_b => {
            type       => 'hash',
            index_type  => 'string',
            @element
        },
        a_string => {
            type => 'leaf',
            value_type => "uniline",
            default => "blah",
        },
        check_list => {
            type       => 'check_list',
            choice  => [qw/A B C D/],
            default_list => [qw/B C/],
        },
    ]
);

$model->create_config_class(
    name    => "Main",
    element => [
        hcl1 => {
            type       => 'node',
            config_class_name => 'HashAndCheckList'
        },
        hcl2 => {
            type       => 'node',
            config_class_name => 'HashAndCheckList'
        },
        hcld1 => {
            type       => 'node',
            config_class_name => 'HashAndDefaultCheckList'
        },
        hnode => {
            type => 'hash',
            index_type => 'string',
            cargo => {
                type => 'node',
                config_class_name => 'TwoStrings',
            }
        }
    ]
);

use XXX;
my $inst_name = "test001";
my $test_data = LoadFile('t/filter-test.yml');

foreach my $test (@{$test_data->{tests}}) {
    next if ($args->{filter} and $test->{label} !~ /$args->{filter}/);

    my $output = merge($test->{output}, $test_data->{default_output});

    my $inst = $model->instance (
        root_class_name => 'Main',
        instance_name => $inst_name++ ,
        root_dir   => $wr_root,
    );

    $inst->config_root->load_data($test->{load});

    ok($inst,"created test instance for ". $test->{label}) ;

    my %args = %{ $test->{input} // {}};
    my $actions = { "__is_kept" => 1 };
    my $ref = \$actions;
    apply_filter(actions => $actions, instance => $inst, %args);
    YYY $actions if $trace;
    ok(! $actions->{__is_kept},"old entries are deleted");
    ok($$ref eq $actions, "ref is kept through when filtering");
    eq_or_diff( $actions, $output, $test->{label});
}

done_testing;
