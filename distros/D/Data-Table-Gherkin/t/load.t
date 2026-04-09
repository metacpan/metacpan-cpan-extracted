use Test2::V1
  -pragmas,
  qw( is note ok plan );
plan 5;
use Test2::Plugin::DieOnFail;

use Config qw( %Config );

my $main_module;
my $main_module_version;
{
  local @INC  = @INC;
  local @ARGV = qw( DISTNAME NAME VERSION );
  ok scalar( ( my $distname, $main_module, $main_module_version ) = @{ require './Makefile.PL' } ), ## no critic ( RequireBarewordIncludes )
    "Load 'Makefile.PL' as a module";
  is $distname, 'Data-Table-Gherkin', 'Check dist name';
  is $main_module, 'Data::Table::Gherkin', 'Check main module name'
}

ok eval "require $main_module", "Load main module '$main_module'"; ## no critic ( RequireCheckingReturnValueOfEval )
is $main_module_version, $main_module->VERSION, 'Check main module version';
note "Testing $main_module $main_module_version";

note "Perl $] at $^X";
note 'Harness is ',      $ENV{ HARNESS_ACTIVE } ? 'on' : 'off';
note 'Harness ',         $ENV{ HARNESS_VERSION } if $ENV{ HARNESS_VERSION };
note 'Verbose mode is ', exists $ENV{ TEST_VERBOSE } ? 'on' : 'off';
note 'Test2::V1 ',       Test2::V1->VERSION;
note join "\n  ",        'PERL5LIB:', split( /$Config{ path_sep }/, $ENV{ PERL5LIB } ) if exists $ENV{ PERL5LIB };
note join "\n  ",        '@INC:',     @INC;
note join "\n  ", 'PATH:', split( /$Config{ path_sep }/, $ENV{ PATH } )
