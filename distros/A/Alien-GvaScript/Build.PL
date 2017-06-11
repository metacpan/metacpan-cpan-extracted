use strict;
use warnings;
use lib '.';
use GvaScript_Builder;

my $builder = GvaScript_Builder->new(
    module_name         => 'Alien::GvaScript',
    license             => 'perl',
    dist_author         => 'Laurent Dami <laurent.dami@justice.ge.ch>',
    dist_version_from   => 'lib/Alien/GvaScript.pm',
    requires            => {
      'File::Copy' => 0,
      'File::Path' => 0,
     },
    recommends => {
      'Pod::POM'             => 0,
      'Pod::POM::View'       => 0,
      'Pod::POM::View::HTML' => 0,
     },
    build_requires => {
      'Test::More'           => 0,
    },
    add_to_cleanup      => [ 'Alien-GvaScript-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Alien-GvaScript',
       }
     },
);


# include dhtml files in the distribution
$builder->add_build_element($_) for qw/html js css gif png/;
$builder->create_build_script();
