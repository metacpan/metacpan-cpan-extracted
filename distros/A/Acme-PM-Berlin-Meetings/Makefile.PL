# -*- cperl -*-
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

WriteMakefile(NAME =>         'Acme::PM::Berlin::Meetings',
	      VERSION_FROM => 'lib/Acme/PM/Berlin/Meetings.pm',
	      ($eumm_recent_enough ?
	       (META_ADD => { resources => { repository => 'git://github.com/eserte/acme-pm-berlin-meetings.git' },
			    }) : ()),
	      PREREQ_PM => { 'DateTime' => 0,
			     'Exporter' => 5.57,
			   },
	      EXE_FILES => ['script/berlin-pm'],
	     );

sub MY::postamble {
    my $postamble = "";

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    if ($^O ne 'MSWin32') { # shell commands in Makefile rules are too hard for dmake
	my $bbbike_dir = sub {
	    for my $candidate ("$ENV{HOME}/src/bbbike") {
		return $candidate if -d $candidate;
	    }
	}->();
	my $berlinpm_github_io_dir = sub {
	    for my $candidate ("$ENV{HOME}/work2/BerlinPM.github.io") {
		return $candidate if -d $candidate;
	    }
	}->();
	$postamble .= <<"EOF";
BBBIKE_DIR=		$bbbike_dir
BERLINPM_GITHUB_IO_DIR= $berlinpm_github_io_dir

EOF
	$postamble .= <<'EOF';
convert-berlin-pm-meetings.org: convert-for-acme-pm-berlin-meetings convert-for-berlin-pm-org

convert-for-acme-pm-berlin-meetings: only-convert-for-acme-pm-berlin-meetings push-convert-for-acme-pm-berlin-meetings

only-convert-for-acme-pm-berlin-meetings:
	${PERL} script/pmmeetings2bbd.pl data/berlin-pm-meetings.org | ${PERL} ${BBBIKE_DIR}/miscsrc/bbd2kml -title "Berlin PM meetings" - > data/berlin-pm.kml~
	mv data/berlin-pm.kml~ data/berlin-pm.kml
	${PERL} script/pmmeetings2bbd.pl data/berlin-pm-meetings.org | ${PERL} ${BBBIKE_DIR}/miscsrc/bbd2geojson -combine - > data/berlin-pm.geojson~
	mv data/berlin-pm.geojson~ data/berlin-pm.geojson

push-convert-for-acme-pm-berlin-meetings:
	git diff data
	@echo "Does the diff look OK? (CTRL-C if not) "
	@read yn
	git commit -m "kml and geojson update" data/berlin-pm.kml data/berlin-pm.geojson
	git push

convert-for-berlin-pm-org: only-convert-for-berlin-pm-org push-convert-for-berlin-pm-org

only-convert-for-berlin-pm-org:
	[ -s "${BERLINPM_GITHUB_IO_DIR}" ]
	cd ${BERLINPM_GITHUB_IO_DIR}/javascripts && git pull
	${PERL} -c script/pmmeetings2bbd.pl
	${PERL} script/pmmeetings2bbd.pl -r data/berlin-pm-meetings.org | ${PERL} -Iinternal ${BBBIKE_DIR}/miscsrc/bbd2geojson -combine -combinemodule Acme::PM::Berlin::Meetings::GeoJSONCombiner -bbbgeojsonp - > ${BERLINPM_GITHUB_IO_DIR}/javascripts/berlin-pm.geojsonp~
	mv ${BERLINPM_GITHUB_IO_DIR}/javascripts/berlin-pm.geojsonp~ ${BERLINPM_GITHUB_IO_DIR}/javascripts/berlin-pm.geojsonp

push-convert-for-berlin-pm-org:
	cd ${BERLINPM_GITHUB_IO_DIR}/javascripts && git diff
	@echo "Does the diff look OK? (CTRL-C if not) "
	@read yn
	cd ${BERLINPM_GITHUB_IO_DIR}/javascripts && git commit -m "update historical map" berlin-pm.geojsonp && git push

EOF
    }

    $postamble;
}
