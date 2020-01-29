BEGIN {
  unless(eval q{ use 5.008001; 1}) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}
use strict;
use warnings;

use Module::Build;
use Acme::Alien::DontPanic;

my $dontpanic = Acme::Alien::DontPanic->new;

my $builder = Module::Build->new(
    module_name       => 'Acme::Ford::Prefect::FFI',
    dist_abstract     => 'FFI test for Alien::Base',
    dist_author       => 'Graham Ollis <plicease@wdlabs.com>',
    license           => 'perl',
    configure_requires => {
      'Module::Build' => '0.38',
      'Acme::Alien::DontPanic' => '1.96',
    },
    build_requires    => {
      'ExtUtils::CBuilder' => 0,
    },
    requires          => {
      'perl'                   => '5.008001',
      'FFI::Platypus'          => '0.47',
      'Acme::Alien::DontPanic' => '1.96',
      'FFI::CheckLib'          => '0.15',
    },
    test_requires => {
      'Test2::V0'              => 0,
    },
    meta_merge => {
      resources  => {
        repository => "http://github.com/Perl5-Alien/Acme-Ford-Prefect-FFI",
        bugtracker => "http://github.com/Perl5-Alien/Acme-Ford-Prefect-FFI/issues",
        x_MailingList => 'https://groups.google.com/forum/#!forum/perl5-alien',
        x_IRC => "irc://irc.perl.org/#native",
      },
    },  
);

$builder->add_to_cleanup('Acme-Ford-Prefect-FFI*');

$builder->create_build_script;

