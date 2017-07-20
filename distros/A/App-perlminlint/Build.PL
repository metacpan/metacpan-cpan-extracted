use strict;
use warnings;
use Module::Build::Pluggable 'CPANfile';
use FindBin;

my $gitrepo = 'https://github.com/hkoba/app-perlminlint';

my $builder = Module::Build::Pluggable->new
  (module_name       => 'App::perlminlint'
   , dist_version_from   => 'lib/App/perlminlint.pm'
   , dist_author           => q{KOBAYASHI, Hiroaki <hkoba@cpan.org>},
   , license => 'perl'
   , meta_merge => +{
     resources => {repository  => $gitrepo},
     x_static_install => 1,
   }
   , script_files =>
   +{map(("script/$_" => "bin/$_"), qw/perlminlint/)}
 );

$builder->create_build_script();
