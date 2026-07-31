use strict;
use warnings;
use Test::More;

# Author check on the build recipe itself.  An Alien::Build `build` command must
# confine every write to $DESTDIR: Alien::Build and ExtUtils::MakeMaker re-prepend
# DESTDIR during the *install* phase, when the process has the right privileges and
# the user's install target is known.  A build-phase write to a reconstructed
# absolute path is what made CPAN Testers fail with
#   copy .../destdir_XXXX/usr/local/lib64/perl5/5.32/SNMP.pm: Permission denied
# Not run for installers.
unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author tests not required for installation';
}

# Comment lines are stripped: the recipe documents *why* it no longer touches these
# things, and that prose must not read as a violation.
my $alienfile = join "\n", grep { !/^\s*#/ } split /\n/, _slurp('alienfile');

# A substitution whose pattern mentions DESTDIR, e.g. s/^\Q$destdir\E// -- the only
# reason to write one is to turn a staged path back into a live one.  Bounded to a
# single statement so an unrelated later mention cannot trip it.
unlike $alienfile, qr/=~ \s* s [^;]{0,120} DESTDIR/xi,
  'alienfile__build_recipe__never_strips_DESTDIR_to_rebuild_an_absolute_path';

# perllocal.pod is an append-only global manifest and .packlist is per-install
# bookkeeping; both belong to whatever installs this distribution, never to us.
foreach my $artifact (qw( perllocal.pod .packlist )) {
    unlike $alienfile, qr/\Q$artifact\E/,
      "alienfile__build_recipe__does_not_handle_$artifact";
}

done_testing;

sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "can't read $file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}
