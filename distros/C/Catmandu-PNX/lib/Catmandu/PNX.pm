package Catmandu::PNX;

=encoding utf8

=head1 NAME

Catmandu::PNX - Modules for handling PNX data within the Catmandu framework

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert PNX to JSON --fix myfixes.txt < data/pnx.xml > data/pnx.json

  catmandu convert JSON to PNX --fix myfixes.txt < data/pnx.json > data/pnx.xml

See documentation of modules for more examples.

=head1 DESCRIPTION

Catmandu::PNX contains modules to handle PNX an
XML Schema for Ex Libris' Primo search engine.

=head1 AVAILABLE MODULES

=over

=item L<Catmandu::Exporter::PNX>

Serialize PNX data

=item L<Catmandu::Importer::PNX>

Parse PNX data

=back

=head1 SEE ALSO

This module is based on the L<Catmandu> framework and L<XML::Compile>.
For more information on Catmandu visit: http://librecat.org/Catmandu/
or follow the blog posts at: https://librecatproject.wordpress.com/

=head1 DISCLAIMER

 * I'm not a PNX expert.
 * This project was created as part of the L<Catmandu> project as an example PNX files can be generated from MARC, EAD and others.
 * All the heavy work is done by the excellent L<XML::Compile> package.
 * I invite other developers to contribute to this code.

=head1 BUGS, QUESTIONS HELP

Use the github issue tracker for any bug reports or questions on this module:
https://github.com/LibreCat/Catmandu-PNX/issues

=head1 COPYRIGHT AND LICENSE

Patrick Hochstenbach, 2016 -

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

use Moo;

use XML::Compile;
use XML::Compile::Schema;
use XML::Compile::Util 'pack_type';

our $VERSION = '0.02';

has 'schema'    => (is => 'lazy');
has 'reader'    => (is => 'lazy');
has 'writer'    => (is => 'lazy');

sub _build_schema {
	my $self   = shift;
	my $schema = XML::Compile::Schema->new();

    my @lines = <DATA>;
	my $s = join '' , @lines;

	$schema->importDefinitions($s);

	$schema;
}

sub _build_reader {
	my $self = shift;
	$self->schema->compile(READER => '{}record' );
}

sub _build_writer {
	my $self = shift;
	$self->schema->compile(WRITER => '{}record' );
}

sub parse {
	my ($self,$input) = @_;
	$self->reader->($input);
}

sub to_xml {
	my ($self,$data) = @_;
	my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $xml    = $self->writer->($doc, $data);
	$doc->setDocumentElement($xml);
	$doc->toString(1);
}

1;
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:annotation>
          <xs:documentation xml:lang="en">
              PNX Schema created for Catmandu-PNX
              Patrick.Hochstenbach @ UGent.be
          </xs:documentation>
    </xs:annotation>

    <xs:element name="record" type="recordType">

    </xs:element>

    <xs:complexType name="recordType">
        <xs:all>
            <xs:element name="control" type="controlType" minOccurs="0" maxOccurs="1"/>
            <xs:element name="display" type="displayType" minOccurs="0" maxOccurs="1"/>
            <xs:element name="links"   type="linksType"   minOccurs="0" maxOccurs="1"/>
            <xs:element name="search"  type="searchType"  minOccurs="0" maxOccurs="1"/>
            <xs:element name="facets"  type="facetsType"  minOccurs="0" maxOccurs="1"/>
            <xs:element name="sort"    type="sortType"    minOccurs="0" maxOccurs="1"/>
            <xs:element name="dedup"   type="dedupType"   minOccurs="0" maxOccurs="1"/>
            <xs:element name="frbr"    type="frbrType"    minOccurs="0" maxOccurs="1"/>
            <xs:element name="delivery" type="deliveryType"   minOccurs="0" maxOccurs="1"/>
            <xs:element name="ranking" type="rankingType" minOccurs="0" maxOccurs="1"/>
            <xs:element name="enrichment" type="enrichmentType" minOccurs="0" maxOccurs="1"/>
            <xs:element name="addata"  type="addataType"  minOccurs="0" maxOccurs="1"/>
            <xs:element name="browse"  type="browseType"  minOccurs="0" maxOccurs="1"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="controlType">
        <xs:all>
            <xs:element name="sourceid" type="xs:string" minOccurs="0"/>
            <xs:element name="originalsourceid" type="xs:string" minOccurs="0"/>
            <xs:element name="sourcerecordid" type="xs:string" minOccurs="0"/>
            <xs:element name="addsrcrecordid" type="xs:string"  minOccurs="0"/>
            <xs:element name="recordid" type="xs:string" minOccurs="0"/>
            <xs:element name="sourcetype" type="xs:string" minOccurs="0"/>
            <xs:element name="sourceformat" type="xs:string" minOccurs="0"/>
            <xs:element name="sourcesystem" type="xs:string" minOccurs="0"/>
            <xs:element name="recordtype" type="xs:string" minOccurs="0"/>
            <xs:element name="lastmodified" type="xs:string" minOccurs="0"/>
            <xs:element name="almaid" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="displayType">
        <xs:all>
            <xs:element name="availinstitution" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="availlibrary" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="availpnx" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="contributor" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="coverage" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creationdate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creator" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsinfo" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="description" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="edition" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="format" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="identifier" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="ispartof" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="language" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="oa" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="publisher" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="relation" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="rights" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="source" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="subject" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="title" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="type" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="unititle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="userrank" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="userreview" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="vertitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds01" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds02" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds03" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds04" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds05" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds06" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds07" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds08" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds09" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds10" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds11" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds12" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds13" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds14" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds15" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds16" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds17" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds18" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds19" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds20" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds21" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds22" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds23" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds24" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds25" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds26" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds27" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds28" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds29" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds30" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds31" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds32" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds33" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds34" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds35" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds36" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds37" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds38" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds39" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds40" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds41" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds42" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds43" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds44" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds45" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds46" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds47" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds48" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds49" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lds50" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
        </xs:all>
    </xs:complexType>

    <xs:complexType name="linksType">
        <xs:all>
            <xs:element name="additionallinks" type="xs:string" minOccurs="0"/>
            <xs:element name="backlink" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoabstract" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoextract" type="xs:string" minOccurs="0"/>
            <xs:element name="linktofindingaid" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoholdings" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoholdings_avail" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoholdings_unavail" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoholdings_notexist" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoprice" type="xs:string" minOccurs="0"/>
            <xs:element name="linktorequest" type="xs:string" minOccurs="0"/>
            <xs:element name="linktoreview" type="xs:string" minOccurs="0"/>
            <xs:element name="linktorsrc" type="xs:string" minOccurs="0"/>
            <xs:element name="linktotoc" type="xs:string" minOccurs="0"/>
            <xs:element name="linktouc" type="xs:string" minOccurs="0"/>
            <xs:element name="openurl" type="xs:string" minOccurs="0"/>
            <xs:element name="openurlfulltext" type="xs:string" minOccurs="0"/>
            <xs:element name="openurlservice" type="xs:string" minOccurs="0"/>
            <xs:element name="thumbnail" type="xs:string" minOccurs="0"/>
            <xs:element name="lln01" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln02" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln03" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln04" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln05" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln06" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln07" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln08" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln09" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln10" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln11" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln12" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln13" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln14" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln15" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln16" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln17" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln18" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln19" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln20" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln21" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln22" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln23" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln24" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln25" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln26" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln27" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln28" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln29" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln30" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln31" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln32" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln33" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln34" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln35" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln36" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln37" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln38" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln39" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln40" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln41" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln42" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln43" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln44" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln45" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln46" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln47" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln48" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln49" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lln50" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
        </xs:all>
    </xs:complexType>

    <xs:complexType name="searchType">
        <xs:all>
            <xs:element name="addsrcrecordid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="addtitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="alttitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creationdate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creatorcontrib" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsdept" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsinstrc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsname" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="description" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="enddate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="frbrid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="fulltext" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="general" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="isbn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="issn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="matchid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="orcidid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="pnxtype" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="recordid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="recordtype" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="ressearscope" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="rsrctype" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="scope" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="searchscope" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="sourceid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="startdate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="subject" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="syndetics_fulltext" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="syndetics_toc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="title" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="toc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="usertag" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr01" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr02" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr03" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr04" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr05" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr06" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr07" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr08" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr09" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr10" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr11" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr12" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr13" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr14" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr15" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr16" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr17" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr18" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr19" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr20" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr21" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr22" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr23" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr24" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr25" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr26" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr27" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr28" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr29" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr30" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr31" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr32" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr33" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr34" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr35" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr36" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr37" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr38" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr39" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr40" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr41" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr42" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr43" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr44" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr45" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr46" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr47" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr48" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr49" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lsr50" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
        </xs:all>
    </xs:complexType>

    <xs:complexType name="facetsType">
        <xs:all>
            <xs:element name="classificationlcc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="classificationddc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="classificationudc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="classificationrvk" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="collection" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creationdate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="creatorcontrib" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsdept" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsinstrc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="crsname" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="filesize" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="format" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="genre" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="jtitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="language" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="library" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="prefilter" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="related" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="rsrctype" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="topic" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="toplevel" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc01" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc02" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc03" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc04" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc05" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc06" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc07" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc08" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc09" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc10" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc11" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc12" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc13" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc14" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc15" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc16" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc17" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc18" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc19" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc20" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc21" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc22" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc23" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc24" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc25" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc26" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc27" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc28" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc29" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc30" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc31" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc32" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc33" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc34" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc35" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc36" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc37" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc38" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc39" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc40" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc41" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc42" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc43" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc44" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc45" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc46" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc47" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc48" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc49" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lfc50" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
        </xs:all>
    </xs:complexType>

    <xs:complexType name="sortType">
        <xs:all>
            <xs:element name="author" type="xs:string" minOccurs="0"/>
            <xs:element name="creationdate" type="xs:string" minOccurs="0"/>
            <xs:element name="title" type="xs:string" minOccurs="0"/>
            <xs:element name="lso01" type="xs:string" minOccurs="0"/>
            <xs:element name="lso02" type="xs:string" minOccurs="0"/>
            <xs:element name="lso03" type="xs:string" minOccurs="0"/>
            <xs:element name="lso04" type="xs:string" minOccurs="0"/>
            <xs:element name="lso05" type="xs:string" minOccurs="0"/>
            <xs:element name="lso06" type="xs:string" minOccurs="0"/>
            <xs:element name="lso07" type="xs:string" minOccurs="0"/>
            <xs:element name="lso08" type="xs:string" minOccurs="0"/>
            <xs:element name="lso09" type="xs:string" minOccurs="0"/>
            <xs:element name="lso10" type="xs:string" minOccurs="0"/>
            <xs:element name="lso11" type="xs:string" minOccurs="0"/>
            <xs:element name="lso12" type="xs:string" minOccurs="0"/>
            <xs:element name="lso13" type="xs:string" minOccurs="0"/>
            <xs:element name="lso14" type="xs:string" minOccurs="0"/>
            <xs:element name="lso15" type="xs:string" minOccurs="0"/>
            <xs:element name="lso16" type="xs:string" minOccurs="0"/>
            <xs:element name="lso17" type="xs:string" minOccurs="0"/>
            <xs:element name="lso18" type="xs:string" minOccurs="0"/>
            <xs:element name="lso19" type="xs:string" minOccurs="0"/>
            <xs:element name="lso20" type="xs:string" minOccurs="0"/>
            <xs:element name="lso21" type="xs:string" minOccurs="0"/>
            <xs:element name="lso22" type="xs:string" minOccurs="0"/>
            <xs:element name="lso23" type="xs:string" minOccurs="0"/>
            <xs:element name="lso24" type="xs:string" minOccurs="0"/>
            <xs:element name="lso25" type="xs:string" minOccurs="0"/>
            <xs:element name="lso26" type="xs:string" minOccurs="0"/>
            <xs:element name="lso27" type="xs:string" minOccurs="0"/>
            <xs:element name="lso28" type="xs:string" minOccurs="0"/>
            <xs:element name="lso29" type="xs:string" minOccurs="0"/>
            <xs:element name="lso30" type="xs:string" minOccurs="0"/>
            <xs:element name="lso31" type="xs:string" minOccurs="0"/>
            <xs:element name="lso32" type="xs:string" minOccurs="0"/>
            <xs:element name="lso33" type="xs:string" minOccurs="0"/>
            <xs:element name="lso34" type="xs:string" minOccurs="0"/>
            <xs:element name="lso35" type="xs:string" minOccurs="0"/>
            <xs:element name="lso36" type="xs:string" minOccurs="0"/>
            <xs:element name="lso37" type="xs:string" minOccurs="0"/>
            <xs:element name="lso38" type="xs:string" minOccurs="0"/>
            <xs:element name="lso39" type="xs:string" minOccurs="0"/>
            <xs:element name="lso40" type="xs:string" minOccurs="0"/>
            <xs:element name="lso41" type="xs:string" minOccurs="0"/>
            <xs:element name="lso42" type="xs:string" minOccurs="0"/>
            <xs:element name="lso43" type="xs:string" minOccurs="0"/>
            <xs:element name="lso44" type="xs:string" minOccurs="0"/>
            <xs:element name="lso45" type="xs:string" minOccurs="0"/>
            <xs:element name="lso46" type="xs:string" minOccurs="0"/>
            <xs:element name="lso47" type="xs:string" minOccurs="0"/>
            <xs:element name="lso48" type="xs:string" minOccurs="0"/>
            <xs:element name="lso49" type="xs:string" minOccurs="0"/>
            <xs:element name="lso50" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="dedupType">
        <xs:all>
            <xs:element name="t" type="xs:string" minOccurs="0"/>
            <xs:element name="c1" type="xs:string" minOccurs="0"/>
            <xs:element name="c2" type="xs:string" minOccurs="0"/>
            <xs:element name="c3" type="xs:string" minOccurs="0"/>
            <xs:element name="c4" type="xs:string" minOccurs="0"/>
            <xs:element name="c5" type="xs:string" minOccurs="0"/>
            <xs:element name="f1" type="xs:string" minOccurs="0"/>
            <xs:element name="f1" type="xs:string" minOccurs="0"/>
            <xs:element name="f2" type="xs:string" minOccurs="0"/>
            <xs:element name="f3" type="xs:string" minOccurs="0"/>
            <xs:element name="f4" type="xs:string" minOccurs="0"/>
            <xs:element name="f5" type="xs:string" minOccurs="0"/>
            <xs:element name="f6" type="xs:string" minOccurs="0"/>
            <xs:element name="f7" type="xs:string" minOccurs="0"/>
            <xs:element name="f8" type="xs:string" minOccurs="0"/>
            <xs:element name="f9" type="xs:string" minOccurs="0"/>
            <xs:element name="f10" type="xs:string" minOccurs="0"/>
            <xs:element name="f11" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="frbrType">
        <xs:all>
            <xs:element name="t" type="xs:string" minOccurs="0"/>
            <xs:element name="k1" type="xs:string" minOccurs="0"/>
            <xs:element name="k2" type="xs:string" minOccurs="0"/>
            <xs:element name="k3" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="deliveryType">
        <xs:all>
            <xs:element name="institution" type="xs:string" minOccurs="0"/>
            <xs:element name="delcategory" type="xs:string" minOccurs="0"/>
            <xs:element name="fulltext" type="xs:string" minOccurs="0"/>
            <xs:element name="resdelscope" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="rankingType">
        <xs:all>
            <xs:element name="booster1" type="xs:string" minOccurs="0"/>
            <xs:element name="booster2" type="xs:string" minOccurs="0"/>
            <xs:element name="pcg_type" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="enrichmentType">
        <xs:all>
            <xs:element name="abstract" type="xs:string" minOccurs="0"/>
            <xs:element name="availability" type="xs:string" minOccurs="0"/>
            <xs:element name="classificationlcc" type="xs:string" minOccurs="0"/>
            <xs:element name="classificationddc" type="xs:string" minOccurs="0"/>
            <xs:element name="classificationudc" type="xs:string" minOccurs="0"/>
            <xs:element name="classificationrvk" type="xs:string" minOccurs="0"/>
            <xs:element name="fulltext" type="xs:string" minOccurs="0"/>
            <xs:element name="rankdatefirstcopy" type="xs:string" minOccurs="0"/>
            <xs:element name="ranknocopies" type="xs:string" minOccurs="0"/>
            <xs:element name="ranknoloans" type="xs:string" minOccurs="0"/>
            <xs:element name="rankparentchild" type="xs:string" minOccurs="0"/>
            <xs:element name="review" type="xs:string" minOccurs="0"/>
            <xs:element name="toc" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn01" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn02" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn03" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn04" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn05" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn06" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn07" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn08" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn09" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn10" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn11" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn12" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn13" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn14" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn15" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn16" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn17" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn18" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn19" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn20" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn21" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn22" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn23" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn24" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn25" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn26" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn27" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn28" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn29" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn30" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn31" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn32" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn33" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn34" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn35" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn36" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn37" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn38" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn39" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn40" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn41" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn42" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn43" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn44" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn45" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn46" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn47" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn48" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn49" type="xs:string" minOccurs="0"/>
            <xs:element name="lrn50" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>

    <xs:complexType name="addataType">
        <xs:all>
            <xs:element name="abstract" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="addau" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="adddate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="dat" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="addtitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="artnum" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="atitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="au" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="aufirst" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="auinit1" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="auinit" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="aulast" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="auinitm" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="ausuffix" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="btitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="title" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="cop" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="coden" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="aucorp" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="co" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="cc" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="date" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="degree" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="advisor" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="doi" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="eissn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="epage" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="genre" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="inst" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="isbn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="issn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="issue" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="jtitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="format" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="mis1" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="mis2" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="mis3" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="notes" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="objectid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="oclcid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="oa" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="pages" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="part" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="pmid" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="pub" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="quarter" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="risdate" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="ristype" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="ssn" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="seriesau" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="seriestitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="stitle" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="sici" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="spage" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="url" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="volume" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad01" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad02" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad03" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad04" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad05" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad06" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad07" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad08" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad09" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad10" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad11" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad12" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad13" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad14" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad15" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad16" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad17" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad18" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad19" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad20" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad21" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad22" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad23" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad24" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
            <xs:element name="lad25" type="xs:string" minOccurs="0" maxOccurs="unbounded" />
        </xs:all>
    </xs:complexType>

    <xs:complexType name="browseType">
        <xs:all>
            <xs:element name="institution" type="xs:string" minOccurs="0"/>
            <xs:element name="author" type="xs:string" minOccurs="0"/>
            <xs:element name="title" type="xs:string" minOccurs="0"/>
            <xs:element name="subject" type="xs:string" minOccurs="0"/>
            <xs:element name="callnumber" type="xs:string" minOccurs="0"/>
        </xs:all>
    </xs:complexType>
</xs:schema>
