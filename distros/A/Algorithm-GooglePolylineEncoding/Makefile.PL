# -*- perl -*-
use 5.006; # sprintf("%b")
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough || !eval { require CPAN::Meta; 1 }) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, you need a recent EUMM and CPAN::Meta"

EOF
    };
}




WriteMakefile(
	      NAME          => 'Algorithm::GooglePolylineEncoding',
	      AUTHOR        => 'Slaven Rezic <srezic@cpan.org>',
	      VERSION_FROM  => 'GooglePolylineEncoding.pm',
	      ABSTRACT_FROM => 'GooglePolylineEncoding.pm',
	      LICENSE       => 'perl',
	      ($eumm_recent_enough
	       ? (META_MERGE => { resources => { repository => 'git://github.com/eserte/algorithm-googlepolylineencoding.git' },
				  no_index => { directory => [qw(xt)] },
				})
	       : ()
	      ),
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
