CREATE TABLE `Service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric service identifier.',
  `name` varchar(64) NOT NULL COMMENT 'Unique text service identifier.',
  `owner_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to user that owns service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  KEY `Service_owner` (`owner_id`),
  UNIQUE KEY `name` (`name`),
  CONSTRAINT `Service_owner` FOREIGN KEY (`owner_id`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A User''s Service'
