use strict;
use warnings;
use ExtUtils::MakeMaker;
use ASPEER::MakeMaker::Markdown::Publish;

WriteMakefile(
    NAME    => 'Example::Documentation',
    VERSION => '0.001',
    META_MERGE => {
        'meta-spec' => {version => 2},
        x_documentation => {
            publish => {
                sources => ['doc'],
                name    => 'Example documentation',
            },
        },
    },
);
