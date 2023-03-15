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
    NAME              => 'App::orgdaemon',
    VERSION_FROM      => 'bin/org-daemon',
    PREREQ_PM         => {
	'Tk'	   => 0,
	'IPC::Run' => 0, # but may also work without
	($] < 5.010 ? ('Time::y2038' => 0) : ()),
    },
    EXE_FILES         => ['bin/org-daemon', 'bin/org2ical'],
    LICENSE	      => 'perl',
    ($] >= 5.005 ?
      (ABSTRACT	      => 'watch for appointments in org-mode files',
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'https://github.com/eserte/org-daemon.git' } }) : ()),
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
