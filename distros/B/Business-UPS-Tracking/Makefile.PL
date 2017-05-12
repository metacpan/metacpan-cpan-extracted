# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;


my $from = 'lib/Business/UPS/Tracking.pm';

# Define metadata
name            'Business-UPS-Tracking';
all_from        $from;
readme_from     $from;

perl_version    '5.010';

# Specific dependencies
requires        'Moose'                 => '2.0400';
requires        'DateTime'              => '0.44';
requires        'Exception::Class'      => 0;
requires        'LWP::UserAgent'        => 0;
requires        'Text::SimpleTable'     => 0;
requires        'MooseX::Getopt'        => '0.30';
requires        'Path::Class'           => 0;
requires        'Encode'                => 0;
unless (can_use('Crypt::SSLeay') || can_use('IO::Socket::SSL')) {
    requires    'Crypt::SSLeay'         => 0;
}
requires        'XML::LibXML'           => 0;
requires        'Try::Tiny'             => 0;

build_requires  'Test::NoWarnings'      => 0;

author_requires 'Test::Pod'             => '1.14';
author_requires 'Test::Pod::Coverage'   => '1.04';
author_requires 'Test::Perl::Critic'    => 0;
author_requires 'Module::Install::ReadmeFromPod'        => 0;

repository 'git://github.com/maros/Business-UPS-Tracking.git';

install_script 'bin/ups_tracking';

WriteAll;