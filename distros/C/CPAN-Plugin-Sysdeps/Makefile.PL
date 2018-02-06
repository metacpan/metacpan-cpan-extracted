use strict;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    NAME              => 'CPAN::Plugin::Sysdeps',
    VERSION_FROM      => 'lib/CPAN/Plugin/Sysdeps.pm',
    PREREQ_PM         => {
	'List::Util' => 0,
	'Test::More' => 0,
    },
    EXE_FILES         => ['script/cpan-sysdeps'],
    LICENSE	      => 'perl',
    ABSTRACT          => 'CPAN.pm plugin for installing external dependencies',
    AUTHOR            => 'Slaven Rezic <srezic@cpan.org>',
    MIN_PERL_VERSION  => 5.006,

    ($eumm_recent_enough
     ? (META_ADD => { resources  => { repository => 'git://github.com/eserte/cpan-plugin-sysdeps.git' } }) : ()),

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
