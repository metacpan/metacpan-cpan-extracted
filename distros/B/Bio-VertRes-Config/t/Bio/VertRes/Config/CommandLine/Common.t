#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::CommandLine::Common');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my @input_args = qw(-t study -i ZZZ -r ABC -m smalt --smalt_index_k 15 --smalt_index_s 4 --smalt_mapper_r 1 --smalt_mapper_y 0.9 --smalt_mapper_x --smalt_mapper_l pe -c);
push(@input_args, $destination_directory);
ok( my $obj = Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' ), 'initialise commandline common obj');
my $mapping_params = $obj->mapping_parameters;
$mapping_params->{config_base} = 'no need to check';
is_deeply($mapping_params, {
          'protocol' => 'StrandSpecificProtocol',
          'overwrite_existing_config_file' => 0,
          'reference_lookup_file' => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index',
          'database' => 'pathogen_prok_track',
          'database_connect_file' => '/software/pathogen/config/database_connection_details',
          'limits' => {
                        'project' => [
                                       'ZZZ'
                                     ]
                      },
          'mapper_index_params' => '-k 15 -s 4',
          'reference' => 'ABC',
          'additional_mapper_params' => ' -r 1 -y 0.9 -x -l pe',
          'root_base' => '/lustre/scratch108/pathogen/pathpipe',
          'log_base'  => '/nfs/pathnfs05/log',
          'config_base' => 'no need to check'
          
        }, 'Mapping parameters include smalt parameters');

@input_args = qw(-t study -i ZZZ -r ABC -m smalt --smalt_mapper_l xxx -c);
push(@input_args, $destination_directory);
throws_ok(
    sub {
        Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' )->_construct_smalt_additional_mapper_params;
    },
    qr/Invalid type/,
    'Invalid --smalt_mapper_l throws an error'
);

@input_args = qw(-t study -i ZZZ -r ABC -m tophat --tophat_mapper_max_intron 50000 --tophat_mapper_min_intron 70 --tophat_mapper_max_multihit 20 -c);
push(@input_args, $destination_directory);
ok( my $obj_tophat = Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' ), 'initialise commandline common obj');
$mapping_params = $obj_tophat->mapping_parameters;
$mapping_params->{config_base} = 'no need to check';
is_deeply($mapping_params, {
          'protocol' => 'StrandSpecificProtocol',
          'overwrite_existing_config_file' => 0,
          'reference_lookup_file' => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index',
          'database' => 'pathogen_prok_track',
          'database_connect_file' => '/software/pathogen/config/database_connection_details',
          'limits' => {
                        'project' => [
                                       'ZZZ'
                                     ]
                      },
          'reference' => 'ABC',
          'additional_mapper_params' => ' -I 50000 -i 70 -g 20',
          'root_base' => '/lustre/scratch108/pathogen/pathpipe',
          'log_base'  => '/nfs/pathnfs05/log',
          'config_base' => 'no need to check'
          
        }, 'Mapping parameters include tophat parameters');

@input_args = qw(-t study -i ZZZ -r ABC --root_base /path/to/root --log_base /path/to/log -c);
push(@input_args, $destination_directory);
ok( my $user_root = Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' ), 'initialise commandline common obj with user-defined root and log');
$mapping_params = $user_root->mapping_parameters;
$mapping_params->{config_base} = 'no need to check';
is_deeply($mapping_params, {
          'protocol' => 'StrandSpecificProtocol',
          'overwrite_existing_config_file' => 0,
          'reference_lookup_file' => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index',
          'database' => 'pathogen_prok_track',
          'database_connect_file' => '/software/pathogen/config/database_connection_details',
          'limits' => {
                        'project' => [
                                       'ZZZ'
                                     ]
                      },
          'reference' => 'ABC',
          'root_base' => '/path/to/root',
          'log_base'  => '/path/to/log',
          'config_base' => 'no need to check'
          
        }, 'Mapping parameters include user-defined root and log');

@input_args = qw(-t study -i ZZZ -r ABC --db_file /user/database/connect/file -c);
push(@input_args, $destination_directory);
ok( my $user_dbconnect = Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' ), 'initialise commandline common obj with user-defined database connect file');
$mapping_params = $user_dbconnect->mapping_parameters;
$mapping_params->{config_base} = 'no need to check';
is_deeply($mapping_params, {
          'protocol' => 'StrandSpecificProtocol',
          'overwrite_existing_config_file' => 0,
          'reference_lookup_file' => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index',
          'database' => 'pathogen_prok_track',
          'database_connect_file' => '/user/database/connect/file',
          'limits' => {
                        'project' => [
                                       'ZZZ'
                                     ]
                      },
          'reference' => 'ABC',
          'root_base' => '/lustre/scratch108/pathogen/pathpipe',
          'log_base'  => '/nfs/pathnfs05/log',
          'config_base' => 'no need to check'
          
        }, 'Mapping parameters include user-defined database connect file');

@input_args = qw(-t study -i ZZZ -r ABC --db_file -c);
push(@input_args, $destination_directory);
ok( $user_dbconnect = Bio::VertRes::Config::CommandLine::Common->new(args => \@input_args, script_name => 'name_of_script' ), 'initialise commandline common obj with user-defined database connect file set to empty string');
$mapping_params = $user_dbconnect->mapping_parameters;
$mapping_params->{config_base} = 'no need to check';
is_deeply($mapping_params, {
          'protocol' => 'StrandSpecificProtocol',
          'overwrite_existing_config_file' => 0,
          'reference_lookup_file' => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index',
          'database' => 'pathogen_prok_track',
          'database_connect_file' => '',
          'limits' => {
                        'project' => [
                                       'ZZZ'
                                     ]
                      },
          'reference' => 'ABC',
          'root_base' => '/lustre/scratch108/pathogen/pathpipe',
          'log_base'  => '/nfs/pathnfs05/log',
          'config_base' => 'no need to check'
          
        }, 'Mapping parameters include user-defined database connect file set empty string');


done_testing();

