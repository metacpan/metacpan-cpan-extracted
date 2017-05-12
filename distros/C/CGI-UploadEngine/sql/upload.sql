DROP TABLE IF EXISTS `upload_files`;
CREATE TABLE `upload_files` (
  `upload_file_id`     int(8) NOT NULL auto_increment,
  `file_path`          varchar(255) NOT NULL default '',
  `file_name`          varchar(255) NOT NULL default '',
  `attempt_token`      varchar(60) NOT NULL default '',
  `success_token`      varchar(60) NOT NULL default '',
  `created`            date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`upload_file_id`)
);

