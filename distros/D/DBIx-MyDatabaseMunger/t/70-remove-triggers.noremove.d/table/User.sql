CREATE TABLE `User` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric user identifier.',
  `name` varchar(64) NOT NULL DEFAULT 'bob''b' COMMENT 'Unique login name for user.',
  `email` varchar(64) NOT NULL COMMENT 'User email address.',
  `admin` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Boolean indicating user is an administrator.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for User.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of User last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of User creation.',
  UNIQUE KEY `name` (`name`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Application User.'
