################################################################################
# Convert audiofiles from one format to another (ogg, mp3 or wav)              #
#                                                                              #
# Copyright (C) 2006 Michael Hooreman <michael_AT_mijoweb_DOT_net>             #
################################################################################

#$Id: ConvTools.pm,v 1.3 2006-10-28 10:24:23 michael Exp $

=head1 NAME

Audio::ConvTools - API to convert audio files from/to mp3 ogg and wav

=head1 SYNOPSIS

 use Audio::ConvTools;
 use Audio::ConvTools qw/:DEFAULT :Tmp :Log/;

 $status = ogg2mp3('file.ogg');
 $status = ogg2wav('file.ogg');
 $status = ogg2wav('in.ogg', 'out.wav');
 $status = mp32ogg('file.mp3');
 $status = mp32wav('file.mp3');
 $status = mp32wav('in.mp3', 'out.wav');
 $status = wav2ogg('file.wav');
 $status = wav2ogg('in.wav', 'out.ogg');
 $status = wav2mp3('file.wav');
 $status = wav2mp3('in.wav', 'out.mp3');

 Audio::ConvTools::logMsg('This is a log message');
 Audio::ConvTools::errMsg('This is an error message');

 $tmp = Audio::ConvTools::getTmpFile('.wav');
 Audio::ConvTools::destroyTmpFile(\$tmp);

=head2 OBJECT INTERFACE

 No object interface is defined

=head1 DESCRIPTION

C<Audio::ConvTools> provides miscellaneous tools to convert audio files between
Ogg Vorbis, MPEG III and Wav files. This is a function interface only.

By default, all the conversions functions are exported. You can also export
temporary file usage tools with the :Tmp tag, and logging tools with the :Log
tag.

Moreover, two scipts are provided with this package:

=over

=item *

audiocdmaker   To brun audio CD

=item *

audioconv      To convert audio files

=back

=head2 PROGRAMS USED

To do the conversions, this module uses the following linux programs:

=over

=item *

oggdec, tested with version 1.0.1

=item *

mpg321, tested with version 0.2.10

=item *

oggenc, tested with version 1.0.2

=item *

lame, tested with version 3.96.1

=back

=head1

=head1 FUNCTIONS

=head2 EXPORTED BY DEFAULT

=head3 ogg2mp3

This makes a conversion from ogg to mp3:

 $status = ogg2mp3('file.ogg');

This takes the ogg file name as argument, and returns the status of the
conversion.

It first converts the ogg file to wav using ogg2wav, and then converts the wav
to ogg.

The input file has to end with '.ogg' (case insensitive). The generated file
will have the same name, excepts that '.ogg' will be replaced by 'mp3'.

=head3 ogg2wav

This makes a conversion from ogg to wav:

 $status = ogg2wav('file.ogg');
 $status = ogg2wav('in.ogg', 'out.wav');

This takes the ogg file name as first argument, and returns the status of the
conversion. If a second argument is provided, this is the name of the resulting
wav file.

The input file has to end with '.ogg' (case insensitive). If the second
argument is not provided, the generated file will have the same name, excepts
that '.ogg' will be replaced by 'wav'.

=head3 mp32ogg

This makes a conversion from ogg to mp3:

 $status = mp32ogg('file.mp3');

This takes the mp3 file name as argument, and returns the status of the
conversion.

It first converts the mp3 file to wav using mp32wav, and then converts the wav
to ogg.

The input file has to end with '.mp3' (case insensitive). The generated file
will have the same name, excepts that '.mp3' will be replaced by 'ogg'.

=head3 mp32wav

This makes a conversion from mp3 to wav:

 $status = mp32wav('file.mp3');
 $status = mp32wav('in.mp3', 'out.wav');

This takes the mp3 file name as first argument, and returns the status of the
conversion. If a second argument is provided, this is the name of the resulting
wav file.

The input file has to end with '.mp3' (case insensitive). If the second
argument is not provided, the generated file will have the same name, excepts
that '.mp3' will be replaced by 'wav'.

=head3 wav2ogg

This makes a conversion from wav to ogg:

 $status = wav2ogg('file.wav');
 $status = wav2ogg('in.wav', 'out.ogg');

This takes the wav file name as first argument, and returns the status of the
conversion. If a second argument is provided, this is the name of the resulting
ogg file.

The input file has to end with '.wav' (case insensitive). If the second
argument is not provided, the generated file will have the same name, excepts
that '.wav' will be replaced by 'ogg'.

=head3 wav2mp3

This makes a conversion from wav to mp3:

 $status = wav2mp3('file.wav');
 $status = wav2mp3('in.wav', 'out.mp3');

This takes the wav file name as first argument, and returns the status of the
conversion. If a second argument is provided, this is the name of the resulting
mp3 file.

The input file has to end with '.wav' (case insensitive). If the second
argument is not provided, the generated file will have the same name, excepts
that '.wav' will be replaced by 'mp3'.

=head2 EXPORTED BY :Log

=head3 logMsg

This prints a contatenation of getNowStr, "INFO:" and the message to STDERR:

 logMsg('This is a log message');

=head3 errMsg

This prints a contatenation of getNowStr, "ERROR:" and the message to STDERR:

 logMsg('This is an error message');

=head2 EXPORTED BY :Tmp

=head3 getTmpFile

This returns a new File::Temp object with file name extension provided as
argument:

 my $tmp = getTmpFile('.wav');

=head3 destroyTmpFile

This destroys a temp file given, as reference, as argument:

 destroyTmpFile(\$tmp)

The deferenced argument will be undef at the end of this function.

=head2 NEVER EXPORTED

=head3 getVersion

This returns the version of the module:

 print "Module Version = " . getVersion();

This is used by binary script (the version of the scripts is the version of the
module).

=head3 getNowTxt

This returns the actual date and time in format: Day YYYY-MM-DD hh:mm:ss:

 print "We are " . getNowStr();

This is used by logMsg and errMsg.

=head1 SEE ALSO

L<File::Temp>, L<String::ShellQuote>

=head1 AUTHOR

Michael Hooreman C<< <mhooreman at skynet.be> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-audioconv-tools at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-ConvTools>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audio::ConvTools

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-ConvTools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-ConvTools>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-ConvTools>

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-ConvTools>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Michael Hooreman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Audio::ConvTools;

use strict;
use warnings;

require Exporter;

our @ISA = qw/Exporter/;
our $VERSION = "0.08";
our @EXPORT = qw/
	mp32ogg
	mp32wav
	ogg2mp3
	ogg2wav
	wav2ogg
	wav2mp3
/;
our %EXPORT_TAGS = (
	Log => [qw/
		logMsg
		errMsg
	/],
	Tmp => [qw/
		getTmpFile
		destroyTmpFile
	/],
);
our @EXPORT_OK = qw/
		logMsg
		errMsg
		getTmpFile
		destroyTmpFile
/;

use File::Temp;
use String::ShellQuote;

BEGIN {
	#$Exporter::Verbose = 1
};

sub getVersion()
{
	return $VERSION;
}

sub getNowTxt()
{
	my ($s, $m, $h, $D, $M, $Y) = localtime(time);
	return sprintf(
		"%04d-%02d-%02d %02d:%02d:%02d",
		$Y+1900, $M+1, $D, $h, $m, $s
	);
}

sub logMsg($)
{
	my $txt = shift;
	print STDERR getNowTxt() . ": INFO: " . $txt . $/;
}

sub errMsg($)
{
	my $txt = shift;
	print STDERR getNowTxt() . ": ERROR: " . $txt . $/;
}

sub getTmpFile($)
{
	my $extension = shift;
	my $tmp = new File::Temp(
		SUFFIX=>$extension,
		UNLINK=>1         , #to automatically remove when out of scope
	);
	return $tmp;
}

sub destroyTmpFile($)
{
	my $pTmp = shift;
	$$pTmp->cleanup(); #to be sure
	$$pTmp = undef; #old tmp object is out of scope => automatically cleaned
}

sub mp32ogg($)
{
	my $inFile = shift;
	my $outFile;
	my $tmpFile;
	my $status;

	($inFile =~ /^(.*)\.[Mm][Pp]3$/) or do {
		errMsg("$inFile is not a mp3 file");
		return 0;
	};
	$outFile = "$1.ogg";
	$tmpFile = getTmpFile('.wav');

	$status = mp32wav($inFile, $tmpFile);
	unless ($status) {
		errMsg("Cannot create temp wav file");
		return $status;
	}

	$status = wav2ogg($tmpFile, $outFile);
	destroyTmpFile(\$tmpFile);

	return $status;
}

sub ogg2mp3($)
{
	my $inFile = shift;
	my $outFile;
	my $tmpFile;
	my $status;

	($inFile =~ /^(.*)\.[Oo][Gg][Gg]$/) or do {
		errMsg("$inFile is not a ogg file");
		return 0;
	};
	$outFile = "$1.mp3";
	$tmpFile = getTmpFile('.wav');

	$status = ogg2wav($inFile, $tmpFile);
	unless ($status) {
		errMsg("Cannot create temp wav file");
		return $status;
	}

	$status = wav2mp3($tmpFile, $outFile);
	destroyTmpFile(\$tmpFile);

	return $status;
}

sub mp32wav($;$)
{
	my $inFile = shift;
	my $outFile = shift;
	my $status;
	($inFile =~ /^(.*)\.[Mm][Pp]3$/) or do {
		errMsg("$inFile is not an mp3 file");
		return 0;
	};
	$outFile = "$1.wav" unless defined $outFile;
	$status = system(
		"mpg321 -w " . shell_quote($outFile) . " " . shell_quote($inFile)
	);
	return ($status==0);
}

sub ogg2wav($;$)
{
	my $inFile = shift;
	my $outFile = shift;
	my $status;
	($inFile =~ /^(.*)\.[Oo][Gg][Gg]$/) or do {
		errMsg("$inFile is not an ogg vorbis file");
		return 0;
	};
	$outFile = "$1.wav" unless defined $outFile;
	$status = system(
		"oggdec " . shell_quote($inFile) . " -o " . shell_quote($outFile)
	);
	return ($status==0);
}

sub wav2ogg($;$)
{
	my $inFile = shift;
	my $outFile = shift;
	my $status;
	($inFile =~ /^(.*)\.[Ww][Aa][Vv]$/) or do {
		errMsg("$inFile is not an wav file");
		return 0;
	};
	$outFile = "$1.ogg" unless defined $outFile;
	$status = system(
		"oggenc -q 10 -o " . shell_quote($outFile) . " " . shell_quote($inFile)
	);
	return ($status==0);
}

sub wav2mp3($;$)
{
	my $inFile = shift;
	my $outFile = shift;
	my $status;
	($inFile =~ /^(.*)\.[Ww][Aa][Vv]$/) or do {
		errMsg("$inFile is not an wav file");
		return 0;
	};
	$outFile = "$1.mp3" unless defined $outFile;
	$status = system(
		"lame -h " . shell_quote($inFile) . " " . shell_quote($outFile)
	);
	return ($status==0);
}

1;

__END__

#$Log: ConvTools.pm,v $
#Revision 1.3  2006-10-28 10:24:23  michael
#Updated my email address.
#Changed to version 0.08
#
#Revision 1.2  2006-10-28 10:12:45  michael
#Require File::Temp version 0.17
#New version 0.7
#
#Revision 1.1  2006-10-28 10:03:45  michael
#Added loss ConvTools.pm to the repos.
#
#Revision 1.1  2006/08/18 12:50:12  mhoo
#module is now Audio::ConvTool
#switched to version 0.06
#
#Revision 1.1  2006/08/18 12:36:22  mhoo
#AudioConvTools becomes Audio::ConvTools
#switched to v0.4
#
#Revision 1.6  2006/08/18 12:28:28  mhoo
#AudioConvTools becomes Audio::ConvTools
#switched to v0.4
#
#Revision 1.5  2006/08/18 11:59:19  mhoo
#Adapted MANIFEST (INSTALL is lost)
#Swith to version 0.03
#
#Revision 1.4  2006/08/18 11:56:35  mhoo
#Removed INSTALL (not needed)
#Switched to version 0.02
#
#Revision 1.3  2006/08/18 11:52:43  mhoo
#Tagged to version 0.01
#
#Revision 1.2  2006/08/18 11:49:12  mhoo
#Adapted manifest
#Tagging to version 0.9
#
#Revision 1.1.1.2  2006/08/18 11:46:27  mhoo
#Version 0.9 Ready for CPAN
#

