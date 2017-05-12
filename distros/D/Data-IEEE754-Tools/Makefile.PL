use ExtUtils::MakeMaker;
use 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'Data::IEEE754::Tools',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'Tools.pm',
    'ABSTRACT_FROM' => 'Tools.pm',
    'PREREQ_PM'     => {
        'Exporter'      => 0,
        'version'       => 0.77,
        'warnings'      => 0,
        'strict'        => 0,
        'Carp'          => 0,
    },
);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.46' ) {
        $mm_args{META_MERGE} = {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    mailto  => 'bug-Data-IEEE754-Tools@rt.cpan.org',
                    web     => 'https://github.com/pryrt/Data-IEEE754-Tools/issues',
                },
                repository => 'https://github.com/pryrt/Data-IEEE754-Tools',
            },
            keywords => [ 'IEEE-754', 'floating point representation'],
            # don't use 'provides', because it's an extra step to maintain, and
            # can cause problems (getting a mismatch between the $VERSION string and the
            # provides->{version} will really make it hard to release a next version into CPAN
        },
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.6.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.52' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            'ExtUtils::MakeMaker' => 0,
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
        },
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
        };
    }
}

WriteMakefile( %mm_args )
