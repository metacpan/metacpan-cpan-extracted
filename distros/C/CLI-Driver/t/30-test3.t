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

# test 3 without optional arg
push @ARGV, '-m', 'foo';

my $action = $Driver->get_action(name => 'test3');
ok($action);

$ENV{SOFTARGX} = 'bar';
my $result;
eval { $result = $action->do; };
ok(!$@);
ok(!defined $result);

$ENV{SOFTARGX} = undef;
eval {$result = $action->do;};
ok($@);

push @ARGV, '-s', 'biz';
$result = $action->do;
ok($result);
 
###

done_testing();

###### END MAIN ######
