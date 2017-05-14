#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::RnaSeqExpression');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();


my $obj;
ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::RnaSeqExpression->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'] },
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => $destination_directory,
            protocol              => 'StrandSpecificProtocol'
        )
    ),
    'initialise rna seq expression config'
);
is($obj->toplevel_action, '__VRTrack_RNASeqExpression__');
my $returned_config_hash = $obj->to_hash;
my $prefix               = $returned_config_hash->{prefix};
ok( ( $prefix =~ m/_[\d]{10}_[\d]{1,4}_/ ), 'check prefix pattern is as expected' );
$returned_config_hash->{prefix} = '_checked_elsewhere_';

is_deeply(
    $returned_config_hash,
    {
              'limits' => {
                            'project' => [
                                           'ABC\ study\(\ EFG\ \)'
                                         ]
                          },
              'vrtrack_processed_flags' => {
                                             'stored' => 1,
                                             'mapped' => 1,
                                             'import' => 1
                                           },
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'data' => {
                          'annotation_file' => '/path/to/ABC.gff',
                          'protocol' => 'StrandSpecificProtocol',
                          'ignore_rnaseq_called_status' => 1,
                          'intergenic_regions' => 1,
                          'db' => {
                                    'database' => 'my_database',
                                    'password' => 'some_password',
                                    'user' => 'some_user',
                                    'port' => 1234,
                                    'host' => 'some_hostname'
                                  },
                          'dont_wait' => 0,
                          'mapping_quality' => 1,
                          'sequencing_file_suffix' => 'markdup.bam'
                        },
              'log' => '/path/to/log/my_database/rna_seq_ABC_study_EFG_ABC.log',
              'root' => '/path/to/root/my_database/seq-pipelines',
              'prefix' => '_checked_elsewhere_',
              'module' => 'VertRes::Pipelines::RNASeqExpression'
            },
    'Expected base config file'
);

is(
    $obj->config,
    $destination_directory . '/my_database/rna_seq/rna_seq_ABC_study_EFG_ABC.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );


done_testing();
