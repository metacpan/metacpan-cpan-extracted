DROP TABLE IF EXISTS `hits`;
CREATE TABLE `hits` (
  `hit_id`         int(8) NOT NULL auto_increment,
  `query_id`       varchar(16) NOT NULL,
  `query_start`    int(16) NOT NULL,
  `query_end`      int(16) NOT NULL,
  `query_string`   blob NOT NULL,
  `subject_id`     varchar(16) NOT NULL,
  `subject_start`  int(16) NOT NULL,
  `subject_end`    int(16) NOT NULL,
  `subject_string` blob NOT NULL,
  `expect`         dec(16,15) NOT NULL default '0.0',
  PRIMARY KEY  (`hit_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

insert into hits ( query_id, query_start, query_end, query_string, subject_id, subject_start, subject_end, subject_string ) values ( 'AA123456', 20, 40, 'ACTGACTGACTGACTGACTG', 'AB123456', 40, 60, 'ACTGACTGACTGACTGACTG'), ( 'AA123456', 20, 40, 'ACTGACTGACTGACTGACTG', 'AC123456', 60, 80, 'ACTGACTGACTGACTGACTG'), ( 'AB123456', 40, 60, 'ACTGACTGACTGACTGACTG', 'AA123456', 20, 40, 'ACTGACTGACTGACTGACTG'), ( 'AB123456', 40, 60, 'ACTGACTGACTGACTGACTG', 'AC123456', 60, 80, 'ACTGACTGACTGACTGACTG'), ( 'AC123456', 60, 80, 'ACTGACTGACTGACTGACTG', 'AA123456', 20, 40, 'ACTGACTGACTGACTGACTG'), ( 'AC123456', 60, 80, 'ACTGACTGACTGACTGACTG', 'AB123456', 40, 60, 'ACTGACTGACTGACTGACTG');

