#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::SnpCalling');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my $obj;
ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::SnpCalling->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'] },
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => $destination_directory
        )
    ),
    'initialise snp calling config'
);
is($obj->toplevel_action, '__VRTrack_SNPs__');
my $returned_config_hash = $obj->to_hash;
my $prefix               = $returned_config_hash->{prefix};
ok( ( $prefix =~ m/_[\d]{10}_[\d]{1,4}_/ ), 'check prefix pattern is as expected' );
$returned_config_hash->{prefix} = '_checked_elsewhere_';

is_deeply(
    $returned_config_hash,
    {
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'data' => {
                          'bsub_opts_long' => '-q normal -M3500000 -R \'select[type==X86_64 && mem>3500] rusage[mem=3500,thouio=1,tmp=16000]\'',
                          'db' => {
                                    'database' => 'my_database',
                                    'password' => 'some_password',
                                    'user' => 'some_user',
                                    'port' => 1234,
                                    'host' => 'some_hostname'
                                  },
                          'split_size_mpileup' => 300000000,
                          'task' => 'pseudo_genome,mpileup,update_db,cleanup',
                          'dont_wait' => 0,
                          'ignore_snp_called_status' => 1,
                          'mpileup_cmd' => 'samtools mpileup -d 1000 -DSug ',
                          'bsub_opts' => '-q normal -M3500000 -R \'select[type==X86_64 && mem>3500] rusage[mem=3500,thouio=1,tmp=16000]\'',
                          'tmp_dir' => '/lustre/scratch108/pathogen/tmp',
                          'fai_ref' => '/path/to/ABC.fa.fai',
                          'fai_chr_regex' => '[\w\.\#]+',
                          'bsub_opts_mpileup' => '-q normal -R \'select[type==X86_64] rusage[thouio=1]\'',
                          'max_jobs' => 100,
                          'bam_suffix' => 'markdup.bam',
                          'fa_ref' => '/path/to/ABC.fa'
                        },
              'max_lanes' => 300,
              'vrtrack_processed_flags' => {
                                             'qc' => 1,
                                             'stored' => 1,
                                             'mapped' => 1,
                                             'import' => 1
                                           },
              'root' => '/path/to/root/my_database/seq-pipelines',
              'log' => '/path/to/log/my_database/snps_ABC_study_EFG_ABC.log',
              'module' => 'VertRes::Pipelines::SNPs',
              'prefix' => '_checked_elsewhere_',
              'limits' => {
                  'project' => ['ABC\ study\(\ EFG\ \)']
              },
            },
    'Expected base config file'
);

is(
    $obj->config,
    $destination_directory . '/my_database/snps/snps_ABC_study_EFG_ABC.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );


ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::SnpCalling->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'] },
            _pseudo_genome        => 0,
            run_after_bam_improvement => 1,
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => '/tmp'
            
        )
    ),
    'initialise snp calling config without pseudo genome step and after bam improvement'
);

is($obj->to_hash->{data}{task}, 'mpileup,update_db,cleanup', 'dont run the pseudo geneome step');
is($obj->to_hash->{vrtrack_processed_flags}{improved}, 1, 'run after bam improvement step');

done_testing();
