#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Dackup',
    VERSION_FROM => 'lib/Dackup.pm',
    ABSTRACT     => 'Back up files over the network',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Data::Stream::Bulk'         => '0',
        'DBI'                        => '0',
        'DBD::SQLite'                => '0',
        'Devel::CheckOS'             => '0',
        'Digest::MD5::File'          => '0',
        'File::HomeDir'              => '0',
        'Moose'                      => '0',
        'MooseX::StrictConstructor'  => '0',
        'MooseX::Types::Path::Class' => '0',
        'Net::Amazon::S3'            => '0.50',
        'Net::Mosso::CloudFiles'     => '0.41',
        'Net::OpenSSH'               => '0.30',
        'Number::DataRate'           => '0',
        'Path::Class'                => '0',
        'Term::ProgressBar::Simple'  => '0.03',
        'File::Temp'                 => '0',
        'Test::More'                 => '0',
    }
);
