-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: cpanblog
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `access`
--

DROP TABLE IF EXISTS `access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access` (
  `accessid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessname` varchar(255) DEFAULT NULL,
  `accesslevel` int(4) DEFAULT NULL,
  PRIMARY KEY (`accessid`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `access`
--

INSERT INTO `access` VALUES (1,'reader',1);
INSERT INTO `access` VALUES (2,'editor',2);
INSERT INTO `access` VALUES (3,'publisher',3);
INSERT INTO `access` VALUES (4,'admin',4);
INSERT INTO `access` VALUES (5,'master',5);

--
-- Table structure for table `acls`
--

DROP TABLE IF EXISTS `acls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acls` (
  `aclid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned DEFAULT '0',
  `userid` int(10) unsigned DEFAULT '0',
  `accessid` int(4) DEFAULT NULL,
  PRIMARY KEY (`aclid`),
  KEY `IXFOLDER` (`folderid`),
  KEY `IXGROUP` (`groupid`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acls`
--

INSERT INTO `acls` VALUES (1,1,9,0,5);
INSERT INTO `acls` VALUES (2,1,1,0,1);
INSERT INTO `acls` VALUES (3,1,0,5,4);
INSERT INTO `acls` VALUES (4,1,0,9,4);
INSERT INTO `acls` VALUES (5,1,0,3,5);

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `articles` (
  `articleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `createdate` int(11) DEFAULT '0',
  `sectionid` int(10) unsigned NOT NULL DEFAULT '0',
  `quickname` varchar(32) DEFAULT NULL,
  `snippet` varchar(255) DEFAULT NULL,
  `imageid` int(10) unsigned DEFAULT '1',
  `front` int(1) DEFAULT '0',
  `latest` int(1) DEFAULT '0',
  `publish` int(4) DEFAULT NULL,
  PRIMARY KEY (`articleid`),
  KEY `IXSECT` (`sectionid`),
  KEY `IXPUB` (`publish`),
  KEY `IXDATE` (`createdate`),
  KEY `IXFOLDER` (`folderid`),
  KEY `IXIMAGE` (`imageid`),
  KEY `IXNAME` (`quickname`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `articles`
--

INSERT INTO `articles` VALUES (1,1,'Test Post',1,1242597696,6,'1242597696',NULL,0,0,0,2);
INSERT INTO `articles` VALUES (2,1,'About CPAN Testers',1,1241650800,1,'about',NULL,0,0,0,3);

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `commentid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `entryid` int(10) unsigned NOT NULL DEFAULT '0',
  `subject` varchar(255) NOT NULL DEFAULT '',
  `createdate` int(11) DEFAULT '0',
  `author` varchar(255) NOT NULL DEFAULT '',
  `href` varchar(255) DEFAULT NULL,
  `publish` int(4) DEFAULT NULL,
  `ipaddr` varchar(255) NOT NULL DEFAULT '',
  `body` blob,
  PRIMARY KEY (`commentid`),
  KEY `IXENTRY` (`entryid`),
  KEY `IXPUB` (`publish`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `eventid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `eventtypeid` int(10) DEFAULT NULL,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `align` int(10) unsigned NOT NULL DEFAULT '1',
  `eventdate` varchar(255) DEFAULT NULL,
  `eventtime` varchar(255) DEFAULT NULL,
  `listdate` int(11) DEFAULT '0',
  `venueid` int(10) unsigned NOT NULL DEFAULT '0',
  `body` blob,
  `links` blob,
  `extralink` varchar(255) DEFAULT NULL,
  `publish` int(4) DEFAULT NULL,
  `sponsorid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`eventid`),
  KEY `IXTYPE` (`eventtypeid`),
  KEY `IXFOLDER` (`folderid`),
  KEY `IXDATE` (`listdate`),
  KEY `IXVENUE` (`venueid`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

INSERT INTO `events` VALUES (1,1,1,'YAPC::Europe 2009',3,1,1,'3-5 August 2009','all day',1249426800,13,'<p>This will be the 10th YAPC::Europe, with the event returning to Portugal, although this time around it\'ll be in the capital, Lisbon.</p><p>Testing &amp; QA related talk currently scheduled are:</p><ul><li>Philippe Bruhat - Test::Database - Easy database access for test scripts</li><li>Abe Timmerman - Testing the Tester</li><li>Abigail - Test::Regexp</li></ul>','<ul><li><a href=\"http://yapceurope2009.org\">YAPC::Europe 2009<br /></a></li></ul>',NULL,3,1);
INSERT INTO `events` VALUES (2,1,1,'YAPC::NA 2009',3,1,1,'22-24 June 2009','all day',1245798000,12,'<p>This will be the 10th anniversary of YAPC::NA, with the event returning to Carnegie Mellon University in Pittsburgh, where it all started.</p><p>Testing &amp; QA related talk currently scheduled are:</p><ul><li>Scott McWhirter - Test automation for the risk adverse</li><li>Gabor Szabo - Test Automation in Open Source Projects</li><li>Abigail - Test::Regexp</li><li>Michael Peters - TAP in depth</li><li>Barbie - The Statistics of CPAN</li><li>Nathan Gray - Getting the most out of TAP</li></ul>','<ul><li><a href=\"http://yapc10.org\">YAPC::NA 2009</a></li></ul>',NULL,3,0);
INSERT INTO `events` VALUES (11,3,1,'2008 QA Hackathon',3,1,0,'5-7 April 2008','all day',1207350000,0,'<p><a href=\"http://2008.qa-hackathon.org\">2008 QA Hackathon</a> will be in Oslo, Norway.</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (10,1,1,'YAPC::Europe 2011',3,1,0,'15-17 August 2011','all day',1313362800,17,'<p><a href=\"http://yapceurope.lv/ye2011/\">YAPC::Europe 2011</a> will be in Riga, Latvia.</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (8,1,1,'YAPC::NA 2010',3,1,0,'21-23 June 2010','all day',1277074800,15,'<p>YAPC::NA 2010 will be at <a href=\"http://yapc2010.com/yn2010/wiki?node=Location\">The Ohio State University, Columbus, Ohio</a>.</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (9,1,1,'YAPC::NA 2011',3,1,0,'27-29 june 2011','all day',1309129200,16,'<p><a href=\"http://www.yapc2011.us/yn2011/\">YAPC::NA 2011</a> will be in Asheville, North Carolina.</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (7,1,1,'YAPC::Europe 2010',3,1,0,'4 -6 August 2010','all day',1280617200,14,'<p><a href=\"http://conferences.yapceurope.org/ye2010\">YAPC::Europe 2010</a> will take place in Pisa, Italy.</p>','<p><a href=\"http://conferences.yapceurope.org/ye2010\">YAPC::Europe 2010</a></p>',NULL,3,0);
INSERT INTO `events` VALUES (12,3,1,'2009 QA Hackathon',3,1,0,'28-30 March 2009','all day',1238198400,0,'<p><a href=\"http://2009.qa-hackathon.org\">2009 QA Hackathon</a> will be in Birmingham, UK</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (13,3,1,'2010 QA Hackathon',3,1,0,'10-12 April 2010','all day',1270854000,0,'<p><a href=\"http://2010.qa-hackathon.org\">2010 QA Hackathon</a> will be in Vienna, Austria.</p>',NULL,NULL,3,0);
INSERT INTO `events` VALUES (14,3,1,'2011 QA Hackathon',3,1,0,'16-18 April 2011','all day',1302908400,0,'<p><a href=\"http://2011.qa-hackathon.org\">2011 QA Hackathon</a> will be in Amsterdam, The Netherlands.</p>',NULL,NULL,3,0);

--
-- Table structure for table `eventtypes`
--

DROP TABLE IF EXISTS `eventtypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eventtypes` (
  `eventtypeid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `eventtype` varchar(255) NOT NULL DEFAULT '',
  `talks` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`eventtypeid`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eventtypes`
--

INSERT INTO `eventtypes` VALUES (1,'Conference',1);
INSERT INTO `eventtypes` VALUES (2,'Workshop',1);
INSERT INTO `eventtypes` VALUES (3,'Hackathon',1);
INSERT INTO `eventtypes` VALUES (4,'User Group',1);
INSERT INTO `eventtypes` VALUES (5,'Social Meeting',0);
INSERT INTO `eventtypes` VALUES (6,'Technical Meeting',1);
INSERT INTO `eventtypes` VALUES (7,'Special',1);

--
-- Table structure for table `folders`
--

DROP TABLE IF EXISTS `folders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `folders` (
  `folderid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent` int(10) DEFAULT NULL,
  `accessid` int(10) NOT NULL DEFAULT '5',
  PRIMARY KEY (`folderid`),
  KEY `IXPATH` (`path`)
) ENGINE=MyISAM AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `folders`
--

INSERT INTO `folders` VALUES (1,'public',0,1);

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `groupid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(255) DEFAULT NULL,
  `master` int(2) DEFAULT '0',
  `member` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`groupid`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `groups`
--

INSERT INTO `groups` VALUES (1,'public',1,'Guest');
INSERT INTO `groups` VALUES (2,'users',1,'User');
INSERT INTO `groups` VALUES (3,'editors',1,'Author');
INSERT INTO `groups` VALUES (4,'sponsors',1,'Sponsor');
INSERT INTO `groups` VALUES (5,'admins',1,'Admin');
INSERT INTO `groups` VALUES (9,'masters',1,'Master');

--
-- Table structure for table `hits`
--

DROP TABLE IF EXISTS `hits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hits` (
  `pageid` int(11) NOT NULL DEFAULT '0',
  `area` varchar(32) DEFAULT '',
  `photoid` int(11) NOT NULL DEFAULT '0',
  `counter` int(11) DEFAULT NULL,
  `query` varchar(255) DEFAULT '',
  `createdate` int(11) DEFAULT '0',
  KEY `IXPAGE` (`pageid`,`photoid`),
  KEY `IXAREA` (`area`),
  KEY `IXQUERY` (`query`),
  KEY `IXDATE` (`createdate`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `images` (
  `imageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tag` varchar(255) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `type` int(4) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  `dimensions` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`imageid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `images`
--

INSERT INTO `images` VALUES (1,NULL,'images/blank.png',1,NULL,NULL);

--
-- Table structure for table `imagestock`
--

DROP TABLE IF EXISTS `imagestock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `imagestock` (
  `stockid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`stockid`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imagestock`
--

INSERT INTO `imagestock` VALUES (1,'Public','images/public');
INSERT INTO `imagestock` VALUES (2,'Random','images/public');
INSERT INTO `imagestock` VALUES (3,'Advert','images/adverts');
INSERT INTO `imagestock` VALUES (4,'User','images/users');
INSERT INTO `imagestock` VALUES (5,'Layout','images/layout');
INSERT INTO `imagestock` VALUES (9,'DRAFT','images/draft');

--
-- Table structure for table `imetadata`
--

DROP TABLE IF EXISTS `imetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `imetadata` (
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `tag` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`imageid`,`tag`),
  KEY `IXTAG` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipindex`
--

DROP TABLE IF EXISTS `ipindex`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipindex` (
  `ipaddr` varchar(255) NOT NULL DEFAULT '',
  `author` varchar(255) NOT NULL DEFAULT '',
  `type` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ipaddr`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ixfolderrealm`
--

DROP TABLE IF EXISTS `ixfolderrealm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixfolderrealm` (
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `realmid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`folderid`,`realmid`),
  KEY `IXREALM` (`realmid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixfolderrealm`
--

INSERT INTO `ixfolderrealm` VALUES (1,1);
INSERT INTO `ixfolderrealm` VALUES (1,2);

--
-- Table structure for table `ixusergroup`
--

DROP TABLE IF EXISTS `ixusergroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixusergroup` (
  `indexid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` int(1) unsigned NOT NULL DEFAULT '0',
  `linkid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`indexid`),
  KEY `IXTYPE` (`type`),
  KEY `IXLINK` (`linkid`),
  KEY `IXGROUP` (`groupid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixusergroup`
--

INSERT INTO `ixusergroup` VALUES (1,1,1,1);
INSERT INTO `ixusergroup` VALUES (2,1,1,9);

--
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menus` (
  `menuid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `typeid` int(10) unsigned DEFAULT '1',
  `realmid` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `parentid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`menuid`),
  KEY `IXTYPE` (`typeid`),
  KEY `IXREALM` (`realmid`),
  KEY `IXPARENT` (`parentid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

INSERT INTO `menus` VALUES (1,1,1,'Public','Public Menu',0);
INSERT INTO `menus` VALUES (2,1,2,'Admin','Admin Menu',0);

--
-- Table structure for table `mxarticles`
--

DROP TABLE IF EXISTS `mxarticles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mxarticles` (
  `articleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `metadata` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`articleid`,`metadata`),
  KEY `IXMETA` (`metadata`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mxarticles`
--

INSERT INTO `mxarticles` VALUES (1,'reports');

--
-- Table structure for table `optimages`
--

DROP TABLE IF EXISTS `optimages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `optimages` (
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `typeid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`optionid`,`typeid`),
  KEY `IXTYPE` (`typeid`),
  KEY `IXIMAGE` (`imageid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `options`
--

DROP TABLE IF EXISTS `options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `options` (
  `optionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `menuid` int(10) unsigned NOT NULL DEFAULT '0',
  `orderno` int(2) DEFAULT '0',
  `accessid` int(2) DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  `section` varchar(255) DEFAULT '',
  PRIMARY KEY (`optionid`),
  KEY `IXMENU` (`menuid`)
) ENGINE=MyISAM AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `options`
--

INSERT INTO `options` VALUES (1,1,1,1,NULL,'Home','/page/main',NULL);
INSERT INTO `options` VALUES (2,1,2,1,NULL,'About','/article/about',NULL);
INSERT INTO `options` VALUES (3,1,3,1,NULL,'Events','/event/main',NULL);
INSERT INTO `options` VALUES (4,1,4,1,NULL,'Admin','/user/login',NULL);
INSERT INTO `options` VALUES (11,2,2,4,NULL,'Diary','/diary/admin',NULL);
INSERT INTO `options` VALUES (12,2,3,4,NULL,'Articles','/arts/admin',NULL);
INSERT INTO `options` VALUES (13,2,4,4,NULL,'Events','/event/admin',NULL);
INSERT INTO `options` VALUES (15,2,6,5,NULL,'Menus','/menu/admin',NULL);
INSERT INTO `options` VALUES (16,2,7,5,NULL,'Hits','/hits/pages',NULL);
INSERT INTO `options` VALUES (17,2,8,4,NULL,'Users','/user/admin',NULL);
INSERT INTO `options` VALUES (18,2,9,1,NULL,'Logout','/user/logout',NULL);

--
-- Table structure for table `paragraphs`
--

DROP TABLE IF EXISTS `paragraphs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `paragraphs` (
  `paraid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `articleid` int(10) unsigned NOT NULL DEFAULT '0',
  `orderno` int(4) DEFAULT NULL,
  `type` int(4) DEFAULT NULL,
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `href` varchar(255) DEFAULT NULL,
  `body` blob,
  `align` int(4) DEFAULT NULL,
  PRIMARY KEY (`paraid`),
  KEY `IXART` (`articleid`),
  KEY `IXIMG` (`imageid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `paragraphs`
--

INSERT INTO `paragraphs` VALUES (1,1,1,2,0,NULL,'<p>Test</p>',NULL);
INSERT INTO `paragraphs` VALUES (2,2,1,2,0,NULL,'<h2>Who, What, Why?</h2><p>CPAN Testers is a volunteer effort to test distributions as they are uploaded to CPAN, the Perl code repository. There are currently over 100 testers, who are able to test across several different versions of Perl and on many different platforms.</p><p>There are two aims behind the CPAN Testers projects, firstly to give feedback to authors, and secondly to give users the opportunity to check whether a particular distribution will install and run on their system.</p><p>Authors often are limited to the number of Perl/platform combinations, so CPAN Testers provide a unique opportunity to get feedback on issues which they might not receive from users trying to use their distribution.</p><p>Users are also able to benefit from CPAN Testers, as the reports can highlight when a distribution might be problematic. Together with the other resources, such as the <a href=\"http://pass.cpantesters.org\">PASS Matrix</a>, <a href=\"http://deps.cpantesters.org\">CPAN Dependencies</a> and the <a href=\"http://matrix.cpantesters.org\">CPAN Testers Matrix</a>, users can make an informed choice as to which distributions might be best for them.</p><h2>History</h2><p>The CPAN testers was conceived back in May 1998 by Graham Barr and Chris Nandor as a way to provide multi-platform testing for modules. Today there are over 3 million tester reports and more than 100 testers each month giving valuable feedback for users and authors alike.</p><p>For several years testers created test reports by hand, until CPANPLUS included a simple test smoker script. This script was dropped when CPANPLUS-0.50 was redesigned, such that the new API was no longer compatible. Robert Rothenberg and Barbie wrote CPAN-YACSmoke, which lasted for several years. In the meantime those using CPAN.pm as their installer felt there should be a counterpart for them. As such David Golden wrote <a href=\"http://search.cpan.org/dist/CPAN-Reporter\">CPAN-Reporter</a>. Due to lack of time to work on the core software, <a href=\"http://search.cpan.org/dist/CPAN-YACSmoke\">CPAN-YACSmoke</a> started to stagnate, to the point Chris Williams wrote <a href=\"http://search.cpan.org/dist/CPANPLUS-YACSmoke\">CPANPLUS-YACSmoke</a> as a replacement.</p><p>The current eco-system is driven by SMTP/NNTP, which is creaking under the weight of the reports. The future is looking to move CT2.0 to a HTTP system based on the new Metabase system being developed by Ricardo Signes and David Golden.</p><h2>The New Team<br /></h2><p>The people promoting CPAN Testers has changed over the years, as interest in the project fluctuates. However, right now we have a very dedicated team working behind the scenes to ensure that we are continually refining and improving the process of testing and reporting, and providing the authors with the right feedback to help improve their code.</p><p>Specific mentions should go to the following people, who although act as primary contacts for specific parts of the toolchain mentioned, all have helped to maintain CPAN Testers eco-system.</p><ul><li>Dave Golden - CPAN-Reporter / Metabase</li><li>Chris \'BinGOs\' Williams - CPANPLUS-Reporter</li><li>Andreas K&ouml;nig - CPAN.pm</li><li>Jos Boumans - CPANPLUS</li><li>Ricardo Signes - Metabase</li><li>David Cantrell - CPAN Dependencies</li><li>Slaven Rezi&#263; - CPAN Testers Matrix</li><li>Barbie - Databases &amp; Websites</li></ul><h2>Resources<br /></h2><p>If you have any issues with any part of the process, please use the resouces we have available to help improve the feedback and use of CPAN Testers to you. Specifically if you are an author or a tester, please see the <a href=\"http://wiki.cpantesters.org/\">CPAN Testers Wiki</a>, to see if there is anything appropriate there, or join the <a href=\"http://wiki.cpantesters.org/wiki/MailingLists\">\'CPAN Testers Discuss\'</a> mailing list and ask your question there. There are a number of testers and developers on the mailing list who are on hand to help out wherever possible.</p>',NULL);

--
-- Table structure for table `realms`
--

DROP TABLE IF EXISTS `realms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `realms` (
  `realmid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `realm` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `command` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`realmid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `realms`
--

INSERT INTO `realms` VALUES (1,'public','Public Interface','home-main');
INSERT INTO `realms` VALUES (2,'admin','Admin Interface','home-admin');

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `sessionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `labyrinth` varchar(255) DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `realm` varchar(255) DEFAULT NULL,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `timeout` int(11) unsigned NOT NULL DEFAULT '0',
  `langcode` char(2) NOT NULL DEFAULT 'en',
  `query` blob,
  PRIMARY KEY (`sessionid`),
  KEY `IXLAB` (`labyrinth`),
  KEY `IXTIMEOUT` (`timeout`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sponsors`
--

DROP TABLE IF EXISTS `sponsors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sponsors` (
  `sponsorid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sponsor` varchar(255) NOT NULL DEFAULT '',
  `sponsorlink` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sponsorid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` VALUES (1,'Miss Barbell Productions','http://www.missbarbell.co.uk');

--
-- Table structure for table `techtalks`
--

DROP TABLE IF EXISTS `techtalks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `techtalks` (
  `talkid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `eventid` int(10) unsigned NOT NULL DEFAULT '0',
  `guest` int(2) DEFAULT '0',
  `talktitle` varchar(255) DEFAULT NULL,
  `abstract` blob,
  `resource` blob,
  PRIMARY KEY (`talkid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `techtalks`
--

INSERT INTO `techtalks` VALUES (1,3,1,0,'Title To Be Confirmed','<p>Abstract Here</p>','<p>No Resources</p>');

--
-- Table structure for table `updates`
--

DROP TABLE IF EXISTS `updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `updates` (
  `upid` int(11) NOT NULL AUTO_INCREMENT,
  `area` varchar(8) DEFAULT '',
  `pageid` int(11) DEFAULT NULL,
  `now` int(11) DEFAULT NULL,
  `pagets` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`upid`),
  KEY `IXAREA` (`area`),
  KEY `IXPAGE` (`pageid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `userid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned NOT NULL DEFAULT '1',
  `nickname` varchar(255) DEFAULT NULL,
  `realname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `realm` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `aboutme` blob,
  PRIMARY KEY (`userid`),
  KEY `IXACCESS` (`accessid`),
  KEY `IXIMAGE` (`imageid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES (1,5,1,'','Master','master@missbarbell.co.uk','admin','c00a8735efadd488c3251ef24211cd2e7baa9e66','','');
INSERT INTO `users` VALUES (2,1,1,'Guest','guest','GUEST','public','c8d6ea7f8e6850e9ed3b642900ca27683a257201','','');

--
-- Table structure for table `venues`
--

DROP TABLE IF EXISTS `venues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `venues` (
  `venueid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `venue` varchar(255) DEFAULT NULL,
  `venuelink` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `addresslink` varchar(255) DEFAULT NULL,
  `info` blob,
  PRIMARY KEY (`venueid`)
) ENGINE=MyISAM AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `venues`
--

INSERT INTO `venues` VALUES (1,'To Be Confirmed','','More details soon','','');
INSERT INTO `venues` VALUES (2,'University of Minho','http://www.uminho.pt/','Braga, Portugal','http://braga.yapceurope.org/index.cgi?Location','');
INSERT INTO `venues` VALUES (3,'Wirtschaftsuniversit&auml;t Wien','http://www.wu-wien.ac.at/english/','Vienna University of Economics and Business Administration, Augasse 2-6, A-1090 Vienna, Austria, E.U.','http://maps.google.co.uk/maps?f=q&amp;hl=en&amp;q=Wirtschaftsuniversit%C3%A4t&amp;layer=&amp;sll=48.230105,16.364136&amp;sspn=0.083018,0.181274&amp;ie=UTF8&amp;z=16&amp;t=h&amp;om=1','');
INSERT INTO `venues` VALUES (4,'CBSO Centre','http://www.cbso.co.uk/?page=about/cbsoCentre.html','Berkley Street, Birmingham, B1 2LF','http://maps.google.com/maps?f=q&amp;hl=en&amp;q=B1+2LF&amp;om=1','');
INSERT INTO `venues` VALUES (5,'Illinois Institute of Technology','http://www.iit.edu/','Chicago, IL, USA','http://en.wikipedia.org/wiki/Chicago','');
INSERT INTO `venues` VALUES (6,'University of Houston&#39;s University Center','http://www.uh.edu/ucaf/','4800 Calhoun Rd, Houston, TX 77004-2693','http://maps.citysearch.com/map/view/9840002','');
INSERT INTO `venues` VALUES (7,'The Lighthouse','http://www.light-house.co.uk/','The Chubb Buildings, Fryer Street, Wolverhampton, WV1 1HT','http://maps.google.co.uk/maps?f=q&amp;hl=en&amp;q=WV1+1HT&amp;layer=&amp;ie=UTF8&amp;z=16&amp;t=h&amp;om=1&amp;iwloc=addr','');
INSERT INTO `venues` VALUES (8,'University of Westminster','http://www.wmin.ac.uk/page-4459','115 New Cavendish Street, London W1W 6UW','http://www.wmin.ac.uk/page-7679-smhp=4459','<p>The Campus is located just by Cleveland Street and the imposing landmark of the BT Tower, and close to undergound and mainline railway stations and bus routes. Limited underground car parking is available only to those people with special needs. The nearest undergound stations are:</p><ul><li>Goodge Street (Northern Line)<br /></li><li>Great Portland Street (Metropolitan, Circle and Hammersmith and City Lines)<br /></li><li>Oxford Circus (Central, Bakerloo and Victoria Lines)<br /></li><li>Warren Street (Northern and Victoria Lines).<br /></li></ul><p>Several buses run along Tottenham Court Road and Euston Road that are only five minutes&#39; walk away. The Campus is a 15-20 minute walk from Kings&#39; Cross, St Pancras and Euston railway stations.</p>');
INSERT INTO `venues` VALUES (9,'Illinois Institute of Technology (Main Campus)','http://www.iit.edu/','3300 South federal Street, Chicago, IL, USA','http://www.iit.edu/about/directions_main.html','<p>The event will take place at the Main Campus of the IIT.</p>');
INSERT INTO `venues` VALUES (10,'Copenhagen Business School','http://www.cbs.dk/','Solbjerg Plads 3, 2000 Frederiksberg, Denmark','http://maps.google.co.uk/maps?ie=UTF-8&amp;oe=utf-8&amp;rls=org.mozilla:en-US:official&amp;client=firefox-a&amp;um=1&amp;q=Business+School&amp;near=Copenhagen,+Danmark&amp;fb=1&amp;cid=0,0,175902229759621988&amp;sa=X&amp;oi=local_result&amp;resnum=1&amp;c','');
INSERT INTO `venues` VALUES (11,'Imperial College London',NULL,'London',NULL,'');
INSERT INTO `venues` VALUES (12,'Carnegie Mellon University, University Center','http://cmu.edu/','5000 Forbes Avenue Pittsburgh, PA 15213, USA','http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=5000+Forbes+Avenue+Pittsburgh,+PA+15213&amp;sll=52.476324,-1.913424&amp;sspn=0.009149,0.027874&amp;gl=uk&amp;ie=UTF8&amp;z=16&amp;iwloc=addr','');
INSERT INTO `venues` VALUES (13,'FCUL (Faculty of Sciences of the University of Lisbon)','http://www.fc.ul.pt/en/','Campo Grande, Edif&iacute;cio C5, 1749-016 Lisboa, Portugal','http://maps.google.co.uk/maps?f=l&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=Edif%C3%ADcio+C5,+1749-016&amp;sll=38.76498,-9.096157&amp;sspn=0.011712,0.027874&amp;gl=uk&amp;g=1749-016+Lisboa,+portugal&amp;ie=UTF8&amp;near=Lisbon,+Portugal&amp;ll=38.756861','');
INSERT INTO `venues` VALUES (14,'My One Hotel Pisa Conference Centre','http://www.myonehotel.it/eng/galilei/default.asp','Via Darsena, 1 (Ang. Via Aurelia) - 56121 Pisa (PI)','http://bit.ly/8FN64F','');
INSERT INTO `venues` VALUES (15,'The Ohio State University','http://ohiounion.osu.edu/','1739 N. High Street, Columbus, OH 43210','http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=1739+North+High+Street,+Columbus,+OH+43210,+United+States&amp;aq=0&amp;sll=53.800651,-4.064941&amp;sspn=18.304449,57.084961&amp;ie=UTF8&amp;hq=&amp;hnear=1739+N+High+St,+Columbu','');
INSERT INTO `venues` VALUES (16,'Crowne Plaza Resort','http://www.ashevillecp.com/home/','One Resort Drive, Asheville, NC 28806','http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=Crowne+Plaza+Resort,+Resort+Drive,+Asheville,+NC+28806,+United+States&amp;aq=&amp;sll=35.594464,-82.580093&amp;sspn=0.024533,0.055747&amp;ie=UTF8&amp;hq=Crowne+Plaza+Resort,&amp','');
INSERT INTO `venues` VALUES (17,'Riga Congress Centre','http://www.kongresunams.riga.lv/','K. Valdem&#257;ra iela 5, LV-1010, R&#299;ga, Latvija','http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=K.+Valdem%C4%81ra+iela+5,+LV-1010,+R%C4%ABga,+Latvija&amp;aq=&amp;sll=35.592749,-82.579355&amp;sspn=0.012267,0.027874&amp;ie=UTF8&amp;hq=&amp;hnear=Kri%C5%A1j%C4%81%C5%86a+Valde','');
INSERT INTO `venues` VALUES (18,'Booking.com','http://booking.com','Nieuwe Weteringstraat 36, Amsterdam, Noord-Holland 1017 ZX','http://maps.google.co.uk/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=Nieuwe+Weteringstraat+36,+Amsterdam,+Noord-Holland+1017+ZX&amp;aq=&amp;sll=56.954871,24.109043&amp;sspn=0.008226,0.027874&amp;ie=UTF8&amp;hq=&amp;hnear=Nieuwe+Weteringstraat+36,','');

--
-- Table structure for table `volumes`
--

DROP TABLE IF EXISTS `volumes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `volumes` (
  `volumeid` varchar(8) NOT NULL DEFAULT '',
  `sectionid` int(10) unsigned NOT NULL DEFAULT '0',
  `archdate` varchar(32) DEFAULT NULL,
  `counter` int(10) unsigned DEFAULT '1',
  PRIMARY KEY (`volumeid`,`sectionid`),
  KEY `IXSECT` (`sectionid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-02-16 21:20:36
