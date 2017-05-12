use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Meta;
use My::Module::Recommend;

use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};
use FileHandle;
use Getopt::Std;

my $meta = My::Module::Meta->new();

my %opt;
getopts ('ny', \%opt) or die <<'EOD';
The only legal options are
  -n = answer all questions 'no'.
  -y = answer all questions 'yes'.
You may not assert both of these at once - it's too confusing.
EOD

my @exe_files = map {"script/$_"} $meta->notice( \%opt );

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my %attr = (
    NAME => 'Astro::SpaceTrack',
    VERSION_FROM => 'lib/Astro/SpaceTrack.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    EXE_FILES => \@exe_files,
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Tom Wyant (wyant at cpan dot org)',
    ABSTRACT => 'Download satellite orbital elements from Space Track',
    realclean	=> { FILES => 'cover_db xt/author/optionals' },
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4501
    and $attr{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $attr{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $attr{META_MERGE}{build_requires} = $meta->build_requires();

WriteMakefile (%attr);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN) "-Iinc" "-MMy::Module::Test"', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    $authortest =~ s/ (?= \b test_harness \b ) /spacetrack_user(); /smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t xt/author/optionals/*.t

authortest :: pure_all
	\$(FULLPERLRUN) "-Iinc" "-MMy::Module::Recommend" \\
	    "-e" "My::Module::Recommend->make_optional_modules_tests()"
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/
EOD
}
