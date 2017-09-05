use v5.14;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new( module_name        => 'API::Drip::Request',
                                  license            => 'perl_5',
                                  dist_author        => q{Dan Wright <Dan@DWright.Org>},
                                  dist_version_from  => 'lib/API/Drip/Request.pm',
                                  release_status     => 'stable',
                                  configure_requires => { 'Module::Build' => '0', },
                                  build_requires     => { 'Test::More' => '0', },
                                  requires           => {
                                                'Carp'                       => 0,
                                                'Data::Printer'              => 0,
                                                'File::HomeDir'              => 0,
                                                'File::Spec'                 => 0,
                                                'HTTP::Request::Common'      => 0,
                                                'JSON'                       => 0,
                                                'LWP::UserAgent'             => 0,
                                                'Params::ValidationCompiler' => 0,
                                                'Readonly'                   => 0,
                                                'Types::Standard'            => 0,
                                                'URI'                        => 0,
                                                'YAML'                       => 0,
                                  },
                                  add_to_cleanup => ['API-Drip-*'],
                                  meta_merge     => {
                                                  'meta-spec' => { version => '2',
                                                                   url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
                                                  },
                                                  resources => { bugtracker => { web => 'https://github.com/dwright/API-Drip/issues', },
                                                                 repository => { url  => 'https://github.com/dwright/API-Drip.git',
                                                                                 web  => 'https://github.com/dwright/API-Drip',
                                                                                 type => 'git',
                                                                 }
                                                  },
                                  }, );

$builder->create_build_script();
