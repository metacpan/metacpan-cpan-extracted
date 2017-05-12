# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, asnmtap-3.002.003-distributed_mysql-v5.0.x.sql
# ---------------------------------------------------------------------------------------------------------

SET NAMES utf8;

SET SQL_MODE='';

create database if not exists `asnmtap`;

USE `asnmtap`;

SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';

/*Table structure for table catalog */

DROP TABLE IF EXISTS `catalog`;

CREATE TABLE `catalog` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `catalogName` varchar(64) NOT NULL default '',
  `catalogType` ENUM('central','federated','probe','distributed') NOT NULL DEFAULT 'probe',
  `databaseFQDN` varchar(64) NOT NULL default 'localhost',
  `databasePort` varchar(4) NOT NULL default '3306',
  `lastEventsID` int(11) NOT NULL default '0',
  `lastCommentsID` int(11) NOT NULL default '0',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`),
  KEY `catalogName` (`catalogName`)
) ENGINE=InnoDB;

/* Data for the table catalog */

insert into `catalog` (`catalogID`,`catalogName`,`catalogType`,`databaseFQDN`,`databasePort`,`lastEventsID`,`lastCommentsID`,`activated`) values ('CID','Central System Enterprise','central','localhost','3306',0,0,1);

/*Table structure for table `collectorDaemons` */

DROP TABLE IF EXISTS `collectorDaemons`;

CREATE TABLE `collectorDaemons` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `collectorDaemon` varchar(64) NOT NULL default '',
  `groupName` varchar(64) NOT NULL default '',
  `serverID` varchar(11) NOT NULL default '',
  `mode` char(1) NOT NULL default 'C',
  `dumphttp` char(1) NOT NULL default 'N',
  `status` char(1) NOT NULL default 'N',
  `debugDaemon` char(1) NOT NULL default 'F',
  `debugAllScreen` char(1) NOT NULL default 'F',
  `debugAllFile` char(1) NOT NULL default 'F',
  `debugNokFile` char(1) NOT NULL default 'F',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`collectorDaemon`),
  KEY `catalogID` (`catalogID`),
  KEY `serverID` (`serverID`),
  KEY `collectorDaemon` (`collectorDaemon`),
  KEY `collectorDaemons_ibfk_1` (`catalogID`,`serverID`),
  CONSTRAINT `collectorDaemons_ibfk_1` FOREIGN KEY (`catalogID`, `serverID`) REFERENCES `servers` (`catalogID`, `serverID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `collectorDaemons` */

insert into `collectorDaemons` (`catalogID`,`collectorDaemon`,`groupName`,`serverID`,`mode`,`dumphttp`,`status`,`debugDaemon`,`debugAllScreen`,`debugAllFile`,`debugNokFile`,`activated`) values ('CID','asnmtap01','Admin Collector [asnmtap01]','asnmtap01','C','U','N','F','F','F','F',1);
insert into `collectorDaemons` (`catalogID`,`collectorDaemon`,`groupName`,`serverID`,`mode`,`dumphttp`,`status`,`debugDaemon`,`debugAllScreen`,`debugAllFile`,`debugNokFile`,`activated`) values ('CID','asnmtap02','Admin Collector [asnmtap02]','asnmtap02','C','U','N','F','F','F','F',1);
insert into `collectorDaemons` (`catalogID`,`collectorDaemon`,`groupName`,`serverID`,`mode`,`dumphttp`,`status`,`debugDaemon`,`debugAllScreen`,`debugAllFile`,`debugNokFile`,`activated`) values ('CID','index','Production Daemon','CTP-CENTRAL','C','U','N','F','F','F','F',1);
insert into `collectorDaemons` (`catalogID`,`collectorDaemon`,`groupName`,`serverID`,`mode`,`dumphttp`,`status`,`debugDaemon`,`debugAllScreen`,`debugAllFile`,`debugNokFile`,`activated`) values ('CID','test','Test Daemon','CTP-CENTRAL','C','U','N','F','F','F','F',1);

/*Table structure for table `comments` */

DROP TABLE IF EXISTS `comments`;

CREATE TABLE `comments` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `id` int(11) NOT NULL auto_increment,
  `uKey` varchar(11) NOT NULL default '',
  `replicationStatus` ENUM('I','U','R') NOT NULL DEFAULT 'I',
  `title` varchar(75) NOT NULL default '',
  `remoteUser` varchar(11) NOT NULL default '',
  `instability` tinyint(1) NOT NULL default '0',
  `persistent` tinyint(1) NOT NULL default '0',
  `downtime` tinyint(1) NOT NULL default '0',
  `entryDate` date NOT NULL default '0000-00-00',
  `entryTime` time NOT NULL default '00:00:00',
  `entryTimeslot` varchar(10) NOT NULL default '0000000000',
  `activationDate` date NOT NULL default '0000-00-00',
  `activationTime` time NOT NULL default '00:00:00',
  `activationTimeslot` varchar(10) NOT NULL default '0000000000',
  `suspentionDate` date NOT NULL default '0000-00-00',
  `suspentionTime` time NOT NULL default '00:00:00',
  `suspentionTimeslot` varchar(10) NOT NULL default '9999999999',
  `solvedDate` date NOT NULL default '0000-00-00',
  `solvedTime` time NOT NULL default '00:00:00',
  `solvedTimeslot` varchar(10) NOT NULL default '0000000000',
  `problemSolved` tinyint(1) NOT NULL default '1',
  `commentData` blob NOT NULL,
  PRIMARY KEY (`catalogID`,`id`),
  KEY `catalogID` (`catalogID`),
  KEY `id` (`id`),
  KEY `uKey` (`uKey`),
  KEY `replicationStatus` (`replicationStatus`),
  KEY `remoteUser` (`remoteUser`),
  KEY `persistent` (`persistent`),
  KEY `downtime` (`downtime`),
  KEY `entryTimeslot` (`entryTimeslot`),
  KEY `activationTimeslot` (`activationTimeslot`),
  KEY `suspentionTimeslot` (`suspentionTimeslot`),
  KEY `solvedTimeslot` (`solvedTimeslot`),
  KEY `problemSolved` (`problemSolved`),
  KEY `comments_ibfk_1` (`catalogID`,`uKey`),
  KEY `comments_ibfk_2` (`catalogID`,`remoteUser`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`catalogID`, `uKey`) REFERENCES `plugins` (`catalogID`, `uKey`),
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`catalogID`, `remoteUser`) REFERENCES `users` (`catalogID`, `remoteUser`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `comments` */

/*Table structure for table `countries` */

DROP TABLE IF EXISTS `countries`;

CREATE TABLE `countries` (
  `countryID` char(2) NOT NULL default '',
  `countryName` varchar(45) default NULL,
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`countryID`),
  KEY `countryName` (`countryName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `countries` */

insert into `countries` (`countryID`,`countryName`,`activated`) values ('00','+ All Countries',1);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AD','Andorra',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AE','United Arab Emirates',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AF','Afghanistan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AG','Antigua and Barbuda',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AI','Anguilla',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AL','Albania',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AM','Armenia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AN','Netherlands Antilles',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AO','Angola',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AQ','Antarctica',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AR','Argentina',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AS','American Samoa',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AT','Austria',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AU','Australia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AW','Aruba',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('AZ','Azerbaijan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BA','Bosnia and Herzegovina',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BB','Barbados',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BD','Bangladesh',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BE','Belgium',1);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BF','Burkina Faso',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BG','Bulgaria',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BH','Bahrain',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BI','Burundi',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BJ','Benin',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BM','Bermuda',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BN','Brunei Darussalam',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BO','Bolivia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BR','Brazil',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BS','Bahamas',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BT','Bhutan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BV','Bouvet Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BW','Botswana',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BY','Belarus',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('BZ','Belize',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CA','Canada',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CC','Cocos (Keeling) Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CF','Central African Republic',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CG','Congo',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CH','Switzerland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CI','Cote D\'Ivoire',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CK','Cook Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CL','Chile',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CM','Cameroon',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CN','China',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CO','Colombia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CR','Costa Rica',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CS','Czechoslovakia (former)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CU','Cuba',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CV','Cape Verde',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CX','Christmas Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CY','Cyprus',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('CZ','Czech Republic',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DE','Germany',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DJ','Djibouti',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DK','Denmark',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DM','Dominica',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DO','Dominican Republic',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('DZ','Algeria',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('EC','Ecuador',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('EE','Estonia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('EG','Egypt',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('EH','Western Sahara',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ER','Eritrea',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ES','Spain',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ET','Ethiopia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FI','Finland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FJ','Fiji',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FK','Falkland Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FM','Micronesia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FO','Faroe Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FR','France',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('FX','France, Metropolitan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GA','Gabon',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GB','Great Britain (UK)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GD','Grenada',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GE','Georgia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GF','French Guiana',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GH','Ghana',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GI','Gibraltar',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GL','Greenland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GM','Gambia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GN','Guinea',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GP','Guadeloupe',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GQ','Equatorial Guinea',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GR','Greece',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GS','S. Georgia and S. Sandw',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GT','Guatemala',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GU','Guam',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GW','Guinea-Bissau',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('GY','Guyana',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HK','Hong Kong',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HM','Heard and McDonald Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HN','Honduras',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HR','Croatia (Hrvatska)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HT','Haiti',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('HU','Hungary',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ID','Indonesia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IE','Ireland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IL','Israel',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IN','India',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IO','British Indian Ocean',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IQ','Iraq',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IR','Iran',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IS','Iceland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('IT','Italy',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('JM','Jamaica',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('JO','Jordan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('JP','Japan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KE','Kenya',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KG','Kyrgyzstan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KH','Cambodia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KI','Kiribati',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KM','Comoros',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KN','Saint Kitts and Nevis',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KP','Korea (North)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KR','Korea (South)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KW','Kuwait',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KY','Cayman Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('KZ','Kazakhstan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LA','Laos',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LB','Lebanon',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LC','Saint Lucia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LI','Liechtenstein',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LK','Sri Lanka',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LR','Liberia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LS','Lesotho',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LT','Lithuania',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LU','Luxembourg',1);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LV','Latvia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('LY','Libya',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MA','Morocco',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MC','Monaco',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MD','Moldova',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MG','Madagascar',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MH','Marshall Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MK','Macedonia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ML','Mali',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MM','Myanmar',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MN','Mongolia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MO','Macau',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MP','Northern Mariana Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MQ','Martinique',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MR','Mauritania',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MS','Montserrat',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MT','Malta',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MU','Mauritius',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MV','Maldives',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MW','Malawi',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MX','Mexico',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MY','Malaysia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('MZ','Mozambique',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NA','Namibia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NC','New Caledonia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NE','Niger',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NF','Norfolk Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NG','Nigeria',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NI','Nicaragua',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NL','Netherlands',1);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NO','Norway',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NP','Nepal',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NR','Nauru',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NT','Neutral Zone',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NU','Niue',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('NZ','New Zealand (Aotearoa)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('OM','Oman',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PA','Panama',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PE','Peru',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PF','French Polynesia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PG','Papua New Guinea',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PH','Philippines',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PK','Pakistan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PL','Poland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PM','St. Pierre and Miquelon',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PN','Pitcairn',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PR','Puerto Rico',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PT','Portugal',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PW','Palau',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('PY','Paraguay',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('QA','Qatar',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('RE','Reunion',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('RO','Romania',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('RU','Russian Federation',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('RW','Rwanda',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SA','Saudi Arabia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('Sb','Solomon Islands',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SC','Seychelles',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SD','Sudan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SE','Sweden',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SG','Singapore',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SH','St. Helena',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SI','Slovenia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SJ','Svalbard and Jan Mayen',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SK','Slovak Republic',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SL','Sierra Leone',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SM','San Marino',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SN','Senegal',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SO','Somalia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SR','Suriname',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ST','Sao Tome and Principe',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SU','USSR (former)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SV','El Salvador',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SY','Syria',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('SZ','Swaziland',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TC','Turks and Caicos Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TD','Chad',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TF','French Southern Territo',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TG','Togo',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TH','Thailand',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TJ','Tajikistan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TK','Tokelau',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TM','Turkmenistan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TN','Tunisia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TO','Tonga',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TP','East Timor',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TR','Turkey',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TT','Trinidad and Tobago',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TV','Tuvalu',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TW','Taiwan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('TZ','Tanzania',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UA','Ukraine',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UG','Uganda',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UK','United Kingdom',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UM','US Minor Outlying Island',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('US','United States',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UY','Uruguay',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('UZ','Uzbekistan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VA','Vatican City State',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VC','Saint Vincent and the G.',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VE','Venezuela',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VG','Virgin Islands (British)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VI','Virgin Islands (U.S.)',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VN','Viet Nam',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('VU','Vanuatu',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('WF','Wallis and Futuna Islan',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('WS','Samoa',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('YE','Yemen',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('YT','Mayotte',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('YU','Yugoslavia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ZA','South Africa',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ZM','Zambia',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ZR','Zaire',0);
insert into `countries` (`countryID`,`countryName`,`activated`) values ('ZW','Zimbabwe',0);

/*Table structure for table `crontabs` */

DROP TABLE IF EXISTS `crontabs`;

CREATE TABLE `crontabs` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `lineNumber` char(2) NOT NULL default '',
  `uKey` varchar(11) NOT NULL default '',
  `collectorDaemon` varchar(64) NOT NULL default '',
  `arguments` varchar(1024) default '',
  `minute` varchar(167) NOT NULL default '*',
  `hour` varchar(61) NOT NULL default '*',
  `dayOfTheMonth` varchar(83) NOT NULL default '*',
  `monthOfTheYear` varchar(26) NOT NULL default '*',
  `dayOfTheWeek` varchar(13) NOT NULL default '*',
  `noOffline` varchar(12) default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`lineNumber`,`uKey`),
  KEY `catalogID` (`catalogID`),
  KEY `uKey` (`uKey`),
  KEY `collectorDaemon` (`collectorDaemon`),
  KEY `crontabs_ibfk_1` (`catalogID`,`collectorDaemon`),
  KEY `crontabs_ibfk_2` (`catalogID`,`uKey`),
  CONSTRAINT `crontabs_ibfk_1` FOREIGN KEY (`catalogID`, `collectorDaemon`) REFERENCES `collectorDaemons` (`catalogID`, `collectorDaemon`),
  CONSTRAINT `crontabs_ibfk_2` FOREIGN KEY (`catalogID`, `uKey`) REFERENCES `plugins` (`catalogID`, `uKey`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `crontabs` */

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','DUMMY-T1','test','','1-59/4','7-21/2','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','DUMMY-T2','test','-r 1','1-59/6','7-21/2','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','DUMMY-T3','test','-r 1','1-59/6','8-22/2','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','DUMMY-T4','test','-r 0','1-59/4','8-22/2','*','*','*','noTEST',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','DUMMY-T5','test','-r 0','1-5/2,17-21/2,33-37/2,49-53/2','*','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','MYSQLS-P-01','index','','*/5','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','MYSQLS-P-02','index','','*/5','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','NAGIOS-P-01','asnmtap01','','*/5','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','NAGIOS-P-02','asnmtap02','','*/5','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','DUMMY-T2','test','-r 2','3-59/6','7-21/2','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','DUMMY-T3','test','-r 2','3-59/6','8-22/2','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','DUMMY-T5','test','-r 0','9-13/2,25-29/2,41-45/2,57-59/2','*','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','DUMMY-T2','test','-r 3','3-59/6','8-22/2','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','DUMMY-T5','test','-r 2','7-59/8','*','*','*','*','noOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','03','DUMMY-T2','test','-r 0','1-59/6','8-22/2','*','*','*','noOFFLINE',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','CLUSTER-T1','test','-r 0','0-29/8,30-59/8','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','CLUSTER-T2','test','-r 0','0-7/2,30-37/2','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','CLUSTER-T3','test','-r 0','0-29/2','0-23/3','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','CLUSTER-T4','test','-r 0','*/2','0,1,9,10,18,19','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','CLUSTER-T1','test','-r 1','2-29/8,32-59/8','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','CLUSTER-T2','test','-r 1','8-15/2,38-45/2','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','CLUSTER-T3','test','-r 1','30-59/2','0-23/3','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','01','CLUSTER-T4','test','-r 1','*/2','2,3,11,12,20,21','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','CLUSTER-T1','test','-r 2','4-29/8,34-59/8','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','CLUSTER-T2','test','-r 2','16-23/2,46-53/2','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','CLUSTER-T3','test','-r 2','0-29/2','1-23/3','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','02','CLUSTER-T4','test','-r 2','*/2','4,5,13,14,22,23','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','03','CLUSTER-T1','test','-r 3','6-29/8,36-59/8','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','03','CLUSTER-T2','test','-r 3','24-29/2,54-59/2','*','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','03','CLUSTER-T3','test','-r 3','30-59/2','1-23/3','*','*','*','multiOFFLINE',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','03','CLUSTER-T4','test','-r 3','*/2','6,7,15,16','*','*','*','multiOFFLINE',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-01','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-02','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-03','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-04','test','','*/2','*','*','*','*','',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-10','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-11','test','','*/2','*','*','*','*','',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-20','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-21','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-22','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-23','test','','*/2','*','*','*','*','',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-30','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-31','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-32','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-33','test','','*/2','*','*','*','*','',1);

insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-40','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-41','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-42','test','','*/2','*','*','*','*','',1);
insert into `crontabs` (`catalogID`,`lineNumber`,`uKey`,`collectorDaemon`,`arguments`,`minute`,`hour`,`dayOfTheMonth`,`monthOfTheYear`,`dayOfTheWeek`,`noOffline`,`activated`) values ('CID','00','zCLUSTER-43','test','','*/2','*','*','*','*','',1);

/*Table structure for table `displayDaemons` */

DROP TABLE IF EXISTS `displayDaemons`;

CREATE TABLE `displayDaemons` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `displayDaemon` varchar(64) NOT NULL default '',
  `groupName` varchar(64) NOT NULL default '',
  `pagedir` varchar(11) NOT NULL default '',
  `serverID` varchar(11) NOT NULL default '',
  `loop` char(1) NOT NULL default 'T',
  `trigger` char(1) NOT NULL default 'T',
  `displayTime` char(1) NOT NULL default 'T',
  `lockMySQL` char(1) NOT NULL default 'F',
  `debugDaemon` char(1) NOT NULL default 'F',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`displayDaemon`),
  KEY `catalogID` (`catalogID`),
  KEY `serverID` (`serverID`),
  KEY `pagedir` (`catalogID`,`pagedir`),
  KEY `displayDaemon` (`displayDaemon`),
  KEY `displayDaemons_ibfk_2` (`catalogID`,`serverID`),
  CONSTRAINT `displayDaemons_ibfk_1` FOREIGN KEY (`catalogID`, `pagedir`) REFERENCES `pagedirs` (`catalogID`, `pagedir`),
  CONSTRAINT `displayDaemons_ibfk_2` FOREIGN KEY (`catalogID`, `serverID`) REFERENCES `servers` (`catalogID`, `serverID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `displayDaemons` */

insert into `displayDaemons` (`catalogID`,`displayDaemon`,`groupName`,`pagedir`,`serverID`,`loop`,`trigger`,`displayTime`,`lockMySQL`,`debugDaemon`,`activated`) values ('CID','index','Production Daemon','index','CTP-CENTRAL','T','F','T','F','F',1);
insert into `displayDaemons` (`catalogID`,`displayDaemon`,`groupName`,`pagedir`,`serverID`,`loop`,`trigger`,`displayTime`,`lockMySQL`,`debugDaemon`,`activated`) values ('CID','test','Test Daemon','test','CTP-CENTRAL','T','F','T','F','F',1);

/*Table structure for table `displayGroups` */

DROP TABLE IF EXISTS `displayGroups`;

CREATE TABLE `displayGroups` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `displayGroupID` int(11) NOT NULL auto_increment,
  `groupTitle` varchar(100) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`displayGroupID`),
  KEY `catalogID` (`catalogID`),
  KEY `displayGroupID` (`displayGroupID`),
  KEY `groupTitle` (`groupTitle`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `displayGroups` */

insert into `displayGroups` (`catalogID`,`displayGroupID`,`groupTitle`,`activated`) values ('CID',1,'Testing Collector & Display for the \'Application Monitor\'',1);
insert into `displayGroups` (`catalogID`,`displayGroupID`,`groupTitle`,`activated`) values ('CID',2,'Condenced View Test',1);
insert into `displayGroups` (`catalogID`,`displayGroupID`,`groupTitle`,`activated`) values ('CID',3,'90 Monitoring Servers',1);

/*Table structure for table `environment` */

DROP TABLE IF EXISTS `environment`;

CREATE TABLE `environment` (
  `environment` char(1) NOT NULL default 'L',
  `label` varchar(12) default 'Local',
  PRIMARY KEY (`environment`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `environment` */

insert into `environment` (`environment`,`label`) values ('A','Acceptation');
insert into `environment` (`environment`,`label`) values ('D','Development');
insert into `environment` (`environment`,`label`) values ('L','Local');
insert into `environment` (`environment`,`label`) values ('P','Production');
insert into `environment` (`environment`,`label`) values ('S','Simulation');
insert into `environment` (`environment`,`label`) values ('T','Test');

/*Table structure for table `events` */

DROP TABLE IF EXISTS `events`;

CREATE TABLE `events` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `id` int(11) NOT NULL auto_increment,
  `uKey` varchar(11) NOT NULL default '',
  `replicationStatus` ENUM('I','U','R') NOT NULL DEFAULT 'I',
  `test` varchar(512) NOT NULL default '',
  `title` varchar(75) NOT NULL default '',
  `status` varchar(9) NOT NULL default '',
  `startDate` date NOT NULL default '0000-00-00',
  `startTime` time NOT NULL default '00:00:00',
  `endDate` date NOT NULL default '0000-00-00',
  `endTime` time NOT NULL default '00:00:00',
  `duration` time NOT NULL default '00:00:00',
  `statusMessage` varchar(1024) NOT NULL default '',
  `perfdata` text,
  `step` smallint(6) NOT NULL default '0',
  `timeslot` varchar(10) NOT NULL default '',
  `instability` tinyint(1) NOT NULL default '9',
  `persistent` tinyint(1) NOT NULL default '9',
  `downtime` tinyint(1) NOT NULL default '9',
  `filename` varchar(254) default '',
  PRIMARY KEY (`catalogID`,`id`),
  KEY `catalogID` (`catalogID`),
  KEY `id` (`id`),
  KEY `uKey` (`uKey`),
  KEY `replicationStatus` (`replicationStatus`),
  KEY `key_test` (`test`),
  KEY `key_status` (`status`),
  KEY `key_startDate` (`startDate`),
  KEY `key_startTime` (`startTime`),
  KEY `key_endDate` (`endDate`),
  KEY `key_endTime` (`endTime`),
  KEY `key_timeslot` (`timeslot`),
  KEY `idx_persistent` (`persistent`),
  KEY `idx_downtime` (`downtime`),
  KEY `events_ibfk_1` (`catalogID`,`uKey`),
  CONSTRAINT `events_ibfk_1` FOREIGN KEY (`catalogID`,`uKey`) REFERENCES `plugins` (`catalogID`,`uKey`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `events` */

/*Table structure for table `eventsChangesLogData` */

DROP TABLE IF EXISTS `eventsChangesLogData`;

CREATE TABLE `eventsChangesLogData` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `uKey` varchar(11) NOT NULL default '',
  `replicationStatus` ENUM('I','U','R') NOT NULL DEFAULT 'I',
  `lastStatus` varchar(9) NOT NULL default '',
  `lastTimeslot` varchar(10) NOT NULL default '',
  `prevStatus` varchar(9) NOT NULL default '',
  `prevTimeslot` varchar(10) NOT NULL default '',
  `posTimeslot` int(11) NOT NULL DEFAULT '9',
  PRIMARY KEY (`catalogID`,`uKey`),
  KEY `catalogID` (`catalogID`),
  KEY `uKey` (`uKey`),
  KEY `replicationStatus` (`replicationStatus`),
  KEY `eventsChangesLogData_ibfk_1` (`catalogID`,`uKey`),
  CONSTRAINT `eventsChangesLogData_ibfk_1` FOREIGN KEY (`catalogID`,`uKey`) REFERENCES `plugins` (`catalogID`,`uKey`)
) ENGINE=InnoDB;

/*Data for the table `eventsChangesLogData` */

#
# Table structure for table eventsDisplayData
#

DROP TABLE IF EXISTS `eventsDisplayData`;

CREATE TABLE `eventsDisplayData` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `posTimeslot` int(11) NOT NULL DEFAULT '0',
  `uKey` varchar(11) NOT NULL default '',
  `replicationStatus` ENUM('I','U','R') NOT NULL DEFAULT 'I',
  `test` varchar(512) NOT NULL default '',
  `title` varchar(75) NOT NULL default '',
  `status` varchar(9) NOT NULL default '',
  `startDate` date NOT NULL default '0000-00-00',
  `startTime` time NOT NULL default '00:00:00',
  `endDate` date NOT NULL default '0000-00-00',
  `endTime` time NOT NULL default '00:00:00',
  `duration` time NOT NULL default '00:00:00',
  `statusMessage` varchar(1024) NOT NULL default '',
  `perfdata` text,
  `step` smallint(6) NOT NULL default '0',
  `timeslot` varchar(10) NOT NULL default '',
  `instability` tinyint(1) NOT NULL default '9',
  `persistent` tinyint(1) NOT NULL default '9',
  `downtime` tinyint(1) NOT NULL default '9',
  `filename` varchar(254) default '',
  PRIMARY KEY (`catalogID`,`uKey`,`posTimeslot`),
  KEY `catalogID` (`catalogID`),
  KEY `uKey` (`uKey`),
  KEY `posTimeslot` (`posTimeslot`),
  KEY `replicationStatus` (`replicationStatus`)
) ENGINE=InnoDB;

/*Data for the table `eventsDisplayData` */

/*Table structure for table `holidays` */

DROP TABLE IF EXISTS `holidays`;

CREATE TABLE `holidays` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `holidayID` varchar(14) NOT NULL default '0-0-0-0-00',
  `formule` char(1) NOT NULL default '0',
  `month` char(2) NOT NULL default '0',
  `day` char(2) NOT NULL default '0',
  `offset` char(3) NOT NULL default '0',
  `countryID` char(2) NOT NULL default '00',
  `holiday` varchar(64) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`holidayID`),
  KEY `catalogID` (`catalogID`),
  KEY `countryID` (`countryID`),
  KEY `holiday` (`holiday`),
  CONSTRAINT `holidays_ibfk_1` FOREIGN KEY (`countryID`) REFERENCES `countries` (`countryID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `holidays` */

insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-1-1-0-00','0','1','1','0','00','Nieuwjaarsdag',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-11-1-0-00','0','11','1','0','00','Allerheiligen',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-11-11-0-BE','0','11','11','0','BE','Wapenstilstand',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-11-15-0-BE','0','11','15','0','BE','Feestdag van de Duitstalige Gemeenschap',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-11-2-0-00','0','11','2','0','00','Allerzielen',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-12-25-0-00','0','12','25','0','00','Kerstmis',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-12-26-0-BE','0','12','26','0','BE','Kerstmis (2-de)',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-5-1-0-00','0','5','1','0','00','Feest van de arbeid',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-7-11-0-BE','0','7','11','0','BE','Feest van de Vlaamse Gemeenschap',0);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-7-21-0-BE','0','7','21','0','BE','Nationale feestdag',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-8-15-0-00','0','8','15','0','00','O.L.H. Hemelvaart',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','0-9-27-0-BE','0','9','27','0','BE','Feest van de Franse Gemeenschap',0);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','1-0-0-0-00','1','0','0','0','00','Pasen',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','1-0-0-1-00','1','0','0','1','00','Paasmaandag',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','1-0-0-39-00','1','0','0','39','00','O.L.V. Hemelvaart',1);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','1-0-0-49-00','1','0','0','49','00','Pinksteren',0);
insert into `holidays` (`catalogID`,`holidayID`,`formule`,`month`,`day`,`offset`,`countryID`,`holiday`,`activated`) values ('CID','1-0-0-50-00','1','0','0','50','00','Pinkstermaandag',1);

/*Table structure for table `holidaysBundle` */

DROP TABLE IF EXISTS `holidaysBundle`;

CREATE TABLE `holidaysBundle` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `holidayBundleID` int(11) NOT NULL auto_increment,
  `holidayBundleName` varchar(64) NOT NULL default '',
  `holidayID` varchar(254) NOT NULL default '',
  `countryID` char(2) NOT NULL default '00',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`holidayBundleID`),
  KEY `catalogID` (`catalogID`),
  KEY `holidayBundleID` (`holidayBundleID`),
  KEY `holidayBundleName` (`holidayBundleName`),
  KEY `holidayID` (`holidayID`),
  KEY `countryID` (`countryID`),
  CONSTRAINT `holidaysBundle_ibfk_1` FOREIGN KEY (`countryID`) REFERENCES `countries` (`countryID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `holidaysBundle` */

insert into `holidaysBundle` (`catalogID`,`holidayBundleID`,`holidayBundleName`,`holidayID`,`countryID`,`activated`) values ('CID',1,'None','/0-0-0-0-00/','BE',0);
insert into `holidaysBundle` (`catalogID`,`holidayBundleID`,`holidayBundleName`,`holidayID`,`countryID`,`activated`) values ('CID',2,'ASNMTAP','/0-11-1-0-00/0-11-2-0-00/0-5-1-0-00/0-9-27-0-BE/0-7-11-0-BE/0-11-15-0-BE/0-12-25-0-00/0-12-26-0-BE/0-7-21-0-BE/0-1-1-0-00/0-8-15-0-00/1-0-0-39-00/1-0-0-1-00/1-0-0-0-00/1-0-0-49-00/1-0-0-50-00/0-11-11-0-BE/','BE',1);

/*Table structure for table `language` */

DROP TABLE IF EXISTS `language`;

CREATE TABLE `language` (
  `keyLanguage` char(2) NOT NULL default '',
  `languageActive` tinyint(1) NOT NULL default '0',
  `languageName` varchar(16) default NULL,
  `languageFamily` varchar(24) default NULL,
  PRIMARY KEY (`keyLanguage`),
  KEY `languageName` (`languageName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `language` */

insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AA',0,'Afar','Hamitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AB',0,'Abkhazian','Ibero-Caucasian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AF',0,'Afrikaans','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AM',0,'Amharic','Semitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AR',0,'Arabic','Semitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AS',0,'Assamese','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AY',0,'Aymara','Amerindian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('AZ',0,'Azerbaijani','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BA',0,'Bashkir','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BE',0,'Byelorussian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BG',0,'Bulgarian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BH',0,'Bihari','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BI',0,'Bislama','[not given]');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BN',0,'Bengali; Bangla','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BO',0,'Tibetan','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('BR',0,'Breton','Celtic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('CA',0,'Catalan','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('CO',0,'Corsican','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('CS',0,'Czech','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('CY',0,'Welsh','Celtic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('DA',0,'Danish','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('DE',0,'German','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('DZ',0,'Bhutani','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('EL',0,'Greek','Latin/greek');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('EN',1,'English','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('EO',0,'Esperanto','International aux.');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ES',0,'Spanish','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ET',0,'Estonian','Finno-ugric');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('EU',0,'Basque','Basque');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('Fa',0,'Persian (farsi)','Iranian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('FI',0,'Finnish','Finno-ugric');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('FJ',0,'Fiji','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('FO',0,'Faroese','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('FR',1,'French','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('FY',0,'Frisian','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('GA',0,'Irish','Celtic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('Gd',0,'Scots GAELIC','Celtic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('GL',0,'Galician','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('GN',0,'Guarani','Amerindian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('GU',0,'Gujarati','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HA',0,'Hausa','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HE',0,'Hebrew','Semitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HI',0,'Hindi','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HR',0,'Croatian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HU',0,'Hungarian','Finno-ugric');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('HY',0,'Armenian','Indo-european (other)');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('IA',0,'Interlingua','International aux.');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ID',0,'Indonesian','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('IE',0,'Interlingue','International aux.');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('IK',0,'Inupiak','Eskimo');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('IS',0,'Icelandic','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('IT',0,'Italian','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('JA',0,'Japanese','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('JV',0,'Javanese','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KA',0,'Georgian','Ibero-caucasian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KK',0,'Kazakh','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KL',0,'Greenlandic','Eskimo');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KM',0,'Cambodian','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KN',0,'Kannada','Dravidian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KO',0,'Korean','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KS',0,'Kashmiri','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KU',0,'Kurdish','Iranian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('KY',0,'Kirghiz','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('LA',0,'Latin','Latin/greek');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('LN',0,'Lingala','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('LO',0,'Laothian','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('LT',0,'Lithuanian','Baltic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('LV',0,'Latvian; Lettish','Baltic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MG',0,'Malagasy','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MI',0,'Maori','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MK',0,'Macedonian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ML',0,'Malayalam','Dravidian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MN',0,'Mongolian','[not given]');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MO',0,'Moldavian','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MR',0,'Marathi','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MS',0,'Malay','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MT',0,'Maltese','Semitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('MY',0,'Burmese','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('NA',0,'Nauru','[not given]');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('NE',0,'Nepali','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('NL',1,'Dutch','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('NO',0,'Norwegian','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('OC',0,'Occitan','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('OM',0,'Afan (Oromo)','Hamitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('OR',0,'Oriya','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('PA',0,'Punjabi','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('PL',0,'Polish','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('PS',0,'Pashto; Pushto','Iranian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('PT',0,'Portuguese','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('QU',0,'Quechua','Amerindian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('RM',0,'Rhaeto-romance','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('RN',0,'Kurundi','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('RO',0,'Romanian','Romance');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('RU',0,'Russian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('RW',0,'Kinyarwanda','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SA',0,'Sanskrit','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SD',0,'Sindhi','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SG',0,'Sangho','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SH',0,'Serbo-croatian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SI',0,'Singhalese','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SK',0,'Slovak','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SL',0,'Slovenian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SM',0,'Samoan','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SN',0,'Shona','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SO',0,'Somali','Hamitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SQ',0,'Albanian','Indo-european (other)');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SR',0,'Serbian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SS',0,'Siswati','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ST',0,'Sesotho','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SU',0,'Sundanese','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SV',0,'Swedish','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('SW',0,'Swahili','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TA',0,'Tamil','Dravidian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TE',0,'Telugu','Dravidian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TG',0,'Tajik','Iranian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TH',0,'Thai','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TI',0,'Tigrinya','Semitic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TK',0,'Turkmen','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TL',0,'Tagalog','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TN',0,'Setswana','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TO',0,'Tonga','Oceanic/indonesian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TR',0,'Turkish','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TS',0,'Tsonga','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TT',0,'Tatar','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('TW',0,'Twi','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('UK',0,'Ukrainian','Slavic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('UR',0,'Urdu','Indian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('UZ',0,'Uzbek','Turkic/altaic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('VI',0,'Vietnamese','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('VO',0,'Volapuk','International aux.');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('WO',0,'Wolof','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('XH',0,'Xhosa','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('YI',0,'Yiddish','Germanic');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('YO',0,'Yoruba','Negro-african');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ZH',0,'Chinese','Asian');
insert into `language` (`keyLanguage`,`languageActive`,`languageName`,`languageFamily`) values ('ZU',0,'Zulu','Negro-african');

/*Table structure for table `pagedirs` */

DROP TABLE IF EXISTS `pagedirs`;

CREATE TABLE `pagedirs` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `pagedir` varchar(11) NOT NULL default '',
  `groupName` varchar(64) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`pagedir`),
  KEY `catalogID` (`catalogID`),
  KEY `pagedir` (`pagedir`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `pagedirs` */

insert into `pagedirs` (`catalogID`,`pagedir`,`groupName`,`activated`) values ('CID','index','Production View',1);
insert into `pagedirs` (`catalogID`,`pagedir`,`groupName`,`activated`) values ('CID','test','Test View',1);

/*Table structure for table `plugins` */

DROP TABLE IF EXISTS `plugins`;

CREATE TABLE `plugins` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `uKey` varchar(11) NOT NULL default '',
  `test` varchar(100) NOT NULL default '',
  `arguments` varchar(1024) default '',
  `argumentsOndemand` varchar(1024) default '',
  `title` varchar(75) NOT NULL default '',
  `trendline` smallint(6) NOT NULL default '0',
  `shortDescription` text,
  `percentage` tinyint(1) NOT NULL default '25',
  `tolerance` tinyint(1) NOT NULL default '5',
  `step` smallint(6) NOT NULL default '0',
  `ondemand` char(1) NOT NULL default '0',
  `production` char(1) NOT NULL default '0',
  `environment` char(1) NOT NULL default 'L',
  `pagedir` varchar(254) NOT NULL default '',
  `resultsdir` varchar(64) NOT NULL default '',
  `helpPluginFilename` varchar(100) default '<NIHIL>',
  `holidayBundleID` int(11) default '1',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`uKey`),
  KEY `catalogID` (`catalogID`),
  KEY `uKey` (`uKey`),
  KEY `resultsdir` (`resultsdir`),
  KEY `holidayBundleID` (`holidayBundleID`),
  KEY `test` (`test`),
  KEY `title` (`title`),
  KEY `plugins_ibfk_1` (`catalogID`,`resultsdir`),
  KEY `plugins_ibfk_2` (`catalogID`,`holidayBundleID`),
  CONSTRAINT `plugins_ibfk_1` FOREIGN KEY (`catalogID`, `resultsdir`) REFERENCES `resultsdir` (`catalogID`, `resultsdir`),
  CONSTRAINT `plugins_ibfk_2` FOREIGN KEY (`catalogID`,`holidayBundleID`) REFERENCES `holidaysBundle` (`catalogID`,`holidayBundleID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `plugins` */

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','DUMMY-T1','check_dummy.pl','-r 0','','[0] DUMMY-T1','',0,25,5,2,'1','1','T','/test/','test-01','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','DUMMY-T2','check_dummy.pl','','-r 1','[0] DUMMY-T2','',1,25,5,2,'1','1','T','/test/','test-02','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','DUMMY-T3','check_dummy.pl','','-r 2','[0] DUMMY-T3','',2,25,5,2,'1','1','T','/test/','test-03','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','DUMMY-T4','check_dummy.pl','','-r 3','[0] DUMMY-T4','',3,25,5,2,'1','1','T','/test/','test-04','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','DUMMY-T5','check_dummy.pl','','-r 0','[0] Condenced View test','',5,25,5,2,'1','1','T','/test/','test-05','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','CLUSTER-T1','check_dummy.pl','','','[1] CLUSTER-T1','',0,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','CLUSTER-T2','check_dummy.pl','','','[1] CLUSTER-T2','',0,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','CLUSTER-T3','check_dummy.pl','','','[1] CLUSTER-T3','',0,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','CLUSTER-T4','check_dummy.pl','','','[1] CLUSTER-T4','',0,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-01','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=non-OK --outOfDate=2 --message=\'non-OK\' --warning=0 --critical=4','','[2] CLUSTER-T1..CLUSTER-T4 - non-OK - w:0 - c:4','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-02','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=non-OK --outOfDate=2 --message=\'non-OK, ignoreOffline\' --warning=0 --critical=4 --ignoreOffline=T','','[2] CLUSTER-T1..CLUSTER-T4 - non-OK - w:0 - c:4 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-03','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=non-OK --outOfDate=2 --message=\'non-OK\' --warning=2 --critical=3','','[2] CLUSTER-T1..CLUSTER-T4 - non-OK - w:2 - c:3','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-04','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=non-OK --outOfDate=2 --message=\'non-OK, ignoreOffline\' --warning=2 --critical=3 --ignoreOffline=T','','[2] CLUSTER-T1..CLUSTER-T4 - non-OK - w:2 - c:3 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-10','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=highest-status --outOfDate=2 --message=\'highest-status\'','','[3] CLUSTER-T1..CLUSTER-T4 - highest-status','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-11','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=highest-status --outOfDate=2 --message=\'highest-status, ignoreOffline\' --ignoreOffline=T','','[3] CLUSTER-T1..CLUSTER-T4 - highest-status - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-20','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=percentage --outOfDate=2 --message=\'percentage\' --warning=25 --critical=100','','[4] CLUSTER-T1..CLUSTER-T4 - percentage - w:25 - c:100','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-21','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=percentage --outOfDate=2 --message=\'percentage, ignoreOffline\' --warning=25 --critical=100 --ignoreOffline=T','','[4] CLUSTER-T1..CLUSTER-T4 - percentage - w:25 - c:100 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-22','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=percentage --outOfDate=2 --message=\'percentage\' --warning=50 --critical=75','','[4] CLUSTER-T1..CLUSTER-T4 - percentage - w:50 - c:75','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-23','check_cluster.pl','--uKeys=\'CLUSTER-T1:CLUSTER-T2:CLUSTER-T3:CLUSTER-T4\' --server=localhost --user=asnmtap --passwd=asnmtap --method=percentage --outOfDate=2 --message=\'percentage, ignoreOffline\' --warning=50 --critical=75 --ignoreOffline=T','','[4] CLUSTER-T1..CLUSTER-T4 - percentage - w:50 - c:75 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-30','check_cluster.pl','--uKeys=\'CLUSTER-T1%10:CLUSTER-T2%20:CLUSTER-T3%30:CLUSTER-T4%40\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight\' --warning=25 --critical=100','','[5] CLUSTER-T1..CLUSTER-T4 - weight 10,20,30,40 - w:25 - c:100','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-31','check_cluster.pl','--uKeys=\'CLUSTER-T1%10:CLUSTER-T2%20:CLUSTER-T3%30:CLUSTER-T4%40\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight, ignoreOffline\' --warning=25 --critical=100 --ignoreOffline=T','','[5] CLUSTER-T1..CLUSTER-T4 - weight 10,20,30,40 - w:25 - c:100 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-32','check_cluster.pl','--uKeys=\'CLUSTER-T1%10:CLUSTER-T2%20:CLUSTER-T3%30:CLUSTER-T4%40\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight\' --warning=50 --critical=75','','[5] CLUSTER-T1..CLUSTER-T4 - weight 10,20,30,40 - w:50 - c:75','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-33','check_cluster.pl','--uKeys=\'CLUSTER-T1%10:CLUSTER-T2%20:CLUSTER-T3%30:CLUSTER-T4%40\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight, ignoreOffline\' --warning=50 --critical=75 --ignoreOffline=T','','[5] CLUSTER-T1..CLUSTER-T4 - weight 10,20,30,40 - w:50 - c:75 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-40','check_cluster.pl','--uKeys=\'CLUSTER-T1%40:CLUSTER-T2%30:CLUSTER-T3%20:CLUSTER-T4%10\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight\' --warning=25 --critical=100','','[6] CLUSTER-T1..CLUSTER-T4 - weight 40,30,20,10 - w:25 - c:100','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-41','check_cluster.pl','--uKeys=\'CLUSTER-T1%40:CLUSTER-T2%30:CLUSTER-T3%20:CLUSTER-T4%10\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight, ignoreOffline\' --warning=25 --critical=100 --ignoreOffline=T','','[6] CLUSTER-T1..CLUSTER-T4 - weight 40,30,20,10 - w:25 - c:100 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-42','check_cluster.pl','--uKeys=\'CLUSTER-T1%40:CLUSTER-T2%30:CLUSTER-T3%20:CLUSTER-T4%10\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight\' --warning=50 --critical=75','','[6] CLUSTER-T1..CLUSTER-T4 - weight 40,30,20,10 - w:50 - c:75','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','zCLUSTER-43','check_cluster.pl','--uKeys=\'CLUSTER-T1%40:CLUSTER-T2%30:CLUSTER-T3%20:CLUSTER-T4%10\' --server=localhost --user=asnmtap --passwd=asnmtap --method=weight --outOfDate=2 --message=\'weight, ignoreOffline\' --warning=50 --critical=75 --ignoreOffline=T','','[6] CLUSTER-T1..CLUSTER-T4 - weight 40,30,20,10 - w:50 - c:75 - ignoreOffline:T','',5,25,5,2,'0','1','T','/test/','test','<NIHIL>',1,1);

insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','MYSQLS-P-01','check_MySQL-database-replication.pl','-H asnmtap01 -1 asnmtap -2 \'\' -3 events -4 S -w 900 -c 1800','','Application Monitor / Nagios Server asnmtap01 - MySQL','',0,25,5,5,'1','1','P','/index/','MySQL','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','MYSQLS-P-02','check_MySQL-database-replication.pl','-H asnmtap02 -1 asnmtap -2 \'\' -3 events -4 S -w 900 -c 1800','','Application Monitor / Nagios Server asnmtap02 - MySQL','',0,25,5,5,'1','1','P','/index/','MySQL','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','NAGIOS-P-01','check_fs-stat.pl','--message=\'Nagios Central Server -asnmtap01\' --directory=/opt/nagios/var/ --wildcard=status.sav --type=F --files=0 --wAge=300 --cAge=600','','Nagios Central Server asnmtap01','',0,25,5,5,'0','1','P','/index/','AdminCollector','<NIHIL>',1,1);
insert into `plugins` (`catalogID`,`uKey`,`test`,`arguments`,`argumentsOndemand`,`title`,`shortDescription`,`trendline`,`percentage`,`tolerance`,`step`,`ondemand`,`production`,`environment`,`pagedir`,`resultsdir`,`helpPluginFilename`,`holidayBundleID`,`activated`) values ('CID','NAGIOS-P-02','check_fs-stat.pl','--message=\'Nagios Central Server -asnmtap02\' --directory=/opt/nagios/var/ --wildcard=status.sav --type=F --files=1 --wAge=300 --cAge=600','','Nagios Central Server asnmtap02','',0,25,5,5,'0','1','P','/index/','AdminCollector','<NIHIL>',1,1);

/*Table structure for table `reports` */

DROP TABLE IF EXISTS `reports`;

CREATE TABLE `reports` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `id` int(11) NOT NULL auto_increment,
  `uKey` varchar(11) NOT NULL default '',
  `reportTitle` varchar(100) NOT NULL default '',
  `periode` char(1) NOT NULL default 'F',
  `timeperiodID` int(11) NOT NULL default '1',
  `status` tinyint(1) NOT NULL default '0',
  `errorDetails` tinyint(1) NOT NULL default '0',
  `bar` tinyint(1) NOT NULL default '0',
  `hourlyAverage` tinyint(1) NOT NULL default '0',
  `dailyAverage` tinyint(1) NOT NULL default '0',
  `showDetails` tinyint(1) NOT NULL default '0',
  `showComments` tinyint(1) NOT NULL default '0',
  `showPerfdata` tinyint(1) NOT NULL default '0',
  `showTop20SlowTests` tinyint(1) NOT NULL default '0',
  `printerFriendlyOutput` tinyint(1) NOT NULL default '0',
  `formatOutput` varchar(4) NOT NULL default 'pdf',
  `userPassword` varchar(15) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`id`),
  KEY `catalogID` (`catalogID`),
  KEY `id` (`id`),
  KEY `uKey` (`uKey`),
  KEY `periode` (`periode`),
  KEY `reportTitle` (`reportTitle`),
  KEY `timeperiodID` (`timeperiodID`),
  KEY `reports_ibfk_1` (`catalogID`,`uKey`),
  KEY `reports_ibfk_2` (`catalogID`,`timeperiodID`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`catalogID`, `uKey`) REFERENCES `plugins` (`catalogID`, `uKey`),
  CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`catalogID`, `timeperiodID`) REFERENCES `timeperiods` (`catalogID`, `timeperiodID`)
) ENGINE=InnoDB;

/*Data for the table `reports` */

#
# Table structure for table reports_perfdata
#

DROP TABLE IF EXISTS `reports_perfdata`;

CREATE TABLE `reports_perfdata` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `uKey` varchar(11) NOT NULL,
  `metric_id` int(11) NOT NULL default '0',
  `times` varchar(64) NOT NULL,
  `percentiles` varchar(64) NOT NULL,
  `unit` enum('ms','s') NOT NULL default 's',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`catalogID`,`uKey`,`metric_id`),
  KEY `catalogID` (`catalogID`),
  KEY `uKey` (`uKey`),
  CONSTRAINT `reports_perfdata_ibfk_1` FOREIGN KEY (`catalogID`, `uKey`) REFERENCES `plugins` (`catalogID`, `uKey`)
) ENGINE=InnoDB;

/*Table structure for table `resultsdir` */

DROP TABLE IF EXISTS `resultsdir`;

CREATE TABLE `resultsdir` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `resultsdir` varchar(64) NOT NULL default '',
  `groupName` varchar(64) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`resultsdir`),
  KEY `catalogID` (`catalogID`),
  KEY `groupName` (`groupName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `resultsdir` */

insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','AdminCollector','Admin Collector',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','index','Production',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','MySQL','MySQL',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test-01','Subdir for DUMMY-01',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test-02','Subdir for DUMMY-02',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test-03','Subdir for DUMMY-03',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test-04','Subdir for DUMMY-04',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test-05','Condenced View test',1);
insert into `resultsdir` (`catalogID`,`resultsdir`,`groupName`,`activated`) values ('CID','test','CLUSTER',1);

/*Table structure for table `servers` */

DROP TABLE IF EXISTS `servers`;

CREATE TABLE `servers` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `serverID` varchar(11) NOT NULL default '',
  `serverTitle` varchar(64) default NULL,
  `typeServers` tinyint(1) NOT NULL default '0',
  `typeMonitoring` tinyint(1) NOT NULL default '0',
  `typeActiveServer` char(1) NOT NULL DEFAULT 'M',
  `masterFQDN` varchar(64) default NULL,
  `masterASNMTAP_PATH` varchar(64) NOT NULL default '/opt/asnmtap',
  `masterRSYNC_PATH` varchar(64) NOT NULL default '/usr/local/bin',
  `masterSSH_PATH` varchar(64) NOT NULL default '/usr/bin',
  `masterSSHlogon` varchar(15) default NULL,
  `masterSSHpasswd` varchar(32) default NULL,
  `masterDatabaseFQDN` varchar(64) NOT NULL default 'chablis.dvkhosting.com',
  `masterDatabasePort` varchar(4) NOT NULL default '3306',
  `slaveFQDN` varchar(64) default NULL,
  `slaveASNMTAP_PATH` varchar(64) NOT NULL default '/opt/asnmtap',
  `slaveRSYNC_PATH` varchar(64) NOT NULL default '/usr/local/bin',
  `slaveSSH_PATH` varchar(64) NOT NULL default '/usr/bin',
  `slaveSSHlogon` varchar(15) default NULL,
  `slaveSSHpasswd` varchar(32) default NULL,
  `slaveDatabaseFQDN` varchar(64) NOT NULL default 'chablis.dvkhosting.com',
  `slaveDatabasePort` varchar(4) NOT NULL default '3306',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`serverID`),
  KEY `catalogID` (`catalogID`),
  KEY `serverTitle` (`serverTitle`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `servers` */

insert into `servers` (`catalogID`,`serverID`,`serverTitle`,`typeServers`,`typeMonitoring`, `typeActiveServer`,`masterFQDN`,`masterASNMTAP_PATH`,`masterRSYNC_PATH`,`masterSSH_PATH`,`masterSSHlogon`,`masterSSHpasswd`,`masterDatabaseFQDN`,`masterDatabasePort`,`slaveFQDN`,`slaveASNMTAP_PATH`,`slaveRSYNC_PATH`,`slaveSSH_PATH`,`slaveSSHlogon`,`slaveSSHpasswd`,`slaveDatabaseFQDN`,`slaveDatabasePort`,`activated`) values ('CID','asnmtap01','Admin Collector [asnmtap01]',0,1,'M','asnmtap01.citap.be','/opt/asnmtap','/usr/local/bin','/usr/bin','','','','3306','','/opt/asnmtap','/usr/local/bin','/usr/bin','','','','3306',1);
insert into `servers` (`catalogID`,`serverID`,`serverTitle`,`typeServers`,`typeMonitoring`, `typeActiveServer`,`masterFQDN`,`masterASNMTAP_PATH`,`masterRSYNC_PATH`,`masterSSH_PATH`,`masterSSHlogon`,`masterSSHpasswd`,`masterDatabaseFQDN`,`masterDatabasePort`,`slaveFQDN`,`slaveASNMTAP_PATH`,`slaveRSYNC_PATH`,`slaveSSH_PATH`,`slaveSSHlogon`,`slaveSSHpasswd`,`slaveDatabaseFQDN`,`slaveDatabasePort`,`activated`) values ('CID','asnmtap02','Admin Collector [asnmtap02]',0,1,'M','asnmtap02.citap.be','/opt/asnmtap','/usr/local/bin','/usr/bin','','','','3306','','/opt/asnmtap','/usr/local/bin','/usr/bin','','','','3306',1);
insert into `servers` (`catalogID`,`serverID`,`serverTitle`,`typeServers`,`typeMonitoring`, `typeActiveServer`,`masterFQDN`,`masterASNMTAP_PATH`,`masterRSYNC_PATH`,`masterSSH_PATH`,`masterSSHlogon`,`masterSSHpasswd`,`masterDatabaseFQDN`,`masterDatabasePort`,`slaveFQDN`,`slaveASNMTAP_PATH`,`slaveRSYNC_PATH`,`slaveSSH_PATH`,`slaveSSHlogon`,`slaveSSHpasswd`,`slaveDatabaseFQDN`,`slaveDatabasePort`,`activated`) values ('CID','CTP-CENTRAL','CITAP\'s Application Monitoring Server',1,0,'M','asnmtap01.citap.be','/opt/asnmtap','/usr/local/bin','/usr/bin','','','localhost','3306','asnmtap02.citap.be','/opt/asnmtap','/usr/local/bin','/usr/bin','','','localhost','3306',1);

/*Table structure for table `timeperiods` */

DROP TABLE IF EXISTS `timeperiods`;

CREATE TABLE `timeperiods` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `timeperiodID` int(11) NOT NULL auto_increment,
  `timeperiodAlias` varchar(24) NOT NULL default '',
  `timeperiodName` varchar(64) NOT NULL default '',
  `sunday` varchar(36) default NULL,
  `monday` varchar(36) default NULL,
  `tuesday` varchar(36) default NULL,
  `wednesday` varchar(36) default NULL,
  `thursday` varchar(36) default NULL,
  `friday` varchar(36) default NULL,
  `saturday` varchar(36) default NULL,
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`timeperiodID`),
  KEY `catalogID` (`catalogID`),
  KEY `timeperiodID` (`timeperiodID`),
  KEY `timeperiodName` (`timeperiodName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `timeperiods` */

insert into `timeperiods` (`catalogID`,`timeperiodID`,`timeperiodAlias`,`timeperiodName`,`sunday`,`monday`,`tuesday`,`wednesday`,`thursday`,`friday`,`saturday`,`activated`) values ('CID',1,'24x7','24 Hours A Day, 7 Days A Week','','','','','','','',1);
insert into `timeperiods` (`catalogID`,`timeperiodID`,`timeperiodAlias`,`timeperiodName`,`sunday`,`monday`,`tuesday`,`wednesday`,`thursday`,`friday`,`saturday`,`activated`) values ('CID',2,'WorkingHours','Working Hours','','09:00-17:00','09:00-17:00','09:00-17:00','09:00-17:00','09:00-17:00','',1);
insert into `timeperiods` (`catalogID`,`timeperiodID`,`timeperiodAlias`,`timeperiodName`,`sunday`,`monday`,`tuesday`,`wednesday`,`thursday`,`friday`,`saturday`,`activated`) values ('CID',3,'Non-WorkingHours','Non-Working Hours','00:00-24:00','00:00-09:00,17:00-24:00','00:00-09:00,17:00-24:00','00:00-09:00,17:00-24:00','00:00-09:00,17:00-24:00','00:00-09:00,17:00-24:00','00:00-24:00',1);

/*Table structure for table `titles` */

DROP TABLE IF EXISTS `titles`;

CREATE TABLE `titles` (
  `cKeyTitle` varchar(7) NOT NULL default '',
  `keyTitle` varchar(4) default NULL,
  `keyLanguage` char(2) default NULL,
  `titleActive` tinyint(1) NOT NULL default '0',
  `titleName` varchar(64) default NULL,
  PRIMARY KEY (`cKeyTitle`),
  KEY `keyTitle` (`keyTitle`),
  KEY `keyLanguage` (`keyLanguage`),
  CONSTRAINT `titles_ibfk_1` FOREIGN KEY (`keyLanguage`) REFERENCES `language` (`keyLanguage`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `titles` */

/*Table structure for table `users` */

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `remoteUser` varchar(15) NOT NULL default '',
  `remoteAddr` varchar(15) NOT NULL default '',
  `remoteNetmask` char(2) NOT NULL default '',
  `givenName` varchar(50) NOT NULL default '',
  `familyName` varchar(50) NOT NULL default '',
  `email` varchar(64) NOT NULL default '',
  `downtimeScheduling` tinyint(1) NOT NULL default '1',
  `generatedReports` tinyint(1) NOT NULL default '0',
  `password` varchar(32) NOT NULL default '',
  `userType` char(1) NOT NULL default '',
  `pagedir` varchar(254) NOT NULL default '',
  `activated` tinyint(1) NOT NULL default '0',
  `keyLanguage` char(2) NOT NULL default '',
  PRIMARY KEY (`catalogID`,`remoteUser`),
  KEY `catalogID` (`catalogID`),
  KEY `keyLanguage` (`keyLanguage`),
  KEY `remoteUser` (`remoteUser`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`keyLanguage`) REFERENCES `language` (`keyLanguage`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `users` */

insert into `users` (`catalogID`,`remoteUser`,`remoteAddr`,`remoteNetmask`,`givenName`,`familyName`,`email`,`downtimeScheduling`,`generatedReports`,`password`,`userType`,`pagedir`,`activated`,`keyLanguage`) values ('CID','admin','','','admin','administrator','zxr750@citap.com',1,0,'2157d29d0465deacbe112062f5947e1c','4','/test/',1,'EN');
insert into `users` (`catalogID`,`remoteUser`,`remoteAddr`,`remoteNetmask`,`givenName`,`familyName`,`email`,`downtimeScheduling`,`generatedReports`,`password`,`userType`,`pagedir`,`activated`,`keyLanguage`) values ('CID','guest','','','test','user','info@citap.com',1,0,'2157d29d0465deacbe112062f5947e1c','0','/index/test/',1,'FR');
insert into `users` (`catalogID`,`remoteUser`,`remoteAddr`,`remoteNetmask`,`givenName`,`familyName`,`email`,`downtimeScheduling`,`generatedReports`,`password`,`userType`,`pagedir`,`activated`,`keyLanguage`) values ('CID','member','','','test','user','info@citap.com',1,0,'2157d29d0465deacbe112062f5947e1c','1','/index/test/',1,'EN');
insert into `users` (`catalogID`,`remoteUser`,`remoteAddr`,`remoteNetmask`,`givenName`,`familyName`,`email`,`downtimeScheduling`,`generatedReports`,`password`,`userType`,`pagedir`,`activated`,`keyLanguage`) values ('CID','sadmin','','','sadmin','server administrator','alex.peeters@citap.com',1,0,'2157d29d0465deacbe112062f5947e1c','8','/test/',1,'EN');

/*Table structure for table `views` */

DROP TABLE IF EXISTS `views`;

CREATE TABLE `views` (
  `catalogID` varchar(5) NOT NULL default 'CID',
  `uKey` varchar(11) NOT NULL default '',
  `displayDaemon` varchar(64) NOT NULL default '',
  `displayGroupID` int(11) NOT NULL default '1',
  `timeperiodID` INT(11) NOT NULL DEFAULT '1',
  `activated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY (`catalogID`,`uKey`,`displayDaemon`),
  KEY `displayDaemon` (`displayDaemon`),
  KEY `displayGroupID` (`displayGroupID`),
  KEY `uKey` (`uKey`),
  KEY `timeperiodID` (`timeperiodID`),
  KEY `views_ibfk_1` (`catalogID`,`displayDaemon`),
  KEY `views_ibfk_2` (`catalogID`,`displayGroupID`),
  KEY `views_ibfk_3` (`catalogID`,`uKey`),
  KEY `views_ibfk_4` (`catalogID`,`timeperiodID`),
  CONSTRAINT `views_ibfk_1` FOREIGN KEY (`catalogID`, `displayDaemon`) REFERENCES `displayDaemons` (`catalogID`, `displayDaemon`),
  CONSTRAINT `views_ibfk_2` FOREIGN KEY (`catalogID`, `displayGroupID`) REFERENCES `displayGroups` (`catalogID`, `displayGroupID`),
  CONSTRAINT `views_ibfk_3` FOREIGN KEY (`catalogID`, `uKey`) REFERENCES `plugins` (`catalogID`, `uKey`),
  CONSTRAINT `views_ibfk_4` FOREIGN KEY (`catalogID`, `timeperiodID`) REFERENCES `timeperiods` (`catalogID`, `timeperiodID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `views` */

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','DUMMY-T1','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','DUMMY-T2','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','DUMMY-T3','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','DUMMY-T4','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','DUMMY-T5','test',2,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','MYSQLS-P-01','index',3,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','MYSQLS-P-02','index',3,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','NAGIOS-P-01','index',3,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','NAGIOS-P-02','index',3,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','CLUSTER-T1','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','CLUSTER-T2','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','CLUSTER-T3','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','CLUSTER-T4','test',1,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-01','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-02','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-03','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-04','test',1,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-10','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-11','test',1,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-20','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-21','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-22','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-23','test',1,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-30','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-31','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-32','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-33','test',1,1,1);

insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-40','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-41','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-42','test',1,1,1);
insert into `views` (`catalogID`,`uKey`,`displayDaemon`,`displayGroupID`,`timeperiodID`,`activated`) values ('CID','zCLUSTER-43','test',1,1,1);


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
