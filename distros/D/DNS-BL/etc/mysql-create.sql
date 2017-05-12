# Create the required tables for the DNS::BL modules in a
# MySQL database
#
# $Id: mysql-create.sql,v 1.2 2004/12/24 12:58:49 lem Exp $

USE dnsbl;

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