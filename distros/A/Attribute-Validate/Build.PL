#!/usr/bin/env perl
use Module::Build;
use CPAN::Meta;

my $home = $ENV{HOME};

my $build = Module::Build->new(
    module_name       => 'Attribute::Validate',
    license           => 'mit',
    dist_version_from => 'lib/Attribute/Validate.pm',
    dist_author       => 'Sergio Iglesias <sergioxz@cpan.org>',
    dist_abstract     =>
      'Validate subroutine parameters.',
    requires => {
        'Attribute::Handlers' => 0,
        'Carp' => 0,
        'Carp::Always' => 0,
        'Type::Params' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    test_requires => {
        'Types::Standard' => 0,
        'Test::Exception' => 0,
    },
    meta_merge => {
        resources => {
            bugtracker =>
              'https://github.com/sergiotarxz/Perl-Attribute-Validate/issues',
            repository => 'https://github.com/sergiotarxz/Perl-Attribute-Validate',
        }
    },
);
$build->create_build_script;
