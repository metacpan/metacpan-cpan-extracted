package App::XMMS2::Notifier;
use 5.014000;
use strict;
use warnings;
our $VERSION = 0.001002;

use Audio::XMMSClient 0.03;
use Gtk2::Notify 0.05 -init,'xmms2-notifyd';

use constant CONVERSION_SPECIFIERS => qw/bitrate date sample_format url id channels samplerate tracknr genre artist album title/;

##################################################

my $format;
my $xmms = Audio::XMMSClient->new('xmms2-notifyd');
my $notify = Gtk2::Notify->new('');

$notify->set_timeout(3000);

##################################################

sub notify_libnotify{
	$notify->update($_[0]);
	$notify->show;
}

sub notify{
	my ($id, $minfo);
	eval {
		$id=$xmms->playback_current_id->wait->value or return;
		$minfo=$xmms->medialib_get_info($id)->wait->value;
	} or return;

	my %metadata = map { $_ => exists $minfo->{$_} ? (values %{$minfo->{$_}})[0] : undef } CONVERSION_SPECIFIERS;
	my $str=$format;
	$str =~ s/\$$_/$metadata{$_}/gs for keys %metadata;

	notify_libnotify $str
}

sub on_playback_current_id {
	notify;
	$xmms->broadcast_playback_current_id->notifier_set(\&on_playback_current_id);
}

sub on_playback_status {
	notify if $xmms->playback_status->wait->value == 1; # 1 means playing, 2 means paused
	$xmms->broadcast_playback_status->notifier_set(\&on_playback_status);
}

sub run {
	$format = $_[0];
	while (1) {
		last if ($xmms->connect);
		sleep 1
	}

	$xmms->broadcast_playback_current_id->notifier_set(\&on_playback_current_id);
	$xmms->broadcast_playback_status->notifier_set(\&on_playback_status);
	$xmms->loop
}

1;
__END__

=head1 NAME

App::XMMS2::Notifier - script which notifies you what xmms2 is playing

=head1 SYNOPSIS

  # Shows libnotify notifications e.g. "Silence - Cellule"
  xmms2-notifier

  # Shows libnotify notifications e.g. "Cellule by Silence (L'autre endroit), year 2005, genre Electro"
  xmms2-notifier --format="$title by $artist ($album), year $date, genre $genre"

=head1 DESCRIPTION

xmms2-notifier is a script which shows libnotify notifications when
the song is changed and when the playback is started/resumed.

You can control the notification format with the B<--format> argument.
The following strings are replaced:

=over

=item $bitrate

The song bitrate, in bits/s. Example: 785104

=item $date

Usually the year the song was published. Example: 2005

=item $sample_format

The format of each sample. Example: S16

=item $url

An URL that points to the song. Example: file:///ext/Music/Silence+-+Cellule.flac

=item $id

The XMMS2 id of the song. Example: 498

=item $channels

The number of channels the song has. Example: 2

=item $samplerate

The sample rate of the song, in Hz. Example: 44100

=item $tracknr

The track number in the album. Example: 1

=item $genre

The genre of the song. Example: Electro

=item $artist

The artist/band. Example: Silence

=item $album

The album the song is from. Example: L'autre endroit

=item $title

The song title. Example: Cellule

=back

=head1 SEE ALSO

L<xmms2(1)>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
