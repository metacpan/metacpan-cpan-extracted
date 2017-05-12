package Datahub::Factory::TMS::Importer::Index;

# TODO: to datahub-factory-kmska

use Moo;
use Catmandu;
use strict;

use DBI;

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);

has index_commands => (is => 'lazy');

sub _build_index_commands {
    my $self = shift;
    return {
        'Classifications' => [
            'ALTER TABLE `Classifications` CHANGE `ClassificationID` `ClassificationID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Classifications` CHANGE `Classification` `Classification` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Classifications` ADD INDEX ( `ClassificationID` , `Classification` ) ;'
        ],
        'ObjectID' => [
            'ALTER TABLE `ObjContext` CHANGE `Period` `Period` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `ObjContext` ADD INDEX ( `ObjectID` , `Period` ) ;'
        ],
        'vgsrpObjTombstoneD_RO' => [
            'ALTER TABLE `vgsrpObjTombstoneD_RO` ADD INDEX ( `ObjectID` , `ObjectNumber` ) ;'
        ],
        'Dimensions' => [
            'ALTER TABLE `Dimensions` CHANGE `DimItemElemXrefID` `DimItemElemXrefID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;',
            'ALTER TABLE `Dimensions` CHANGE `DimensionTypeID` `DimensionTypeID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Dimensions` CHANGE `PrimaryUnitID` `PrimaryUnitID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Dimensions` ADD INDEX ( `DimItemElemXrefID` , `DimensionTypeID` ,  `PrimaryUnitID` ) ;'
        ],
        'DimensionTypes' => [
            'ALTER TABLE `DimensionTypes` CHANGE `DimensionTypeID` `DimensionTypeID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimensionTypes` ADD INDEX ( `DimensionTypeID` ) ;'
        ],
        'DimensionElements' => [
            'ALTER TABLE `DimensionElements` CHANGE `ElementID` `ElementID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimensionElements` ADD INDEX ( `ElementID` ) ;'
        ],
        'DimensionUnits' => [
            'ALTER TABLE `DimensionUnits` CHANGE `UnitID` `UnitID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimensionUnits` ADD INDEX ( `UnitID` ) ;'
        ],
        'DimItemElemXrefs' => [
            'ALTER TABLE `DimItemElemXrefs` CHANGE `DimItemElemXrefID` `DimItemElemXrefID` INT( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimItemElemXrefs` CHANGE `TableID` `TableID` INT( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimItemElemXrefs` CHANGE `ID` `ID` INT( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimItemElemXrefs` CHANGE `ElementID` `ElementID` INT( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `DimItemElemXrefs` ADD INDEX ( `DimItemElemXrefID` , `TableID` , `ID` , `ElementID` ) ;'
        ],
        'Terms' => [
            'ALTER TABLE `Terms` CHANGE `TermID` `TermID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Terms` CHANGE `TermTypeID` `TermTypeID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `Terms` ADD INDEX ( `TermID` , `TermTypeID` ) ;'
        ],
        'ThesXrefs' => [
            'ALTER TABLE `ThesXrefs` CHANGE `ID` `ID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `ThesXrefs` CHANGE `TermID` `TermID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `ThesXrefs` CHANGE `ThesXrefTypeID` `ThesXrefTypeID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `ThesXrefs` ADD INDEX ( `ID` , `TermID` , `ThesXrefTypeID` ) ;'
        ],
        'ThesXrefTypes' => [
            'ALTER TABLE `ThesXrefTypes` CHANGE `ThesXrefTypeID` `ThesXrefTypeID` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL ;',
            'ALTER TABLE `ThesXrefTypes` ADD INDEX ( `ThesXrefTypeID` ) ;'
        ]
    };
}

sub add_indices {
    my $self = shift;
    my $dbh = DBI->connect(
        data_source => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password
    );
    my $sth;
    while (my ($table, $commands) = each %{$self->index_commands}) {
        foreach my $command (@{$commands}) {
            $sth = $dbh->prepare($command);
            my $rv = $sth->execute();
        }
    }
}

1;