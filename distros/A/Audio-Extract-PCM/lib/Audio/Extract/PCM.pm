package Audio::Extract::PCM;
use strict;
use warnings;
use Carp;
use IO::CaptureOutput qw(qxx);

=head1 NAME

Audio::Extract::PCM - Extract PCM data from audio files

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This module's purpose is to extract PCM data from various audio formats.  PCM
is the format in which you send data to your sound card driver.  This module
aims to provide a single interface for PCM extraction from various audio
formats, compressed and otherwise.

Currently the implementation makes use of the external "sox" program.  As of
2008, sox's supported input formats include "wav", "mp3", "ogg/vorbis", "flac",
if you have compiled sox with support for them, but do not include "wma" or
"aac".

I have chosen the use of "sox" for the first implementation of this module
because it already has an abstract interface to many formats.  However I plan
to include more implementations to (1) maybe include more formats, (2) make the
implementation more perlish and (3) make the module more portable.  CPAN has
specialized modules like L<Audio::Mad> and L<Ogg::Vorbis::Decoder>, to which I
could implement an abstract interface.

If you have suggestions how to include more implementations, or if you simply
need them and want to motivate me, please contact me.

Usage example:

    use Audio::PCM::Extract;
    my $extractor = Audio::PCM::Extract->new('song.ogg');
    my $pcm = $extractor->pcm(44100, 2, 2) or die $extractor->error;

=head1 METHODS

=head2 new

Parameters: C<filename>

Constructs a new object to access the specified file.

=cut

sub new {
    my $class = shift;
    my ($filename) = @_;

    my $this = bless {
        filename => $filename,
    }, $class;

    return $this;
}

my %bppvals = (
    1 => '-b',
    2 => '-w',
    4 => '-l',
    8 => '-d',
);

if (_get_sox_version() && _get_sox_version() > '13.0.0') {
    $bppvals{$_} = '-' . $_ for keys %bppvals;
}

=head2 pcm

Parameters: C<frequency>, C<samplesize>, C<channels>

Extracts PCM data.

The sample size is specified in bytes, so C<2> means 16 bit sound.

Returns the pcm data as a reference to a string, or an empty list in case of an
error (cf.  L</error>).

=cut

sub pcm {
    my $this = shift;
    my ($freq, $samplesize, $channels) = @_;

    croak 'Bad frequency' unless $freq =~ /^\d+\z/;
    croak 'Bad sample size' unless $samplesize =~ /^\d+\z/;
    croak 'Bad channels parameter' unless $channels =~ /^\d+\z/;

    # Newer soxes have the flags -1, -2, -4, -8, but the old flags still work
    # in newer versions, even though they aren't documented.
    my $sparam = $bppvals{$samplesize} or croak "Unsupported sample size: $samplesize";

    my $fn = $this->{filename};

    use bytes;

    local $ENV{LC_ALL} = 'C';

    my @command = ('sox', $fn, $sparam, '-r'.$freq, '-c'.$channels, '-twav', '-');

    warn qq(Running "@command"\n) if $ENV{DEBUG};

    $! = 0;
    my ($pcm, $soxerr, $success) = qxx(@command);

    chomp $soxerr;

    # Well, this is ugly, but that warning is annoying and does not matter to
    # us (we strip the header anyway)
    $soxerr =~ s/.*header will be wrong since can't seek.*\s*//;

    unless ($success) {
        my $err;
        if ($!) {
            $err = length($soxerr) ? "$! - $soxerr" : "$!";
        } else {
            $err = length($soxerr) ? $soxerr : "Error running sox";
        }

        undef $pcm;

        $this->error($err);
        return ();
    }

    warn $soxerr if length $soxerr;

    substr($pcm, 0, 44, ''); # strip wave header (we know the details, we specified them to sox)

    return \$pcm;
}


=head2 error

Returns the last error that occured for this object.

=cut


sub error {
    my $this = shift;

    if (@_) {
        my ($msg) = @_;
        return $this->{error} = $msg;
    }

    return $this->{error};
}


=head1 SEE ALSO

=over 8

=item *

L<Audio::Mad> - Module to decode MPEG files, in particular MP3

=item *

L<Ogg::Vorbis::Decoder> - Module to decode Vorbis files

=item *

L<http://en.wikipedia.org/wiki/Pulse-code_modulation> - PCM (Pulse-code modulation)

=item *

L<http://sox.sourceforge.net/> - SoX homepage

=back


=head1 AUTHOR

Christoph Bussenius, C<< <pepe at cpan.org> >>

Please include the name of this module in the subject of your emails so they
won't get lost in spam.

If you find this module useful, I'll be glad if you drop me a note.


=head1 COPYRIGHT & LICENSE

Copyright 2008 Christoph Bussenius, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

{
    my $soxver;

    # This will be documented and without underscore in Audio::Extract::PCM::Backend::SoX
    # once I release the multiple-backends branch.

    sub _get_sox_version {
        return $soxver if defined $soxver;

        my $vers_output = `sox --version`;

        if (defined $vers_output) {
            ($soxver) = $vers_output =~ /v(\d+\.\d+\.\d+)/
                or warn "Strange sox --version output: $vers_output\n";
        }

        use version;
        $soxver = version->new($soxver);

        return $soxver;
    }
}

1; # End of Audio::Extract::PCM
