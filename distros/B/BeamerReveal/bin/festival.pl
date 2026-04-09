#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: festival.pl
# ABSTRACT: script converting textfile named $1
#                                  into file $2
#                          with engine:voice $3
#           using festival
our $VERSION = '20260408.1240'; # VERSION


use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $voice ) = @ARGV;

# determine format from audiofilename
my $format = $audiofilename;
$format =~ s/.+\.([^\.]+)/$1/;

# Run festival, run!
my $command = [
	       "text2wave",
	       "-eval",
	       "(voice_$voice)",
	       "-o",
	       "$audiofilename.wav",
	       "$textfilename"
	      ];
my $out;
IPC::Run::run( $command,
	       '>',  \$out );
die( "Error: could not start festival's 'text2wave'\n" ) if ( $? );

foreach ( $format ) {
  'mp3' and do {
    $command = [ "lame",
		 "$audiofilename.wav",
		 "$audiofilename" ];
    last;
  };
  'ogg' and do {
    $command = [ "oggenc",
		 "-o",
		 "$audiofilename",
		 "$audiofilename.wav" ];
    last;
  };
  die( "Error: could not guess audio format based on output audiofilename\n" );
}
IPC::Run::run( $command,
	       '>',  \$out );
exit($?) if ($?);
unlink "$audiofilename.wav";
exit(0);

__END__

=pod

=encoding UTF-8

=head1 NAME

festival.pl - script converting textfile named $1

=head1 VERSION

version 20260408.1240

=head1 DESCRIPTION

The script reads the text file, and converts it to a speech audio file using
B<festival>. You need to setup the software yourself.
In addition, make sure B<lame> and B<oggenc> are installed also.

=head1 NAME

festival.pl - convert text to speech

=head1 SYNOPSYS

festival.pl <input-text-file> <output-audio-file> <voice>

=head1 ARGUMENTS

=over 4

=item <input-text-file>

name of the file containing the text to convert to speech

=item <output-audio-file>

name of the file (including extension) to write the speech audio to.

=item <voice>

voice to use fo the text-to-speech generation.
E.g. en1_mbrola

See the Festival/Festvox documentation for valid voices.

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

=item https://www.cstr.ed.ac.uk/projects/festival

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
