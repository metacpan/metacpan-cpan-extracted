CREATE TABLE `User` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric user identifier.',
  `name` varchar(64) NOT NULL DEFAULT 'bob''b' COMMENT 'Unique login name for user.',
  `email` varchar(64) NOT NULL COMMENT 'User email address.',
  `admin` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Boolean indicating user is an administrator.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for User.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of User last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of User creation.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='Application User.';

CREATE TABLE `Service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric service identifier.',
  `name` varchar(64) NOT NULL COMMENT 'Unique text service identifier.',
  `description` text NOT NULL COMMENT 'Service description.',
  `owner_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to user that owns service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `Service_owner` (`owner_id`),
  CONSTRAINT `Service_owner` FOREIGN KEY (`owner_id`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A User''s Service';

CREATE VIEW `ServiceWithOwner` AS
SELECT s.name service_name, s.description service_description, o.name owner_name, o.email owner_email
FROM Service s JOIN User o ON s.owner_id=o.id;

delimiter //
CREATE PROCEDURE user_count (OUT number INT)
BEGIN
    SELECT COUNT(*) FROM User;
END //
delimiter ;

