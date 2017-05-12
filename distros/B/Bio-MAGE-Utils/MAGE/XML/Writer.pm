#
# Bio::MAGE::XML::Writer.pm
#   a module for exporting MAGE-ML
#
package Bio::MAGE::XML::Writer;

use strict;
use vars qw($VERSION $DEBUG);
use Carp;
use Bio::MAGE;
use XML::Xerces;

$VERSION = 2006_08_15.0;

=head1 NAME

Bio::MAGE::XML::Writer - a module for exporting MAGE-ML

=head1 SYNOPSIS

  use Bio::MAGE::XMLUtils;

  my $writer = Bio::MAGE::XML::Writer->new(@args);
  $writer->write($mage);

  #
  # attributes to modify where the output is written
  #

  # set the output filehandle
  my $fh = \*STDOUT;
  $writer->fh($fh);

  # whether to write data cubes externally (default == FALSE)
  $writer->external_data($bool);

  # which directory to write external data cubes (default == /tmp)
  $writer->external_data_dir($path);

  # whether the to interpret the C<cube> as data or a file
  # path (default == FALSE)
  $writer->cube_holds_path($bool);

  #
  # attributes to modify the output format
  #

  # which format is the external data file
  $writer->data_format($dataformat);

  # to change the level of indent for each new tag (defaul == 2)
  $writer->indent_increment($num);

  # to change the beginning indent level (defaul == 0)
  $writer->indent_level($num);

  # set to true to not format attributes (default == FALSE)
  $writer->attrs_on_one_line($bool);

  # how many extra spaces attributes should be indented past start
  # tag end (default == 1)
  $writer->attr_indent($num);

  # whether to write all sub-tags on the same line (default == undef)
  $writer->collapse_tag($bool);

  #
  # attributes to modify the the document
  #

  # to change the encoding (default == ISO-8859-1)
  $writer->encoding($format);

  # to set the public id (default == undef)
  $writer->public_id($id);

  # to change the system id (default == MAGE-ML.dtd)
  $writer->system_id($id);

  # check to see that objects set more than just identifier (default == TRUE)
  $writer->empty_identifiable_check();

  #
  # attributes to handle identifiers
  #

  # whether to create identifiers if not specified (default == FALSE)
  $writer->generate_new_identifiers();

  # code reference to be invoked for creating new identifiers
  $writer->generate_identifier();

=head1 DESCRIPTION

Methods for transforming information from a MAGE-OM objects into
MAGE-ML.

=cut

use base qw(Bio::MAGE::Base);

$DEBUG = 1;

sub initialize {
  my ($self) = shift;
  $self->tag_buffer([]);
  $self->cube_holds_path(0)
    unless defined $self->cube_holds_path();
  $self->attrs_on_one_line(0)
    unless defined $self->attrs_on_one_line();
  $self->attr_indent(1)
    unless defined $self->attr_indent();
  $self->indent_increment(2)
    unless defined $self->indent_increment();
  $self->indent_level(0)
    unless defined $self->indent_level();
  $self->data_format('tab delimited')
    unless defined $self->data_format();
  $self->external_data(0)
    unless defined $self->external_data();
  $self->external_data_dir('/tmp')
    unless defined $self->external_data_dir();
  $self->empty_identifiable_check(1)
    unless defined $self->empty_identifiable_check();
  $self->encoding('ISO-8859-1')
    unless defined $self->encoding();
  $self->system_id('MAGE-ML.dtd')
    unless defined $self->system_id();
  $self->generate_identifier(sub {$self->identifier_generatation(shift)})
    unless defined $self->generate_identifier();
  $self->generate_new_identifiers(0)
    unless defined $self->generate_new_identifiers();
}

sub incr_indent {
  my $self = shift;
  $self->indent_level($self->indent_level + $self->indent_increment);
}

sub decr_indent {
  my $self = shift;
  $self->indent_level($self->indent_level - $self->indent_increment);
}

=head1 METHODS

=item write($MAGE_object);

C<write()> prints the objects contained in $MAGE_object as MAGE-ML to
the file handle used by the writer.

=cut

sub write {
  my ($self,$top_level_obj) = @_;
  die __PACKAGE__."::write: must specify a file handle for output"
    unless defined $self->fh();

  # handle the basics
  $self->write_xml_decl();
  $self->write_doctype();

  $top_level_obj->obj2xml($self);
}

sub write_xml_decl {
  my $self = shift;
  my $fh = $self->fh();
  my $encoding = $self->encoding();
  print $fh <<"MAGEML";
<?xml version="1.0" encoding="$encoding" standalone="no"?>
MAGEML
}

sub write_doctype {
  my $self = shift;
  my $public_id = $self->public_id();
  my $PUBLIC;
  if (defined $public_id) {
    $PUBLIC = qq[PUBLIC "$public_id"];
  } else {
    $PUBLIC = '';
  }
  my $system_id = $self->system_id();
  my $SYSTEM;
  if (defined $public_id) {
    $SYSTEM = qq["$system_id"];
  } else {
    $SYSTEM = qq[SYSTEM "$system_id"];
  }
  my $fh = $self->fh();
  print $fh <<"MAGEML";
<!DOCTYPE MAGE-ML $PUBLIC $SYSTEM>
MAGEML
}

sub write_start_tag {
  my ($self,$tag,$empty,%attrs) = @_;
  my $indent = ' ' x $self->indent_level();
  my $buffer;
  my (@attrs);
  foreach my $attribute_name (keys %attrs) {

      my $attribute_val = $attrs{$attribute_name};
      $attribute_val =~ s/\&/&amp;/g;
      $attribute_val =~ s/\&amp;amp;/&amp;/g;
      $attribute_val =~ s/\"/&quot;/g;
      $attribute_val =~ s/\&amp;quot;/&quot;/g;
      $attribute_val =~ s/\'/&apos;/g;
      $attribute_val =~ s/\&amp;apos;/&apos;/g;
      $attribute_val =~ s/\>/&gt;/g;
      $attribute_val =~ s/\&amp;gt;/&gt;/g;
      $attribute_val =~ s/\</&lt;/g;
      $attribute_val =~ s/\&amp;lt;/&lt;/g;
      
      push(@attrs,qq[$attribute_name="$attribute_val"]);
  }
  my ($attrs,$attr_indent);
  if ($self->attrs_on_one_line()) {
    $attrs = join(' ',@attrs);
  } else {
    # we add one to compensate for the '<' in the start tag
    $attr_indent = $self->attr_indent() + 1;
    $attr_indent += length($tag);
    $attr_indent = ' ' x $attr_indent . $indent;
    $attrs = join("\n$attr_indent",@attrs);
  }
  if ($attrs) {
    $buffer .= "$indent<$tag $attrs";
  } else {
    # don't print the space after the tag because Eric said so
    $buffer .= "$indent<$tag";
  }
  if ($empty) {
    $buffer .= '/>';
  } else {
    $buffer .= '>';
  }
  $buffer .= "\n" unless $self->collapse_tag();
  $self->incr_indent()
    unless $empty;

  # we don't actually write out the tag yet. We buffer it on a stack
  # until we actually know we should write it out
  push(@{$self->tag_buffer},$buffer);

  # if this was an empty tag, we immediately flush the buffer
  $self->flush_tag_buffer()
    if $empty;
}

sub flush_tag_buffer {
  my $self = shift;
  my $fh = $self->fh();
  my $tag_buffer = $self->tag_buffer();
  while (my $string = shift @{$tag_buffer}) {
    print $fh $string;
  }
}

sub write_end_tag {
  my ($self,$tag) = @_;
  $self->decr_indent();

  # if there is still something on the tag buffer, we must not have
  # had any data to write, so don't write the end tag
  if (scalar @{$self->tag_buffer}) {
    pop(@{$self->tag_buffer});
    return;
  }
  my $indent = ' ' x $self->indent_level();
  my $fh = $self->fh();
  print $fh "$indent</$tag>\n";
}

# we purposefully avoid copying the text, since it may be BIG
sub write_text {
  my $self = shift;
  my $fh = $self->fh();
  print $fh $_[0];
}

#
# Helper methods
#

sub identifier_generation {
  my ($self,$obj) = @_;
  my $known_identifiers = $self->identifiers();
  return if exists $known_identifiers->{$obj->getIdentifier};

  # stringify the object: Bio::MAGE::Identifiable=SCALAR(0x10379980)
  my $identifier = $obj;
  # strip of the leading class qualifiers: Identifiable=SCALAR(0x10379980)
  $identifier =~ s/^Bio::MAGE:://;
  # convert the '=' to a colon: Identifiable:SCALAR(0x10379980)
  $identifier =~ tr/=/:/;
  # remove the SCALAR: Identifiable:10379980
  $identifier =~ s/SCALAR\(0x(.*)\)/$1/;
  $obj->setIdentifier($identifier);
}

sub obj2xml_ref {
  my ($self,$obj) = @_;

  # create the <*_ref> tag
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;
  $tag .= '_ref';

  # we create the empty tag with only the identifier
  my $empty = 1;
  $self->write_start_tag($tag,$empty,identifier=>$obj->getIdentifier());
}

sub flatten {
  my ($self,$list) = @_;
  my @list;
  foreach my $item (@{$list}) {
    if (ref($item) eq 'ARRAY') {
      push(@list,$self->flatten($item));
    } else {
      push(@list,$item);
    }
  }
  return join("\t",@list);
}

sub external_file_id {
  my $self = shift;
  my $num = $self->external_data();
  $num++;
  $self->external_data($num);
  return "external-data-$num.txt";
}

sub write_bio_data_tuples() {
  my ($self,$obj) = @_;

  # has no attributes

  # the tag name is the name of the class
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;
  $self->write_start_tag($tag,my $empty = 0);

  # make the data structure
  my %data;
  my %des;
  my %bas;
  my %qts;
  foreach my $datum (@{$obj->getBioAssayTupleData()}) {
    my $de = $datum->getDesignElement();
    my $ba = $datum->getBioAssay();
    my $qt = $datum->getQuantitationType();

    my $ba_id = $ba->getIdentifier();
    my $qt_id = $qt->getIdentifier();
    my $de_id = $de->getIdentifier();

    # store the datum object
    $data{$ba_id}->{$de_id}{$qt_id} = $datum;

    # store the design element obj
    $des{$de_id} = $de;
    # store the quantitation type obj
    $qts{$qt_id} = $qt;
    # store the bioassay obj
    $bas{$ba_id} = $ba;
  }

  # write the container tag
  $tag = 'BioAssayTuples_assnlist';
  my $EMPTY = 0;
  my $NOT_EMPTY = 1;
  $self->write_start_tag($tag,$EMPTY);
  # write the XML
  foreach my $ba (keys %data) {
    # write the BioAssayTuple container tag
    my $bat_tag = 'BioAssayTuple';
    $self->write_start_tag($bat_tag,$EMPTY);

    # write the container tag
    my $tag = 'BioAssay_assnref';
    $self->write_start_tag($tag,$EMPTY);

    # write the BioAssay ref object
    my $ba_obj = $bas{$ba};#bioassay
    $self->obj2xml_ref($ba_obj);

    # end the BioAssay_ref container tag
    $self->write_end_tag($tag);

    # write the container tag
    $tag = 'DesignElementTuples_assnlist';
    $self->write_start_tag($tag,$EMPTY);
    foreach my $de (keys %{$data{$ba}}) {
      # write the DesignElementTuple container tag
      my $det_tag = 'DesignElementTuple';
      $self->write_start_tag($det_tag,$EMPTY);

      my $tag = 'DesignElement_assnref';
      # write the container tag
      $self->write_start_tag($tag,$EMPTY);

      # write the DesignElement ref object
      my $de_obj = $des{$de};		#design element
      $self->obj2xml_ref($de_obj);

      # end the DesignElement ref container tag
      $self->write_end_tag($tag);

      # write the container tag
      $tag = 'QuantitationTypeTuples_assnlist';
      $self->write_start_tag($tag,$EMPTY);
      foreach my $qt (keys %{$data{$ba}->{$de}}) {
	# write the QuantitationTypeTuple container tag
	my $qtt_tag = 'QuantitationTypeTuple';
	$self->write_start_tag($qtt_tag,$EMPTY);

	my $tag = 'QuantitationType_assnref';
	# write the container tag
	$self->write_start_tag($tag,$EMPTY);

	# write the QuantitationType ref object
	my $ba_obj = $qts{$qt};		#quantitation type
	$self->obj2xml_ref($ba_obj);

	# end the Quantitation Type ref container tag
	$self->write_end_tag($tag);

	# write the datum container tag
	my $datum_tag = 'Datum_assn';
	$self->write_start_tag($datum_tag,$EMPTY);

	# write the datum tag
	$tag = 'Datum';
	my $value = $data{$ba}->{$de}{$qt}->getValue();
	die "no $value for BioAssay: ", $ba,
	  ", DesignElement: ", $de,
	    ", QuantitationType: ", $qt,
	  unless defined $value;
	my %attrs = (value=>$value);
	$self->write_start_tag($tag,$NOT_EMPTY,%attrs);

	# end the Datum container tag
	$self->write_end_tag($datum_tag);

	# end the QuantitationTypeTuple container tag
	$self->write_end_tag($qtt_tag);
      }
      # end the QuantitationTypeTuples_list container tag
      $self->write_end_tag($tag);

      # end the DesignElementTuple container tag
      $self->write_end_tag($det_tag);
    }
    # end the DesignElementTuples_list container tag
    $self->write_end_tag($tag);

    # end the BioAssayTuple container tag
    $self->write_end_tag($bat_tag);
  }
  # end the BioAssayTuples_list container tag
  $self->write_end_tag($tag);

  # end the BioDataTuples tag
  $self->write_end_tag('BioDataTuples');
}

sub obj2xml {
  my ($self,$obj) = @_;

  if ($obj->isa("Bio::MAGE::BioAssayData::BioDataTuples")) {
    return $self->write_bio_data_tuples($obj);
  }

  # all attributes are gathered into a hash
  my %attributes;
  my $data;
  foreach my $attribute ($obj->get_attribute_names()) {

    # $obj->get_attribute_names can return an array with empty ('')
    # values.
    next unless $attribute;

    my $attribute_val;
    {
      no strict 'refs';
      my $getter_method = 'get'.ucfirst($attribute);
      $attribute_val = $obj->$getter_method();
      if (defined $attribute_val) {
	if ($attribute eq 'cube') {
	  if ($self->cube_holds_path()) {
	    # the cube holds the path to an already written file
	    # so we don't bother interpreting it
	    $data = $attribute_val;
	  } else {
	    $data = $self->flatten($attribute_val);
	  }
	  next;
	}
	$attribute_val =~ s/\&/&amp;/g;
	$attribute_val =~ s/\&amp;amp;/&amp;/g;
	$attribute_val =~ s/\"/&quot;/g;
	$attribute_val =~ s/\&amp;quot;/&quot;/g;
	$attribute_val =~ s/\'/&apos;/g;
	$attribute_val =~ s/\&amp;apos;/&apos;/g;
	$attribute_val =~ s/\>/&gt;/g;
	$attribute_val =~ s/\&amp;gt;/&gt;/g;
	$attribute_val =~ s/\</&lt;/g;
	$attribute_val =~ s/\&amp;lt;/&lt;/g;
	$attributes{$attribute} = $attribute_val;
      }
    }
  }
  # the tag name is the name of the class
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;

  # we create the start tag, with the object attributes represented as
  # element attributes. If the object has no associations we make it
  # an empty element - this is to avoid XML validation errors
  my $empty = not scalar $obj->associations();
  my $xml_written = 0;
  $self->write_start_tag($tag,$empty,%attributes);

  # if we discover an object that only has it's identifier attribute set
  # we don't flush the tag buffer
  unless ($self->empty_identifiable_check() and
	  exists $attributes{identifier} and
	  scalar keys %attributes == 1) {
    $self->flush_tag_buffer();
    $xml_written = 1;
  }

  # associations are handled as sub-elements of the current element
  # and we use the association meta-data to instruct how to represent
  # each association
  #
  # We use the IxHash module because the associations are ordered
  # in the same order the DTD expects to receive them, and IxHash
  # preserves insertion order
  tie my %assns_hash, 'Tie::IxHash', $obj->associations();
  foreach my $association (keys %assns_hash) {
    my $association_obj;
    {
      no strict 'refs';
      my $getter_method = 'get'.ucfirst($association);
      $association_obj = $obj->$getter_method();
    }
    if (defined $association_obj) {
      # we've found an association object, so if we were delaying
      # the writing of the code, we write it out now
      unless ($xml_written) {
	$self->flush_tag_buffer();
	$xml_written = 1;
      }

      # if this is a bi-navigable association, and we there is an aggregate
      # association from the other end, we do *not* write the object out
      # we know it's bi-navigable if self->name is defined
      # we know it's aggregate if other->is_ref is not true
      if (defined $assns_hash{$association}->self->name()
	  and not $assns_hash{$association}->other->is_ref()
	 ) {
	next;
      }

      # we first create the container tag with the proper prefix
      # to know if this is a ref element or not we look at the self
      # side of the association
      my $prefix;
      my $is_ref = $assns_hash{$association}->self->is_ref();
      if ($is_ref) {
	$prefix = '_assnref';
      } else {
	$prefix = '_assn';
      }
      my @association_objects;
      if ($assns_hash{$association}->other->is_list) {
	$prefix .= 'list';
	@association_objects = @{$association_obj};
      } else {
	@association_objects = ($association_obj);	
      }
      my $container_tag = ucfirst("$association$prefix");
      # container tags must not be empty
      $self->write_start_tag("$container_tag",my $cont_empty=0);

      # now we fill in the container with the object(s)
      foreach $association_obj (@association_objects) {
	if ($is_ref) {
	  $self->obj2xml_ref($association_obj)
	} else {
	  $self->obj2xml($association_obj);
	}
      }
      # now end the container tag
      $self->write_end_tag("$container_tag");
    }
  }
  if (defined $data) {
    if ($self->external_data()) {
      my %attributes;
      if ($self->cube_holds_path()) {
        $attributes{filenameURI} = $data;
      } else {
        $attributes{filenameURI} = $self->external_file_id();
      }
      $attributes{dataFormat} = $self->data_format();

      my $tag = 'DataExternal_assn';
      $self->write_start_tag($tag,my $empty=0);
      # we need to make it external
      {
        my $tag = 'DataExternal';
        $self->write_start_tag($tag,my $empty=1,%attributes);
        
        # if we've been told the cube is already written, we don't
        # bother re-writing it
        unless ($self->cube_holds_path()) {
          my $dir = $self->external_data_dir();
          open(DATA, ">$dir/$attributes{filenameURI}")
            or die "Couldn't open $dir/$attributes{filenameURI} for writing";
          print DATA $data;
          close(DATA);
        }
      }
      $self->write_end_tag($tag);
    } else {
      # we make it internal
      my $tag = 'DataInternal_assn';
      $self->write_start_tag($tag,0);
      {
        my $tag = 'DataInternal';
        $self->write_start_tag($tag,0);
        $self->flush_tag_buffer;
        my $fh = $self->fh();
        print $fh "<![CDATA[$data]]>";
        $self->write_end_tag($tag);
      }
      $self->write_end_tag($tag);
    }
  }
  # now end the current element
  $self->write_end_tag($tag)
      unless $empty;
}

sub is_bio_mage_object {
  my ($self,$obj) = @_;
  return UNIVERSAL::isa($obj,'Bio::MAGE');
}

=head1 ATTRIBUTE METHODS

  The following methods must all be invoked using an instance of Bio::MAGE::XML::Writer;

=over

=cut

=item indent_level($num)

This attribute controls the current level of indentation while writing
a document. It should not be manipulated by users, unless for some
reason you wanted to set the starting indent level to something other
than zero.

B<Default Value:> 0 (zero)

=cut

sub indent_level {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_LEVEL} = shift;
  }
  return $self->{__INDENT_LEVEL};
}



=item indent_increment($num)

This attribute controls the the number of spaces that added to the
indent for every new level of elements.

B<Default Value:> 2

=cut

sub indent_increment {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_INCREMENT} = shift;
  }
  return $self->{__INDENT_INCREMENT};
}

=item attrs_on_one_line($bool)

This attribute controls whether attribute values should be
pretty-printed. If true, attributes will not pretty-printed, but will
instead be written out all on one line.

B<Default Value:> false

=cut

sub attrs_on_one_line {
  my $self = shift;
  if (@_) {
    $self->{__ATTRS_ON_ONE_LINE} = shift;
  }
  return $self->{__ATTRS_ON_ONE_LINE};
}

=item attr_indent($bool)

Controls how many spaces past the end start tag that attributes should
be indented. This example shows an C<attr_inden> of 1:

      <Reporter identifier="Reporter:X Units Per Pixel"
                name="X Units Per Pixel">

The following illustrates and C<attr_indent> of -2:

      <Person firstName="John"
           identifier="Person:John Smith"
           name="John Smith"
           lastName="Smith">

B<Default Value:> 1

=cut

sub attr_indent {
  my $self = shift;
  if (@_) {
    $self->{__ATTR_INDENT} = shift;
  }
  return $self->{__ATTR_INDENT};
}

=item collapse_tag($bool)

This attribute is not very useful at the moment. In the future it may
be used to specify tags that should have their contents all on a
single line.

Currently it controls whether or not to write a newline after each
elements start tag, with no method to decide to write or not to write
based on the name of the tag.

B<Default Value:> false

=cut

sub collapse_tag {
  my $self = shift;
  if (@_) {
    $self->{__COLLAPSE_TAG} = shift;
  }
  return $self->{__COLLAPSE_TAG};
}

=item encoding($string)

This is the value that value be written out as the encoding attribute
for the XML Declaration of the output MAGE-ML document:

  <?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>

B<Default Value:> ISO-8859-1

=cut

sub encoding {
  my $self = shift;
  if (@_) {
    $self->{__ENCODING} = shift;
  }
  return $self->{__ENCODING};
}

=item public)_id($string)

If defined, this value will be written out as the value of the PUBLIC
attribute of the DOCTYPE tag in the output MAGE-ML document.

B<Default Value:> undef

=cut

sub public_id {
  my $self = shift;
  if (@_) {
    $self->{__PUBLIC_ID} = shift;
  }
  return $self->{__PUBLIC_ID};
}

=item system_id($string)

If defined, this value will be written out as the value of the SYSTEM
attribute of the DOCTYPE tag in the output MAGE-ML document:

  <!DOCTYPE MAGE-ML  SYSTEM "MAGE-ML.dtd">

B<Default Value:> MAGE-ML.dtd

=cut

sub system_id {
  my $self = shift;
  if (@_) {
    $self->{__SYSTEM_ID} = shift;
  }
  return $self->{__SYSTEM_ID};
}

=item generate_identifier($code_ref)

This attribute stores a code reference that will be invoked to create
a new identifier for any object that does not already have one
defined. This will happen only if the C<generate_new_identifiers>
attribute is set to true.

B<Default Value:> \&identifier_generation

=cut

sub generate_identifier {
  my $self = shift;
  if (@_) {
    $self->{__GENERATE_IDENTIFIER} = shift;
  }
  return $self->{__GENERATE_IDENTIFIER};
}

=item generate_new_identifier($bool)

If this attribute is set to true, the code reference store in the
C<generate_identifier> attribute will be invoked to create a new
identifier for any object that does not already have one defined.

B<Default Value:> false

=cut

sub generate_new_identifiers {
  my $self = shift;
  if (@_) {
    $self->{__GENERATE_NEW_IDENTIFIERS} = shift;
  }
  return $self->{__GENERATE_NEW_IDENTIFIERS};
}

=item fh($file_handle)

This is the file handle to which the MAGE-ML document will be written.

B<Default Value:> undef

=cut

sub fh {
  my $self = shift;
  if (@_) {
    $self->{__FH} = shift;
  }
  return $self->{__FH};
}

sub tag_buffer {
  my $self = shift;
  if (@_) {
    $self->{__TAG_BUFFER} = shift;
  }
  return $self->{__TAG_BUFFER};
}

=item external_data($bool)

If defined, this will cause all BioAssayData objects to write
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


=item data_format($format)

$format is either 'tab delimited' or 'space delimited'

B<Default Value:> 'tab delimited'

=cut

sub data_format {
  my $self = shift;
  if (@_) {
    $self->{__DATA_FORMAT} = shift;
  }
  return $self->{__DATA_FORMAT};
}

=item external_data_dir($path)

The C<fh> attribute only controls where the main MAGE-ML document is
written. If the C<external_data> attribute is set, the writer will
also create a seperate external data file for each data cube.

The C<external_data_dir> controls what director those files are
written to.

B<Default Value:> /tmp

=cut

sub external_data_dir {
  my $self = shift;
  if (@_) {
    $self->{__EXTERNAL_DATA_DIR} = shift;
  }
  return $self->{__EXTERNAL_DATA_DIR};
}

=item cube_holds_path($path)

Sometimes, you already have your data written to an external file, and
you simply want to reuse the file without any extra overhead. The
C<cube_holds_path> attribute controls indicates that you are storing
the path to the external file in the C<cube> attribute of the
C<BioDataCube> objects.

B<Default Value:> false

=cut

sub cube_holds_path {
  my $self = shift;
  if (@_) {
    $self->{__CUBE_HOLDS_PATH} = shift;
  }
  return $self->{__CUBE_HOLDS_PATH};
}

=item empty_identifiable_check($bool)

If true, all objects that define an C<identifier> attribute and no
other attributes will only be included as <*_ref> elements.

B<NOTE:> Currently no checking of association values is made, only
attributes. So if you want to ensure that an Identifiable object is
written, make sure that you set the C<name> attribute as well as the
C<identifier> attribute.

B<Default Value:> true

=cut

sub empty_identifiable_check {
  my $self = shift;
  if (@_) {
    $self->{__EMPTY_IDENTIFIABLE_CHECK} = shift;
  }
  return $self->{__EMPTY_IDENTIFIABLE_CHECK};
}

1;
