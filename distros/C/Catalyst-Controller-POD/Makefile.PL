#
# This file is part of Catalyst-Controller-POD
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
use inc::Module::Install;

# Define metadata
name 'Catalyst-Controller-POD';
all_from 'lib/Catalyst/Controller/POD.pm';

repository 'http://github.com/monken/Catalyst-Controller-POD/tree/master';

# Specific dependencies
requires 'Test::More'            => 0;
requires 'Pod::Simple'           => 0;
requires 'File::Find'            => "0.05";
requires 'File::ShareDir'        => "0.05";
requires 'File::Slurp'           => "9999";
requires 'Pod::Simple'           => "3.05";
#requires 'File::Wildcard';
requires 'JSON::XS'              => "2.21";
requires 'Pod::POM'              => "0.17";
requires 'LWP::Simple'           => "5.810";
requires "XML::Simple"           => "2.18";
requires 'List::MoreUtils'       => "0.22";
requires 'Class::Accessor::Fast' => "0.31";
requires 'Catalyst::Controller'  => 0;
requires 'Pod::POM::View::TOC'   => "0.02";
requires 'parent'                => 0;
requires 'Path::Class::File' => 0;
requires 'Catalyst::Plugin::Static::Simple' => 0;

test_requires 'Test::More'     => '0.42';
test_requires 'Test::WWW::Mechanize::Catalyst' => "0.41";

install_share;

WriteAll;
