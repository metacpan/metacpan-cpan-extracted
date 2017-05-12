# $Id: XML.pm,v 1.2 1999/11/30 21:06:05 lstein Exp $

# Boulder::XML
#
# XML input/output for Stone objects

package Boulder::XML;

=head1 NAME

Boulder::XML - XML format input/output for Boulder streams

=head1 SYNOPSIS

   use Boulder::XML;
   
   $stream = Boulder::XML->newFh;

   while ($stone = <$stream>) {
        print $stream $stone;
   }

=head1 DESCRIPTION

Boulder::XML generates BoulderIO streams from XML files and/or
streams.  It is also able to output Boulder Stones in XML format.  Its
semantics are similar to those of Boulder::Stream, except that there
is never any pass-through behavior.

Because XML was not designed for streaming, some care must be taken
when reading an XML document into a series of Stones.  Consider this
XML document:

 <?xml version="1.0" standalone="yes"?>

 <Paper>
   <Author>Lincoln Stein</Author>
   <Author>Jean Siao</Author>
   <Date>September 29, 1999</Date>
   <Copyright copyrighted="yes">1999 Lincoln Stein</Copright>
   <Abstract>
       This is the abstract.  It is not anything very fancy,
       but it will do.
   </Abstract>
   <Citation>
        <Author>Fitchberg J</Author>
        <Journal>Journal of Irreproducible Results</Journal>
        <Volume>23</Volume>
        <Year>1998</Volume>
   </Citation>
   <Citation>
        <Author>Clemenson V</Author>
        <Journal>Ecumenica</Journal>
        <Volume>10</Volume>
        <Year>1968</Volume>
   </Citation>
   <Citation>
        <Author>Ruggles M</Author>
        <Journal>Journal of Aesthetic Surgery</Journal>
        <Volume>10</Volume>
        <Year>1999</Volume>
   </Citation>
 </Paper>

Ordinarily the document will be construed as a single Paper tag
containing subtags Author, Date, Copyright, Abstract, and so on.
However it might be desirable to fetch out just the citation tags as a
series of Stones.  In this case, you can declare Citation to be the
top level tag by passing the B<-tag> argument to new(). Now calling
get() will return each of the three Citation sections in turn.  If no
tag is explicitly declared to be the top level tag, then Boulder::XML
will take the first tag it sees in the document.

It is possible to stream XML files.  You can either separate them into
separate documents and use the automatic ARGV processing features of
the BoulderIO library, or separate the XML documents using a
B<delimiter> string similar to the delimiters used in MIME multipart
documents.  By default, BoulderIO uses a delimiter of
E<lt>!--Boulder::XML--E<gt>.

B<This is not a general XML parsing engine!> Instead, it is a way to
represent BoulderIO tag/value streams in XML format.  The module uses
XML::Parser to parse the XML streams, and therefore any syntactic
error in the stream can cause the XML parser to quit with an error.
Another thing to be aware of is that there are certain XML
constructions that will not translate into BoulderIO format, specifically 
free text that contains embedded tags.  This is OK:

  <Author>Jean Siao</Author>

but this is not:

  <Author>The <Emphatic>extremely illustrious</Emphatic> Jean Siao</Author>

In BoulderIO format, tags can contain other tags or text, but cannot
contain a mixture of tags and text.

=head2 CONSTRUCTORS

=over 4

=item $stream = Boulder::XML->new(*IN,*OUT);

=item $stream = Boulder::XML->new(-in=>*IN,-out=>*OUT,-tag=>$tag,-delim=>$delim,-strip=>$strip)

new() creates a new Boulder::XML stream that can be read from or
written to.  All arguments are optional.

 -in    Filehandle to read from. 
        If a file name is provided, will open the file.
        Defaults to the magic <> filehandle.

 -out   Filehandle to write to.  
        If a file name is provided, will open the file for writing.
        Defaults to STDOUT

 -tag   The top-level XML tag to consider as the Stone record.  Defaults
        to the first tag seen when reading from an XML file, or to 
        E<lt>StoneE<gt> when writing to an output stream without
        previously having read.

 -delim Delimiter to use for delimiting multiple Stone objects in an
        XML stream.

 -strip If true, automatically strips leading and trailing whitespace 
        from text contained within tags.

=item $fh = Boulder::XML->newFh(*IN,*OUT);

=item $fh = Boulder::XML->newFh(-in=>*IN,-out=>*OUT,-tag=>$tag,-delim=>$delim,-strip=>$strip)

The newFh() constructor creates a tied filehandle that can read and
write Boulder::XML streams.  Invoking <> on the filehandle will
perform a get(), returning a Stone object.  Calling print() on the
filehandle will perform a put(), writing a Stone object to output in
XML format.

=back

=head2 METHODS

=over 4

=item $stone = $stream->get()

=item $stream->put($stone)

=item $done = $stream->done

All these methods have the same semantics as the similar methods in
L<Boulder::Stream>, except that pass-through behavior doesn't apply.

=back

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>, Cold Spring Harbor Laboratory,
Cold Spring Harbor, NY.  This module can be used and distributed on
the same terms as Perl itself.

=head1 SEE ALSO

L<Boulder>, L<Boulder::Stream>, L<Stone>

=cut

use Boulder::Stream;
use Stone;
use XML::Parser;

use strict;
use vars qw(@ISA);

@ISA = 'Boulder::Stream';
*rearrange = \&Boulder::Stream::rearrange;
*put = \&write_record;

sub new {
  my $package = shift;
  my($in,$out,$tag,$delim,$strip) = rearrange(['IN','OUT','TAG','DELIM','STRIP'],@_);
  my $self = bless {
		    'top_level' => $tag,
		    'delim' => $delim || '<!--Boulder::XML-->',
		    'strip' => $strip,
		    'in'  => Boulder::Stream->to_fh($in)    || \*ARGV,
		    'out' => Boulder::Stream->to_fh($out,1) || \*STDOUT,
		     },$package;
  my $parser = XML::Parser->new(
				ErrorContext => 2,
				Stream_Delimiter => $self->{delim},
			       );
  @ARGV = ('-') if $self->{in} == \*ARGV and !@ARGV;
  $parser->setHandlers(
		       Start   => sub { $self->_start(@_) },
		       Default => sub { $self->_default(@_) },
		       End     => sub { $self->_end(@_) } 
		      );
  $self->{'parser'} = $parser;
  return $self;
}

sub read_one_record {
  my ($self,@tags) = @_;
  return shift @{$self->{stones}} if $self->{stones} && @{$self->{stones}};
  my $fh = $self->magic_file_open || return;
  $self->{parser}->parse($fh);
  return shift @{$self->{stones}};
}

sub write_record {
  my $self = shift;
  my @stone = @_;
  my $out = $self->{out};
  print $out $self->{delim},"\n" if $self->{printed}++;
  print $out qq(<?xml version="1.0" standalone="yes"?>\n\n);
  for my $stone (@stone) {
    next unless ref $stone && $stone->can('asXML');
    print $out $stone->asXML($self->{top_level});
  }
}

sub magic_file_open {
  my $self = shift;
  my $fh = $self->{in};
  return $fh unless $fh == \*main::ARGV;
  return $fh unless eof $fh;
  return unless my $a = shift @ARGV;
  open $fh,$a or die "$a: $!";
  return $fh;
}

sub done {
  my $self = shift;
  return if defined $self->{stones} && @{$self->{stones}};
  return eof $self->{in} if $self->{in} != \*main::ARGV;
  return $self->{in} && eof $self->{in} && !@ARGV;
}

sub _default {
  my ($self,$p, $string) = @_;
  return unless $string=~/\S/;
  if ($self->{'strip'}) { # strip leading whitespace
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
  }

  return unless $self->{stack} && @{$self->{stack}};
  my $stone = $self->{stack}[-1];
  my $current = $stone->name();
  $current .= $string;
  $stone->name($current);
}

sub _start {
  my ($self,$p, $element, %attributes) = @_;

  $self->{top_level} ||= $element;
  if ($element eq $self->{top_level}) {
    $self->{stack} = [$self->{stone} = new Stone];  # empty stone
    $self->{stone}->attributes(\%attributes) if %attributes;
    return;
  }

  return unless $self->{stack}[-1];
  my $s = new Stone;
  $self->{stack}[-1]->insert($element => $s);
  push(@{$self->{stack}},$s);
  $s->attributes(\%attributes) if %attributes;
}

sub _end {
  my ($self,$p, $element) = @_;

  pop @{$self->{stack}};

  if ( $element eq $self->{top_level} ) { 
    push @{$self->{stones}},$self->{stone};
    delete $self->{stone};
    delete $self->{stack};
  }

}  # End end


1;
