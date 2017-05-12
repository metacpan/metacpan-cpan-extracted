package App::SnerpVortex;
BEGIN {
  $App::SnerpVortex::VERSION = '1.000';
}
use strict;
use warnings;

1;

__END__

=head1 NAME

App::SnerpVortex - Replay a Subversion dump into Git/Filesystem/etc.

=head1 About

Snerp Vortex is an anagram of SVN Exporter.  It aims to be a faster,
more reliable way to create new repositories from Subversion dumps
than using git-svn and/or various abandonment techniques.

Faster?  On my canonical example repository (POE), Snerp Vortex
converts 2824 Subversion commits to Git in under 300 seconds.

Not fast enough?  The conversion happens in about 100 seconds if we
remove Git's porcelain from the equation.  So there's a lot of room
for improvement, perhaps by switching to git-fast-import.  I'm looking
for someone who wants to help port it over.

More satisfying?  Snerp Vortex uses path analysis to detect hints
about tags and branches.  It then adjusts its assumptions according to
actual repository use.  Tags that are modified later become branches.
Branches that are never touched are demoted to tags.

Snerp Vortex gains some benefits by doing tag and branch analysis
before converting the repository:

=over 4

=item *

Tag and branch analyses can be examined by a human without converting
the repository.  The L<snassign-gui> utility graphically browses the
repository structure over time.

=item *

Analysis errors can be fixed and redone quickly without waiting for
lengthy repository conversions each time.

=item *

Tagging and branching are performed as "git tag" and "git branch" at
appropriate times.  It's faster and smaller than duplicating directory
trees and converting them later.

=back

There is rudimentary support for multiple projects per repository, but
it needs love.

=head2 Toolset

Snerp Vortex is a chain of multiple tools.

=over 4

=item snanalyze

L<snanalyze> examines a Subversion dump and produces a SQLite database
that describes its structure over time.  snanalyze is intended to be
run first, as most other utilities require the SQLite database to
work.

=item snassign-auto

L<snassing-auto> attemtps to automaically assign tags and branches
based on directory locations and usage patterns.  It's generally run
after snanalyze and before snassign-gui.

=item snassign-gui

L<snassign-gui> is a Gtk2 utility to browse a repository analysis.
With it, one can page back and forth through significant revisions to
see how snassign-auto interpreted structural changes.

Some repositories will be too complex for snassign-auto to be
successful.  We hope a motivated individual will update snassign-gui
to be a tag/branch assignment editor so humans can override the
automatic assignment.

snassign-gui is intended to be used to verify that snassign-auto
worked correctly, before a possibly lengthy snerp run.

=item snerp

When everything is ready, snerp is called to export the Subversion
dump.  It takes as input the Subversion dump, and the index database
containing final tag and branch assignments.  It produces a new copy
of the repository in the desired format.

=back

=head2 Getting Subversion Dumps

Snerp Vortex requires a Subversion dump file, which is generally
created by running svnadmin dump on a local repository.

There's also a remote svn dump utility that may help, but we haven't
tried it: http://rsvndump.sourceforge.net/

=head2 Other Included Utilities

Snerp Vortex comes with some utilities and scripts that will
eventually be cleaned up and organized.  Until then:

=over 4

=item mkramdisk_osx

Create a 1 GB RAM disk with a case-sensitive filesystem.  Extremely
useful for Macintosh machines that use case-insensitive filesystems by
default.

=item snub

Snub the file contents of a dump.  Retains the file and directory
structure, but the resulting dump and replays are much smaller.
Written for Ævar Arnfjörð Bjarmason's six-gigabyte dump, which
triggers a hard to reproduce bug.

=item diff-test

Performs a recursive diff, excluding some things that Subversion may
have that another VCS may not.  For example, expanded "$Id$" tags.
Useful for testing the results of a replay, although it won't test
intermediate revisions... only the final ones.

=back

=head2 Development Scripts

Other development and/or test scripts are included in the distribution
but are neither installed nor documented here.  Browse around!

=head1 OSX Users

Get yourselves a case-sensitive filesystem.  This is easier done than
said.  Disk Utility can create empty random-access disk images with
the filesystems of your choice.  They mount in /Volumes and are
accessible like any other filesystem.

Even better, build a RAM disk if you have the memory to spare.  See
the mkramdisk_osx utility in this project.

=head1 Improvements?

I've heard that git-fast-import can potentially make Snerp Vortex a
lot faster.  The program should be flexible enough to support it
without much fuss.

I may not get around to it, as I'm rapidly running out of Subversion
repositories to convert.  If you want or need this, please consider
contributing.

=head1 Testing

Until there's a proper test framework, here's the plan from a recent
test I ran.

Create a dummy repository, check it out and establish a test case
within it.

	svnadmin create binary-svn
	svn co file:///home/troc/projects/git/binary-svn binary-co          
	cd binary-co
	cp ~/Downloads/wtf.gif .
	svn add wtf.gif
	svn commit -m 'Commit a binary file.' 

Dump the repository.

	cd ..
	svnadmin dump binary-svn > binary-svn.dump

If it's a really huge repository, then early debugging might go better
if the contents of all the files is omitted.

	cat huge.dump | ./snub --file - > smaller.dump

Replay the repository into git.

	cd snerp-vortex

	time ./snerp \
		--replayer=git \
		--authors=/home/troc/projects/authors.txt \
		--into=/Volumes/snerp-vortex-workspace/binary-git \
		--dump=../binary-files.dump \
		--copies=/Volumes/snerp-vortex-workspace/binary-snerp-copies \
		--verbose

Verify that the replayed binary file works.

	open /Volumes/snerp-vortex-workspace/binary-git/wtf.gif

The distribution's t/dumps directory is the repository for test dumps.

=head1 Design Notes

There are multiple kinds of branch, some of which don't map to Git's
idea of branches.  For example, there's the branch that is someone's
personal scratch workspace.  Then there's the branch intended to be
merged back later.

Tags and branches are defined by usage patterns, not by the
directories in which they live.  Proper branches and tags are created
by copying, not by creating directories.  The difference is that
branches are modified after copying while tags are not.  Subversion
"tags" are frequently modified, and "branches" are sometimes never
touched.  Snerp Vortex tries to be smart about this.

Subprojects are not attempted to be spun off into separate
repositories.  In personal experience, spin-off projects are moved
from /trunk into some new directory, possibly also in trunk.  The
files are then modified there.  To preserve full history, I plan to
fork the full Git repository and follow Michaelangelo's advice: carve
away everything that isn't the project.  Better plans are welcome.

Subversion can tag subdirectories within trunk.  After all, tags are
just directory copies.  Git cannot.  Subversion tags are translated to
Git by tagging HEAD at the relative moment when the Subversion tree
has been tagged.  Is there a better way to do this?

=head1 BUGS

Snerp Vortex is early beta quality.  It seems to work in limited
tests, but there's no guarantee it will work for you.  Fixes are
greatly appreciated.

=head1 SEE ALSO

L<SVN::Dump> - Subversion dumps are parsed by SVN::Dump.

snanalyze - Analyze a Subversion dump, and produce an index database
for other tools to process.

snassign-auto - Automatically assign tags and branches to a snanalyze
index.

snassign-gui - Graphical snanalyze index browser.  Future plans will
allow users to assign branches and tags by hand.  Requires Gtk.

snauthors - Extract a basic authors.txt file from a Subversion dump.

snerp - Convert a Subversion repository to a flat filesystem or Git.
Uses the snanalyze index, with help from the snassign tools, to
intelligently branch and tag as it goes.

=head1 AUTHORS AND LICENSE

Snerp Vortex is Copyright 2010 by Rocco Caputo and contributors.

It is released under the same terms as Perl itself.

=cut
