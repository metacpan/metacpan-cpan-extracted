# =========================================================================
# Pleae do not run "minil build"
# =========================================================================

use 5.008_001;

use strict;
use warnings;
use utf8;

use Module::Build;
use File::Basename;
use File::Spec;

use FindBin;
use lib "$FindBin::Bin/misc/cpan";

# This custom builder adds 'zsh_fpath' build_element
use MyBuilder;

my $gitrepo = 'https://github.com/hkoba/perl-App-oo_modulino_zsh_completion_helper.git';

my %args = (
    # build_class     => 'MyBuilder',
    module_name     => 'App::oo_modulino_zsh_completion_helper',
    dist_name       => 'App-oo_modulino_zsh_completion_helper',
    dist_author       => q{KOBAYASHI, Hiroaki <hkoba@cpan.org>},
    dist_version_from => 'lib/App/oo_modulino_zsh_completion_helper.pm',

    meta_merge => {resources => {repository  => $gitrepo}},

    MyBuilder->my_cpanfile_specs,

    license              => 'perl_5',
    dynamic_config       => 0,
    allow_pureperl => 0,

    script_files => ['script/oo_modulino_zsh_completion_helper.pl'],
    PL_files => {},

    test_files           => 't/',
    recursive_test_files => 1,

    zsh_fpath_files => {"script/_perl_oo_modulino" => "zsh_fpath/_perl_oo_modulino"},

    # install_path => {zsh_fpath => "/usr/local/share/zsh/site-functions"},
    # zsh_fpath installation path is automatically derived in MyBuilder(I hope)
);

my $builder = MyBuilder->new(%args);
#my $builder = Module::Build->new(%args);

$builder->create_build_script();

