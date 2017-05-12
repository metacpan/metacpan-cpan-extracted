use warnings;
use strict;

use Module::Build;

my $builder = Module::Build->new
    ( module_name         => 'Archlinux::Term',
      license             => 'perl',
      dist_author         => q{Justin Davis <juster at cpan dot org>},
      dist_version_from   => 'lib/Archlinux/Term.pm',
      build_requires      => { 'Test::More' => 0, },
      add_to_cleanup      => [ 'Archlinux-Term-*' ],
      create_makefile_pl  => 'traditional',

      requires            => { map { ( $_ => 0 ) } 
                               qw/ Term::ANSIColor Text::Wrap / },

      meta_add => { resources =>
                    { repository =>
                      'http://github.com/juster/perl-archlinux-term' }},

     );

$builder->create_build_script();
