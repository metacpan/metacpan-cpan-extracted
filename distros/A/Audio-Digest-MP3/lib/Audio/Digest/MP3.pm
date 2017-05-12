package Audio::Digest::MP3;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = 0.10;
our @EXPORT_OK = qw(format_time digest_frames);
our @ISA = 'Exporter';

use MPEG::Audio::Frame;
use Digest;
use Carp;

sub scan {
    my $class = shift;
    my $file = shift;
    my $ctx = Digest->new(shift || 'MD5');
    open my($fh), "<", $file or croak "Can't open file \"$file\": $!";
    binmode $fh;
    my $frames = 0;
    my $seconds = 0;
    my $bytes = 0;
    my %histogram;
    while(my $frame = MPEG::Audio::Frame->read($fh)){
        $ctx->add($frame->asbin);
        $frames++;
        $seconds += $frame->seconds;
        $bytes += length $frame->asbin;
        $histogram{$frame->bitrate}++;
    }
    return bless [ $ctx->hexdigest, $seconds, $frames, $bytes, \%histogram ], $class;
}

use overload '""' => \&digest;
sub digest  { shift->[0] };
sub seconds { shift->[1] };
sub frames  { shift->[2] };
sub bytes   { shift->[3] };
sub histogram { shift->[4] };
sub cbr { 1 == keys %{&histogram} }
sub vbr { 1 < keys %{&histogram} }

sub bitrate {
    my $self = shift;
    my $seconds = $self->seconds or return undef;
    if($self->cbr) { return +(keys %{$self->histogram})[0] }
    (my $bitrate = sprintf "%.1f", ($self->bytes/$seconds)*8/1000) =~ s/\.0//;
    return $bitrate;
}

sub playing_time {
    my $seconds = (shift)->seconds;
    return format_time($seconds, @_);
}

sub format_time {
    my $seconds = shift;
    my $digits = shift;
    local *_ = \$seconds;
    if(defined $digits) {
        my $abbrev = $digits =~ s/^-//;
        $_ = sprintf "%.$digits\Ef", $_;
        s/\.?0+$// if $abbrev;
    }
    s<^(\d+)>{
        $1 < 3600 ?
        sprintf "%d:%02d", $1 / 60, $1 % 60
        : sprintf "%d:%02d:%02d", $1 / 3600, int($1 / 60) % 60, $1 % 60
      }e;
    return $_;
}

sub digest_frames {
    my $file = shift;
    my $ctx = Digest->new(shift || 'MD5');
    open my($fh), "<", $file or croak "Can't open file \"$file\": $!";
    binmode $fh;
    my @digest;
    while(my $frame = MPEG::Audio::Frame->read($fh)){
        $ctx->reset;
        $ctx->add($frame->asbin);
        push @digest, $ctx->hexdigest;
    }
    return wantarray ? @digest : \@digest;
}

1;

__END__

=head1 NAME

Audio::Digest::MP3 - Get a message digest for the audio stream out of an MP3 file (skipping ID3 tags)

=head1 SYNOPSIS

  use Audio::Digest::MP3;
  my $streaminfo = Audio::Digest::MP3->scan($filepath, 'MD5');
  printf "%s: %s (%s) %s\n", $file,
      $streaminfo->playing_time,
      $streaminfo->bitrate,
      $streaminfo->digest;


=head1 DESCRIPTION

Sometimes you want to know if you have duplicate MP3 files on your disks. But
as soon as you start editing the ID3 tags, the file contents changes, and you
can no longer trust a plain MD5 checksum on the file, nor the file size, to
compare them.

This module scans the MP3 file, only including the audio stream (undecoded!) to
calculate the message digest.

While it scans, it compiles more metadata about the file, such as playing time,
either in seconds or as formatted string, bitrate (in kbits/sec), stream size
in bytes, and whether the file is a CBR or a VBR file.

In short: lots of info that you can use to compare MP3 files, but excluding any
info coming out of the ID3 tags.

By default, it uses L<Digest::MD5|Digest::MD5> to calculate the digest, but if you specify
'SHA1' (or any other specifier for a message digest module, that is compatible
with L<Digest>) it'll use that instead.

It uses L<MPEG::Audio::Frame|MPEG::Audio::Frame>, a Pure Perl module, to extract
the stream from the file. Average processing speed on my computer is about 1-2MB/sec.

=head2 METHODS

=over

=item C<$info-E<gt>digest>

The message digest for the stream

=item C<my $info = Audio::Digest::MP3-E<gt>scan($filepath)>

=item C<my $info = Audio::Digest::MP3-E<gt>scan($filepath, 'MD5')>

=item C<my $info = Audio::Digest::MP3-E<gt>scan($filepath, 'SHA1')>

This class method scans the audio stream for an MP3 file, calculating its message
digest and various other meta data, and constructing a summary data structure
in the form of an object. When used as a string, this object returns the hex
digest string.

Default digest type is MD5.

=item C<$info-E<gt>seconds>

=item C<$info-E<gt>playing_time>

=item C<$info-E<gt>playing_time(0)>

=item C<$info-E<gt>playing_time(1)>

=item C<$info-E<gt>playing_time(-1)>

Get the playing time for an MP3 file, either as a number (C<seconds>) or as a time
formatted string (C<playing_time>). For the latter you can pass a parameter
specifying the number of decimals for roundoff of fractional seconds.
If this number is negative, trailing zeros as well (as a trailing decimal point)
are dropped. Default is C<-1>.

=item C<$info-E<gt>frames>

The integer number of audio frames

=item C<$info-E<gt>bytes>

The number of bytes in the audio stream.

=item C<$info-E<gt>bitrate>

Returns the average bitrate in kbits/sec. If the file is a CBR file, this is the
bitrate used for the file E<ndash> this value may be slightly different from the
quotient of stream size over playing time.

=item C<$info-E<gt>cbr>

=item C<$info-E<gt>vbr>

Returns a boolean on whether this file is a constant bitrate file, or a variable
bitrate file.


=back

=head2 PLANS FOR THE FUTURE

The basic idea is, if it ever becomes feasable, to add support for other compressed
audio file formats, for example for Ogg Vorbis under C<Audio::Digest::Ogg>, and
next, to provide a unifying interface as C<Audio::Digest>, that would figure out
by itself what kind of audio file it is, and which in turn invokes the proper
module to calculate its stream digest.

As things are looking now, I do not plan on ever adding support for DRM-infected files.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<MPEG::Audio::Frame>

L<Digest>


=head1 AUTHOR

Bart Lateur, E<lt>bartl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Bart Lateur

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
