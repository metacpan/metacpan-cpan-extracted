# -*- cperl -*-

use ExtUtils::testlib;
use Data::Dumper;
use Storable qw/dclone/;
use Test::More;
use Test::Differences;
use Test::Memory::Cycle;
use Test::Log::Log4perl;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";
use boolean;

my $dump_model_file = 'dump_load_model.pl';

Test::Log::Log4perl->ignore_priority("info");

my ($model, $trace) = init_test();

my $inst = $model->instance(
    root_class_name => 'Master',
    model_file      => $dump_model_file,
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

my $perl_data;
my $cml_dump;

sub get_expected_dump {
    return {
        'olist'         => [ { 'X' => 'Av' }, { 'X' => 'Bv' } ],
        'my_check_list' => ['toto'],
        'tree_macro'    => 'mXY',
        'ordered_hash'   => [ 'z', '1', 'y', '2', 'x', '3' ],
        'another_string' => 'toto tata',
        bool_list => [ false, true ],
        'listb'          => ['bb'],
        'my_reference'   => 'titi',
        'hash_a'         => {
            'toto' => 'toto_value',
            'titi' => 'titi_value',
        },
        'std_id' => {
            'ab' => { 'X' => 'Bv' },
            'bc' => { 'X' => 'Av' }
        },
        'lista' => [qw/a b c d g/],
        'warp'  => {
            'warp2' => {
                'aa2' => 'foo bar'
            }
        },
    }
}

# add default information provided by model to check full dump
sub get_expected_dump_with_default_values {
    my $expect = get_expected_dump();
    $expect->{string_with_def} = 'yada yada';
    $expect->{int_v}           = 10;
    $expect->{olist}[0]{DX}    = 'Dv';
    $expect->{olist}[1]{DX}    = 'Dv';
    $expect->{std_id}{ab}{DX}  = 'Dv';
    $expect->{std_id}{bc}{DX}  = 'Dv';
    $expect->{a_uniline_with_default} = 'yada yada';
    return $expect;
}

subtest "dump ordered_hash of value" => sub {
    {
        my $step = '
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
';

        $step =~ s/\n/ /g;

        ok( $root->load( step => $step ), "set up ordered_hash data" );
    }

    {
        my $data = $root->dump_as_data(mode => 'custom');
        my $expect = { ordered_hash => [ 'z', '1', 'y', '2', 'x', '3' ]};
        eq_or_diff( $data, $expect, "check plain perl dump" );
    }

    {
        my $data = $root->dump_as_data(
            mode => 'custom',
            ordered_hash_as_list_of_hashes => 1,
        );

        my $expect = {
            ordered_hash =>  [
                { name => 'z', value => '1'},
                { name => 'y', value => '2'},
                { name => 'x', value => '3'},
            ]
        };
        eq_or_diff( $data, $expect, "check list_of_hash dump indexed by name" );
    }

    {
        my $data = $root->dump_as_data(
            mode => 'custom',
            ordered_hash_as_list_of_hashes => 1,
            ordered_hash_key_name => "key"
        );

        my $expect = {
            ordered_hash => [
                { key => 'z', value => '1'},
                { key => 'y', value => '2'},
                { key => 'x', value => '3'},
            ]
        };
        eq_or_diff( $data, $expect, "check list_of_hash data dump indexed by key" );
    }
    $root->load("ordered_hash:.clear");
};

subtest "dump ordered_hash_of_node" => sub {
    {
        my $step = '
ordered_hash_of_node:z aa2=foo_x -
ordered_hash_of_node:y aa2=foo_y ab2=bar_y -
';

        $step =~ s/\n/ /g;

        ok( $root->load( step => $step ), "set up ordered_hash_of_node data in tree" );
    }


    {
        my $data_str = $root->dump_as_data(
            mode => 'custom',
            ordered_hash_as_list_of_hashes => 1,
            ordered_hash_key_name => "key"
        );

        my $expect = {
            ordered_hash_of_node => [
                {
                    aa2 => 'foo_x',
                    key => 'z'
                },
                {
                    aa2 => 'foo_y',
                    ab2 => 'bar_y',
                    key => 'y'
                }
            ]
        };

        eq_or_diff( $data_str, $expect, "check list_of_hash dump of ordered hash of node" );
    }

    $root->load("ordered_hash_of_node:.clear");
};

subtest "add fixture" => sub {
    my $step = '
std_id:ab X=Bv -
std_id:bc X=Av -
bool_list=0,1
tree_macro=mXY
another_string="toto tata"
hash_a:toto=toto_value
hash_a:titi=titi_value
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_check_list=toto my_reference="titi"
warp warp2 aa2="foo bar"
';

    $step =~ s/\n/ /g;

    note("steps are $step") if $trace;
    ok( $root->load( step => $step ), "set up data in tree" );
};

subtest "perl dump" => sub {

    # load some values with undef
    $root->fetch_element('hash_a')->fetch_with_id('undef_val');
    $root->fetch_element('lista')->fetch_with_id(6)->store('g');

    $root->load_data( { listb => 'bb' } );
    ok( 1, "loaded single array element as listb => 'bb'" );

    $perl_data = $root->dump_as_data( full_dump => 0 );

    print Dumper $perl_data if $trace;

    is_deeply($perl_data, get_expected_dump(), "check data dump" );
};

subtest "check default mapping of boolean value type" => sub {
    my $data = $root->dump_as_data( full_dump => 0 );
    for (0,1) {
        is($data->{bool_list}[$_], $_, "Perl data value of bool_list:$_ ");
        is(ref $data->{bool_list}[$_], '', "Perl data of bool_list:$_ is not a ref");
    }
};

subtest "check mapping of boolean value type to Perl boolean" => sub {
    my $data = $root->dump_as_data( full_dump => 0, to_boolean => sub { boolean(shift) } );
    for (0,1) {
        isa_ok($data->{bool_list}[$_], "boolean", "Perl data of bool_list:$_ ");
    };
};

subtest "check mapping of boolean value type to Perl boolean" => sub {
    plan skip_all => "JSON PP boolean behavior not yet checked";
    my $data = $root->dump_as_data( full_dump => 0, to_boolean => 'JSON::PP::Boolean' );
    for (0,1) {
        isa_ok($data->{bool_list}[$_], "JSON::PP::Boolean", "Perl data of bool_list:$_ ");
    }
};

subtest "dump in user mode" =>  sub {
    my $full_data = $root->dump_as_data(mode => 'user');
    my $expect = get_expected_dump_with_default_values();
    is_deeply( $full_data, $expect, "check full data dump" );
};


subtest "test load and dump data" => sub {
    my $dump1 = $root->dump_tree;

    my $inst2 = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'test2'
    );
    ok( $inst2, "created 2nd dummy instance" );

    my $root2 = $inst2->config_root;
    ok( $root2, "Config root2  created" );

    $root2->load_data($perl_data);

    ok( 1, "loaded perl data structure in 2nd instance" );

    my $dump2 = $root2->dump_tree;

    is( $dump2, $dump1, "check that dump of 2nd tree is identical to dump of the first tree" );
};


subtest "try partial dumps" => sub {
    my $expect = get_expected_dump_with_default_values();
    my @tries = (
        [ 'olist'           => $expect->{olist} ],
        [ 'olist:0'         => $expect->{olist}[0] ],
        [ 'olist:0 DX'      => $expect->{olist}[0]{DX} ],
        [ 'string_with_def' => $expect->{string_with_def} ],
        [ 'ordered_hash'    => $expect->{ordered_hash} ],
        [ 'hash_a'          => $expect->{hash_a} ],
        [ 'std_id:ab'       => $expect->{std_id}{ab} ],
        [ 'my_check_list'   => $expect->{my_check_list} ],
    );

    foreach my $test (@tries) {
        my ( $path, $expect ) = @$test;
        my $obj  = $root->grab($path);
        my $dump = $obj->dump_as_data(mode => 'user');
        is_deeply( $dump, $expect, "check data dump for '$path'" );
    }
};

subtest "test ordered_hash warnings" => sub {
    my $tw = Test::Log::Log4perl->get_logger("Tree.Element.Id.Hash");
    Test::Log::Log4perl->start(ignore_priority => "info");
    $tw->warn(qr/order is not defined/);

    # load 2 items in ordered_hash without __order produces a warning";
    $root->load_data( { ordered_hash => { y => '2', 'x' => '3' }});

    # load one item in ordered_hash without __order produce no warning";
    $root->load_data( { ordered_hash => { 'x' => '3' }});
    Test::Log::Log4perl->end("warnings without __order");
};

subtest "ordered hash load with hash ref instead of array ref" => sub {
    my $expect = get_expected_dump_with_default_values();
    my $inst3 = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'test3'
    );
    ok( $inst, "created 3rd dummy instance" );
    my $root3 = $inst3->config_root;
    my $pdata = dclone($perl_data);
    $pdata->{ordered_hash} = { @{ $expect->{ordered_hash} }, __order => [qw/y x z/] };
    $root3->load_data($pdata);

    my @tries = (
        [ 'olist'           => $expect->{olist} ],
        [ 'olist:0'         => $expect->{olist}[0] ],
        [ 'olist:0 DX'      => $expect->{olist}[0]{DX} ],
        [ 'string_with_def' => $expect->{string_with_def} ],
        [ 'ordered_hash'    => [qw/y 2 x 3 z 1/] ],
        [ 'hash_a'          => $expect->{hash_a} ],
        [ 'std_id:ab'       => $expect->{std_id}{ab} ],
        [ 'my_check_list'   => $expect->{my_check_list} ],
    );

    foreach my $test (@tries) {
        my ( $path, $expect ) = @$test;
        my $obj  = $root3->grab($path);
        my $dump = $obj->dump_as_data(mode => 'user');
        is_deeply( $dump, $expect, "check data dump for '$path'" );
    }
};

memory_cycle_ok($model, "memory cycles");

done_testing;
