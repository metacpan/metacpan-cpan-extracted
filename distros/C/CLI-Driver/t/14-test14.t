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

#test14:
#  desc: "test help"
#  class:
#    name: CLI::Driver::TestArray
#    attr:
#      required:
#          hard:
#            a: '@attrArrayReq'
#      optional:
#        o: 'attrOptional'
#      flags: 
#        attr-flag: attrFlag
#  method:
#    name: test14_method
#    args:
#      required:
#        hard: 
#          r: 'argRequired'
#      optional:
#        o: 'argOptional'
#        n: 'noHelp'
#      flags:
#        method-flag: argFlag
#  help:
#    args:
#      a: "a help"
#      o: "o help"
#      attr-flag: "attr-flag help"
#      r: "r help"
#      method-flag: "method-flag help"
#    examples:
#      - "This is an example"
#      - "This is the second example"    

#
# Test multiple arguments passed in
#
push @ARGV, '-?';          

my $action = $Driver->get_action(name => 'test14');
ok($action);

is( $action->help->get_help('a'), "a help");
is( $action->help->get_help('o'), "o help");
is( $action->help->get_help('attr-flag'), "attr-flag help");
is( $action->help->get_help('r'), "r help");
is( $action->help->get_help('method-flag'), "method-flag help");

ok( $action->help->has_examples );
###

done_testing();

###### END MAIN ######
