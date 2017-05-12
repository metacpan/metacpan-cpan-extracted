use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::URL',
    license             => 'perl',
    dist_author         => q{Barry Walsh <draegtun@cpan.org>},
    dist_version_from   => 'lib/Acme/URL.pm',
    
    build_requires => {
        'Test::More' => 0,
    },
    
    requires => {
        'Devel::Declare'        => 0.005011,
        'LWP::Simple'           => 0,
    },
    
    add_to_cleanup      => [ 'Acme-URL-*' ],
    
    meta_merge => {
      resources => {
          bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme::URL',
          repository => 'http://github.com/draegtun/Acme-URL'
      },
    },
    
);

$builder->create_build_script();
