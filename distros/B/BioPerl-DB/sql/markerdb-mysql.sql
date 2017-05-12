CREATE TABLE map_study (
    map_study_id        integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    map_study_name      varchar(64) not null,
    map_type_id	        integer(11) not null,
    species_id          integer(11) not null,
    description         text not null,
    evidence_id         integer(11)
);

CREATE TABLE map_type (
    map_type_id	        integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    map_type	        varchar(64) not null,
    map_units	        varchar(12) not null
);

CREATE TABLE strain (
    strain_id	        integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    species_id	        integer(11) not null,
    common_name	        varchar(64)
);

CREATE TABLE species (
    species_id	        integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    full_name	        varchar(64) not null,
    common_name	        varchar(64) not null
);

-- constraint: only two strains should be associated with a single map study!
-- (at least for terrestrial organisms)
CREATE TABLE strain_to_map_study (
    strain_id	        integer(11) not null,
    map_study_id	integer(11) not null,
    UNIQUE          (strain_id,map_study_id)
);

CREATE TABLE map (
    map_id 	        integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    map_study_id        integer(11) not null,
    map_name 	        varchar(32) not null,
    linkage_group       varchar(32), -- ????  or chromosome?
    UNIQUE          (map_study_id,map_name)
);

-- This is essential the locus table, in which markers are assigned to maps
-- with a position.  To accomodate QTLs, position may be a range.
-- There is no constraint that a single marker must map to a single position
-- on a map or a map study.
-- Unfortunately, markers sometimes do map to several places on the same map!
CREATE TABLE map_position (
    map_position_id     integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    marker_id	        integer(11) not null,
    map_id              integer(11) not null,
    position_start      float(8,4)  not null, -- unresolved question: what about markers that
    position_stop       float(8,4),           -- are assigned to chromosome but not to positions?
    KEY                 i_marker_map (marker_id,map_id),
    KEY                 i_position   (map_id,position_start,position_stop)	
);

CREATE TABLE marker (
    marker_id	       integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    marker_table       varchar(32),
    evidence_id        integer(11)
);

CREATE TABLE marker_to_dna (
    marker_id           integer(11) not null,
    dna_id              integer(11) not null, -- this is the Ensembl dna.id key
    KEY i_marker_dna (marker_id,dna_id)
);

CREATE TABLE marker_rflp (
    marker_id           integer(11) not null PRIMARY KEY, 
    enzyme_id           integer(11) not null
);

CREATE TABLE marker_rapd (
    marker_id           integer(11) not null PRIMARY KEY, 
    oligo_id            integer(11) not null
);

CREATE TABLE marker_microsatellite (
    marker_id           integer(11) not null PRIMARY KEY, 
    oligo1_id           integer(11) not null,
    oligo2_id           integer(11) not null,
    flanking_gc_percent float(8,4),
    length_low          integer(6),
    length_high         integer(6),
    motif               varchar(128) not null
);

CREATE TABLE marker_sts (
    marker_id           integer(11) not null PRIMARY KEY, 
    oligo1_id           integer(11) not null,
    oligo2_id           integer(11) not null
);

CREATE TABLE marker_morphological (
    marker_id           integer(11) not null PRIMARY KEY,
    trait_id            integer(11) not null    -- coming from the Trait Ontology
);

CREATE TABLE marker_aflp (
    marker_id           integer(11) not null PRIMARY KEY, 
    oligo1_id           integer(11) not null,
    oligo2_id           integer(11) not null,
    cycle_count         integer(11),  -- same as "amplification" in RiceGenes
    molecular_weight    float(8,4) 
);

CREATE TABLE marker_isozyme (
    marker_id           integer(11) not null PRIMARY KEY, 
    go_id               integer(11) not null, -- from the Gene Ontology (tm)
    molecular_weight    float(8,4) 
);

create table marker_alias (
    marker_id           integer(11) not null,
    alias		varchar(64) not null,
    evidence_id         integer(11) not null,
    UNIQUE          (marker_id,alias)
);

CREATE TABLE enzyme (
    enzyme_id           integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    enzyme_name         varchar(64) not null
);

CREATE TABLE next_number (
    table_name          varchar(64) not null PRIMARY KEY,
    next_number         integer(11) not null
);

------------------------ Marker Equivalence Table ---------------------
CREATE TABLE marker_to_marker_group (
    marker_group_id     integer(11) not null,
    marker_id           integer(11) not null,
    UNIQUE          (marker_group_id,marker_id)
);

CREATE TABLE marker_group (
    marker_group_id     integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    evidence_id         integer(11) not null
    
);

------------------------ Alleles and Polymorphisms ---------------------
-- some technologies like RAPDs only tell us when two individuals
-- have the same or different phenotypes, so we record a boolean
CREATE TABLE marker_polymorphic (
   marker_id             integer(11) not null,
   strain1_id            integer(11) not null,
   strain2_id            integer(11) not null,
   is_polymorphic        tinyint,
   UNIQUE            (marker_id,strain1_id,strain2_id)
);

-- microsatellites, isozymes and morphological markers have values
-- that allow us to make associative inferences.  
CREATE TABLE microsatellite_allele (
   marker_id             integer(11) not null,
   strain_id             integer(11) not null,
   allele_length         integer(6),
   UNIQUE            (marker_id,strain_id)
);
INSERT INTO map (map_id,map_study_id,map_name,linkage_group) values(NULL,1,'marshfield','chr');
INSERT INTO map_type (map_type,map_units) VALUES ('Genetic','cM');
INSERT INTO map_type (map_type,map_units) VALUES ('Physical','Kb');
INSERT INTO map_type (map_type,map_units) VALUES ('Radiation Hybrid','cR');
INSERT INTO map_type (map_type,map_units) VALUES ('Cytogenetic','microns');
