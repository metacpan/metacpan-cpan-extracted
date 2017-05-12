package AudioCD::Mac;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Mac::Files;
require Exporter;
require DynaLoader;
@EXPORT = qw(CD_PLAY CD_PAUSE CD_MUTE CD_FINISH CD_ERR CD_STOP CD_OFFLINE);
@ISA = qw(Exporter DynaLoader);
$VERSION = '0.25';

bootstrap AudioCD::Mac $VERSION;

BEGIN {
    sub CD_PLAY    () { 0 }
    sub CD_PAUSE   () { 1 }
    sub CD_MUTE    () { 2 }
    sub CD_FINISH  () { 3 }
    sub CD_ERR     () { 4 }
    sub CD_STOP    () { 5 }
    sub CD_OFFLINE () { 6 }
}


sub new {
    my $cd = _GetDrive() or die $^E;
    my $self = bless({DRIVE=>$cd}, shift);
    return($self->cd_toc ? $self : undef);
}

sub volume {
    my($self, $vol_l, $vol_r) = @_;
    $vol_r = $vol_l if (!defined($vol_r) && defined($vol_l));
    if (defined($vol_l)) {
        _SetVolume($self->{DRIVE}, $vol_l, $vol_r);
    }
    my @vol = split /\t/, _GetVolume($self->{DRIVE});
    wantarray ? @vol : $vol[0] == $vol[1] ? $vol[0] : @vol;
}

sub play {
    my($self, $track) = @_;
    if ($self->status == 1 && !$track) {
        $self->continue;
    } else {
        $track ||= 1;
		_Stop($self->{DRIVE}, _fix_track($self->last_track)) or return;
        _Play($self->{DRIVE}, _fix_track($track));
    }
}

sub eject {
    my $self = shift;
    _Eject($self->{DRIVE});
}

sub pause {
    my $self = shift;
    _Pause($self->{DRIVE}, $self->status);
}

sub continue {
    my $self = shift;
    _Continue($self->{DRIVE}, $self->status);
}

sub stop {
    my $self = shift;
    _Stop($self->{DRIVE}, 0, 0);
}

sub status {
    my $self = shift;
    _Status($self->{DRIVE});
}

sub info {
    my $self = shift;
    map {_BCDToHex($_)} split("\t", _Info($self->{DRIVE}));
}

sub cddb_toc {
    my $self = shift;
    my $toc = $self->cd_toc() or return;
    my @toc;
    foreach (@$toc) {
        push @toc, sprintf "%d\t%d\t%d\t%d", @{$_}[0..3];
    }
    return @toc;
}

sub cd_toc {
    my $self = shift;
    my($toc, $leadin, @tocb, @tocf);
    $toc = _GetToc($self->{DRIVE}) or return;
    @tocb = split(/\n/, $toc);
    return if @tocb < 4;
    shift(@tocb);
    shift(@tocb);
    $leadin = shift(@tocb);
    $leadin =~ s/^-?\d+\t/999\t/;
    push(@tocb, $leadin);

    foreach my $entry (@tocb) {
        my(@t1, @t2);
        next if $entry =~ /-/;
        @t1 = split(/\t/, $entry);
        @t2 = map {_BCDToHex($_)} @t1;
        $t2[0] = 999 if $t1[0] == 999;
        next if $t1[0] == 0;
        push @tocf, [@t2];
    }
    return [@tocf];
}

sub last_track {
    my $self = shift;
    my $a = $self->cd_toc() or die $^E;
    my $i = -2;
    $i-- while $$a[$i]->[0] < 1;
    return $$a[$i]->[0];
}

sub _BCDToHex {
    my($value, $tens, $digits, $result) = ($_[0], 0, 0, 0);
    $value &= 0x00FF;
    $tens = $value >> 4;
    $digits = $value & 0x000F;
    if ($tens > 9 || $digits > 9) {
        $result = 0;
    } else {
        $result = 10*$tens + $digits;
    }
    return($result);
}

sub _HexToBCD {
    my($value, $result, $j, $i) = ($_[0], 0);
    if ($value <= 99 && $value > 0) {
        for ($j = 0, $i = 10; $i <= 100; $i+=10, $j++) {
            if ($i > $value) {
                $i -= 10;
                $value -= $i;
                $result = ($j << 4) | $value;
                last;
            }
        }
    }
    return($result);
}

sub _fix_track {unpack("s*", pack "l", _HexToBCD(shift))}

1;
__END__

=head1 NAME

AudioCD::Mac - MacPerl extension for controlling Audio CDs

=head1 SYNOPSIS

    #!perl -w
    use AudioCD;
    use strict;
    my $cd = new AudioCD;

    $cd->volume(255);
    $cd->play(2);
    print "Now playing\n" if $cd->status == CD_PLAY;
    printf "Volume is %d\n", $cd->volume;
    sleep(5);

    $cd->pause;
    print "Now paused\n" if $cd->status == CD_PAUSE;
    sleep(5);

    $cd->volume(100);
    $cd->continue;
    print "Now playing\n" if $cd->status == CD_PLAY;
    printf "Volume is %d\n", $cd->volume;
    sleep(5);

    my @info = $cd->info;
    printf "Currently at track %d, %.2d:%.2d\n", @info[0..2];

    $cd->stop;
    my $status = $cd->status;
    print "Now stopped\n" if
        ($status == CD_FINISH || $status == CD_STOP);

    if (do 'CDDB.pm') {  # sold separately
        my $cddb = new CDDB;
        my @cddb_info = $cddb->calculate_id( $cd->cddb_toc );
        my @discs = $cddb->get_discs(@cddb_info[0, 3, 4]);
        print "You were probably listening to $discs[0]->[2]\n";
    }

    $cd->eject;


=head1 DESCRIPTION

This is the MacPerl module to be used by the C<AudioCD> module.  Other
modules can be written for other platforms, but this one is Mac specific,
calling Mac OS APIs to control the CD player.

=head1 FUNCTIONS

All functions except for C<new> are methods that need to be called
via the C<AudioCD> object.  All functions attempt to return C<undef>
and set C<$^E> on failure, and unless otherwise specified, return C<1>
on success.

Note that the data returned from the Mac OS APIs is often in BCD format,
but the functions that return track and time data convert it to
decimal.


=over 4

=item new

Should be called from C<AudioCD>, not C<AudioCD::Mac>, but should work
either way.  Returns the object.


=item status

Returns the current status of the CD, one of:
CD_PLAY, CD_PAUSE, CD_MUTE, CD_FINISH, CD_ERR, CD_STOP, CD_OFFLINE.


=item info

Returns an array of information about the CD, with two sets of times,
one for the current track, one for the disc.  The first item in the list
is the current track number.

    #  0          1       2        3         4       5        6
    ($t_number, $t_min, $t_sec, $t_frames, $a_min, $a_sec, $a_frames)
        = $cd->info;


=item play([TRACK])

If called without a track number, will start from the first track if stopped,
or continue if paused.  Otherwise will start at specified track number, and
continue until the CD is finished.


=item stop

Stops the CD.  Time settings will likely be left at last play point, not at
beginning of CD.


=item pause

Will pause the CD if it is playing, or continue playing if paused.


=item continue

Will continue playing if paused.


=item eject

Will unmount the volumes on the drive if any, and then eject the tray.


=item volume([LEFT_VOLUME [, RIGHT_VOLUME]])

Sets the left and right channels to a valume from 0 to 255.  Returns the
left and right channel volumes, unless the two have the same value and the 
method is called in a scalar context, in which case it returns just
one value.

If C<RIGHT_VOLUME> is not supplied, it will be set to the same value as
supplied in C<LEFT_VOLUME>.  If not values are supplied, the current volume
value(s) will be returned, and will remain unchanged.


=item cd_toc

Returns the table of contents in an anonymous array, where each
element is another anonymous array, containing the track number [0]
and the track's starting time offset from the beginning of the CD
in minutes [1], seconds [2], and frames [3].

=item cddb_toc

Returns the same as above, but in a format suitable for passing to
the C<CDDB> module.

=item last_track

Ideally, returns the last audio track number on the CD.  If this
turns out to be wrong, let me know.

=back


=head1 TODO

=over 4

=item Change interface to work well with others (Tuomas' Linux code)

=item Add support for multiple drives, multiple volumes on drive

=item Add support for moving forward/backward in tracks, and scanning

=item Add support for modes (stereo/mono/etc., random/program/repeat/etc.)

=item Add support to add/extract data in the CD Remote Programs file

=item Need good test suite ... don't know how this should work, since
I won't have good data to test against.  Maybe I should just play some
tracks, change the volume, print out the number of tracks and have the
user say whether or not it passes.

=back


=head1 AUTHOR

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself.  Please see the Perl Artistic License.

Special thanks to Matthias Neeracher for help with MacPerl XS and C,
and Glenn Howes E<lt>grhowes@kagi.comE<gt> for his code examples that helped
me understand this stuff.

    http://www.xnet.com/~grhowes/html/helpful.html

For more info, check out Technote DV22:

    http://developer.apple.com/technotes/dv/dv_22.html

=head1 HISTORY

=over 4

=item v0.25, Thursday, December 11, 1998

Significant clean up of Perl and XS code, lots of misc. changes.

Hopefully fixed C<cd_toc> to give all the right values.

Fixed C<eject> problems.

   "no pointer is a pointer, too" -- Matthias Neeracher

=item v0.20, Wednesday, December 9, 1998

Renamed to C<AudioCD>, added controls for Audio CD.

=item v0.10, Thursday, October 8, 1998

First version, made for Mac OS to get CDDB TOC data.

=back

=head1 VERSION

v0.25, Thursday, December 11, 1998


=head1 SEE ALSO

CDDB.pm.

=cut
