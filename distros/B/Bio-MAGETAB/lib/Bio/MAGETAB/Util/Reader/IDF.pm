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
# $Id: IDF.pm 380 2013-04-30 09:08:39Z tfrayner $

package Bio::MAGETAB::Util::Reader::IDF;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw(first);

BEGIN { extends 'Bio::MAGETAB::Util::Reader::TagValueFile' };

has 'magetab_object'     => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB::Investigation',
                              required   => 0 );

has 'document_version'   => ( is         => 'rw',
                              isa        => 'Str' );

# Define some standard regexps:
my $BLANK = qr/\A [ ]* \z/xms;

sub BUILD {

    my ( $self, $params ) = @_;

    # Dispatch table to direct each field to the appropriate place in
    # the text_store hashref. First argument is the internal tag used
    # to group the fields into concepts, the second is the
    # Bio::MAGETAB attribute name for the object.
    my $dispatch = {
        qr/Investigation *Title/i
            => sub{ $self->_add_singleton_datum('investigation', 'title',          @_) },
        qr/Date *Of *Experiment/i
            => sub{ $self->_add_singleton_datum('investigation', 'date',           @_) },
        qr/Public *Release *Date/i
            => sub{ $self->_add_singleton_datum('investigation', 'publicReleaseDate', @_) },
        qr/Experiment *Description/i
            => sub{ $self->_add_singleton_datum('investigation', 'description',    @_) },
        qr/SDRF *Files?/i
            => sub{ $self->_add_singleton_data('sdrf', 'uris',   @_) },

        qr/Experimental *Factor *Names?/i
            => sub{ $self->_add_grouped_data('factor', 'name',       @_) },
        qr/Experimental *Factor *Types?/i
            => sub{ $self->_add_grouped_data('factor', 'factorType', @_) },
        qr/Experimental *Factor *(?:Types?)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('factor', 'termSource', @_) },
        qr/Experimental *Factor *(?:Types?)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('factor', 'accession',  @_) },

        qr/Person *Last *Names?/i
            => sub{ $self->_add_grouped_data('person', 'lastName',    @_) },
        qr/Person *First *Names?/i
            => sub{ $self->_add_grouped_data('person', 'firstName',   @_) },
        qr/Person *Mid *Initials?/i
            => sub{ $self->_add_grouped_data('person', 'midInitials', @_) },
        qr/Person *Emails?/i
            => sub{ $self->_add_grouped_data('person', 'email',       @_) },
        qr/Person *Phones?/i
            => sub{ $self->_add_grouped_data('person', 'phone',       @_) },
        qr/Person *Fax(es)?/i
            => sub{ $self->_add_grouped_data('person', 'fax',         @_) },
        qr/Person *Address(es)?/i
            => sub{ $self->_add_grouped_data('person', 'address',     @_) },
        qr/Person *Affiliations?/i
            => sub{ $self->_add_grouped_data('person', 'organization', @_) },
        qr/Person *Roles?/i
            => sub{ $self->_add_grouped_data('person', 'roles',       @_) },
        qr/Person *Roles? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('person', 'termSource',  @_) },
        qr/Person *Roles? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('person', 'accession',  @_) },

        qr/Experimental *Designs?/i
            => sub{ $self->_add_grouped_data('design', 'value',     @_) },
        qr/Experimental *Designs? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('design', 'termSource', @_) },
        qr/Experimental *Designs? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('design', 'accession', @_) },
        qr/Quality *Control *Types?/i
            => sub{ $self->_add_grouped_data('qualitycontrol', 'value',       @_) },
        qr/Quality *Control *(?:Types?)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('qualitycontrol', 'termSource', @_) },
        qr/Quality *Control *(?:Types?)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('qualitycontrol', 'accession', @_) },
        qr/Replicate *Types?/i
            => sub{ $self->_add_grouped_data('replicate',      'value',       @_) },
        qr/Replicate *(?:Types?)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('replicate',      'termSource', @_) },
        qr/Replicate *(?:Types?)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('replicate',      'accession', @_) },
        qr/Normali[sz]ation *Types?/i
            => sub{ $self->_add_grouped_data('normalization',  'value',       @_) },
        qr/Normali[sz]ation *(?:Types?)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('normalization',  'termSource', @_) },
        qr/Normali[sz]ation *(?:Types?)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('normalization',  'accession', @_) },
 
        qr/PubMed *IDs?/i
            => sub{ $self->_add_grouped_data('publication', 'pubMedID',   @_) },
        qr/Publication *DOIs?/i
            => sub{ $self->_add_grouped_data('publication', 'DOI',        @_) },
        qr/Publication *Authors? *Lists?/i
            => sub{ $self->_add_grouped_data('publication', 'authorList', @_) },
        qr/Publication *Titles?/i
            => sub{ $self->_add_grouped_data('publication', 'title',      @_) },
        qr/Publication *Status/i
            => sub{ $self->_add_grouped_data('publication', 'status',     @_) },
        qr/Publication *Status *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('publication', 'termSource', @_) },
        qr/Publication *Status *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('publication', 'accession', @_) },

        qr/Protocol *Names?/i
            => sub{ $self->_add_grouped_data('protocol', 'name',        @_) },
        qr/Protocol *Descriptions?/i
            => sub{ $self->_add_grouped_data('protocol', 'text', @_) },
        qr/Protocol *Parameters?/i
            => sub{ $self->_add_grouped_data('protocol', 'parameters',  @_) },
        qr/Protocol *Hardwares?/i
            => sub{ $self->_add_grouped_data('protocol', 'hardware',    @_) },
        qr/Protocol *Softwares?/i
        => sub{ $self->_add_grouped_data('protocol', 'software',    @_) },
        qr/Protocol *Contacts?/i
            => sub{ $self->_add_grouped_data('protocol', 'contact',     @_) },
        qr/Protocol *Types?/i
            => sub{ $self->_add_grouped_data('protocol', 'protocolType', @_) },
        qr/Protocol *(?:Types?)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('protocol', 'termSource',  @_) },
        qr/Protocol *(?:Types?)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('protocol', 'accession',  @_) },

        qr/Term *Source *Names?/i
            => sub{ $self->_add_grouped_data('termsource', 'name',     @_) },
        qr/Term *Source *Files?/i
            => sub{ $self->_add_grouped_data('termsource', 'uri',      @_) },
        qr/Term *Source *Versions?/i
            => sub{ $self->_add_grouped_data('termsource', 'version',  @_) },

        qr/MAGE-?TAB *Version/i    # New in 1.1; Strictly speaking 1.0 should never appear.
            => sub{ $self->set_document_version($_[0]);
                    croak("Unsupported MAGE-TAB version.") unless( first { $_[0] eq $_ } qw(1.1 1.0) ) },
    };

    $self->set_dispatch_table( $dispatch );

    return;
}

##################
# Public methods #
##################

sub parse {

    my ( $self ) = @_;

    # Parse the IDF file into memory here.
    my $array_of_rows = $self->_read_as_arrayref();

    # Check tags for duplicates, make sure that tags are recognized.
    my $idf_data = $self->_validate_arrayref_tags( $array_of_rows );

    # Populate the IDF object's internal data text_store attribute.
    foreach my $datum ( @$idf_data ) {
        my ( $tag, $values ) = @$datum;
	$self->_dispatch( $tag, @$values );
    }

    # Set our MAGE-TAB version if it's a 1.0 doc (which has no version
    # tag).
    unless ( defined $self->get_document_version() ) {
        $self->set_document_version('1.0');
    }

    # Actually generate the Bio::MAGETAB objects.
    my ( $investigation, $magetab ) = $self->_generate_magetab();

    return wantarray ? ( $investigation, $magetab ) : $investigation;
}

###################
# Private methods #
###################

sub _generate_magetab {

    my ( $self ) = @_;

    my $magetab       = $self->get_builder()->get_magetab();
    my $investigation = $self->_create_investigation();

    return ( $investigation, $magetab );
}

sub _create_sdrfs {

    my ( $self ) = @_;

    my @sdrfs;

    SDRF:
    foreach my $uri ( @{ $self->get_text_store()->{ 'sdrf' }{ 'uris' } } ) {

        # URI is required for all SDRF objects.
        next SDRF unless ( defined $uri
                                && $uri !~ $BLANK );

        my $sdrf = $self->get_builder()->find_or_create_sdrf({
            uri => $uri,
        });
        push @sdrfs, $sdrf;
    }

    return \@sdrfs;
}

sub _create_factors {

    my ( $self ) = @_;

    my @factors;
    FACTOR:
    foreach my $f_data ( @{ $self->get_text_store()->{ 'factor' } } ) {

        # Name is required for all Factor objects.
        next FACTOR unless ( defined $f_data->{'name'}
                                  && $f_data->{'name'} !~ $BLANK );

        my %args = ('name' => $f_data->{'name'} );

        if ( $f_data->{'factorType'} ) {

            my $termsource;
            if ( my $ts = $f_data->{'termSource'} ) {
                $termsource = $self->get_builder()->get_term_source({
                    'name' => $ts,
                });
            }
            
            my $type = $self->get_builder()->find_or_create_controlled_term({
                'category'   => 'ExperimentalFactorCategory',
                'value'      => $f_data->{'factorType'},
                'termSource' => $termsource,
            });

            if ( defined $f_data->{'accession'} && ! defined $type->get_accession() ) {
                $type->set_accession( $f_data->{'accession'} );
                $self->get_builder()->update( $type );
            }

            $args{'factorType'} = $type,
        }

        my $factor = $self->get_builder()->find_or_create_factor( \%args );

	push @factors, $factor;
    }

    return \@factors;
}

sub _create_people {

    my ( $self ) = @_;

    my @people;
    PERSON:
    foreach my $p_data ( @{ $self->get_text_store()->{ 'person' } } ) {

        # Something is required for all Contact objects. MidInitials
        # just doesn't cut it.
        my $id_found;
        foreach my $key ( qw( lastName firstName ) ) {
            $id_found++ if ( defined $p_data->{$key}
                                  && $p_data->{$key} !~ $BLANK );
        }
        next PERSON unless $id_found;

        my $termsource;
        if ( my $ts = $p_data->{'termSource'} ) {
            $termsource = $self->get_builder()->get_term_source({
                'name' => $ts,
            });
        }

        my @roles = map {
            my $role = $self->get_builder()->find_or_create_controlled_term({
                'category'   => 'Roles',
                'value'      => $_,
                'termSource' => $termsource,
            });
            if ( defined $p_data->{'accession'} && ! defined $role->get_accession() ) {
                $role->set_accession( $p_data->{'accession'} );
                $self->get_builder()->update( $role );
            }                
            $role;
        } split /\s*;\s*/, ( $p_data->{'roles'} || q{} );

        my @wanted = grep { $_ !~ /^roles|termSource|accession$/ } keys %{ $p_data };
        my %args   = map { $_ => $p_data->{$_} } @wanted;
        $args{'roles'} = \@roles;

        my $person = $self->get_builder()->find_or_create_contact( \%args );

	push @people, $person;
    }

    return \@people;
}

sub _create_protocols {

    my ( $self ) = @_;

    my @protocols;
    PROTOCOL:
    foreach my $p_data ( @{ $self->get_text_store()->{ 'protocol' } } ) {

        # Name is required for all Protocol objects.
        next PROTOCOL unless ( defined $p_data->{'name'}
                                    && $p_data->{'name'} !~ $BLANK );

        my @wanted = grep { $_ !~ /^parameters|protocolType|termSource|accession$/ } keys %{ $p_data };
        my %args   = map { $_ => $p_data->{$_} } @wanted;

        if ( defined $p_data->{'protocolType'} ) {

            my $termsource;
            if ( my $ts = $p_data->{'termSource'} ) {
                $termsource = $self->get_builder()->get_term_source({
                    'name' => $ts,
                });
            }

            my $type = $self->get_builder()->find_or_create_controlled_term({
                'category'   => 'ProtocolType',
                'value'      => $p_data->{'protocolType'},
                'termSource' => $termsource,
            });

            if ( defined $p_data->{'accession'} && ! defined $type->get_accession() ) {
                $type->set_accession( $p_data->{'accession'} );
                $self->get_builder()->update( $type );
            }

            $args{'protocolType'} = $type;
        }

        my $protocol = $self->get_builder()->find_or_create_protocol( \%args );

        if ( my $parameters = $p_data->{'parameters'} ) {
            foreach my $paramname ( split /\s*;\s*/, $parameters ) {
                $self->get_builder()->find_or_create_protocol_parameter({
                    'name'       => $paramname,
                    'protocol'   => $protocol,
                });
            }
        }

	push @protocols, $protocol;
    }

    return \@protocols;
}

sub _create_publications {

    my ( $self ) = @_;

    my @publications;
    PUBL:
    foreach my $p_data ( @{ $self->get_text_store()->{ 'publication' } } ) {

        # Title is required for all Publication objects.
        next PUBL unless ( defined $p_data->{'title'}
                                && $p_data->{'title'} !~ $BLANK );

        my @wanted = grep { $_ !~ /^status|termSource|accession$/ } keys %{ $p_data };
        my %args   = map { $_ => $p_data->{$_} } @wanted;

        if ( defined $p_data->{'status'} ) {

            my $termsource;
            if ( my $ts = $p_data->{'termSource'} ) {
                $termsource = $self->get_builder()->get_term_source({
                    'name' => $ts,
                });
            }

            my $status = $self->get_builder()->find_or_create_controlled_term({
                'category'   => 'PublicationStatus',
                'value'      => $p_data->{'status'},
                'termSource' => $termsource,
            });

            if ( defined $p_data->{'accession'} && ! defined $status->get_accession() ) {
                $status->set_accession( $p_data->{'accession'} );
                $self->get_builder()->update( $status );
            }

            $args{'status'} = $status;
        }

        my $publication = $self->get_builder()->find_or_create_publication( \%args );

	push @publications, $publication;
    }

    return \@publications;
}

sub _create_investigation {

    my ( $self ) = @_;

    # Term Sources. These must be created first.
    my $term_sources = $self->_create_termsources();

    my $factors      = $self->_create_factors();
    my $people       = $self->_create_people();
    my $protocols    = $self->_create_protocols();
    my $publications = $self->_create_publications();

    my $design_types        = $self->_create_controlled_terms(
        'design',         'ExperimentDesignType',
    );
    my $normalization_types = $self->_create_controlled_terms(
        'normalization',  'NormalizationDescriptionType',
    );
    my $replicate_types     = $self->_create_controlled_terms(
        'replicate',      'ReplicateDescriptionType',
    );
    my $qc_types            = $self->_create_controlled_terms(
        'qualitycontrol', 'QualityControlDescriptionType',
    );

    my $sdrfs = $self->_create_sdrfs();

    my $data = $self->get_text_store()->{'investigation'};
    
    my $investigation;
    if ( $investigation = $self->get_magetab_object() ) {
        while ( my ( $key, $value ) = each %{ $data } ) {
            my $setter = "set_$key";
            $investigation->$setter( $value ) if defined $value;
        }
    }
    else {
        $investigation = $self->get_builder()->find_or_create_investigation({
            %{ $data },
        });
        $self->set_magetab_object( $investigation );
    }

    $investigation->set_contacts            ( $people              ) if @$people;
    $investigation->set_protocols           ( $protocols           ) if @$protocols;
    $investigation->set_publications        ( $publications        ) if @$publications;
    $investigation->set_factors             ( $factors             ) if @$factors;
    $investigation->set_termSources         ( $term_sources        ) if @$term_sources;
    $investigation->set_designTypes         ( $design_types        ) if @$design_types;
    $investigation->set_normalizationTypes  ( $normalization_types ) if @$normalization_types;
    $investigation->set_replicateTypes      ( $replicate_types     ) if @$replicate_types;
    $investigation->set_qualityControlTypes ( $qc_types            ) if @$qc_types;
    $investigation->set_sdrfs               ( $sdrfs               ) if @$sdrfs;

    my $comments = $self->_create_comments();
    $investigation->set_comments( $comments );
    $self->get_builder()->update( $investigation );

    return $investigation;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::IDF - IDF parser class.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Reader::IDF;
 my $parser = Bio::MAGETAB::Util::Reader::IDF->new({
     uri => $idf_filename,
 });
 my $investigation = $parser->parse();

=head1 DESCRIPTION

This class is used to parse IDF files. It can be used on its own, but
more often you will want to use the main Bio::MAGETAB::Util::Reader
class which handles extended parsing options more transparently.

=head1 ATTRIBUTES

See the L<TagValueFile|Bio::MAGETAB::Util::Reader::TagValueFile> class for superclass attributes.

=over 2

=item magetab_object

A Bio::MAGETAB::Investigation object. This can either be set upon
instantiation, or a new object will be created for you. It can be
retrieved at any time using C<get_magetab_object>.

=item document_version

A string representing the MAGE-TAB version used in the parsed
document. This is populated by the parse() method.

=back

=head1 METHODS

=over 2

=item parse

Parse the IDF pointed to by C<$self-E<gt>get_uri()>. Returns the
Bio::MAGETAB::Investigation object updated with the IDF contents.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader::TagValueFile>
L<Bio::MAGETAB::Util::Reader::Tabfile>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Investigation>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
