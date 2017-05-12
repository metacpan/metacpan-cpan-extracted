
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Combust::Spontaneously',
  license             => 'perl',
  requires => {
    'Getopt::AsDocumented'     => 0,
    'HTTP::Server::Simple::Er' => 0,
    'Class::Accessor::Classy'  => 'v0.9.1',
    # combust requires:
    'Config::Simple'     => 0,
    'Digest::MD5'        => 0,
    'Digest::SHA1'       => 0,
    'Exception::Class'   => 0,
    'HTML::Entities'     => 0,
    'LWP::MediaTypes'    => 0,
    'Pod::Simple'        => 0,
    'Pod::Simple::HTML'  => 0,
    'Template'           => 0,
    'Template::Document' => 0,
    'Template::Parser'   => 0,
    'Template::Stash'    => 0,
    'URI::Escape'        => 0,
  },
  build_requires => {
    'Module::Build' => 0.34,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Combust-Spontaneously-* META.yml)],
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Combust-Spontaneously',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Combust-Spontaneously/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
