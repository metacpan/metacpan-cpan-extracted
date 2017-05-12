# -*- perl -*-

use strict;
use warnings;
use inc::Module::Install;

name           ('Bb-Collaborate-V3');
module_name    ('Bb::Collaborate::V3');
author         ('David Warring <david.warring@gmail.com>');
all_from       ('lib/Bb/Collaborate/V3.pm');
license	       ('perl');
install_script ();

requires(
    'Class::Accessor'              => 0,
    'Class::Data::Inheritable'     => 0,
    'Date::Parse'                  => 0,
    'Carp'                         => 0,
    'File::Spec'                   => 0,
    'File::Basename'               => 0,
    'Elive::DAO'                   => '1.37',
    'Elive::Connection'            => '1.37',
    'Elive::Util'                  => '1.37',
    'MIME::Base64'                 => 0,
    'Mouse'                        => 0.56,
    'SOAP::Lite'                   => 0.712,
    'Try::Tiny'                    => 0,
    'URI'                          => 0,
    'XML::Simple'                  => 0,
    'YAML::Syck'                   => 0,
    );

recommends(

    );

test_requires (
    'Test::Builder'            => 0,
    'Test::More'               => 0,
    'Test::Warn'               => 0,
    'Test::Fatal'              => 0,
    'version'                  => 0,
    );

repository("https://github.com/dwarring/p5-Bb-Collaborate.git");

WriteAll;
