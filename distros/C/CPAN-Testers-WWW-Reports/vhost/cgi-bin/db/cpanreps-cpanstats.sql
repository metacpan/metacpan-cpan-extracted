--- new table used by Builder.pm

CREATE TABLE stats_store (
  `storeid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dist`    varchar(150) NOT NULL,
  `version` varchar(150) DEFAULT NULL,
  `perl`    varchar(10) DEFAULT NULL,
  `osname`  varchar(32) DEFAULT NULL,
  `counter` int(10) unsigned NOT NULL,
  `lastid`  int(10) unsigned NOT NULL,
  PRIMARY KEY (`storeid`),
  KEY `dist` (`dist`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
