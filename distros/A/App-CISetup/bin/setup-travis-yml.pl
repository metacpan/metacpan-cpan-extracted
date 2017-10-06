#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.10';

use App::CISetup::Travis::ConfigUpdater;

exit App::CISetup::Travis::ConfigUpdater->new_with_options->run;

# PODNAME: setup-travis-yml.pl

# ABSTRACT: Tool for managing .travis.yml files

__END__

=pod

=encoding UTF-8

=head1 NAME

setup-travis-yml.pl - Tool for managing .travis.yml files

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This script updates existing F<.travis.yml> files or creates a new one based
on various settings from the command line. It is mostly focused on configuring
Perl projects to work with the L<Perl Travis
Helpers|https://github.com/travis-perl/helpers> tools. It also reorders the
top-level keys in the YAML file and does some other minor cleanups.

=head1 GETTING STARTED

You can create a new file for a Perl build from scratch by running this script
with the C<--create> argument:

    $> setup-travis-yml.pl --dir . --create

If you want to update one or more existing files, don't pass C<--create>.

If you want email or slack notification you'll need to pass a few more
arguments:

    $> setup-travis-yml.pl \
           --github-user example \
           --slack-key o8PZMLqZK6uWVxyyTzZf4qdY \
           --email-address example@example.org

=head1 THE CONFIG

If there is an existing file, most of its config will be preserved. The
existing config is used as the guide for some decisions about what to update,
as detailed below. A newly created file will also follow this guide.

Here's a step-by-step guide to the generated Travis config and what it does:

=head2 C<sudo> and C<addons>

By default, C<sudo> will be disabled for the Travis run. This makes Travis
faster. However, if an existing C<before_install> or C<install> block invokes
C<sudo>, then sudo will be enabled.

When C<sudo> is disabled, the C<addons> block will be updated to include
C<aspell> and C<aspell-en> for the benefit of L<Test::Spelling>.

If C<sudo> is enabled, then you'll need to make sure your config installs any
Debian packages which are needed.

=head2 C<before_install>, C<install>, and C<script>

If this exists and does not mention either C<travis-perl> (the new name) or
C<perl-travis-helper> (the old name), then these blocks will be left as-is.

If the travis-perl helpers I<are> referenced, the following updates are done:

If the C<script> block is more than 3 lines long I<and> either the C<install>
block is longer than 2 lines I<or> the C<install> block does not contain a
call to the travis-perl C<cpan-install>, then the C<before_install> block is
updated to include these lines:

    - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
    - source ~/travis-perl-helpers/init

If there are existing travis-perl C<clone> and C<source> lines, these will be
replaced with the two lines above. Otherwise these two lines will be inserted
at the beginning of the block.

This is how you would start using the travis-perl helpers in the non-auto
(long) config.

If the C<script> and C<install> blocks don't match the aforementioned
conditions, then the C<instal> and C<script> blocks are deleted entirely and
the C<before_install> block is updated to contain this line:

    - eval $(curl https://travis-perl.github.io/init) --auto --always-upgrade-modules

If there is an existing travis-perl C<eval> line, this will be replaced with
the line above. Otherwise this line will be inserted at the beginning of the
block.

=head2 C<perl> and C<matrix>

The C<perl> block will be updated based on the following rules:

If your distro does not have XS and you did not force the use of threaded
Perls, then you get a block like this:

    perl:
      - blead
      - dev
      - '5.26'
      - '5.24'
      - '5.22'
      - '5.20'
      - '5.18'
      - '5.16'
      - '5.14'

If the distro has XS code or you pass the C<--force-threaded-perls>
command line argument, then you will get a block with every Perl from 5.14 to
the latest stable release, plus dev and blead, in both threaded and unthreaded
forms. This will look something like this:

    perl:
      - blead
      - blead-thr
      - dev
      - dev-thr
      - 5.26.0
      - 5.26.0-thr
      - 5.24.1
      - 5.24.1-thr
      - 5.22.3
      - 5.22.3-thr
      - 5.20.3
      - 5.20.3-thr
      - 5.18.3
      - 5.18.3-thr
      - 5.16.3
      - 5.16.3-thr
      - 5.14.4
      - 5.14.4-thr

In either case, you will also get a C<matrix> block that is configured to
allow failures for all blead runs. It will also include a run with
C<COVERAGE=1> in the environment against the latest stable Perl version, so
something like this:

    matrix:
      allow_failures:
        - perl: blead
      include:
        - env: COVERAGE=1
          perl: '5.26'

=head2 C<env.global>

This script will ensure that C<env.global> sets both C<RELEASE_TESTING=1> and
C<AUTHOR_TESTING=1>, in addition to any other variables you have listed. It
will also sort the entries in this block.

=head2 C<notifications>

If you pass an C<--email-address> or C<--slack-key> command line argument,
then this block will be updated. For email, notifications will be sent on all
failures and on changes.

If you pass a slack key the C<travis> command line tool will be executed to
encrypt the key and it will be added to the config. If you have an existing
secure key it will not be updated, because the C<travis> tool generates a new
encrypted key every time it's invoked, leading to annoying churn.

=head2 C<__app_cisetup__> comment

This saves any flags you pass on the command line. Future runs of this script
will use these flags. However, CLI flags will always take precedence over
these.

=head1 ARGUMENTS

This script accepts the following command line arguments:

=head2 --create

Create a new file instead of updating existing ones.

=head2 --dir

The directory under which to look for F<.travis.yml> files. This does a
recursive search so you can update many projects at once. In create mode it
will only create a file in the current directory.

This is required.

=head2 --force-threaded-perls

Force the inclusion of both threaded and unthreaded Perls in the generated
config, regardless of whether the distro has XS or not.

=head2 --perl-caching

If this is true, then a C<cache> block will added to cache the C<$HOME/perl5>
directory. In addition, the travis-perl C<init> call will be updated to add
C<--always-uprade-modules>.

Caching is enabled for Perl projects by default, but you can disable this by
passing C<--no-perl-caching>.

=head2 --slack-key

A Slack key to use for Slack notifications. If you pass this you must also
pass C<--github-user>.

You'll need to have the Travis CLI installed. On a linux box this would be
something like

    $> sudo apt-get install ruby1.9.1-dev
    $> sudo gem install travis -v 1.8.2 --no-rdoc --no-ri

=head2 --github-user

Your github user name. This is required if you pass C<--slack-key>.

=head2 --email-address

The email address to which notifications should be sent. This is optional, and
if you don't provide it, then no notification emails will be configured (but
the default Travis notifications will still be in place).

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-CISetup/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
