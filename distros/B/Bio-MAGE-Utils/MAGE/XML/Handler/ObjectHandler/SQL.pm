# $Id: SQL.pm,v 1.7 2003/04/20 22:15:21 allenday Exp $
#
# BioPerl module for Bio::MAGE::XML::Handler::ObjectHandler::SQL
#
# Cared for by Allen Day <allenday@ucla.edu>
#
# Copyright Allen Day
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::MAGE::XML::Handler::ObjectHandler::SQL - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 AUTHOR - Allen Day

Email allenday@ucla.edu

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::MAGE::XML::Handler::ObjectHandler::SQL;
use vars qw(@ISA);
use strict;
use Carp;

use Data::Dumper;

@ISA = qw(Bio::MAGE::XML::Handler::ObjectHandlerI );

use constant CARD_1 => '1';
use constant CARD_0_OR_1 => '0..1';
use constant CARD_1_TO_N => '1..N';
use constant CARD_0_TO_N => '0..N';

=head2 new

 Title   : new
 Usage   : my $obj = new Bio::MAGE::XML::Handler::ObjectHandler::SQL();
 Function: Builds a new Bio::MAGE::XML::Handler::ObjectHandler::SQL object 
 Returns : an instance of Bio::MAGE::XML::Handler::ObjectHandler::SQL
 Args    :

=cut

sub new {
  my($class,@args) = @_;
  my $self = bless {}, $class;
  return $self;
}

sub fk {
  my $self = shift;
}

###############################################################################
# fh: setter/getter for the file handle
###############################################################################
sub fh {
  my $self = shift;
  if (@_) {
    $self->{__FH} = shift;
  }
  return $self->{__FH} || \*STDOUT;
}

sub handle {
  my($self,$handler,$obj) = @_;
  self->throw("not a Bio::MAGE object") unless ref($obj) =~ /^Bio::MAGE/;

  #report that the object is handled if it is package level.

  # create the <*_ref> tag
  my $table_name = $obj->class_name();
  $table_name =~ s/.+:://;

  # we create the empty tag with only the identifier
  my $empty = 1;

  my $referring = $handler->object_stack->[-1];
  my $association = $handler->assn_stack->[-1];
  my $target_ID = $self->object_IDs($obj);
  unless (defined($target_ID)) {
    #print "+++ Yipe, the target object hasn't been written yet.\n";
    #print "    Try to write the object:\n";
    $self->obj2database($handler,$obj);
    $target_ID = $self->object_IDs($obj);
    die "INTERNAL ERROR POS1: Failed to INSERT needed object $obj\n"
      unless (defined($target_ID));
  }

  #print "referring: ",join(" , ",@{$referring}),"\n";
  #print "assn: ",join(" , ",@{$association}),"\n";
  #print "cardinality: ",$association->[0]->other->cardinality(),"\n";
  #print "name: ",$association->[0]->other->name(),"\n";
  #print "class_name: ",$association->[0]->other->class_name(),"\n";

  #### If cardinality is 1 or 0..1
#warn Dumper($handler->assn_stack);
  if ($association->other->cardinality eq CARD_0_OR_1 ||
	  $association->other->cardinality eq CARD_1) {
    my $table_name = $referring->class_name();
    $table_name =~ s/.+:://;
    my $assn_name = $association->other->name();
    my %rowdata = ($assn_name.'_fk'=>$target_ID);


    if($referring->isa('Bio::MAGE::Identifiable')){

    $self->update_or_insert_row(
      update=>1,
      table_name=>$table_name,
      rowdata_ref=>\%rowdata,
      PK=>"ID",
      PK_value=>$referring->getIdentifier,
      print_SQL=>1,
      testonly=>1,
    );
    print "\n";

    }

  #### If cardinality is 0..n or 1..n
  } elsif ($association->other->cardinality() eq CARD_0_TO_N ||
      $association->other->cardinality() eq CARD_1_TO_N) {
    my $table_name = $referring->class_name() .
      $association->other->class_name() . '_link';
    $table_name =~ s/.+:://;
    my $assn_name = $association->other->name();
    my $referring_table_name = $referring->class_name();
    $referring_table_name =~ s/.+:://;
    my %rowdata = ($referring_table_name.'_fk'=>$referring,
      $association->other->name().'_fk'=>$target_ID);

    $self->update_or_insert_row(
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

###############################################################################
# obj2database: write an object and all its children to the database
###############################################################################
sub obj2database {
  my ($self,$handler,$obj) = @_;

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
  my $table_name = $tag;
  my $returned_PK;

  #### If the object has already been serialized
  if ($self->object_IDs($obj)) {
    #print "=== Okay, well, it appears that this guy was already written\n";
    #print "    so just sweep on without writing\n\n";
    $returned_PK = $self->object_IDs($obj);

  #### Else write it to the database
  } else {
    $returned_PK = $self->update_or_insert_row(
      insert=>1,
      table_name=>$table_name,
      rowdata_ref=>\%attributes,
      PK=>"ID",
      return_PK=>1,
      print_SQL=>1,
      testonly=>1,
    );

    #### Store the database autogen key to a lookup table:
    $self->object_IDs($obj,$returned_PK);
    print "  --> returned ID = $returned_PK\n";
    print "\n";
  }

  #### Push some information about this object onto the stack
  push(@{$handler->object_stack},[$obj,$returned_PK]);


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
#warn "2 $assns_hash{$association}";
      push(@{$handler->assn_stack},[$assns_hash{$association}]);

      # now we fill in the container with the object(s)
      foreach $association_obj (@association_objects) {
	if ($is_ref) {
          #print "** assnref: ",$cardinality,"\n";

          if ($cardinality eq CARD_1) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to update the referring with the fk\n";
            #print "     to the target object.\n";
	    $self->obj2database_ref($handler,$association_obj);
          }

          if ($cardinality eq CARD_0_OR_1) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to update the referring with the fk\n";
            #print "     to the target object.\n";
	    $self->obj2database_ref($handler,$association_obj);
          }

          if ($cardinality eq CARD_0_TO_N) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to add a row in a linking table, fk'ing\n";
            #print "     to both referring and target objects.\n\n";
	    $self->obj2database_ref($handler,$association_obj);
          }

          if ($cardinality eq CARD_1_TO_N) {
            #print "  == Cardinality is $cardinality\n";
            #print "     Need to add a row in a linking table, fk'ing\n";
            #print "     to both referring and target objects.\n\n";
	    $self->obj2database_ref($handler,$association_obj);
          }

	} else {
          #print "** assn: ",$cardinality,"\n";
	  $self->obj2database($handler,$association_obj);
	}
      }
      # now end the container tag
      #$self->write_end_tag("$container_tag");
      pop(@{$handler->assn_stack});
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
  pop(@{$handler->object_stack});
}

###############################################################################
# obj2database_ref: write a reference object to the database
###############################################################################
sub obj2database_ref {
  my ($self,$handler,$obj) = @_;

  # create the <*_ref> tag
  my $tag = $obj->class_name();
  $tag =~ s/.+:://;
  $tag .= '_ref';

  # we create the empty tag with only the identifier
  my $empty = 1;
  #$self->write_start_tag($tag,$empty,identifier=>$obj->getIdentifier());

  my $table_name = $tag;
  $table_name =~ s/_ref$//;

  my $referring = $handler->object_stack->[-1];
  my $association = $handler->assn_stack->[-1];
  my $target_ID = $self->object_IDs($obj);
  unless (defined($target_ID)) {
    #print "+++ Yipe, the target object hasn't been written yet.\n";
    #print "    Try to write the object:\n";
    $self->obj2database($handler,$obj);
    $target_ID = $self->object_IDs($obj);
    die "INTERNAL ERROR POS2: Failed to INSERT needed object $obj\n"
      unless (defined($target_ID));
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
    $self->update_or_insert_row(
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

    $self->update_or_insert_row(
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

sub attr_indent {
  my $self = shift;
  if (@_) {
    $self->{__ATTR_INDENT} = shift;
  }
  return $self->{__ATTR_INDENT};
}

sub attrs_on_one_line {
  my $self = shift;
  if (@_) {
    $self->{__ATTRS_ON_ONE_LINE} = shift;
  }
  return $self->{__ATTRS_ON_ONE_LINE};
}

sub collapse_tag {
  my $self = shift;
  if (@_) {
    $self->{__COLLAPSE_TAG} = shift;
  }
  return $self->{__COLLAPSE_TAG};   
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

sub external_data {
  my $self = shift;
  if (@_) {
    $self->{__EXTERNAL_DATA} = shift;
  }
  return $self->{__EXTERNAL_DATA};
}

sub external_file_id {
  my $self = shift;
  my $num = $self->external_data();
  $num++;
  $self->external_data($num);
  return "external-data-$num.txt";
}

sub incr_indent {
  my $self = shift;
  $self->indent_level($self->indent_level + $self->indent_increment);
}

sub decr_indent { 
  my $self = shift;
  $self->indent_level($self->indent_level - $self->indent_increment);
}

sub indent_increment {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_INCREMENT} = shift;
  }
  return $self->{__INDENT_INCREMENT};
}

sub indent_level {
  my $self = shift;
  if (@_) {
    $self->{__INDENT_LEVEL} = shift;
  }
  return $self->{__INDENT_LEVEL};
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

sub update_or_insert_row {
  my $self = shift || croak("parameter self not passed");
  my %args = @_;

  #### Decode the argument list
  my $table_name         = $args{'table_name'}         || die "ERROR: table_name not passed";
  my $rowdata_ref        = $args{'rowdata_ref'}        || die "ERROR: rowdata_ref not passed";
  my $database_name      = $args{'database_name'}      || "";
  my $return_PK          = $args{'return_PK'}          || 0;
  my $verbose            = $args{'verbose'}            || 0;
  my $print_SQL          = $args{'print_SQL'}          || 0;
  my $testonly           = $args{'testonly'}           || 0;
  my $insert             = $args{'insert'}             || 0;
  my $update             = $args{'update'}             || 0;
  my $PK                 = $args{'PK'}                 || "";
  my $PK_value           = $args{'PK_value'}           || "";
  my $quoted_identifiers = $args{'quoted_identifiers'} || "ON";


  #### Make sure either INSERT or UPDATE was selected
  unless ( ($insert or $update) and (!($insert and $update)) ) {
    croak "ERROR: Need to specify either 'insert' or 'update'\n\n";
  }

  #### If this is an UPDATE operation, make sure that we got the PK and value
  if ($update) {
    unless (defined($PK) and defined($PK_value)) {
      croak "ERROR: Need both PK and PK_value if operation is UPDATE.  PK: $PK ; PK_value: $PK_value\n\n";
    }
  }

  #### Initialize some variables
  my ($column_list,$value_list,$columnvalue_list) = ("","","");
  my ($key,$value,$value_ref);


  #### Loops over each passed rowdata element, building the query
  while ( ($key,$value) = each %{$rowdata_ref} ) {

    #### If quoted identifiers is set, then quote the key
    $key = '"'.$key.'"';

    #### If $value is a reference, assume it's a reference to a hash and
    #### extract the {value} key value.  This is because of Xerces.
    $value = $value->{value} if (ref($value));

    print "	$key = $value\n" if ($verbose > 0);

    #### Add the key as the column name
    $column_list .= "$key,";

    #### Enquote and add the value as the column value
    $value = $self->convertSingletoTwoQuotes($value);
    if (uc($value) eq "CURRENT_TIMESTAMP") {
      $value_list .= "$value,";
      $columnvalue_list .= "$key = $value,\n";
    } else {
      $value_list .= "'$value',";
      $columnvalue_list .= "$key = '$value',\n";
    }

  }


  unless ($column_list || 1) {
    print "ERROR: insert_row(): column_list is empty!\n";
    return;
  }


  #### Chop off the final commas
  chop $column_list;
  chop $value_list;
  chop $columnvalue_list;		# First the \n
  chop $columnvalue_list;		# Then the comma


  #### Create the final table name
  my $full_table_name = "$database_name$table_name";
  $full_table_name = '"'.$full_table_name.'"' if ($quoted_identifiers);


  #### Build the SQL statement
  my $sql;
  if ($update) {
    my $PK_tag = $PK;
    $PK_tag = '"'.$PK.'"' if ($quoted_identifiers);
    $sql = "UPDATE $full_table_name SET $columnvalue_list WHERE $PK_tag = '$PK_value'";
  } else {
    $sql = "INSERT INTO $full_table_name ( $column_list ) VALUES ( $value_list )";
  }
  print "$sql\n" if ($verbose > 0 || $print_SQL > 0);


  #### If we're just testing
  if ($testonly) {

    #### If the user asked for the PK to be returned, make a random one up
    if ($return_PK) {
      return int(rand()*1000);

	  #### Otherwise, just return a 1
    } else {
      return 1;
    }
  }


  #### Execute the SQL
  $self->executeSQL($sql);


  #### If user didn't want PK, return with success
  return "1" unless ($return_PK);


  #### If user requested the resulting PK, return it
  if ($update) {
    return $PK_value;
  } else {
    return $self->getLastInsertedPK(table_name=>"$database_name$table_name",
									PK_column_name=>"$PK");
  }
}

###############################################################################
# convertSingletoTwoQuotes
#
# Converts all instances of a single quote to two consecutive single
# quotes as wanted by an SQL string already enclosed in single quotes
###############################################################################
sub convertSingletoTwoQuotes {
  my $self = shift;
  my $string = shift;

  return if (! defined($string));
  return '' if ($string eq '');
  return 0 unless ($string);

  my $resultstring = $string;
  $resultstring =~ s/'/''/g;  ####'

  return $resultstring;
} # end convertSingletoTwoQuotes

sub object_IDs {
  my $self = shift;
  my($k,$v) = @_;

  if(defined $k and defined $v){
	$self->{__OBJECT_IDS}->{$k} = $v;
  } elsif(defined $k){
	return $self->{__OBJECT_IDS}->{$k};
  } else {
	return $self->{__OBJECT_IDS};
  }
}

1;
