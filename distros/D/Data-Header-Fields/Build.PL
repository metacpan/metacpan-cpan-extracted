use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Header::Fields',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Data/Header/Fields.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'IO::Any'           => 0,
        'Carp'              => 0,
        'String::Escape'    => 0,
        'List::MoreUtils'   => 0,
        'Scalar::Util'      => 0,
        'MIME::QuotedPrint' => 0,
        'MIME::Base64'      => 0,    # Introduce make_path() and rm_tree() API extension.
        'Encode'            => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Deep'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'Data-Header-Fields-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Data-Header-Fields.git',
            bugtracker => 'http://github.com/jozef/Data-Header-Fields/issues',
        },
        keywords => [ qw/ rfc822 rfc2822 header parse edit / ],
    },
);
$builder->create_build_script();
