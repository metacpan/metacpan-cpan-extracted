-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
    tableinfo_id serial not null,
    primary key (tableinfo_id),
    name varchar(30) not null,
    primary_key_column varchar(30) null,
    is_view int not null default 0,
    view_on_table_id int null,
    superclass_table_id int null,
    is_updateable int not null default 1,
    modification_date date not null default now(),
    constraint tableinfo_c1 unique (name)
);

COMMENT ON TABLE tableinfo IS NULL;

-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
    contact_id serial not null,
    primary key (contact_id),
    name varchar(30) not null,
    description varchar(255) null,
    constraint contact_c1 unique (name)
);

COMMENT ON TABLE contact IS NULL;

-- ================================================
-- TABLE: db
-- ================================================

create table db (
    db_id serial not null,
    primary key (db_id),
    name varchar(255) not null,
    contact_id int,
    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    description varchar(255) null,
    urlprefix varchar(255) null,
    url varchar(255) null,
    constraint db_c1 unique (name)
);

COMMENT ON TABLE db IS NULL;

-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
    dbxref_id serial not null,
    primary key (dbxref_id),
    db_id int not null,
    foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
    accession varchar(255) not null,
    version varchar(255) not null default '',
    description text,
    constraint dbxref_c1 unique (db_id,accession,version)
);
create index dbxref_idx1 on dbxref (db_id);
create index dbxref_idx2 on dbxref (accession);
create index dbxref_idx3 on dbxref (version);

COMMENT ON TABLE dbxref IS NULL;

-- ================================================
-- TABLE: project
-- ================================================
create table project (
    project_id serial not null,  
    primary key (project_id),
    name varchar(255) not null,
    description varchar(255) not null,
    constraint project_c1 unique (name)
);

COMMENT ON TABLE project IS NULL;

-- See cv-intro.txt

-- ================================================
-- TABLE: cv
-- ================================================

create table cv (
    cv_id serial not null,
    primary key (cv_id),
    name varchar(255) not null,
   definition text,
   constraint cv_c1 unique (name)
);

-- ================================================
-- TABLE: cvterm
-- ================================================

create table cvterm (
    cvterm_id serial not null,
    primary key (cvterm_id),
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    name varchar(1024) not null,
    definition text,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    is_obsolete int not null default 0,
    is_relationshiptype int not null default 0,
    constraint cvterm_c1 unique (name,cv_id,is_obsolete),
    constraint cvterm_c2 unique (dbxref_id)
);
create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);

COMMENT ON TABLE cvterm IS
 'A term, class or concept within an ontology or controlled vocabulary.
  Also used for relationship types. A cvterm can also be thought of
  as a node in a graph';
COMMENT ON COLUMN cvterm.cv_id IS
 'The cv/ontology/namespace to which this cvterm belongs';
COMMENT ON COLUMN cvterm.name IS
 'A concise human-readable name describing the meaning of the cvterm';
COMMENT ON COLUMN cvterm.definition IS
 'A human-readable text definition';
COMMENT ON COLUMN cvterm.dbxref_id IS
 'Primary dbxref - The unique global OBO identifier for this cvterm.
  Note that a cvterm may  have multiple secondary dbxrefs - see also
  table: cvterm_dbxref';
COMMENT ON COLUMN cvterm.is_obsolete IS
 'Boolean 0=false,1=true; see GO documentation for details of obsoletion.
  note that two terms with different primary dbxrefs may exist if one
  is obsolete';
COMMENT ON COLUMN cvterm.is_relationshiptype IS
 'Boolean 0=false,1=true
  Relationship types (also known as Typedefs in OBO format, or as
  properties or slots) form a cv/ontology in themselves. We use this
  flag to indicate whether this cvterm is an actual term/concept or
  a relationship type';
COMMENT ON INDEX cvterm_c1 IS 
 'the OBO identifier is globally unique';
COMMENT ON INDEX cvterm_c2 IS 
 'a name can mean different things in different contexts;
  for example "chromosome" in SO and GO. A name should be unique
  within an ontology/cv. A name may exist twice in a cv, in both
  obsolete and non-obsolete forms - these will be for different
  cvterms with different OBO identifiers; so GO documentation for
  more details on obsoletion';

-- ================================================
-- TABLE: cvterm_relationship
-- ================================================

create table cvterm_relationship (
    cvterm_relationship_id serial not null,
    primary key (cvterm_relationship_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint cvterm_relationship_c1 unique (subject_id,object_id,type_id)
);
COMMENT ON TABLE cvterm_relationship IS
 'A relationship linking two cvterms. A relationship can be thought of
  as an edge in a graph, or as a natural language statement about
  two cvterms. The statement is of the form SUBJECT PREDICATE OBJECT;
  for example "wing part_of body"';

create index cvterm_relationship_idx1 on cvterm_relationship (type_id);
create index cvterm_relationship_idx2 on cvterm_relationship (subject_id);
create index cvterm_relationship_idx3 on cvterm_relationship (object_id);


-- ================================================
-- TABLE: cvtermpath
-- ================================================

create table cvtermpath (
    cvtermpath_id serial not null,
    primary key (cvtermpath_id),
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    pathdistance int,
    constraint cvtermpath_c1 unique (subject_id,object_id,type_id,pathdistance)
);
create index cvtermpath_idx1 on cvtermpath (type_id);
create index cvtermpath_idx2 on cvtermpath (subject_id);
create index cvtermpath_idx3 on cvtermpath (object_id);
create index cvtermpath_idx4 on cvtermpath (cv_id);

-- ================================================
-- TABLE: cvtermsynonym
-- ================================================

create table cvtermsynonym (
    cvtermsynonym_id serial not null,
    primary key (cvtermsynonym_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym varchar(1024) not null,
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade  INITIALLY DEFERRED,
    constraint cvtermsynonym_c1 unique (cvterm_id,synonym)
);
create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);

-- ================================================
-- TABLE: cvterm_dbxref
-- ================================================

create table cvterm_dbxref (
    cvterm_dbxref_id serial not null,
    primary key (cvterm_dbxref_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_for_definition int not null default 0,
    constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
);
create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);

-- ================================================
-- TABLE: cvtermprop 	 
-- ================================================ 	 

create table cvtermprop ( 
    cvtermprop_id serial not null, 
    primary key (cvtermprop_id), 
    cvterm_id int not null, 
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade, 
    type_id int not null, 
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade, 
    value text not null default '', 
    rank int not null default 0,

    unique(cvterm_id, type_id, value, rank) 
);

-- ================================================
-- TABLE: dbxrefprop
-- ================================================

create table dbxrefprop (
    dbxrefprop_id serial not null,
    primary key (dbxrefprop_id),
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    value text not null default '',
    rank int not null default 0,
    constraint dbxrefprop_c1 unique (dbxref_id,type_id,rank)
);
create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);

-- ================================================
-- TABLE: organism
-- ================================================

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbreviation varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,
    constraint organism_c1 unique (genus,species)
);

COMMENT ON COLUMN organism.species IS
 'A type of organism is always uniquely identified by genus+species. When mapping from the NCBI taxonomy names.dmp file, the unique-name column must be used where it is present, as the name column is not always unique (eg environmental samples)';

-- Compared to mol5..Species, organism table lacks "approved char(1) null".  
-- We need to work w/ Aubrey & Michael to ensure that we don't need this in 
-- future [dave]
--
-- in response: this is very specific to a limited use case I think;
-- if it's really necessary we can have an organismprop table
-- for adding internal project specific data
-- [cjm]
-- done (below) 19-MAY-03 [dave]


-- ================================================
-- TABLE: organism_dbxref
-- ================================================

create table organism_dbxref (
    organism_dbxref_id serial not null,
    primary key (organism_dbxref_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint organism_dbxref_c1 unique (organism_id,dbxref_id)
);
create index organism_dbxref_idx1 on organism_dbxref (organism_id);
create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);

-- ================================================
-- TABLE: organismprop
-- ================================================

create table organismprop (
    organismprop_id serial not null,
    primary key (organismprop_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organismprop_c1 unique (organism_id,type_id,rank)
);
create index organismprop_idx1 on organismprop (organism_id);
create index organismprop_idx2 on organismprop (type_id);

CREATE VIEW cvterm_relationship_with_typename AS
 SELECT
  cvterm_relationship.*,
  typeterm.name AS typename,
  typeterm.cv_id AS typeterm_cv_id
 FROM cvterm_relationship
      INNER JOIN cvterm AS typeterm ON (type_id=typeterm.cvterm_id);

CREATE VIEW cvtermprop_with_propname AS
 SELECT
  cvtermprop.*,
  propterm.name AS propname,
  propterm.cv_id AS propterm_cv_id
 FROM cvtermprop
      INNER JOIN cvterm AS propterm ON (type_id=propterm.cvterm_id);



-- Cross-products, logical definitions

-- These views are for advanced use - you will only need them if
-- you are loading ontologies that use either advanced obo format 1.2
-- features or OWL DL ontologies. Please read the relevant documentation
-- first

-- keywords: defined classes, OWL, Aristotelian definitions

CREATE OR REPLACE VIEW is_anonymous_cvterm AS
 SELECT cvterm_id
 FROM cvtermprop_with_propname
 WHERE propname='is_anonymous' AND value='1';

CREATE OR REPLACE VIEW cvterm_ldef_intersection AS
SELECT *
FROM 
 cvterm_relationship_with_typename
WHERE
 typename='intersection_of';

COMMENT ON VIEW cvterm_ldef_intersection IS 'for advanced OWL/Description Logic style definitions, chado allows the specification of an equivalentClass using intersection_of links between the defined term and the cross-product';


CREATE OR REPLACE VIEW cvterm_genus AS
SELECT
 i.subject_id AS cvterm_id,
 i.object_id AS genus_id
FROM
 cvterm_ldef_intersection AS i
WHERE
 i.object_id NOT IN (SELECT cvterm_id FROM is_anonymous_cvterm);

COMMENT ON VIEW cvterm_genus IS 'In a logical (cross-product) definition, there is a generic term (genus) and discriminating characteristics. E.g. a biosynthesis (genus) which outputs cysteine (differentia). The genus is the -true- is_a parent';

CREATE OR REPLACE VIEW cvterm_differentium AS
SELECT
 i.subject_id AS cvterm_id,
 diff.*
FROM
 cvterm_ldef_intersection AS i
 INNER JOIN cvterm_relationship AS diff ON (i.object_id=diff.subject_id)
 INNER JOIN is_anonymous_cvterm AS anon  ON (anon.cvterm_id=i.object_id);

COMMENT ON VIEW cvterm_differentium IS 'In a logical (cross-product) definition, there is a generic term (genus) and discriminating characteristics. E.g. a biosynthesis (genus) which outputs cysteine (differentia). Each differentium is a link via a relation to another cvterm which discriminates the defined term from other is_a siblings';

