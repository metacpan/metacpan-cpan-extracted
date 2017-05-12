##############################
#
# Bio::MAGE::Tools::MGEDOntologyClassEntry
#
##############################
# C O P Y R I G H T   N O T I C E
#  Copyright (c) 2001-2002 by:
#    * The MicroArray Gene Expression Database Society (MGED)
#    * Rosetta Inpharmatics
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

package  Bio::MAGE::Tools::MGEDOntologyClassEntry;

use strict;
use Carp;

use vars qw($VERSION $DEBUG);

# Inherit methods from superclass
use base qw(Bio::MAGE::Tools::MGEDOntologyEntry);

$VERSION = 2006_08_16.1;

=head1 Bio::MAGE::Tools::MGEDOntologyClassEntry

=head2 SYNOPSIS

  use Bio::MAGE::Tools::MGEDOntologyClassEntry;
  use Bio::MAGE::Tools::MGEDOntologyHelper;
  use Bio::MAGE::QuantitationType::MeasuredSignal;

  my $mo_helper = Bio::MAGE::Tools::MGEDOntologyHelper->new(
                        sourceFile => 'MGEDOntology.owl',
                  );

  my $qt = Bio::MAGE::QuantitationType::MeasuredSignal->new(
             identifier => 'QT1',
             isBackground => 'false',
           );

  my $ont_entry = Bio::MAGE::Tools::MGEDOntologyClassEntry->new(
                    parentObject => $qt,
                    className => 'QuantitationType',
                    association => 'DataType',
                    values => {
                  	    DataType => 'float',
                  	    },
                    ontology => $mo_helper,
                  );

=head2 DESCRIPTION

This provides functionaliy for an ontology-aware OntologyEntry class
for entries of type Class.

Bio::MAGE::Tools::MGEDOntologyClassEntry is a concrete class.

Superclass is: Bio::MAGE::Tools::MGEDOntologyEntry

Subclasses are: none

=cut

$DEBUG = 0;

###############################################################################
#
# Constructor
#
###############################################################################
sub new {
  my $class = shift;
  if (ref($class)) {
    $class = ref($class);
  }
  my $self = bless {}, $class;

  my %args = @_;

  #### Manually define some recursive entries in the ontology.  This should
  #### be moved to the MGEDOntologyHelper class
  $self->initializeRecursivePropertyMap
    unless ($self->getRecursivePropertyMap);

  #### Create this entry and all possible children
  $self->createEntry(%args);

  return $self;
}



###############################################################################
#
# Getter and Setter methods for class attributes
#
###############################################################################

=head2 ATTRIBUTES

Attributes are simple data types that belong to a single instance of a
class. In the Perl implementation of the MAGE-OM classes, the
interface to attributes is implemented using separate setter and
getter methods for each attribute.

=over

=item mgedOntologyClass

Stores the name of the equivalent class or property in the MGED
Ontology for this OntologyEntry

=cut


###############################################################################
# setMgedOntologyClass
###############################################################################
sub setMgedOntologyClass {
  my $self = shift;
  my $attributeName = 'mgedOntologyClass';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getMgedOntologyClass
###############################################################################
sub getMgedOntologyClass {
  my $self = shift;
  my $attributeName = 'mgedOntologyClass';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item isInstantiable

Stores true if the class is an instantiable one.

=cut


###############################################################################
# setIsInstantiable
###############################################################################
sub setIsInstantiable {
  my $self = shift;
  my $attributeName = 'isInstantiable';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getIsInstantiable
###############################################################################
sub getIsInstantiable {
  my $self = shift;
  my $attributeName = 'isInstantiable';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item isInstantiable

Contains a hash reference to a list of OM clases that are circular
references which should only be followed one level.

=cut


###############################################################################
# setRecursivePropertyMap
###############################################################################
sub setRecursivePropertyMap {
  my $self = shift;
  my $attributeName = 'recursivePropertyMap';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getRecursivePropertyMap
###############################################################################
sub getRecursivePropertyMap {
  my $self = shift;
  my $attributeName = 'recursivePropertyMap';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


###############################################################################
# initializeRecursivePropertyMap
###############################################################################
sub initializeRecursivePropertyMap {
  my $self = shift;

  my %recursivePropertyMap = (
			      "has_parent_organization" => "Organization",
			      "has_software" => "Software",
			      "has_hardware" => "Hardware",
			     );
  $self->setRecursivePropertyMap(\%recursivePropertyMap);

  return 1;
}



###############################################################################
#
# Regular methods
#
###############################################################################

###############################################################################
# createEntry
###############################################################################
sub createEntry {
  my $self = shift || die ("self not passed");

  my %args = @_;
  my $className = $args{'className'} || die "ERROR: className not passed";
  my $ontology = $args{'ontology'} || die "ERROR: ontology not passed";
  my $parentObject = $args{'parentObject'};
  my $association = $args{'association'};
  my $values = $args{'values'} || die("ERROR: values not passed");
  my $usedValues = $args{'usedValues'};

  unless (defined($usedValues)) {
    $usedValues = {};
  }

  #### Set class variable
  $self->setMgedOntologyClass($className);

  #### But if there was a parentObject supplied, then the mgedOntologyClass
  #### should be the association name
  #### FIXME This needs to be far more complex.  First the translation
  #### from Characteristics needs to be converted to BioMaterialCharacterics
  #### And we should probably be checking if $className is a MAGE class
  #### instead of looking for $parentObject
  if (defined($parentObject) &&
      $parentObject->class_name() ne 'Bio::MAGE::Description::OntologyEntry') {

    $DEBUG && print STDERR ("Checking Association: $association\n");

    if ($ontology->classExists($association)) {
      $self->setMgedOntologyClass($association);
    } 
    else {

      my $test = "$className$association";

      $DEBUG && print STDERR ("Checking: $test\n");

      if ($ontology->classExists($test)) {
	$self->setMgedOntologyClass($test);
      } 
      else {
	my @superclasses = $parentObject->get_superclasses();
	my $found = 0;
	foreach my $superclass (@superclasses) {
	  $superclass =~ s/^.+:://;
	  $test = "$superclass$association";

	  $DEBUG && print STDERR ("Checking: $test\n");

	  if ($ontology->classExists($test)) {
	    $self->setMgedOntologyClass($test);
	    $found = 1;
	    last;
	  }
	}

	unless ($found) {
	  die("ERROR: Unable to determine MO class name from class $className with association $association");
	}
      }
    }
  }


  #### If the passed class is defined and exists in the ontology
  if (defined($self->getMgedOntologyClass()) && $ontology->classExists($className)) {

    ## Check for Policy 2 : Instantiable MGED Ontology Class
    if ($ontology->isInstantiable($self->getMgedOntologyClass())) {

      $DEBUG && print STDERR "--- MGEDOntologyClassEntry working on instantiable ".$self->getMgedOntologyClass."\n";

      #### Set the attributes for this case
      $self->setIsInstantiable(1);
      $self->setIsAssignable(1);

      ## Set category to MGED Ontology Class
      $self->setCategory($self->getMgedOntologyClass());

      ## Get list of possible instances
      my @assignableValues = $ontology->getInstances($self->getMgedOntologyClass());
      $self->setAssignableValues(\@assignableValues);
#      $DEBUG && print STDERR "  assignableValues=".join(",",@assignableValues)."\n";;

      #### See if the user has provided a value for this class
      my $value;
      if ($self->getIsAssigned()) {
	$value = $self->getValue();
      } else {
	$self->setIsAssigned(0);
	$value = $ontology->getUserSpecifiedValue(
	  className => $self->getMgedOntologyClass(),
	  values => $values,
	  usedValues => $usedValues,
        );
      }

      #### Check to see whether this is a valid selection
      if (defined($value)) {

	$DEBUG && print STDERR "+++ Creating instantiable ".$self->getMgedOntologyClass." => $value\n";

	if (grep(/^$value$/,@assignableValues)) {
	  $self->setIsAssigned(1);
	  $self->setOntologyReference($ontology->getOntologyReference($value));

	#### Else, this is an invalid entry
	} else {
	  carp ("Warning: Tried to set $className=$value, but the only allowed values are (".join(",",@assignableValues).")");
	}

# FIXME the usedValues tracking mechanism probably should be fixed and reinstated at some point
#	$value = $ontology->retireUserSpecifiedValue(
#	  className => $self->getMgedOntologyClass(),
#	  values => $values,
#	  usedValues => $usedValues,
#        );

      }

      #### Set the MO structure for this Ontologyentry
      $self->setValue($value);

    }


    ## Policy 3 : Abstract MGED Ontology Class
    else {

      $DEBUG && print STDERR "--- MGEDOntologyClassEntry working on abstract ".$self->getMgedOntologyClass."\n";

      $self->setIsInstantiable(0);

      ## Set category and value to the MGED Ontology Class
      $self->setCategory($self->getMgedOntologyClass());

      #### See if the user has provided a value for this class
      my $value = $ontology->getUserSpecifiedValue(
	className => $className,
	values => $values,
	usedValues => $usedValues,
	ontology => $ontology,
      );

      # If there's a value, use it; otherwise use the className
      $self->setValue($value || $self->getMgedOntologyClass());

      ## Add MO DB reference
      $self->setOntologyReference(
        $ontology->getOntologyReference($self->getValue()));

      ## Check if a sub class should be assigned 
      my @subclasses = $ontology->getSubclasses($self->getMgedOntologyClass());

      if (scalar(@subclasses) == 0) {
	$self->setIsAssignable(0);
      } else {
	$self->setIsAssignable(1);
	$self->setAssignableValues( [] );

	#### Loop through the subclasses to see if the user specified one of them
	my $selectedSubclass;
	foreach my $subclass (@subclasses) {

          #### See if the user has provided a value for this class
          my $value = $ontology->getUserSpecifiedValue(
	    className => $subclass,
	    values => $values,
	    usedValues => $usedValues,
	    ontology => $ontology,
          );

	  #### The the user did mention this class
	  if ($value) {

	    $DEBUG && print STDERR "+++ Creating abstract ".$self->getMgedOntologyClass." => $value\n";

	    if ($selectedSubclass) {
	      die("ERROR: More that one subclass of ".$self->getMgedOntologyClass().
		  " specified.  This is not permitted.  A separate association is required.");
	    } else {
	      $selectedSubclass = $subclass;
	    }
	  }

	}

	## Create subclass OE's and store before assigned.
	my $nAssignedSubclasses = 0;

	#### If this is the class that the user specified, then assign it
	if (defined($selectedSubclass)) {
	    #print STDERR "Setting $subclass as assigned...\n";
	  my $childClass = Bio::MAGE::Tools::MGEDOntologyClassEntry->new(
            className  => $selectedSubclass,
            values     => $values,
            usedValues => $usedValues,
            ontology   => $ontology,
          );
	  $childClass->setIsAssigned(1);
	  $nAssignedSubclasses++ if ($childClass->getIsAssigned());
	  #print "New $subclass isAssigned: ".($childClass->getIsAssigned() || '')."\n";
	  push(@{$self->getAssignableValues()},$childClass);

	}

	## If only one was assigned
	if ($nAssignedSubclasses == 1) {
	  foreach my $childClass ( @{$self->getAssignableValues()}) {
	    if ($childClass->getIsAssigned()) {
	      $self->addAssociations($childClass);
	    }
	  }
	} # end if $nAssignedSubclasses == 1

      } # end else

    } # end Policy 3


    #### If we know our parent object and association, associate with the parent
    if (defined($parentObject) && defined($association)) {
      my %associations = $parentObject->associations();
      #print "assoc = $association\n";
      #print Data::Dumper->Dump([ \%associations ]);
      my $cardinality = $associations{lcfirst($association)}->other()->cardinality();
      my $setter = "set$association";
      if ($cardinality =~ /N$/) {
        $setter = "add$association";
      }
      $parentObject->$setter($self);
    }


    ## Create nested MGEDOntologyEntries for properties of this MGED
    ## Ontology class and add them to OntologyEntry's
    ## Associations_list

    my %propNameType = $ontology->getProperties(
      $self->getMgedOntologyClass()
    );

  PROPERTY: while (my ($propName,$propType) = each (%propNameType)) {

      if ($self->getRecursivePropertyMap()->{$propName} &&
	  $self->getRecursivePropertyMap()->{$propName} eq
            $self->getMgedOntologyClass()) {
	next PROPERTY;

      } 
      else {

	$DEBUG && print STDERR ("=== ",$self->getMgedOntologyClass,": $propName -> $propType\n");

	#### See if the user has provided a value for this property
	my $value = $ontology->getUserSpecifiedValue(
	    className => $propName,
	    values => $values,
	    usedValues => $usedValues,
	    ontology => $ontology,
        );

	#### The the user did mention this property
	if ($value) {

	  # has_accession in the absence of has_database is bad.
	  if ($propName eq 'has_accession' && !$values->{'has_database'}){
	    carp ("Warning: Accessions (has_accession => $value) should be associated with a database (has_database).\n");
	  }

	  # Skip creating has_accession or has_value if we have has_database to hang them from
	  if (($propName eq 'has_accession' || $propName eq 'has_value')
	      && $values->{'has_database'}){

	    #### See if the user has provided a hash with key 'identifier'
	    my $has_database = $ontology->getUserSpecifiedValue(
	      className  => 'has_database',
	      values     => $values,
	      usedValues => $usedValues,
	      ontology   => $ontology,
            );

	    next PROPERTY if (ref($has_database) eq 'HASH' && $has_database->{'identifier'});
	  }

	  # For database entries we create a full MAGE DatabaseEntry.
	  if ($propName eq 'has_database' 
	      && ref($value) eq 'HASH' 
	      && $value->{'identifier'}){

	    my $database = Bio::MAGE::Description::Database->new(%$value);
	    my $databaseEntry = Bio::MAGE::Description::DatabaseEntry->new(
              database  => $database,
	      accession => $values->{'has_accession'},
	    );

	    $self->setOntologyReference($databaseEntry);
	    $self->setValue($values->{'has_value'}) if $values->{'has_value'};
	  }
	  else {
	  
	    $DEBUG && print STDERR "+++ Creating abstract ".$propName." => $value\n";
	  
	    my $childObject = Bio::MAGE::Tools::MGEDOntologyPropertyEntry->new(
              propertyName => $propName,
              propertyType => $propType,
	      # If the value is a hash, recurse into that structure
              values => (ref($value) eq 'HASH' ? $value : $values),
              usedValues => $usedValues,
              ontology => $ontology,
            );
	    # Don't add empty OntologyEntry objects
	    $self->addAssociations($childObject);

# FIXME the usedValues tracking mechanism probably should be fixed and reinstated at some point
#	  $value = $ontology->retireUserSpecifiedValue(
#	    className => $propName,
#	    values => $values,
#	    usedValues => $usedValues,
#          );
	  }
	}
      }
    }


  #### Else if the class is not defined or doesn't exist, complain
  } else {
    die("Argh!  No class");
  }


  return $self;

}



###############################################################################
# assignValue
###############################################################################
sub assignValue {
  my $self = shift || die ("self not passed");
  my $val = shift;

      $DEBUG && print STDERR "Setting value $val\n";

  if ($self->getIsAssignable() && ! $self->getIsAssigned() &&
      grep(/^$val$/,@{$self->getAssignableValues()})) {

    ## Instantiable MGED Ontology Class
    if ($self->getIsInstantiable()) {
      $self->setValue($val);

      ## Correct the temporary MO DB reference
      # Java to be converted FIXME
      my $ontRef = $self->getOntologyReference();
      $ontRef->setAccession("#".$val);
      my $uri = $ontRef->getURI();
      $uri =~ s/placeholder/$val/;
      $ontRef->setURI($uri);

    } else {
      ## Abstract class with assignable subclass
      ## Add association to selected subclass and delete the other choises
      #$self->addToAssociations((MGEDOntologyClassEntry) $val);
      $self->addToAssociations($val);
      $self->setAssignableValues( [] );
    }

    $self->setIsAssigned(1);
  }

}

=head1 BUGS

Please send bug reports to the project mailing list: (mged-mage 'at' lists 'dot' sf 'dot' net)

=head1 AUTHOR

Eric W. Deutsch (edeutsch 'at' systemsbiology 'dot' org)
followup work by Jason E. Stewart (jasons 'at' cpan 'dot' org)

=head1 SEE ALSO

perl(1).

=cut

#
# End the module by returning a true value
#
1;

