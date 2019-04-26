
SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT;
SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS;
SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION;
SET NAMES utf8;
SET @OLD_TIME_ZONE=@@TIME_ZONE;
SET TIME_ZONE='+00:00';
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
DROP TABLE IF EXISTS `ACCESSORY_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ACCESSORY_TYPE` (
  `accessory_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this type of accessory',
  `accessory_type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Type of accessory',
  PRIMARY KEY (`accessory_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog types of photographic accessory';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `ACCESSORY`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ACCESSORY` (
  `accessory_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this accessory',
  `accessory_type_id` int(11) DEFAULT NULL COMMENT 'ID of this type of accessory',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model of the accessory',
  `acquired` date DEFAULT NULL COMMENT 'Date that this accessory was acquired',
  `cost` decimal(5,2) DEFAULT NULL COMMENT 'Purchase cost of the accessory',
  `lost` date DEFAULT NULL COMMENT 'Date that this accessory was lost',
  `lost_price` decimal(5,2) DEFAULT NULL COMMENT 'Sale price of the accessory',
  PRIMARY KEY (`accessory_id`),
  KEY `fk_ACCESSORY_1_idx` (`accessory_type_id`),
  CONSTRAINT `fk_ACCESSORY_1` FOREIGN KEY (`accessory_type_id`) REFERENCES `ACCESSORY_TYPE` (`accessory_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog accessories that are not tracked in more specific tables';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `PERSON`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `PERSON` (
  `person_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for the person',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the photographer',
  PRIMARY KEY (`person_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog photographers';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `ARCHIVE_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ARCHIVE_TYPE` (
  `archive_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of archive type',
  `archive_type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this type of archive',
  PRIMARY KEY (`archive_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list the different types of archive available for materials';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `CONDITION`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `CONDITION` (
  `condition_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique condition ID',
  `code` varchar(6) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Condition shortcode (e.g. EXC)',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Full name of condition (e.g. Excellent)',
  `min_rating` int(11) DEFAULT NULL COMMENT 'The lowest percentage rating that encompasses this condition',
  `max_rating` int(11) DEFAULT NULL COMMENT 'The highest percentage rating that encompasses this condition',
  `description` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Longer description of condition',
  PRIMARY KEY (`condition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list of physical condition descriptions that can be used to evaluate equipment';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `LOG`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `LOG` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the log entry',
  `datetime` datetime DEFAULT NULL COMMENT 'Timestamp for the log entry',
  `type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Type of log message, e.g. ADD, EDIT',
  `message` varchar(450) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Log message',
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to store data modification logs';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `BATTERY`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `BATTERY` (
  `battery_type` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique battery ID',
  `battery_name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Common name of the battery',
  `voltage` decimal(4,2) DEFAULT NULL COMMENT 'Nominal voltage of the battery',
  `chemistry` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Battery chemistry (e.g. Alkaline, Lithium, etc)',
  `other_names` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Alternative names for this kind of battery',
  PRIMARY KEY (`battery_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog of types of battery';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `PROCESS`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `PROCESS` (
  `process_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID of this development process',
  `name` varchar(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this developmenmt process (e.g. C-41, E-6)',
  `colour` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a colour process',
  `positive` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a positive/reversal process',
  PRIMARY KEY (`process_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog chemical processes that can be used to develop film and paper';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `MANUFACTURER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `MANUFACTURER` (
  `manufacturer_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the manufacturer',
  `manufacturer` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the manufacturer',
  `city` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'City in which the manufacturer is based',
  `country` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Country in which the manufacturer is based',
  `url` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL to the manufacturer''s main website',
  `founded` smallint(6) DEFAULT NULL COMMENT 'Year in which the manufacturer was founded',
  `dissolved` smallint(6) DEFAULT NULL COMMENT 'Year in which the manufacturer was dissolved',
  PRIMARY KEY (`manufacturer_id`),
  UNIQUE KEY `manufacturer_UNIQUE` (`manufacturer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog manufacturers of equipment and consumables';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `EXPOSURE_PROGRAM`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `EXPOSURE_PROGRAM` (
  `exposure_program_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID of exposure program as defined by EXIF tag ExposureProgram',
  `exposure_program` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of exposure program as defined by EXIF tag ExposureProgram',
  PRIMARY KEY (`exposure_program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Exposure programs as defined by EXIF tag ExposureProgram';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `EXHIBITION`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `EXHIBITION` (
  `exhibition_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this exhibition',
  `title` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Title of the exhibition',
  `location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Location of the exhibition',
  `start_date` date DEFAULT NULL COMMENT 'Start date of the exhibition',
  `end_date` date DEFAULT NULL COMMENT 'End date of the exhibition',
  PRIMARY KEY (`exhibition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to record exhibition events';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FOCUS_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FOCUS_TYPE` (
  `focus_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of focus type',
  `focus_type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of focus type',
  PRIMARY KEY (`focus_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different focusing methods';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `METERING_MODE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `METERING_MODE` (
  `metering_mode_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID of metering mode as defined by EXIF tag MeteringMode',
  `metering_mode` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of metering mode as defined by EXIF tag MeteringMode',
  PRIMARY KEY (`metering_mode_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Metering modes as defined by EXIF tag MeteringMode';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `SHUTTER_SPEED`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `SHUTTER_SPEED` (
  `shutter_speed` varchar(10) CHARACTER SET latin1 NOT NULL COMMENT 'Shutter speed in fractional notation, e.g. 1/250',
  `duration` decimal(7,5) DEFAULT NULL COMMENT 'Shutter speed in decimal notation, e.g. 0.04',
  PRIMARY KEY (`shutter_speed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Table to list all possible shutter speeds';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `SHUTTER_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `SHUTTER_TYPE` (
  `shutter_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the shutter type',
  `shutter_type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the shutter type (e.g. Focal plane, Leaf, etc)',
  PRIMARY KEY (`shutter_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog the different types of camera shutter';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `PAPER_STOCK`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `PAPER_STOCK` (
  `paper_stock_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this paper stock',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this paper stock',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of this paper stock',
  `resin_coated` tinyint(1) DEFAULT NULL COMMENT 'Whether the paper is resin-coated',
  `tonable` tinyint(1) DEFAULT NULL COMMENT 'Whether this paper accepts chemical toning',
  `colour` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a colour paper',
  `finish` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The finish of the paper surface',
  PRIMARY KEY (`paper_stock_id`),
  KEY `fk_PAPER_STOCK_1` (`manufacturer_id`),
  CONSTRAINT `fk_PAPER_STOCK_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different paper stocks available';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `METERING_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `METERING_TYPE` (
  `metering_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the metering type',
  `metering` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the metering type (e.g. Selenium)',
  PRIMARY KEY (`metering_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different metering technologies and cell types';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FORMAT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FORMAT` (
  `format_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this format',
  `format` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The name of this film/sensor format',
  `digital` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a digital format',
  PRIMARY KEY (`format_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalogue different film formats. These are distinct from negative sizes.';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FLASH_PROTOCOL`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FLASH_PROTOCOL` (
  `flash_protocol_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this flash protocol',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer that introduced this flash protocol',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the flash protocol',
  PRIMARY KEY (`flash_protocol_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different protocols used to communicate with flashes';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FILTER_ADAPTER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FILTER_ADAPTER` (
  `filter_adapter_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of filter adapter',
  `camera_thread` decimal(3,1) DEFAULT NULL COMMENT 'Diameter of camera-facing screw thread in mm',
  `filter_thread` decimal(3,1) DEFAULT NULL COMMENT 'Diameter of filter-facing screw thread in mm',
  PRIMARY KEY (`filter_adapter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalogue filter adapter rings';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FILTER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FILTER` (
  `filter_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique filter ID',
  `thread` decimal(4,1) DEFAULT NULL COMMENT 'Diameter of screw thread in mm',
  `type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Filter type (e.g. Red, CPL, UV)',
  `attenuation` decimal(2,1) DEFAULT NULL COMMENT 'Attenuation of this filter in decimal stops',
  `qty` int(11) DEFAULT NULL COMMENT 'Quantity of these filters available',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Denotes the manufacturer of the filter.',
  PRIMARY KEY (`filter_id`),
  KEY `fk_FILTER_1_idx` (`manufacturer_id`),
  CONSTRAINT `fk_FILTER_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog filters';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `ARCHIVE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ARCHIVE` (
  `archive_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this archive',
  `archive_type_id` int(11) DEFAULT NULL COMMENT 'ID of this type of archive',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this archive',
  `max_width` int(11) DEFAULT NULL COMMENT 'Maximum width of media that this archive can store',
  `max_height` int(11) DEFAULT NULL COMMENT 'Maximum height of media that this archive can store',
  `location` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Location of this archive',
  `storage` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The type of storage used for this archive, e.g. box, folder, ringbinder, etc',
  `sealed` tinyint(1) DEFAULT '0' COMMENT 'Whether or not this archive is sealed (closed to new additions)',
  PRIMARY KEY (`archive_id`),
  KEY `fk_ARCHIVE_3_idx` (`archive_type_id`),
  CONSTRAINT `fk_ARCHIVE_3` FOREIGN KEY (`archive_type_id`) REFERENCES `ARCHIVE_TYPE` (`archive_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list all archives that exist for storing physical media';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `LIGHT_METER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `LIGHT_METER` (
  `light_meter_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this light meter',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Denotes ID of manufacturer of the light meter',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model name or number of the light meter',
  `metering_type` int(11) DEFAULT NULL COMMENT 'ID of metering technology used in this light meter',
  `reflected` tinyint(1) DEFAULT NULL COMMENT 'Whether the meter is capable of reflected-light metering',
  `incident` tinyint(1) DEFAULT NULL COMMENT 'Whether the meter is capable of incident-light metering',
  `flash` tinyint(1) DEFAULT NULL COMMENT 'Whether the meter is capable of flash metering',
  `spot` tinyint(1) DEFAULT NULL COMMENT 'Whether the meter is capable of spot metering',
  `min_asa` int(11) DEFAULT NULL COMMENT 'Minimum ISO/ASA that this meter is capable of handling',
  `max_asa` int(11) DEFAULT NULL COMMENT 'Maximum ISO/ASA that this meter is capable of handling',
  `min_lv` int(11) DEFAULT NULL COMMENT 'Minimum light value (LV/EV) that this meter is capable of handling',
  `max_lv` int(11) DEFAULT NULL COMMENT 'Maximum light value (LV/EV) that this meter is capable of handling',
  PRIMARY KEY (`light_meter_id`),
  KEY `fk_LIGHT_METER_1_idx` (`manufacturer_id`),
  KEY `fk_LIGHT_METER_2_idx` (`metering_type`),
  CONSTRAINT `fk_LIGHT_METER_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_LIGHT_METER_2` FOREIGN KEY (`metering_type`) REFERENCES `METERING_TYPE` (`metering_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog light meters';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `BODY_TYPE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `BODY_TYPE` (
  `body_type_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique body type ID',
  `body_type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of camera body type (e.g. SLR, compact, etc)',
  PRIMARY KEY (`body_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog types of camera body style';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `NEGATIVE_SIZE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `NEGATIVE_SIZE` (
  `negative_size_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of negative size',
  `width` decimal(4,1) DEFAULT NULL COMMENT 'Width of the negative size in mm',
  `height` decimal(4,1) DEFAULT NULL COMMENT 'Height of the negative size in mm',
  `negative_size` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Common name of the negative size (e.g. 35mm, 6x7, etc)',
  `crop_factor` decimal(4,2) DEFAULT NULL COMMENT 'Crop factor of this negative size',
  `area` int(11) DEFAULT NULL COMMENT 'Area of this negative size in sq. mm',
  `aspect_ratio` decimal(4,2) DEFAULT NULL COMMENT 'Aspect ratio of this negative size, expressed as a single decimal. (e.g. 3:2 is expressed as 1.5)',
  PRIMARY KEY (`negative_size_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different negative sizes available. Negtives sizes are distinct from film formats.';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `MOUNT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `MOUNT` (
  `mount_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this lens mount',
  `mount` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this lens mount (e.g. Canon FD)',
  `fixed` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a fixed (non-interchangable) lens mount',
  `shutter_in_lens` tinyint(1) DEFAULT NULL COMMENT 'Whether this lens mount system incorporates the shutter into the lens',
  `type` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The physical mount type of this lens mount (e.g. Screw, Bayonet, etc)',
  `purpose` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The intended purpose of this lens mount (e.g. camera, enlarger, projector)',
  `notes` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Freeform notes field',
  `digital_only` tinyint(1) DEFAULT NULL COMMENT 'Whether this mount is intended only for digital cameras',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Manufacturer ID of this lens mount, if applicable',
  PRIMARY KEY (`mount_id`),
  KEY `fk_MOUNT_1_idx` (`manufacturer_id`),
  CONSTRAINT `fk_MOUNT_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog different lens mount standards. This is mostly used for camera lens mounts, but can also be used for enlarger and projector lenses.';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FILMSTOCK`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FILMSTOCK` (
  `filmstock_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the filmstock',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of the film',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the film',
  `iso` int(11) DEFAULT NULL COMMENT 'Nominal ISO speed of the film',
  `colour` tinyint(1) DEFAULT NULL COMMENT 'Whether the film is colour',
  `process_id` int(11) DEFAULT NULL COMMENT 'ID of the normal process for this film',
  `panchromatic` tinyint(1) DEFAULT NULL COMMENT 'Whether this film is panchromatic',
  PRIMARY KEY (`filmstock_id`),
  KEY `fk_manufacturer_id` (`manufacturer_id`),
  KEY `fk_FILMSTOCK_1_idx` (`process_id`),
  CONSTRAINT `fk_FILMSTOCK_1` FOREIGN KEY (`process_id`) REFERENCES `PROCESS` (`process_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_manufacturer_id` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list different brands of film stock';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `DEVELOPER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `DEVELOPER` (
  `developer_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique developer ID',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Denotes the manufacturer ID',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the developer',
  `for_paper` tinyint(1) DEFAULT NULL COMMENT 'Whether this developer can be used with paper',
  `for_film` tinyint(1) DEFAULT NULL COMMENT 'Whether this developer can be used with film',
  `chemistry` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The key chemistry on which this developer is based (e.g. phenidone)',
  PRIMARY KEY (`developer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list film and paper developers';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `MOUNT_ADAPTER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `MOUNT_ADAPTER` (
  `mount_adapter_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of lens mount adapter',
  `lens_mount` int(11) DEFAULT NULL COMMENT 'ID of the mount used between the adapter and the lens',
  `camera_mount` int(11) DEFAULT NULL COMMENT 'ID of the mount used between the adapter and the camera',
  `has_optics` tinyint(1) DEFAULT NULL COMMENT 'Whether this adapter includes optical elements',
  `infinity_focus` tinyint(1) DEFAULT NULL COMMENT 'Whether this adapter allows infinity focus',
  `notes` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Freeform notes',
  PRIMARY KEY (`mount_adapter_id`),
  KEY `fk_MOUNT_ADAPTER_1` (`lens_mount`),
  KEY `fk_MOUNT_ADAPTER_2` (`camera_mount`),
  CONSTRAINT `fk_MOUNT_ADAPTER_1` FOREIGN KEY (`lens_mount`) REFERENCES `MOUNT` (`mount_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_MOUNT_ADAPTER_2` FOREIGN KEY (`camera_mount`) REFERENCES `MOUNT` (`mount_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog adapters to mount lenses on other cameras';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FILM_BULK`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FILM_BULK` (
  `film_bulk_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this bulk roll of film',
  `format_id` int(11) DEFAULT NULL COMMENT 'ID of the format of this bulk roll',
  `filmstock_id` int(11) DEFAULT NULL COMMENT 'ID of the filmstock',
  `purchase_date` date DEFAULT NULL COMMENT 'Purchase date of this bulk roll',
  `cost` decimal(5,2) DEFAULT NULL COMMENT 'Purchase cost of this bulk roll',
  `source` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Place where this bulk roll was bought from',
  `batch` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Batch code of this bulk roll',
  `expiry` date DEFAULT NULL COMMENT 'Expiry date of this bulk roll',
  PRIMARY KEY (`film_bulk_id`),
  KEY `fk_FILM_BULK_1_idx` (`format_id`),
  KEY `fk_FILM_BULK_2_idx` (`filmstock_id`),
  CONSTRAINT `fk_FILM_BULK_1` FOREIGN KEY (`format_id`) REFERENCES `FORMAT` (`format_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_FILM_BULK_2` FOREIGN KEY (`filmstock_id`) REFERENCES `FILMSTOCK` (`filmstock_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to record bulk film stock, from which individual films can be cut';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `TELECONVERTER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `TELECONVERTER` (
  `teleconverter_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this teleconverter',
  `mount_id` int(11) DEFAULT NULL COMMENT 'ID of the lens mount used by this teleconverter',
  `factor` decimal(4,2) DEFAULT NULL COMMENT 'Magnification factor of this teleconverter (numerical part only, e.g. 1.4)',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of this teleconverter',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model name of this teleconverter',
  `elements` tinyint(4) DEFAULT NULL COMMENT 'Number of optical elements used in this teleconverter',
  `groups` tinyint(4) DEFAULT NULL COMMENT 'Number of optical groups used in this teleconverter',
  `multicoated` tinyint(1) DEFAULT NULL COMMENT 'Whether this teleconverter is multi-coated',
  PRIMARY KEY (`teleconverter_id`),
  KEY `fk_TELECONVERTER_1` (`manufacturer_id`),
  KEY `fk_TELECONVERTER_2` (`mount_id`),
  CONSTRAINT `fk_TELECONVERTER_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_TELECONVERTER_2` FOREIGN KEY (`mount_id`) REFERENCES `MOUNT` (`mount_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog teleconverters (multipliers)';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `TONER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `TONER` (
  `toner_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the toner',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of the toner',
  `toner` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the toner',
  `formulation` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Chemical formulation of the toner',
  `stock_dilution` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Stock dilution of the toner',
  PRIMARY KEY (`toner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog paper toners that can be used during the printing process';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `ENLARGER`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ENLARGER` (
  `enlarger_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique enlarger ID',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Manufacturer ID of the enlarger',
  `enlarger` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name/model of the enlarger',
  `negative_size_id` int(11) DEFAULT NULL COMMENT 'ID of the largest negative size that the enlarger can handle',
  `acquired` date DEFAULT NULL COMMENT 'Date on which the enlarger was acquired',
  `lost` date DEFAULT NULL COMMENT 'Date on which the enlarger was lost/sold',
  `introduced` year(4) DEFAULT NULL COMMENT 'Year in which the enlarger was introduced',
  `discontinued` year(4) DEFAULT NULL COMMENT 'Year in which the enlarger was discontinued',
  `cost` decimal(6,2) DEFAULT NULL COMMENT 'Purchase cost of the enlarger',
  `lost_price` decimal(6,2) DEFAULT NULL COMMENT 'Sale price of the enlarger',
  PRIMARY KEY (`enlarger_id`),
  KEY `fk_ENLARGER_1` (`manufacturer_id`),
  KEY `fk_ENLARGER_2` (`negative_size_id`),
  CONSTRAINT `fk_ENLARGER_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ENLARGER_2` FOREIGN KEY (`negative_size_id`) REFERENCES `NEGATIVE_SIZE` (`negative_size_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list enlargers';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FLASH`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FLASH` (
  `flash_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of external flash unit',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Manufacturer ID of the flash',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model name/number of the flash',
  `guide_number` int(11) DEFAULT NULL COMMENT 'Guide number of the flash',
  `gn_info` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Extra freeform info about how the guide number was measured',
  `battery_powered` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash takes batteries',
  `pc_sync` tinyint(1) DEFAULT NULL COMMENT 'Whether the flash has a PC sync socket',
  `hot_shoe` tinyint(1) DEFAULT NULL COMMENT 'Whether the flash has a hot shoe connection',
  `light_stand` tinyint(1) DEFAULT NULL COMMENT 'Whether the flash can be used on a light stand',
  `battery_type_id` int(11) DEFAULT NULL COMMENT 'ID of battery type',
  `battery_qty` int(11) DEFAULT NULL COMMENT 'Quantity of batteries needed in this flash',
  `manual_control` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash offers manual power control',
  `swivel_head` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash has a horizontal swivel head',
  `tilt_head` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash has a vertical tilt head',
  `zoom` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash can zoom',
  `dslr_safe` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash is safe to use with a digital camera',
  `ttl` tinyint(1) DEFAULT NULL COMMENT 'Whether this flash supports TTL metering',
  `flash_protocol_id` int(11) DEFAULT NULL COMMENT 'ID of flash TTL metering protocol',
  `trigger_voltage` decimal(4,1) DEFAULT NULL COMMENT 'Trigger voltage of the flash, in Volts',
  `own` tinyint(1) DEFAULT NULL COMMENT 'Whether we currently own this flash',
  `acquired` date DEFAULT NULL COMMENT 'Date this flash was acquired',
  `cost` decimal(5,2) DEFAULT NULL COMMENT 'Purchase cost of this flash',
  PRIMARY KEY (`flash_id`),
  KEY `fk_FLASH_1_idx` (`flash_protocol_id`),
  KEY `fk_FLASH_2_idx` (`battery_type_id`),
  CONSTRAINT `fk_FLASH_1` FOREIGN KEY (`flash_protocol_id`) REFERENCES `FLASH_PROTOCOL` (`flash_protocol_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_FLASH_2` FOREIGN KEY (`battery_type_id`) REFERENCES `BATTERY` (`battery_type`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catlog flashes, flashguns and speedlights';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `PROJECTOR`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `PROJECTOR` (
  `projector_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this projector',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of this projector',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model name of this projector',
  `mount_id` int(11) DEFAULT NULL COMMENT 'ID of the lens mount of this projector, if it has interchangeable lenses',
  `negative_size_id` int(11) DEFAULT NULL COMMENT 'ID of the largest negative size that this projector can handle',
  `own` tinyint(1) DEFAULT NULL COMMENT 'Whether we currently own this projector',
  `cine` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a cine (movie) projector',
  PRIMARY KEY (`projector_id`),
  KEY `fk_PROJECTOR_1_idx` (`manufacturer_id`),
  KEY `fk_PROJECTOR_2_idx` (`mount_id`),
  KEY `fk_PROJECTOR_3_idx` (`negative_size_id`),
  CONSTRAINT `fk_PROJECTOR_1` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_PROJECTOR_2` FOREIGN KEY (`mount_id`) REFERENCES `MOUNT` (`mount_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_PROJECTOR_3` FOREIGN KEY (`negative_size_id`) REFERENCES `NEGATIVE_SIZE` (`negative_size_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog projectors (still and movie)';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `LENS`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `LENS` (
  `lens_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this lens',
  `mount_id` int(11) DEFAULT NULL COMMENT 'Denotes the ID of the lens mount, if this is an interchangeable lens',
  `zoom` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a zoom lens',
  `min_focal_length` int(11) DEFAULT NULL COMMENT 'Shortest focal length of this lens, in mm',
  `max_focal_length` int(11) DEFAULT NULL COMMENT 'Longest focal length of this lens, in mm',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'ID of the manufacturer of this lens',
  `model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model name of this lens',
  `closest_focus` int(11) DEFAULT NULL COMMENT 'The closest focus possible with this lens, in cm',
  `max_aperture` decimal(4,1) DEFAULT NULL COMMENT 'Maximum (widest) aperture available on this lens (numerical part only, e.g. 2.8)',
  `min_aperture` decimal(4,1) DEFAULT NULL COMMENT 'Minimum (narrowest) aperture available on this lens (numerical part only, e.g. 22)',
  `elements` int(11) DEFAULT NULL COMMENT 'Number of optical lens elements',
  `groups` int(11) DEFAULT NULL COMMENT 'Number of optical groups',
  `weight` int(11) DEFAULT NULL COMMENT 'Weight of this lens, in grammes (g)',
  `nominal_min_angle_diag` int(11) DEFAULT NULL COMMENT 'Nominal minimum diagonal field of view from manufacturer''s specs',
  `nominal_max_angle_diag` int(11) DEFAULT NULL COMMENT 'Nominal maximum diagonal field of view from manufacturer''s specs',
  `aperture_blades` int(11) DEFAULT NULL COMMENT 'Number of aperture blades',
  `autofocus` tinyint(1) DEFAULT NULL COMMENT 'Whether this lens has autofocus capability',
  `filter_thread` decimal(4,1) DEFAULT NULL COMMENT 'Diameter of lens filter thread, in mm',
  `magnification` decimal(5,3) DEFAULT NULL COMMENT 'Maximum magnification ratio of the lens, expressed like 0.765',
  `url` varchar(145) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL to more information about this lens',
  `serial` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Serial number of this lens',
  `date_code` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Date code of this lens, if different from the serial number',
  `introduced` smallint(6) DEFAULT NULL COMMENT 'Year in which this lens model was introduced',
  `discontinued` smallint(6) DEFAULT NULL COMMENT 'Year in which this lens model was discontinued',
  `manufactured` smallint(6) DEFAULT NULL COMMENT 'Year in which this specific lens was manufactured',
  `negative_size_id` int(11) DEFAULT NULL COMMENT 'ID of the negative size which this lens is designed for',
  `acquired` date DEFAULT NULL COMMENT 'Date on which this lens was acquired',
  `cost` decimal(6,2) DEFAULT NULL COMMENT 'Price paid for this lens in local currency units',
  `fixed_mount` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a fixed lens (i.e. on a compact camera)',
  `notes` text COLLATE utf8mb4_unicode_ci COMMENT 'Freeform notes field',
  `own` tinyint(1) DEFAULT NULL COMMENT 'Whether we currently own this lens',
  `lost` date DEFAULT NULL COMMENT 'Date on which lens was lost/sold/disposed',
  `lost_price` decimal(6,2) DEFAULT NULL COMMENT 'Price for which the lens was sold',
  `source` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Place where the lens was acquired from',
  `coating` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Notes about the lens coating type',
  `hood` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Model number of the compatible lens hood',
  `exif_lenstype` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EXIF LensID number, if this lens has one officially registered. See documentation at http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/',
  `rectilinear` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a rectilinear lens',
  `length` int(11) DEFAULT NULL COMMENT 'Length of lens in mm',
  `diameter` int(11) DEFAULT NULL COMMENT 'Width of lens in mm',
  `condition_id` int(11) DEFAULT NULL COMMENT 'Denotes the cosmetic condition of the camera',
  `image_circle` int(11) DEFAULT NULL COMMENT 'Diameter of image circle projected by lens, in mm',
  `formula` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the type of lens formula (e.g. Tessar)',
  `shutter_model` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the integrated shutter, if any',
  PRIMARY KEY (`lens_id`),
  KEY `fk_LENS_2` (`manufacturer_id`),
  KEY `fk_LENS_3` (`mount_id`),
  KEY `fk_LENS_4` (`negative_size_id`),
  KEY `fk_LENS_1_idx` (`condition_id`),
  CONSTRAINT `fk_LENS_1` FOREIGN KEY (`condition_id`) REFERENCES `CONDITION` (`condition_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_LENS_2` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_LENS_3` FOREIGN KEY (`mount_id`) REFERENCES `MOUNT` (`mount_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_LENS_4` FOREIGN KEY (`negative_size_id`) REFERENCES `NEGATIVE_SIZE` (`negative_size_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog lenses';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `CAMERA`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `CAMERA` (
  `camera_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Auto-incremented camera ID',
  `manufacturer_id` int(11) DEFAULT NULL COMMENT 'Denotes the manufacturer of the camera.',
  `model` varchar(45) DEFAULT NULL COMMENT 'The model name of the camera',
  `mount_id` int(11) DEFAULT NULL COMMENT 'Denotes the lens mount of the camera if it is an interchangeable-lens camera',
  `format_id` int(11) DEFAULT NULL COMMENT 'Denotes the film format of the camera',
  `focus_type_id` int(11) DEFAULT NULL COMMENT 'Denotes the focus type of the camera',
  `metering` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has built-in metering',
  `coupled_metering` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera''s meter is coupled automatically',
  `metering_type_id` int(11) DEFAULT NULL COMMENT 'Denotes the technology used in the meter',
  `body_type_id` int(11) DEFAULT NULL COMMENT 'Denotes the style of camera body',
  `weight` int(11) DEFAULT NULL COMMENT 'Weight of the camera body (without lens or batteries) in grammes (g)',
  `acquired` date DEFAULT NULL COMMENT 'Date on which the camera was acquired',
  `cost` decimal(6,2) DEFAULT NULL COMMENT 'Price paid for the camera, in local currency units',
  `introduced` smallint(6) DEFAULT NULL COMMENT 'Year in which the camera model was introduced',
  `discontinued` smallint(6) DEFAULT NULL COMMENT 'Year in which the camera model was discontinued',
  `serial` varchar(45) DEFAULT NULL COMMENT 'Serial number of the camera',
  `datecode` varchar(12) DEFAULT NULL COMMENT 'Date code of the camera, if different from the serial number',
  `manufactured` smallint(6) DEFAULT NULL COMMENT 'Year of manufacture of the camera',
  `own` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera is currently owned',
  `negative_size_id` int(11) DEFAULT NULL COMMENT 'Denotes the size of negative made by the camera',
  `shutter_type_id` int(11) DEFAULT NULL COMMENT 'Denotes type of shutter',
  `shutter_model` varchar(45) DEFAULT NULL COMMENT 'Model of shutter',
  `cable_release` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has the facility for a remote cable release',
  `viewfinder_coverage` int(11) DEFAULT NULL COMMENT 'Percentage coverage of the viewfinder. Mostly applicable to SLRs.',
  `power_drive` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has integrated motor drive',
  `continuous_fps` decimal(3,1) DEFAULT NULL COMMENT 'The maximum rate at which the camera can shoot, in frames per second',
  `video` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera can take video/movie',
  `digital` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a digital camera',
  `fixed_mount` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has a fixed lens',
  `lens_id` int(11) DEFAULT NULL COMMENT 'If fixed_mount is true, specify the lens_id',
  `battery_qty` int(11) DEFAULT NULL COMMENT 'Quantity of batteries needed',
  `battery_type` int(11) DEFAULT NULL COMMENT 'Denotes type of battery needed',
  `notes` text COMMENT 'Freeform text field for extra notes',
  `lost` date DEFAULT NULL COMMENT 'Date on which the camera was lost/sold/etc',
  `lost_price` decimal(6,2) DEFAULT NULL COMMENT 'Price at which the camera was sold',
  `source` varchar(150) DEFAULT NULL COMMENT 'Where the camera was acquired from',
  `min_shutter` varchar(10) CHARACTER SET latin1 DEFAULT NULL COMMENT 'Fastest available shutter speed, expressed like 1/400',
  `max_shutter` varchar(10) CHARACTER SET latin1 DEFAULT NULL COMMENT 'Slowest available shutter speed, expressed like 30 (no ")',
  `bulb` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera supports bulb (B) exposure',
  `time` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera supports time (T) exposure',
  `min_iso` int(11) DEFAULT NULL COMMENT 'Minimum ISO the camera will accept for metering',
  `max_iso` int(11) DEFAULT NULL COMMENT 'Maximum ISO the camera will accept for metering',
  `af_points` tinyint(4) DEFAULT NULL COMMENT 'Number of autofocus points',
  `int_flash` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has an integrated flash',
  `int_flash_gn` tinyint(4) DEFAULT NULL COMMENT 'Guide number of internal flash',
  `ext_flash` tinyint(1) DEFAULT NULL COMMENT ' Whether the camera supports an external flash',
  `flash_metering` varchar(12) DEFAULT NULL COMMENT 'Flash metering protocol',
  `pc_sync` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has a PC sync socket for flash',
  `hotshoe` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has a hotshoe',
  `coldshoe` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has a coldshoe or accessory shoe',
  `x_sync` varchar(6) DEFAULT NULL COMMENT 'X-sync shutter speed, expressed like 1/125',
  `meter_min_ev` tinyint(4) DEFAULT NULL COMMENT 'Lowest EV/LV the built-in meter supports',
  `meter_max_ev` tinyint(4) DEFAULT NULL COMMENT 'Highest EV/LV the built-in meter supports',
  `condition_id` int(11) DEFAULT NULL COMMENT 'Denotes the cosmetic condition of the camera',
  `dof_preview` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has depth of field preview',
  `tripod` tinyint(1) DEFAULT NULL COMMENT 'Whether the camera has a tripod bush',
  `display_lens` int(11) DEFAULT NULL COMMENT 'Lens ID of the lens that this camera should normally be displayed with',
  PRIMARY KEY (`camera_id`),
  UNIQUE KEY `display_lens_UNIQUE` (`display_lens`),
  KEY `manufacturer_id` (`manufacturer_id`),
  KEY `body_type_id` (`body_type_id`),
  KEY `fk_body_type` (`body_type_id`),
  KEY `fk_focus_type` (`focus_type_id`),
  KEY `fk_mount` (`mount_id`),
  KEY `fk_format` (`format_id`),
  KEY `fk_manufacturer` (`manufacturer_id`),
  KEY `fk_metering_type` (`metering_type_id`),
  KEY `fk_negative_size_id` (`negative_size_id`),
  KEY `fk_shutter_type_id` (`shutter_type_id`),
  KEY `fk_CAMERA_3_idx` (`condition_id`),
  KEY `fk_CAMERA_1_idx` (`min_shutter`),
  KEY `fk_CAMERA_2_idx` (`max_shutter`),
  KEY `fk_CAMERA_3_idx1` (`display_lens`),
  KEY `fk_CAMERA_4_idx` (`battery_type`),
  CONSTRAINT `fk_CAMERA_1` FOREIGN KEY (`min_shutter`) REFERENCES `SHUTTER_SPEED` (`shutter_speed`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_CAMERA_2` FOREIGN KEY (`max_shutter`) REFERENCES `SHUTTER_SPEED` (`shutter_speed`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_CAMERA_3` FOREIGN KEY (`display_lens`) REFERENCES `LENS` (`lens_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_CAMERA_4` FOREIGN KEY (`battery_type`) REFERENCES `BATTERY` (`battery_type`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_CAMERA_5` FOREIGN KEY (`display_lens`) REFERENCES `LENS` (`lens_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_body_type` FOREIGN KEY (`body_type_id`) REFERENCES `BODY_TYPE` (`body_type_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_condition` FOREIGN KEY (`condition_id`) REFERENCES `CONDITION` (`condition_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_focus_type` FOREIGN KEY (`focus_type_id`) REFERENCES `FOCUS_TYPE` (`focus_type_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_format` FOREIGN KEY (`format_id`) REFERENCES `FORMAT` (`format_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_manufacturer` FOREIGN KEY (`manufacturer_id`) REFERENCES `MANUFACTURER` (`manufacturer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_metering_type` FOREIGN KEY (`metering_type_id`) REFERENCES `METERING_TYPE` (`metering_type_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_mount` FOREIGN KEY (`mount_id`) REFERENCES `MOUNT` (`mount_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_negative_size` FOREIGN KEY (`negative_size_id`) REFERENCES `NEGATIVE_SIZE` (`negative_size_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_shutter_type` FOREIGN KEY (`shutter_type_id`) REFERENCES `SHUTTER_TYPE` (`shutter_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Table to catalog cameras - both cameras with fixed lenses and cameras with interchangeable lenses';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `MOVIE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `MOVIE` (
  `movie_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this motion picture film / movie',
  `title` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Title of this movie',
  `camera_id` int(11) DEFAULT NULL COMMENT 'ID of the camera used to shoot this movie',
  `lens_id` int(11) DEFAULT NULL COMMENT 'ID of the lens used to shoot this movie',
  `format_id` int(11) DEFAULT NULL COMMENT 'ID of the film format on which this movie was shot',
  `sound` tinyint(1) DEFAULT NULL COMMENT 'Whether this movie has sound',
  `fps` int(11) DEFAULT NULL COMMENT 'Frame rate of this movie, in fps',
  `filmstock_id` int(11) DEFAULT NULL COMMENT 'ID of the filmstock used to shoot this movie',
  `feet` int(11) DEFAULT NULL COMMENT 'Length of this movie in feet',
  `date_loaded` date DEFAULT NULL COMMENT 'Date that the filmstock was loaded into a camera',
  `date_shot` date DEFAULT NULL COMMENT 'Date on which this movie was shot',
  `date_processed` date DEFAULT NULL COMMENT 'Date on which this movie was processed',
  `process_id` int(11) DEFAULT NULL COMMENT 'ID of the process used to develop this film',
  `description` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Table to catalog motion picture films (movies)',
  PRIMARY KEY (`movie_id`),
  KEY `fk_MOVIE_1_idx` (`camera_id`),
  KEY `fk_MOVIE_2_idx` (`lens_id`),
  KEY `fk_MOVIE_3_idx` (`format_id`),
  KEY `fk_MOVIE_4_idx` (`filmstock_id`),
  KEY `fk_MOVIE_5_idx` (`process_id`),
  CONSTRAINT `fk_MOVIE_1` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_MOVIE_2` FOREIGN KEY (`lens_id`) REFERENCES `LENS` (`lens_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_MOVIE_3` FOREIGN KEY (`format_id`) REFERENCES `FORMAT` (`format_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_MOVIE_4` FOREIGN KEY (`filmstock_id`) REFERENCES `FILMSTOCK` (`filmstock_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_MOVIE_5` FOREIGN KEY (`process_id`) REFERENCES `PROCESS` (`process_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog motion picture films (movies)';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `METERING_MODE_AVAILABLE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `METERING_MODE_AVAILABLE` (
  `camera_id` int(11) NOT NULL COMMENT 'ID of camera',
  `metering_mode_id` int(11) NOT NULL COMMENT 'ID of metering mode',
  PRIMARY KEY (`camera_id`,`metering_mode_id`),
  KEY `fk_METERING_MODE_AVAILABLE_2_idx` (`metering_mode_id`),
  CONSTRAINT `fk_METERING_MODE_AVAILABLE_1` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_METERING_MODE_AVAILABLE_2` FOREIGN KEY (`metering_mode_id`) REFERENCES `METERING_MODE` (`metering_mode_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to associate cameras with available metering modes';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `EXPOSURE_PROGRAM_AVAILABLE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `EXPOSURE_PROGRAM_AVAILABLE` (
  `camera_id` int(11) NOT NULL COMMENT 'ID of camera',
  `exposure_program_id` int(11) NOT NULL COMMENT 'ID of exposure program',
  PRIMARY KEY (`camera_id`,`exposure_program_id`),
  KEY `fk_EXPOSURE_PROGRAM_AVAILABLE_1_idx` (`camera_id`),
  KEY `fk_EXPOSURE_PROGRAM_AVAILABLE_2_idx` (`exposure_program_id`),
  CONSTRAINT `fk_EXPOSURE_PROGRAM_AVAILABLE_1` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_EXPOSURE_PROGRAM_AVAILABLE_2` FOREIGN KEY (`exposure_program_id`) REFERENCES `EXPOSURE_PROGRAM` (`exposure_program_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to associate cameras with available exposure programs';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `ACCESSORY_COMPAT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ACCESSORY_COMPAT` (
  `compat_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this compatibility',
  `accessory_id` int(11) NOT NULL COMMENT 'ID of the accessory',
  `camera_id` int(11) DEFAULT NULL COMMENT 'ID of the compatible camera',
  `lens_id` int(11) DEFAULT NULL COMMENT 'ID of the compatible lens',
  PRIMARY KEY (`compat_id`),
  KEY `fk_ACCESSORY_COMPAT_1_idx` (`accessory_id`),
  KEY `fk_ACCESSORY_COMPAT_2_idx` (`camera_id`),
  KEY `fk_ACCESSORY_COMPAT_3_idx` (`lens_id`),
  CONSTRAINT `fk_ACCESSORY_COMPAT_1` FOREIGN KEY (`accessory_id`) REFERENCES `ACCESSORY` (`accessory_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ACCESSORY_COMPAT_2` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ACCESSORY_COMPAT_3` FOREIGN KEY (`lens_id`) REFERENCES `LENS` (`lens_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to define compatibility between accessories and cameras or lenses';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `SHUTTER_SPEED_AVAILABLE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `SHUTTER_SPEED_AVAILABLE` (
  `camera_id` int(11) NOT NULL COMMENT 'ID of the camera',
  `shutter_speed` varchar(10) CHARACTER SET latin1 NOT NULL COMMENT 'Shutter speed that this camera has',
  PRIMARY KEY (`camera_id`,`shutter_speed`),
  KEY `fk_SHUTTER_SPEED_AVAILABLE_1_idx` (`shutter_speed`),
  KEY `fk_SHUTTER_SPEED_AVAILABLE_2_idx` (`camera_id`),
  CONSTRAINT `fk_SHUTTER_SPEED_AVAILABLE_1` FOREIGN KEY (`shutter_speed`) REFERENCES `SHUTTER_SPEED` (`shutter_speed`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_SHUTTER_SPEED_AVAILABLE_2` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Table to associate cameras with shutter speeds';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `REPAIR`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `REPAIR` (
  `repair_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for the repair job',
  `camera_id` int(11) DEFAULT NULL COMMENT 'ID of camera that was repaired',
  `lens_id` int(11) DEFAULT NULL COMMENT 'ID of lens that was repaired',
  `date` date DEFAULT NULL COMMENT 'The date of the repair',
  `summary` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Brief summary of the repair',
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Longer description of the repair',
  PRIMARY KEY (`repair_id`),
  KEY `fk_REPAIR_1_idx` (`camera_id`),
  KEY `fk_REPAIR_2_idx` (`lens_id`),
  CONSTRAINT `fk_REPAIR_1` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_REPAIR_2` FOREIGN KEY (`lens_id`) REFERENCES `LENS` (`lens_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabe to catalog all repairs and servicing undertaken on cameras and lenses in the collection';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `FILM`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `FILM` (
  `film_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of the film',
  `filmstock_id` int(11) DEFAULT NULL COMMENT 'ID of the filmstock used',
  `exposed_at` int(11) DEFAULT NULL COMMENT 'ISO at which the film was exposed',
  `format_id` int(11) DEFAULT NULL COMMENT 'ID of the film format',
  `date_loaded` date DEFAULT NULL COMMENT 'Date when the film was loaded into a camera',
  `date` date DEFAULT NULL COMMENT 'Date when the film was processed',
  `camera_id` int(11) DEFAULT NULL COMMENT 'ID of the camera that exposed this film',
  `notes` varchar(145) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Title of the film',
  `frames` int(11) DEFAULT NULL COMMENT 'Expected (not actual) number of frames from the film',
  `developer_id` int(11) DEFAULT NULL COMMENT 'ID of the developer used to process this film',
  `directory` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the directory that contains the scanned images from this film',
  `photographer_id` int(11) DEFAULT NULL COMMENT 'ID of the photographer who took these pictures',
  `dev_uses` int(11) DEFAULT NULL COMMENT 'Numnber of previous uses of the developer',
  `dev_time` time DEFAULT NULL COMMENT 'Duration of development',
  `dev_temp` decimal(3,1) DEFAULT NULL COMMENT 'Temperature of development',
  `dev_n` int(11) DEFAULT NULL COMMENT 'Number of the Push/Pull rating of the film, e.g. N+1, N-2',
  `development_notes` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Extra freeform notes about the development process',
  `film_bulk_id` int(11) DEFAULT NULL COMMENT 'ID of bulk film from which this film was cut',
  `film_bulk_loaded` date DEFAULT NULL COMMENT 'Date that this film was cut from a bulk roll',
  `film_batch` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Batch number of the film',
  `film_expiry` date DEFAULT NULL COMMENT 'Expiry date of the film',
  `purchase_date` date DEFAULT NULL COMMENT 'Date this film was purchased',
  `price` decimal(4,2) DEFAULT NULL COMMENT 'Price paid for this film',
  `processed_by` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Person or place that processed this film',
  `archive_id` int(11) DEFAULT NULL COMMENT 'ID of the archive to which this film belongs',
  PRIMARY KEY (`film_id`),
  KEY `fk_filmstock_id` (`filmstock_id`),
  KEY `fk_camera_id` (`camera_id`),
  KEY `fk_format_id` (`format_id`),
  KEY `fk_FILM_1` (`developer_id`),
  KEY `fk_FILM_2_idx` (`photographer_id`),
  KEY `fk_FILM_3_idx` (`archive_id`),
  KEY `fk_FILM_4_idx` (`film_bulk_id`),
  CONSTRAINT `fk_FILM_1` FOREIGN KEY (`developer_id`) REFERENCES `DEVELOPER` (`developer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_FILM_2` FOREIGN KEY (`photographer_id`) REFERENCES `PERSON` (`person_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_FILM_3` FOREIGN KEY (`archive_id`) REFERENCES `ARCHIVE` (`archive_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_FILM_4` FOREIGN KEY (`film_bulk_id`) REFERENCES `FILM_BULK` (`film_bulk_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_camera_id` FOREIGN KEY (`camera_id`) REFERENCES `CAMERA` (`camera_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_filmstock_id` FOREIGN KEY (`filmstock_id`) REFERENCES `FILMSTOCK` (`filmstock_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_format_id` FOREIGN KEY (`format_id`) REFERENCES `FORMAT` (`format_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list films which consist of one or more negatives. A film can be a roll film, one or more sheets of sheet film, one or more photographic plates, etc.';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `NEGATIVE`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `NEGATIVE` (
  `negative_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this negative',
  `film_id` int(11) DEFAULT NULL COMMENT 'ID of the film that this negative belongs to',
  `frame` varchar(5) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT 'Frame number or code of this negative',
  `description` varchar(145) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT 'Caption of this picture',
  `date` datetime DEFAULT NULL COMMENT 'Date & time on which this picture was taken',
  `lens_id` int(11) DEFAULT NULL COMMENT 'ID of lens used to take this picture',
  `shutter_speed` varchar(45) CHARACTER SET latin1 DEFAULT NULL COMMENT 'Shutter speed used to take this picture',
  `aperture` decimal(4,1) DEFAULT NULL COMMENT 'Aperture used to take this picture (numerical part only)',
  `filter_id` int(11) DEFAULT NULL COMMENT 'ID of filter used to take this picture',
  `teleconverter_id` int(11) DEFAULT NULL COMMENT 'ID of teleconverter used to take this picture',
  `notes` text CHARACTER SET utf8mb4 COMMENT 'Extra freeform notes about this exposure',
  `mount_adapter_id` int(11) DEFAULT NULL COMMENT 'ID of lens mount adapter used to take this pciture',
  `focal_length` int(11) DEFAULT NULL COMMENT 'If a zoom lens was used, specify the focal length of the lens',
  `latitude` decimal(9,6) DEFAULT NULL COMMENT 'Latitude of the location where the picture was taken',
  `longitude` decimal(9,6) DEFAULT NULL COMMENT 'Longitude of the location where the picture was taken',
  `flash` tinyint(1) DEFAULT NULL COMMENT 'Whether flash was used',
  `metering_mode` int(11) DEFAULT NULL COMMENT 'MeteringMode ID as defined in EXIF spec',
  `exposure_program` int(11) DEFAULT NULL COMMENT 'ExposureProgram ID as defined in EXIF spec',
  `photographer_id` int(11) DEFAULT NULL COMMENT 'ID of person who took this photograph',
  `copy_of` int(11) DEFAULT NULL COMMENT 'Negative ID of negative from which this negative is reproduced/duplicated/rephotographed',
  PRIMARY KEY (`negative_id`),
  KEY `fk_NEGATIVE_1` (`film_id`),
  KEY `fk_NEGATIVE_2` (`lens_id`),
  KEY `fk_NEGATIVE_3` (`filter_id`),
  KEY `fk_NEGATIVE_4` (`teleconverter_id`),
  KEY `fk_NEGATIVE_5` (`mount_adapter_id`),
  KEY `fk_NEGATIVE_6_idx` (`metering_mode`),
  KEY `fk_NEGATIVE_7_idx` (`exposure_program`),
  KEY `fk_NEGATIVE_8_idx` (`photographer_id`),
  KEY `fk_NEGATIVE_9_idx` (`shutter_speed`),
  KEY `fk_NEGATIVE_10_idx` (`copy_of`),
  CONSTRAINT `fk_NEGATIVE_1` FOREIGN KEY (`film_id`) REFERENCES `FILM` (`film_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_NEGATIVE_10` FOREIGN KEY (`copy_of`) REFERENCES `NEGATIVE` (`negative_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_NEGATIVE_2` FOREIGN KEY (`lens_id`) REFERENCES `LENS` (`lens_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_NEGATIVE_3` FOREIGN KEY (`filter_id`) REFERENCES `FILTER` (`filter_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_NEGATIVE_4` FOREIGN KEY (`teleconverter_id`) REFERENCES `TELECONVERTER` (`teleconverter_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_NEGATIVE_5` FOREIGN KEY (`mount_adapter_id`) REFERENCES `MOUNT_ADAPTER` (`mount_adapter_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_NEGATIVE_6` FOREIGN KEY (`metering_mode`) REFERENCES `METERING_MODE` (`metering_mode_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_NEGATIVE_7` FOREIGN KEY (`exposure_program`) REFERENCES `EXPOSURE_PROGRAM` (`exposure_program_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_NEGATIVE_8` FOREIGN KEY (`photographer_id`) REFERENCES `PERSON` (`person_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_NEGATIVE_9` FOREIGN KEY (`shutter_speed`) REFERENCES `SHUTTER_SPEED` (`shutter_speed`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog negatives (which includes positives/slide too). Negatives are created by cameras, belong to films and can be used to create scans or prints.';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `PRINT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `PRINT` (
  `print_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for the print',
  `negative_id` int(11) DEFAULT NULL COMMENT 'ID of the negative that this print was made from',
  `date` date DEFAULT NULL COMMENT 'The date that the print was made',
  `paper_stock_id` int(11) DEFAULT NULL COMMENT 'ID of the paper stock used',
  `height` decimal(4,1) DEFAULT NULL COMMENT 'Height of the print in inches',
  `width` decimal(4,1) DEFAULT NULL COMMENT 'Width of the print in inches',
  `aperture` decimal(3,1) DEFAULT NULL COMMENT 'Aperture used to make this print (numerical part only, e.g. 5.6)',
  `exposure_time` decimal(5,1) DEFAULT NULL COMMENT 'Exposure time of this print in seconds',
  `filtration_grade` decimal(2,1) DEFAULT NULL COMMENT 'Contrast grade of paper used',
  `development_time` int(11) DEFAULT NULL COMMENT 'Development time of this print in seconds',
  `bleach_time` time DEFAULT NULL COMMENT 'Duration of bleaching',
  `toner_id` int(11) DEFAULT NULL COMMENT 'ID of the first toner used to make this print',
  `toner_dilution` varchar(6) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Dilution of the first toner used to make this print',
  `toner_time` time DEFAULT NULL COMMENT 'Duration of first toning',
  `2nd_toner_id` int(11) DEFAULT NULL COMMENT 'ID of the second toner used to make this print',
  `2nd_toner_dilution` varchar(6) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Dilution of the second toner used to make this print',
  `2nd_toner_time` time DEFAULT NULL COMMENT 'Duration of second toning',
  `own` tinyint(1) DEFAULT NULL COMMENT 'Whether we currently own this print',
  `location` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'The place where this print is currently',
  `sold_price` decimal(5,2) DEFAULT NULL COMMENT 'Sale price of the print',
  `enlarger_id` int(11) DEFAULT NULL COMMENT 'ID of the enlarger used to make this print',
  `lens_id` int(11) DEFAULT NULL COMMENT 'ID of the lens used to make this print',
  `developer_id` int(11) DEFAULT NULL COMMENT 'ID of the developer used to develop this print',
  `fine` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a fine print',
  `notes` text COLLATE utf8mb4_unicode_ci COMMENT 'Freeform notes about this print, e.g. dodging, burning & complex toning',
  `archive_id` int(11) DEFAULT NULL COMMENT 'ID of the archive to which this print belongs',
  `printer_id` int(11) DEFAULT NULL COMMENT 'ID of the person who made this print',
  PRIMARY KEY (`print_id`),
  KEY `fk_PRINT_1` (`paper_stock_id`),
  KEY `fk_PRINT_2` (`negative_id`),
  KEY `fk_PRINT_3` (`toner_id`),
  KEY `fk_PRINT_4` (`enlarger_id`),
  KEY `fk_PRINT_6` (`developer_id`),
  KEY `fk_PRINT_5_idx` (`lens_id`),
  KEY `fk_PRINT_7_idx` (`archive_id`),
  KEY `fk_PRINT_8_idx` (`printer_id`),
  CONSTRAINT `fk_PRINT_1` FOREIGN KEY (`paper_stock_id`) REFERENCES `PAPER_STOCK` (`paper_stock_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_2` FOREIGN KEY (`negative_id`) REFERENCES `NEGATIVE` (`negative_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_3` FOREIGN KEY (`toner_id`) REFERENCES `TONER` (`toner_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_4` FOREIGN KEY (`enlarger_id`) REFERENCES `ENLARGER` (`enlarger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_5` FOREIGN KEY (`lens_id`) REFERENCES `LENS` (`lens_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_6` FOREIGN KEY (`developer_id`) REFERENCES `DEVELOPER` (`developer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_PRINT_7` FOREIGN KEY (`archive_id`) REFERENCES `ARCHIVE` (`archive_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_PRINT_8` FOREIGN KEY (`printer_id`) REFERENCES `PERSON` (`person_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalog prints made from negatives';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `SCAN`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `SCAN` (
  `scan_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this scan',
  `negative_id` int(11) DEFAULT NULL COMMENT 'ID of the negative that was scanned',
  `print_id` int(11) DEFAULT NULL COMMENT 'ID of the print  that was scanned',
  `filename` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Filename of the scan',
  `date` date DEFAULT NULL COMMENT 'Date that this scan was made',
  `colour` tinyint(1) DEFAULT NULL COMMENT 'Whether this is a colour image',
  `width` int(11) DEFAULT NULL COMMENT 'Width of the scanned image in pixels',
  `height` int(11) DEFAULT NULL COMMENT 'Height of the scanned image in pixels',
  PRIMARY KEY (`scan_id`),
  KEY `fk_SCAN_1_idx` (`negative_id`),
  KEY `fk_SCAN_2_idx` (`print_id`),
  CONSTRAINT `fk_SCAN_1` FOREIGN KEY (`negative_id`) REFERENCES `NEGATIVE` (`negative_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_SCAN_2` FOREIGN KEY (`print_id`) REFERENCES `PRINT` (`print_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to record all the images that have been scanned digitally';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `TO_PRINT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `TO_PRINT` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this table',
  `negative_id` int(11) DEFAULT NULL COMMENT 'Negative ID to be printed',
  `width` int(11) DEFAULT NULL COMMENT 'Width of print to be made',
  `height` int(11) DEFAULT NULL COMMENT 'Height of print to be made',
  `printed` tinyint(1) DEFAULT '0' COMMENT 'Whether the print has been made',
  `print_id` int(11) DEFAULT NULL COMMENT 'ID of print made',
  `recipient` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Recipient of the print',
  `added` date DEFAULT NULL COMMENT 'Date that record was added',
  PRIMARY KEY (`id`),
  KEY `fk_TO_PRINT_1_idx` (`negative_id`),
  CONSTRAINT `fk_TO_PRINT_1` FOREIGN KEY (`negative_id`) REFERENCES `NEGATIVE` (`negative_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to catalogue negatives that should be printed';
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `EXHIBIT`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `EXHIBIT` (
  `exhibit_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID for this exhibit',
  `exhibition_id` int(11) DEFAULT NULL COMMENT 'ID of the exhibition',
  `print_id` int(11) DEFAULT NULL COMMENT 'ID of the print',
  PRIMARY KEY (`exhibit_id`),
  KEY `fk_EXHIBIT_1_idx` (`exhibition_id`),
  KEY `fk_EXHIBIT_2_idx` (`print_id`),
  CONSTRAINT `fk_EXHIBIT_1` FOREIGN KEY (`exhibition_id`) REFERENCES `EXHIBITION` (`exhibition_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_EXHIBIT_2` FOREIGN KEY (`print_id`) REFERENCES `PRINT` (`print_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to record which prints were displayed in which exhibitions';
SET character_set_client = @saved_cs_client;
SET TIME_ZONE=@OLD_TIME_ZONE;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT;
SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS;
SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION;
SET SQL_NOTES=@OLD_SQL_NOTES;

