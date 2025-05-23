# ABSTRACT: gimp build
package App::gimpgitbuild;
$App::gimpgitbuild::VERSION = '0.32.1';
use strict;
use warnings;

use App::Cmd::Setup -app;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App-gimpgitbuild - build GIMP from git

=head1 VERSION

version 0.32.1

=head1 SYNOPSIS

    gimpgitbuild build

=head1 DESCRIPTION

gimpgitbuild is a command line utility to automatically build
L<GIMP|https://www.gimp.org/> (= the "GNU Image Manipulation Program")
and some of its dependencies from its version control git repositories:
L<https://developer.gimp.org/git.html> .

Use it only if your paths and environment do not contain too many nasty
characters (such as whitespace, quotes, or backspace ) because we interpolate
strings into the shell a lot.

So far, it is quite opinionated, but hopefully we'll allow for better
customization using L<https://en.wikipedia.org/wiki/Environment_variable>
in the future.

=head2 HISTORY

This utility evolved from an L<old bash version|https://github.com/shlomif/shlomif-computer-settings/blob/db468a5d6190bce053af1621b30e7dfd673be43f/shlomif-settings/build-scripts/build/gimp-git-all-deps.bash>
and a L<rewrite in perl 5|https://github.com/shlomif/shlomif-computer-settings/blob/master/shlomif-settings/build-scripts/build/gimp-git-all-deps.pl> .

=head1 SEE ALSO

=over 4

=item * L<Shlomi Fish's Wrapper script/configuration|https://github.com/shlomif/shlomif-computer-settings/blob/master/shlomif-settings/home-bin-executables/bin/gimpgitbuild-runner--simplified-non-debug.bash>

=item * L<https://www.gimp.org/>

=back

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-gimpgitbuild>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-gimpgitbuild>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-gimpgitbuild>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-gimpgitbuild>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-gimpgitbuild>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::gimpgitbuild>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-gimpgitbuild at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-gimpgitbuild>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-gimpgitbuild>

  git clone git://github.com/shlomif/App-gimpgitbuild.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/App-gimpgitbuild/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
