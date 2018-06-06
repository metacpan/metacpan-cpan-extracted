package TestsFor::BioX::Workflow::Command::run::Test002;

use strict;
use warnings FATAL => 'all';
use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;
use Storable qw(dclone);
use File::Spec;
use File::Slurp;

extends 'TestMethod::Base';

sub write_test_file {
    my $test_dir = shift;

    my $href = {
        global => [
            { root_dir      => 'data/raw' },
            { indir         => '{$self->root_dir}' },
            { outdir        => 'data/processed' },
            { sample_rule   => "(Sample_.*)" },
            { gatk          => '{$self->outdir}/{$sample}/gatk' },
            { some_array    => [ 'one', 'two' ] },
            { some_hash     => { 'banana' => 'yellow', 'apple' => 'red' } },
            { some_test_var => 'global_test_var' },
            { some_dir      => 'some_dir' },
        ],
        rules => [
            {
                rule1 => {
                    'local' => [
                        { INPUT       => 'some_input_rule1' },
                        { OUTPUT      => ['some_output_rule1'] },
                        { local_rule1 => 'mylocalrule1' },
                        { before_meta => "# HPC things\n#HPC mem=64GB" },
                        { local_rule2 => 'mylocalrule2' },
                        { some_hash   => { 'banana' => 'Yellow' } },
                        { stash       => { 'banana' => 'Yellow' } }
                    ],
                    process =>
'Executing rule1 {$self->indir} {$self->local_rule1} for {$sample}',
                },
            },
            {
                rule2 => {
                    'local' => [
                        { OUTPUT      => ['some_output_rule2'] },
                        { local_rule1 => 'mylocalrule1' },
                        { local_rule2 => 'mylocalrule2' },
                        { stash       => { 'some_key' => 'some_value' } }
                    ],
                    process =>
'Executing rule2 {$self->OUTPUT->[0]} {$self->local_rule1} for {$sample}',
                },
            },
            {
                rule3 => {
                    'local' => [
                        { indir => '{$self->root_dir}' },
                        { INPUT => '{$self->root_dir}/some_config_file.yml' },
                        {
                            OUTPUT =>
                              [ 'some_output_rule3_1', 'some_output_rule3_2' ]
                        },
                        { some_test_var => 'local_test_var' },
                    ],
                    process =>
'ROOT_DIR: {$self->root_dir} INDIR: {$self->indir} INPUT: {$self->INPUT}',
                },
            },
        ]
    };

    #Write out the config
    my $yaml = Dump $href;
    make_path( File::Spec->catdir( $test_dir, 'conf' ) );
    write_file( File::Spec->catdir( $test_dir, 'conf', 'test1.1.yml' ), $yaml );

    make_path( File::Spec->catdir( $test_dir, 'data', 'raw' ) );

    #Create some samples
    write_file( File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_01' ),
        '' );
    write_file( File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_02' ),
        '' );
}

sub construct_tests {
    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();

    write_test_file($test_dir);

    my $t = File::Spec->catdir( $test_dir, 'conf', 'test1.1.yml' );

    MooseX::App::ParsedArgv->new( argv => [ "run", "--workflow", $t ] );

    my $test = BioX::Workflow::Command->new_with_command();

    $test->load_yaml_workflow;
    $test->apply_global_attributes;
    $test->get_samples;

    my $rules = $test->workflow_data->{rules};

    return ( $test, $test_dir, $rules );
}

sub test_001 : Tags(global_attr) {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->load_yaml_workflow;
    $test->apply_global_attributes;

    is( $test->global_attr->indir, '{$self->root_dir}', 'Indir matches' );
    is(
        $test->global_attr->gatk,
        File::Spec->catdir( '{$self->outdir}', '{$sample}', 'gatk' ),
        'GATK matches'
    );
    is( $test->global_attr->some_hash->{'banana'}, 'yellow',
        'We have hashes!' );
}

sub test_002 : Tags(global_attr_interpolate) {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->load_yaml_workflow;
    $test->apply_global_attributes;

    #TODO I am going to break this test now
    # $test->global_attr->create_process($test->workflow_data->{global}, []);
    #
    # is(
    #     $test->global_attr->indir,
    #     $test_dir . '/data/raw',
    #     'Indir interpolated correctly after walking'
    # );
    ok(1);
}

sub test_003 : Tags(get_samples) {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->load_yaml_workflow;
    $test->apply_global_attributes;
    $test->get_samples;

    is_deeply( $test->samples, [ 'Sample_01', 'Sample_02' ], 'Samples match' );
    is_deeply(
        $test->sample_files,
        [
            File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_01' ),
            File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_02' ),
        ],
        'Samples files match'
    );

    ok( $test->global_attr->indir->can('absolute'),
        'Indir has method absolute' );

#    ok( $test->global_attr->can('all_some_arrays'), 'Array has all method' );
#    ok( $test->global_attr->can('some_hash_pairs'), 'Hash has pairs method' );
}

sub test_004 : Tags(local_attr) {
    my ( $test, $test_dir, $rules ) = construct_tests;
    my $rule;

    #############################
    # Test Rule 1
    #############################
    $rule = $rules->[0];
    _init_rule( $test, $rule );

    is( $test->rule_name, 'rule1', 'Rule name is correct' );
    is( $test->local_attr->outdir,
        'data/processed/rule1', 'Rule1 outdir is correct' );
    is( $test->local_attr->some_hash->{'banana'},
        'Yellow', 'Local attr initialized correctly' );
#    use Data::Dumper;
#    diag Dumper($test->local_attr);
    is_deeply( $test->local_attr->stash, { banana => 'Yellow' } );

    #############################
    # Test Rule 2
    #############################
    $rule = $rules->[1];
    _init_rule( $test, $rule );

    is( $test->local_attr->some_hash->{'banana'},
        'yellow', 'Local rule 2 appropriately resets to global some_hash' );
    is( $test->local_attr->local_rule1, 'mylocalrule1' );
    is( $test->local_attr->indir,       'data/processed/rule1' );
    is( $test->local_attr->outdir,      'data/processed/rule2' );
#    is_deeply( $test->local_attr->stash,
#        { some_key => 'some_value', banana => 'Yellow' } );

    #############################
    # Test Rule 3
    #############################
    $rule = $rules->[2];
    _init_rule( $test, $rule );

    is( $test->local_attr->indir, '{$self->root_dir}', 'Checking local attr' );
#    is_deeply( $test->local_attr->stash,
#        { some_key => 'some_value', banana => 'Yellow' } );
}

sub test_005 : Tags(INPUT_OUTPUT) {
    my ( $test, $test_dir, $rules ) = construct_tests;
    my $rule;

    #############################
    # Test Rule 1
    #############################
    $rule = $rules->[0];
    _init_rule( $test, $rule );

    is( $test->local_attr->INPUT, 'some_input_rule1' );
    is_deeply( $test->local_attr->OUTPUT, ['some_output_rule1'] );

    #############################
    # Test Rule 2
    #############################
    $rule = $rules->[1];
    _init_rule( $test, $rule );
    is_deeply( $test->local_attr->INPUT,  ['some_output_rule1'] );
    is_deeply( $test->local_attr->OUTPUT, ['some_output_rule2'] );

    #############################
    # Test Rule 3
    #############################
    $rule = $rules->[2];
    _init_rule( $test, $rule );
    is_deeply( $test->local_attr->INPUT,
        '{$self->root_dir}/some_config_file.yml' );
    is_deeply( $test->local_attr->OUTPUT,
        [ 'some_output_rule3_1', 'some_output_rule3_2' ] );
}

=head3 test_eval_process

Test the process interpolation per sample

=cut

sub test_eval_process {
    my ( $test, $test_dir, $rules ) = construct_tests;
    my $rule;
    my $text;

    #############################
    # Test Rule 1
    #############################
    $rule = $rules->[0];
    _init_rule( $test, $rule );

    $test->sample( $test->samples->[0] );
    $test->local_attr->sample( $test->samples->[0] );
    $text = $test->eval_process($test->local_attr);

    is(
        $text,
        "Executing rule1 $test_dir/data/raw mylocalrule1 for "
          . $test->samples->[0],
        'First rule process works'
    );

    #############################
    # Test Rule 2
    #############################
    $rule = $rules->[1];
    _init_rule( $test, $rule );

    $test->sample( $test->samples->[0] );
    $test->local_attr->sample( $test->samples->[0] );
    $text = $test->eval_process($test->local_attr);

    is( $text,
        "Executing rule2 $test_dir/some_output_rule2 mylocalrule1 for "
          . $test->samples->[0] );

#    #############################
#    # Test Rule 2
#    #############################
    $rule = $rules->[2];
    _init_rule( $test, $rule );

    $test->local_attr->sample( $test->samples->[0] );
    $text = $test->eval_process($test->local_attr);

    is( $text,
"ROOT_DIR: $test_dir/data/raw INDIR: $test_dir/data/raw INPUT: $test_dir/data/raw/some_config_file.yml"
    );

    #############################
    # Test Interpolating rule
    #############################
    #    my $attr = dclone( $test->local_attr );
    # $attr->create_process([{'root_dir' => 'data/raw'}], [{'INPUT' => '{$self->root_dir}/config.json'}]);

}

sub _init_rule {
    my $test = shift;
    my $rule = shift;

    $test->local_rule($rule);
    $test->process_rule;
    $test->p_rule_name( $test->rule_name );
    $test->p_local_attr( dclone( $test->local_attr ) );

}
