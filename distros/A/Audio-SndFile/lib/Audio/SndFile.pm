# Audio::SndFile - perl glue to libsndfile
#
# Copyright (C) 2006 by Joost Diepenmaat, Zeekat Softwareontwikkeling
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package Audio::SndFile;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
our $VERSION = '0.09';
use Fcntl;
require XSLoader;
XSLoader::load('Audio::SndFile', $VERSION);

use Audio::SndFile::Constants qw(:all);


my %constanttoname;
for (@Audio::SndFile::Constants::FORMAT_TYPES, @Audio::SndFile::Constants::FORMAT_SUBTYPES, @Audio::SndFile::Constants::ENDIANNESS) {
    no strict 'refs';
    my $c = eval { &{"Audio::SndFile::$_"} };
    if (!$@) {
        $constanttoname{$c} = $_;
    }
}

my %filehandles = ();

sub open {
    my ($class,$mode,$filename,@args) = @_;
    my $nmode;
    my $auto_close_fh = 0;
    if ($mode eq '<') {
        $nmode = SFM_READ;
    }
    elsif ($mode eq '>') {
        $nmode = SFM_WRITE;
    }
    elsif ($mode eq "+<") {
        $nmode = SFM_RDWR;
    }
    my $info;
    if (@args == 1) {
        $info = $args[0];
    }
    else {
        $info = Audio::SndFile::Info->new();
        while (@args) {
            my ($name,$value) = splice @args,0,2;
            $info->$name($value);
        }
    }
    if ($nmode == SFM_WRITE && ! $info->format_check()) {
        croak "Invalid format for writing";
    }
    elsif ($nmode == SFM_WRITE && ! $info->samplerate) {
      croak "No samplerate specified";
    }
    my $fh;
    if (ref $filename) {
        $fh = $filename;
    }
    else {
        open $fh,$mode,$filename or croak "Can't open $filename with mode $mode: $!";
        $auto_close_fh = 0;
    }
    my $fn = fileno($fh);
    if (! defined($fn)) {
        croak "Cannot get a fileno from filehandle.";
    }
    my $self = $class->open_fd(fileno $fh,$nmode,$info,$auto_close_fh);
    $filehandles{$self} = $fh; # store $fh to prevent it from being closed at the end of scope.
    $self;
}

sub DESTROY {
    my $self = shift;
    $self->close();
    delete $filehandles{$self};
}


for my $s (qw(type subtype frames channels endianness samplerate seekable sections)) {
    no strict 'refs';
    *{$s} = sub {
        my $self = shift;
        $self->info->$s();
    }
}

for my $s (qw(title copyright software artist comment date)) {
  no strict 'refs';
  *{$s} = sub {
    my $self = shift;
    my $method = @_ ? "set_$s" : "get_$s";
    $self->$method(@_);
  };
}

my %pack = (
   short => "s",
   'int' => "i",
   float => "f",
   double => "d",
);
 
for my $type (keys %pack) {
    no strict 'refs';
    *{"unpack_$type"} = sub {
        my ($self,$len) = @_;
        my $meth = "read_$type";
        my $buff = "";
        my $reallen = $self->$meth($buff,$len);
        return unpack "$pack{$type}$reallen",$buff;
    };
    *{"unpackf_${type}"} = sub {
        my ($self,$len) = @_;
        my $meth = "readf_${type}";
        my $buff = "";
        my $reallen = $self->$meth($buff,$len);
        my $packlen = $reallen * $self->channels;
        return unpack "$pack{$type}$packlen",$buff;
    };
    *{"pack_$type"} = sub {
        my $self = shift;
        my $len = @_;
        my $buff = pack "$pack{$type}$len",@_;
        my $meth = "write_${type}";
        $self->$meth($buff);
    },
    *{"packf_$type"} = sub {
        my $self = shift;
        my $len = @_;
        my $buff = pack "$pack{$type}$len",@_;
        my $meth = "writef_${type}";
        $self->$meth($buff);
    },
 
}

sub clipping {
    my $self = shift;
    @_ ? $self->set_clipping(@_) : $self->get_clipping;
}


package Audio::SndFile::Info;
use Audio::SndFile::Constants ":all";
use Carp qw(croak);

for (qw(samplerate channels format)) {
    my $get = "get_$_";
    my $set = "set_$_";
    no strict 'refs';
    *{$_} = sub {
        my $self = shift;
        if (@_) {
            $self->$set(@_);
        }
        else {
            $self->$get();
        }
    };
}

sub type {
    my $self = shift;
    my $format = $self->get_format;
    if (@_) {
        my $type = shift;
        $format &= ~ SF_FORMAT_TYPEMASK;
        my $constname = "SF_FORMAT_\U$type";
        no strict 'refs';
        $format |= &$constname();
        $self->set_format($format);
    }
    else {
        my $type = $format & SF_FORMAT_TYPEMASK;
        my $constname = $constanttoname{$type} || croak "Uknown type $type";
        $constname =~ s/SF_FORMAT_//;
        lc($constname);
    }
}

sub subtype {
    my $self = shift;
    my $format = $self->get_format;
    if (@_) {
        my $type = shift;
        $format &= ~ SF_FORMAT_SUBMASK;
        my $constname = "SF_FORMAT_\U$type";
        no strict 'refs';
        $format |= &$constname();
        $self->set_format($format);
    }
    else {
        my $type = $format & SF_FORMAT_SUBMASK;
        my $constname = $constanttoname{$type} || croak "Uknown subtype $type";
        $constname =~ s/SF_FORMAT_//;
        lc($constname);
    }
}

sub endianness {
    my $self = shift;
    my $format = $self->get_format;
    if (@_) {
        my $type = shift;
        $format &= ~ SF_FORMAT_ENDMASK;
        my $constname = "SF_ENDIAN_\U$type";
        no strict 'refs';
        $format |= &$constname();
        $self->set_format($format);
    }
    else {
        my $type = $format & SF_FORMAT_ENDMASK;
        my $constname = $constanttoname{$type} || croak "Uknown endianness $type";
        $constname =~ s/SF_ENDIAN_//;
        lc($constname);
    }
}



1;

__END__

=head1 NAME

Audio::SndFile - Portable reading and writing of sound files

=head1 SYNOPSIS

  use Audio::SndFile;

  my $f = Audio::SndFile->open("<","audiofile.wav");
  my $g = Audio::SndFile->open(">","audiofile.au", type => 'au', 
          subtype => 'pcm_16', channels => 1, endianness => 'file');

  my $buffer = "";
  while ($f->read_int($buffer,1024)) {
     $g->write_int($buffer);
  }

=head1 DESCRIPTION

Audio::SndFile is a perl interface to the sndfile (soundfile) library and provides a portable
API for reading and writing sound files in different formats.

=head1 Reading & Writing

=head2 Constructor

 my $sndfile = Audio::SndFile->open($mode, $file, %options);

Creates an Audio::SndFile object from a file specification.

$mode can be "<" (read), ">" (write) or "+<" (read/write)

$file is a filehandle or filename.

=head3 %options

A list of name => value pairs. All required when reading raw data.
Most are required when opening a file write-only.

=over 4

=item type

The major filetype. Required when opening a file write-only.

=item subtype

The representation of data in the file. Required when opening a file write-only.

=item channels

The number of channels. Required when opening a file write-only.

=item endianness

The endianness of the data in the file.

=item samplerate

The samplerate for this file.

=back

The available values for type, subtype and endianness are listed in L</FORMATS>.

Examples:

 # open for reading; no options are needed for non-raw
 # soundfiles:

 my $infile = Audio::SndFile->open("<","/tmp/test.wav");

 # open for writing, you need type, subtype & channels options:
 
 my $outfile = Audio::SndFile->open(">","/tmp/out.wav",
                                    type     => "wav",
                                    subtype  => "pcm_16",
                                    channels => 2);

=head2 Audio info

Information about the sound data is available from the Audio::SndFile object.

 my $type       = $sndfile->type;
 my $subtype    = $sndfile->subtype;
 my $endianness = $sndfile->endianness;
 my $channels   = $sndfile->channels;
 my $samplerate = $sndfile->samplerate;

These are the same as the L<open() options|%options>. The following
are also available:

 my $sections   = $sndfile->sections;   # number of sections
 my $bool       = $sndfile->seekable;   # is this stream/file seekable
 my $frames     = $sndfile->frames;     # number of frames

See also L</FORMATS> and L</Meta info>.

=head2 Meta info

Additional metadata

 my $title     = $sndfile->title();
 my $copyright = $sndfile->copyright();
 my $software  = $sndfile->software();
 my $artist    = $sndfile->artist();
 my $comment   = $sndfile->comment();
 my $date      = $sndfile->date();

Read metadata from $sndfile. When given an argument, set the metadata
on a $sndfile:

 $sndfile->title($title);
 $sndfile->copyright($copyright);
 # etc.

These methods are not supported for all filetypes.

=head2 Read audio data

 my $numsamples = $sndfile->read_TYPE($buffer,$num);

 my $numframes  = $sndfile->readf_TYPE($buffer,$num);

Read max $num samples (single values) or frames (interleaved values; one value for
each channel) from $sndfile into $buffer as a packed
string of native endianness. TYPE may be one of "short", "int", "float" or
"double". Values will be converted if necessary.

Returns the number of samples / frames read. $buffer will be shrunk
or grown accordingly.

 my @values = $sndfile->unpack_TYPE($num);
 my @values = $sndfile->unpackf_TYPE($num);

Same as read_TYPE and readf_TYPE, but returns the values as a list of
scalars.

=head2 Write audio data

 my $num = $sndfile->write_TYPE($buffer);
 my $num = $sndfile->writef_TYPE($buffer);

Write $buffer with packed samples or frames to $sndfile. TYPE may be one of
"short", "int", "float" or "double". Returns the number of frames / samples
written.

 my $num = $sndfile->pack_TYPE(@values);
 my $num = $sndfile->packf_TYPE(@values);

Same as write_TYPE and writef_TYPE but these take a list of values instead of
a packed string.

=head1 Other file operations

=head2 Seek

 $sndfile->seek($offset, $whence);

Seek to frame $offset. See also L<Fcntl> and L<perlfunc/seek>.

=head2 Sync

 $sndfile->write_sync();

Flush data to disk if $sndfile is opened for writing. This function
is not available in libsndfile prior to 2006-07-31 / release 1.0.17.

You can use C<< $sndfile->can('write_sync') >> to test for it.

=head2 Truncate

 $sndfile->truncate($number_of_frames);

Truncate file to $number_of_frames.

Implemented via sf_command().

=head1 Conversion parameters

=head2 Clipping

 $sndfile->clipping($bool);
 my $bool = $sndfile->clipping;

Get or set automatic clipping for float -> integer conversions.

Implemented via sf_command().

=head1 Other methods  

=head2 Errors

Most methods throw an exception on error, but if you need to know:

 my $enum    = $sndfile->error;
 my $estring = $sndfile->strerror;

Return the last error as a number or string.

=head2 lib_version

 my $libsndfile_version = Audio::SndFile::lib_version;

Version of the libsndfile library linked by the module.

Implemented via sf_command().

=head1 FORMATS

The exact list of supported file types is dependend on your libsndfile version.
When building this module it tries to figure out which types are available.
File types that are not supported by your libsndfile at the time of building this
module will not be available. In other words: recompile this module after
upgrading your libsndfile.

Supported file types (when available) in this version of Audio::SndFile are:

wav, aiff, au, raw, paf, svx, nist, voc, ircam, w64, mat4, mat5, pvf, xi, htk, 
sds, avr, wavex, sd2, flac, caf.

Supported subtypes are:

pcm_s8, pcm_16, pcm_24, pcm_32, pcm_u8, float, double, ulaw, alaw, ima_adpcm,
ms_adpcm, gsm610, vox_adpcm, g721_32, g723_24, g723_40, dwvw_12, dwvw_16, dwvw_24,
dwvw_n, dpcm_8, dpcm_16.

These map to SF_FORMAT_$type in the C API.

See L<http://www.mega-nerd.com/libsndfile/api.html#open> for the description of
each (sub)type.

The following endianness specifications are supported:

file, big, little, cpu.

These map to SF_ENDIAN_$endianness in the C API.

Note that not all combinations of type, subtype and endianness are supported.
See also L<http://www.mega-nerd.com/libsndfile/#Features>.

=head1 SF_COMMAND, LIBSNDFILE VERSIONS & API CHANGES

As noted in L</FORMATS>, the supported file formats are dependent on the
version of libsndfile that is installed I<at the time of building this module>.

This is also true for the methods implemented via sf_command() and the 
write_sync() method. Available methods are detected by Makefile.PL at build time.

Methods implemented via sf_command() are noted in the documentation. Other
methods, except for write_sync() should be available everywhere, since this
module won't build if they're not available.

=head1 BUGS & ISSUES.

Currenly there are no I<known> bugs, but this code is new and not very well
tested.

This module does not implement the full libsndfile API. Notably missing are
most of the sf_command() calls. They will be implemented later.

There is currently no way to read seperate channels into seperate buffers.

=head1 CHANGES

=over 4

=item v0.09

Documentation updates. Documented changes for v0.08.
Fixed MANIFEST to include test wav for fix in 0.08

=item v0.08

Tomas Doran fixed an issue with opening broken files. Added test case
for this fix. See commit 24b54574a0a17a6c6f0fce033d62c2c0d8275361

=item v0.07

Noticed that installation was aborting on systems with perl < 5.8.6. Moved
minimum required version to 5.6.0 in all files. Let's see what breaks.

Fixed http://rt.cpan.org/Public/Bug/Display.html?id=32318

=item v0.06

Fixed Makefile.PL to use LIBS correctly. Amongst other things, that means
that it's now possible to build the module if your libsndfile shared library
is in a non-standard location.

(get_/set_)artist, comment etc *should* now work, but need some serious testing.

Thanks to Paul Seelig for reporting the issues and helping me find the solution.

=item v0.05

Made the frames() method work and added regression test. 
Thanks to zergen for the bug report.

=item v0.04

Pushed the required perl version back to v5.6.0. If this breaks anything,
please let me know.

=item v0.03

Added write_sync() method. Added some sf_command() methods.
Documentation updates.

=item v0.02

Documentation updates.

=item v0.01

Initial version

=back

=head1 SEE ALSO 

Erik de Castro Lopo's libsndfile page: L<http://www.mega-nerd.com/libsndfile/>

L<Audio::SoundFile> - an old(er) interface to libsndfile. Doesn't build on
my perl and looks incomplete.

L<Audio::Play> - play audio and read/write .au files.

L<Audio::LADSPA> - process audio streams using LADSPA plugins.

=head1 AUTHOR

Joost Diepenmaat, E<lt>joost@zeekat.nlE<gt>. L<http://zeekat.nl>.

With bug fix by Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>. Thanks!

=head1 COPYRIGHT AND LICENSE

B<Note:> The following copyright & license only apply to this perl package
(i.e. the "glue" to libsndfile). See L<http://www.mega-nerd.com/libsndfile/#Licensing>
for the license to libsndfile.

Copyright (C) 2006, 2012 Joost Diepenmaat, Zeekat Softwareontwikkeling

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

