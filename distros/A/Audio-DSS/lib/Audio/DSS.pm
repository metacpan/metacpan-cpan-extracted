package Audio::DSS;

use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

sub new {
	my ($class, $file) = @_;
	my $self = bless {}, $class;
	$self->{file} = $file;
	if ($file) {
		$self->getDSSMetaData();
	}
	return $self;
}

sub getDSSMetaData {
	my $self = shift;
	my $d;
	my $buf;
	open IN, $self->{'file'} or die "Can't open $self->{file} because $!\n";
	read IN, $buf, 1256;
	$self->{id} = substr($buf, 1,3);	
	$self->{create_date} = fixDSSDate(substr($buf, 38, 12));
	$self->{complete_date} = fixDSSDate(substr($buf, 50, 12));
	$self->{length} = substr($buf, 62, 6);
	$self->{priority} = undef;
	$self->{comments} = substr($buf, 0x31e,100);
	$self->{comments} =~ s/\x00//g;
	close IN;
}

sub fixDSSDate {
	my $raw = shift;
	# accept "040815193651" and return "2004-08-15 19:36:51"
	return "20" . substr($raw,0,2) . '-' . substr($raw,2,2) . '-' . substr($raw,4,2) . ' ' . substr($raw,6,2) . ':' . substr($raw,8,2) . ':' . substr($raw,10,2);
}

1;
__END__

=head1 NAME

Audio::DSS - Extract meta data from Digital Speech Standard (DSS) files

=head1 SYNOPSIS

  use Audio::DSS;
  my $dss = new Audio::DSS;
  $dss->{file} = 'dss_is_cool.dss';
  $dss->getDSSMetaData();

  or

  my $dss = new Audio::DSS(file=>'dss_is_cool.dss');;

  print $dss->{file};  
  print $dss->{create_date};  
  print $dss->{complete_date};  
  print $dss->{length};  
  print $dss->{comments};  

  There is a utility program to dump dss for you:
  dumpdss.pl /somepath/*.dss

  the file eg/dss_is_cool.dss can be used for testing:
  eg/dumpdss.pl eg/dss_is_cool.dss 
  file|create_date|complete_date|length|comments

  returns: 

  eg/dss_is_cool.dss|2004-08-17 17:33:02|2004-08-17 17:33:04|000002|DSS File comments are sadly limited to 100 characters, and this comment uses every one of them, see?|

=head1 DESCRIPTION

Extract the meta information from a Digital Speech Standard (DSS) file.  
DSS is a compact file format used for recording voice.  It is used 
in Olympus Digital Voice Recorders.  

To be precise, I assume it is used all over, but I _know_ that it
is used in the Olympus DS-330 Digital Voice Recorder.

My voice recorder supports five different folders, and many different tracks
in each folder.  The interface software then sucks my recordings from the
voice recorder onto my iBook, putting clips into individual dss files in
one of five different directories.

The DSS header includes the time a track was created, when it was last 
edited, the total time, and up to 100 characters of comments.  The key
use case for this module is to pull time stamps then use 
the as yet unwritten and not really named 'Geo::Track::Interpolate' to
syncronize DSS files with GPS track logs based on the time stamps.

Huh?  Time is the universal foreign key!  If you know what time something 
occurred then you can syncronize it with your GPS track log.  Digital 
photos, voice records, heart rate monitoring, temperature, random stuff,
etc.

Double huh?  Syncronizing 'media' (Schuyler thinks these are all media, 
and I get wierded out by that language so put it in scare quotes) with 
position, or 'geocoding the media' is the key component of Quantitative
Psychogeography.  This is the quantitative study of spaces and our 
relationships with those spaces.  Among other things.

As an aside, or intercalery, how much POD do I need to write for this
module before my code to pod ratio exceeds all known limits?

=head2 EXPORT

None by default.

=head1 SEE ALSO

See http://www.mappinghacks.com, which might be cool.  http://locative.us
is another site of potential interest.  http://geocoder.us is a US 
Geocoder written by Schuyler Erle. 

You should 'probably' think about using the GPX format if you want 
to share these tracks with other people.

=head1 AUTHOR

Rich Gibson, E<lt>rgibson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Rich Gibson 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
