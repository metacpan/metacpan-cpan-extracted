# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: Persistence.pm 361 2011-04-18 20:01:51Z tfrayner $

package Bio::MAGETAB::Util::Persistence;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Tangram;
use DBI;

use MooseX::Types::Moose qw( Str HashRef ArrayRef );

# Uncomment these to print the SQL statements used to STDOUT.
#$Tangram::TRACE = \*STDOUT;
#$Tangram::DEBUG_LEVEL = 1;

sub class_config {

    my ( $class ) = @_;

    # This is where the magic happens. This needs to be kept synchronised
    # with any changes made to the core MAGETAB model.
    my $hashref = {

    classes => [

        'Bio::MAGETAB::ArrayDesign' => {
            bases  => [ 'Bio::MAGETAB::DatabaseEntry' ],
            fields => {
                string => { name             => {},
                            version          => {},
                            provider         => {},
                            printingProtocol => { sql => 'text default NULL' },
                            uri              => {}, },

                ref    => [ qw( technologyType
                                surfaceType
                                substrateType
                                sequencePolymerType )],

                array  => { designElements => 'Bio::MAGETAB::DesignElement', },
                iarray => { comments => { class  => 'Bio::MAGETAB::Comment',
                                          aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::Assay' => {
            bases  => [ 'Bio::MAGETAB::Event' ],
            fields => {
                ref => [ qw( arrayDesign
                             technologyType ) ],
            },
        },

        'Bio::MAGETAB::BaseClass' => {
            abstract => 1,
            fields   => {
                string => [ qw( authority namespace ) ],
            },
        },

        'Bio::MAGETAB::CompositeElement' => {
            bases  => [ 'Bio::MAGETAB::DesignElement' ],
            fields => {
                string => [ qw( name ) ],
                array  => { databaseEntries => 'Bio::MAGETAB::DatabaseEntry', },
                iarray => { comments => { class  => 'Bio::MAGETAB::Comment',
                                          aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::Comment' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( name
                                value ) ],
            },
        },

        'Bio::MAGETAB::Contact' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => { firstName    => {},
                            lastName     => {},
                            midInitials  => {},
                            email        => {},
                            organization => {},
                            phone        => {},
                            fax          => {},
                            address      => { sql => 'varchar(511) default NULL' }, },
                array  => { roles    => 'Bio::MAGETAB::ControlledTerm' },
                iarray => { comments => { class  => 'Bio::MAGETAB::Comment',
                                          aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::ControlledTerm' => {
            bases  => [ 'Bio::MAGETAB::DatabaseEntry' ],
            fields => {
                string => [ qw( category
                                value ) ],
            },
        },

        'Bio::MAGETAB::Data' => {
            abstract => 1,
            bases    => [ 'Bio::MAGETAB::Node' ],
            fields   => {
                string => [ qw( uri ) ],
                ref    => [ qw( dataType ) ],
            },
        },

        'Bio::MAGETAB::DataAcquisition' => {
            bases => [ 'Bio::MAGETAB::Event' ],
        },

        'Bio::MAGETAB::DatabaseEntry' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( accession ) ],
                ref    => [ qw( termSource ) ],
            },
        },

        'Bio::MAGETAB::DataFile' => {
            bases  => [ 'Bio::MAGETAB::Data' ],
            fields => {
                ref => [ qw( format ) ],
            },
        },
        
        'Bio::MAGETAB::DataMatrix' => {
            bases  => [ 'Bio::MAGETAB::Data' ],
            fields => {
                string => [ qw( rowIdentifierType ) ],
                iarray => { matrixColumns => { class  => 'Bio::MAGETAB::MatrixColumn',
                                               aggreg => 1 },
                            matrixRows    => { class  => 'Bio::MAGETAB::MatrixRow',
                                               aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::DesignElement' => {
            abstract => 1,
            bases    => [ 'Bio::MAGETAB::BaseClass' ],
            fields   => {
                string => [ qw( chromosome ) ],
                int    => [ qw( startPosition
                                endPosition ) ],
            },
        },

        'Bio::MAGETAB::Edge' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                ref   => [ qw( inputNode
                               outputNode ) ],
                array => { protocolApplications => 'Bio::MAGETAB::ProtocolApplication' },
            },
        },

        'Bio::MAGETAB::Event' => {
            abstract => 1,
            bases    => [ 'Bio::MAGETAB::Node' ],
            fields   => {
                string => [ qw( name ) ],
            },
        },

        'Bio::MAGETAB::Extract' => {
            bases => [ 'Bio::MAGETAB::Material' ],
            table => 'Bio_MAGETAB_Material',
        },

        'Bio::MAGETAB::Factor' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( name ) ],
                ref    => [ qw( factorType ) ],
            },
        },

        'Bio::MAGETAB::FactorValue' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {

                # N.B. measurement better as iref (which is not fully implemented yet).
                ref  => [ qw( term
                              measurement
                              factor ) ],
            },
        },

        'Bio::MAGETAB::Feature' => {
            bases  => [ 'Bio::MAGETAB::DesignElement' ],
            fields => {

                # N.B. column is a reserved word, we use col as an
                # abbreviation (and blockCol for consistency).
                int => [ qw( blockCol
                             blockRow
                             col
                             row ) ],
                ref => [ qw( reporter ) ],
            },
        },

        'Bio::MAGETAB::Investigation' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => { title             => {},
                            description       => { sql => 'text default NULL'},
                            date              => {},
                            publicReleaseDate => {}, },
                array  => { contacts            => 'Bio::MAGETAB::Contact',
                            protocols           => 'Bio::MAGETAB::Protocol',
                            publications        => 'Bio::MAGETAB::Publication',
                            termSources         => 'Bio::MAGETAB::TermSource',
                            designTypes         => 'Bio::MAGETAB::ControlledTerm',
                            normalizationTypes  => 'Bio::MAGETAB::ControlledTerm',
                            replicateTypes      => 'Bio::MAGETAB::ControlledTerm',
                            qualityControlTypes => 'Bio::MAGETAB::ControlledTerm', },
                iarray => { comments => { class  => 'Bio::MAGETAB::Comment',
                                          aggreg => 1 },
                            factors  => { class  => 'Bio::MAGETAB::Factor',
                                          aggreg => 1 },
                            sdrfs    => { class  => 'Bio::MAGETAB::SDRF',
                                          aggreg => 1 }, },
            },
        },
        
        'Bio::MAGETAB::LabeledExtract' => {
            bases   => [ 'Bio::MAGETAB::Material' ],
            fields  => {
                ref => [ qw( label ) ],
            },
        },

        'Bio::MAGETAB::Material' => {
            abstract => 1,
            bases    => [ 'Bio::MAGETAB::Node' ],
            fields   => {
                string => [ qw( name description ) ],
                ref    => [ qw( materialType ) ],
                array  => { characteristics => 'Bio::MAGETAB::ControlledTerm' },
                iarray => { measurements => { class  => 'Bio::MAGETAB::Measurement',
                                              aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::MatrixColumn' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                int   => [ qw( columnNumber ) ],
                ref   => [ qw( quantitationType ) ],
                array => { referencedNodes => 'Bio::MAGETAB::Node' },
            },
        },

        'Bio::MAGETAB::MatrixRow' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                int => [ qw( rowNumber ) ],
                ref => [ qw( designElement ) ],
            },
        },

        'Bio::MAGETAB::Measurement' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( measurementType
                                value
                                minValue
                                maxValue ) ],
                ref    => [ qw( unit ) ],
            },
        },

        'Bio::MAGETAB::Node' => {
            abstract => 1,
            bases    => [ 'Bio::MAGETAB::BaseClass' ],
            table    => 'Bio_MAGETAB_BaseClass',
            fields   => {
                array  => { sdrfRows    => 'Bio::MAGETAB::SDRFRow', },
                iarray => { inputEdges  => { class  => 'Bio::MAGETAB::Edge',
                                             aggreg => 1 },
                            outputEdges => { class  => 'Bio::MAGETAB::Edge',
                                             aggreg => 1 },
                            comments    => { class  => 'Bio::MAGETAB::Comment',
                                             aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::Normalization' => {
            bases => [ 'Bio::MAGETAB::Event' ],
            table => 'Bio_MAGETAB_Event',
        },

        'Bio::MAGETAB::ParameterValue' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {

                # N.B. measurement better as iref (which is not fully implemented yet).
                ref    => [ qw( parameter measurement term ) ],
                iarray => { comments => { class  => 'Bio::MAGETAB::Comment',
                                          aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::Protocol' => {
            bases  => [ 'Bio::MAGETAB::DatabaseEntry' ],
            fields => {
                string => { name     => {},
                            text     => { sql => 'text default NULL' },
                            software => {},
                            hardware => {},
                            contact  => {}, },
                ref    => [ qw( protocolType ) ],
            },
        },

        'Bio::MAGETAB::ProtocolApplication' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( date ) ],
                ref    => [ qw( protocol ) ],
                array  => { performers => 'Bio::MAGETAB::Contact' },
                iarray => { comments        => { class  => 'Bio::MAGETAB::Comment',
                                                 aggreg => 1 },
                            parameterValues => { class  => 'Bio::MAGETAB::ParameterValue',
                                                 aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::ProtocolParameter' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( name ) ],
                ref    => [ qw( protocol ) ],
            },
        },

        'Bio::MAGETAB::Publication' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => { title      => { sql => 'varchar(511) default NULL' },
                            authorList => { sql => 'varchar(511) default NULL' },
                            pubMedID   => {},
                            DOI        => {}, },
                ref    => [ qw( status ) ],
            },
        },

        'Bio::MAGETAB::Reporter' => {
            bases  => [ 'Bio::MAGETAB::DesignElement' ],
            fields => {
                string => [ qw( name sequence ) ],
                ref    => [ qw( controlType ) ],
                array  => { compositeElements => 'Bio::MAGETAB::CompositeElement',
                            databaseEntries   => 'Bio::MAGETAB::DatabaseEntry',
                            groups            => 'Bio::MAGETAB::ControlledTerm', },
            },
        },

        'Bio::MAGETAB::SDRF' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( uri ) ],
                iarray => { sdrfRows => { class  => 'Bio::MAGETAB::SDRFRow',
                                          aggreg => 1 }, },
            },
        },

        'Bio::MAGETAB::SDRFRow' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                int   => [ qw( rowNumber ) ],
                array => { nodes        => 'Bio::MAGETAB::Node',
                           factorValues => 'Bio::MAGETAB::FactorValue', },
                ref   => [ qw( channel ) ],
            },
        },

        'Bio::MAGETAB::Sample' => {
            bases => [ 'Bio::MAGETAB::Material' ],
            table => 'Bio_MAGETAB_Material',
        },

        'Bio::MAGETAB::Source' => {
            bases  => [ 'Bio::MAGETAB::Material' ],
            table  => 'Bio_MAGETAB_Material',
            fields => {
                array  => { providers => 'Bio::MAGETAB::Contact' },
            },
        },

        'Bio::MAGETAB::TermSource' => {
            bases  => [ 'Bio::MAGETAB::BaseClass' ],
            fields => {
                string => [ qw( name
                                uri
                                version ) ],
            },
        },
    ],

    # Instantiation of persistent objects in the database needs to
    # circumvent the Moose type constraints during any
    # Tangram::Storage->select( $remote, $filter ) calls. This just
    # returns a blessed hashref; the final objects still obey the
    # original constraints, however.
    make_object => sub { my $class = shift; return bless {}, $class },

    };
}

has 'config'   => ( is       => 'rw',
                    isa      => HashRef,
                    required => 1,
                    default  => \&class_config, );

# We delegate quite a lot to the associated Tangram::Storage
# instance. We could delegate even more, although tests should then be
# written to ensure the delegated calls are functioning correctly.
has 'store'    => ( is       => 'rw',
                    isa      => 'Tangram::Storage',
                    handles  => [qw( insert
                                     select
                                     update
                                     erase
                                     id
                                     count
                                     sum
                                     cursor
                                     remote )] );

has 'dbparams' => ( is         => 'ro',
                    isa        => ArrayRef,
                    required   => 1,
                    auto_deref => 1, );

sub BUILD {

    my ( $self, $params ) = @_;

    unless ( defined $params->{ 'dbparams' }[0] ) {
        croak("Error: Database DSN must be specified.\n");
    }
}

sub deploy {

    my ( $self ) = @_;

    my $dbh = DBI->connect( $self->get_dbparams() );

    Tangram::Relational->deploy( $self->get_schema(), $dbh );

    $dbh->disconnect();

    return;
}

sub get_schema {

    my ( $self ) = @_;

    return Tangram::Relational->schema( $self->get_config() );
}

sub connect {

    my ( $self ) = @_;

    my $store = Tangram::Relational->connect( $self->get_schema(), $self->get_dbparams() );

    $self->set_store( $store );

    return;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Persistence - A Tangram-based object persistence
class for MAGE-TAB.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Persistence;
 my $db = Bio::MAGETAB::Util::Persistence->new({
    dbparams       => [ "dbi:mysql:$dbname", $user, $pass ],
 });

 $db->deploy();
 $db->connect();
 $db->insert( $magetab_object );

=head1 DESCRIPTION

This class provides an object persistence mechanism for storing
MAGE-TAB objects in a relational database. The class is, in effect,
just a thin wrapper around a Tangram::Storage instance which
implements most of the database interaction methods. The class has
been used successfully with both MySQL and SQLite database backends,
and should in theory be usable with any database engine supported by
the Tangram modules.

=head1 ATTRIBUTES

=over 2

=item dbparams

A reference to an array containing database connection
parameters. This array is passed directly to C<DBI-E<gt>connect()>.

=item config

The Tangram schema definition used to create the database. This
attribute is read-only.

=item store

The underlying Tangram::Storage object used for most of the
interaction with the database.

=back

=head1 METHODS

=over 2

=item deploy

Connect to the database and deploy the schema. This only needs to be
done once to set up the database.

=item connect

Connect to the database. This must be done before using any of the
following methods.

=item get_schema

Returns the Tangram::Schema object created using the config attribute.

=item class_config

A class method which returns the config hash reference used to create
the Tangram::Schema object.

=item insert

=item select

=item update

=item erase

=item id

=item count

=item sum

=item cursor

=item remote

All these methods are delegated directly to the Tangram::Storage
object created by the C<connect> method, and contained within the
Persistence object. Please see the Tangram documentation for more
information on these methods.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::DBLoader>
L<http://tangram.utsl.gen.nz/>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
