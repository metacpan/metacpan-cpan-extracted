# -*- mode: perl -*-
#
# $Id: Header.pm,v 1.2 2001/01/07 04:09:12 tai Exp $
#

package Audio::SoundFile::Header;

=head1 NAME

 Audio::SoundFile::Header - Interface to handle sound format information

=head1 SYNOPSIS

 use Audio::SoundFile::Header;

 $header = new Audio::SoundFile::Header(
    samplerate  => 44100,
    channels    => 1,
    format      => SF_FORMAT_WAV | SF_FORMAT_PCM,
 );

 die "Invalid format information" unless $header;
 die "Invalid format information" unless $header->set(channels => 2);
 die "Invalid format information" unless $header->format_check;

=head1 DESCRIPTION

This module provides abstract interface to handle sound format
information. It manages format information defined by sndfile.h
in libsndfile library.

Currently, following methods are provided:

=over 4

=cut

use Exporter;
use DynaLoader;

use strict;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = (split(/\s+/, q$Revision 1.1$))[1] / 10;
@ISA     = qw(DynaLoader Exporter);
@EXPORT  = qw(
    SF_FORMAT_WAV
    SF_FORMAT_AIFF
    SF_FORMAT_AU
    SF_FORMAT_RAW
    SF_FORMAT_PAF
    SF_FORMAT_SVX
    SF_FORMAT_NIST
    SF_FORMAT_VOC
    SF_FORMAT_IRCAM
    SF_FORMAT_W64
    SF_FORMAT_MAT4
    SF_FORMAT_MAT5
    SF_FORMAT_PVF
    SF_FORMAT_XI
    SF_FORMAT_HTK
    SF_FORMAT_SDS
    SF_FORMAT_AVR
    SF_FORMAT_WAVEX
    SF_FORMAT_SD2
    SF_FORMAT_FLAC
    SF_FORMAT_CAF
    SF_FORMAT_PCM_S8
    SF_FORMAT_PCM_16
    SF_FORMAT_PCM_24
    SF_FORMAT_PCM_32
    SF_FORMAT_PCM_U8
    SF_FORMAT_FLOAT
    SF_FORMAT_DOUBLE
    SF_FORMAT_ULAW
    SF_FORMAT_ALAW
    SF_FORMAT_IMA_ADPCM
    SF_FORMAT_MS_ADPCM
    SF_FORMAT_GSM610
    SF_FORMAT_VOX_ADPCM
    SF_FORMAT_G721_32
    SF_FORMAT_G723_24
    SF_FORMAT_G723_40
    SF_FORMAT_DWvW_12
    SF_FORMAT_DWvW_16
    SF_FORMAT_DWvW_24
    SF_FORMAT_DWvW_N
    SF_FORMAT_DPCM_8
    SF_FORMAT_DPCM_16
    SF_ENDIAN_FILE
    SF_ENDIAN_LITTLE
    SF_ENDIAN_BIG
    SF_ENDIAN_CPU
    SF_FORMAT_SUBMASK
    SF_FORMAT_TYPEMASK
    SF_FORMAT_ENDMASK
);

bootstrap Audio::SoundFile::Header $VERSION;

sub SF_FORMAT_WAV   { 0x010000 }
sub SF_FORMAT_AIFF  { 0x020000 }
sub SF_FORMAT_AU    { 0x030000 }
sub SF_FORMAT_RAW   { 0x040000 }
sub SF_FORMAT_PAF   { 0x050000 }
sub SF_FORMAT_SVX   { 0x060000 }
sub SF_FORMAT_NIST  { 0x070000 }
sub SF_FORMAT_VOC   { 0x080000 }
sub SF_FORMAT_IRCAM { 0x0A0000 }
sub SF_FORMAT_W64   { 0x0B0000 }
sub SF_FORMAT_MAT4  { 0x0C0000 }
sub SF_FORMAT_MAT5  { 0x0D0000 }
sub SF_FORMAT_PVF   { 0x0E0000 }
sub SF_FORMAT_XI    { 0x0F0000 }
sub SF_FORMAT_HTK   { 0x100000 }
sub SF_FORMAT_SDS   { 0x110000 }
sub SF_FORMAT_AVR   { 0x120000 }
sub SF_FORMAT_WAVEX { 0x130000 }
sub SF_FORMAT_SD2   { 0x160000 }
sub SF_FORMAT_FLAC  { 0x170000 }
sub SF_FORMAT_CAF   { 0x180000 }

sub SF_FORMAT_PCM_S8    { 0x0001 }
sub SF_FORMAT_PCM_16    { 0x0002 }
sub SF_FORMAT_PCM_24    { 0x0003 }
sub SF_FORMAT_PCM_32    { 0x0004 }
sub SF_FORMAT_PCM_U8    { 0x0005 }
sub SF_FORMAT_FLOAT     { 0x0006 }
sub SF_FORMAT_DOUBLE    { 0x0007 }
sub SF_FORMAT_ULAW      { 0x0010 }
sub SF_FORMAT_ALAW      { 0x0011 }
sub SF_FORMAT_IMA_ADPCM { 0x0012 }
sub SF_FORMAT_MS_ADPCM  { 0x0013 }
sub SF_FORMAT_GSM610    { 0x0020 }
sub SF_FORMAT_VOX_ADPCM { 0x0021 }
sub SF_FORMAT_G721_32   { 0x0030 }
sub SF_FORMAT_G723_24   { 0x0031 }
sub SF_FORMAT_G723_40   { 0x0032 }
sub SF_FORMAT_DWvW_12   { 0x0040 }
sub SF_FORMAT_DWvW_16   { 0x0041 }
sub SF_FORMAT_DWvW_24   { 0x0042 }
sub SF_FORMAT_DWvW_N    { 0x0043 }
sub SF_FORMAT_DPCM_8    { 0x0050 }
sub SF_FORMAT_DPCM_16   { 0x0051 }

sub SF_ENDIAN_FILE      { 0x00000000 }
sub SF_ENDIAN_LITTLE    { 0x10000000 }
sub SF_ENDIAN_BIG       { 0x20000000 }
sub SF_ENDIAN_CPU       { 0x30000000 }

sub SF_FORMAT_SUBMASK  { 0x0000FFFF }
sub SF_FORMAT_TYPEMASK { 0x0FFF0000 }
sub SF_FORMAT_ENDMASK  { 0x30000000 }

=item $header = new Audio::SoundFile::Header(%format_info);

Constructor.

Returns a class instance which is initialized by given format
information. This automatically does sanity check of the info,
and returns undef if the format structure is invalid.

=cut
sub new {
    my $name = shift;
    my %parm = @_;
    my $self = bless { %parm }, $name;

    unless ($self->format_check) {
        $@ = "Insufficient header parameters";
        return undef;
    }
    return $self;
}

=item $value = $header->get($name);

Returns a value that corresponds with given parameter name.

=cut
sub get {
    my $self = shift || return undef;
    my $name = shift || return undef;

    return $self->{$name};
}

=item $value = $header->set($name => $value, $name => $value, ...);

Sets a value for given parameter name.

If new format structure is invalid (contradicting parameters, etc),
it discards all information passed, and returns an error. Original
structure is retained in that case.

Returns true on success, otherwise false.

=cut
sub set {
    my $self = shift || return undef;
    my %newp = @_;
    my %oldp;

    while (my($k, $v) = each %newp) {
        $oldp{$k} = $self->{$k}; $self->{$k} = $v;
    }
    return 1 if $self->format_check;

    while (my($k, $v) = each %oldp) {
        $self->{$k} = $v;
    }
    return 0;
}

=item $bool = $header->format_check;

Runs sanity check on the format structure.
Returns true if format is valid, otherwise false.

=back

=head1 AUTHORS / CONTRIBUTORS

Taisuke Yamada E<lt>tai@imasy.or.jpE<gt>

=head1 COPYRIGHT

Copyright (C) 2001. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
