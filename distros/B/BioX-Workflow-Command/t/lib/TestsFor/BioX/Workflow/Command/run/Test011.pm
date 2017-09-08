package TestsFor::BioX::Workflow::Command::run::Test011;

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

=head1 Purpose

Test out how the Types implementation is working out for us

=cut

sub write_test_file {
    my $test_dir = shift;

    my $href = {
        global => [
            { sample_glob       => "data/raw/Sample_*" },
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
                        { root_dir  => 'data/raw' },
                        { outdir    => '{$self->jellyfish_dir}' },
                        { some_glob => '{$self->root_dir}/Sample*' },
                        {
                            INPUT => '{$self->jellyfish_dir}/some_input_rule1'
                        },
                        { OUTPUT => '{$self->jellyfish_dir}/some_input_rule1' },
                        { HPC    => [ { 'deps' => 'some_dep' } ] }
                    ],
                    process =>
'R1: INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT}',
                },
            },
        ]
    };

    ## Setup the directory structure
    make_path( File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_01' ) );
    make_path( File::Spec->catdir( $test_dir, 'data', 'raw', 'Sample_02' ) );
    make_path( File::Spec->catdir( $test_dir, 'data', 'raw', 'NOT_A_SAMPLE' ) );
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

    my $t     = File::Spec->catdir( $test_dir, 'conf', 'test1.1.yml' );
    my $test  = $test_methods->make_test_env( $t, );
    my $rules = $test->workflow_data->{rules};

    return ( $test, $test_dir, $rules );
}

sub test_001 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    is_deeply( $test->samples, [ 'Sample_01', 'Sample_02' ] );
    ok(1);
}

sub test_002 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    my $rule = $rules->[0];
    _init_rule( $test, $rule );

    $test->sample('Sample_01');
    my $attr = $test->walk_attr;

    is_deeply( $attr->some_glob,
        [ File::Spec->catdir($attr->root_dir, 'Sample_01'), File::Spec->catdir($attr->root_dir, 'Sample_02') ] );

    $test->post_process_rules;
}

sub _init_rule {
    my $test = shift;
    my $rule = shift;

    $test->local_rule($rule);
    $test->process_rule;
    $test->p_rule_name( $test->rule_name );
    $test->p_local_attr( dclone( $test->local_attr ) );
}
