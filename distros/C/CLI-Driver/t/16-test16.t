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
ok($Driver);

###

my $action = $Driver->get_action( name => 'test16');
ok($action);

my $ret;
eval { $ret = $action->do; };
ok( !$@ ) or die $@;

ok($action->is_deprecated);
ok($action->deprecated->is_true);
ok($action->deprecated->replaced_by);

###

done_testing();

###### END MAIN ######
