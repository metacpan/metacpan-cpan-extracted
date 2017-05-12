##############################
#
# Bio::MAGE::Tools::MGEDOntologyHelper
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

package  Bio::MAGE::Tools::MGEDOntologyHelper;

use strict;
use Carp;
use RDF::Redland;


use vars qw($VERSION $DEBUG
	    $model %nodeTypes $NORDF $format @list_members %nodeHash);

$NORDF = 0;
$DEBUG = 0;

$VERSION = q[$Id: MGEDOntologyHelper.pm,v 1.3 2005/09/27 15:38:40 awitney Exp $];

=head1 Bio::MAGE::Tools::MGEDOntologyHelper

=head2 SYNOPSIS

  my $mo_helper = Bio::MAGE::Tools::MGEDOntologyHelper->new(
                       sourceFile=>'MGEDOntology.owl',
                       databaseIdentifier=>'MO',
                       );


=head2 DESCRIPTION


=cut


###############################################################################
# Constructor
###############################################################################
sub new {
  my $class = shift;
  if (ref($class)) {
    $class = ref($class);
  }
  my $self = bless {}, $class;

  my %args = @_;
  my $sourceFile = $args{'sourceFile'};

  if (defined($sourceFile)) {
    $self->readSourceFile($sourceFile);
  }

  my $databaseIdentifier = $args{'databaseIdentifier'};
  $self->setDatabaseIdentifier($databaseIdentifier);

  return $self;

}



###############################################################################
# classExists
###############################################################################
sub classExists {
  my $self = shift || die("ERROR: self not passed");
  my $className = shift || die("ERROR: className not passed");

  my $node;

  if ($NORDF) {
    $node = 1;
  } else {
    $node = get_node($className);
  }

  #print "classExists: className=$className node=",$node,"\n";

  if (defined($node)) {
    return(1);
  } else {
    return(0);
  }

}


###############################################################################
# isInstantiable
###############################################################################
sub isInstantiable {
  my $self = shift || die("ERROR: self not passed");
  my $parentClass = shift || die("ERROR: parentClass not passed");

  if ($self->getInstances($parentClass)) {
    return(1);
  }

  return 0;

}


###############################################################################
# getInstances
###############################################################################
sub getInstances {
  my $self = shift || die("ERROR: self not passed");
  my $parentClass = shift || die("ERROR: parentClass not passed");

  print "[getInstances] $parentClass has instances:\n" if ($DEBUG);

  my @instances;

  if ($NORDF) {
    if ($parentClass eq "PolymerType") {
      @instances = ('DNA','RNA','protein');
    } else {
      @instances = ('eeny','meeny','moe');
    }
    return(@instances);
  }

  my $node = get_node($parentClass);
  return unless (defined($node));

  foreach my $instance (@{get_sources($nodeTypes{type_node}, $node)}) {
    my $instanceName = clean_MGED($instance->as_string);
    push(@instances,$instanceName);
    print "                  $instanceName\n" if ($DEBUG);
  }

  return @instances;
}


###############################################################################
# getSubclasses
###############################################################################
sub getSubclasses {
  my $self = shift || die("ERROR: self not passed");
  my $parentClass = shift || die("ERROR: parentClass not passed");

  print "[getSubclasses] $parentClass has subclasses:\n" if ($DEBUG);

  my @subclasses;

  my $node = get_node($parentClass);
  return unless (defined($node));

  foreach my $subclass (@{get_sources($nodeTypes{subclass_node}, $node)}) {
    my $subclassName = clean_MGED($subclass->as_string);
    push(@subclasses,$subclassName);
    print "                  $subclassName\n" if ($DEBUG);
  }

  return @subclasses;
}



###############################################################################
# getSuperclasses
###############################################################################
sub getSuperclasses {
  my $self = shift || die("ERROR: self not passed");
  my $parentClass = shift || die("ERROR: parentClass not passed");

  print "[getSuperclasses] $parentClass has superclasses:\n" if ($DEBUG);

  my @superclasses;

  my $node = get_node($parentClass);
  return unless (defined($node));

  # finds all the subclasses of this class
  foreach my $subclass (@{get_targets($node, $nodeTypes{subclass_node})}) {
    my $comment = $model->target($subclass, $nodeTypes{comment_node});

    # fetch the list of types for the node
    foreach my $type (@{get_types($subclass)}) {

      # these are the superclasses, store them for printing below
      if ($type eq 'Class') {
	push(@superclasses, clean_MGED($subclass->as_string));
      }
    }
  }

  return @superclasses;
}



###############################################################################
# getProperties
###############################################################################
sub getProperties {
  my $self = shift || die("ERROR: self not passed");
  my $parentClass = shift || die("ERROR: parentClass not passed");

  my $DEBUG_THIS = $DEBUG;
  $DEBUG_THIS = 0;

  print "[getProperties] $parentClass has properties:\n" if ($DEBUG_THIS);

  my %properties;
  @list_members = ();
  my @used_in_class = ();

  my $node = get_node($parentClass);
  return unless (defined($node));


  foreach my $subclass (@{get_targets($node, $nodeTypes{subclass_node})})     # finds all the subclasses of this class
    {
     my $comment = $model->target($subclass, $nodeTypes{comment_node});

     foreach my $type (@{get_types($subclass)})     # fetch the list of types for the node
       {
        #-----------------------------------------------------------------
        # check what type of subClass
        #-----------------------------------------------------------------

        if($type eq 'Restriction')
           {
            #-----------------------------------------------------------------
            # find the association e.g. has_units
            #-----------------------------------------------------------------

            foreach my $property (@{get_targets($subclass, $nodeTypes{property_node})})
              {

	       my $propertyName = clean_MGED($property->as_string);
               print $propertyName." - " if ($DEBUG_THIS);
	       $properties{$propertyName} = '?';

               print "\t=>\t" if ($DEBUG_THIS);

               #-----------------------------------------------------------------
               # find the classes associated with the Restriction e.g. Unit
               #-----------------------------------------------------------------

               my $node2;

               if($format eq 'daml'){$node2 = $nodeTypes{hasclass_node}}
                elsif($format eq 'owl'){$node2 = $nodeTypes{somevaluesfrom_node}}

               foreach my $class (@{get_targets($subclass, $node2)})
                 {

                  foreach my $new_type (@{get_types($class)})     # fetch the list of types for the node
                    {
                     if($new_type eq 'Thing')
                        {
                         print $new_type." - " if ($DEBUG_THIS);
                         foreach (@{get_types($class)}) {print "(".$_.") " if ($DEBUG_THIS);}
			 $properties{$propertyName} = join(",",@{get_types($class)});
                        }
                       elsif($new_type eq 'Class')
                         {
                          foreach my $list (@{get_targets($class, $nodeTypes{oneof_node})})     # finds all the individuals of this class
                            {   
                             if($format eq 'owl')
                                {
                                 #-----------------------------------------------------------------
                                 # OWL: if its a list of instances
                                 #-----------------------------------------------------------------

                                 foreach (@{get_list_items_owl($list)})
                                   {
                                    print "\n\t- ".clean_MGED($_->as_string)." - " if ($DEBUG_THIS);
				    $properties{$propertyName} = join(",",@{get_types($_)});
                                    foreach (@{get_types($_)}) {print "(".$_.") " if ($DEBUG_THIS);}      # fetch the list of types for the node

                                   }

                                 @list_members = (); # reset the array
                                }
                               elsif($format eq 'daml')
                                 {
                                  #-----------------------------------------------------------------
                                  # DAML: if its a list of instances
                                  #-----------------------------------------------------------------

                                     foreach my $list_type (@{get_types($list)})     # fetch the list of types for the node
                                       {

                                        #-----------------------------------------------------------------
                                        # if it is a List, get the List elements
                                        #-----------------------------------------------------------------

                                        if($list_type eq 'List')
                                           {
                                            foreach (@{get_list_items_daml($list)})
                                              {
                                               print "\n\t- ".clean_MGED($_->as_string) if ($DEBUG_THIS);

                                               print " - " if ($DEBUG_THIS);
					       $properties{$propertyName} = join(",",@{get_types($_)});
                                               foreach (@{get_types($_)}) {print "(".$_.") " if ($DEBUG_THIS);}      # fetch the list of types for the node

                                              }

                                            @list_members = (); # reset the array

                                           }
                                       }
                                 }
                            }

                          #-----------------------------------------------------------------
                          # if its just a class then print the class, eg Unit
                          #-----------------------------------------------------------------

                          unless(clean_MGED($class->as_string) =~ m/r\d+/)      # don't print the blank identifiers - HACK JOB!
                           {
                            print clean_MGED($class->as_string) if ($DEBUG_THIS);

                            print " - " if ($DEBUG_THIS);
			    $properties{$propertyName} = clean_MGED($class->as_string);
                            foreach (@{get_types($class)}) {print "(".$_.") " if ($DEBUG_THIS);}      # fetch the list of types for the node

                            push(@used_in_class, $class);  # for USED IN section, this won't work yet
                           }
                         }

                        if(clean_MGED($class->as_string) =~ m/^string$|^boolean$|^integer$/)        # another hack job!
                           {                                                                        # These are Datatype properties
                            print clean_MGED($class->as_string) if ($DEBUG_THIS);                                    # and so are their own class
                            foreach (@{get_types($class)}) {print "(".$_.") " if ($DEBUG_THIS);}
                           }
                    }
                 }

              }
           }
       }

     print "\n" if ($DEBUG_THIS);

    }


  # Deal with property inheritance here
  foreach my $superclass ($self->getSuperclasses($parentClass)){

    my %superclassProperties;
    # Don't recurse into the MAGE model itself
    if ($superclass ne 'MGEDOntology'){
      %superclassProperties = $self->getProperties($superclass);
    }
    # Merge superclass properties into %properties
    while (my ($key, $value) = each %superclassProperties){
      $properties{$key} ||= $value;
    }
    
  }

  return %properties;

}


###############################################################################
# setDatabaseIdentifier
###############################################################################
sub setDatabaseIdentifier {
  my $self = shift;
  my $attributeName = 'DatabaseIdentifier';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}

###############################################################################
# getDatabaseIdentifier
###############################################################################
sub getDatabaseIdentifier {
  my $self = shift;
  my $attributeName = 'DatabaseIdentifier';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  # Default MO database identifier is set here
  return $self->{"__$attributeName"} || 'www.mged.org:Database:MO';
}


###############################################################################
# getOntologyReference
###############################################################################
sub getOntologyReference {
  my $self               = shift || croak("ERROR: self not passed");
  my $term               = shift || croak("ERROR: term not passed");
  
  my $databaseEntry = Bio::MAGE::Description::DatabaseEntry->new(
    accession => "#$term",
    URI => "http://mged.sourceforge.net/ontologies/MGEDOntology.php#$term",
    database => Bio::MAGE::Description::Database->new(
      identifier => $self->getDatabaseIdentifier,
      name=>"The MGED Ontology",
      URI => "http://mged.sourceforge.net/ontologies/MGEDOntology.php",
      version => $self->{version}
    ),
  );

  return $databaseEntry;

}


###############################################################################
# getUserSpecifiedValue
###############################################################################
sub getUserSpecifiedValue {
  my $self = shift || die("ERROR: self not passed");

  my %args = @_;
  my $className = $args{'className'} || die "ERROR: className not passed";
  my $values = $args{'values'} || die("ERROR: values not passed");
  my $usedValues = $args{'usedValues'} || die("ERROR: usedValues not passed");

  my $specifiedValue;

  my @assignableValues = $self->getInstances($className);

  #### See if the value is in the used hash
  while (my ($key,$value) = each (%{$usedValues})) {
    if ($key eq $className) {
      print Data::Dumper->Dump([$values]);
      print Data::Dumper->Dump([$usedValues]);
      die("ERROR: Encountered a duplicate class $className for which a value was already assigned elsewhere");
    }
  }

  #### See if the value is in the hash
  while (my ($key,$value) = each (%{$values})) {

    #print "Looking for user def value at $key with className $className\n";

    #### If found
    if ($key eq $className) {
      #print STDERR "Found user-specified $className => $value\n";
      #### Set this to the returned value and move the entry to usedValues hash
      $specifiedValue = $value;
    }

  }

  return $specifiedValue;

}


###############################################################################
# retireUserSpecifiedValue
###############################################################################
sub retireUserSpecifiedValue {
  my $self = shift || die("ERROR: self not passed");

  my %args = @_;
  my $className = $args{'className'} || die "ERROR: className not passed";
  my $values = $args{'values'} || die("ERROR: values not passed");
  my $usedValues = $args{'usedValues'} || die("ERROR: usedValues not passed");

  my $specifiedValue;

  #### See if the value is in the used hash
  while (my ($key,$value) = each (%{$usedValues})) {
    if ($key eq $className) {
      die("ERROR: Encountered already retired $className.");
    }
  }

  #### See if the value is in the hash
  while (my ($key,$value) = each (%{$values})) {

    #### If found
    if ($key eq $className) {
      #print "Found user-specified $className\n";
      #### Set this to the returned value and move the entry to usedValues hash
      $specifiedValue = $value;
      $usedValues->{$key} = $value;
      delete($values->{$key});
    }

  }

  return $specifiedValue;

}



###############################################################################
###############################################################################
# RDF OWL Read related stuff
###############################################################################
###############################################################################



###############################################################################
# readSourceFile
###############################################################################
sub readSourceFile {
  my $self = shift || die("ERROR: self not passed");
  my $sourceFile = shift || die("ERROR: sourceFile not passwd");
  $format = shift || "owl";


  unless (-e $sourceFile) {
    die("ERROR: Unable to find source file '$sourceFile'");
  }

  # specify the RDF parser to use
  my $parser = new RDF::Redland::Parser("raptor");

  # generate Redland URI object pointing to specified RDF file
  my $uri = new RDF::Redland::URI("file:$sourceFile");

  # choose the method for storing the model and then set up model 
  # object, with the specified storage method
  my $storage = new RDF::Redland::Storage("hashes", "test",
					  "new='yes',hash-type='memory'");
  $model   = new RDF::Redland::Model($storage, "");

  # load the model from the file
  print "Loading Model..... \n" if ($DEBUG);
  $parser->parse_into_model($uri, undef, $model);
  print "Model loaded\tmodel size = ".$model->size."\n" if ($DEBUG);


  #-----------------------------------------------------------------
  # define generic nodes (may be able to get this from the RDF
  # file automatically, but can't see how to do it yet!)
  #-----------------------------------------------------------------

  my $owl_namespace  = "http://www.w3.org/2002/07/owl";
  my $daml_namespace = "http://www.daml.org/2001/03/daml+oil";

  my $namespace;
  my $namespace2;

  if ($format eq 'daml') {
    die "\n\nDAML format no longer supported, please use OWL format\n\n";   
#    $namespace = $daml_namespace;
#    $namespace2 = $daml_namespace;
  } elsif ($format eq 'owl') {
    $namespace = $owl_namespace;
    $namespace2 = 'http://www.w3.org/1999/02/22-rdf-syntax-ns';
  } else { 
    die "\n\nUnknown format\n\n";
  }


  $nodeTypes{subclass_node}          = new RDF::Redland::Node->new_from_uri_string("http://www.w3.org/2000/01/rdf-schema#subClassOf");
  $nodeTypes{class_node}             = new RDF::Redland::Node->new_from_uri_string("$namespace#Class");
  $nodeTypes{hasclass_node}          = new RDF::Redland::Node->new_from_uri_string("$namespace#hasClass");
  $nodeTypes{property_node}          = new RDF::Redland::Node->new_from_uri_string("$namespace#onProperty");
  $nodeTypes{object_property_node}   = new RDF::Redland::Node->new_from_uri_string("$namespace#ObjectProperty");
  $nodeTypes{unique_property_node}   = new RDF::Redland::Node->new_from_uri_string("$namespace#UniqueProperty");
  $nodeTypes{datatype_property_node} = new RDF::Redland::Node->new_from_uri_string("$namespace#DatatypeProperty");
  $nodeTypes{type_node}              = new RDF::Redland::Node->new_from_uri_string("http://www.w3.org/1999/02/22-rdf-syntax-ns#type");
  $nodeTypes{comment_node}           = new RDF::Redland::Node->new_from_uri_string("http://www.w3.org/2000/01/rdf-schema#comment");
  $nodeTypes{domain_node}            = new RDF::Redland::Node->new_from_uri_string("http://www.w3.org/2000/01/rdf-schema#domain");
  $nodeTypes{oneof_node}             = new RDF::Redland::Node->new_from_uri_string("$namespace#oneOf");
  $nodeTypes{thing_node}             = new RDF::Redland::Node->new_from_uri_string("$namespace#Thing");
  $nodeTypes{list_node}              = new RDF::Redland::Node->new_from_uri_string("$namespace#List");
  $nodeTypes{rest_node}              = new RDF::Redland::Node->new_from_uri_string("$namespace2#rest");
  $nodeTypes{first_node}             = new RDF::Redland::Node->new_from_uri_string("$namespace2#first");
  $nodeTypes{restriction_node}       = new RDF::Redland::Node->new_from_uri_string("$namespace#Restriction");

  $nodeTypes{file_node}              = new RDF::Redland::Node->new_from_uri_string("http://mged.sourceforge.net/ontologies/MGEDOntology.owl");
  $nodeTypes{version_node}           = new RDF::Redland::Node->new_from_uri_string("$namespace#versionInfo");
  $nodeTypes{date_node}              = new RDF::Redland::Node->new_from_uri_string("http://www.w3.org/2002/07/dc#date");

  $nodeTypes{somevaluesfrom_node}    = new RDF::Redland::Node->new_from_uri_string("$namespace#someValuesFrom");

    #-----------------------------------------------------------------
    # print version info from the file
    #-----------------------------------------------------------------

    foreach my $version (@{get_targets($nodeTypes{file_node}, $nodeTypes{version_node})}) {
      
      $self->{version} = clean_MGED($version->as_string);
      
       if ($DEBUG) {
         print "\nVERSION:\t";
         print clean_MGED($version->as_string)."\n"
       }
    }

    foreach my $date (@{get_targets($nodeTypes{file_node}, $nodeTypes{date_node})}) {
      
       if ($DEBUG) {
         print "\nRELEASE DATE:\t";
         print clean_MGED($date->as_string)."\n"
       }
    }

  return 1;
}



########################################################################
# get_node - Returns the node given a string name
########################################################################
sub get_node {
  my ($nodeName) = @_;

  make_node_hash() unless (scalar %nodeHash);

  return $nodeHash{$nodeName};

}


########################################################################
# make_node_hash - Creates a hash of othe nodes
########################################################################
sub make_node_hash {

  my $iterator = $model->sources_iterator($nodeTypes{type_node},
					  $nodeTypes{class_node});
  while($iterator && !$iterator->end) {
    my $node = $iterator->current;
    $nodeHash{clean_MGED($node->as_string)} = $node;
    $iterator->next;
  }

  return;

}


########################################################################
# get_targets - generic subroutine to get targets from source and arc
########################################################################

sub get_targets {
  my ($source, $arc) = @_;

  my(@targets) = $model->targets($source, $arc);

  return \@targets;
}


########################################################################
# get_sources - generic subroutine to get sources from target and arc
########################################################################
sub get_sources {
  my ($arc, $target) = @_;

  my (@sources) = $model->sources($arc, $target);

  return \@sources;
}


########################################################################
# get_types - retrieves list of types of a Node
########################################################################
sub get_types {
  my ($source) = @_;

  my(@targets) = $model->targets($source, $nodeTypes{type_node});

  my %seen;       # %seen and @unique just used to remove duplicate
  my @unique;     # nodes in the @targets list 

  foreach my $item (@targets) {
    my $type = clean_MGED($item->as_string);
    push(@unique, $type) unless $seen{$type}++;
  }

  return \@unique;   # return only the unique values
}


################################################################
# clean_MGED - cleans the stringified Node description
################################################################

sub clean_MGED {
  my($input) = @_;

  $input =~ s/\^\^<http:\/\/www\.w3\.org\/2001\/XMLSchema#string>//;
  $input =~ s/.+#//;
  $input =~ s/\]$//;

  return $input;
}


########################################################################
# get_list_items_daml - retrieves all the elements of a List from DAML
########################################################################

sub get_list_items_daml {
  my($list_node) = @_;

  # get first member of list

  foreach my $list_item (@{get_targets($list_node, $nodeTypes{first_node})})
    {
     push(@list_members, $list_item);   # add item to list
    }

  # get second level list (rest Node)

  foreach my $list_item (@{get_targets($list_node, $nodeTypes{rest_node})})
    {
     foreach my $new_type (@{get_types($list_item)})
       {
        if($new_type eq 'List'){get_list_items_daml($list_item, @list_members)}     # recursive subroutine to collect all members of the list
         elsif($new_type eq 'nil'){}
         else{die "\n\nUNKNOWN TYPE IN THE LIST\n\n"}
       }
    }

  return \@list_members;
}

########################################################################
# get_list_item_owls - retrieves all the elements of a List from OWL
########################################################################

sub get_list_items_owl {
  my($list_node) = @_;

  # get first member of list

  foreach my $list_item (@{get_targets($list_node, $nodeTypes{first_node})})
    {
     push(@list_members, $list_item);   # add item to list
    }

  # get second level list (rest Node)

  foreach my $list_item (@{get_targets($list_node, $nodeTypes{rest_node})})
    {
     get_list_items_owl($list_item, @list_members);
    }

  return \@list_members;
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

