#!perl

use warnings;
use strict;
use Test::More tests => 7;
use Activator::Options;
use Activator::Log;
use Data::Dumper;
use IO::Capture::Stderr;

#Activator::Log->level( 'DEBUG' );

$ENV{ACT_OPT_project} = 'test';
my $proj_dir = "$ENV{PWD}/t/data/test_project";
my $user_yml = "$ENV{USER}.yml";
system( qq( cp $proj_dir/USER.yml $proj_dir/$user_yml));

@ARGV = (# '--debug', # debug this test: doesn't break tests
	 '--realm=realm1', "--conf_path=$proj_dir", '--foo="set from args"',
	  'bare', '--bar=baz', '--', 'bare2', '--name=activation' );
my ( $opts, $args ) = Activator::Options->get_opts( \@ARGV);

# make sure recognized options stripped
ok( @ARGV == 4, '@ARGV has correct count' );

ok( $ARGV[0] eq 'bare' &&
    $ARGV[1] eq '--' &&
    $ARGV[2] eq 'bare2' &&
    $ARGV[3] eq '--name=activation', '@ARGV is stripped of recognized options' );


ok( $opts->{name} eq 'set by $USER.yml->realm1', "<user>.yml respected" );
ok( $opts->{foo} eq 'set from args', "$opts->{foo} command line args respected" );
ok( $opts->{company} eq 'set by org.yml', 'org.yml respected' );
ok( $opts->{deep}->{deep1} eq 'set by test.yml', 'deep hash maintained');
ok( $opts->{deep}->{deep2} eq 'override by $USER.yml', 'deep hash overrides work');

system( qq( rm -f $proj_dir/$user_yml));
