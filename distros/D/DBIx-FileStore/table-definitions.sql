CREATE TABLE IF NOT EXISTS `files` (
  `c_len` int(10) unsigned,
  `b_num` mediumint(8) unsigned,
  `lasttime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `name` varchar(85),
  `b_md5` char(22),
  `c_md5` char(22),
  UNIQUE KEY `name` (`name`),
  KEY `b_num` (`b_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AVG_ROW_LENGTH=109;
 
 
CREATE TABLE IF NOT EXISTS `fileblocks` (
  `name` varchar(85),
  `block` blob,
  `lasttime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


