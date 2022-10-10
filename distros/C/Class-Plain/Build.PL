use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;
use XS::Parse::Sublike::Builder;

my @extra_compiler_flags = qw( -Iinclude -Ihax -I.);

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function );
}

my $build = Module::Build->new(
   module_name => 'Class::Plain',
   requires => {
      'perl' => '5.016',
      'XS::Parse::Keyword' => '0.22',
      'XS::Parse::Sublike' => '0.15',
      'Role::Tiny' => '2.002004',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.22',
      'XS::Parse::Sublike::Builder' => '0.15',
   },
   license => 'perl',

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

XS::Parse::Sublike::Builder->extend_module_build( $build );

$build->create_build_script;
