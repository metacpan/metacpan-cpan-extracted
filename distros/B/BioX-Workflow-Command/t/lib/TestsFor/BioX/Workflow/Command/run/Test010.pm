package TestsFor::BioX::Workflow::Command::run::Test010;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;
use Data::Walk;
use File::Slurp;
use File::Spec;
use DateTime;
use DateTime::Format::Strptime;
use Storable qw(dclone);
use Text::CSV::Slurp;
use JSON;

extends 'TestMethod::Base';

our $array_of_hashes = [
    { Sample => 'Sample_01', condition => 'wildtype',  time => '12hours' },
    { Sample => 'Sample_02', condition => 'treatment', time => '12hours' },
    { Sample => 'Sample_01', condition => 'wildtype',  time => '12hours' },
];

=head1 Purpose

Test out how the Types implementation is working out for us

=cut

sub write_test_file {
    my $test_dir = shift;

    my $href = {
        global => [
            { sample_rule       => "Sample_.*" },
            { root_dir          => 'data/analysis' },
            { root_dir          => 'data/analysis' },
            { indir             => 'data/raw' },
            { outdir            => 'data/processed' },
            { jellyfish_dir     => 'data/analysis/{$sample}/jellyfish' },
            { find_sample_bydir => 1 },
            { by_sample_outdir  => 1 },
            { HPC               => [ { account => 'gencore' } ] },
        ],
        rules => [
            {
                its_a_rule => {
                    'local' => [
                        { root_dir => 'data/raw' },
                        { outdir   => '{$self->jellyfish_dir}' },
                        {
                            INPUT => '{$self->jellyfish_dir}/some_input_rule1'
                        },
                        { OUTPUT => '{$self->jellyfish_dir}/some_input_rule1' },
                        {
                            my_csv => {
                                file => File::Spec->catdir(
                                    'data', 'some_csv_file.csv'
                                ),
                                options => { separator => ',', },
                                key     => 'Sample',
                            }
                        },
                        {
                            my_json => {
                                file => 'data/some_json_file.json',
                            }
                        },
                        { HPC => [ { 'deps' => 'some_dep' } ] }
                    ],
                    process =>
'R1: INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT}',
                },
            },
        ]
    };

    ## Create a fake csv file
    my $csv = Text::CSV::Slurp->create(
        input       => $array_of_hashes,
        field_order => [ 'Sample', 'condition', 'time' ]
    );
    write_file( File::Spec->catdir( $test_dir, 'data', 'some_csv_file.csv' ),
        $csv );
    write_file( File::Spec->catdir( $test_dir, 'data', 'some_json_file.json' ),
        encode_json($array_of_hashes) );

    ## Setup the directory structure
    make_path( File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_01' ) );
    write_file(
        File::Spec->catdir(
            $test_dir, 'data', 'raw', 'Sample_01', 'some_input_rule1'
        ),
        ''
    );

    ## Write out the config
    my $file = File::Spec->catdir( $test_dir, 'conf', 'test1.1.yml' );
    my $yaml = Dump $href;
    write_file( $file, $yaml );
}

sub construct_tests {
    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();

    write_test_file($test_dir);

    my $t = File::Spec->catdir( $test_dir, 'conf', 'test1.1.yml' );
    my $test = $test_methods->make_test_env( $t, [ '--samples', 'Sample_01' ] );
    my $rules = $test->workflow_data->{rules};

    return ( $test, $test_dir, $rules );
}

sub test_001 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->set_rule_names;
    $test->filter_rule_keys;

    foreach my $rule ( @{$rules} ) {
        _init_rule( $test, $rule );
    }

    $test->post_process_rules;
    is_deeply( $test->samples, ['Sample_01'] );

}

sub test_002 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->set_rule_names;
    $test->filter_rule_keys;

    my $rule = $rules->[0];
    _init_rule( $test, $rule );

    $test->sample('Sample_01');
    my $attr = $test->walk_attr;

    my $json = [
        {
            'time'      => '12hours',
            'condition' => 'wildtype',
            'Sample'    => 'Sample_01'
        },
        {
            'condition' => 'treatment',
            'time'      => '12hours',
            'Sample'    => 'Sample_02'
        },
        {
            'Sample'    => 'Sample_01',
            'condition' => 'wildtype',
            'time'      => '12hours'
        }
    ];
    is_deeply( $attr->my_json, $json, 'JSON Structure Matches' );

    my $csv = {
        'Sample_01' => {
            'condition' => 'wildtype',
            'Sample'    => 'Sample_01',
            'time'      => '12hours'
        },
        'Sample_02' => {
            'condition' => 'treatment',
            'Sample'    => 'Sample_02',
            'time'      => '12hours'
        }
    };
    is_deeply( $attr->my_csv, $csv, 'CSV Structure Matches' );

    $test->post_process_rules;
    is_deeply( $test->samples, ['Sample_01'] );

    ok(1);
}

sub _init_rule {
    my $test = shift;
    my $rule = shift;

    $test->local_rule($rule);
    $test->process_rule;
    $test->p_rule_name( $test->rule_name );
    $test->p_local_attr( dclone( $test->local_attr ) );
}
