-- MySQL dump 10.11
--
-- Host: localhost    Database: test
-- ------------------------------------------------------
-- Server version	5.0.67

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
-- Table structure for table `Bio_MAGETAB_ArrayDesign`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ArrayDesign`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ArrayDesign` (
  `id` int(11) NOT NULL,
  `provider` varchar(255) default NULL,
  `substrateType_type` int(11) default NULL,
  `sequencePolymerType_type` int(11) default NULL,
  `printingProtocol` text,
  `version` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `substrateType` int(11) default NULL,
  `technologyType` int(11) default NULL,
  `surfaceType` int(11) default NULL,
  `sequencePolymerType` int(11) default NULL,
  `uri` varchar(255) default NULL,
  `surfaceType_type` int(11) default NULL,
  `technologyType_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DatabaseEntry` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`substrateType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`surfaceType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`technologyType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`sequencePolymerType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ArrayDesign`
--

LOCK TABLES `Bio_MAGETAB_ArrayDesign` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ArrayDesign` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ArrayDesign` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Assay`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Assay`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Assay` (
  `id` int(11) NOT NULL,
  `arrayDesign_type` int(11) default NULL,
  `arrayDesign` int(11) default NULL,
  `technologyType_type` int(11) default NULL,
  `technologyType` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_Event` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`technologyType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`arrayDesign`) REFERENCES `Bio_MAGETAB_ArrayDesign` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Assay`
--

LOCK TABLES `Bio_MAGETAB_Assay` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Assay` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Assay` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_BaseClass`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_BaseClass`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_BaseClass` (
  `id` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `namespace` varchar(255) NOT NULL,
  `authority` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_BaseClass`
--

LOCK TABLES `Bio_MAGETAB_BaseClass` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_BaseClass` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_BaseClass` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Comment`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Comment`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Comment` (
  `id` int(11) NOT NULL,
  `Bio_MAGETAB_Node_comments_slot` int(11) default NULL,
  `Bio_MAGETAB_Investigation_comments_slot` int(11) default NULL,
  `Bio_MAGETAB_CompositeElement_comments` int(11) default NULL,
  `Bio_MAGETAB_Node_comments` int(11) default NULL,
  `Bio_MAGETAB_ParameterValue_comments_slot` int(11) default NULL,
  `Bio_MAGETAB_Contact_comments` int(11) default NULL,
  `Bio_MAGETAB_ParameterValue_comments` int(11) default NULL,
  `value` varchar(255) default NULL,
  `Bio_MAGETAB_Contact_comments_slot` int(11) default NULL,
  `name` varchar(255) default NULL,
  `Bio_MAGETAB_ArrayDesign_comments` int(11) default NULL,
  `Bio_MAGETAB_ArrayDesign_comments_slot` int(11) default NULL,
  `Bio_MAGETAB_ProtocolApplication_comments` int(11) default NULL,
  `Bio_MAGETAB_ProtocolApplication_comments_slot` int(11) default NULL,
  `Bio_MAGETAB_Investigation_comments` int(11) default NULL,
  `Bio_MAGETAB_CompositeElement_comments_slot` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`Bio_MAGETAB_Node_comments`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_CompositeElement_comments`) REFERENCES `Bio_MAGETAB_CompositeElement` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_ParameterValue_comments`) REFERENCES `Bio_MAGETAB_ParameterValue` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_Contact_comments`) REFERENCES `Bio_MAGETAB_Contact` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_ArrayDesign_comments`) REFERENCES `Bio_MAGETAB_ArrayDesign` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_ProtocolApplication_comments`) REFERENCES `Bio_MAGETAB_ProtocolApplication` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_Investigation_comments`) REFERENCES `Bio_MAGETAB_Investigation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Comment`
--

LOCK TABLES `Bio_MAGETAB_Comment` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_CompositeElement`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_CompositeElement`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_CompositeElement` (
  `id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_CompositeElement`
--

LOCK TABLES `Bio_MAGETAB_CompositeElement` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_CompositeElement` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_CompositeElement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_CompositeElement_compositeElements`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_CompositeElement_compositeElements`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_CompositeElement_compositeElements` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Reporter` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_CompositeElement` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_CompositeElement_compositeElements`
--

LOCK TABLES `Bio_MAGETAB_CompositeElement_compositeElements` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_CompositeElement_compositeElements` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_CompositeElement_compositeElements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Contact`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Contact`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Contact` (
  `id` int(11) NOT NULL,
  `firstName` varchar(255) default NULL,
  `midInitials` varchar(255) default NULL,
  `phone` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `fax` varchar(255) default NULL,
  `lastName` varchar(255) default NULL,
  `address` varchar(511) default NULL,
  `organization` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Contact`
--

LOCK TABLES `Bio_MAGETAB_Contact` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Contact_contacts`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Contact_contacts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Contact_contacts` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_Contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Contact_contacts`
--

LOCK TABLES `Bio_MAGETAB_Contact_contacts` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_contacts` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_contacts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Contact_performers`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Contact_performers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Contact_performers` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_ProtocolApplication` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_Contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Contact_performers`
--

LOCK TABLES `Bio_MAGETAB_Contact_performers` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_performers` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_performers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Contact_providers`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Contact_providers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Contact_providers` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Material` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_Contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Contact_providers`
--

LOCK TABLES `Bio_MAGETAB_Contact_providers` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_providers` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Contact_providers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm` (
  `id` int(11) NOT NULL,
  `value` varchar(255) default NULL,
  `category` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DatabaseEntry` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_characteristics`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_characteristics`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_characteristics` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Material` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_characteristics`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_characteristics` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_characteristics` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_characteristics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_designTypes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_designTypes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_designTypes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_designTypes`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_designTypes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_designTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_designTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_groups`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_groups` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Reporter` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_groups`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_groups` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_normalizationTypes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_normalizationTypes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_normalizationTypes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_normalizationTypes`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_normalizationTypes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_normalizationTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_normalizationTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_qualityControlTypes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_qualityControlTypes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_qualityControlTypes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_qualityControlTypes`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_qualityControlTypes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_qualityControlTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_qualityControlTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_replicateTypes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_replicateTypes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_replicateTypes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_replicateTypes`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_replicateTypes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_replicateTypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_replicateTypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ControlledTerm_roles`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ControlledTerm_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ControlledTerm_roles` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Contact` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ControlledTerm_roles`
--

LOCK TABLES `Bio_MAGETAB_ControlledTerm_roles` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_roles` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ControlledTerm_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Data`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Data`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Data` (
  `id` int(11) NOT NULL,
  `dataType` int(11) default NULL,
  `dataType_type` int(11) default NULL,
  `uri` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`dataType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Data`
--

LOCK TABLES `Bio_MAGETAB_Data` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Data` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DataFile`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DataFile`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DataFile` (
  `id` int(11) NOT NULL,
  `format` int(11) default NULL,
  `format_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_Data` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`format`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DataFile`
--

LOCK TABLES `Bio_MAGETAB_DataFile` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DataFile` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DataFile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DataMatrix`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DataMatrix`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DataMatrix` (
  `id` int(11) NOT NULL,
  `rowIdentifierType` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_Data` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DataMatrix`
--

LOCK TABLES `Bio_MAGETAB_DataMatrix` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DataMatrix` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DataMatrix` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DatabaseEntry`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DatabaseEntry`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DatabaseEntry` (
  `id` int(11) NOT NULL,
  `termSource_type` int(11) default NULL,
  `termSource` int(11) default NULL,
  `accession` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`termSource`) REFERENCES `Bio_MAGETAB_TermSource` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DatabaseEntry`
--

LOCK TABLES `Bio_MAGETAB_DatabaseEntry` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DatabaseEntry` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DatabaseEntry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DatabaseEntry_databaseEntries`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DatabaseEntry_databaseEntries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DatabaseEntry_databaseEntries` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_DatabaseEntry` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DatabaseEntry_databaseEntries`
--

LOCK TABLES `Bio_MAGETAB_DatabaseEntry_databaseEntries` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DatabaseEntry_databaseEntries` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DatabaseEntry_databaseEntries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DesignElement`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DesignElement`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DesignElement` (
  `id` int(11) NOT NULL,
  `startPosition` int(11) default NULL,
  `chromosome` varchar(255) default NULL,
  `endPosition` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DesignElement`
--

LOCK TABLES `Bio_MAGETAB_DesignElement` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DesignElement` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DesignElement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_DesignElement_designElements`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_DesignElement_designElements`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_DesignElement_designElements` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_ArrayDesign` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_DesignElement_designElements`
--

LOCK TABLES `Bio_MAGETAB_DesignElement_designElements` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_DesignElement_designElements` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_DesignElement_designElements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Edge`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Edge`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Edge` (
  `id` int(11) NOT NULL,
  `Bio_MAGETAB_Node_outputEdges` int(11) default NULL,
  `inputNode` int(11) default NULL,
  `Bio_MAGETAB_Node_inputEdges_slot` int(11) default NULL,
  `Bio_MAGETAB_Node_inputEdges` int(11) default NULL,
  `Bio_MAGETAB_Node_outputEdges_slot` int(11) default NULL,
  `inputNode_type` int(11) default NULL,
  `outputNode` int(11) default NULL,
  `outputNode_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`Bio_MAGETAB_Node_outputEdges`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`Bio_MAGETAB_Node_inputEdges`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`outputNode`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`inputNode`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Edge`
--

LOCK TABLES `Bio_MAGETAB_Edge` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Edge` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Edge` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Event`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Event`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Event` (
  `id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Event`
--

LOCK TABLES `Bio_MAGETAB_Event` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Event` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Factor`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Factor`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Factor` (
  `id` int(11) NOT NULL,
  `factorType_type` int(11) default NULL,
  `factorType` int(11) default NULL,
  `Bio_MAGETAB_Investigation_factors` int(11) default NULL,
  `name` varchar(255) default NULL,
  `Bio_MAGETAB_Investigation_factors_slot` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`factorType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_Investigation_factors`) REFERENCES `Bio_MAGETAB_Investigation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Factor`
--

LOCK TABLES `Bio_MAGETAB_Factor` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Factor` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Factor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_FactorValue`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_FactorValue`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_FactorValue` (
  `id` int(11) NOT NULL,
  `term_type` int(11) default NULL,
  `factor_type` int(11) default NULL,
  `measurement` int(11) default NULL,
  `measurement_type` int(11) default NULL,
  `term` int(11) default NULL,
  `factor` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`term`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`measurement`) REFERENCES `Bio_MAGETAB_Measurement` (`id`),
  FOREIGN KEY (`factor`) REFERENCES `Bio_MAGETAB_Factor` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_FactorValue`
--

LOCK TABLES `Bio_MAGETAB_FactorValue` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_FactorValue` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_FactorValue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_FactorValue_factorValues`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_FactorValue_factorValues`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_FactorValue_factorValues` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_SDRFRow` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_FactorValue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_FactorValue_factorValues`
--

LOCK TABLES `Bio_MAGETAB_FactorValue_factorValues` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_FactorValue_factorValues` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_FactorValue_factorValues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Feature`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Feature`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Feature` (
  `id` int(11) NOT NULL,
  `reporter_type` int(11) default NULL,
  `blockCol` int(11) default NULL,
  `blockRow` int(11) default NULL,
  `col` int(11) default NULL,
  `row` int(11) default NULL,
  `reporter` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`reporter`) REFERENCES `Bio_MAGETAB_Reporter` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Feature`
--

LOCK TABLES `Bio_MAGETAB_Feature` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Feature` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Feature` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Investigation`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Investigation`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Investigation` (
  `id` int(11) NOT NULL,
  `publicReleaseDate` varchar(255) default NULL,
  `date` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `description` text,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Investigation`
--

LOCK TABLES `Bio_MAGETAB_Investigation` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Investigation` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Investigation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_LabeledExtract`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_LabeledExtract`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_LabeledExtract` (
  `id` int(11) NOT NULL,
  `label_type` int(11) default NULL,
  `label` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_Material` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`label`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_LabeledExtract`
--

LOCK TABLES `Bio_MAGETAB_LabeledExtract` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_LabeledExtract` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_LabeledExtract` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Material`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Material`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Material` (
  `id` int(11) NOT NULL,
  `materialType_type` int(11) default NULL,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `materialType` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`materialType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Material`
--

LOCK TABLES `Bio_MAGETAB_Material` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Material` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Material` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_MatrixColumn`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_MatrixColumn`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_MatrixColumn` (
  `id` int(11) NOT NULL,
  `quantitationType_type` int(11) default NULL,
  `quantitationType` int(11) default NULL,
  `Bio_MAGETAB_DataMatrix_matrixColumns_slot` int(11) default NULL,
  `Bio_MAGETAB_DataMatrix_matrixColumns` int(11) default NULL,
  `columnNumber` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`quantitationType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_DataMatrix_matrixColumns`) REFERENCES `Bio_MAGETAB_DataMatrix` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_MatrixColumn`
--

LOCK TABLES `Bio_MAGETAB_MatrixColumn` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_MatrixColumn` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_MatrixColumn` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_MatrixRow`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_MatrixRow`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_MatrixRow` (
  `id` int(11) NOT NULL,
  `Bio_MAGETAB_DataMatrix_matrixRows` int(11) default NULL,
  `rowNumber` int(11) default NULL,
  `designElement_type` int(11) default NULL,
  `Bio_MAGETAB_DataMatrix_matrixRows_slot` int(11) default NULL,
  `designElement` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`designElement`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_DataMatrix_matrixRows`) REFERENCES `Bio_MAGETAB_DataMatrix` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_MatrixRow`
--

LOCK TABLES `Bio_MAGETAB_MatrixRow` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_MatrixRow` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_MatrixRow` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Measurement`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Measurement`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Measurement` (
  `id` int(11) NOT NULL,
  `Bio_MAGETAB_Material_measurements_slot` int(11) default NULL,
  `value` varchar(255) default NULL,
  `maxValue` varchar(255) default NULL,
  `unit_type` int(11) default NULL,
  `unit` int(11) default NULL,
  `minValue` varchar(255) default NULL,
  `measurementType` varchar(255) default NULL,
  `Bio_MAGETAB_Material_measurements` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`unit`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_Material_measurements`) REFERENCES `Bio_MAGETAB_Material` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Measurement`
--

LOCK TABLES `Bio_MAGETAB_Measurement` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Measurement` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Measurement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Node_nodes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Node_nodes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Node_nodes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_SDRFRow` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Node_nodes`
--

LOCK TABLES `Bio_MAGETAB_Node_nodes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Node_nodes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Node_nodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Node_referencedNodes`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Node_referencedNodes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Node_referencedNodes` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_MatrixColumn` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Node_referencedNodes`
--

LOCK TABLES `Bio_MAGETAB_Node_referencedNodes` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Node_referencedNodes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Node_referencedNodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ParameterValue`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ParameterValue`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ParameterValue` (
  `id` int(11) NOT NULL,
  `parameter` int(11) default NULL,
  `parameter_type` int(11) default NULL,
  `measurement` int(11) default NULL,
  `measurement_type` int(11) default NULL,
  `Bio_MAGETAB_ProtocolApplication_parameterValues_slot` int(11) default NULL,
  `Bio_MAGETAB_ProtocolApplication_parameterValues` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`parameter`) REFERENCES `Bio_MAGETAB_ProtocolParameter` (`id`),
  FOREIGN KEY (`measurement`) REFERENCES `Bio_MAGETAB_Measurement` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_ProtocolApplication_parameterValues`) REFERENCES `Bio_MAGETAB_ProtocolApplication` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ParameterValue`
--

LOCK TABLES `Bio_MAGETAB_ParameterValue` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ParameterValue` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ParameterValue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Protocol`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Protocol`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Protocol` (
  `id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  `contact` varchar(255) default NULL,
  `software` varchar(255) default NULL,
  `hardware` varchar(255) default NULL,
  `text` text,
  `protocolType` int(11) default NULL,
  `protocolType_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DatabaseEntry` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`protocolType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Protocol`
--

LOCK TABLES `Bio_MAGETAB_Protocol` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Protocol` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Protocol` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ProtocolApplication`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ProtocolApplication`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ProtocolApplication` (
  `id` int(11) NOT NULL,
  `protocol` int(11) default NULL,
  `date` varchar(255) default NULL,
  `protocol_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`protocol`) REFERENCES `Bio_MAGETAB_Protocol` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ProtocolApplication`
--

LOCK TABLES `Bio_MAGETAB_ProtocolApplication` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolApplication` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolApplication` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ProtocolApplication_protocolApplications`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ProtocolApplication_protocolApplications`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ProtocolApplication_protocolApplications` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Edge` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_ProtocolApplication` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ProtocolApplication_protocolApplications`
--

LOCK TABLES `Bio_MAGETAB_ProtocolApplication_protocolApplications` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolApplication_protocolApplications` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolApplication_protocolApplications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_ProtocolParameter`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_ProtocolParameter`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_ProtocolParameter` (
  `id` int(11) NOT NULL,
  `protocol` int(11) default NULL,
  `name` varchar(255) default NULL,
  `protocol_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`protocol`) REFERENCES `Bio_MAGETAB_Protocol` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_ProtocolParameter`
--

LOCK TABLES `Bio_MAGETAB_ProtocolParameter` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolParameter` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_ProtocolParameter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Protocol_protocols`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Protocol_protocols`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Protocol_protocols` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_Protocol` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Protocol_protocols`
--

LOCK TABLES `Bio_MAGETAB_Protocol_protocols` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Protocol_protocols` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Protocol_protocols` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Publication`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Publication`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Publication` (
  `id` int(11) NOT NULL,
  `authorList` varchar(511) default NULL,
  `pubMedID` varchar(255) default NULL,
  `DOI` varchar(255) default NULL,
  `status` int(11) default NULL,
  `status_type` int(11) default NULL,
  `title` varchar(511) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`status`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Publication`
--

LOCK TABLES `Bio_MAGETAB_Publication` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Publication` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Publication` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Publication_publications`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Publication_publications`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Publication_publications` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_Publication` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Publication_publications`
--

LOCK TABLES `Bio_MAGETAB_Publication_publications` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Publication_publications` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Publication_publications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_Reporter`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_Reporter`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_Reporter` (
  `id` int(11) NOT NULL,
  `controlType` int(11) default NULL,
  `sequence` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `controlType_type` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_DesignElement` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`controlType`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_Reporter`
--

LOCK TABLES `Bio_MAGETAB_Reporter` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_Reporter` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_Reporter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_SDRF`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_SDRF`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_SDRF` (
  `id` int(11) NOT NULL,
  `Bio_MAGETAB_Investigation_sdrfs_slot` int(11) default NULL,
  `Bio_MAGETAB_Investigation_sdrfs` int(11) default NULL,
  `uri` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`Bio_MAGETAB_Investigation_sdrfs`) REFERENCES `Bio_MAGETAB_Investigation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_SDRF`
--

LOCK TABLES `Bio_MAGETAB_SDRF` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRF` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRF` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_SDRFRow`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_SDRFRow`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_SDRFRow` (
  `id` int(11) NOT NULL,
  `rowNumber` int(11) default NULL,
  `Bio_MAGETAB_SDRF_sdrfRows_slot` int(11) default NULL,
  `Bio_MAGETAB_SDRF_sdrfRows` int(11) default NULL,
  `channel_type` int(11) default NULL,
  `channel` int(11) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`channel`) REFERENCES `Bio_MAGETAB_ControlledTerm` (`id`),
  FOREIGN KEY (`Bio_MAGETAB_SDRF_sdrfRows`) REFERENCES `Bio_MAGETAB_SDRF` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_SDRFRow`
--

LOCK TABLES `Bio_MAGETAB_SDRFRow` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRFRow` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRFRow` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_SDRFRow_sdrfRows`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_SDRFRow_sdrfRows`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_SDRFRow_sdrfRows` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_SDRFRow` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_SDRFRow_sdrfRows`
--

LOCK TABLES `Bio_MAGETAB_SDRFRow_sdrfRows` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRFRow_sdrfRows` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_SDRFRow_sdrfRows` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_TermSource`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_TermSource`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_TermSource` (
  `id` int(11) NOT NULL,
  `version` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `uri` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  FOREIGN KEY (`id`) REFERENCES `Bio_MAGETAB_BaseClass` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_TermSource`
--

LOCK TABLES `Bio_MAGETAB_TermSource` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_TermSource` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_TermSource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Bio_MAGETAB_TermSource_termSources`
--

DROP TABLE IF EXISTS `Bio_MAGETAB_TermSource_termSources`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `Bio_MAGETAB_TermSource_termSources` (
  `item` int(11) default NULL,
  `coll` int(11) default NULL,
  `slot` int(11) default NULL,
  FOREIGN KEY (`coll`) REFERENCES `Bio_MAGETAB_Investigation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`item`) REFERENCES `Bio_MAGETAB_TermSource` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `Bio_MAGETAB_TermSource_termSources`
--

LOCK TABLES `Bio_MAGETAB_TermSource_termSources` WRITE;
/*!40000 ALTER TABLE `Bio_MAGETAB_TermSource_termSources` DISABLE KEYS */;
/*!40000 ALTER TABLE `Bio_MAGETAB_TermSource_termSources` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tangram`
--

DROP TABLE IF EXISTS `tangram`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `tangram` (
  `layout` int(11) NOT NULL,
  `engine` varchar(255) default NULL,
  `engine_layout` int(11) default NULL,
  `mark` int(11) NOT NULL,
  UNIQUE KEY `Tangram_Guard` (`layout`,`engine`,`engine_layout`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `tangram`
--

LOCK TABLES `tangram` WRITE;
/*!40000 ALTER TABLE `tangram` DISABLE KEYS */;
INSERT INTO `tangram` VALUES (2,'Tangram::Relational::Engine',1,0);
/*!40000 ALTER TABLE `tangram` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-01-16 15:13:38
