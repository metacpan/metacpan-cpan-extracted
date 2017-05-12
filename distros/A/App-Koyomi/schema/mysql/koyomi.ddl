-- MySQL dump 10.13  Distrib 5.6.24, for osx10.9 (x86_64)
--
-- Host: localhost    Database: koyomi
-- ------------------------------------------------------
-- Server version	5.6.24

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
-- Table structure for table `job_times`
--

DROP TABLE IF EXISTS `job_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_times` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_id` int(10) unsigned NOT NULL,
  `year` varchar(4) NOT NULL DEFAULT '*' COMMENT 'Ex) 2015',
  `month` varchar(2) NOT NULL DEFAULT '*' COMMENT 'Ex) 3, 12',
  `day` varchar(2) NOT NULL DEFAULT '*' COMMENT 'Day in month. Ex) 2, 31',
  `hour` varchar(2) NOT NULL DEFAULT '*' COMMENT 'Hour in day. Ex) 0, 12, 23',
  `minute` varchar(2) NOT NULL DEFAULT '*' COMMENT 'Ex) 0, 59',
  `weekday` varchar(1) NOT NULL DEFAULT '*' COMMENT 'Day of week as number. Compatiable with crontab. Ex) 0, 6, 7',
  `created_on` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY idx_job_id (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_times`
--

LOCK TABLES `job_times` WRITE;
/*!40000 ALTER TABLE `job_times` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_times` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` varchar(32) NOT NULL DEFAULT '' COMMENT 'Command executor in the system',
  `command` varchar(4096) NOT NULL COMMENT 'Shell command to execute',
  `memo` varchar(512) NOT NULL DEFAULT '',
  `created_on` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `semaphores`
--

DROP TABLE IF EXISTS `semaphores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `semaphores` (
  `job_id` int(10) unsigned NOT NULL COMMENT 'jobs.id',
  `number` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'Semaphore resource remains (Not in use)',
  `run_host` varchar(256) NOT NULL DEFAULT '' COMMENT 'On which host the last job ran',
  `run_pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Tha last process id',
  `run_date` datetime NOT NULL DEFAULT '1970-01-01 00:00:00',
  `created_on` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `semaphores`
--

LOCK TABLES `semaphores` WRITE;
/*!40000 ALTER TABLE `semaphores` DISABLE KEYS */;
/*!40000 ALTER TABLE `semaphores` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-05-30  0:47:08
