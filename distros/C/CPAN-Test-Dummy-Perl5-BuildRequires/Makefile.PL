use strict;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.5503;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    NAME              => 'CPAN::Test::Dummy::Perl5::BuildRequires',
    VERSION_FROM      => 'lib/CPAN/Test/Dummy/Perl5/BuildRequires.pm',
    PREREQ_PM         => { },
    BUILD_REQUIRES    => {
        'CPAN::Test::Dummy::Perl5::Make' => 0,
    },
    CONFIGURE_REQUIRES    => {
        'ExtUtils::MakeMaker' => '6.5503', # for BUILD_REQUIRES
    },
    LICENSE	      => 'perl',
    ABSTRACT          => 'Dummy test module with a build_requires dependency',
    AUTHOR            => 'Slaven Rezic <srezic@cpan.org>',
    MIN_PERL_VERSION  => 5.006,

    ($eumm_recent_enough
     ? (META_ADD => {
	 resources      => { repository => 'git://github.com/eserte/cpan-test-dummy-perl5-buildrequires.git' },
	 dynamic_config => 0,
	}) : ()),

);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
