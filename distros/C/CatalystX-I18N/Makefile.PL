# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

my $from = 'lib/CatalystX/I18N.pm';

# Define metadata
name            'CatalystX-I18N';
all_from        $from;
readme_from     $from;

perl_version    '5.008';

# Specific dependencies
requires        'Catalyst::Runtime'                     => '5.80004';
requires        'Moose'                                 => 0;
requires        'parent'                                => 0;
requires        'POSIX'                                 => 0;
requires        'namespace::autoclean'                  => 0;

requires        'Path::Class'                           => 0;
requires        'MooseX::Types::Path::Class'            => 0; 
requires        'Clone'                                 => 0;

requires        'Locale::Maketext::Lexicon'             => 0;
requires        'Locale::Maketext'                      => 0;
requires        'Locale::Geocode'                       => 0;

requires        'DateTime'                              => 0;
requires        'DateTime::Locale'                      => '0.40';
requires        'DateTime::Format::CLDR'                => 0;
requires        'DateTime::TimeZone'                    => 0;
requires        'MooseX::Types::DateTime'               => 0;

requires        'IP::Country'                           => 0;
requires        'HTTP::BrowserDetect'                   => '1.09';
requires        'Number::Format'                        => 0;
requires        'Unicode::Collate'                      => 0;

requires        'Data::Localize'                        => 0;
requires        'Data::Localize::Format::Gettext'       => 0;

build_requires  'Test::Most'                            => 0;
build_requires  'Test::NoWarnings'                      => 0;
build_requires  'Test::WWW::Mechanize::Catalyst'        => 0;
build_requires  'JSON'                                  => '2.17';
build_requires  'Catalyst::Plugin::Session'             => 0;
build_requires  'Catalyst::Plugin::Session::State::Cookie'=> 0;
build_requires  'Catalyst::Plugin::Session::Store::File'=> 0;
build_requires  'Catalyst::View::TT'                    => 0;
build_requires  'Template'                              => 0;

author_requires 'Test::Pod'                             => '1.14';
author_requires 'Test::Pod::Coverage'                   => '1.04';
author_requires 'Test::Perl::Critic'                    => 0;
author_requires 'Module::Install::ReadmeFromPod'        => 0;
author_requires 'Module::Install::AuthorRequires'       => 0;

repository 'git://github.com/maros/CatalystX-I18N.git';

WriteAll;