-- 
-- KMSKA Optimizations to the MySQL database
--
-- These optimisations are geared towards the KMSKA Catmandu Fix as part of the
-- Arthub platform. These queries will add a set of indices to the MySQL tables,
-- and a set of views to ease up querying the data.
--
-- You will need to import these SQL file before attempting to run the 
-- Datahub::Factory::Arthub.
--

-- 
-- INDEXES

-- Classifications

ALTER TABLE `Classifications` CHANGE `ClassificationID` `ClassificationID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Classifications` CHANGE `Classification` `Classification` VARCHAR( 255 ) NULL DEFAULT NULL ;
ALTER TABLE `Classifications` ADD INDEX ( `ClassificationID` , `Classification` );

-- ObjContext (ObjectID)

ALTER TABLE `ObjContext` CHANGE `Period` `Period` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `ObjContext` ADD INDEX ( `ObjectID` , `Period` );

-- Objects

ALTER TABLE `Objects` ADD INDEX ( `ObjectID` , `ObjectNumber` );

-- Dimensions

ALTER TABLE `Dimensions` CHANGE `DimItemElemXrefID` `DimItemElemXrefID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Dimensions` CHANGE `DimensionTypeID` `DimensionTypeID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Dimensions` CHANGE `PrimaryUnitID` `PrimaryUnitID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Dimensions` ADD INDEX ( `DimItemElemXrefID` , `DimensionTypeID` ,  `PrimaryUnitID`);

-- DimensionTypes

ALTER TABLE `DimensionTypes` CHANGE `DimensionTypeID` `DimensionTypeID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimensionTypes` ADD INDEX ( `DimensionTypeID` );

-- DimensionElements

ALTER TABLE `DimensionElements` CHANGE `ElementID` `ElementID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimensionElements` ADD INDEX ( `ElementID` );

-- DimensionUnits

ALTER TABLE `DimensionUnits` CHANGE `UnitID` `UnitID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimensionUnits` ADD INDEX ( `UnitID` );

-- DimItemElemXrefs

ALTER TABLE `DimItemElemXrefs` CHANGE `DimItemElemXrefID` `DimItemElemXrefID` INT( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimItemElemXrefs` CHANGE `TableID` `TableID` INT( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimItemElemXrefs` CHANGE `ID` `ID` INT( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimItemElemXrefs` CHANGE `ElementID` `ElementID` INT( 255 ) NULL DEFAULT NULL;
ALTER TABLE `DimItemElemXrefs` ADD INDEX ( `DimItemElemXrefID` , `TableID` , `ID` , `ElementID` );

-- Terms

ALTER TABLE `Terms` CHANGE `TermID` `TermID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Terms` CHANGE `TermTypeID` `TermTypeID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `Terms` ADD INDEX ( `TermID` , `TermTypeID` );

-- ThesXrefs

ALTER TABLE `ThesXrefs` CHANGE `ID` `ID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `ThesXrefs` CHANGE `TermID` `TermID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `ThesXrefs` CHANGE `ThesXrefTypeID` `ThesXrefTypeID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `ThesXrefs` ADD INDEX ( `ID` , `TermID` , `ThesXrefTypeID` );

-- ThesXrefTypes

ALTER TABLE `ThesXrefTypes` CHANGE `ThesXrefTypeID` `ThesXrefTypeID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `ThesXrefTypes` ADD INDEX ( `ThesXrefTypeID` );

-- UserFieldXrefs

ALTER TABLE `UserFieldXrefs` CHANGE `UserFieldID` `UserFieldID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `UserFieldXrefs` CHANGE `ID` `ID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `UserFieldXrefs` CHANGE `ContextID` `ContextID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `UserFieldXrefs` CHANGE `LoginID` `LoginID` VARCHAR( 255 ) NULL DEFAULT NULL;
ALTER TABLE `UserFieldXrefs` ADD INDEX ( `UserFieldID`, `ID`, `ContextID`, `LoginID` );

--
-- VIEWS

-- VIEW Constituents 

CREATE OR REPLACE VIEW vconstituents AS
SELECT ConstituentID AS _id,
    AlphaSort,
    DisplayName,
    BeginDate,
    EndDate,
    BeginDateISO,
    EndDateISO
FROM Constituents;

-- VIEW Classifications

CREATE OR REPLACE VIEW vclassifications AS
SELECT ClassificationID as _id,
    Classification as term 
FROM Classifications;

-- VIEW Periods

CREATE OR REPLACE VIEW vperiods AS
SELECT ObjectID as _id,
    Period as term 
FROM ObjContext;

-- VIEW Dimensions

CREATE OR REPLACE VIEW vdimensions AS
SELECT o.ObjectID as objectid, 
    d.Dimension as dimension,
    t.DimensionType as type,
    e.Element as element,
    u.UnitName as unit
FROM CITvgsrpObjTombstoneD_RO o
LEFT JOIN
    DimItemElemXrefs x ON x.ID = o.ObjectID
INNER JOIN
    Dimensions d ON d.DimItemElemXrefID = x.DimItemElemXrefID
INNER JOIN
    DimensionUnits u ON u.UnitID = d.PrimaryUnitID
INNER JOIN
    DimensionTypes t ON t.DimensionTypeID = d.DimensionTypeID
INNER JOIN
    DimensionElements e ON e.ElementID = x.ElementID
WHERE
    x.TableID = '108'
AND
    x.ElementID = '3';

-- VIEW Subjects

CREATE OR REPLACE VIEW vsubjects AS
SELECT o.ObjectID as objectid,
    t.Term as subject
FROM Terms t, 
    CITvgsrpObjTombstoneD_RO o,
    ThesXrefs x,
    ThesXrefTypes y
WHERE
    x.TermID = t.TermID AND
    x.ID = o.ObjectID AND
    x.ThesXrefTypeID = y.ThesXrefTypeID AND
    y.ThesXrefTypeID = 30;

-- VIEW Data PIDS

CREATE OR REPLACE VIEW vdatapids AS
SELECT o.ObjectNumber as _id, 
    ref.ID, 
    ref.fieldValue as dataPid
FROM UserFieldXrefs ref
INNER JOIN 
    CITvgsrpObjTombstoneD_RO o ON o.ObjectID = ref.ID
WHERE userFieldID = '44';

-- VIEW Work PIDS

CREATE OR REPLACE VIEW vworkpids AS
SELECT o.ObjectNumber as _id, 
    ref.ID, 
    ref.fieldValue as workPid
FROM UserFieldXrefs ref
INNER JOIN 
    CITvgsrpObjTombstoneD_RO o ON o.ObjectID = ref.ID
WHERE userFieldID = '46';

-- VIEW Representation PIDS

CREATE OR REPLACE VIEW vrepresentationpids AS
SELECT o.ObjectNumber as _id, 
    ref.ID, 
    ref.fieldValue as representationPid
FROM UserFieldXrefs ref
INNER JOIN 
    CITvgsrpObjTombstoneD_RO o ON o.ObjectID = ref.ID
WHERE userFieldID = '48';


