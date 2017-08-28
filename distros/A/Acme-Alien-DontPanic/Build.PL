use strict;
use warnings;

use Alien::Base::ModuleBuild;

if($^O eq 'midnightbsd')
{
  print "Sorry, MidnightBSD is not supported.\n";
  print "See:\n";
  print "https://github.com/Perl5-Alien/Alien-Base-Extras/issues/4\n";
  print "pull requests to fix this are welcome.\n";
  print "OS Unsupported\n";
  exit;
}

my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Acme::Alien::DontPanic',
  license => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => '0.044',
    'Module::Build' => 0.38,
  },
  test_requires => {
    'Test2::V0'           => 0,
    'ExtUtils::CBuilder' => 0,
    'Capture::Tiny'      => 0,
    'Test::Alien'        => '0.05',
    'Test2'              => '1.302015',
    'Test2::Suite'       => '0.000030',
  },
  requires => {
    'perl' => '5.008001',
    'Alien::Base' => '1.01',
  },
  dist_author => [
    'Graham Ollis <plicease@cpan.org>',
    'Joel A. Berger <joel.a.berger@gmail.com>',
  ],
  alien_name => 'dontpanic',
  alien_isolate_dynamic => 1,
  alien_repository => {
    protocol => 'https',
    host     => 'perl5-alien.github.io',
    location => '/page/dontpanic.html',
    pattern  => qr/\/([\d\.]+)\.tar\.gz$/,
  },
  alien_inline_auto_include => [ 'libdontpanic.h' ],
  meta_merge => {
    resources  => {
      repository => "http://github.com/Perl5-Alien/Acme-Alien-DontPanic",
      bugtracker => "http://github.com/Perl5-Alien/Acme-Alien-DontPanic/issues",
      x_MailingList => 'https://groups.google.com/forum/#!forum/perl5-alien',
      x_IRC => "irc://irc.perl.org/#native",
    },
  },  
  alien_stage_install => 1,
);

$builder->add_to_cleanup(
  'inc/dontpanic',
  't/static_link/*.o',
  't/static_link/main.so',
  't/static_link/main.dll',
  't/static_link/main.bundle',
);

$builder->create_build_script;

