use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::Plugin::Session::Store::DBIC',
    AUTHOR        => 'Daniel Westermann-Clark <danieltwc@cpan.org>',
    VERSION_FROM  => 'lib/Catalyst/Plugin/Session/Store/DBIC.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Plugin/Session/Store/DBIC.pm',
    PREREQ_PM     => {
        'Carp'                                       => 0,
        'Catalyst'                                   => '5.65',  # For setup_finished
        'Catalyst::Exception'                        => 0,
        'Catalyst::Plugin::Session::Store::Delegate' => '0.05',
        'Class::Accessor::Fast'                      => 0,
        'DBIx::Class'                                => '0.07000',  # For find with unique constraints
        'MIME::Base64'                               => 0,
        'MRO::Compat'                                => 0,
        'Scalar::Util'                               => 0,
        'Storable'                                   => 0,
        'FindBin'                                    => 0,
        'Test::More'                                 => 0,
        'Test::Warn'                                 => '0.20', # so we get warnings_exist
    },
    META_MERGE              => {
        resources => {
            repository  =>      'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Session-Store-DBIC/',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Catalyst-Plugin-Session-Store-DBIC-* MANIFEST META.yml README' },
);


package MY;

sub postamble {
    return <<"...";
cover::
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	cover

readme::
	perldoc -o text -d README \$(NAME)
...
}

1;
