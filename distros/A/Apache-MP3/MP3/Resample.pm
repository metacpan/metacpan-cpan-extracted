package Apache::MP3::Resample;

# $Id: Resample.pm,v 1.7 2003/10/06 14:10:30 lstein Exp $
# Resamples (downsamples) on the fly

use strict;
use vars qw(@ISA $VERSION);
use Apache2::Const -compile => qw(:common);
use IO::File;
use CGI qw(:standard *table *TR *td escape);
use CGI::Cookie;
use Apache::MP3::Playlist;
use File::Basename;
$VERSION = 1.0;

@ISA = 'Apache::MP3::Playlist';

use constant ENCODE => qq(%Dlame%I %b -%F);

my @DECOMPRESSOR_DEFAULTS = ("audio/shorten" => "shorten -x %f -|",
			     "audio/flac" => "flac -d -c -s %f|");

my @PRESET_DEFAULTS = (
	       '24 kbps' => '-b24 --lowpass 4.0  --highpass 0.1  --resample 8',
	       '40 kbps' => '-b40 --lowpass 4.0  --resample 16',
	       '56 kbps' => '-b56 --lowpass 12.0 --resample 22.05',
	       '64 kbps' => '-b64 --lowpass 15.0 --resample 22.05',
	       '96 kbps' => '-b96 --lowpass 15.0',
	       '128 kbps' => '-b128 --lowpass 18',
	       '160 kbps' => '-b160',
	       '192 kbps' => '-b192',
	      );

my (%PRESETS,@PRESETS,%DECOMPRESSORS,@DECOMPRESSORS);

sub new {
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self = $class->SUPER::new (@_);

   # Add to suffix list and supported type hash
   push (@{$self->{'suffixes'}}, ".shn", ".SHN", ".flac", ".FLAC");
   $self->{'supported_types'}->{'audio/shorten'} = 'read_shorten';
   $self->{'supported_types'}->{'audio/flac'} = 'read_flac';

   bless ($self, $class);
   $self;
}

sub run {
  my $self = shift;
  $self->process_cookies;
  $self->SUPER::run();
}

sub process_cookies {
  my $self = shift;
  my $r = $self->r;

  # don't set cookies for ordinary MP3 file downloads.
  return if !param() && !-d $r->filename;

  if (my $cookies = CGI::Cookie->parse($r->headers_in('Cookie'))) {
    $self->bitrate($cookies->{bitrate}->value)
      if $cookies->{bitrate};
  }
  $self->bitrate(param('bitrate')) if defined param('bitrate');
  my $c = CGI::Cookie->new(-name  => 'bitrate',
			   -value => $self->bitrate,
			   -expires => '+90d'
			  );
  tied(%{$r->err_headers_out})->add('Set-Cookie' => $c);
  param(bitrate => $self->bitrate);
}

sub bitrate {
  my $self = shift;
  my $g    = $self->{bitrate};
  $self->{bitrate} = shift if @_;
  return unless $self->presets($g);
  $g;
}

sub stream_parms {
  my $self = shift;
  my $p =  $self->SUPER::stream_parms;
  my $rate = escape($self->bitrate);
  $p .= ";bitrate=$rate" if $rate;
  $p;
}

sub presets {
  my $self = shift;
  unless (%PRESETS) {
    my @p;
    if (my $conf = $self->r->dir_config('ResamplePresets')) {
      @p = split /\s*(?:=>|,)\s*/,$conf;
    } else {
      @p = @PRESET_DEFAULTS;
    }
    my @i = map {$_*2} (0..(@p-1)/2);
    %PRESETS    = @p;
    @PRESETS = @p[@i];
  }
  my $bitrate = shift or return @PRESETS;
  return $PRESETS{$bitrate};
}

sub decompressor {
  my $self = shift;
  unless (%DECOMPRESSORS) {
    my @p;
    if (my $conf = $self->r->dir_config('DecompressorPresets')) {
      @p = split /\s*(?:=>|,)\s*/,$conf;
    } else {
      @p = @DECOMPRESSOR_DEFAULTS;
    }
    my @i = map {$_*2} (0..(@p-1)/2);
    %DECOMPRESSORS    = @p;
    @DECOMPRESSORS = @p[@i];
  }
  my $mime = shift or return @DECOMPRESSORS;
  return $DECOMPRESSORS{$mime};
}

sub sample_popup {
  my $self = shift;
  my @bitrates = $self->presets;
  unshift @bitrates,0;
  my %labels = (0 => '--');
  return (
	  start_form(-name=>'form'),
	  table(
		TR(th('Resample:'),
		   td(
		      popup_menu(-name  => 'bitrate',
				 -value => \@bitrates,
				 -labels => \%labels,
				 -onChange => 'form.submit()'
				),
		     )
		  )
		),
	    end_form);
}

sub directory_top {
  my $self = shift;
  print start_table({-width=>'100%'});
  print start_TR,start_td;
  $self->SUPER::directory_top(@_);
  print end_td;
  print td({-align=>'RIGHT',-valign=>'TOP'},
	   $self->sample_popup());
  print end_TR,end_table;
}

sub open_file {
  my $self = shift;
  return $self->SUPER::open_file(@_) unless $self->bitrate;
  my $file = shift;
  my $bitrate = $self->bitrate;
  my $presets = $self->presets($bitrate);
  my $type = $self->r->lookup_file($file)->content_type;
  my $decompress = $self->decompressor ($type) || "";
  my $encode = $self->r->dir_config('MP3Encoder') || ENCODE;
  my $inputtype = length $decompress ? "" : " --mp3input";
  my $percentF = length $decompress ? "" : ("<" . quotemeta ($file));
  $decompress =~ s{%([a-zA-Z])}
    { $1 eq 'f' ? quotemeta($file) :
	"%$1"}exg;
  $encode =~ s{%([a-zA-Z])}
              {$1 eq 'b' ? $presets         :
	       $1 eq 'D' ? $decompress      :
	       $1 eq 'I' ? $inputtype       :
	       $1 eq 'F' ? $percentF        :
               $1 eq 'f' ? quotemeta($file) :
               "%$1"}exg;
  my $filter = $self->r->dir_config('VerboseMP3Encoder')
    ? "$encode |" : "$encode 2>/dev/null |";
  return IO::File->new($filter);
}

sub read_shorten {
  my $self = shift;
  my ($file,$data) = @_;
  my $sec;
  my $bits = 0;
  my $samples = 0;
  my $channels = 0;
  my $track = "";

  open (SHNINFO, "shntool info \Q$file\E 2>/dev/null|") or return;

  while (<SHNINFO>) {
     if (/^length:\s+(\d+):(\d+)\.(\d+)/) {
	$sec = $1 * 60 + $2;
     } elsif (/^channels:\s+(\d+)/) {
	$channels = $1;
     } elsif (/^samples\/sec:\s+(\d+)/) {
	$samples = $1;
     } elsif (/^bits\/sample:\s+(\d+)/) {
	$bits = $1;
     }
  }
  close SHNINFO;

  %$data = (
	    title  => basename ($file),
	    artist => "",
	    album  => "",
	    year   => "",
	    genre  => "",
	    track  => $track,
	    comment => "",
	    min         => int $sec/60,
	    sec         => $sec % 60,
	    seconds     => $sec,
	    bitrate     => int ($channels * $bits * $samples / 1024),
	    samplerate  => $samples,
	    duration    => sprintf("%dm %2.2ds", int $sec/60,$sec%60),
	   )
}

sub read_flac {
  my $self = shift;
  my ($file,$data) = @_;
  my $sec;
  my $bits = 0;
  my $samples = 0;
  my $channels = 0;
  my $track = "";
  my $rate = 0;

  open (METAFLAC, "metaflac --list --block-number 0 \Q$file\E 2>/dev/null|")
    or return;

  while (<METAFLAC>) {
     if (/sample_rate: (\d+)\s/) {
	$rate = $1;
     } elsif (/channels: (\d+)/) {
	$channels = $1;
     } elsif (/bits-per-sample: (\d+)/) {
	$bits = $1;
     } elsif (/total samples: (\d+)/) {
	$samples = $1;
	$sec = $samples / $rate if $rate;
     }
  }
  close METAFLAC;

  %$data = (
	    title  => basename ($file),
	    artist => "",
	    album  => "",
	    year   => "",
	    genre  => "",
	    track  => $track,
	    comment => "",
	    min         => int $sec/60,
	    sec         => $sec % 60,
	    seconds     => $sec,
	    bitrate     => int ($channels * $bits * $rate / 1024),
	    samplerate  => $samples,
	    duration    => sprintf("%dm %2.2ds", int $sec/60,$sec%60),
	   )
}

1;

=head1 NAME

Apache::MP3::Resample - Downsample MP3/FLAC/Shorten files during streaming

=head1 SYNOPSIS

 # httpd.conf or access.conf
 AddType audio/shorten .shn .SHN
 AddType audio/flac .flac

 Alias /apache_mp3 /usr/share/libapache-mp3-perl

 <Location /songs>
   SetHandler perl-script
   PerlHandler Apache::MP3::Resample
   PerlSetVar CacheDir		/var/cache/Apache::MP3
   PerlSetVar AllowDownload	no
   PerlSetVar SortFields	Album,Track,Title,-Duration
   PerlSetVar Fields		Track,Title,Artist,Album,Duration,Bitrate
 </Location>

=head1 DESCRIPTION

Apache::MP3::Resample subclasses Apache::MP3::Playlist to allow the
user to downsample audio files before streaming them.  This allows users
on slower connections to stream songs.  When this module is installed,
a menu of bitrates is presented in the upper right-hand corner of the
screen.  The user can choose from one of the bitrates, or select a
mode that performs no resampling.  The selected bitrate is maintained
in a persistent cookie so that resampling is performed whenever the
user returns to the site.

This module requires a command-line MP3 encoder to resample and
reencode the audio data.  If not otherwise specified,
Apache::MP3::Resample will try to use the Open Source Lame MP3 encoder.
This utility is available at http://www.sulaco.org/mp3.  Version 3.90
was used during the development of this module.  Your results with
other versions may vary.

When you install Lame (or the encoder of your choice), be sure to
place it in a directory located in Apache's PATH so that the module
can find them at run time.  You may need to set the PATH environment
variable during Apache's launch, or by explicitly adding a B<SetEnv>
directive to the Apache configuration file.

You should be aware that the decoding/reencoding process is
CPU-intensive, and server performance may degrade as the number of
simultaneous users increases.

=head1 CUSTOMIZATION

This class recognizes the following two configuration variables in
addition to those recognized by its superclasses.

=over 4

=item MP3Encoder

The command to use to invoke the MP3 encoder.  It should accept CDDA
data on standard input and write MP3 data to standard output.  The
command should contain the replacement sequences b<%b> and b<%f>.  At
run time, b<%b> will be replaced with the options used to set the
bitrate and sampling frequency, while b<%f> will contain the MP3 file
to be streamed.

If not present, the following default is used:

  lame --mp3input %b - <%f

=item DecompressorPresets

A list of MIME types and decompression programs to use for each.  The
format uses a variant of the standard Perl hash format, in which the
keys are the MIME types for the audio files and the values are the
command which will be used to decompress files of that type.  The
token "%f" will be replaced by the name of the compressed audio file
and the command should end with a pipe (|) character.  Here is a
simple example, which is also the default list:

    PerlSetVar  DecompressorPresets  '"audio/shorten" => "shorten -x %f -|",\
                                      "audio/flac" => "flac -d -c -s %f|"'

Note the use of quotation marks and backslashes to protect whitespace
and newlines respectively.

=item ResamplePresets

A list of bitrates and the command-line options to pass to the
encoder.  The format uses a variant of the standard Perl hash format,
in which the keys are the bitrates to present to the user and the
values are command-line options to pass to the encoder.  Here is a
simple example:

    PerlSetVar  ResamplePresets  '16 kbps => -b16,\
	                          56 kbps => -b56,\
                                 128 kbps => -b128,\
				 160 kbps => -b160'

Note the use of quotation marks and backslashes to protect whitespace
and newlines respectively.

Here is another example, which takes advantage of the --preset feature
present in newer versions of Lame.

    PerlSetVar  ResamplePresets 'phone => --preset phone,\
	                         voice  => --preset voice,\
                                 fm     => --preset fm, \
				 tape   => --preset tape,\
	                         hifi   => --preset hifi,\
                                 cd     => --preset cd'

The user will see a popup menu containing the entries "16 kbps", "56
kbps" and so forth, as well as a blank ("--") entry that is provided
automatically.  Upon selecting each option the corresponding
command-line arguments will be slotted into the "%s" variable in the
encoder line specified by B<MP3Encoder>.

More complex command line options are possible.  For example, to
invoke VBR (variable bitrate) encoding and resample the output to
22.05 kHz, you could apply these options

    PerlSetVar  ResamplePresets  '16 => -b16 -v --resample 22.05,\
	                          56 => -b56 -v --resample 22.05,\
                                 128 => -b128 -v --resample 22.05,\
				 160 => -b160 -v --resample 22.05'

Lame only accepts certain combinations of command-line options, and I
do not fully understand the restrictions.  Please do not e-mail me
with Lame-related questions.

The default presets are:

     24  kbps => -b24 --lowpass 4.0  --highpass 0.1  --resample 8,
     40  kbps => -b40 --lowpass 4.0  --resample 16,
     56  kbps => -b56 --lowpass 12.0 --resample 22.05,
     64  kbps => -b64 --lowpass 15.0 --resample 22.05,
     96  kbps => -b96 --lowpass 15.0,
     128 kbps => -b128 --lowpass 18,
     160 kbps => -b160,
     192 kbps => -b192

=back

=head1 METHODS

This module overrides the inherited run(), open_file() and
directory_top() methods.  It adds the following new methods:

=over 4

=item bitrate()

Set or get the command-line options to pass to the encoder for a
desired bitrate.

=item stream_parms()

Return the parameters to append to an MP3 playlist entry in order to
activate resampling.

=item presets()

Get the names of the bitrate presets specified by the ResamplePresets
configuration variable, or the default names.  Called with an argument
equal to the name of a preset, returns the command-line arguments to
pass to the encoder.

=item sample_popup()

Draws the popup menu with the sample rate options.

=back

=head1 BUGS

When the external program is invoked to downsample the MP3 data, its
standard error is redirected to /dev/null.  This prevents Lame's
informational messages from gumming up the server error log, but also
prevents the system from giving you helpful diagnostic messages, such
as "file not found".  If you are having trouble with the downsampling,
set the configuration variable VerboseMP3Encoder to a true value in
order to see the standard error messages.

Also, the module does not function properly unless CacheDir is set and
points to a directory which exists and is writeable by the Apache
server.

=head1 ACKNOWLEDGEMENTS

Many people have requested this feature and/or proposed implementations.
Thank you all for your help.

FLAC and Shorten support added by Caleb Epstein <cae@bklyn.org>.

=head1 AUTHOR

Copyright 2000, Lincoln Stein <lstein@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 SEE ALSO

L<Apache::MP3::Playlist>, L<Apache::MP3>, L<MP3::Info>, L<Apache>

=cut

