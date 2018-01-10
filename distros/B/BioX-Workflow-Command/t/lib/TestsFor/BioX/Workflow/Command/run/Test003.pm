package TestsFor::BioX::Workflow::Command::run::Test003;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;
use Storable qw(dclone);

extends 'TestMethod::Base';

sub write_test_file {
    my $test_dir = shift;

    my $fh;
    my $href = {
        global => [
            { sample_rule      => "(Sample_\\w+)_read" },
            { root_dir         => 'data/raw' },
            { indir            => '{$self->root_dir}' },
            { outdir           => 'data/processed' },
            { find_sample_bydir     => 1 },
            { by_sample_outdir => 1 },
        ],
        rules => [
            {
                t3_rule1 => {
                    'local' => [
                        { root_dir => 'data/raw' },
                        { INPUT    => '{$self->root_dir}/some_input_rule1' },
                        { OUTPUT   => ['some_output_rule1'] },
                    ],
                    process =>
'R1: INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT->[0]}',
                },
            },
            {
                t3_rule2 => {
                    'local' => [
                        { INPUT  => '{$self->root_dir}/some_input_rule2' },
                        { OUTPUT => ['some_output_rule2'] },
                    ],
                    process =>
'R2: SAMPLE: {$sample} INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT->[0]}',
                },
            },
            {
                t3_rule3 => {
                    'local' => [ { indir => 'data/raw' }, ],
                    process =>
'R3: SAMPLE: {$sample} INDIR: {$self->indir} INPUT: {$self->INPUT->[0]} outdir: {$self->outdir}',
                },
            },
        ]
    };

    #Write out the config
    open( $fh, ">$test_dir/conf/test1.1.yml" )
      or die print "Couldn't open file! $!";
    my $yaml = Dump $href;
    print $fh $yaml;
    close($fh);

    make_path( $test_dir . "/data/raw/Sample_01_read1" );
    make_path( $test_dir . "/data/raw/Sample_02_read1" );
    make_path( $test_dir . "/data/raw/Sample_01_read2" );
    make_path( $test_dir . "/data/raw/Sample_02_read2" );
}

sub construct_tests {
    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/conf/test1.1.yml";
    my $test = $test_methods->make_test_env($t);
    my $rules = $test->workflow_data->{rules};

    return ( $test, $test_dir, $rules );
}

# test_001 indirectly test the check_indir_outdir function
# TODO - add direct tests

sub test_001 {
    my ( $test, $test_dir, $rules ) = construct_tests;
    my $rule;
    my $text;

    is_deeply(
        $test->global_keys,
        [
            'sample_rule',  'root_dir',
            'indir',        'outdir',
            'find_sample_bydir', 'by_sample_outdir'
        ]
    );

    #############################
    # Test Rule 1
    #############################
    $rule = $rules->[0];
    _init_rule( $test, $rule );

    $test->local_attr->sample( $test->samples->[0] );
    $test->sample( $test->samples->[0] );
    $text = $test->eval_process;

    is_deeply(
        $test->samples,
        [ 'Sample_01', 'Sample_02' ],
        'Samples samples_bydir match'
    );
    is( $text,
            "R1: INDIR: $test_dir/data/raw/Sample_01 "
          . "INPUT: $test_dir/data/raw/some_input_rule1"
          . " outdir: $test_dir/data/processed/Sample_01/t3_rule1 "
          . "OUTPUT: $test_dir/some_output_rule1" );

    #############################
    # Test Rule 2
    #############################
    $rule = $rules->[1];
    _init_rule( $test, $rule );

    $test->local_attr->sample( $test->samples->[0] );
    $test->sample( $test->samples->[0] );
    $text = $test->eval_process;
    is( $text,
            "R2: SAMPLE: Sample_01"
          . " INDIR: $test_dir/data/processed/Sample_01/t3_rule1"
          . " INPUT: $test_dir/data/raw/some_input_rule2"
          . " outdir: $test_dir/data/processed/Sample_01/t3_rule2"
          . " OUTPUT: $test_dir/some_output_rule2" );

    #############################
    # Test Rule 3
    #############################
    $rule = $rules->[2];
    _init_rule( $test, $rule );

    $test->local_attr->sample( $test->samples->[0] );
    $test->sample( $test->samples->[0] );
    $text = $test->eval_process;
    is( $text,
            "R3: SAMPLE: Sample_01 "
          . "INDIR: $test_dir/data/raw "
          . "INPUT: $test_dir/some_output_rule2 "
          . "outdir: $test_dir/data/processed/Sample_01/t3_rule3" );
}

sub test_002 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    #############################
    $test->set_rule_names();
    is_deeply( $test->rule_names, [ 't3_rule1', 't3_rule2', 't3_rule3' ] );

    #############################
    # Test Select Rules
    #############################
    $test->select_rules( [ 't3_rule1', 't3_rule2' ] );
    $test->set_rule_keys('select');
    is_deeply( $test->select_rule_keys, [ 't3_rule1', 't3_rule2' ] );
    $test->select_rules( [] );

    #############################
    # Test Select Before
    #############################
    $test->select_before('t3_rule2');
    $test->set_rule_keys('select');
    is_deeply( $test->select_rule_keys, [ 't3_rule1', 't3_rule2' ] );
    $test->clear_select_before;

    #############################
    # Test Select After
    #############################
    $test->select_after('t3_rule2');
    $test->set_rule_keys('select');
    is_deeply(
        $test->select_rule_keys,
        [ 't3_rule2', 't3_rule3' ],
        'Select After evaluates correctly'
    );
    $test->clear_select_after;

    #############################
    # Test Select Between
    #############################
    $test->select_between( ['t3_rule2-t3_rule3'] );
    $test->set_rule_keys('select');
    is_deeply(
        $test->select_rule_keys,
        [ 't3_rule2', 't3_rule3' ],
        'Select Between evaluates correctly'
    );
    $test->select_between( [] );

    #############################
    # Test Match Rules
    #############################
    $test->select_match( ['t3'] );
    $test->set_rule_keys('select');
    is_deeply(
        $test->select_rule_keys,
        [ 't3_rule1', 't3_rule2', 't3_rule3' ],
        'Match rules evaluates correctly'
    );
    $test->select_match( [] );

    #############################
    # Test Match Rules
    #############################
    $test->select_match( ['rule'] );
    $test->set_rule_keys('select');
    is_deeply(
        $test->select_rule_keys,
        [ 't3_rule1', 't3_rule2', 't3_rule3' ],
        'Match rules evaluates correctly'
    );
    $test->select_match( [] );

    #############################
    # Test Match Rules
    #############################
    $test->select_match( ['t3_rule1'] );
    $test->set_rule_keys('select');
    is_deeply( $test->select_rule_keys, ['t3_rule1'],
        'Match rules evaluates correctly' );
    $test->select_match( [] );

    #############################
    # Writing some meta
    $test->write_workflow_meta('start');

    diag( $test->outfile );
}

sub test_003 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    #############################
    $test->set_rule_names();
    is_deeply( $test->rule_names, [ 't3_rule1', 't3_rule2', 't3_rule3' ] );

    #############################
    # Test Select Rules
    #############################
    $test->omit_rules( [ 't3_rule1', 't3_rule2' ] );
    $test->set_rule_keys('omit');
    is_deeply( $test->omit_rule_keys, [ 't3_rule1', 't3_rule2' ] );
    $test->omit_rules( [] );

    #############################
    # Test Select Before
    #############################
    $test->omit_before('t3_rule2');
    $test->set_rule_keys('omit');
    is_deeply( $test->omit_rule_keys, [ 't3_rule1', 't3_rule2' ] );
    $test->clear_omit_before;

    #############################
    # Test Select After
    #############################
    $test->omit_after('t3_rule2');
    $test->set_rule_keys('omit');
    is_deeply(
        $test->omit_rule_keys,
        [ 't3_rule2', 't3_rule3' ],
        'Select After evaluates correctly'
    );
    $test->clear_omit_after;

    #############################
    # Test Select Between
    #############################
    $test->omit_between( ['t3_rule2-t3_rule3'] );
    $test->set_rule_keys('omit');
    is_deeply(
        $test->omit_rule_keys,
        [ 't3_rule2', 't3_rule3' ],
        'Select Between evaluates correctly'
    );
    $test->omit_between( [] );

    #############################
    # Test Match Rules
    #############################
    $test->omit_match( ['t3'] );
    $test->set_rule_keys('omit');
    is_deeply(
        $test->omit_rule_keys,
        [ 't3_rule1', 't3_rule2', 't3_rule3' ],
        'Match rules evaluates correctly'
    );
    $test->omit_match( [] );

    #############################
    # Test Match Rules
    #############################
    $test->omit_match( ['rule'] );
    $test->set_rule_keys('omit');
    is_deeply(
        $test->omit_rule_keys,
        [ 't3_rule1', 't3_rule2', 't3_rule3' ],
        'Match rules evaluates correctly'
    );
    $test->omit_match( [] );

    #############################
    # Test Match Rules
    #############################
    $test->omit_match( ['t3_rule1'] );
    $test->set_rule_keys('omit');
    is_deeply( $test->omit_rule_keys, ['t3_rule1'],
        'Match rules evaluates correctly' );
    $test->omit_match( [] );

    #############################
    # Writing some meta
    $test->write_workflow_meta('start');

    diag( $test->outfile );
}

sub _init_rule {
    my $test = shift;
    my $rule = shift;

    $test->local_rule($rule);
    $test->process_rule;
    $test->p_rule_name( $test->rule_name );
    $test->p_local_attr( dclone( $test->local_attr ) );
}
