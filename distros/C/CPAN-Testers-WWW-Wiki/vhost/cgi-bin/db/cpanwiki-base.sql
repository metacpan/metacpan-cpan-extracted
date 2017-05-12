-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: cpanwiki
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
INSERT INTO `groups` VALUES (3,'editors',1,'Editor');
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
  `photoid` int(11) NOT NULL DEFAULT '0',
  `counter` int(11) DEFAULT NULL,
  `area` varchar(32) DEFAULT '',
  `query` varchar(255) DEFAULT '',
  `createdate` varchar(255) DEFAULT '0',
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
  PRIMARY KEY (`imageid`,`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imetadata`
--


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
-- Dumping data for table `ipindex`
--


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
  KEY `IXGRP` (`groupid`)
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
-- Table structure for table `optimages`
--

DROP TABLE IF EXISTS `optimages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `optimages` (
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `typeid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`optionid`,`typeid`)
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
  `text` varchar(255) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`optionid`),
  KEY `IXMENU` (`menuid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

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
-- Table structure for table `renderer`
--

DROP TABLE IF EXISTS `renderer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `renderer` (
  `renderid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `renderer` varchar(255) NOT NULL DEFAULT '',
  `plugin` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`renderid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `renderer`
--

INSERT INTO `renderer` VALUES (1,'Wiki Text','Wiki::WikiText');

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
  KEY `IXTIMEOUT` (`timeout`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

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
  PRIMARY KEY (`upid`)
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
  `search` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`userid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES (1,5,1,'','Master','barbie@cpantesters.org',NULL,'SECRET','http://wiki.cpantesters.org','Master Wiki Admin',0);
INSERT INTO `users` VALUES (2,1,1,'','Guest','GUEST','public','c8d6ea7f8e6850e9ed3b642900ca27683a257201','','',0);

--
-- Table structure for table `wikiindex`
--

DROP TABLE IF EXISTS `wikiindex`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikiindex` (
  `pagename` varchar(255) NOT NULL DEFAULT '',
  `version` int(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`pagename`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wikiindex`
--

INSERT INTO `wikiindex` VALUES ('AdminRequests',1);
INSERT INTO `wikiindex` VALUES ('HomePage',1);
INSERT INTO `wikiindex` VALUES ('SandBox',1);
INSERT INTO `wikiindex` VALUES ('SiteCredits',1);
INSERT INTO `wikiindex` VALUES ('WikiFormat',1);

--
-- Table structure for table `wikipage`
--

DROP TABLE IF EXISTS `wikipage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikipage` (
  `pagename` varchar(255) NOT NULL DEFAULT '',
  `version` int(4) NOT NULL DEFAULT '1',
  `locked` int(1) NOT NULL DEFAULT '0',
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `createdate` int(10) DEFAULT '0',
  `comment` varchar(255) DEFAULT NULL,
  `content` blob,
  PRIMARY KEY (`pagename`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wikipage`
--

INSERT INTO `wikipage` VALUES ('AdminRequests',1,0,1,1179853525,'','Are there any feature requests, bug fixes or other items you would like the site admins to look at? We cannot guarantee a rapid response, but this will be a good place to record any issues, so that they can be addressed as soon as possible. Urgent requests can be sent to [[user:1|Barbie]].');
INSERT INTO `wikipage` VALUES ('SiteCredits',1,0,1,1179853525,'','== Site Credits ==\n\n=== Layout &amp; Design ===\n\nSite layout by Barbie, from an original CSS/XHTML Template Design by Arcsin ([http://templates.arcsin.se] and [http://www.oswd.org/user/profile/id/8377]) and released under a Creative Commons Attribution 2.5 License.\n\nMajor help and much appreciation in getting the CSS working from Kake and Colin.\n\nSmoke Box image copyright (c) Tyson Ibele 2004 ([http://www.tysonibele.com/Main/gallery.htm])\n\n=== Code Base ===\n\nThe underlying wiki code is powered by Labyrinth, a website management tool, developed by Miss Barbell Productions.\n\n=== Contributions ===\n\nThis website was started thanks to the contributions and suggestions of:\n\n* Adam Kennedy\n* Audrey Tang\n* Barbie\n* Chris Williams\n* David Cantrell\n* David Golden\n* Jos Bormans\n* L&eacute;on Brocard\n\nWith greatful thanks to the CPAN Testers community for their continued support in the testing of so many CPAN distributions.\n\n=== Bugs, Fixes &amp; Patches ===\n\nIf you spot any problems or have any suggestions for new or improved features within the site, please email Barbie.');
INSERT INTO `wikipage` VALUES ('WikiFormat',1,0,1,1179853525,'','== Wiki Format ==\n\n=== Headings ===\n\n  == Heading 1 / H1 ==\n  === Heading 2 / H2 ===\n  ==== Heading 3 / H3 ====\n  ===== Heading 4 / H4 =====\n  ====== Heading 5 / H5 ======\n  ======= Heading 6 / H6 =======\n\n=== Text Formatting ===\n\n  \'\'Italic\'\'\n  \'\'\'Bold\'\'\'\n  \'\'\'\'\'Italic &amp; Bold\'\'\'\'\'\n  !!code text!!\n\n=== Links ===\n\n!  [[PAGENAME]]                       - inline wiki page link\n!  [[PAGENAME|Page Name Spaced Text]] - named wiki page link\n!  [http://link]                      - inline link\n!  [http://link link spaced text]     - named link\n\nSpecial links can also be used as shortcuts:\n\n!  [[cpan:My-CPAN-Module]]                   - <a href=\"http://search.cpan.org/dist/My-CPAN-Module\">My-CPAN-Module</a>\n!  [[cpan:This-Really-Long-Name|Short Name]] - <a href=\"http://search.cpan.org/dist/This-Really-Long-Name\">Short Name</a>\n!  [[cpan:~pauseid]]                         - <a href=\"http://search.cpan.org/~pauseid\">pauseid</a>\n!  [[cpan:~pauseid|Author Name]]             - <a href=\"http://search.cpan.org/~pauseid\">Author Name</a>\n!  [[perldoc:index]]                         - <a href=\"http://perldoc.perl.org?index\">index</a>\n!  [[user:1]]                                - <a href=\"/cgi-bin/pages.cgi?act=user-item&amp;userid=1\">Barbie</a>\n\n=== Points ===\n\n  * first level bullet point\n  ** second level bullet point\n  # first level numbered point\n  ## second level numbered point\n\nMaximum limit to a depth of 6 levels.\n\n=== Redirection ===\n\n!  #REDIRECT [[PAGENAME]]\n\n=== Blocks ===\n\n  &quot; quotation\n  &quot; &quot;quoted quotation&quot;\n\n\n    code block (2 spaces)\n\n! ! code block (no link interpretation)');
INSERT INTO `wikipage` VALUES ('HomePage',1,0,1,1179853525,'','== The CPAN Testers Wiki ==\n\nThis wiki is the online reference for everything related to CPAN Testing. HowTos, Tutorials, FAQs and Notes are all here to help both beginners and experienced CPAN testers.\n\nIf there is any aspect of CPAN Testing missing from this site you are encourage to update it. The wiki is backed up, so don\'t worry about getting it wrong. Either we can edit the page or restore the content.\n\nDue to the amount of wiki spam that gets generated these days, you will need to [[Login]] to change page contents. Note that your login does not need to be anything complex, as it is merely an aid to stopping the spammers, but we would request you use something that can identify you to the community, such as a PAUSEID.\n\nSome pages are admin protected, such as the Home page, so if you feel they require an update, please email [mailto:barbie@missarbell.co.uk Barbie] with the details.\n\n  ====================================================\n  PLEASE NOTE THIS PAGE IS A STARTING POINT FOR A WIKI\n  ====================================================\n\n\n=== Contents ===\n\n* To Be Added\n\n=== Additional Pages ===\n\n==== Notes ====\n\n* [[AdminRequests]]\n* [[SandBox]]\n\n==== Retired Pages ====\n\n* ?');
INSERT INTO `wikipage` VALUES ('SandBox',1,0,1,1179853525,'','Test of cpan link: [[cpan:Test-Unit]]');

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-02-22  9:27:36
