# MySQL dump 8.14
#
# Host: localhost    Database: centipaid_rcpt
#--------------------------------------------------------
# Server version	3.23.41

#
# Table structure for table 'rcpt'
#

CREATE TABLE rcpt (
  rcpt varchar(100) NOT NULL default '',
  date datetime NOT NULL default '0000-00-00 00:00:00',
  expire datetime NOT NULL default '0000-00-00 00:00:00',
  paid double NOT NULL default '0',
  ip varchar(100) default NULL,
  zone varchar(50) NOT NULL default '',
  PRIMARY KEY  (rcpt)
) TYPE=MyISAM;

#
# Dumping data for table 'rcpt'
#

INSERT INTO rcpt VALUES ('AEF0011037311494','2002-11-14 16:34:31','2002-11-15 16:34:31',0.005,'127.0.0.1','');
INSERT INTO rcpt VALUES ('AEF0011037311446','2002-11-14 16:33:48','2002-11-15 16:33:48',0.01,'127.0.0.1','');
INSERT INTO rcpt VALUES ('AEF0011037312018','2002-11-14 16:42:48','2002-12-14 16:42:48',1,'127.0.0.1','');

