#
# Bio::MAGE::SQLUtils.pm
#   a module for exporting MAGE-OM objects to a database
#
package Bio::MAGE::SQLWriter;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $DEBUG);
use Carp;
use Bio::MAGE;
use Bio::MAGE::Base;
use XML::Xerces;
require Exporter;

use constant CARD_1 => '1';
use constant CARD_0_OR_1 => '0..1';
use constant CARD_1_TO_N => '1..N';
use constant CARD_0_TO_N => '0..N';

=head1 NAME

Bio::MAGE::SQLWriter - a module for exporting MAGE-OM objects to a database

=head1 SYNOPSIS

  use Bio::MAGE::SQLWriter;

  my $writer = Bio::MAGE::SQLWriter->new(@args);
  use dbhandle;
  my $dbhandle = dbhandle->new();
  $writer->obj2database($dbhandle,@object_list);

=head1 DESCRIPTION

Methods for transforming information from a MAGE-OM objects into
tuples in a MAGE database.


=cut

@ISA = qw(Bio::MAGE::Base Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(obj2database);

$DEBUG = 1;


sub indent_level {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_LEVEL} = shift;
  }
  return $self->{__INDENT_LEVEL};
}

sub indent_increment {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_INCREMENT} = shift;
  }
  return $self->{__INDENT_INCREMENT};
}

sub attrs_on_one_line {
  my $self = shift;
  if (@_) {
    $self->{__ATTRS_ON_ONE_LINE} = shift;
  }
  return $self->{__ATTRS_ON_ONE_LINE};
}

sub attr_indent {
  my $self = shift;
  if (@_) {
    $self->{__ATTR_INDENT} = shift;
  }
  return $self->{__ATTR_INDENT};
}

sub collapse_tag {
  my $self = shift;
  if (@_) {
    $self->{__COLLAPSE_TAG} = shift;
  }
  return $self->{__COLLAPSE_TAG};
}

sub encoding {
  my $self = shift;
  if (@_) {
    $self->{__ENCODING} = shift;
  }
  return $self->{__ENCODING};
}

sub public_id {
  my $self = shift;
  if (@_) {
    $self->{__PUBLIC_ID} = shift;
  }
  return $self->{__PUBLIC_ID};
}

sub system_id {
  my $self = shift;
  if (@_) {
    $self->{__SYSTEM_ID} = shift;
  }
  return $self->{__SYSTEM_ID};
}

sub generate_identifier {
  my $self = shift;
  if (@_) {
    $self->{__GENERATE_IDENTIFIER} = shift;
  }
  return $self->{__GENERATE_IDENTIFIER};
}

sub generate_new_identifiers {
  my $self = shift;
  if (@_) {
    $self->{__GENERATE_NEW_IDENTIFIERS} = shift;
  }
  return $self->{__GENERATE_NEW_IDENTIFIERS};
}

sub indent_level {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_LEVEL} = shift;
  }
  return $self->{__INDENT_LEVEL};
}

sub external_data {
  my $self = shift;
  if (@_) {
    $self->{__EXTERNAL_DATA} = shift;
  }
  return $self->{__EXTERNAL_DATA};
}


###############################################################################
# fh: setter/getter for the file handle
###############################################################################
sub fh {
  my $self = shift;
  if (@_) {
    $self->{__FH} = shift;
  }
  return $self->{__FH};
}


###############################################################################
# dbhandle: setter/getter for the database handle
###############################################################################
sub dbhandle {
  my $self = shift;
  if (@_) {
    $self->{__DBHANDLE} = shift;
  }
  return $self->{__DBHANDLE};
}


###############################################################################
# object_stack: setter/getter for the stack on which objects are placed
###############################################################################
sub object_stack {
  my $self = shift;
  if (@_) {
    $self->{__OBJECT_STACK} = shift;
  }
  return $self->{__OBJECT_STACK};
}


###############################################################################
# assn_stack: setter/getter for the stack on which assn's are placed
###############################################################################
sub assn_stack {
  my $self = shift;
  if (@_) {
    $self->{__ASSN_STACK} = shift;
  }
  return $self->{__ASSN_STACK};
}


###############################################################################
# object_IDs: setter/getter for the hash table which holds database ID's
###############################################################################
sub object_IDs {
  my $self = shift;
  if (@_) {
    $self->{__OBJECT_IDS} = shift;
  }
  return $self->{__OBJECT_IDS};
}


sub identifier {
  my $self = shift;
  if (@_) {
    $self->{__IDENTIFIER} = shift;
  }
  return $self->{__IDENTIFIER};
}

sub initialize {
  my ($self) = shift;
  $self->indent_increment(2);
  $self->indent_level(0);
  $self->external_data(0)
    unless defined $self->external_data();
  $self->encoding('ISO-8859-1')
    unless defined $self->encoding();
  $self->system_id('MAGE-ML.dtd')
    unless defined $self->system_id();
  $self->generate_identifier(sub {$self->identifier_generatation(shift)})
    unless defined $self->generate_identifier();
  $self->generate_new_identifiers(0)
    unless defined $self->generate_new_identifiers();

  #### Initialize the various stacks and lookup tables
  $self->object_stack([]);
  $self->assn_stack([]);
  $self->object_IDs({});

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
  die "Bio::MAGE::SQLWriter::write: must specify a file handle and a ".
    "database handle for output"
    unless ((defined $self->fh()) && (defined $self->dbhandle()));

  # handle the basics
  #$self->write_xml_decl();
  #$self->write_doctype();

  $top_level_obj->obj2database($self);
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
  my $SYSTEM = qq[SYSTEM "$system_id"];
  my $fh = $self->fh();
  print $fh <<"MAGEML";
<!DOCTYPE MAGE-ML $PUBLIC $SYSTEM>
MAGEML
}

sub write_start_tag {
  my ($self,$tag,$empty,%attrs) = @_;
  my $indent = ' ' x $self->indent_level();
  my $fh = $self->fh();
  my (@attrs);
  foreach my $attribute_name (keys %attrs) {
    push(@attrs,qq[$attribute_name="$attrs{$attribute_name}"]);
  }
  my ($attrs,$attr_indent);
  if ($self->attrs_on_one_line()) {
    $attrs = join(' ',@attrs);
  } else {
    $attr_indent = $self->attr_indent();
    $attr_indent = length($tag) + 2
      unless defined $attr_indent;
    $attr_indent = ' ' x $attr_indent . $indent;
    $attrs = join("\n$attr_indent",@attrs);
  }
  if ($attrs) {
    print $fh "$indent<$tag $attrs";
  } else {
    # don't print the space after the tag because Eric said so
    print $fh "$indent<$tag";
  }
  if ($empty) {
    print $fh '/>';
  } else {
    print $fh '>';
  }
  print $fh "\n" unless $self->collapse_tag();
  $self->incr_indent()
    unless $empty;
}

sub write_end_tag {
  my ($self,$tag) = @_;
  $self->decr_indent();
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


###############################################################################
# obj2database_ref: write a reference object to the database
###############################################################################
sub obj2database_ref {
  my ($self,$obj) = @_;

  # create the <*_ref> tag
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;
  $tag .= '_ref';

  # we create the empty tag with only the identifier
  my $empty = 1;
  #$self->write_start_tag($tag,$empty,identifier=>$obj->getIdentifier());

  my $dbhandle = $self->dbhandle();
  my $table_name = $tag;
  $table_name =~ s/_ref$//;

  my $referring = $self->object_stack->[-1];
  my $association = $self->assn_stack->[-1];
  my $target_ID = $self->object_IDs->{$obj};
  unless ($target_ID) {
    #print "+++ Yipe, the target object hasn't been written yet.\n";
    #print "    Try to write the object:\n";
    $self->obj2database($obj);
    $target_ID = $self->object_IDs->{$obj};
    die "INTERNAL ERROR: Failed to INSERT needed object $obj\n"
      unless ($target_ID);
  }


  #print "referring: ",join(" , ",@{$referring}),"\n";
  #print "assn: ",join(" , ",@{$association}),"\n";
  #print "cardinality: ",$association->[0]->cardinality(),"\n";
  #print "name: ",$association->[0]->name(),"\n";
  #print "class_name: ",$association->[0]->class_name(),"\n";


  #### If cardinality is 1 or 0..1
  if ($association->[0]->other->cardinality() eq CARD_0_OR_1 ||
      $association->[0]->other->cardinality() eq CARD_1) {
    my $table_name = $referring->[0]->class_name();
    $table_name =~ s/.+:://;
    my $assn_name = $association->[0]->other->name();
    my %rowdata = ($assn_name.'_fk'=>$target_ID);
    $dbhandle->updateOrInsertRow(
      update=>1,
      table_name=>$table_name,
      rowdata_ref=>\%rowdata,
      PK=>"ID",
      PK_value=>$referring->[1],
      print_SQL=>1,
      testonly=>1,
    );
    print "\n";

  #### If cardinality is 0..n or 1..n
  } elsif ($association->[0]->other->cardinality() eq CARD_0_TO_N ||
      $association->[0]->other->cardinality() eq CARD_1_TO_N) {
    my $table_name = $referring->[0]->class_name() .
      $association->[0]->other->class_name() . '_link';
    $table_name =~ s/.+:://;
    my $assn_name = $association->[0]->other->name();
    my $referring_table_name = $referring->[0]->class_name();
    $referring_table_name =~ s/.+:://;
    my %rowdata = ($referring_table_name.'_fk'=>$referring->[1],
      $association->[0]->other->name().'_fk'=>$target_ID);

    $dbhandle->updateOrInsertRow(
      insert=>1,
      table_name=>$table_name,
      rowdata_ref=>\%rowdata,
      print_SQL=>1,
      testonly=>1,
    );
    print "\n";

  #### Otherwise plead ignorance
  } else {
    print "Don't know what to do with this kind of cardinality yet!\n";
  }

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


###############################################################################
# obj2database: write an object and all its children to the database
###############################################################################
sub obj2database {
  my ($self,$obj) = @_;

  # all attributes are gathered into a hash
  my %attributes;
  my $data;
  foreach my $attribute ($obj->attribute_methods()) {
    my $attribute_val;
    {
      no strict 'refs';
      my $getter_method = 'get'.ucfirst($attribute);
      $attribute_val = $obj->$getter_method();
      if ($attribute eq 'cube') {
	$data = $self->flatten($attribute_val);
	$attribute_val = undef;
      } else {
	$attribute_val =~ s/\"/&quot;/g;
      }
    }
    if (defined $attribute_val) {
      $attributes{$attribute} = $attribute_val;
    }
  }
  # the tag name is the name of the class
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;

  # we create the start tag, with the object attributes represented as
  # element attributes. If the object has no associations we make it
  # an empty element - this is to avoid XML validation errors
  my $empty = not scalar $obj->associations();
  #$self->write_start_tag($tag,$empty,%attributes);

  #### Get the database handle and write the data to the database
  my $dbhandle = $self->dbhandle();
  my $table_name = $tag;
  my $returned_PK;

  #### If the object has already been serialized
  if ($self->object_IDs->{$obj}) {
    #print "=== Okay, well, it appears that this guy was already written\n";
    #print "    so just sweep on without writing\n\n";
    $returned_PK = $self->object_IDs->{$obj};

  #### Else write it to the database
  } else {
    $returned_PK = $dbhandle->updateOrInsertRow(
      insert=>1,
      table_name=>$table_name,
      rowdata_ref=>\%attributes,
      PK=>"ID",
      return_PK=>1,
      print_SQL=>1,
      testonly=>1,
    );

    #### Store the database autogen key to a lookup table:
    $self->object_IDs->{$obj} = $returned_PK;
    print "  --> returned ID = $returned_PK\n";
    print "\n";
  }


  #### Push some information about this object onto the stack
  push(@{$self->object_stack},[$obj,$returned_PK]);


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

      # we first create the container tag with the proper prefix
      my $prefix;
      my $is_ref = $assns_hash{$association}->other->is_ref();
      if ($is_ref) {
	$prefix = '_assnref';
      } else {
	$prefix = '_assn';
      }
      my @association_objects;
      my $cardinality = $assns_hash{$association}->other->cardinality();
      if (($cardinality eq CARD_1_TO_N) ||
	  ($cardinality eq CARD_0_TO_N)) {
	$prefix .= 'list';
	@association_objects = @{$association_obj};
      } else {
	@association_objects = ($association_obj);	
      }
      my $container_tag = ucfirst("$association$prefix");
      # container tags must not be empty
      #$self->write_start_tag("$container_tag",my $cont_empty=0);
      push(@{$self->assn_stack},[$assns_hash{$association}]);

      # now we fill in the container with the object(s)
      foreach $association_obj (@association_objects) {
	if ($is_ref) {
          #print "** assnref: ",$cardinality,"\n";

          if ($cardinality eq CARD_1) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to update the referring with the fk\n";
            #print "     to the target object.\n";
	    $self->obj2database_ref($association_obj);
          }

          if ($cardinality eq CARD_0_OR_1) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to update the referring with the fk\n";
            #print "     to the target object.\n";
	    $self->obj2database_ref($association_obj);
          }

          if ($cardinality eq CARD_0_TO_N) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to add a row in a linking table, fk'ing\n";
            #print "     to both referring and target objects.\n\n";
	    $self->obj2database_ref($association_obj);
          }

          if ($cardinality eq CARD_1_TO_N) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to add a row in a linking table, fk'ing\n";
            #print "     to both referring and target objects.\n\n";
	    $self->obj2database_ref($association_obj);
          }

	} else {
          #print "** assn: ",$cardinality,"\n";
	  $self->obj2database($association_obj);
	}
      }
      # now end the container tag
      #$self->write_end_tag("$container_tag");
      pop(@{$self->assn_stack});
    }
  }


  #### Special code for BioDataCube
  if (defined $data) {
    if ($self->external_data()) {
      my %attributes;
      $attributes{filenameURI} = $self->external_file_id();
      my $tag = 'DataExternal_assn';
      $self->write_start_tag($tag,my $empty=0);
      # we need to make it external
      {
	my $tag = 'DataExternal';
	$self->write_start_tag($tag,my $empty=1,%attributes);

	open(DATA, ">$attributes{filenameURI}")
	  or die "Couldn't open $attributes{filenameURI} for writing";
	print DATA $data;
	close(DATA);
      }
      $self->write_end_tag($tag);
    } else {
      # we make it internal
      my $tag = 'DataInternal_assn';
      $self->write_start_tag($tag,0);
      {
	my $tag = 'DataInternal';
	$self->write_start_tag($tag,0);
	my $fh = $self->fh();
	print $fh "<![CDATA[$data]]>";
	$self->write_end_tag($tag);
      }
      $self->write_end_tag($tag);
    }
  }
  # now end the current element
  #$self->write_end_tag($tag)
  #  unless $empty;
  pop(@{$self->object_stack});
}

sub is_object {
  my ($self,$obj) = @_;
  my $ref = ref($obj);
  return $ref
    && $ref ne 'ARRAY'
    && $ref ne 'SCALAR'
    && $ref ne 'HASH'
    && $ref ne 'CODE'
    && $ref ne 'GLOB'
    && $ref ne 'REF';
}

sub is_bio_mage_object {
  my ($self,$obj) = @_;
  return $self->is_object($obj)
    && ref($obj) =~ /^Bio::MAGE/;
}

1;
