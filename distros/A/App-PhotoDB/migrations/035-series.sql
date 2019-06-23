CREATE TABLE `SERIES` (
  `series_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this series',
  `name` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of this collection, e.g. Canon FD SLRs',
  PRIMARY KEY (`series_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to list all series of cameras and lenses';

CREATE TABLE `SERIES_MEMBER` (
  `series_member_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique ID of this series membership',
  `series_id` int(11) DEFAULT NULL COMMENT 'ID of the series to which this camera model or lens model belongs',
  `cameramodel_id` int(11) DEFAULT NULL COMMENT 'ID of the camera model',
  `lensmodel_id` int(11) DEFAULT NULL COMMENT 'ID of the lens model',
  PRIMARY KEY (`series_member_id`),
  KEY `fk_SERIES_MEMBER_1_idx` (`series_id`),
  KEY `fk_SERIES_MEMBER_2_idx` (`cameramodel_id`),
  KEY `fk_SERIES_MEMBER_3_idx` (`lensmodel_id`),
  CONSTRAINT `fk_SERIES_MEMBER_1` FOREIGN KEY (`series_id`) REFERENCES `SERIES` (`series_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_SERIES_MEMBER_2` FOREIGN KEY (`cameramodel_id`) REFERENCES `CAMERAMODEL` (`cameramodel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_SERIES_MEMBER_3` FOREIGN KEY (`lensmodel_id`) REFERENCES `LENSMODEL` (`lensmodel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table to record which cameras and lenses belong to which series';
