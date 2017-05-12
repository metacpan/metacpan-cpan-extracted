#!perl

use warnings;
use strict;
use Test::More tests => 6;
use Activator::Options;
use Activator::Log qw( :levels );
use Data::Dumper;
use IO::Capture::Stderr;

#Activator::Log->level( 'DEBUG' );

$ENV{ACT_OPT_project} = 'test';

my $proj_dir = "$ENV{PWD}/t/data/test_project";
my $user_yml = "$ENV{USER}.yml";
system( qq( cp $proj_dir/USER.yml $proj_dir/$user_yml));

push @ARGV, qq(--conf_path="$proj_dir");

# loads multiple YAML from ~/.activator.d/test
my $opts = Activator::Options->get_opts( \@ARGV );

ok( $opts->{name} eq 'set by $USER.yml->default', '$USER.yml respected' );
ok( $opts->{project_home} eq 'set by test.yml', '<realm>.yml respected' );
ok( $opts->{company} eq 'set by org.yml', 'org.yml respected' );

$ENV{ACT_OPT__realm2__company} = 'set from env';
$opts = Activator::Options->get_opts( \@ARGV, 'realm2' );
ok( $opts->{name} eq 'set by $USER.yml->realm2', '$USER.yml respected for realm' );
ok( $opts->{project_home} eq 'set by test.yml', "default value set when realm doesn't define key" );
ok( $opts->{company} eq 'set from env', "env override of org.yml respected" );

system( qq( rm -f $proj_dir/$user_yml));
