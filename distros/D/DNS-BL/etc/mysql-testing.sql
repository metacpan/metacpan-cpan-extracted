# Create the required tables for TESTING the DNS::BL modules in a
# MySQL database.  

# $Id: mysql-testing.sql,v 1.1 2004/12/24 19:18:20 lem Exp $

# This must NOT be the same as any existing database, to insure
# meaningful results... Set the $DNS_BL_DBI_TEST variable and
# "mysqladmin create" accordingly 

USE dnsbltest;

CREATE TABLE IF NOT EXISTS bls
(	
  Id		SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT DEFAULT 1
		COMMENT 'Numeric ID of the dnsbl',
  Name		VARCHAR(255) NOT NULL
		COMMENT 'Name of the dnsbl',
  PRIMARY KEY (Id)
);

CREATE TABLE IF NOT EXISTS entries
(
  Bls_Id	SMALLINT UNSIGNED NOT NULL 
		COMMENT 'dnsbl containing this entry',
  Start_CIDR	INTEGER UNSIGNED NOT NULL
		COMMENT 'Start of the listed subnet, in integer format',
  End_CIDR 	INTEGER UNSIGNED NOT NULL
		COMMENT 'End of the listed subnet, in integer format',
  Created 	INTEGER UNSIGNED NOT NULL
		COMMENT 'TIme and date this entry was entered in Unix format',
  Text 		VARCHAR(255) NOT NULL
		COMMENT 'Descriptive text for this entry',
  Return 	VARCHAR(16) NOT NULL DEFAULT '127.0.0.2'
		COMMENT 'DNS return associated with this entry',
  PRIMARY KEY (Bls_Id, Start_CIDR, End_CIDR),
  FOREIGN KEY (Bls_Id) REFERENCES bls(Id) 
);

INSERT INTO bls (Name) VALUES ('testing-123');

GRANT SELECT,UPDATE,INSERT,DELETE ON dnsbltest.* TO 'dnsbltest'@'%';