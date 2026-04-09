#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: awspollymp3.pl
# ABSTRACT: script converting textfile named $1
#                                  into file $2
#                          with engine:voice $3
#           using AWS Polly
our $VERSION = '20260408.1240'; # VERSION


use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <region:engine:voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $regionenginevoice ) = @ARGV;

# determine format from audiofilename
my $format = $audiofilename;
$format =~ s/.+\.([^\.]+)/$1/;
foreach ( $format ) {
  /^mp3$/ and do {
    $format = 'mp3';
    last;
  };
  /^ogg$/ and do {
    $format = 'ogg_vorbis';
    last;
  };
  die( "Error: could not guess audio format based on output audiofilename\n" );
}

# determine engine and voice
my ( $region, $engine, $voice ) = split( /:/, $regionenginevoice );
    die( "Invalid region, engine or voice format. Use <region:engine:voice>.\n" )
      
  unless( defined $region and defined $engine and defined $voice );

# read text file
my $textfile = IO::File->new();
$textfile->open( "<$textfilename" )
  or die( "Error: cannot open '$textfilename'\n" );
my $text = do { local $/; <$textfile> };

# Run polly, run!
my $command = [
	       'aws',
	       'polly',
	       'synthesize-speech',
	       '--output-format',
	       $format,
	       '--engine',
	       $engine,
	       '--voice-id',
	       $voice,
	       '--text',
	       $text,
	       # '--text-type',
	       # 'ssml',
	       $audiofilename
	      ];
my $out;
IPC::Run::run( $command,
	       '>',  \$out );
exit($?);

__END__

=pod

=encoding UTF-8

=head1 NAME

awspollymp3.pl - script converting textfile named $1

=head1 VERSION

version 20260408.1240

=head1 DESCRIPTION

The script reads the text file, and converts it to a speech audio file using
B<AWS Polly>. You need to setup the correct credentials yourself (in F<.aws/credentials>)
and also the correct region and output format in a configuration file (in F<.aws/config>).

=head1 NAME

awspolly.pl - convert text to speech

=head1 SYNOPSYS

awspolly.pl <input-text-file> <output-audio-file> <region:engine:voice>

=head1 ARGUMENTS

=over 4

=item <input-text-file>

name of the file containing the text to convert to speech

=item <output-audio-file>

name of the file (including extension) to write the speech audio to.

=item <region:engine:voice>

region, engine and voice to use fo the text-to-speech generation.
E.g. en-GB:neural:Amy

See the Amazon documentation for avlid regions, engines and voices.

=back

=head1 BUGS

No bugs have been reported so far. If you find any, please,
send an e-mail to the author containing:

=over 4

=item - what you were trying;

=item - enough data such that I can reproduce your attempt;

=item - what strange behavior you observed;

=item - what normal behavior you would have expected.

=back

=head1 LINKS

=over 4

=item https://aws.amazon.com/polly

=back

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
