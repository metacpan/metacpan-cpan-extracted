#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.11';

use App::CISetup::AppVeyor::ConfigUpdater;

exit App::CISetup::AppVeyor::ConfigUpdater->new_with_options->run;

# PODNAME: setup-appveyor-yml.pl

# ABSTRACT: Tool for managing appveyor.yml files

__END__

=pod

=encoding UTF-8

=head1 NAME

setup-appveyor-yml.pl - Tool for managing appveyor.yml files

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This script updates existing appveyor.yml files with various settings from the
command line. Currently all this does is update the notifications block for
Slack and email notifications.  It also reorders the top-level keys in the
YAML file and does some other minor cleanups.

=head1 GETTING STARTED

You can create a new file for a Perl build from scratch by running this script
with the C<--create> argument:

    $> setup-appveyor-yml.pl --dir . --create

If you want to update one or more existing files, don't pass C<--create>.

If you want email or slack notification you'll need to pass a few more
arguments:

    $> setup-appveyor-yml.pl \
           --encrypted-slack-key o8PZMLqZK6uWVxyyTzZf4qdY \
           --email-address example@example.org

=head1 THE CONFIG

If there is an existing file, most of its config will be preserved. The
existing config is used as the guide for some decisions about what to update,
as detailed below. A newly created file will also follow this guide.

Here's a step-by-step guide to the generated Travis config and what it does:

=head2 C<skip_tags>

This will be set to true for newly created files.

=head2 C<cache>

This will be set to C<C:\strawberry> for newly created files.

=head2 C<install>

For new files this will contain the following commands:

    - if not exist "C:\strawberry" cinst strawberryperl -y
    - set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%
    - cd C:\projects\%APPVEYOR_PROJECT_NAME%
    - cpanm --installdeps . -n

=head2 C<build_script>

This will contain one command, C<perl -e 1>, for newly created files.

=head2 C<test_script>

This will contain one command, C<prove -lrv t/>, for newly created files.

=head2 C<notifications>

If you pass an C<--email-address> or C<--slack-key> command line argument,
then this block will be updated. For email, notifications will be sent on all
failures and on status changes.

If you pass an encrypted slack key then notifications will be delivered via
Slack on all failures and on status changes.

=head2 C<__app_cisetup__> comment

This saves any flags you pass on the command line. Future runs of this script
will use these flags. However, CLI flags will always take precedence over
these.

=head1 ARGUMENTS

This script accepts the following command line arguments:

=head2 --create

Create a new file instead of updating existing ones.

=head2 --dir

The directory under which to look for F<appveyor.yml> files. This does a
recursive search so you can update many projects at once. In create mode it
will only create a file in the current directory.

This is required.

=head2 --encrypted-slack-key

A Slack key to use for Slack notifications. If you pass this you must also
pass C<--slack-channel>.

You can generate an encrypted key from the AppVeyor website.

=head2 --slack-channel

The Slack channel to notify. If you pass this you must also pass
C<--encrypted-slack-key>.

=head2 --email-address

The email address to which notifications should be sent. This is optional, and
if you don't provide it, then no notification emails will be configured (but
the default AppVeyor notifications will still be in place).

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
