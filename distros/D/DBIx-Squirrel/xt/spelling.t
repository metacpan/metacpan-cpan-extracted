use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The POD's spelling, checked as Minilla's own release test,
# xt/minilla/spelling.t, checks it as `minil dist` builds the tarball,
# so that a word it doesn't know fails CI on the push that brings it,
# not the release. A word in the manuals failed only at the release
# before: v3.4.0's reference said "21st" (5d1801c), and Ekorn-Pipeline's
# v0.3.8, tagged before its tarball failed on "setlist", never reached
# CPAN. A word that's right but unknown goes in the stopwords of the
# file it's in: in docs/REFERENCE.md and docs/HOWTO.md, the
# <!-- stopwords: ... --> comment at the top, which scripts/manuals
# makes the manual's =for stopwords; in a module, its =for stopwords
# line. README.pod is checked too (roadmap 2026-0052). CI's coverage
# job runs it, as it installs the cpanfile's develop modules,
# Test::Spellunker among them; elsewhere it's skipped without that
# module, saying so.


BEGIN {
    eval { require Test::Spellunker; Test::Spellunker->VERSION('v0.2.2') }
        or skip_all "Test::Spellunker v0.2.2 or later isn't installed";
    Test::Spellunker->import;
}

# As Minilla's test does: the distribution's name, and the stopwords in
# minil.toml, of which there are none.
add_stopwords('DBIx-Squirrel');

pod_file_spelling_ok($_) for Test::Spellunker::all_pod_files('lib');

pod_file_spelling_ok('README.pod');

done_testing;
