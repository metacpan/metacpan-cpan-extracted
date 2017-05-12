# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, snmptt-3.002.003-v5.0.x.sql
# ---------------------------------------------------------------------------------------------------------

create database if not exists `snmptt`;

USE `snmptt`;

#
# Table structure for table `snmptt`
#

DROP TABLE IF EXISTS `snmptt`;

CREATE TABLE `snmptt` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `eventname` varchar(50) default NULL,
  `eventid` varchar(50) default NULL,
  `trapoid` varchar(100) default NULL,
  `enterprise` varchar(100) default NULL,
  `community` varchar(32) default NULL,
  `hostname` varchar(100) default NULL,
  `agentip` varchar(16) default NULL,
  `category` varchar(20) default NULL,
  `severity` varchar(20) default NULL,
  `uptime` varchar(20) default NULL,
  `traptime` varchar(30) default NULL,
  `formatline` varchar(1024) default NULL,
  `system_running_SNMPTT` varchar(100) default NULL,
  `trapread` int(1) default '0',
  `uniqueProblem` varchar(255) default NULL,
  `archivetime` timestamp(14) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `trapread` (`trapread`),
  KEY `uniqueProblem` (`uniqueProblem`),
  KEY `enterprise` (`enterprise`),
  KEY `community` (`community`),
  KEY `hostname` (`hostname`),
  KEY `severity` (`severity`),
  KEY `category` (`category`),
  KEY `trapoid` (`trapoid`)
) ENGINE=InnoDB;

#
# Table structure for table `snmptt_archive`
#

DROP TABLE IF EXISTS `snmptt_archive`;

CREATE TABLE `snmptt_archive` (
  `id` int(10) unsigned NOT NULL default '0',
  `eventname` varchar(50) default NULL,
  `eventid` varchar(50) default NULL,
  `trapoid` varchar(100) default NULL,
  `enterprise` varchar(100) default NULL,
  `community` varchar(32) default NULL,
  `hostname` varchar(100) default NULL,
  `agentip` varchar(16) default NULL,
  `category` varchar(20) default NULL,
  `severity` varchar(20) default NULL,
  `uptime` varchar(20) default NULL,
  `traptime` varchar(30) default NULL,
  `formatline` varchar(1024) default NULL,
  `system_running_SNMPTT` varchar(100) default NULL,
  `trapread` int(1) default '0',
  `uniqueProblem` varchar(255) default NULL,
  `archivetime` timestamp(14) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `trapread` (`trapread`),
  KEY `uniqueProblem` (`uniqueProblem`),
  KEY `enterprise` (`enterprise`),
  KEY `community` (`community`),
  KEY `hostname` (`hostname`),
  KEY `severity` (`severity`),
  KEY `category` (`category`),
  KEY `trapoid` (`trapoid`)
) ENGINE=InnoDB;

#
# Table structure for table `snmptt_statistics`
#

DROP TABLE IF EXISTS `snmptt_statistics`;

CREATE TABLE `snmptt_statistics` (
  `stat_time` varchar(30) default NULL,
  `total_received` bigint(20) default NULL,
  `total_translated` bigint(20) default NULL,
  `total_ignored` bigint(20) default NULL,
  `total_unknown` bigint(20) default NULL
) ENGINE=MyISAM;

#
# Table structure for table `snmptt_unknown`
#

DROP TABLE IF EXISTS `snmptt_unknown`;

CREATE TABLE `snmptt_unknown` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `trapoid` varchar(100) default NULL,
  `enterprise` varchar(100) default NULL,
  `community` varchar(32) default NULL,
  `hostname` varchar(100) default NULL,
  `agentip` varchar(16) default NULL,
  `uptime` varchar(20) default NULL,
  `traptime` varchar(30) default NULL,
  `formatline` varchar(1024) default NULL,
  `system_running_SNMPTT` varchar(100) default NULL,
  `trapread` int(11) default '0',
  `archivetime` timestamp(14) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

#
# Table structure for table `snmptt_unknown_archive`
#

DROP TABLE IF EXISTS `snmptt_unknown_archive`;

CREATE TABLE `snmptt_unknown_archive` (
  `id` int(10) unsigned NOT NULL default '0',
  `trapoid` varchar(100) default NULL,
  `enterprise` varchar(100) default NULL,
  `community` varchar(32) default NULL,
  `hostname` varchar(100) default NULL,
  `agentip` varchar(16) default NULL,
  `uptime` varchar(20) default NULL,
  `traptime` varchar(30) default NULL,
  `formatline` varchar(1024) default NULL,
  `system_running_SNMPTT` varchar(100) default NULL,
  `trapread` int(11) default '0',
  `archivetime` timestamp(14) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

