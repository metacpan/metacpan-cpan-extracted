package TestsFor::BioX::Workflow::Command::run::Test004;

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
                            INPUT =>
                              '{$self->root_dir}/{$sample}/some_input_rule2'
                        },
                        { OUTPUT => 'some_output_rule2' },
                    ],
                    process =>
'R2: SAMPLE: {$sample} INDIR: {$self->indir} INPUT: {$self->INPUT} outdir: {$self->outdir} OUTPUT: {$self->OUTPUT->[0]}',
                },
            },

#             {
#                 t3_rule3 => {
#                     'local' => [ { indir => 'data/raw' }, ],
#                     process =>
# 'R3: SAMPLE: {$sample} INDIR: {$self->indir} INPUT: {$self->INPUT->[0]} outdir: {$self->outdir}',
#                 },
#             },
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

##This whole sub tested timestamps
##Getting rid of timestamps for now
# sub test_001 {
#     my ( $test, $test_dir, $rules ) = construct_tests;
#     my ( $rule, $text, $file, $dt );
#
#     # my ( $now, $strp ) = create_times();
#     # $now = $now->subtract( hours => 1 );
#
#     # $dt   = $strp->format_datetime($now);
#     $file = File::Spec->catfile( $test_dir, 'data', 'raw', 'Sample_01',
#         'some_input_rule1' );
#     # $test->track_files->{$file}->{mtime} = $dt;
#
#     #############################
#     # Test Rule 1 Files
#     # This file has a last modified stamp
#     #############################
#     $rule = $rules->[0];
#
#     # my ( $stdout, $stderr, $exit ) = capture {
#     # $test->use_timestamps(1);
#     $test->samples( [ 'Sample_01', 'Sample_02' ] );
#     $test->set_rule_names;
#     $test->filter_rule_keys;
#     _init_rule( $test, $rule );
#     $text = $test->eval_process;
#     $test->fh->close();
#     # };
#
#     my $expect_seen_modify = {
#         $test_dir . '/data/raw/Sample_01/some_input_rule1' => 1,
#         $test_dir . '/data/raw/Sample_02/some_input_rule1' => 1,
#         $test_dir . '/some_output_rule1'                   => 1,
#     };
#     my $expect_select_rule_keys = ['t3_rule1'];
#     my $expect_graph = {
#         't3_rule1' => {
#             'INPUT' => {
#                 $test_dir.'/data/raw/Sample_02/some_input_rule1'
#                   => 1,
#                 $test_dir.'/data/raw/Sample_01/some_input_rule1'
#                   => 1
#             },
#             'OUTPUT' => {
#                 $test_dir.'/some_output_rule1' => 1
#             }
#         }
#     };
#
#     # is_deeply($expect_graph, $test->rule_deps);
#     is_deeply( $expect_select_rule_keys,  $test->select_rule_keys );
#     # is_deeply( $test->seen_modify->{all}, $expect_seen_modify );
#
#     # is_deeply($test->select_rule_keys, ['t3_rule1']);
#     my $outfile = read_file( $test->outfile );
#
#     my $expect_log = <<EOF;
# ; \\
# biox file_log \\
# \t--exit_code `echo \$\?`  \\
# \t--file $test_dir/data/raw/Sample_02/some_input_rule1 \\
# \t--file $test_dir/some_output_rule1\n
# EOF
#     $text = $test->write_file_log;
#     is( $text, $expect_log );
# }

# sub test_002 {
#     my ( $test, $test_dir, $rules ) = construct_tests;
#     my $rule;
#     my $text;
#
#     #############################
#     # Test Rule 1 Files
#     #############################
#     my ( $now, $strp ) = create_times();
#     my $dt   = $strp->format_datetime($now);
#     my $file = File::Spec->catfile( $test_dir, 'data', 'raw', 'Sample_02',
#         'some_input_rule1' );
#
#     diag( 'testing for file ' . $file );
#
#     $test->use_timestamps(1);
#     $test->track_files->{$file}->{mtime} = $dt;
#
#     #############################
#     # Test Rule 1 Files
#     # This file has a last modified stamp
#     #############################
#     $rule = $rules->[0];
#
#     my ( $stdout, $stderr, $exit ) = capture {
#         $test->set_rule_names;
#         $test->filter_rule_keys;
#         _init_rule( $test, $rule );
#     };
#
#     ( $stdout, $stderr, $exit ) = capture {
#         $test->sample( $test->samples->[1] );
#         $test->local_attr->sample( $test->samples->[1] );
#         $text = $test->eval_process;
#         $test->fh->close;
#     };
#
#     is_deeply($test->select_rule_keys, ['t3_rule1']);
#     diag(Dumper($test->select_rule_keys));
#     # like( $stderr, qr/No modified files were found/, );
#     ok(1);
# }

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
