create table biblio (

CiteKey	varchar(128) PRIMARY KEY,
CiteType tinyint unsigned,
Category varchar(128),
Identifier varchar(128),

CrossRef varchar(128),

AccessMonth varchar(64),
AccessYear varchar(64),
Authors	text,
Chapter	varchar(128),
Edition	varchar(128),
Editors	text,
HowPublished varchar(128),
Institution varchar(128),
ISBN varchar(64),
ISSN varchar(64),
Journal	varchar(255),
Location varchar(255),
Month varchar(64),
Number varchar(64),
Organization varchar(255),
Pages varchar(64),
Publisher varchar(255),
ReportType varchar(255),
School varchar(255),
Series varchar(255),
SuperTitle varchar(255),
Title varchar(255),
Volume varchar(64),
Year varchar(64),

Abstract longtext,
Annotation longtext,
BibDate datetime,
BibNote	text,
ExportDate datetime,
Keywords varchar(255),
Note longtext,
PBibNote longtext,
Recommendation varchar(255),

File text,
Source text,

index Category (Category),
index Year (Year),
index CrossRef (CrossRef),

fulltext index Combined (CiteKey, Category, Authors, Title, Year, Keywords, Note, Annotation, BibNote, PBibNote, Recommendation, Abstract)

);

create table category (
ID varchar(128) PRIMARY KEY,
Comment varchar(255)
);

create table shortcuts (
Identifier varchar(64) PRIMARY KEY,
Expanded varchar(255)
);
