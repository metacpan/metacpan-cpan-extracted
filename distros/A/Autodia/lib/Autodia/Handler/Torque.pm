################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
#                                                              #
# ----                                                         #
# 03.05.04 - J. Gilbreath - Vanderbilt University              #
#  - Modified to handle tables with only one column            #
#       as well as those without any keys (primary or          #
#       foreign).                                              #
#  - Foreign keys, indexed columns, and unique columns were    #
#       also added as operations on each table.                #
#  - Primary key support was changed to add a operation for    #
#       each primary key instead of  grouping all of them      #
#       under one operation.                                   #
#  - Relationship code was enhanced to handle foreign key      #
#       relationships  to the same table without throwing      #
#       an exception during diagram construction.              #
#  - Finally, _subParse function was trimmed and sub functions #
#       broken out for individual portions of table            #
#       processing.                                            #
#  - TODO : Add support for onUpdate and onDelete for foreign  #
#       keys (maybe a comment on the operation?)               #
#  ----                                                        #
################################################################
package Autodia::Handler::Torque;

require Exporter;

use strict;
use XML::Simple;
## added for debugging - jg
use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse {
  my $self     = shift;
  my $fh       = shift;
  my $filename = shift;

  my $Diagram  = $self->{Diagram};

  my $xml = XMLin(join('',<$fh>));

  #print Dumper($xml->{table});
  my %tables = ();
  my @relationships = ();

  # process tables

  foreach my $tablename (sort keys %{$xml->{'table'}}) {
    #print "Processing table $tablename\n";

    my $Class = Autodia::Diagram::Class->new($tablename);
    $Diagram->add_class($Class);

    # Orignially primary keys were placed into a HASH and all appeared as one 
    # operation on the class (table).  This was replaced to generate an operation
    # for each Primary Key to reduce the size of the table width for tables with
    # many primary keys.
    # In addition, foreign keys, index columns, and unique columns were added as
    # operations as well. -jg
    # primary key(s)
    #my $primary_key = { name=>'Primary Key', type=>'pk', Params=>[], visibility=>0, };

    $tables{$tablename} = $Class;

    # process column(s) and primary key(s)
    _processColumns($Class, $xml, $tablename);

    # process foreign key(s)
    _processForeignKeys($self, $Class, $xml, $tablename);

    # process index(es)
    _processIndexes($Class, $xml, $tablename);

    # process unique column(s)
    _processUniqueColumns($Class, $xml, $tablename);

  } # end foreach table
} # end _parse

####
# Adds a Primary Key as an operation of the given class
####
sub _addPKOperation {
    my ($localClass , $localColumn) = @_;
    $localClass->add_operation({name=>"Primary Key", type=>'pk', Params=>[{Name=>$localColumn, Type=>''}],
        visibility=>0 });
}

####
# Adds a Foreign Key as an operation of the given class
####
sub _addFKOperation {
    my ($localClass , $localFK, $localFKTable) = @_;
    $localClass->add_operation({name=>"Foreign Key", type=>'fk', Params=>[{Name=>$localFK, Type=>$localFKTable}],
        visibility=>0 });
}

####
# Adds an Indexed Column as an operation of the given class
####
sub _addIndexOperation {
    my ($localClass , $localColumn) = @_;
    $localClass->add_operation({name=>"Indexed Column", type=>'ic', Params=>[{Name=>$localColumn, Type=>''}],
        visibility=>0 });
}

####
# Adds a Unique Column as an operation of the given class
####
sub _addUniqueOperation {
    my ($localClass , $localColumn) = @_;
    $localClass->add_operation({name=>"Unique Column", type=>'uc', Params=>[{Name=>$localColumn, Type=>''}],
        visibility=>0 });
}


####
# Builds a Relationship for the given Class based on the given Foreign Key 
# reference and adds it to the Diagram
####
sub _buildFKRelationship {
    my ($localSelf, $localClass, $localFK) = @_;
      # create foreign key table or get it if already present
    my $Superclass = Autodia::Diagram::Superclass->new($localFK);
    my $exists_already = $localSelf->{Diagram}->add_superclass($Superclass);
      if (ref $exists_already) {
	$Superclass = $exists_already;
      }

      # create new relationship
    my $Relationship = Autodia::Diagram::Inheritance->new($localClass, $Superclass);
      # add Relationship to superclass
      $Superclass->add_inheritance($Relationship);
      # add Relationship to class
    $localClass->add_inheritance($Relationship);
      # add Relationship to diagram
    $localSelf->{Diagram}->add_inheritance($Relationship);
}

####
# Constructs a Foreign Key compound string from the given HASH
####
sub _constructForeignKey {
    my %fkHash = @_;
    return "(l=".$fkHash{"local"}." : f=". $fkHash{"foreign"}.") ";
}

####
# Constructs a Type for the column based on the given HASH
####
sub _constructType {
    my %typeHash = @_;
    if (exists $typeHash{"size"}) {
        return $typeHash{"type"}."(".$typeHash{"size"}.")";
    } else {
        return $typeHash{"type"};
  }
}

####
# Processes the Columns using the given XML, Class, and tablename
#
# The processing takes into account that depending on the quantity of columns a table
# has, the reference in the XML will map differently.  The HASH will key off of the 
# keyword "name" if the table has a single column.  The key to the HASH will be the
# column name if the table has more than one column.
####
sub _processColumns {
    my ($localClass, $localXML, $localTablename) = @_;
    my %columnHash;
    foreach my $column (keys %{$localXML ->{'table'}{$localTablename}{'column'}}) {
        no strict 'refs';
        %columnHash = %{$localXML ->{'table'}{$localTablename}{'column'}};
        if (exists $columnHash{"name"}) {
            # this is a table with one column
            my $columnName = $columnHash{"name"};
            #if ($column eq "name") {
            #    print "adding column $columnName to $localTablename\n";
            #}

            $localClass->add_attribute({
                        name => $columnName,
                        visibility => 0,
                        type => _constructType(%columnHash),
            });
            if ($column eq "primaryKey") {
                # add each primary key as a different operation to avoid wide
                # class diagrams
                _addPKOperation($localClass, $columnName);
            }

        } else {
            # this is a table with multiple columns in which case
            # the key is the column name repopulate hash one deep
            %columnHash = %{$localXML ->{'table'}{$localTablename}{'column'}{$column}};

            #print "adding column $column to $localTablename\n";

            $localClass->add_attribute({
                            name => $column,
                            visibility => 0,
                            type => _constructType(%columnHash),
			});

            if (exists $columnHash{"primaryKey"}) {
                # add each primary key as a different operation to avoid wide
                # class diagrams
                _addPKOperation($localClass, $column);
            }
        }
    }
} # end processColumns

####
# Processes the Foreign Keys using the given XML , Class, self, and tablename
#
# Again, XML will parse differently based on the quantity of foreign keys.  It will be a
# HASH if only one foreign key exists for the table.  It will be an ARRAY if there is more
# than one.  In addtion, a local relationship HASH holds the names of the tables in which
# relationships were made so only one relationship is constructed for tables with many
# foreign keys to the same table. 
####
sub _processForeignKeys {
    my ($localSelf, $localClass, $localXML, $localTablename) = @_;
    if (exists $localXML->{'table'}{$localTablename}{'foreign-key'}) {
        no strict 'refs';
        if (ref($localXML->{'table'}{$localTablename}{'foreign-key'}) eq 'HASH' ) {
            # this table has only one foreign-key
            #print "$localTablename has only one foreign key \n";
            #print Dumper($localXML ->{'table'}{$localTablename}{'foreign-key'});
            my %fKeyHash = (%{$localXML->{'table'}{$localTablename}{'foreign-key'}});
            _buildFKRelationship($localSelf, $localClass, $fKeyHash{"foreignTable"});
            if (exists $localXML ->{'table'}{$localTablename}{'foreign-key'}{'reference'}) {
                _addFKOperation($localClass,
                                _constructForeignKey(%{$localXML ->{'table'}{$localTablename}{'foreign-key'}{'reference'}}),
                                $fKeyHash{"foreignTable"});
            }
        } else {
            # this table has more than one foreign-key
            #print "$localTablename has more than one foreign key \n";
            #print Dumper($localXML->{table}{$localTablename}{'foreign-key'});

            # hash that holds the foreign key table names
            # this is used to avoid a division by zero error if a reference is made to the
            # same table more than once. -jg
            my %relMade; 
            # the foreign table name
            my $foreignTableName = "";
            foreach my $fKeyArray (@{$localXML->{'table'}{$localTablename}{'foreign-key'}}) {
                #print Dumper($fKeyArray);
                $foreignTableName = $fKeyArray->{'foreignTable'};
                #print "processing foreign key $foreignTableName \n";
                if (!exists ($relMade{"$foreignTableName"})) {
                    _buildFKRelationship($localSelf, $localClass, $foreignTableName);
                    # add it to the hash of foreign table names
                    $relMade{$foreignTableName} = $foreignTableName;
                }
                if (defined $fKeyArray->{'reference'}) {
                    _addFKOperation($localClass, 
                                    _constructForeignKey(%{$fKeyArray->{'reference'}}),
                                    $foreignTableName);
                }
            }
        }
    }
} # end processForeignKeys

####
# Processes the indexes using the given Class, XML, and tablename
#
# The processing here is complex due to the fact that the Torque schema DTD allows 
# a table to have multiple <index/> nodes defined each with one to many <index-column/>
# nodes as well.
####
sub _processIndexes {
    my ($localClass, $localXML, $localTablename) = @_;
    if (exists $localXML -> {'table'}{$localTablename}{'index'}) {
        no strict 'refs';
        if (ref ($localXML->{'table'}{$localTablename}{'index'}) eq 'HASH') {
            # so this is a HASH; however, it could be that the HASH contains only one 
            # index column or many just depending on the parse.
            #print Dumper($localXML->{'table'}{$localTablename}{'index'});
            my %indexHash = %{$localXML->{'table'}{$localTablename}{'index'}{'index-column'}};
            if (exists $indexHash{"name"}) {
                # this is indeed a single index column
                #print "$localTablename has only one index-column \n";
                _addIndexOperation($localClass, $indexHash{"name"});
            }
            else {
                foreach my $indexKey (keys %{$localXML->{'table'}{$localTablename}{'index'}{'index-column'}}) {
                    # the key is the actual name of the column
                    _addIndexOperation($localClass, $indexKey);
                }
            }
        }
        else {
            foreach  my $indexArray (@{$localXML->{'table'}{$localTablename}{'index'}}) {
                #print "Indexed columns for $localTablename are: \n";
                #print Dumper($indexArray);
                foreach my $indexKey (keys %{$indexArray->{'index-column'}}) {
                    if ($indexKey eq "name") {
                        # this is an instance of a table with multiple index nodes, one with 
                        # only one index-column and the other with many index-column nodes
                        # so add the name of the column
                        _addIndexOperation($localClass, $indexArray->{'index-column'}{'name'});
                    } else {
                        # the key is the actual name of the column
                        _addIndexOperation($localClass, $indexKey);
                    }
                } # end foreach in keys
            } # end foreach in array
       } # end else
    } # end if exists
} # end processIndexes

####
# Process the unique columns of the table using the given Class, XML, and tablename
#
# Just like index columns, the processing here is complex due to the fact that 
# the Torque schema DTD allows a table to have multiple <unique/> nodes defined each with 
# one to many <unique-column/> nodes as well.
####
sub _processUniqueColumns {
    my ($localClass, $localXML, $localTablename) = @_;
    if (exists $localXML -> {'table'}{$localTablename}{'unique'}) {
        no strict 'refs';
        if (ref ($localXML->{'table'}{$localTablename}{'unique'}) eq 'HASH') {
            # so this is a HASH; however, it could be that the HASH contains only one 
            # unique column or many just depending on the parse.
            #print Dumper($localXML->{'table'}{$localTablename}{'unique'});
            my %uniqueHash = %{$localXML->{'table'}{$localTablename}{'unique'}{'unique-column'}};
            if (exists $uniqueHash{"name"}) {
                # this is indeed a single unique column
                #print "$localTablename has only one unique-column \n";
                _addUniqueOperation($localClass, $uniqueHash{"name"});
            }
            else {
                foreach my $uniqueKey (keys %{$localXML->{'table'}{$localTablename}{'unique'}{'unique-column'}}) {
                    # the key is the actual name of the column
                    _addUniqueOperation($localClass, $uniqueKey);
                }
            }
        }
        else {
            # this is any array of unique columns
            foreach  my $uniqueArray (@{$localXML->{'table'}{$localTablename}{'unique'}}) {
                #print "Unique columns for $localTablename are: \n";
                #print Dumper($uniqueArray);
                foreach my $uniqueKey (keys %{$uniqueArray->{'unique-column'}}) {
                    if ($uniqueKey eq "name") {
                        # this is an instance of a table with multiple unique nodes, one with 
                        # only one unique-column and the other with many unique-column nodes
                        # so add the name of the column
                        _addUniqueOperation($localClass, $uniqueArray->{'unique-column'}{'name'});
                    } else {
                        # the key is the actual name of the column
                        _addUniqueOperation($localClass, $uniqueKey);
                    }
                } # end foreach in keys
            } # end foreach in array
       } # end else
    } # end if exists
}
1;

###############################################################################

=head1 NAME

Autodia::Handler::Torque.pm - AutoDia handler for Torque xml database schema

=head1 INTRODUCTION

This provides Autodia with the ability to read Torque Database Schema files, allowing you to convert them via the Diagram Export methods to images (using GraphViz and VCG) or html/xml using custom templates or to Dia.

=head1 SYNOPSIS

use Autodia::Handler::Torque;

my $handler = Autodia::Handler::dia->New(\%Config);

$handler->Parse(filename); # where filename includes full or relative path.

=head1 Description

The Torque handler will parse the xml file using XML::Simple and populating the diagram object with class, superclass, and relationships representing tables and relationships.

The Torque handler is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language.

An example Torque database schema is shown here - its actually a rather nice format apart from the Java studlyCaps..


<?xml version="1.0" encoding="ISO-8859-1" standalone="no" ?>

<!DOCTYPE database SYSTEM "http://db.apache.org/torque/dtd/database_3_0_1.dtd">

<database name="INTERPLANETARY">

  <table name="CIVILIZATION">
    <column name="CIV_ID" required="true" autoIncrement="true" primaryKey="true" type="INTEGER"/>
    <column name="NAME" required="true" type="LONGVARCHAR"/>
  </table>

  <table name="CIV_PEOPLE">
    <column name="CIV_ID" required="true" primaryKey="true" type="INTEGER"/>
    <column name="PEOPLE_ID" required="true" primaryKey="true" type="INTEGER"/>

    <foreign-key foreignTable="CIVILIZATION">
        <reference local="CIV_ID" foreign="CIV_ID"/>
    </foreign-key>
    <foreign-key foreignTable="PEOPLE">
        <reference local="PEOPLE_ID" foreign="PEOPLE_ID"/>
    </foreign-key>
  </table>

  <table name="PEOPLE">
    <column name="PEOPLE_ID" required="true" autoIncrement="true" primaryKey="true" type="INTEGER"/>
    <column name="NAME" required="true" size="255" type="VARCHAR"/>
    <column name="SPECIES" type="INTEGER" default="-2"/>
    <column name="PLANET" type="INTEGER" default="-1"/>
  </table>
</database>

=head1 METHODS

=head2 CONSTRUCTION METHOD

use Autodia::Handler::Torque;

my $handler = Autodia::Handler::Torque->New(\%Config);
This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head2 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

=head1 SEE ALSO

Autodia

Torque

Autodia::Handler

=cut
