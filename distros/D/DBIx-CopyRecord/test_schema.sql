-- MySQL dump 10.10
--
-- Host: localhost    Database: amsu
-- ------------------------------------------------------
-- Server version	5.0.27

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
-- Table structure for table `xq9_invoice_detail`
--

DROP TABLE IF EXISTS `xq9_invoice_detail`;
CREATE TABLE `xq9_invoice_detail` (
  `invoice_detail_id` int(10) unsigned NOT NULL auto_increment,
  `invoice_number` int(10) unsigned NOT NULL,
  `product_number` int(10) unsigned NOT NULL,
  `qry` int(10) unsigned NOT NULL,
  `price` decimal(10,0) NOT NULL,
  `ext_price` decimal(10,0) NOT NULL,
  PRIMARY KEY  (`invoice_detail_id`),
  KEY `Index_2` (`invoice_number`),
  CONSTRAINT `FK_xq9_invoice_detail_1` FOREIGN KEY (`invoice_number`) REFERENCES `xq9_invoice_master` (`invoice_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=FIXED;

--
-- Dumping data for table `xq9_invoice_detail`
--

LOCK TABLES `xq9_invoice_detail` WRITE;
/*!40000 ALTER TABLE `xq9_invoice_detail` DISABLE KEYS */;
INSERT INTO `xq9_invoice_detail` VALUES (1,1,12345,1,'10','10'),(1921,61,12345,1,'10','10'),(1922,62,12345,1,'10','10'),(1923,63,12345,1,'10','10');
/*!40000 ALTER TABLE `xq9_invoice_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `xq9_invoice_master`
--

DROP TABLE IF EXISTS `xq9_invoice_master`;
CREATE TABLE `xq9_invoice_master` (
  `invoice_number` int(10) unsigned NOT NULL auto_increment,
  `client_number` int(10) unsigned NOT NULL,
  `invoice_date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `billed` char(1) NOT NULL default 'N',
  PRIMARY KEY  (`invoice_number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `xq9_invoice_master`
--

LOCK TABLES `xq9_invoice_master` WRITE;
/*!40000 ALTER TABLE `xq9_invoice_master` DISABLE KEYS */;
INSERT INTO `xq9_invoice_master` VALUES (1,7874,'2007-01-07 05:41:00','N'),(2,7874,'2007-01-07 05:41:00','N'),(3,7874,'2007-01-07 05:41:00','N'),(4,7874,'2007-01-07 05:41:00','N'),(5,7874,'2007-01-07 05:41:00','N'),(6,7874,'2007-01-07 05:41:00','N'),(7,7874,'2007-01-07 05:41:00','N'),(8,7874,'2007-01-07 05:41:00','Y'),(9,7874,'0000-00-00 00:00:00','Y'),(10,7874,'0000-00-00 00:00:00','Y'),(11,7874,'2007-01-21 10:34:13','Y'),(12,7874,'2007-01-21 12:07:10','Y'),(13,7874,'2007-01-21 12:07:10','Y'),(14,7874,'2007-01-21 12:10:46','Y'),(15,7874,'2007-01-21 12:10:46','Y'),(16,7874,'2007-01-21 12:11:53','Y'),(17,7874,'2007-01-21 12:11:53','Y'),(18,7874,'2007-01-21 12:15:56','Y'),(19,7874,'2007-01-21 12:15:56','Y'),(20,7874,'2007-01-21 12:16:47','Y'),(21,7874,'2007-01-21 12:16:47','Y'),(22,7874,'2007-01-21 12:24:15','Y'),(23,7874,'2007-01-21 12:24:15','Y'),(24,7874,'2007-01-21 12:25:40','Y'),(25,7874,'2007-01-21 12:25:40','Y'),(26,7874,'2007-01-22 01:54:04','Y'),(27,7874,'2007-01-22 01:54:04','Y'),(28,7874,'2007-01-22 04:40:02','Y'),(29,7874,'2007-01-22 04:46:14','Y'),(30,7874,'2007-01-22 04:50:37','Y'),(31,7874,'2007-01-25 06:32:58','Y'),(32,7874,'2007-01-25 06:33:25','Y'),(33,7874,'2007-01-31 07:12:40','Y'),(34,7874,'2007-01-07 05:41:00','N'),(35,7874,'2007-01-07 05:41:00','N'),(36,7874,'2007-01-07 05:41:00','N'),(37,7874,'2007-01-31 07:41:29','Y'),(38,7874,'2007-01-31 07:52:18','Y'),(39,7874,'2007-01-31 08:07:20','Y'),(40,7874,'2007-01-31 08:21:37','Y'),(41,7874,'2007-01-31 08:22:34','Y'),(42,7874,'2007-02-01 02:55:06','Y'),(43,7874,'2007-02-01 05:13:13','Y'),(44,7874,'2007-02-01 05:19:59','Y'),(45,7874,'2007-02-01 05:29:36','Y'),(46,7874,'2007-02-07 04:41:44','Y'),(47,7874,'2007-02-07 04:41:49','Y'),(48,7874,'2007-02-11 07:06:33','Y'),(49,7874,'2007-02-11 07:07:56','Y'),(50,7874,'2007-02-11 07:12:16','Y'),(51,7874,'2007-02-11 07:13:41','Y'),(52,7874,'2007-02-11 07:14:00','Y'),(53,7874,'2007-02-11 07:14:15','Y'),(54,7874,'2007-02-13 05:59:05','Y'),(55,7874,'2007-02-18 23:39:13','Y'),(56,7874,'2007-02-19 00:08:22','Y'),(57,7874,'2007-02-19 00:18:17','Y'),(58,7874,'2007-02-19 04:19:20','Y'),(59,7874,'2007-04-17 22:16:13','Y'),(60,7874,'2007-05-05 08:26:43','Y'),(61,7874,'2007-05-05 08:38:40','Y'),(62,7874,'2007-05-05 08:51:54','Y'),(63,7874,'2007-05-05 08:53:11','Y');
/*!40000 ALTER TABLE `xq9_invoice_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `xq9_ship_to`
--

DROP TABLE IF EXISTS `xq9_ship_to`;
CREATE TABLE `xq9_ship_to` (
  `ship_to_id` int(10) unsigned NOT NULL auto_increment,
  `invoice_number` int(10) unsigned NOT NULL,
  `salutation` char(4) NOT NULL,
  `fname` varchar(15) NOT NULL,
  `lname` varchar(25) NOT NULL,
  `address1` varchar(45) NOT NULL,
  `address2` varchar(45) NOT NULL,
  `city` varchar(25) NOT NULL,
  `state` char(2) NOT NULL,
  `zip` char(9) NOT NULL,
  PRIMARY KEY  (`ship_to_id`),
  KEY `FK_xq9_ship_to_1` (`invoice_number`),
  CONSTRAINT `FK_xq9_ship_to_1` FOREIGN KEY (`invoice_number`) REFERENCES `xq9_invoice_master` (`invoice_number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `xq9_ship_to`
--

LOCK TABLES `xq9_ship_to` WRITE;
/*!40000 ALTER TABLE `xq9_ship_to` DISABLE KEYS */;
INSERT INTO `xq9_ship_to` VALUES (1,1,'MR','JOHN','CONSUMER','123 N. MAIN ST','SUITE 100','PASADENA','CA','91103'),(481,61,'MR','JOHN','CONSUMER','123 N. MAIN ST','SUITE 100','PASADENA','CA','91103'),(482,62,'MR','JOHN','CONSUMER','123 N. MAIN ST','SUITE 100','PASADENA','CA','91103'),(483,63,'MR','JOHN','CONSUMER','123 N. MAIN ST','SUITE 100','PASADENA','CA','91103');
/*!40000 ALTER TABLE `xq9_ship_to` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `xq9_instructions`
--

DROP TABLE IF EXISTS `xq9_instructions`;
CREATE TABLE `xq9_instructions` (
  `instruction_id` int(10) unsigned NOT NULL auto_increment,
  `invoice_number` int(10) unsigned NOT NULL,
  `instructions` text NOT NULL,
  PRIMARY KEY  (`instruction_id`),
  KEY `FK_xq9_instructions_1` (`invoice_number`),
  CONSTRAINT `FK_xq9_instructions_1` FOREIGN KEY (`invoice_number`) REFERENCES `xq9_invoice_master` (`invoice_number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `xq9_instructions`
--

LOCK TABLES `xq9_instructions` WRITE;
/*!40000 ALTER TABLE `xq9_instructions` DISABLE KEYS */;
INSERT INTO `xq9_instructions` VALUES (1,1,'SHIP ASAP; AIRPORT COUNTER-TO-COUNTER'),(469,61,'SHIP ASAP; AIRPORT COUNTER-TO-COUNTER'),(470,62,'SHIP ASAP; AIRPORT COUNTER-TO-COUNTER'),(471,63,'SHIP ASAP; AIRPORT COUNTER-TO-COUNTER');
/*!40000 ALTER TABLE `xq9_instructions` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-05-05 15:22:12
