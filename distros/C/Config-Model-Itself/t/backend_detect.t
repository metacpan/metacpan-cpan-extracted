# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 5 ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use Test::Memory::Cycle;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $ERROR);

my $model = Config::Model->new() ;

$model ->create_config_class
  (
   name => "Master",
   'element'
   => [ 
       'backend' => { type => 'leaf',
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

ok( (scalar grep { $_ eq 'Yaml'} @choices), "Yaml plugin backend was found") ;

# test break when using directly Config::Model repo because get_help
# retrieves info from NAME section which is added at build time by
# Pod::Weaver
my $help = $backend->get_help('Yaml') ;
like($help,qr/provided by L<Config::Model::Backend::Yaml>/,
   "Found Yaml NAME section from pod") ;

$help = $backend->get_help('cds_file') ;
is($help,"file ...", "cds_file help was kept") ;

memory_cycle_ok($model);
