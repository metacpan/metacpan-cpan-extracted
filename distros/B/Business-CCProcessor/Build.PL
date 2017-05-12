use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Business::CCProcessor',
    license             => 'gpl',
    dist_author         => 'Hugh Esco <hesco@campaignfoundations.com>',
    dist_version_from   => 'lib/Business/CCProcessor.pm',
    requires => {
        'Test::More' => 0,
  'CGI::FormBuilder' => 0,
           'version' => 0,
              'Carp' => 0,
    'WWW::Mechanize' => 0,
  'Test::HTML::Tidy' => 0,
  'Test::HTML::Lint' => 0,
'Test::Perl::Critic' => 0,
    },
    add_to_cleanup      => [ 'Business-CCProcessor-*', 'test-*.html' ],
);

$builder->create_build_script();
