package TestsFor::BioX::Workflow::Command::run::Test005;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;
use File::Slurp;
use File::Spec;
use DateTime;
use DateTime::Format::Strptime;
use Storable qw(dclone);

extends 'TestMethod::Base';

sub write_test_file {
    my $test_dir = shift;

    my $fh;
    my $href = {
        global => [
            { sample_rule      => "Sample_.*" },
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
                        {
                            INPUT =>
                              '{$self->root_dir}/{$sample}/some_input_rule1'
                        },
                        { OUTPUT => ['some_output_rule1'] },
                    ],
                    process =>
'R1: INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT->[0]}',
                },
            },
            {
                t3_rule2 => {
                    'local' => [
                        {
                            INPUT => 'some_ouput_rule1'
                        },
                        { OUTPUT => 'some_output_rule2' },
                    ],
                    process =>
'R2: SAMPLE: {$sample} INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT->[0]}',
                },
            },

            {
                t3_rule3 => {
                    'local' => [
                        { indir => 'data/raw' },
                        {
                            INPUT => 'some_output_rule2'
                        },
                        { OUTPUT => 'some_output_rule3' },
                    ],
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

    make_path( $test_dir . "/data/raw/Sample_01" );
    make_path( $test_dir . "/data/raw/Sample_02" );
    write_file( $test_dir . "/data/raw/Sample_01/" . "some_input_rule1" );
    write_file( $test_dir . "/data/raw/Sample_02/" . "some_input_rule1" );
}

sub construct_tests {
    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t     = "$test_dir/conf/test1.1.yml";
    my $test  = $test_methods->make_test_env($t);
    my $rules = $test->workflow_data->{rules};

    return ( $test, $test_dir, $rules );
}

sub test_001 {
    my ( $test, $test_dir, $rules ) = construct_tests;

    $test->samples( [ 'Sample_01', 'Sample_02' ] );
    $test->set_rule_names;
    $test->filter_rule_keys;

    foreach my $rule ( @{$rules} ) {
        _init_rule( $test, $rule );
    }
    $test->auto_deps(1);
    $test->post_process_rules;

    # diag(Dumper($test->select_rule_keys));
    # diag(Dumper($test->process_obj->{t3_rule1}->{meta}));
    ok(1);
}

sub create_times {
    my $now = DateTime->now( time_zone => 'local' );
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%a %b %e %T %Y',
        time_zone => 'local',
    );

    return $now, $strp;
}

sub _init_rule {
    my $test = shift;
    my $rule = shift;

    $test->local_rule($rule);
    $test->process_rule;
    $test->p_rule_name( $test->rule_name );
    $test->p_local_attr( dclone( $test->local_attr ) );
}
