# MySQL dump 5.10
#
# Host: localhost    Database: catalog_example
#--------------------------------------------------------
# Server version	3.22.14b-gamma

#
# Table structure for table 'catalog'
#
CREATE TABLE catalog (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  name varchar(32) DEFAULT '' NOT NULL,
  tablename varchar(60) DEFAULT '' NOT NULL,
  navigation enum('alpha','theme','date') DEFAULT 'theme',
  info set('hideempty'),
  updated datetime,
  corder varchar(128),
  cwhere varchar(128),
  fieldname varchar(60),
  root int(11) DEFAULT '0' NOT NULL,
  dump varchar(255),
  dumplocation varchar(255),
  UNIQUE catalog1 (rowid),
  UNIQUE catalog2 (name)
);

#
# Dumping data for table 'catalog'
#

INSERT INTO catalog VALUES (3,'1999-03-10 12:01:56',19990312083747,'urlcatalog','urldemo','theme',NULL,'0000-00-00 00:00:00','comment',NULL,NULL,1,NULL,NULL);
INSERT INTO catalog VALUES (5,'1999-03-10 20:04:44',19990312085007,'urlalpha','urldemo','alpha',NULL,'1999-03-12 08:47:17','comment',NULL,'comment',0,NULL,NULL);
INSERT INTO catalog VALUES (4,'1999-03-10 19:55:27',19990312112409,'urldate','urldemo','date',NULL,'1999-03-12 08:38:41','comment',NULL,'created',0,NULL,NULL);

#
# Table structure for table 'catalog_category2category_urlcatalog'
#
CREATE TABLE catalog_category2category_urlcatalog (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  info set('hidden','symlink'),
  up int(11) DEFAULT '0' NOT NULL,
  down int(11) DEFAULT '0' NOT NULL,
  externalid varchar(32) DEFAULT '' NOT NULL,
  UNIQUE catalog_category2category_urlcatalog1 (rowid),
  KEY catalog_category2category_urlcatalog2 (created),
  KEY catalog_category2category_urlcatalog3 (modified),
  UNIQUE catalog_category2category_urlcatalog4 (up,down),
  KEY catalog_category2category_urlcatalog5 (down),
  KEY catalog_category2category_urlcatalog6 (externalid)
);

#
# Dumping data for table 'catalog_category2category_urlcatalog'
#

INSERT INTO catalog_category2category_urlcatalog VALUES (1,'1999-03-10 12:05:05',19990310120505,'hidden',1,2,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (2,'1999-03-10 12:05:28',19990310120528,'hidden',1,3,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (3,'1999-03-10 12:06:07',19990310120607,'hidden',1,4,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (4,'1999-03-10 12:06:23',19990310120623,'hidden',1,5,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (5,'1999-03-10 13:09:40',19990310130940,'hidden',4,6,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (6,'1999-03-10 13:09:47',19990310130947,'hidden',4,7,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (7,'1999-03-10 13:09:53',19990310130953,'hidden',4,8,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (8,'1999-03-10 13:10:01',19990310131001,'hidden',4,9,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (9,'1999-03-10 13:10:47',19990310131047,'hidden',4,10,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (10,'1999-03-10 13:10:58',19990310131058,'hidden',4,11,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (11,'1999-03-10 13:11:14',19990310131114,'hidden',4,12,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (12,'1999-03-10 13:19:19',19990310131919,'hidden',11,13,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (13,'1999-03-10 13:21:11',19990310132111,'hidden',11,14,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (14,'1999-03-10 13:21:35',19990310132135,'hidden',11,15,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (15,'1999-03-10 13:22:29',19990310132229,'hidden',11,16,'');
INSERT INTO catalog_category2category_urlcatalog VALUES (16,'1999-03-10 13:23:19',19990310132319,'hidden',11,17,'');

#
# Table structure for table 'catalog_category_urlcatalog'
#
CREATE TABLE catalog_category_urlcatalog (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  info set('root'),
  name varchar(255) DEFAULT '' NOT NULL,
  count int(11) DEFAULT '0',
  externalid varchar(32) DEFAULT '' NOT NULL,
  UNIQUE catalog_category_urlcatalog1 (rowid),
  KEY catalog_category_urlcatalog2 (created),
  KEY catalog_category_urlcatalog3 (modified),
  KEY catalog_category_urlcatalog4 (name(122)),
  KEY catalog_category_urlcatalog5 (externalid)
);

#
# Dumping data for table 'catalog_category_urlcatalog'
#

INSERT INTO catalog_category_urlcatalog VALUES (1,'1999-03-10 12:01:56',19990310132632,'root','',54,'');
INSERT INTO catalog_category_urlcatalog VALUES (2,'1999-03-10 12:05:05',19990310130855,NULL,'Search',11,'');
INSERT INTO catalog_category_urlcatalog VALUES (3,'1999-03-10 12:05:28',19990310120824,NULL,'Directory',3,'');
INSERT INTO catalog_category_urlcatalog VALUES (4,'1999-03-10 12:06:07',19990310132415,NULL,'Full text',34,'');
INSERT INTO catalog_category_urlcatalog VALUES (5,'1999-03-10 12:06:23',19990310132632,NULL,'Software',6,'');
INSERT INTO catalog_category_urlcatalog VALUES (6,'1999-03-10 13:09:40',19990310130940,NULL,'Technical Reports',0,'');
INSERT INTO catalog_category_urlcatalog VALUES (7,'1999-03-10 13:09:47',19990310131558,NULL,'Conferences',3,'');
INSERT INTO catalog_category_urlcatalog VALUES (8,'1999-03-10 13:09:53',19990310131649,NULL,'People',4,'');
INSERT INTO catalog_category_urlcatalog VALUES (9,'1999-03-10 13:10:01',19990310131900,NULL,'Research Groups',2,'');
INSERT INTO catalog_category_urlcatalog VALUES (10,'1999-03-10 13:10:47',19990310131823,NULL,'References',6,'');
INSERT INTO catalog_category_urlcatalog VALUES (11,'1999-03-10 13:10:58',19990310132341,NULL,'Software',18,'');
INSERT INTO catalog_category_urlcatalog VALUES (12,'1999-03-10 13:11:14',19990310132415,NULL,'Standards',1,'');
INSERT INTO catalog_category_urlcatalog VALUES (13,'1999-03-10 13:19:19',19990310132054,NULL,'Free Software',9,'');
INSERT INTO catalog_category_urlcatalog VALUES (14,'1999-03-10 13:21:11',19990310132122,NULL,'Source not free',1,'');
INSERT INTO catalog_category_urlcatalog VALUES (15,'1999-03-10 13:21:35',19990310132212,NULL,'Maybe Free',3,'');
INSERT INTO catalog_category_urlcatalog VALUES (16,'1999-03-10 13:22:29',19990310132306,NULL,'Algorithm Implementation',3,'');
INSERT INTO catalog_category_urlcatalog VALUES (17,'1999-03-10 13:23:19',19990310132340,NULL,'Lossless compression',2,'');

#
# Table structure for table 'catalog_entry2category_urlcatalog'
#
CREATE TABLE catalog_entry2category_urlcatalog (
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  info set('hidden'),
  row int(11) DEFAULT '0' NOT NULL,
  category int(11) DEFAULT '0' NOT NULL,
  externalid varchar(32) DEFAULT '' NOT NULL,
  KEY catalog_entry2category_urlcatalog2 (created),
  KEY catalog_entry2category_urlcatalog3 (modified),
  UNIQUE catalog_entry2category_urlcatalog4 (row,category),
  KEY catalog_entry2category_urlcatalog5 (category),
  KEY catalog_entry2category_urlcatalog6 (externalid)
);

#
# Dumping data for table 'catalog_entry2category_urlcatalog'
#

INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:07:14',19990310120714,'hidden',1,3,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:08:07',19990310120807,'hidden',2,3,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:08:24',19990310120824,'hidden',3,3,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:09:02',19990310120902,'hidden',4,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:09:22',19990310120922,'hidden',5,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:09:53',19990310120953,'hidden',6,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:10:10',19990310121010,'hidden',7,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:10:34',19990310121034,'hidden',8,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:10:47',19990310121047,'hidden',9,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:10:57',19990310121057,'hidden',10,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:11:13',19990310121113,'hidden',11,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 12:11:29',19990310121129,'hidden',12,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:08:20',19990310130820,'hidden',13,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:08:55',19990310130855,'hidden',14,2,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:14:40',19990310131440,'hidden',15,7,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:15:47',19990310131547,'hidden',16,7,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:15:58',19990310131558,'hidden',17,7,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:16:18',19990310131618,'hidden',18,8,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:16:30',19990310131630,'hidden',19,8,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:16:40',19990310131640,'hidden',20,8,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:16:49',19990310131649,'hidden',21,8,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:17:16',19990310131716,'hidden',22,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:17:34',19990310131734,'hidden',23,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:17:45',19990310131745,'hidden',24,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:17:57',19990310131757,'hidden',25,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:18:05',19990310131805,'hidden',26,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:18:23',19990310131823,'hidden',27,10,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:18:52',19990310131852,'hidden',28,9,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:19:00',19990310131900,'hidden',29,9,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:19:32',19990310131932,'hidden',30,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:19:41',19990310131941,'hidden',31,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:19:51',19990310131951,'hidden',32,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:04',19990310132004,'hidden',33,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:15',19990310132015,'hidden',34,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:24',19990310132024,'hidden',35,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:33',19990310132033,'hidden',36,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:46',19990310132046,'hidden',37,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:20:54',19990310132054,'hidden',38,13,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:21:22',19990310132122,'hidden',39,14,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:21:52',19990310132152,'hidden',40,15,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:22:03',19990310132203,'hidden',41,15,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:22:12',19990310132212,'hidden',42,15,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:22:41',19990310132241,'hidden',43,16,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:22:49',19990310132249,'hidden',44,16,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:23:06',19990310132306,'hidden',45,16,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:23:30',19990310132330,'hidden',46,17,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:23:40',19990310132340,'hidden',47,17,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:24:15',19990310132415,'hidden',48,12,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:24:54',19990310132454,'hidden',49,5,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:25:14',19990310132514,'hidden',50,5,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:25:41',19990310132541,'hidden',51,5,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:25:53',19990310132553,'hidden',52,5,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:26:06',19990310132606,'hidden',53,5,'');
INSERT INTO catalog_entry2category_urlcatalog VALUES ('1999-03-10 13:26:32',19990310132632,'hidden',54,5,'');

#
# Table structure for table 'catalog_path_urlcatalog'
#
CREATE TABLE catalog_path_urlcatalog (
  pathname text NOT NULL,
  md5 varchar(32) DEFAULT '' NOT NULL,
  path varchar(128) DEFAULT '' NOT NULL,
  id int(11) DEFAULT '0' NOT NULL,
  UNIQUE catalog_path_urlcatalog1 (md5),
  UNIQUE catalog_path_urlcatalog2 (path),
  UNIQUE catalog_path_urlcatalog3 (id)
);

#
# Dumping data for table 'catalog_path_urlcatalog'
#

INSERT INTO catalog_path_urlcatalog VALUES ('/','6666cd76f96956469e7be39d750cc7d9','',1);
INSERT INTO catalog_path_urlcatalog VALUES ('/Search/','84b219a9d636fd0e5105c17f8a8f869a',',2,',2);
INSERT INTO catalog_path_urlcatalog VALUES ('/Directory/','1d9363333301035adb917d989858f235',',3,',3);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/','2d88b6e54067d2080ead29197737ec0d',',4,',4);
INSERT INTO catalog_path_urlcatalog VALUES ('/Software/','1ba25e4803d97ad7889ea08e1b00ff50',',5,',5);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Technical_Reports/','3bbad17345b2092fc7a48e2b2c099dff',',4,6,',6);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Conferences/','2ebba41387095f8924bbd9a56a85e932',',4,7,',7);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/People/','98374deb3200ca6e3bf97058a2cc82da',',4,8,',8);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Research_Groups/','8aa6060a2ff07aa078aabfa8ce0cd69c',',4,9,',9);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/References/','a34a5e8df758685f15dcce25cc373cd5',',4,10,',10);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/','df8b52aecf78b3395f1efdd9c810121a',',4,11,',11);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Standards/','9cd97597b6d0a3fe7a036799ce898568',',4,12,',12);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/Free_Software/','abc0162815bfdcb541942fea2987758c',',4,11,13,',13);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/Source_not_free/','517041919399524263ee79cc82097e64',',4,11,14,',14);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/Maybe_Free/','088cf5d6765f1a4c782f66426eed2756',',4,11,15,',15);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/Algorithm_Implementation/','efa332e969dcff597408a6057390278d',',4,11,16,',16);
INSERT INTO catalog_path_urlcatalog VALUES ('/Full_text/Software/Lossless_compression/','c362bd869cff084dc52b40867ca489a9',',4,11,17,',17);

#
# Table structure for table 'catalog_alpha_urlalpha'
#
CREATE TABLE catalog_alpha_urlalpha (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  letter char(1) DEFAULT '' NOT NULL,
  count int(11) DEFAULT '0',
  UNIQUE catalog_alpha_urlalpha1 (rowid)
);

#
# Dumping data for table 'catalog_alpha_urlalpha'
#

INSERT INTO catalog_alpha_urlalpha VALUES (1,'1999-03-10 20:04:44',19990310200444,'0',0);
INSERT INTO catalog_alpha_urlalpha VALUES (2,'1999-03-10 20:04:44',19990310200444,'1',0);
INSERT INTO catalog_alpha_urlalpha VALUES (3,'1999-03-10 20:04:44',19990310200444,'2',0);
INSERT INTO catalog_alpha_urlalpha VALUES (4,'1999-03-10 20:04:44',19990310200444,'3',0);
INSERT INTO catalog_alpha_urlalpha VALUES (5,'1999-03-10 20:04:44',19990310200444,'4',0);
INSERT INTO catalog_alpha_urlalpha VALUES (6,'1999-03-10 20:04:44',19990310200444,'5',0);
INSERT INTO catalog_alpha_urlalpha VALUES (7,'1999-03-10 20:04:44',19990310200444,'6',0);
INSERT INTO catalog_alpha_urlalpha VALUES (8,'1999-03-10 20:04:44',19990310200444,'7',0);
INSERT INTO catalog_alpha_urlalpha VALUES (9,'1999-03-10 20:04:44',19990310200444,'8',0);
INSERT INTO catalog_alpha_urlalpha VALUES (10,'1999-03-10 20:04:44',19990310200444,'9',0);
INSERT INTO catalog_alpha_urlalpha VALUES (11,'1999-03-10 20:04:44',19990310200448,'a',7);
INSERT INTO catalog_alpha_urlalpha VALUES (12,'1999-03-10 20:04:44',19990310200448,'b',1);
INSERT INTO catalog_alpha_urlalpha VALUES (13,'1999-03-10 20:04:44',19990310200448,'c',6);
INSERT INTO catalog_alpha_urlalpha VALUES (14,'1999-03-10 20:04:44',19990310200448,'d',3);
INSERT INTO catalog_alpha_urlalpha VALUES (15,'1999-03-10 20:04:44',19990310200444,'e',0);
INSERT INTO catalog_alpha_urlalpha VALUES (16,'1999-03-10 20:04:44',19990310200448,'f',2);
INSERT INTO catalog_alpha_urlalpha VALUES (17,'1999-03-10 20:04:44',19990310200448,'g',3);
INSERT INTO catalog_alpha_urlalpha VALUES (18,'1999-03-10 20:04:44',19990310200448,'h',2);
INSERT INTO catalog_alpha_urlalpha VALUES (19,'1999-03-10 20:04:44',19990310200448,'i',2);
INSERT INTO catalog_alpha_urlalpha VALUES (20,'1999-03-10 20:04:44',19990310200448,'j',1);
INSERT INTO catalog_alpha_urlalpha VALUES (21,'1999-03-10 20:04:44',19990310200444,'k',0);
INSERT INTO catalog_alpha_urlalpha VALUES (22,'1999-03-10 20:04:44',19990310200448,'l',4);
INSERT INTO catalog_alpha_urlalpha VALUES (23,'1999-03-10 20:04:44',19990310200448,'m',4);
INSERT INTO catalog_alpha_urlalpha VALUES (24,'1999-03-10 20:04:44',19990310200444,'n',0);
INSERT INTO catalog_alpha_urlalpha VALUES (25,'1999-03-10 20:04:44',19990310200448,'o',1);
INSERT INTO catalog_alpha_urlalpha VALUES (26,'1999-03-10 20:04:44',19990310200448,'p',1);
INSERT INTO catalog_alpha_urlalpha VALUES (27,'1999-03-10 20:04:44',19990310200444,'q',0);
INSERT INTO catalog_alpha_urlalpha VALUES (28,'1999-03-10 20:04:44',19990310200444,'r',0);
INSERT INTO catalog_alpha_urlalpha VALUES (29,'1999-03-10 20:04:44',19990310200448,'s',6);
INSERT INTO catalog_alpha_urlalpha VALUES (30,'1999-03-10 20:04:44',19990310200448,'t',7);
INSERT INTO catalog_alpha_urlalpha VALUES (31,'1999-03-10 20:04:44',19990310200448,'u',1);
INSERT INTO catalog_alpha_urlalpha VALUES (32,'1999-03-10 20:04:44',19990310200444,'v',0);
INSERT INTO catalog_alpha_urlalpha VALUES (33,'1999-03-10 20:04:44',19990310200444,'w',0);
INSERT INTO catalog_alpha_urlalpha VALUES (34,'1999-03-10 20:04:44',19990310200444,'x',0);
INSERT INTO catalog_alpha_urlalpha VALUES (35,'1999-03-10 20:04:44',19990310200448,'y',1);
INSERT INTO catalog_alpha_urlalpha VALUES (36,'1999-03-10 20:04:44',19990310200448,'z',2);

#
# Table structure for table 'urldemo'
#
CREATE TABLE urldemo (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  created datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  modified timestamp(14),
  info enum('active','inactive') DEFAULT 'active',
  url char(128),
  comment char(255),
  UNIQUE cdemo1 (rowid)
);

#
# Dumping data for table 'urldemo'
#

INSERT INTO urldemo VALUES (1,'1999-03-10 12:07:14',19990310120714,'active','http://www.mmedia.is/free-directory/','The free internet directory project');
INSERT INTO urldemo VALUES (2,'1999-03-10 12:08:07',19990310120807,'active','http://dmoz.org/','Open Directory Project');
INSERT INTO urldemo VALUES (3,'1999-03-10 12:08:24',19990310120824,'active','http://multiagent.com/bk2site.htm','bk2site');
INSERT INTO urldemo VALUES (4,'1999-03-10 12:09:02',19990310120902,'active','http://www.yahoo.com/','Yahoo!');
INSERT INTO urldemo VALUES (5,'1999-03-10 12:09:22',19990310120922,'active','http://www.altavista.digital.com/cgi-bin/query?pg=aq','AltaVista Search: Advanced Query');
INSERT INTO urldemo VALUES (6,'1999-03-10 12:09:53',19990310120953,'active','http://www.dejanews.com/','DejaNews newsgroups search');
INSERT INTO urldemo VALUES (7,'1999-03-10 12:10:10',19990310121010,'active','http://www.cis.ohio-state.edu/hypertext/faq/usenet/top.html','USENET FAQs');
INSERT INTO urldemo VALUES (8,'1999-03-10 12:10:34',19990310121034,'active','http://ftpsearch.ntnu.no/','Search FTP archive sites');
INSERT INTO urldemo VALUES (9,'1999-03-10 12:10:47',19990310121047,'active','http://www.lycos.com/','Lycos');
INSERT INTO urldemo VALUES (10,'1999-03-10 12:10:57',19990310121057,'active','http://google.stanford.edu/','Google! Search Engine');
INSERT INTO urldemo VALUES (11,'1999-03-10 12:11:13',19990310121113,'active','http://www.mail-archive.com/','The Mail Archive');
INSERT INTO urldemo VALUES (12,'1999-03-10 12:11:29',19990310121129,'active','http://las.ml.org/','Linux Archive Search: Welcome');
INSERT INTO urldemo VALUES (13,'1999-03-10 13:08:20',19990310130820,'active','http://www.faq.org/','FAQ.org');
INSERT INTO urldemo VALUES (14,'1999-03-10 13:08:55',19990310130855,'active','http://www.shareware.com/','SHAREWARE.COM -- the way to find shareware on the Internet');
INSERT INTO urldemo VALUES (15,'1999-03-10 13:14:40',19990310131440,'active','http://www.cs.brandeis.edu/~dcc/','Data Compression');
INSERT INTO urldemo VALUES (16,'1999-03-10 13:15:47',19990310131547,'active','http://www.cs.mu.oz.au/sigir98/','SIGIR\'98 Home Page');
INSERT INTO urldemo VALUES (17,'1999-03-10 13:15:58',19990310131558,'active','http://trec.nist.gov/','TREC');
INSERT INTO urldemo VALUES (18,'1999-03-10 13:16:18',19990310131618,'active','http://munkora.cs.mu.oz.au/~alistair/','Alistair Moffat');
INSERT INTO urldemo VALUES (19,'1999-03-10 13:16:30',19990310131630,'active','http://sequence.rutgers.edu/~nevill/','Craig Nevill-Manning');
INSERT INTO urldemo VALUES (20,'1999-03-10 13:16:40',19990310131640,'active','http://www.cs.waikato.ac.nz/~ihw/','Ian H. Witten');
INSERT INTO urldemo VALUES (21,'1999-03-10 13:16:49',19990310131649,'active','http://goanna.cs.rmit.edu.au/~jz/','Justin Zobel');
INSERT INTO urldemo VALUES (22,'1999-03-10 13:17:16',19990310131716,'active','http://www.amazon.com/exec/obidos/query/subject%20word%20is%20data%20and%20compression/002-0383475-3014066','Amazon.com - Query Results');
INSERT INTO urldemo VALUES (23,'1999-03-10 13:17:34',19990310131734,'active','http://www.cs.mu.oz.au/~alistair/dccrefs.bib','Moffat\'s bibliography');
INSERT INTO urldemo VALUES (24,'1999-03-10 13:17:45',19990310131745,'active','http://www.cis.ohio-state.edu/hypertext/faq/usenet/compression-faq/top.html','Compression FAQ');
INSERT INTO urldemo VALUES (25,'1999-03-10 13:17:56',19990310131756,'active','http://www.internz.com/compression-pointers.html','Compression Pointers');
INSERT INTO urldemo VALUES (26,'1999-03-10 13:18:05',19990310131805,'active','http://altavista.looksmart.com/eus1/eus53832/eus155852/eus64723/eus64734/r?l&izf&','LookSmart - exploring World - Computers & Internet - Computer Science - Compression - Data Compression');
INSERT INTO urldemo VALUES (27,'1999-03-10 13:18:23',19990310131823,'active','http://www.ifla.org/VII/s21/p1996/fulltext.htm','Inventory of Full-Text Information Retrieval Software');
INSERT INTO urldemo VALUES (28,'1999-03-10 13:18:52',19990310131852,'active','http://acsys.anu.edu.au/research/frameset_research.htm','ACSys Research');
INSERT INTO urldemo VALUES (29,'1999-03-10 13:19:00',19990310131900,'active','http://pastime.anu.edu.au/TAR/','TAR PROJECT');
INSERT INTO urldemo VALUES (30,'1999-03-10 13:19:32',19990310131932,'active','http://www.cnidr.org/ir/isearch.html','CNIDR Isearch');
INSERT INTO urldemo VALUES (31,'1999-03-10 13:19:41',19990310131941,'active','http://pi0959.kub.nl/Paai/GIRE/','GIRE');
INSERT INTO urldemo VALUES (32,'1999-03-10 13:19:51',19990310131951,'active','http://x10.dejanews.com/[ST_rn=ps]/getdoc.xp?AN=400720186&CONTEXT=920324880.9109690&hitnum=0','GIRE announce');
INSERT INTO urldemo VALUES (33,'1999-03-10 13:20:04',19990310132004,'active','http://htdig.sdsu.edu/','ht://Dig -- Internet search engine software');
INSERT INTO urldemo VALUES (34,'1999-03-10 13:20:15',19990310132015,'active','http://www.locus.cz/locus/','locus fulltext database');
INSERT INTO urldemo VALUES (35,'1999-03-10 13:20:24',19990310132024,'active','http://www.mds.rmit.edu.au/mg/','MG Pages');
INSERT INTO urldemo VALUES (36,'1999-03-10 13:20:33',19990310132033,'active','http://sunsite.berkeley.edu/SWISH-E/','SWISH-Enhanced - Digital Library SunSITE');
INSERT INTO urldemo VALUES (37,'1998-12-10 13:20:46',19990310132046,'active','http://www.best.com/~pjl/software/swish/','SWISH++');
INSERT INTO urldemo VALUES (38,'1999-03-10 13:20:54',19990310132054,'active','http://www.indexdata.dk/zebra/','The Zebra Server');
INSERT INTO urldemo VALUES (39,'1998-12-10 13:21:21',19990310132121,'active','ftp://ftp.cs.cornell.edu/pub/smart/','SMART');
INSERT INTO urldemo VALUES (40,'1999-03-09 13:21:52',19990310132152,'active','http://www.1source.com/~pollarda/findex/#support','Findex Full Text Indexing and Retrieval (Search) Engine Toolkit');
INSERT INTO urldemo VALUES (41,'1998-12-09 13:22:03',19990310132203,'active','http://www.lucene.com/','The Lucene Search Engine');
INSERT INTO urldemo VALUES (42,'1999-02-15 13:22:12',19990310132212,'active','http://www.nist.gov/itl/div894/894.02/works/papers/zp2/zp2.html','Z39.50/PRISE 2.0');
INSERT INTO urldemo VALUES (43,'1999-02-16 13:22:41',19990310132241,'active','ftp://ftp.media.mit.edu/pub/k-arith-code/','Arithmetic coding');
INSERT INTO urldemo VALUES (44,'1999-02-17 13:22:49',19990310132249,'active','ftp://ftp.cl.cam.ac.uk/users/djw3/','Huffman, Block and more');
INSERT INTO urldemo VALUES (45,'1999-02-18 13:23:06',19990310132306,'active','http://www.cs.uiowa.edu/~jones/compress/index.html','Doug Jones\'s compression and encryption algorithms');
INSERT INTO urldemo VALUES (46,'1999-02-19 13:23:30',19990310132330,'active','http://www.gzip.org/','The gzip home page');
INSERT INTO urldemo VALUES (47,'1999-02-20 13:23:40',19990310132340,'active','http://wildsau.idv.uni-linz.ac.at/mfx/lzo.html','Markus F.X.J. Oberhumer: LZO real-time data compression library');
INSERT INTO urldemo VALUES (48,'1999-02-21 13:24:15',19990310132415,'active','http://lcweb.loc.gov/z3950/agency/','Z39.50 maintenance agency home page');
INSERT INTO urldemo VALUES (49,'1999-02-22 13:24:54',19990310132454,'active','http://www.apache.org/','Apache');
INSERT INTO urldemo VALUES (50,'1999-02-23 13:25:14',19990310132514,'active','http://www.tcx.se/','MySQL');
INSERT INTO urldemo VALUES (51,'1999-02-24 13:25:41',19990310132541,'active','http://www.perl.org/','Perl');
INSERT INTO urldemo VALUES (52,'1999-02-25 13:25:53',19990310132553,'active','http://www.senga.org/','Catalog');
INSERT INTO urldemo VALUES (53,'1999-02-26 13:26:06',19990310132606,'active','http://perl.apache.org/','Apache/Perl Integration Project');
INSERT INTO urldemo VALUES (54,'1999-02-27 13:26:32',19990310132632,'active','http://stein.cshl.org/WWW/software/CGI/cgi_docs.html','CGI.pm - a Perl5 CGI Library');

# MySQL dump 5.10
#
# Host: localhost    Database: catalog_example
#--------------------------------------------------------
# Server version	3.22.14b-gamma

#
# Table structure for table 'catalog_date_urldate'
#
CREATE TABLE catalog_date_urldate (
  rowid int(11) DEFAULT '0' NOT NULL auto_increment,
  tag char(8) DEFAULT '' NOT NULL,
  count int(11) DEFAULT '0',
  UNIQUE catalog_date_urldate1 (rowid),
  UNIQUE catalog_date_urldate2 (tag)
);

