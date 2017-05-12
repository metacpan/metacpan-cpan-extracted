#!perl

use warnings;
use strict;
use Test::More tests => 7;
use Activator::Config;
use Activator::Log qw( :levels );
use Test::Exception;

#Activator::Log->level( 'DEBUG' );

my $config;
@ARGV = ();

$ENV{ACT_CONFIG_project} = 'test';

my $proj_dir = "$ENV{PWD}/t/data/test_project";
my $user_yml = "$ENV{USER}.yml";
system( qq( cp $proj_dir/USER.yml $proj_dir/$user_yml));
push @ARGV, qq(--conf_path="$proj_dir");

lives_ok {
    $config = Activator::Config->get_config( \@ARGV );
} 'loads config';

ok( $config->{name} eq 'set by $USER.yml->default', '$USER.yml respected' );
ok( $config->{project_home} eq 'set by test.yml', '<realm>.yml respected' );
ok( $config->{company} eq 'set by org.yml', 'org.yml respected' );

$ENV{ACT_CONFIG__realm2__company} = 'set from env';
$config = Activator::Config->get_config( \@ARGV, 'realm2' );
ok( $config->{name} eq 'set by $USER.yml->realm2', '$USER.yml respected for realm' );
ok( $config->{project_home} eq 'set by test.yml', "default value set when realm doesn't define key" );
ok( $config->{company} eq 'set from env', "env override of org.yml respected" );

system( qq( rm -f $proj_dir/$user_yml));
