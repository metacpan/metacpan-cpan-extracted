CREATE TABLE `ServiceArchive` (
  `id` int(10) unsigned NOT NULL COMMENT 'Numeric service identifier.',
  `name` varchar(64) COMMENT 'Unique text service identifier.',
  `description` text COMMENT 'Service description.',
  `owner_id` int(10) unsigned COMMENT 'Foreign key to user that owns service.',
  `user_management` enum('single','multi','none') COMMENT 'User management style for this service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  `action` enum('insert','update','delete') NOT NULL COMMENT 'SQL action.',
  `updid` varchar(256) NOT NULL COMMENT 'Application user that made this change.',
  `dbuser` varchar(256) NOT NULL COMMENT 'Database user & host that made this change.',
  `stmt` longtext NOT NULL COMMENT 'SQL Statement that initiated this change.',
  KEY `Service_owner` (`owner_id`),
  KEY `name` (`name`),
  PRIMARY KEY (`id`,`revision`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Service archive.'
