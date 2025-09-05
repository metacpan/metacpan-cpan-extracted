use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use File::Find;

install_share dist => 'share';

my $GITHUB_URL = 'https://github.com/CNAG-Biomedical-Informatics/clarid-tools';

WriteMakefile(
    NAME          => 'ClarID::Tools',
    ABSTRACT_FROM => 'lib/ClarID/Tools.pm',
    AUTHOR        => q{Manuel Rueda <mrueda@cpan.org>},
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/ClarID/Tools.pm',
    META_MERGE    => {
        'dynamic_config' => 0,
        'meta-spec' => { version   => 0 },
        'no_index'  => { directory => [qw(docs t nb)] },
        'prereqs'   => { runtime   => { requires => { perl => '5.036000' } } },
        'resources' => {
            bugtracker => { web => "$GITHUB_URL/issues" },
            homepage   => $GITHUB_URL,
            license    =>
              ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository =>
              { type => 'git', url => "$GITHUB_URL.git", web => $GITHUB_URL },
        },
        'x_contributors' => [],
    },
    PREREQ_PM => {
        'JSON::XS'        => '4.03',
        'YAML::XS'        => '0.88',
        'Path::Tiny'      => '0.144',
        'Term::ANSIColor' => '5.01',
        'Text::CSV_XS'    => '1.50',
        'App::Cmd'        => '0.337',
        'Moo'             => '2.005005',
        'MooX::Options'   => '4.103' , 
        'Types::Standard' => '2.004000',
        'JSON::Validator' => '5.14',
        'File::ShareDir::ProjectDistDir' => '1.000009',
        'namespace::autoclean'           => '0.31'

    },
    EXE_FILES => [
        'bin/clarid-tools'

    ],
    TEST_REQUIRES => {
        'Test::More'            => '1.30',
        'File::Path'            => '2.18',
        'File::Spec::Functions' => '3.75'
    },
    test               => { TESTS => 't/*.t' },
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install' => '0.14',
        'ExtUtils::MakeMaker'     => '7.70'
    }
);

package MY;
use File::ShareDir::Install 'postamble';
