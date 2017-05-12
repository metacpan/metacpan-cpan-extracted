#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my %templates;
eval {
  use File::Find::Rule;
  %templates = map { $_ => $_ } File::Find::Rule->file->name('*.tt')->in('templates');
  warn "template: $_\n" for keys %templates;
};

my $build = Module::Build->new(
    module_name   => 'BuzzSaw',
    dist_abstract => 'Tools for parsing and filtering log files',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '0.12.0',
    license => 'gpl',
    requires => {
        'Date::Parse'               => 0,
        'DateTime'                  => 0,
        'DateTime::Format::Pg'      => 0,
        'DBD::Pg'                   => 0,
        'DBIx::Class'               => '0.08196',
        'Digest::SHA'               => 0,
        'File::Find::Rule'          => 0,
        'File::LibMagic'            => 0,
        'IO::Uncompress::Bunzip2'   => '2.020',
        'IO::Uncompress::Gunzip'    => '2.020',
        'Log::Log4perl'             => 0,
        'MIME::Lite'                => 0,
        'Moose'                     => '0.57',
        'MooseX::App::Cmd'          => 0,
        'MooseX::Getopt'            => 0,
        'MooseX::Log::Log4perl'     => 0,
        'MooseX::SimpleConfig'      => 0,
        'MooseX::Types'             => '0.21',
        'MooseX::Types::EmailAddress' => 0,
        'Readonly'                  => 0,
        'Template'                  => 0,
        'Text::Diff'                => 0,
        'UNIVERSAL::require'        => 0,
        'YAML::Syck'                => 0,
        'perl'                      => '5.10.0',
    },
    build_requires => {
        'Test::More'        => '0.87',
        'File::Find::Rule'  => 0,
    },
    templates_files => \%templates,
    install_path => {
      templates => '/usr/share/buzzsaw/templates',
    },
    add_to_cleanup => [ 'MANIFEST.bak', 'ChangeLog.bak' ],
    create_makefile_pl => 'traditional',
);
$build->add_build_element('templates');
$build->create_build_script;
