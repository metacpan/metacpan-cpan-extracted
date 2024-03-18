use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'DB::Object',
    VERSION_FROM        => 'lib/DB/Object.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'A SQL Database object abstraction class',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'            => 0,
        'parent'            => 0,
        'version'           => 0,
        'common::sense'     => '3.75',
        'Class::Struct'     => '0.65',
        'DateTime'          => '1.59',
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::TimeZone' => '2.56',
        'DBI'               => '1.643',
        'Devel::Confess'    => '0.009004',
        'Fcntl'             => 0,
        'JSON'              => '4.10',
        'JSON::XS'          => '4.03',
        'Module::Generic'   => 'v0.35.1',
        'Net::IP'           => '1.26',
        'POSIX'             => '1.53_01',
        'Promise::Me'       => 'v0.4.7',
        'Regexp::Common'    => '2017060201',
        'Scalar::Util'      => '1.63',
        'URI'               => '5.16',
        'Want'              => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
        'version'           => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'DB-Object-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/DB-Object.git',
                web         => 'https://gitlab.com/jackdeguest/DB-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/DB-Object/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
