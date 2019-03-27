SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT;
SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS;
SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION;
SET NAMES utf8;
SET @OLD_TIME_ZONE=@@TIME_ZONE;
SET TIME_ZONE='+00:00';
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;

LOCK TABLES `ACCESSORY_TYPE` WRITE;
ALTER TABLE `ACCESSORY_TYPE` DISABLE KEYS;
INSERT INTO `ACCESSORY_TYPE` VALUES (1,'Power winder'),(2,'Battery grip'),(3,'Viewfinder'),(4,'Focusing screen'),(5,'Film back'),(6,'Lens hood'),(7,'Case');
ALTER TABLE `ACCESSORY_TYPE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `ARCHIVE_TYPE` WRITE;
ALTER TABLE `ARCHIVE_TYPE` DISABLE KEYS;
INSERT INTO `ARCHIVE_TYPE` VALUES (1,'Film'),(2,'Slide'),(3,'Print');
ALTER TABLE `ARCHIVE_TYPE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `BODY_TYPE` WRITE;
ALTER TABLE `BODY_TYPE` DISABLE KEYS;
INSERT INTO `BODY_TYPE` VALUES (1,'Box'),(2,'Compact'),(3,'Folder'),(4,'SLR'),(5,'TLR'),(6,'Bridge'),(7,'View'),(8,'Pistol grip');
ALTER TABLE `BODY_TYPE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `EXPOSURE_PROGRAM` WRITE;
ALTER TABLE `EXPOSURE_PROGRAM` DISABLE KEYS;
INSERT INTO `EXPOSURE_PROGRAM` VALUES (0,'Fixed'),(1,'Manual'),(2,'Program AE'),(3,'Aperture-priority AE'),(4,'Shutter speed priority AE'),(5,'Creative (Slow speed)'),(6,'Action (High speed)'),(7,'Portrait'),(8,'Landscape'),(9,'Bulb');
ALTER TABLE `EXPOSURE_PROGRAM` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `FORMAT` WRITE;
ALTER TABLE `FORMAT` DISABLE KEYS;
INSERT INTO `FORMAT` VALUES (1,'120',0),(2,'135',0),(3,'620',0),(4,'APS-C',1),(5,'1/1.6\"',1),(6,'Super 8mm',0),(7,'8mm',0),(8,'Quarter plate',0),(9,'Polaroid 600',0),(10,'2.25x3.25\" sheet',0),(11,'6.5x9 sheet',0),(12,'4x5\"',0),(13,'126',0),(14,'16mm',0),(15,'110',0),(16,'3¼x4\" sheet',0),(17,'116',0),(18,'127',0);
ALTER TABLE `FORMAT` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `MANUFACTURER` WRITE;
ALTER TABLE `MANUFACTURER` DISABLE KEYS;
INSERT INTO `MANUFACTURER` VALUES (1,'Boots','Nottingham','England','http://www.boots.com/',1849,NULL),(2,'Braun','Nuremberg','Germany','http://www.braun-phototechnik.de/',1915,NULL),(3,'Canon','Tokyo','Japan','http://www.canon.com/',1937,NULL),(4,'Standard Cameras',NULL,'England',NULL,1931,NULL),(5,'Efke','Samobor','Croatia',NULL,1947,2012),(6,'Fuji','Tokyo','Japan','http://www.fujifilm.com/',1934,NULL),(7,'Halina',NULL,'China',NULL,1906,NULL),(8,'Homemade',NULL,'England',NULL,NULL,NULL),(9,'Ilford','Ilford','England','http://www.ilfordphoto.com/',1879,NULL),(10,'KMZ','Krasnogorsk','Russia','http://www.zenit-foto.ru/',1942,NULL),(11,'Kodak','Rochester','USA','http://www.kodak.com/',1892,NULL),(12,'LOMO','St. Petersburg','Russia','http://www.lomoplc.com/',1932,1914),(13,'Maco',NULL,'Germany','http://www.maco-photo.de/',NULL,NULL),(14,'Makinon','Tokyo','Japan',NULL,1967,1985),(15,'Mamiya','Tokyo','Japan','http://www.mamiyaleaf.com/',1940,NULL),(16,'Olympus','Tokyo','Japan','http://www.olympus.co.uk/',1919,NULL),(17,'Opteka',NULL,'Japan',NULL,2002,NULL),(18,'Samyang','Masan','South Korea','http://www.syopt.co.kr/',1972,NULL),(19,'Tamron','Saitama','Japan','http://www.tamron.co.jp/en/',1950,NULL),(20,'Unknown',NULL,NULL,NULL,NULL,NULL),(21,'Voigtlander','Vienna','Austria','http://www.voigtlaender.de/',1756,NULL),(23,'Tokina',NULL,'Japan','http://www.tokinalens.com/',1970,NULL),(24,'Kenko','Tokyo','Japan','http://www.kenko-tokina.co.jp/e/index.html',1928,NULL),(25,'Paragon',NULL,'Japan',NULL,NULL,NULL),(26,'Agfa','Berlin','Germany',NULL,1867,NULL),(27,'LPL',NULL,'Japan','http://www.lpl-web.co.jp/',1953,NULL),(28,'Durst',NULL,'Italy',NULL,1936,NULL),(29,'Toshikato',NULL,'Japan',NULL,NULL,NULL),(30,'Vivitar',NULL,'USA','http://www.vivitar.com/',1938,NULL),(31,'Tudor',NULL,'Japan',NULL,NULL,NULL),(32,'Rollei','Braunschweig','Germany','http://www.rollei.com/',1920,NULL),(33,'Komamura',NULL,'Japan',NULL,1933,NULL),(34,'Ensign','London','England',NULL,1903,NULL),(35,'Ross','London','England',NULL,1830,NULL),(36,'Kentmere','Kentmere','England','http://www.kentmere.co.uk/',NULL,NULL),(37,'Jessops','Leicester','England','http://www.jessops.com/',1935,NULL),(38,'Cosina','Nakano','Japan','http://www.cosina.co.jp/seihin/voigt/english/',1959,NULL),(40,'Manfrotto','Cassola','Italy','http://www.manfrotto.co.uk/',1974,NULL),(41,'Pentax','Tokyo','Japan','http://www.pentax.co.uk/',1919,NULL),(42,'Blazzeo',NULL,'China',NULL,NULL,NULL),(43,'Cobra',NULL,NULL,NULL,NULL,NULL),(44,'Sunpak',NULL,'Japan','http://www.sunpak.jp/english/',1963,NULL),(45,'Miranda',NULL,'Japan',NULL,1955,NULL),(46,'Hanimex',NULL,'Australia',NULL,1947,NULL),(47,'Ohnar',NULL,'Japan',NULL,NULL,NULL),(48,'Celestron',NULL,'USA','http://www.celestron.com/',1964,NULL),(49,'Sigma',NULL,'Japan','http://www.sigma-imaging-uk.com/',1961,NULL),(50,'Lancaster',NULL,'England',NULL,1835,NULL),(51,'Schneider-Kreuznach',NULL,'Germany','http://www.schneiderkreuznach.com/foto_e/foto',1913,NULL),(52,'Leitz',NULL,'Germany','http://uk.leica-camera.com/home/',1913,NULL),(53,'Aldis',NULL,'England',NULL,1901,NULL),(54,'Revelation',NULL,'Taiwan',NULL,NULL,NULL),(55,'Pentacon','Dresden','Germany','http://www.pentacon-dresden.de/',1959,NULL),(57,'Chinon','Nagano','Japan','http://www.chinon.co.jp/',1948,2004),(58,'Dollond & Newcombe',NULL,'England',NULL,NULL,NULL),(59,'Loonar Goupe',NULL,'China',NULL,NULL,NULL),(60,'Polaroid',NULL,'USA','http://www.polaroid.com/',1937,NULL),(61,'The Impossible Project','Enschede','Netherlands','https://www.the-impossible-project.com/',2008,NULL),(62,'Lomography',NULL,'Austria','http://www.lomography.com/',1992,NULL),(63,'Yongnuo',NULL,'China','http://en.yongnuo.com.cn/',NULL,NULL),(64,'Graflex',NULL,'USA','http://graflex.org/',1898,NULL),(65,'Tokyo Kogaku',NULL,'Japan','http://www.topcon.co.jp/en/index.html',1932,NULL),(66,'Linhof',NULL,'Germany','http://www.linhof.com/index-e.html',1887,NULL),(67,'De Vere',NULL,'England',NULL,NULL,NULL),(68,'Nikon','Tokyo','Japan','http://www.nikkor.com/',1932,NULL),(69,'Konica','Tokyo','Japan',NULL,1873,2003),(70,'Feinwerk Technik',NULL,'Germany',NULL,NULL,NULL),(71,'Meopta','Bratislava','Slovakia',NULL,1933,NULL),(72,'ORWO','Wolfen','Germany','http://www.filmotec.de/',NULL,NULL),(73,'Fotospeed','Corsham','England','http://www.fotospeed.com/',NULL,NULL),(74,'Shackman','London','England',NULL,NULL,NULL),(75,'Dallmeyer',NULL,'England',NULL,1860,NULL),(76,'Sekonic',NULL,NULL,NULL,NULL,NULL),(77,'Zeiss Ikon',NULL,'Germany',NULL,NULL,NULL),(78,'Realt',NULL,'France',NULL,NULL,NULL),(79,'Soligor','Stuttgart','Germany',NULL,1968,NULL),(80,'Bowens','London','England',NULL,1923,NULL),(81,'Optomax',NULL,'Japan',NULL,NULL,NULL),(82,'Philips',NULL,'Holland',NULL,1891,NULL),(83,'Bausch & Lomb',NULL,NULL,NULL,NULL,NULL),(84,'Bell & Howell',NULL,NULL,NULL,NULL,NULL),(85,'Kitvision',NULL,'UK',NULL,NULL,NULL),(86,'MDT',NULL,NULL,NULL,NULL,NULL),(87,'Jacquard',NULL,'USA',NULL,1988,NULL),(88,'Neewer',NULL,'China',NULL,NULL,NULL),(89,'Holga',NULL,NULL,NULL,NULL,NULL),(90,'Kawauso-Shoten',NULL,'Japan',NULL,NULL,NULL),(91,'Minolta',NULL,NULL,NULL,NULL,NULL),(92,'Roeschlein-Kreuznach',NULL,'Germany',NULL,NULL,NULL),(93,'Staeble',NULL,'Germany',NULL,1908,NULL),(94,'Tetenal',NULL,NULL,NULL,NULL,NULL),(95,'Foma',NULL,NULL,NULL,NULL,NULL),(96,'Tucht','Dusseldorf','Germany',NULL,NULL,NULL),(97,'Rodenstock',NULL,'Germany',NULL,NULL,NULL),(98,'Roniflex',NULL,NULL,NULL,NULL,NULL);
ALTER TABLE `MANUFACTURER` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `METERING_TYPE` WRITE;
ALTER TABLE `METERING_TYPE` DISABLE KEYS;
INSERT INTO `METERING_TYPE` VALUES (1,'Cadmium sulphide'),(2,'Selenium'),(7,'Silicon');
ALTER TABLE `METERING_TYPE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `METERING_MODE` WRITE;
ALTER TABLE `METERING_MODE` DISABLE KEYS;
INSERT INTO `METERING_MODE` VALUES (0,'None'),(1,'Average'),(2,'Center-weighted average'),(3,'Spot'),(4,'Multi-spot'),(5,'Multi-segment'),(6,'Partial');
ALTER TABLE `METERING_MODE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `NEGATIVE_SIZE` WRITE;
ALTER TABLE `NEGATIVE_SIZE` DISABLE KEYS;
INSERT INTO `NEGATIVE_SIZE` VALUES (5,70.0,56.0,'6x7',0.48,3920,1.25),(6,56.0,56.0,'6x6',0.55,3136,1.00),(7,56.0,41.5,'6x4.5',0.62,2324,1.35),(8,84.0,56.0,'6x9',0.43,4704,1.50),(9,36.0,24.0,'35mm',1.00,864,1.50),(10,22.2,14.8,'APS-C',1.62,329,1.50),(11,18.0,24.0,'35mm half frame',1.44,432,0.75),(12,8.0,6.0,'1/1.6\"',4.33,48,1.33),(13,5.8,4.0,'Super 8mm',6.14,23,1.45),(14,4.5,3.3,'8mm',7.75,15,1.36),(15,110.0,82.6,'Quarter plate',0.31,9086,1.33),(16,79.0,79.0,'Integral 600',0.39,6241,1.00),(17,36.0,12.0,'35mm panoramic',1.14,432,3.00),(18,88.9,63.5,'6.5x9',0.40,5645,1.40),(19,82.0,57.0,'2.25\" x 3.25\"',0.43,4674,1.44),(20,125.0,100.0,'4x5',0.27,12500,1.25),(21,238.0,190.0,'8x10',0.14,45220,1.25),(22,28.0,28.0,'126',1.09,784,1.00),(23,14.0,10.0,'16mm',2.51,140,1.40),(24,17.0,13.0,'110',2.02,221,1.31),(25,24.0,24.0,'1\"x1\"',1.27,576,1.00),(26,108.0,63.5,'2.5\" x 4.25\"',0.35,6858,1.70),(27,108.0,55.0,'6x11',0.36,5940,1.96),(28,60.0,40.0,'1?\" x 2½\"',0.60,2400,1.50),(29,12.5,7.4,'Super 16mm',2.98,93,1.69);
ALTER TABLE `NEGATIVE_SIZE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `PROCESS` WRITE;
ALTER TABLE `PROCESS` DISABLE KEYS;
INSERT INTO `PROCESS` VALUES (1,'C41',1,0),(2,'B&W',0,0),(3,'E6',1,1),(4,'Instant',0,1),(5,'K-14',1,1),(6,'B&W Reversal',0,1),(7,'Cyanotype',0,0);
ALTER TABLE `PROCESS` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `SHUTTER_SPEED` WRITE;
ALTER TABLE `SHUTTER_SPEED` DISABLE KEYS;
INSERT INTO `SHUTTER_SPEED` VALUES ('0.3',0.30000),('0.7',0.70000),('1',1.00000),('1.5',1.50000),('1/10',0.10000),('1/100',0.01000),('1/1000',0.00100),('1/12',0.08333),('1/125',0.00800),('1/1250',0.00080),('1/15',0.06670),('1/150',0.00667),('1/1500',0.00067),('1/180',0.00556),('1/2',0.50000),('1/20',0.05000),('1/200',0.00500),('1/2000',0.00050),('1/24',0.04167),('1/25',0.04000),('1/250',0.00400),('1/3',0.33333),('1/30',0.03333),('1/300',0.00333),('1/3000',0.00033),('1/350',0.00286),('1/4',0.25000),('1/40',0.02500),('1/400',0.00200),('1/4000',0.00025),('1/45',0.02222),('1/5',0.20000),('1/50',0.02000),('1/500',0.00200),('1/6',0.16667),('1/60',0.01667),('1/6000',0.00017),('1/640',0.00156),('1/750',0.00133),('1/8',0.12500),('1/800',0.00125),('1/8000',0.00013),('1/90',0.01111),('10',10.00000),('11',11.00000),('12',12.00000),('120',99.99999),('14',14.00000),('15',15.00000),('16',16.00000),('17',17.00000),('18',18.00000),('180',99.99999),('2',2.00000),('20',20.00000),('22',22.00000),('240',99.99999),('3',3.00000),('30',30.00000),('32',32.00000),('4',4.00000),('45',45.00000),('5',5.00000),('6',6.00000),('60',60.00000),('64',64.00000),('7',7.00000),('8',8.00000),('B',NULL),('T',NULL);
ALTER TABLE `SHUTTER_SPEED` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `SHUTTER_TYPE` WRITE;
ALTER TABLE `SHUTTER_TYPE` DISABLE KEYS;
INSERT INTO `SHUTTER_TYPE` VALUES (1,'Focal plane (horizontal travelling)'),(2,'Leaf'),(3,'Rotary'),(4,'Focal plane (vertical travelling)'),(5,'Sliding'),(6,'Ball bearing'),(7,'Electronic');
ALTER TABLE `SHUTTER_TYPE` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `FILMSTOCK` WRITE;
ALTER TABLE `FILMSTOCK` DISABLE KEYS;
INSERT INTO `FILMSTOCK` VALUES (1,6,'Reala 100',100,1,1,1),(2,9,'FP4+ 125',125,0,2,1),(3,9,'HP5+ 400',400,0,2,1),(4,6,'Acros 100',100,0,2,1),(5,6,'Neopan 1600',1600,0,2,1),(6,11,'Gold',400,1,1,1),(7,6,'S 400',400,1,1,1),(8,11,'GT 800',800,1,1,1),(9,6,'S 200',200,1,1,1),(10,9,'Delta 100',100,0,2,1),(11,9,'Delta 400',400,0,2,1),(12,13,'IR820',400,0,2,1),(13,20,'Unknown',200,1,1,1),(14,5,'R50',50,0,2,1),(15,5,'R25',25,0,2,1),(16,9,'FP3',NULL,0,2,1),(17,11,'200',200,1,1,1),(18,1,'200',200,1,1,1),(19,11,'VR Plus 400',400,1,1,1),(20,9,'Pan F+ 50',50,0,2,1),(30,5,'IR820',100,0,2,1),(31,6,'Pro 160S',160,1,1,1),(32,9,'Pan 100',100,0,2,1),(33,31,'Colour 200',200,1,1,1),(34,11,'Ektar 100',100,1,1,1),(35,11,'Kodacolor 200',200,1,1,1),(36,11,'Elitechrome 100',100,1,3,1),(37,26,'Vista Plus 200',200,1,1,1),(38,31,'XLX 100',100,1,1,1),(39,36,'100',100,0,2,1),(40,11,'Ektar 125',125,1,1,1),(41,37,'Pan 100S',100,0,2,1),(42,36,'Select RC',6,0,2,0),(43,11,'Gold 200',200,1,1,1),(44,61,'PX 600 Silver Shade',600,0,4,1),(45,6,'Neopan 400',400,0,2,1),(46,11,'Kodachrome 40',40,1,5,1),(47,69,'VX 200',200,1,1,1),(48,11,'Kodalith',12,0,2,0),(49,72,'ORWOChrom UK17',40,1,3,1),(50,11,'Ektachrome 50 Tungsten',50,1,3,1),(51,11,'Plus-X pan',125,0,2,1),(52,9,'Delta 3200',3200,0,2,1),(53,5,'IR820 Aura',100,0,2,1),(54,6,'Sensia 200',200,1,3,1),(55,11,'Electron Image Film SO-163',12,0,2,0),(56,6,'Superia 200',200,1,1,1),(57,6,'Velvia 50',50,1,3,1),(58,6,'Velvia 100F',100,1,3,1),(59,6,'Superia X-Tra',400,1,1,1),(60,6,'Superia 100',100,1,1,1),(61,26,'HDC Plus',200,1,1,1),(62,90,'Rera Pan',100,0,2,1),(63,11,'High-Speed Infrared HIE',NULL,0,2,1),(64,1,'200 Colour Slide',200,1,3,1),(65,11,'VR Plus 200',200,1,1,1),(66,9,'FP4',125,0,2,1);
ALTER TABLE `FILMSTOCK` ENABLE KEYS;
UNLOCK TABLES;

LOCK TABLES `MOUNT` WRITE;
ALTER TABLE `MOUNT` DISABLE KEYS;
INSERT INTO `MOUNT` VALUES (1,'EF',0,0,'Bayonet','Camera','EF cameras can not take EF-S lenses',0,3),(2,'EF-S',0,0,'Bayonet','Camera','EF cameras can not take EF-S lenses',1,3),(3,'M39 Rangefinder',0,0,'Screw','Camera','Has focus flange',0,NULL),(4,'OM',0,0,'Bayonet','Camera',NULL,0,16),(5,'RB',0,1,'Bayonet','Camera',NULL,0,15),(6,'FD',0,0,'Bayonet','Camera',NULL,0,3),(17,'lensboard',0,1,'Lens board','Camera',NULL,0,NULL),(19,'M42',0,0,'Screw','Camera',NULL,0,NULL),(22,'T',0,0,'Screw','Camera',NULL,0,NULL),(23,'Mamiya C',0,1,'Lens board','Camera',NULL,0,NULL),(24,'M39 Enlarger',0,0,'Screw','Enlarger','No focus flange',0,NULL),(25,'P',0,0,'Screw','Projector','~62mm diameter',0,NULL),(26,'P2',0,0,'Screw','Projector','~46mm diameter',0,NULL),(27,'Projector',0,0,'Screw','Projector','~42.5mm diameter',0,NULL),(28,'1.25\"',0,0,'Friction fit','Telescope',NULL,0,NULL),(29,'Hole-On EX',0,1,'Bayonet','Camera',NULL,0,NULL),(30,'64mm Enlarger',0,0,'Screw','Enlarger',NULL,0,NULL),(31,'M25 Enlarger',0,0,'Screw','Enlarger',NULL,0,NULL),(32,'FL',0,0,'Bayonet','Camera','Semi-compatible with FD',0,3),(33,'EX',0,0,'Screw','Camera','Fixed rear group',0,3),(34,'M41',0,0,'Screw','Camera','Scientific',0,NULL),(35,'EF-M',0,0,'Bayonet','Camera','Electronically compatible with EF',1,3),(36,'M645',0,0,'Bayonet','Camera',NULL,0,15),(37,'C',0,0,'Screw','Camera',NULL,0,NULL),(38,'R',0,0,'Bayonet','Camera','Semi-compatible with FL',0,3),(39,'M39 Paxette',0,0,'Screw','Camera','Longer register than M39 LTM',0,NULL);
ALTER TABLE `MOUNT` ENABLE KEYS;
UNLOCK TABLES;

SET TIME_ZONE=@OLD_TIME_ZONE;
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT;
SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS;
SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION;
SET SQL_NOTES=@OLD_SQL_NOTES;
