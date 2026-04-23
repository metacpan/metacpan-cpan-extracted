package App::DrivePlayer;

use strict;
use warnings;

our $VERSION = '0.2.7';

1;

__END__

=head1 NAME

App::DrivePlayer - GTK3 music player for Google Drive

=head1 VERSION

0.2.7

=head1 DESCRIPTION

App::DrivePlayer is a GTK3 desktop application that streams audio files stored
in Google Drive.  It maintains a local SQLite library of scanned folders and
tracks, and can sync metadata to and from a Google Spreadsheet for use across
multiple devices.

See L<App::DrivePlayer::GUI> for the main entry point, or run the installed
C<drive_player> script.

=head1 AUTHOR

Robin Murray <mvsjes@cpan.org>

=head1 LICENSE

MIT

=cut
