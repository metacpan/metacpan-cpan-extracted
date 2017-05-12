-- MySQL dump 10.11
--
-- Host: localhost    Database: auth_any
-- ------------------------------------------------------
-- Server version	5.0.51a-24+lenny5

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
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `user` (
  `UID` int(11) NOT NULL auto_increment,
  `username` varchar(32) NOT NULL,
  `created` datetime NOT NULL,
  `active` tinyint(1) default NULL,
  `timeout` int(11) default NULL,
  `firstName` tinytext,
  `lastName` tinytext,
  PRIMARY KEY  (`UID`),
  UNIQUE KEY `username` (`username`)
) ENGINE=MyISAM AUTO_INCREMENT=166 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `userAACookie`
--

DROP TABLE IF EXISTS `userAACookie`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `userAACookie` (
  `PID` varchar(100) NOT NULL,
  `SID` tinytext,
  `authId` varchar(100) default NULL,
  `authProvider` varchar(100) default NULL,
  `last` int(11) default NULL,
  `created` datetime NOT NULL,
  `state` enum('logged_out','recognized','authenticated') NOT NULL default 'logged_out',
  `logoutKey` tinytext NOT NULL,
  PRIMARY KEY  (`PID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `userIdent`
--

DROP TABLE IF EXISTS `userIdent`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `userIdent` (
  `UID` int(10) unsigned NOT NULL,
  `authId` varchar(100) NOT NULL,
  `authProvider` varchar(100) NOT NULL,
  PRIMARY KEY  (`authId`,`authProvider`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `userRole`
--

DROP TABLE IF EXISTS `userRole`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `userRole` (
  `UID` int(11) NOT NULL,
  `role` varchar(200) NOT NULL,
  UNIQUE KEY `UID_2` (`UID`,`role`),
  KEY `UID` (`UID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `userRoleChoice`
--

DROP TABLE IF EXISTS `userRoleChoice`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `userRoleChoice` (
  `UID` int(11) NOT NULL,
  `role` varchar(200) NOT NULL,
  UNIQUE KEY `UID` (`UID`,`role`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-03-28 21:05:05
