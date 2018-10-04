use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use ExtUtils::MakeMaker;
use My::Module::Meta;

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    NAME => 'Astro::Coord::ECI::VSOP87D',
    VERSION_FROM => 'lib/Astro/Coord/ECI/VSOP87D.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Thomas R. Wyant, III F<wyant at cpan dot org>',
    ABSTRACT => 'Implement the VSOP87D position model.',
);

$mmv >= 6.31
    and $args{LICENSE} = 'perl';

if ( $mmv >= 6.4501 ) {
    $args{META_ADD} = {
	no_index => {
	    directory => [ qw{ inc t xt } ],
	},
    };
    $args{META_MERGE} = $meta->meta_merge( $meta->provides() );
}

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $args{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $args{META_MERGE}{build_requires} = $meta->build_requires();

WriteMakefile (%args);

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
	cover -test
EOD

}

# ex: set textwidth=72 :
