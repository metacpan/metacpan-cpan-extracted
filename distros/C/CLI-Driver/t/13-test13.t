#!/usr/bin/env perl

# vim: tabstop=4 expandtab

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use CLI::Driver;
use Test::More;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');
Getopt::Long::Configure('no_auto_abbrev');

###### CONSTANTS ######

###### GLOBALS ######

use vars qw(
  $Driver
);

###### MAIN ######

unshift @INC, 't/lib';

$| = 1;
$Driver = CLI::Driver->new( path => 't/etc', file => 'cli-driver.yml' );

###

#test13:
#  desc: "test multi value array arguments"
#  class:
#    name: CLI::Driver::TestArray
#    attr:
#      required:
#          hard:
#            '@r': attributeArrayReq
#      optional:
#        '@o': attributeArrayOpt
#      flags: 
#  method:
#    name: test13_method1
#    args:
#      required:
#        hard: 
#          '@a': methodArrayReq
#      optional:
#        '@b': methodArrayOpt
#      flags:    

#
# Test multiple arguments passed in
#
push @ARGV, '-r', 'ra1', '-r', 'ra2', '-o', 'oa1', '-o', 'oa2',
            '-a', 'rm1', '-a', 'rm2', '-b', 'om1', '-b', 'om2';          

my $action = $Driver->get_action(name => 'test13');
ok($action);

my @result;
eval { @result = $action->do };
ok(!$@) or BAIL_OUT($@); #pdump $@;

#@result = $action->do;
is_deeply($result[0], ['ra1','ra2'], "Check required attributes array");
is_deeply($result[1], ['oa1','oa2'], "Check optional attributes array");
is_deeply($result[2], ['rm1','rm2'], "Check required method array");
is_deeply($result[3], ['om1','om2'], "Check optional methods array");

###

#
# Test single arguments passed in
#
push @ARGV, '-r', 'ra1', '-o', 'oa1',
            '-a', 'rm1', '-b', 'om1';          

$action = $Driver->get_action(name => 'test13');
ok($action);

@result = ();
eval { @result = $action->do };
ok(!$@) or pdump $@;

#@result = $action->do;
is_deeply($result[0], ['ra1'], "Check required attributes array");
is_deeply($result[1], ['oa1'], "Check optional attributes array");
is_deeply($result[2], ['rm1'], "Check required method array");
is_deeply($result[3], ['om1'], "Check optional methods array");

#
# Test empty optional arguments passed in
#
push @ARGV, '-r', 'ra1',
            '-a', 'rm1';          

$action = $Driver->get_action(name => 'test13');
ok($action);

@result = ();
eval { @result = $action->do };
ok(!$@) or pdump $@;

#@result = $action->do;
is_deeply($result[0], ['ra1'], "Check required attributes array");
is_deeply($result[1], [], "Check optional attributes array");
is_deeply($result[2], ['rm1'], "Check required method array");
is_deeply($result[3], [], "Check optional methods array");

#
# Test missing required argument
#
push @ARGV, '-r', 'ra1';          

$action = $Driver->get_action(name => 'test13');
ok($action);

@result = ();
eval { @result = $action->do };
ok($@, "Got expected error");

#
# Test other missing required argument
#
push @ARGV, '-a', 'rm1';          

$action = $Driver->get_action(name => 'test13');
ok($action);

@result = ();
eval { @result = $action->do };
ok($@, "Got expected error");

done_testing();

###### END MAIN ######
