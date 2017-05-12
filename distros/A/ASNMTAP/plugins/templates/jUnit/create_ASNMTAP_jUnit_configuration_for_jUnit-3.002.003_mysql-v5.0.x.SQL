# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_ASNMTAP_jUnit_configuration_for_jUnit-3.002.003_mysql-v5.0.x.SQL
# ---------------------------------------------------------------------------------------------------------

create database if not exists `jUnitConfig`;

USE `jUnitConfig`;

#
# Table structure for table `BASE_SERVICES`
#

DROP TABLE IF EXISTS `BASE_SERVICES`;

CREATE TABLE `BASE_SERVICES` (
  `BASE_ID` bigint(20) NOT NULL auto_increment,
  `UKEY` varchar(11) default NULL,
  `WLSUSERNAME` varchar(64) default NULL,
  `WLSPASSWORD` varchar(64) default NULL,
  `TITLE` varchar(64) default NULL,
  `APPNAME` varchar(64) default NULL,
  `EJBNAME` varchar(255) default NULL,
  `VERSION` varchar(8) default NULL,
  `PARAMETERS` varchar(255) default NULL,
  `TESTCLASS` varchar(255) default NULL,
  `CREATED` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `SERV_ID` int(11) unsigned NOT NULL default '0',
  `TYPE_ID` int(11) unsigned NOT NULL default '0',
  `TIMEWAIT` int(11) default NULL,
  `MAXTIME` int(11) default '0',
  `ACTIVATED` tinyint(1) unsigned default '1',
  `STATUS` enum('ASNMTAP','NEW','MAINTENANCE','EOL') NOT NULL default 'NEW',
  PRIMARY KEY  (`BASE_ID`),
  KEY `UKEY` (`UKEY`),
  KEY `FK_BASE_SERVICES_1` (`SERV_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

#
# Table structure for table `SERVER`
#

DROP TABLE IF EXISTS `SERVER`;

CREATE TABLE `SERVER` (
  `SERV_ID` int(11) NOT NULL auto_increment,
  `NAME` varchar(255) default NULL,
  `IP` varchar(16) default NULL,
  `CLUSTERNAME` varchar(64) character set latin1 collate latin1_general_ci default NULL,
  `ENV` varchar(4) default NULL,
  `WEBLOGIC_VERSION` enum('8','10') default '10',
  PRIMARY KEY  (`SERV_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

#
# Table structure for table `TYPE`
#

DROP TABLE IF EXISTS `TYPE`;

CREATE TABLE `TYPE` (
  `TYPE_ID` int(11) NOT NULL auto_increment,
  `TYPE_NAME` varchar(100) NOT NULL default '',
  `displayGroupID` int(11) default NULL,
  `groupTitlePos` char(2) NOT NULL default '',
  `collectorDaemons` varchar(64) default NULL,
  `minutes` varchar(16) default NULL,
  PRIMARY KEY  (`TYPE_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

#
# Data for the table `TYPE`
#

insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (1,'Base Service',0,'98','baseservices-01|baseservices-02','*/10|5-59/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (2,'Message Driven Bean',36,'0','MessageDrivenBean-01','*/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (3,'Tuxedo Call',65,'0','tuxedo-01','*/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (4,'Tuxedo Application',25,'0','tuxedo-01','*/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (5,'Web Service',31,'0','web-services-01','7-59/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (6,'Periodical Task',37,'0','periodicalTask-01','5-59/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (7,'Java Application',39,'0','javaApplication-01','7-59/10');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (0,'<CONFIG FAULT>',0,'0',NULL,NULL);
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (8,'Base Service & Web Service',40,'0','ejb-web-services-01','7-59/30');
insert  into `TYPE`(`TYPE_ID`,`TYPE_NAME`,`displayGroupID`,`groupTitlePos`,`collectorDaemons`,`minutes`) values (9,'Database Monitoring',67,'0','databaseMonitoring-01','7-59/10');
