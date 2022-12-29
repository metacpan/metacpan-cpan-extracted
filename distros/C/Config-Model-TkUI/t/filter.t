use Test::More ;
use Test::Log::Log4perl;
use Config::Model 2.137;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use YAML::XS qw/LoadFile/;

use Config::Model::Tk::Filter qw/apply_filter/;

use strict;
use warnings;


my ($model, $trace, $args) = init_test('show','filter=s');

note("You can play with the widget if you run this test with '--show' option");

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
    ]
);

use XXX;
my $inst_name = "test001";
my $test_data = LoadFile('t/filter-test.yml');

foreach my $test (@{$test_data->{tests}}) {
    next if ($args->{filter} and $test->{label} !~ /$args->{filter}/);
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
    is_deeply( $actions, $test->{output}, $test->{label});
}

done_testing;
