
use 5.008004;

use ExtUtils::MakeMaker;

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/_//g;

my %attr = (
    NAME		    => 'DateTime::Calendar::Christian',
    VERSION_FROM	=> 'lib/DateTime/Calendar/Christian.pm',
    PREREQ_PM		=> {
			    'DateTime' => 0.1402,
			    'DateTime::Calendar::Julian' => 0.04,
                       },
    ABSTRACT        => 'Dates in the Christian (combined Julian/Gregorian) calendar',
    AUTHOR          => [
	'Eugene van der Pijll <pijll@gmx.net>',
	'Thomas R. Wyant, III <wyant at cpan dot org>',
    realclean	=> { FILES => 'cover_db' },
    ],
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = '5.008004';

if ( $mmv >= 6.4501 ) {
    $attr{META_MERGE} = {
	'meta-spec'	=> {
	    version	=> 2,
	},
	dynamic_config	=> 0,
	no_index	=> {
	    directory	=> [ qw{ t xt } ],
	},
	resources	=> {
	    bugtracker	=> {
                web	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Calendar-Christian',
                mailto  => 'wyant@cpan.org',
            },
	    license	=> 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-DateTime-Calendar-Christian.git',
		web	=> 'https://github.com/trwyant/perl-DateTime-Calendar-Christian',
	    },
	},
	provides(),
    };
}

my %build_requires = (
    'Test::More'	=> 0.88,
);

if ( $mmv >= 6.5501 ) {
    $attr{BUILD_REQUIRES} = \%build_requires;
} else {
    @{ $attr{PREREQ_PM} }{ keys %build_requires } = values %build_requires;
}

WriteMakefile( %attr );

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t

authortest :: pure_all
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/
EOD
}

sub provides {
    -d 'lib'
	or return;
    local $@ = undef;
    my $provides = eval {
	require Module::Metadata;
	Module::Metadata->provides( version => 2, dir => 'lib' );
    } or return;
    return ( provides => $provides );
}

# ex: set textwidth=72 :
