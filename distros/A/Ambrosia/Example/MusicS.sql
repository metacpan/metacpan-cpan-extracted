DROP SCHEMA IF EXISTS `MusicDB` ;
CREATE SCHEMA IF NOT EXISTS `MusicDB` DEFAULT CHARACTER SET utf8;
USE `MusicDB` ;

DROP TABLE IF EXISTS `tblArtist`;
CREATE TABLE `tblArtist` (
  `ArtistId` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) NOT NULL,
  PRIMARY KEY (`ArtistId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `tblAlbum`;
CREATE TABLE `tblAlbum` (
  `AlbumId` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) NOT NULL,
  `Releas` date NOT NULL,
  `RefArtistId` int(11) NOT NULL,
  PRIMARY KEY (`AlbumId`),
  KEY `fk_idx_Album_Artist` (`RefArtistId`),
  CONSTRAINT `fk_idx_Album_Artist` FOREIGN KEY (`RefArtistId`) REFERENCES `tblArtist` (`ArtistId`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


