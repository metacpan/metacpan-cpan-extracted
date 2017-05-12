# -*- cperl -*-
use 5.010; # new pack features
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(NAME          => 'Acme::Study::SREZIC',
	      AUTHOR        => 'Slaven Rezic <srezic@cpan.org>',
	      VERSION_FROM  => 'SREZIC.pm',
	      LICENSE       => 'perl',
	      ($eumm_recent_enough
	       ? (META_MERGE => { resources => { repository => 'git://github.com/eserte/acme-study-srezic.git' },
				})
	       : ()
	      ),
	      PREREQ_PM => { 'Test::More'  => 0 },
	      MIN_PERL_VERSION => 5.10.0,
	     );

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
        $postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }
}
