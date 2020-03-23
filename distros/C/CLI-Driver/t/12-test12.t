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

#test11:
#  desc: "test cli-driver-v2 with optionals"
#  class:
#    name: CLI::Driver::Test3
#    attr:
#      required:
#        h: reqattr
#      optional:
#        o: optattr
#      flags: 
#  method:
#    name: test11_method
#    args:
#      required: 
#        a: reqarg
#      optional:
#        b: optarg
#      flags:   
      
push @ARGV, '-h', 'hattr', '-a', 'aarg';

my $action = $Driver->get_action(name => 'test12');
ok($action);

my $result;
eval { $result = $action->do };
ok(!$@) or pdump $@;

###

done_testing();

###### END MAIN ######
