#
# Bio::MAGE::XMLReader
#   a class for converting MAGE-ML into Perl objects
#   originally written by Eric Deutsch. Converted into a class
#   by Jason E. Stewart.
#
package Bio::MAGE::XML::Reader;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $DEBUG);
use Carp;
use XML::Xerces;
require Exporter;

use Data::Dumper;
use Benchmark;
use Bio::MAGE qw(:ALL);
use Bio::MAGE::Base;
use Carp;

=head1 NAME

Bio::MAGE::XML::Reader - a module for exporting MAGE-ML

=head1 SYNOPSIS

  use Bio::MAGE::XML::Reader;

  my $reader = Bio::MAGE::XML::Reader->new(handler=>$handler,
					 sax1=>$sax1,
					 verbose=>$verbose,
					 log_file=>\*STDERR,
					);

  # set the sax1 attribute
  $reader->sax1($bool);

  # get the current value
  $value = $reader->sax1();

  # set the content/document handler - this method is provided for completeness
  # the value should be set in the call to the constructor to be effective
  $reader->handler($HANDLER);

  # get the current handler
  $handler = $reader->handler();

  # set the attribute
  $reader->verbose($integer);

  # get the current value
  $value = $reader->verbose();

  # set the attribute
  $reader->log_file($filename);

  # get the current value
  $value = $reader->log_file();

  # whether to read data cubes externally (default == FALSE)
  $writer->external_data($bool);

  my $fh = \*STDOUT;
  my $mage = $reader->read($file_name);

=head1 DESCRIPTION

Methods for transforming information from a MAGE-OM objects into
MAGE-ML.

=cut

@ISA = qw(Bio::MAGE::Base Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

$DEBUG = 1;

###############################################################################
#
# Description : mageml_reader.pl is a MAGE-ML test reader.
#      It reads in a MAGE-ML document, instantiating the objects for
#      the # MAGE-OM class as they are read in.  Lots of diagnostic
#      information # is printed if --verbose is set.  In a final step,
#      a MAGE-ML document # is printed to STDOUT based on all the
#      information read in.  The # result should be (nearly) identical
#      to the XML read in when # everything is working properly.
#
# Search for flags:
#   - FIXME for known bugs/shortcomings
#   - DUBIOUS for things that are probably okay but could lead
#       to future problems.
#
###############################################################################

=head2 ATTRIBUTE METHODS

These methods have a polymorphic setter/getter method that sets an
attribute which affects the parsing of MAGE-ML. If given a value, the
method will save the value to the attribute, if invoked with no
argument it will return the current value of the attribute.

These attributes can all be set in the call to the constructor using
the named parameter style.

=over

=item sax1

This attribute determines whether a SAX1 parser and DocumentHandler or
a SAX2XMLReader and a ContentHandler will be used for parsing. The
default is to use a SAX2 parser.

=cut

sub sax1 {
  my $self = shift;
  if (@_) {
    $self->{__SAX1} = shift;
  }
  return $self->{__SAX1};
}

###############################################################################
# count: setter/getter for the scalar to track counting ouput
###############################################################################
sub count {
  my $self = shift;
  if (scalar @_) {
    $self->{__COUNT} = shift;
  }
  return $self->{__COUNT};
}

=item handler

If an application needs a custom handler it can set this attribute in
the call to the constructor. It is advised that the object use inherit
either from Bio::MAGE::XML::Handler::ContentHandler (if using SAX2) or
Bio::MAGE::DocumentHandler if using SAX1. In particular, whatever
class is used, it needs to implement the following methods:

=over

=item * verbose

called with the integer parameter that specifies the desired level of
output

=item * log_file

called with the file handle to which ouput should be sent

=item * init

called during the constructor for any needed work

=back

=cut

sub handler {
  my $self = shift;
  if (@_) {
    $self->{__HANDLER} = shift;
  }
  return $self->{__HANDLER};
}

=head2 parser

 Title   : parser
 Usage   : $obj->parser($newval)
 Function: 
 Example : 
 Returns : value of parser (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=cut

sub parser{
    my $self = shift;

    return $self->{__PARSE} = shift if @_;
    return $self->{__PARSE};
}

=item verbose

This attribute determines the desired level of output during the
parse. The default is no output. A positive value increases the amount
of information.

=cut

sub verbose {
  my $self = shift;
  if (@_) {
    $self->{__VERBOSE} = shift;
  }
  return $self->{__VERBOSE};
}

=item log_file

This attribute specifies a file handle to which parse output will be
directed. It is only needed if verbose is positive.

=cut

sub log_file {
  my $self = shift;
  if (@_) {
    $self->{__LOG_FILE} = shift;
  }
  return $self->{__LOG_FILE};
}

=item external_data($bool)

If defined, this will cause all BioAssayData objects to read
themselves out using the DataExternal format.

B<Default Value:> false

=cut

sub external_data {
  my $self = shift;
  if (@_) {
    $self->{__EXTERNAL_DATA} = shift;
  }
  return $self->{__EXTERNAL_DATA};
}


=item resolve_identifiers

This attribute specifies whether the reader should attempt to track
unhandled identifiers in the document, and then resolve them when
parsing is over. This can be a huge performance hit if you know that
all identifiers wil not resolve.

B<Default Value:> false

=cut

sub resolve_identifiers {
  my $self = shift;
  if (@_) {
    $self->{__RESOLVE_IDENTIFIERS} = shift;
  }
  return $self->{__RESOLVE_IDENTIFIERS};
}

=pod


=back


=head2 INSTANCE METHODS

=over

=item $self->read($file_name)

This method will open the MAGE-ML file specified by $file_name and if
the C<handler> attribute is not set, it will create either a SAX2
parser or a SAX1 parser (depending on the value of the C <sax1>
attribute) and parse the file. 

C<read()> can read from STDIN by specifying '-' as the filename. This
enables you to handle compressed XML files:

  gzip -dc file.xml.gz | read.pl [options]

=cut

sub read {
  my ($self,$file) = @_;

  unless ($file eq '-') {
    croak "File '$file' does not exist!\n"
      unless (-f $file);
  }

  my $parser = $self->parser();
  my $HANDLER = $self->handler();
  $HANDLER->count($self->count)
    if defined $self->count();

#  my $LOG = $self->log_file();
  my $LOG = new IO::File $self->log_file() , "w";

  my $VERBOSE = $self->verbose();

  #### Actually do the file parsing and loading
  if ($file eq '-') {
    $parser->parse (XML::Xerces::StdInInputSource->new());
  } else {
    my ($path) = $file =~ m|(.*/)|;
    $HANDLER->dir($path)
      if defined $path;
    $parser->parse (XML::Xerces::LocalFileInputSource->new($file));
  }

  #### Try to process any remaining unhandled objects.  These are
  #### most likely to be references encountered before the
  #### definition of that referenced object, but they might be dangling
  #### references which are permitted with the hope that some other
  #### entity can provide the needed information at some later time.
  ####
  #### Deutsch says: I'm not really thrilled with this way of doing things.
  #### It's a legacy from v1 of this code.  Couldn't we just check before
  #### instantiating an object to see if its identifier is already on the
  #### unhandled list and if so, don't even bother calling new() but rather
  #### flesh out the stub object into what it's really supposed to be?
  #### Deutsch continues: Maybe that wouldn't be any easier... leave it
  #### for now.  DUBIOUS.
  ####
  #### Will this even work if there are multiple unresolved references
  #### of the same type?  FIXME if not or remove this comment.
  print $LOG <<LOG if ($VERBOSE);
-----------------------------------------------\
Looking for any unresolved references:
LOG

  if ($self->resolve_identifiers) {
    my $UNHANDLED = $HANDLER->unhandled();
    foreach my $identifier (keys %{$UNHANDLED}) {

      print $LOG "Looking for unhandled: $identifier\n"
	if ($VERBOSE);

      my $array_ref = $UNHANDLED->{$identifier};

      #### Each item in unhandled is a three element array containing
      #### the object, classname and method that needs to be called to
      #### make the association

      foreach my $obj_array_ref (@{$array_ref}) {

	#### Obtain the object and method and classname
	my ($attribute,$object,$class) = @{$obj_array_ref};

	#### If there now is an object with this identifier, make the link
	if (exists $HANDLER->id->{$class}->{$identifier}) {
	  print $LOG "There now is corresponding object: $identifier\n"
	    if ($VERBOSE);
	  no strict 'refs';

	  #### If the place where the reference is supposed to be is in fact
	  #### an array, this must be an array of references instead, so deal
	  #### with that.  This may be a performance hit if there are thousands
	  #### of objects in the array, but it works for now.  DUBIOUS
	  my $value = $object->get_slot($attribute);
	  if (ref($value) eq 'ARRAY') {
	    #### So loop of each element in the array
	    for (my $i=0;$i<scalar @{$value};$i++) {
	      #### When we find the identifier, make the link
	      if ($value->[$i]->getIdentifier() eq $identifier) {
		$value->[$i] = $HANDLER->id->{$class}->{$identifier};
	      }
	    }

	    #### Otherwise it's just a single reference so make the link directly
	  } else {
	    $object->set_slot($attribute,$HANDLER->id->{$class}->{$identifier});
	  }

	  #### Delete the identifier from the unhandled list
	  delete $UNHANDLED->{$identifier};


	  #### Otherwise this identifier must not be in the document which
	  #### is allowed.  It may mean that the data are just stored someplace
	  #### else, or that it could indicate a mistake.
	} else {
	  print STDERR "WARNING: There is an unresolved ".
	    "$attribute '$identifier'\n" if ($VERBOSE);
	}

      }
    }
  }



  #### If we're verbose mode, print $LOG out a good bit of information
  #### about what's sitting in the HANDLER hash
  if ($VERBOSE) {
    print $LOG "\n-------------------------------------------------\n";
    my ($key,$value);
    my ($key2,$value2);

    #### Print $LOG out all the items in the HANDLER hash
    print $LOG "HANDLER:\n";
    while (($key,$value) = each %{$HANDLER}) {
      print $LOG "HANDLER->{$key} = $value:\n";
    }

    print $LOG "\n";
    #### Loop over the various items in the HANDLER hash
    #### and print $LOG out details about them
    while (($key,$value) = each %{$HANDLER}) {
	print $LOG "HANDLER->{$key}\n";

	if ($key eq "__ID" or $key eq "__UNHANDLED") {
	    while (($key2,$value2) = each %{$HANDLER->{$key}}) {
		print $LOG "  $key2 = $value2\n";
	    }
	} elsif ($key eq "__OBJ_STACK" or $key eq "__ASSN_STACK") {
	    foreach $key2 (@{$HANDLER->{$key}}) {
		print $LOG "  $key2\n";
	    }
	} elsif ($key eq '__MAGE' || $key eq '__CLASS2FULLCLASS' || $key eq '__DIR' || $key eq '__READER') {
	    #### Skip those ones
	    #### __DIR and __READER must be an array reference but they are not (__DIR : scalar ; __READER : HASH ref)
	} else {
	    foreach $key2 (@{$HANDLER->{$key}}) {
		print $LOG "  $key2\n";
	    }
	}
     }
  }


  #### Obtain the MAGE object from the HANDLER
  my $mage = $HANDLER->MAGE();


  #### If there was no MAGE object defined, die
  unless ($mage) {
    croak <<ERR;
ERROR: This MAGE-ML document has no top <MAGE-ML> tag! 
This should never happen.  complain to your MAGE-ML provider.
ERR
  }

  return $mage;
}

sub initialize {
  my $self = shift;

  my $HANDLER;
  my $parser;

  $self->verbose(0)
    unless $self->verbose();

  # Added by Mohammad on 19/11/03 shoja@ebi.ac.uk , Change begin 
  $self->external_data(0)
    unless defined $self->external_data();
  # Added by Mohammad on 19/11/03 shoja@ebi.ac.uk , Change end 

  if ($self->sax1) {
    $parser = XML::Xerces::SAXParser->new();
    $parser->setValidationScheme($XML::Xerces::SAXParser::Val_Always);
    $parser->setDoNamespaces(0);
    $parser->setDoSchema(0);
    if (defined $self->handler()) {
      $HANDLER = $self->handler();
    } else {
      $HANDLER = Bio::MAGE::XML::Handler::DocumentHandler->new();
      $self->handler($HANDLER);
    }
    $parser->setDocumentHandler($HANDLER);
  } else {
    $parser = XML::Xerces::XMLReaderFactory::createXMLReader();
    $parser->setFeature("http://xml.org/sax/features/namespaces", 0);
    $parser->setFeature("http://xml.org/sax/features/validation", 1);
    $parser->setFeature("http://apache.org/xml/features/validation/dynamic", 0);
    if (defined $self->handler()) {
      $HANDLER = $self->handler();
    } else {
      $HANDLER = Bio::MAGE::XML::Handler::ContentHandler->new();
      $self->handler($HANDLER);
    }
    $parser->setContentHandler($HANDLER);
  }
  $self->resolve_identifiers(1)
    unless defined $self->resolve_identifiers;

  # this way the handler can access our attributes (verbose, log_file, etc)
  $HANDLER->reader($self);
  $HANDLER->init();

  my $error_handler = XML::Xerces::PerlErrorHandler->new();
  $parser->setErrorHandler($error_handler);

  $self->parser($parser);

  return 1;
}

=pod

=back

=cut

1;
