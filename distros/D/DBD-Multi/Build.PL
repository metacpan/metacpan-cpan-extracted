use v5.8;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new( module_name        => 'DBD::Multi',
                                  license            => 'perl_5',
                                  dist_author        => q{Dan Wright <Dan@DWright.Org>},
                                  dist_version_from  => 'lib/DBD/Multi.pm',
                                  dist_abstract      => 'Failover and Load Balancing of DBI Handles',
                                  release_status     => 'stable',
                                  configure_requires => { 'Module::Build' => '0', },
                                  build_requires     => {
                                                      'Test::TCP'           => '2.19',  # Would not work for me with 2.13
                                                      'Test::More'          => '0',
                                                      'Test::Pod'           => '1.14',
                                                      'Test::Exception'     => '0.21',
                                                      'DBD::SQLite'         => '1.09',
                                                      'Pod::Simple'         => '0',
                                  },
                                  requires => { 'perl'                  => '5.008',
                                                'Class::Accessor::Fast' => '0.19',
                                                'Sys::SigAction'        => '0.10',
                                                'List::Util'            => '1.18',
                                                'DBI'                   => '0',
                                  },
                                  add_to_cleanup => ['DBD-Multi-*'],
                                  meta_merge     => {
                                                  'meta-spec' => { version => '2',
                                                                   url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
                                                  },
                                                  resources => { bugtracker => { web => 'https://github.com/dwright/DBD-Multi/issues', },
                                                                 repository => { url  => 'https://github.com/dwright/DBD-Multi.git',
                                                                                 web  => 'https://github.com/dwright/DBD-Multi',
                                                                                 type => 'git',
                                                                 }
                                                  },
                                  }, );

$builder->create_build_script();
