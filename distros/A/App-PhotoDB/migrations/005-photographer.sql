UPDATE `NEGATIVE` join `FILM` on `NEGATIVE`.`film_id`=`FILM`.`film_id`
SET `NEGATIVE`.`photographer_id` = `FILM`.`photographer_id`
WHERE `NEGATIVE`.`photographer_id` is null and `FILM`.`photographer_id` is not null;

CREATE
     OR REPLACE ALGORITHM = UNDEFINED
    SQL SECURITY DEFINER
VIEW `exifdata` AS
    SELECT
        `f`.`film_id` AS `film_id`,
        `n`.`negative_id` AS `negative_id`,
        `PRINT`.`print_id` AS `print_id`,
        `cm`.`manufacturer` AS `Make`,
        CONCAT(`cm`.`manufacturer`, ' ', `c`.`model`) AS `Model`,
        `p`.`name` AS `Author`,
        `lm`.`manufacturer` AS `LensMake`,
        CONCAT(`lm`.`manufacturer`, ' ', `l`.`model`) AS `LensModel`,
        CONCAT(`lm`.`manufacturer`, ' ', `l`.`model`) AS `Lens`,
        `l`.`serial` AS `LensSerialNumber`,
        `c`.`serial` AS `SerialNumber`,
        CONCAT(`f`.`directory`, '/', `s`.`filename`) AS `path`,
        `l`.`max_aperture` AS `MaxApertureValue`,
        `f`.`directory` AS `directory`,
        `s`.`filename` AS `filename`,
        `n`.`shutter_speed` AS `ExposureTime`,
        `n`.`aperture` AS `FNumber`,
        `n`.`aperture` AS `ApertureValue`,
        IF((`l`.`min_focal_length` = `l`.`max_focal_length`),
            CONCAT(`l`.`min_focal_length`, '.0 mm'),
            CONCAT(`n`.`focal_length`, '.0 mm')) AS `FocalLength`,
        IF((`f`.`exposed_at` IS NOT NULL),
            `f`.`exposed_at`,
            `fs`.`iso`) AS `ISO`,
        `n`.`description` AS `ImageDescription`,
        DATE_FORMAT(`n`.`date`, '%Y:%m:%d %H:%i:%s') AS `DateTimeOriginal`,
        IF((`n`.`latitude` >= 0),
            CONCAT('+', FORMAT(`n`.`latitude`, 6)),
            FORMAT(`n`.`latitude`, 6)) AS `GPSLatitude`,
        IF((`n`.`longitude` >= 0),
            CONCAT('+', FORMAT(`n`.`longitude`, 6)),
            FORMAT(`n`.`longitude`, 6)) AS `GPSLongitude`,
        IF((`ep`.`exposure_program` > 0),
            `ep`.`exposure_program`,
            NULL) AS `ExposureProgram`,
        IF((`mm`.`metering_mode` > 0),
            `mm`.`metering_mode`,
            NULL) AS `MeteringMode`,
        (CASE
            WHEN ISNULL(`n`.`flash`) THEN NULL
            WHEN (`n`.`flash` = 0) THEN 'No Flash'
            WHEN (`n`.`flash` > 0) THEN 'Fired'
        END) AS `Flash`,
        IF((`l`.`min_focal_length` = `l`.`max_focal_length`),
            CONCAT(ROUND((`l`.`min_focal_length` * `NEGATIVE_SIZE`.`crop_factor`),
                            0),
                    ' mm'),
            CONCAT(ROUND((`n`.`focal_length` * `NEGATIVE_SIZE`.`crop_factor`),
                            0),
                    ' mm')) AS `FocalLengthIn35mmFormat`,
        CONCAT('Copyright ',
                `p`.`name`,
                ' ',
                YEAR(`n`.`date`)) AS `Copyright`,
        CONCAT(`n`.`description`,
                '
                Film: ',
                `fsm`.`manufacturer`,
                ' ',
                `fs`.`name`,
                IFNULL(CONCAT('
                                                                Paper: ',
                                `psm`.`manufacturer`,
                                ' ',
                                `ps`.`name`),
                        '')) AS `UserComment`
    FROM
        (((((((((((((((`scans_negs` `n`
        JOIN `FILM` `f` ON ((`n`.`film_id` = `f`.`film_id`)))
        JOIN `FILMSTOCK` `fs` ON ((`f`.`filmstock_id` = `fs`.`filmstock_id`)))
        JOIN `PERSON` `p` ON ((`n`.`photographer_id` = `p`.`person_id`)))
        JOIN `CAMERA` `c` ON ((`f`.`camera_id` = `c`.`camera_id`)))
        LEFT JOIN `MANUFACTURER` `cm` ON ((`c`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `LENS` `l` ON ((`n`.`lens_id` = `l`.`lens_id`)))
        LEFT JOIN `MANUFACTURER` `lm` ON ((`l`.`manufacturer_id` = `lm`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` `ep` ON ((`n`.`exposure_program` = `ep`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE` `mm` ON ((`n`.`metering_mode` = `mm`.`metering_mode_id`)))
        JOIN `SCAN` `s` ON ((`n`.`scan_id` = `s`.`scan_id`)))
        LEFT JOIN `PRINT` ON ((`s`.`print_id` = `PRINT`.`print_id`)))
        LEFT JOIN `NEGATIVE_SIZE` ON ((`c`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`)))
        LEFT JOIN `MANUFACTURER` `fsm` ON ((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`)))
        LEFT JOIN `PAPER_STOCK` `ps` ON ((`PRINT`.`paper_stock_id` = `ps`.`paper_stock_id`)))
        LEFT JOIN `MANUFACTURER` `psm` ON ((`ps`.`manufacturer_id` = `psm`.`manufacturer_id`)));


ALTER TABLE `FILM`
DROP FOREIGN KEY `fk_FILM_2`;
ALTER TABLE `FILM`
DROP COLUMN `photographer_id`,
DROP INDEX `fk_FILM_2_idx` ;
