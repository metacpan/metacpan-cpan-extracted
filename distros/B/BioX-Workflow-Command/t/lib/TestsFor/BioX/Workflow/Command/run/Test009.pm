package TestsFor::BioX::Workflow::Command::run::Test009;

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

extends 'TestMethod::Base';

=head1 Purpose

This tests references -
https://github.com/biosails/BioX-Workflow-Command/issues/19 Refactoring the
'check_sample_exists' function didn't add the samples to the global samples attr

=cut

sub write_test_file {
    my $test_dir = shift;

    my $fh;
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
                pre_assembly_jellyfish_count => {
                    'local' => [
                        { root_dir => 'data/raw' },
                        { outdir   => '{$self->jellyfish_dir}' },
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

    #Write out the config
    open( $fh, ">$test_dir/conf/test1.1.yml" )
      or die print "Couldn't open file! $!";
    my $yaml = Dump $href;
    print $fh $yaml;
    close($fh);

    make_path( $test_dir . "/data/raw/Sample_01" );
    write_file( $test_dir . "/data/raw/Sample_01/" . "some_input_rule1" );
}

sub construct_tests {
    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();

    write_test_file($test_dir);

    my $t = "$test_dir/conf/test1.1.yml";
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

    ok((-d 'data/analysis/Sample_01/jellyfish'));

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
