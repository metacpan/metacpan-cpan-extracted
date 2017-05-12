###############################################################################
# Bio::MAGE::Handler package: Callbacks to process elements as they come
#                    from the SAX or SAX2 parser
###############################################################################
package Bio::MAGE::XML::Handler;
use strict;
use Data::Dumper;
use IO::File;

# import the cardinality constants
use Bio::MAGE::Association qw(:CARD);

###############################################################################
# new: initialize the content handler
###############################################################################

sub init {
  my $self = shift;
  $self->object_stack([]);
  $self->assn_stack([]);
  $self->unhandled({});
  $self->id({});
}

sub reader {
  my $self = shift;
  if (scalar @_) {
    $self->{__READER} = shift;
  }
  return $self->{__READER};
}

sub dir {
  my $self = shift;
  if (scalar @_) {
    $self->{__DIR} = shift;
  }
  return $self->{__DIR};
}

###############################################################################
# object_stack: setter/getter for the stack on which objects are placed
###############################################################################
sub object_stack {
  my $self = shift;
  #### If an argument was supplied (should be an array ref), set it
  if (scalar @_) {
    $self->{__OBJ_STACK} = shift;
  }
  #### Return a reference to the stack
  return $self->{__OBJ_STACK};
}


###############################################################################
# assn_stack: setter/getter for the stack on which associations are placed
###############################################################################
sub assn_stack {
  my $self = shift;
  #### If an argument was supplied (should be an array ref), set it
  if (scalar @_) {
    $self->{__ASSN_STACK} = shift;
  }
  #### Return a reference to the stack
  return $self->{__ASSN_STACK};
}


###############################################################################
# unhandled: setter/getter for the hash into which unhandled references
#            are placed
###############################################################################
sub unhandled {
  my $self = shift;
  #### If an argument was supplied (should be a hash ref), set it
  if (scalar @_) {
    $self->{__UNHANDLED} = shift;
  }
  #### Return a reference to the hash
  return $self->{__UNHANDLED};
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

###############################################################################
# num_tabs: setter/getter for the scalar to track number of tags processed
###############################################################################
sub num_tags {
  my $self = shift;
  if (scalar @_) {
    $self->{__NUM_TAGS} = shift;
  }
  return $self->{__NUM_TAGS};
}

sub MAGE {
  my $self = shift;
  if (scalar @_) {
    $self->{__MAGE} = shift;
  }
  return $self->{__MAGE};
}

sub id {
  my $self = shift;
  if (scalar @_) {
    $self->{__ID} = shift;
  }
  return $self->{__ID};
}

sub data {
  my $self = shift;
  if (scalar @_) {
    $self->{__PRIVATE}{DATA} = shift;
  }
  return $self->{__PRIVATE}{DATA};
}

sub class2fullclass {
  my $self = shift;
  if (scalar @_) {
    $self->{__CLASS2FULLCLASS} = shift;
  }
  return $self->{__CLASS2FULLCLASS};
}

=pod

=item start_element_objecthandler($handler)

Use this method to get/set the start handler that will be called to process
Bio::MAGE objects as they are created.  $handler must be instances of the
Bio::MAGE::XMLUtils::ObjectHandlerI class.

Calling start_element objecthandler() with no arguments returns a reference to the
currently registered Bio::MAGE::XMLUtils::ObjectHandlerI object.

=cut

sub start_element_objecthandler {
  my $self = shift;
  if (@_) {
    $self->{__SE_OBJHANDLER} = shift;
  }
  return $self->{__SE_OBJHANDLER};
}

=pod

=item end_element_objecthandler($handler)

Use this method to get/set the end handler that will be called to process
Bio::MAGE objects as they are finished (when the end tag event occurs.
$handler must be instances of the Bio::MAGE::XMLUtils::ObjectHandlerI class.

Calling end_element_objecthandler() with no arguments returns a reference to the
currently registered Bio::MAGE::XMLUtils::ObjectHandlerI object.

=cut

sub end_element_objecthandler {
  my $self = shift;
  if (@_) {
    $self->{__EE_OBJHANDLER} = shift;
  }
  return $self->{__EE_OBJHANDLER};
}

=pod

=item character_objecthandler($handler)

Use this method to get/set the start handler that will be called to process
character data as it is .  $handler must be instances of the
Bio::MAGE::XMLUtils::ObjectHandlerI class.

Calling character_objecthandler() with no arguments returns a reference to the
currently registered Bio::MAGE::XMLUtils::ObjectHandlerI object.

=cut

sub character_objecthandler {
  my $self = shift;
  if (@_) {
    $self->{__C_OBJHANDLER} = shift;
  }
  return $self->{__C_OBJHANDLER};
}

###############################################################################
# handle_ref
###############################################################################
sub handle_ref {
  my ($self,$class,$identifier) = @_;

  #### Determine the full class name from the class
  my $full_class_name = $self->class2fullclass->{$class};

  #### Try to obtain the object that is referenced
  my $obj = $self->id->{$full_class_name}->{$identifier};

  #### If the referenced object doesn't exist, then create a new object
  #### with that name with the hope that we'll find it later in the document,
  #### and if we don't, we'll still be left with an empty object of the
  #### appropriate type
  unless (defined $obj) {
    #### Get the object expecting resolution
    my $expecting_obj = $self->object_stack->[-1];

    #### Get the name of the container
    my $method = lcfirst($self->assn_stack()->[-1]->other->name) ||
      die "ASSN_STACK doesn't have $identifier on top!";

    #### return a reference to an otherwise empty object with just the
    #### correct identifier and suitably obtuse name
    $obj =  $full_class_name->new(identifier=>$identifier);
    if ($self->reader->resolve_identifiers) {
      #### Push it on the unhandled list so that we know what all the problem
      #### references are for later resolution or reporting
      push(@{$self->unhandled->{$identifier}},
	   [$method,$expecting_obj,$full_class_name]);
    }
  }

  #### Return the object
  return $obj;
}


###############################################################################
# get_quantitation_type_dimension
###############################################################################
sub get_quantitation_type_dimension {
  my ($self) = @_;
  my $bioassay = $self->object_stack->[-2];
  die "Expected BioAssayData but got: $bioassay"
    unless $bioassay->isa('Bio::MAGE::BioAssayData::BioAssayData');
  return scalar @{$bioassay->getQuantitationTypeDimension->getQuantitationTypes()};
}


###############################################################################
# get_design_element_dimension
###############################################################################
sub get_design_element_dimension {

  my ($self) = @_;
  my $bioassaydata = $self->object_stack->[-2];

  die "Expected BioAssayData but got: $bioassaydata"
    unless $bioassaydata->isa('Bio::MAGE::BioAssayData::BioAssayData');
  
  # Added by Mohammad on 20/11/03 shoja@ebi.ac.uk , Change begin 
  # Should have the following control to get the right stuff.
  my $ded = $bioassaydata->getDesignElementDimension();

  if ($ded->isa('Bio::MAGE::BioAssayData::FeatureDimension')) {

      return scalar @{$bioassaydata->getDesignElementDimension->getContainedFeatures()};
  }
  elsif ($ded->isa('Bio::MAGE::BioAssayData::ReporterDimension')) {

      return scalar @{$bioassaydata->getDesignElementDimension->getReporters()};
  }
  elsif ($ded->isa('Bio::MAGE::BioAssayData::CompositeSequenceDimension')) {
      
      return scalar @{$bioassaydata->getDesignElementDimension->getCompositeSequences()};
  }

  #### Otherwise, confess we don't know what to do with this type of element
  #### This should never happen
  else {
      die "ERROR: Unknown DesignElementDimension\n";
  }
  # Added by Mohammad on 20/11/03 shoja@ebi.ac.uk , Change end

}


###############################################################################
# get_bioassay_dimension
###############################################################################
sub get_bioassay_dimension {
  my ($self) = @_;
  my $bioassay = $self->object_stack->[-2];
  die "Expected BioAssayData but got: $bioassay"
    unless $bioassay->isa('Bio::MAGE::BioAssayData::BioAssayData');
  return scalar @{$bioassay->getBioAssayDimension->getBioAssays()};
}


###############################################################################
# get_cube
###############################################################################
sub get_cube {
  my ($self,$order,$string) = @_;

  my %index;
  $index{B} = $self->get_bioassay_dimension();
  $index{Q} = $self->get_quantitation_type_dimension();
  $index{D} = $self->get_design_element_dimension();

  my ($a,$b,$c) = split('', $order);
  my ($i_lim,$j_lim,$k_lim);
  $i_lim = $index{$a};
  $j_lim = $index{$b};
  $k_lim = $index{$c};

  my @bad;
  $string =~ s/\n/\t/g;
  my @list = split("\t",$string);

  for (my $i=0;$i<$i_lim;$i++) {
    my $ded = [];
    for (my $j=0;$j<$j_lim;$j++) {
      my $qtd = [];
      for (my $k=0;$k<$k_lim;$k++) {
	my $item = shift(@list);
	$item =~ s/&space;/ /g;
	push(@{$qtd},$item);
      }
      push(@{$ded},$qtd);
    }
    push(@bad,$ded);
  }
  return \@bad;
}

###############################################################################
# characters: SAX callback function for handling character data in an element
###############################################################################
sub characters {
  my ($self,$string,$len) = @_;

  #flag whether or not the object handler has accepted the request
  #to handle the object.
  my $rc = 1;

  #try to handle the object externally
  if(defined $self->character_objecthandler){
	$rc = $self->character_objecthandler->handle($self,$self->object_stack->[-1]);
  }

  #if the object hasn't been handled ($rc still == 1), attach the object
  #to its parent.
  if($rc){

	#   print $self->reader->log_file() "Characters called with $len characters\n";
	return unless exists $self->{__PRIVATE}{DATA};
	$self->{__PRIVATE}{DATA} .= $string;
  }
}

###############################################################################
# start_element: SAX callback function for handling a XML start element
###############################################################################
sub start_element {
  my ($self,$localname,$attrs) = @_;

  if (defined $self->count) {
    my $tags = $self->num_tags() + 1;
    $self->num_tags($tags);
    print STDERR "$tags\n" if $tags % $self->count == 0;
  }

  #### Dereference the attributes hash
  my %attrs = %{$attrs};

#  my $LOG = $self->reader->log_file();
   my $LOG = new IO::File $self->reader->log_file(),"w";

  my $VERBOSE = $self->reader->verbose();

  #### Special handling for DataInternal or DataExternal (ie, nastiness)
  my $filename_uri;
  if ($localname eq 'DataInternal') {
    $self->{__PRIVATE}{DATA} = '';
    return;

  } elsif ($localname eq 'DataExternal') {
    # we had to wait until we had pushed the tag onto the object stack
    if ($attrs{filenameURI}) {
      local $/;			# enable slurp mode
      my $file;
      $file = $self->dir() . '/' if $self->dir;
      $file .= $attrs{filenameURI};
      open(DATA, $file) or die "Couldn't open $file for reading";

      my $bio_data_cube = $self->object_stack->[-1];
      die "Expected a Bio::MAGE::BioAssayData::BioDataCube but got $bio_data_cube"
		unless $bio_data_cube->isa('Bio::MAGE::BioAssayData::BioDataCube');
#      $bio_data_cube->setCube($self->get_cube($attrs{order},$data));
#      $bio_data_cube->setCube($self->get_cube($bio_data_cube->getOrder,$data));

	    # Added by Mohammad on 19/11/03 shoja@ebi.ac.uk , Change begin 
	    # This assist us to read external files AS IS
	    if (!$self->reader->external_data) {

		my $data = <DATA>;	# slurp whole file
                $bio_data_cube->setCube($self->get_cube($bio_data_cube->getOrder,$data));	
	    }
	    else {
		$bio_data_cube->setOrder($bio_data_cube->getOrder);		
		$bio_data_cube->setCube($attrs{filenameURI});
	    }
	    # Added by Mohammad on 19/11/03  shoja@ebi.ac.uk , Change end 

#warn Dumper($bio_data_cube->getCube);
    }
    return;
  } elsif (scalar @{$self->object_stack} and
	   UNIVERSAL::isa($self->object_stack->[-1],
			  'Bio::MAGE::BioAssayData::BioDataTuples')) {
    # Handle BioDataTuples

    # if we're a <*_ref>, keep track of the element
    if ($localname =~ /_ref/) {
      #### Determine the name of the referenced class
      my $refclass = $localname;
      $refclass =~ s/_ref$//;
      my $refinstance = $self->handle_ref($refclass,$attrs{identifier});
      my $key;
      if ($refinstance->isa('Bio::MAGE::BioAssay::BioAssay')) {
		$key = 'bioAssay';
      } elsif ($refinstance->isa('Bio::MAGE::QuantitationType::QuantitationType')) {
		$key = 'quantitationType';
      } elsif ($refinstance->isa('Bio::MAGE::DesignElement::DesignElement')) {
		$key = 'designElement';
      } else {
		die "Bad ref element when handling BioDataTuples: $localname, with id: $attrs{identifier}";
      }
      $self->{__PRIVATE}{BioDataTuples}{$key} = $refinstance;
    } elsif ($localname eq 'Datum') {
      # if we're a <Datum> add it
      $attrs{bioAssay} = $self->{__PRIVATE}{BioDataTuples}{bioAssay};
      $attrs{quantitationType} = $self->{__PRIVATE}{BioDataTuples}{quantitationType};
      $attrs{designElement} = $self->{__PRIVATE}{BioDataTuples}{designElement};

      foreach my $key (qw(value
			  bioAssay
			  designElement
			  quantitationType)) {
		die "No $key defined for datum" unless defined $attrs{$key};	
      }

      my $obj = Bio::MAGE::BioAssayData::BioAssayDatum->new(%attrs);
      $self->object_stack->[-1]->addBioAssayTupleData($obj);
    }
    return;
  }

  #### Top level tag MAGE-ML signals creation of MAGE object
  if ($localname eq 'MAGE-ML') {
    print $LOG "<$localname> Begin the MAGE-ML document\n" if ($VERBOSE);

    #### Simply create the MAGE object with the supplied attributes
    $self->MAGE(Bio::MAGE->new(%attrs));

    #### Obtain the full class path lookup hash and store it for reuse
    $self->class2fullclass({Bio::MAGE->class2fullclass});

    #### Add the MAGE object to the stack
    push(@{$self->object_stack},$self->MAGE);

  #### If there's no underscore in the tag, it must be a class
  #### This seems a little flimsy, but as long as the OM/ML follows this
  #### convention, this will work.  DUBIOUS.
  } elsif ($localname !~ /_/) {
    print $LOG "\n<$localname> has attributes:\n" if ($VERBOSE);

	#try to handle the object externally.  note that $rc is not really paid
	#attention to, because we may need object again if there is an
	#object handler registered with end_element_objecthandler.  now,
	#we can do a test for the end_element_objecthandler... this is an
	#incomplete thought.
	if(defined $self->start_element_objecthandler){
	  my $rc = $self->start_element_objecthandler->handle($self,$self->object_stack->[-1]);
	}
	
	#### Determine the parent object (if there is one)
	my $parent = $self->object_stack->[-1];

	#### Determine the full class name from the class
	my $class = $self->class2fullclass->{$localname};


	#### Create the object and push it onto object stack
	my $instance = $class->new(%attrs);
	push(@{$self->object_stack},$instance);
	print $LOG "    I am $instance\n" if ($VERBOSE);

	#### If object is identifiable, then add its identifier to ID hash
	if ($instance->isa('Bio::MAGE::Identifiable')) {

	  #### For the moment, we have made the rule that any single document
	  #### must have all totally unique identifiers.  We crash if this
	  #### is ever violated.  DUBIOUS.
	  if ($self->id->{$class}->{$attrs{identifier}}) {
		die "ERROR: duplicate identifier '$attrs{identifier}'." .
		  "Identifiers must be unique for a given class within a document!\n";

		#### Add this object to the ID hash under its indentifier
	  } else {
		$self->id->{$class}->{$attrs{identifier}} = $instance;
	  }
	}
	
	#### Print $LOG out the associations for this class for fun if very verbose
	if ($VERBOSE > 1) {
	  my ($association,$key,$value);
	  my %associations = $instance->associations();
	  print $LOG "    and also has associations: \n";
	  while ( ($key,$value) = each %associations) {
		print $LOG "\t$key = $value\n";
	  }
	}

  #### Otherwise, if the tag is a "_package" then just register it with
  #### the CONTENT_HANDLER and push it onto the object stack.
  } elsif ($localname =~ /_package$/) {
    print $LOG "\n<$localname> is package\n" if ($VERBOSE);

    #### Determine the class and create the object
    my $method = 'get' . $localname;
    my $instance = $self->MAGE->$method();

    #### Add the Package object to the stack
    push(@{$self->object_stack},$instance);

  #### If the tag is a _assn, _assnlist, _assnref, or assnreflist
  #### push the object onto the assn_stack for later use
  } elsif ($localname =~ /_assn/){
	#_assn
	#_assnlist
	#_assnref
	#_assnreflist
	my $assn;
	my $assn_name = $localname;
	$assn_name =~ s/_.*//;
	$assn_name = lcfirst($assn_name);

####
#I'm not sure what I'm doing here, but it seems to have resolved a problem that there was a missing "End" object
#when parsing a DataExternal_assn element.  Whether or not it does what it is supposed to, I don't know, but I no longer
#get runtime exceptions.
	my %associations = $self->object_stack->[-1]->can('associations') ? $self->object_stack->[-1]->associations : ();
	$assn = $associations{$assn_name};

	if(!defined($assn)){
	  my $other = new Bio::MAGE::Association::End(name=>$assn_name,
						      cardinality=>Bio::MAGE::Association::CARD_0_TO_N,
												 );
	  $assn = new Bio::MAGE::Association(other=>$other);
	}

####
#	if($self->object_stack->[-1]->can('associations')){
#	  my %associations = $self->object_stack->[-1]->associations;
#	  $assn = $associations{$assn_name};
#	} else {
#	  my $other = new Bio::MAGE::Association::End(name=>$assn_name,
#						      cardinality=>Bio::MAGE::Association::CARD_0_TO_N,
#												 );
#	  $assn = new Bio::MAGE::Association(other=>$other);
#	}
####
	push(@{$self->assn_stack},$assn);

  #### If the tag is a "_ref" then we need to store the reference(s) in
  #### the parent object
  } elsif ($localname =~ /_ref$/) {
    print $LOG "\n<$localname> is a reference\n" if ($VERBOSE);

    #### Determine the name of the referenced class
    my $refclass = $localname;
    $refclass =~ s/_ref$//;

    #### Determine the parent object
    my $parent = $self->object_stack->[-1];
    print $LOG "\tMy parent is $parent\n" if ($VERBOSE);

    #### Get the instance of the referenced object.  This function
    #### will always return something even if it has to create a dummy
    #### object to refer to.
    my $refinstance = $self->handle_ref($refclass,$attrs{identifier});

    #### Get the information about the container assn
    my $assn = $self->assn_stack()->[-1];

    #### Determine the method name used to store the reference(s)
    my $method = 'add' . ucfirst($assn->other->name);

    #### If only a single reference is allowed, then just set it
 	if( $assn->other->cardinality eq Bio::MAGE::Association::CARD_1 or $assn->other->cardinality eq Bio::MAGE::Association::CARD_0_OR_1 ){
       $method = 'set'. ucfirst($assn->other->name);
       print $LOG "\tSet parent's attribute $method = $refinstance\n" if ($VERBOSE);
       {
         no strict 'refs';
         $self->object_stack->[-1]->$method($refinstance);
       }

 	  #### If multiple references are allowed, store the list as an array
	 } elsif ( $assn->other->cardinality eq Bio::MAGE::Association::CARD_1_TO_N or $assn->other->cardinality eq Bio::MAGE::Association::CARD_0_TO_N ) {
       $method = 'add'. ucfirst($assn->other->name);
       print $LOG "\tAdd parent's attribute $method = $refinstance\n" if ($VERBOSE);
       {
         no strict 'refs';
         $self->object_stack->[-1]->$method($refinstance);
       }

     #### If neither SINGLE or LIST, we're hopelessly confused
     } else {
       die "ERROR: Unknown cardinality: '$assn->other->cardinality'\n";
     }

  #### Otherwise, confess we don't know what to do with this type of element
  #### This should never happen
  } else {
    die "ERROR: <$localname> Don't know what to do with <$localname>\n";
  }

}

###############################################################################
# end_element: SAX callback function for handling a XML end element
###############################################################################
sub end_element {
  my ($self,$localname) = @_;

  #### Special case of BioDataCube data
  if ($localname eq 'DataExternal') {
    return;
  } elsif ($localname eq 'DataInternal') {
    my $bio_data_cube = $self->object_stack->[-1];
    die "Expected a Bio::MAGE::BioDataCube but got $bio_data_cube"
      unless $bio_data_cube->isa('Bio::MAGE::BioAssayData::BioDataCube');
    $bio_data_cube->setCube($self->get_cube($self->{__PRIVATE}{DATA}));
    delete $self->{__PRIVATE}{DATA};
    return;
  } elsif ($localname eq 'BioDataTuples') {
      delete $self->{__PRIVATE}{BioDataTuples}
  } elsif (scalar @{$self->object_stack} and
	   UNIVERSAL::isa($self->object_stack->[-1],
			  'Bio::MAGE::BioAssayData::BioDataTuples')) {
    # do nothing
    return;
  }

#  my $LOG = $self->reader->log_file();
  my $LOG = new IO::File $self->reader->log_file(),"w";
  my $VERBOSE = $self->reader->verbose();

  #### If finishing a _assn* element, pop it off the assn_stack
  if (($localname =~ /_assn$/       or
       $localname =~ /_assnlist$/   or
       $localname =~ /_assnref$/    or
       $localname =~ /_assnreflist$/ 
      )
#      and $localname !~ /DataExternal/  #is this reasonable??? -allen
     ) {
#warn $localname;
    #### Determine the association name
    my $assn = $self->assn_stack()->[-1];
#warn $localname unless defined $assn;
#warn Dumper($self->assn_stack()) unless defined $assn;
#warn Dumper($self->assn_stack()->[-1]) unless defined $assn;
    my $assn_name = $assn->other->name;
    $assn_name =~ s/_assn[a-z]*$//;

    #### If there's something on the stack
    if (scalar @{$self->assn_stack()}) {

      #### If the top object on the stack is the correct one, pop it off
      if ($self->assn_stack()->[-1]->other->name eq $assn_name) {
        pop(@{$self->assn_stack});

      #### Otherwise, die bitterly
      } else {
        my $problem = $self->assn_stack()->[-1]->other->name;
        die "ERROR: Wanted to pop '$assn_name' off the ASSN_STACK, ".
          "but instead I found '$problem'! ".
          "This should never happen.\n";
      }

    #### but if there's nothing on the stack and we got here, die bitterly
    } else {
      die "ERROR: Wanted to pop '$assn_name' off the ASSN_STACK, ".
        "but there's nothing on the stack at all! ".
        "This should never happen.\n";
    }


  #### If finishing a _package element, pop it off the object_stack
  } elsif ($localname =~ /_package$/ ) {

    #### Determine the association name
    my $instance = $self->object_stack()->[-1];
    my $package_name = $localname;
    $package_name =~ s/_package$//;
    $package_name = "Bio::MAGE::$package_name";

    #### If there's something on the stack
    if (scalar @{$self->object_stack()}) {

      #### If the top object on the stack is the correct one, pop it off
      if (ref($self->object_stack()->[-1]) eq $package_name) {
        pop(@{$self->object_stack});

      #### Otherwise, die bitterly
      } else {
        my $problem = ref $self->object_stack()->[-1];
        die "ERROR: Wanted to pop '$package_name' off the OBJECT_STACK, ".
          "but instead I found '$problem'! ".
          "This should never happen.\n";
      }

    #### but if there's nothing on the stack and we got here, die bitterly
    } else {
      die "ERROR: Wanted to pop '$package_name' off the OBJECT_STACK, ".
        "but there's nothing on the stack at all! ".
        "This should never happen.\n";
    }


  #### Otherwise see if it's just a plain object
  #### This is based on the assumption that plain objects have no
  #### underscores!! DUBIOUS
  } elsif ($localname =~ /MAGE-ML/) {
    if (scalar @{$self->object_stack()}){
      #### If the top object on the stack is the correct one, pop it off
      if (ref $self->object_stack->[-1] eq 'Bio::MAGE') {
        pop(@{$self->object_stack});

		### check that object stack is now empty
		if (scalar @{$self->object_stack}) {
		  my $count = scalar @{$self->object_stack};
		  my $problem = ref $self->object_stack->[-1];
		  die <<ERROR;
   ### ERROR ###
       Just popped 'Bio::MAGE' off the OBJECT_STACK,
       but there are still $count objects left
       and the last one is '$problem'!
       This should never happen.
ERROR
		}
		#### Otherwise, die bitterly
      } else {
        my $problem = ref $self->object_stack->[-1];
		die <<ERROR;
   ### ERROR ###
       Wanted to pop 'Bio::MAGE' off the OBJECT_STACK,
       but instead I found '$problem'!
       This should never happen.
ERROR
      }
    } else {
      die <<ERROR;
   ### ERROR ###
       Wanted to pop 'Bio::MAGE' off the OBJECT_STACK,
       but there is nothing on the stack at all!
       This should never happen.
ERROR
    }
	#These are normal objects that need to be written out.
  } elsif (!($localname =~ /_/) && !($localname =~ /MAGE-ML/)) {

    #### If there's an object on the stack consider popping it off
    if (scalar @{$self->object_stack()}){

      #### Determine the full class name from the class
      my $full_class_name = $self->class2fullclass->{$localname};

      #### If the top object on the stack is the correct one, pop it off
      if ($self->object_stack->[-1]->class_name eq $full_class_name) {

		#flag whether or not the object handler has accepted the request
		#to handle the object.
		my $rc = 1;

		#try to handle the object externally
		if(defined $self->end_element_objecthandler){
		  $rc = $self->end_element_objecthandler->handle($self,$self->object_stack->[-1]);
		}

		#if the object hasn't been handled ($rc still == 1), attach the object
		#to its parent.
		if($rc){

		  my $instance = $self->object_stack()->[-1];
		
		  #### Determine the parent object (if there is one)
		  my $parent = $self->object_stack->[-2];

		  #### If we have a parent, then associate with it
		  if ($parent) {

			#### Get the information about the container assn
			my $assn = $self->assn_stack()->[-1];
			print $LOG "    and has parent $parent\n" if ($VERBOSE);

			#### If only a single reference is allowed, then just set it
			if( $assn->other->cardinality eq Bio::MAGE::Association::CARD_1 or $assn->other->cardinality eq Bio::MAGE::Association::CARD_0_OR_1 ){
			  my $method = 'set'. ucfirst($assn->other->name);
			  print $LOG "   so set parent attribute $method = $instance\n" if ($VERBOSE);
			  $self->object_stack->[-2]->$method($instance);

			  #### If multiple references are allowed, store the list as an array
			} elsif ( $assn->other->cardinality eq Bio::MAGE::Association::CARD_1_TO_N or $assn->other->cardinality eq Bio::MAGE::Association::CARD_0_TO_N ) {
			  my $method = 'add'. ucfirst($assn->other->name);
			  $self->object_stack->[-2]->$method($instance);
			  #### If neither SINGLE or LIST, we're hopelessly confused
			} else {
			  die "INTERNAL ERROR: Unknown cardinality: '$assn->other->cardinality'\n";
			}
			#### Otherwise, if there's no parent, die
		  } else {
			die <<ERROR;
   ### ERROR ###
       Found an object with no parent == $instance
       This should never happen.
ERROR
		  }
		}

        pop(@{$self->object_stack});

		#### Otherwise, die bitterly
      } else {
        my $problem = $self->object_stack->[-1]->class_name;
        die "ERROR: Wanted to pop '$full_class_name' off the ".
          "OBJECT_STACK, but instead I found '$problem'! ".
          "This should never happen.\n";
      }

    #### but if there's nothing on the stack and we got here, die bitterly
    } else {
      die <<ERROR;
   ### ERROR ###
       Wanted to pop 'Bio::MAGE::$localname' off the OBJECT_STACK,
       but there is nothing on the stack at all!
       This should never happen.
ERROR
    }

  #### Otherwise, I'll assume we're just ending an uninteresting element
  } else {
    #### Nothing to do
  }
}

1;
