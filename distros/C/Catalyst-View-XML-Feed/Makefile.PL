use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-View-XML-Feed';
all_from 'lib/Catalyst/View/XML/Feed.pm';

requires 'Moose'                => 0;
requires 'namespace::autoclean' => 0;
requires 'XML::Feed'            => '0.43';
requires 'Scalar::Util'         => 0;

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Catalyst::Test'    => 0;
build_requires 'Test::More'        => '0.88';
build_requires 'DateTime'          => 0;


auto_set_repository;
auto_install;

WriteAll;
