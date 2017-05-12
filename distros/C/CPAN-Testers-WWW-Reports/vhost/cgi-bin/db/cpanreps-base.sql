-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: reports
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
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acls`
--

INSERT INTO `acls` VALUES (1,1,9,0,5);
INSERT INTO `acls` VALUES (2,1,1,0,1);
INSERT INTO `acls` VALUES (3,1,0,5,4);

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
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
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
-- Dumping data for table `hits`
--


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

INSERT INTO `menus` VALUES (1,1,1,'Public Navigation','',0);
INSERT INTO `menus` VALUES (2,1,2,'Admin Navigation','',0);

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
-- Dumping data for table `optimages`
--


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

INSERT INTO `options` VALUES (1,1,1,1,NULL,'Home','/',NULL);
INSERT INTO `options` VALUES (2,1,2,1,NULL,'Status','/home/status',NULL);
INSERT INTO `options` VALUES (3,1,3,1,NULL,'Help','/page/help',NULL);
INSERT INTO `options` VALUES (4,1,4,1,NULL,'About','/page/about',NULL);
INSERT INTO `options` VALUES (5,1,5,1,NULL,'Admin','/user/login',NULL);

INSERT INTO `options` VALUES (11,2,1,1,NULL,'Administration','/home/admin',NULL);
INSERT INTO `options` VALUES (12,2,2,2,NULL,'Site Pages','/arts/admin',NULL);
INSERT INTO `options` VALUES (17,2,3,4,NULL,'Users','/user/admin',NULL);
INSERT INTO `options` VALUES (15,2,4,5,NULL,'Menus','/menu/admin',NULL);
INSERT INTO `options` VALUES (16,2,5,5,NULL,'Current Hits','/hits/admin',NULL);
INSERT INTO `options` VALUES (18,2,6,5,NULL,'Requests','/req/admin',NULL);
INSERT INTO `options` VALUES (19,2,7,1,NULL,'Logout','/user/logout',NULL);

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
  PRIMARY KEY (`realmid`),
  KEY `IXREALM` (`realm`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `realms`
--

INSERT INTO `realms` VALUES (1,'public','Public Interface','home-main');
INSERT INTO `realms` VALUES (2,'admin','Admin Interface','home-admin');

--
-- Table structure for table `requests`
--

DROP TABLE IF EXISTS `requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests` (
  `requestid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `section` varchar(15) NOT NULL,
  `command` varchar(15) NOT NULL,
  `actions` varchar(1000) DEFAULT NULL,
  `layout` varchar(255) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `onsuccess` varchar(32) DEFAULT NULL,
  `onerror` varchar(32) DEFAULT NULL,
  `onfailure` varchar(32) DEFAULT NULL,
  `secure` enum('off','on','either','both') DEFAULT 'off',
  `rewrite` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`requestid`),
  KEY `sectcomm` (`section`,`command`)
) ENGINE=MyISAM AUTO_INCREMENT=84 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` VALUES (1,'link','admin','Links::Admin','','links/link_adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (2,'link','csave',',Links::CatSave','','','link-cedit','link-cedit','','off','');
INSERT INTO `requests` VALUES (3,'link','cadmin','Links::CatAdmin','','links/cat_adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (4,'link','add','Links::Add','','links/link_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (5,'link','edit','Links::Edit','','links/link_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (6,'link','cadd','','','links/cat_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (7,'link','main','Links::List','','links/link_list.html','','','','off','');
INSERT INTO `requests` VALUES (8,'link','cedit','Links::CatEdit','','links/cat_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (9,'link','save','Links::CheckLink,Links::Save','','','link-edit','link-edit','','off','');
INSERT INTO `requests` VALUES (10,'link','delete','Links::Delete','','','link-admin','','','off','');
INSERT INTO `requests` VALUES (11,'imgs','save','Images::Save','','','imgs-admin','','imgs-failure','off','');
INSERT INTO `requests` VALUES (12,'imgs','admin','Images::List','','images/image-list.html','','','','off','');
INSERT INTO `requests` VALUES (13,'imgs','failure','','','images/image-failure.html','','','','off','');
INSERT INTO `requests` VALUES (14,'imgs','add','Images::Add','','images/image-edit.html','','','','off','');
INSERT INTO `requests` VALUES (15,'imgs','delete','Images::Delete','','','imgs-admin','','imgs-failure','off','');
INSERT INTO `requests` VALUES (16,'imgs','edit','Images::Edit','','images/image-edit.html','','','','off','');
INSERT INTO `requests` VALUES (17,'cpan','distunk','','','cpan/distro-unknown.html','','','','off','');
INSERT INTO `requests` VALUES (18,'cpan','authors','CPAN::Authors::List','','cpan/author-list.html','','','','off','');
INSERT INTO `requests` VALUES (19,'cpan','report','CPAN::Report::View','','cpan/report-view.html','','','','off','');
INSERT INTO `requests` VALUES (20,'cpan','distro','CPAN::Distros::Reports','','cpan/distro-reports.html','','','','off','');
INSERT INTO `requests` VALUES (21,'cpan','authunk','','','cpan/author-unknown.html','','','','off','');
INSERT INTO `requests` VALUES (22,'cpan','distros','CPAN::Distros::List','','cpan/distro-list.html','','','','off','');
INSERT INTO `requests` VALUES (23,'cpan','author','CPAN::Authors::Reports','','cpan/author-reports.html','','','','off','');
INSERT INTO `requests` VALUES (24,'menu','save','Menus::Save','','','menu-edit','menu-edit','','off','');
INSERT INTO `requests` VALUES (25,'menu','admin','Menus::Admin','','menus/menu_adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (26,'menu','add','Menus::Add','','menus/menu_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (27,'menu','delete','Menus::Delete','','','menu-admin','','','off','');
INSERT INTO `requests` VALUES (28,'menu','edit','Menus::Edit','','menus/menu_adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (29,'arts','save','Articles::Site::Save','','','arts-edit','arts-edit','arts-failure','','');
INSERT INTO `requests` VALUES (30,'arts','admin','Articles::Site::Admin','','articles/arts-adminlist.html','','','','','');
INSERT INTO `requests` VALUES (31,'arts','failure','','','articles/arts-failure.html','','','','off','');
INSERT INTO `requests` VALUES (32,'arts','add','Articles::Site::Add','','articles/arts-adminedit.html','','','','','');
INSERT INTO `requests` VALUES (33,'arts','delete','Articles::Site::Delete','','','arts-admin','','arts-failure','','');
INSERT INTO `requests` VALUES (34,'arts','item','Articles::Site::Item','','articles/arts-item.html','','','','','');
INSERT INTO `requests` VALUES (35,'arts','edit','Articles::Site::Edit','','articles/arts-adminedit.html','','','','','');
INSERT INTO `requests` VALUES (36,'hits','admin','Hits::AdminHits','','hits/hits_admin.html','','','','','');
INSERT INTO `requests` VALUES (37,'user','add','Users::Add','','users/user-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (38,'user','acldel','Users::ACLDelete','','','user-acl','user-acl','user-acl','off','');
INSERT INTO `requests` VALUES (39,'user','item','Users::Item','','users/user-item.html','','','','off','');
INSERT INTO `requests` VALUES (40,'user','edit','Users::Edit','','users/user-edit.html','','','','off','');
INSERT INTO `requests` VALUES (41,'user','aclsave','Users::ACLSave','','','user-acl','user-acl','user-acl','off','');
INSERT INTO `requests` VALUES (42,'user','save','Users::Save','','','user-adminedit','user-adminedit','user-failure','off','');
INSERT INTO `requests` VALUES (43,'user','failure','','','users/user-failure.html','','','','off','');
INSERT INTO `requests` VALUES (44,'user','chng','Users::Password','','','user-edit','user-pass','','off','');
INSERT INTO `requests` VALUES (45,'user','logout','Users::Logout','','','home-main','','','off','');
INSERT INTO `requests` VALUES (46,'user','list','Users::UserLists','','users/user-list.html','','','','off','');
INSERT INTO `requests` VALUES (47,'user','admin','Users::Admin','','users/user-adminlist.html','','','','off','');
INSERT INTO `requests` VALUES (48,'user','pass','Users::Name','','users/user-pass.html','','','','off','');
INSERT INTO `requests` VALUES (49,'user','acl','Users::ACL','','users/user-acl.html','','','','off','');
INSERT INTO `requests` VALUES (50,'user','ban','Users::Ban','','','user-admin','','user-failure','off','');
INSERT INTO `requests` VALUES (51,'user','login','','','users/user-login.html','','','','off','');
INSERT INTO `requests` VALUES (52,'user','amend','Users::Save','','','user-edit','user-editerror','user-failure','off','');
INSERT INTO `requests` VALUES (53,'user','logged','Users::Login,Users::Retrieve','','','','user-login','user-login','off','');
INSERT INTO `requests` VALUES (54,'user','delete','Users::Delete','','','user-admin','','user-failure','off','');
INSERT INTO `requests` VALUES (55,'user','adminedit','Users::Edit','','users/user-adminedit.html','','','','off','');
INSERT INTO `requests` VALUES (56,'realm','admin','Content::GetVersion,Menus::LoadMenus','admin/layout.html','','','','','off','');
INSERT INTO `requests` VALUES (57,'realm','popup','','public/popup.html','','','','','off','');
INSERT INTO `requests` VALUES (58,'realm','public','Content::GetVersion,Hits::SetHits,Menus::LoadMenus','public/layout.html','','','','','off','');
INSERT INTO `requests` VALUES (59,'realm','wide','','public/layout-wide.html','','','','','off','');
INSERT INTO `requests` VALUES (60,'error','badmail','','','public/badmail.html','','','','off','');
INSERT INTO `requests` VALUES (61,'error','badcmd','','','public/badcommand.html','','','','off','');
INSERT INTO `requests` VALUES (62,'error','banuser','','','public/banuser.html','','','','off','');
INSERT INTO `requests` VALUES (63,'error','badaccess','Users::LoggedIn','','public/badaccess.html','','error-login','','off','');
INSERT INTO `requests` VALUES (64,'error','baduser','','','public/baduser.html','','','','off','');
INSERT INTO `requests` VALUES (65,'error','login','Users::Store','','users/user-login.html','','','','off','');
INSERT INTO `requests` VALUES (66,'error','message','','','public/error_message.html','','','','off','');
INSERT INTO `requests` VALUES (67,'home','admin','','','admin/backend_index.html','','','','off','');
INSERT INTO `requests` VALUES (68,'home','prefs','CPAN::Authors::Basic','','cpan/prefs.html','','','','off','');
INSERT INTO `requests` VALUES (69,'home','status','CPAN::Authors::Status','','content/status.html','','','','off','');
INSERT INTO `requests` VALUES (70,'home','main','CPAN::Authors::Status','','content/welcome.html','','','','off','');
INSERT INTO `requests` VALUES (71,'req','admin','Requests::Admin',NULL,'request/request_adminlist.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (72,'req','add','Requests::Add',NULL,'request/request_adminedit.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (73,'req','edit','Requests::Edit',NULL,'request/request_adminedit.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (74,'req','save','Requests::Save',NULL,'','req-edit','req-edit',NULL,'off',NULL);
INSERT INTO `requests` VALUES (75,'req','delete','Requests::Delete',NULL,'','req-admin','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (76,'user','adminpass','Users::AdminPass',NULL,'users/user-adminpass.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (77,'user','adminchng','Users::AdminChng',NULL,'','user-adminedit','user-adminpass',NULL,'off',NULL);
INSERT INTO `requests` VALUES (78,'cpan','drss','CPAN::Report::DistroRSS',NULL,'public/blank.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (79,'cpan','arss','CPAN::Report::AuthorRSS',NULL,'public/blank.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (80,'realm','yaml','','public/layout.yaml','','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (81,'realm','rss','','public/layout.rss','','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (82,'cpan','dyml','CPAN::Report::DistroYAML',NULL,'public/blank.html','','',NULL,'off',NULL);
INSERT INTO `requests` VALUES (83,'cpan','ayml','CPAN::Report::AuthorYAML',NULL,'public/blank.html','','',NULL,'off',NULL);

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
-- Dumping data for table `updates`
--

INSERT INTO `updates` VALUES (1,'site',0,1216750322,'2008-07-22 18:12:02');

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
  `search` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`userid`),
  KEY `IXACCESS` (`accessid`),
  KEY `IXIMAGE` (`imageid`),
  KEY `IXEMAIL` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES (1,5,1,'','Master','master@missbarbell.co.uk','admin','c00a8735efadd488c3251ef24211cd2e7baa9e66','','',0);
INSERT INTO `users` VALUES (2,1,1,'Guest','guest','GUEST','public','c8d6ea7f8e6850e9ed3b642900ca27683a257201','','',0);

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-03-02 22:17:03
