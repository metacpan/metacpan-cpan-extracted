use strict;
use warnings;

use Module::Build;
use Acme::Alien::DontPanic;

my $dontpanic = Acme::Alien::DontPanic->new;

my $cflags = $dontpanic->cflags;
my $libs   = $dontpanic->libs;

my $builder = Module::Build->new(
    module_name       => 'Acme::Ford::Prefect',
    dist_abstract     => 'Part of the test framework for Alien::Base',
    dist_author       => [
      'Graham Ollis <plicease@cpan.org>',
      'Joel Berger <joel.a.berger@gmail.com>',
    ],
    license           => 'perl',
    configure_requires => {
      'Module::Build' => '0.38',
      'Acme::Alien::DontPanic' => '0.042',
    },
    test_requires => {
      'Test::More'    => 0,
    },
    build_requires    => {
      'ExtUtils::CBuilder' => 0,
    },
    requires => {
      'perl' => '5.008001',
    },
    extra_compiler_flags => $cflags,
    extra_linker_flags   => $libs, 
    meta_merge => {
      resources  => {
        repository => "http://github.com/Perl5-Alien/Acme-Ford-Prefect",
        bugtracker => "http://github.com/Perl5-Alien/Acme-Ford-Prefect/issues",
        x_MailingList => 'https://groups.google.com/forum/#!forum/perl5-alien',
        x_IRC => "irc://irc.perl.org/#native",
      },
    },  
);

$builder->create_build_script;

