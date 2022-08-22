use 5.022;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'res';

WriteMakefile(
    NAME             => 'App::InvestSim',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/App/InvestSim.pm',
    ABSTRACT         => "Simulateur d'investissement locatif",
    LICENSE          => 'mit',
    EXE_FILES        => ['script/investment_simulator'],
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'File::ShareDir::Install' => '0',
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
        'CLDR::Number'          => 0,
        'Data::Dumper'          => 0,
        'Exporter'              => 0,
        'File::HomeDir'         => 0,
        'File::ShareDir'        => 0,
        'File::Spec::Functions' => 0,
        'FindBin'               => 0,
        'Hash::Util'            => 0,
        'List::Util'            => 0,  # Note: Perl 5.22 has v1.41
        'Safe'                  => 0,
        'Tkx'                   => 0,
    },
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        # ignores childs of App::InvestSim, but not App::InvestSim itself
        # (we need at least one indexed package in the distribution to make PAUSE be happy).
        namespace => [ 'App::InvestSim' ],
      },
      keywords => [ qw(finance investment simulator property real-estate loan) ],
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/investment_simulator.git',
          web => 'https://github.com/mkende/investment_simulator',
        },
        bugtracker => {
          web => 'https://github.com/mkende/investment_simulator/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-InvestSim-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
