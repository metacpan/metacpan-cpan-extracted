#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: balabolka.pl
# ABSTRACT: script converting textfile named $1
#                                  into file $2
#                          with engine:voice $3
#           using balabolka
our $VERSION = '20260408.1240'; # VERSION


use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $voice ) = @ARGV;

# Run balabolka, run!
my $command = [ "balabolka.exe",
		"-mqs",
		$textfilename,
		$audiofilename,
		$voice ];
my $out;
IPC::Run::run( $command, '>', \$out );
exit( $? );

__END__

=pod

=encoding UTF-8

=head1 NAME

balabolka.pl - script converting textfile named $1

=head1 VERSION

version 20260408.1240

=head1 DESCRIPTION

The script reads the text file, and converts it to a speech audio file using
B<balabolka>. You need to install the B<balabolka.exe> program yourself and must
make sure it is available on your search path.

=head1 NAME

balabolka.pl - convert text to speech

=head1 SYNOPSYS

balabolka.pl <input-text-file> <output-audio-file> <voice>

=head1 ARGUMENTS

=over 4

=item <input-text-file>

name of the file containing the text to convert to speech

=item <output-audio-file>

name of the file (including extension) to write the speech audio to.

=item <voice>

voice to use fo the text-to-speech generation.

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

=item http://www.cross-plus-a.com/balabolka.htm

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
