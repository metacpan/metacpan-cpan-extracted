DROP TABLE IF EXISTS ixaddress;
CREATE TABLE ixaddress (
    id          int(10) unsigned NOT NULL,
    addressid   int(10) unsigned NOT NULL,
    fulldate	varchar(32),
  PRIMARY KEY  (id)
) ENGINE=MyISAM;

DROP TABLE IF EXISTS tester_address;
CREATE TABLE tester_address (
    addressid   int(10) unsigned NOT NULL auto_increment,
    testerid    int(10) unsigned NOT NULL default 0,
    address     varchar(255) NOT NULL,
    email	varchar(255) default NULL,
  PRIMARY KEY  (addressid)
) ENGINE=MyISAM;

DROP TABLE IF EXISTS tester_profile;
CREATE TABLE tester_profile (
    testerid    int(10) unsigned NOT NULL auto_increment,
    name	varchar(255) default NULL,
    pause	varchar(255) default NULL,
  PRIMARY KEY  (testerid)
) ENGINE=MyISAM;

