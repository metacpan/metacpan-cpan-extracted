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
    NAME                => 'CSS::Object',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/CSS/Object.pm',
    ABSTRACT_FROM       => 'lib/CSS/Object.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        'strict'        => 0,
        'warnings'      => 0,
        'parent'        => 0,
        'overload'      => '1.22',
        'overloading'   => '0.02',
        'Devel::Confess'    => '0.009004',
        'Module::Generic'   => 'v0.32.4',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'CSS-Object-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/CSS-Object.git',
                web         => 'https://gitlab.com/jackdeguest/CSS-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/CSS-Object/issues',
            },
            license => [ 'http://dev.perl.org/licenses/' ],
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
