# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Test::Memory::Cycle;

use warnings;
use strict;

my ($model, $trace) = init_test();

$model ->create_config_class (
   name => "Master",
   'element' => [
       'backend' => {
           type => 'leaf',
           class => 'Config::Model::Itself::BackendDetector' ,
           value_type => 'enum',
           choice => [qw/cds_file perl_file ini_file custom/],

           help => {
               cds_file => "file ...",
               ini_file => "Ini file ...",
               perl_file => "file  perl",
               custom => "Custom format",
           }
       }
   ],
);

ok(1,"test class created") ;

my $root = $model->instance(root_class_name => 'Master') -> config_root ;

my $backend = $root->fetch_element('backend') ;

my @choices = $backend->get_choice ;

ok( (scalar grep { $_ eq 'IniFile'} @choices), "IniFile plugin backend was found") ;

# test break when using directly Config::Model repo because get_help
# retrieves info from NAME section which is added at build time by
# Pod::Weaver
my $help = $backend->get_help('IniFile') ;
like($help,qr/provided by L<Config::Model::Backend::IniFile>/,
   "Found IniFile NAME section from pod") ;

$help = $backend->get_help('cds_file') ;
is($help,"file ...", "cds_file help was kept") ;

memory_cycle_ok($model, "memory cycle");

done_testing;
