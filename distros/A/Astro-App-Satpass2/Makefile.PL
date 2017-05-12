use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Meta;
use My::Module::Recommend;

use ExtUtils::MakeMaker qw{WriteMakefile};

my $meta = My::Module::Meta->new();

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my %attr = (
    NAME => 'Astro::App::Satpass2',
    VERSION_FROM => 'lib/Astro/App/Satpass2.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    EXE_FILES => [qw{bin/satpass2}],
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Tom Wyant (wyant at cpan dot org)',
    ABSTRACT => 'Predict satellite visibility using Astro::Coord::ECI',
    realclean	=> { FILES => 'cover_db xt/author/optionals' },
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

if ( $mmv >= 6.4501 ) {
    $attr{META_MERGE} = $meta->meta_merge(
	$meta->provides(),
    );
} else {
    $attr{PREREQ_PM}{'Test::More'} = 0.40;
}

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $attr{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $attr{META_MERGE}{build_requires} = $meta->build_requires();

My::Module::Recommend->recommend();

WriteMakefile (%attr);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t xt/author/optionals/*.t

authortest :: pure_all
	\$(FULLPERLRUN) "-Iinc" "-MMy::Module::Recommend" "-e" "My::Module::Recommend->make_optional_modules_tests()"
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/
EOD
}

# ex: set textwidth=72 :
