######################################################################
# Build.PL for Data::Checker
######################################################################

use strict;
use warnings;
use 5.008;
use Module::Build 0.21;

my %module_prereq = (
   'perl'                     => '5.008',
   'Module::Loaded'           => '0',
   'Net::DNS'                 => '0',
   'Net::Ping'                => '0',
   'Net::Ping::External'      => '0',
   'NetAddr::IP'              => '4.073',
   'NetAddr::IP::Lite'        => '0',
   'Parallel::ForkManager'    => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'Test::Inter'              => '0',
   'Test::More'               => '0',
);

my %config_prereq = (
   'Module::Build'            => '0.21',
);

my %build_prereq = %config_prereq;
if ($Module::Build::VERSION < 0.4004) {
   %build_prereq = (%config_prereq,%test_prereq);
}

my $class = Module::Build->subclass(
   class  => "Module::Build::Custom",
   code   => q { sub ACTION_html { my $self = shift ; $self->SUPER::ACTION_html ( @_ ) if ( $ENV{ MAKE_HTML } ) ; } }
);

my $build = $class->new(
      module_name        => "Data::Checker",
      dist_version       => "1.07",
      dist_abstract      => "a framework for checking data validity",
      license            => "perl",
      dist_author        => "Sullivan Beck <sbeck\@cpan.org>",

      requires           => \%module_prereq,
      ($Module::Build::VERSION >= 0.4004
       ? (test_requires  => \%test_prereq)
       : ()),
      ($Module::Build::VERSION >= 0.30
       ? (configure_requires  => \%config_prereq)
       : ()),
      build_requires     => \%build_prereq,
      recommends         => \%script_prereq,
      sign               => 1,

      ($Module::Build::VERSION >= 0.28
       ? (meta_merge => {
             resources => {
                repository => "https://github.com/SBECK-github/Data-Checker",
             }
          })
       : ()),
);

$build->create_build_script;
