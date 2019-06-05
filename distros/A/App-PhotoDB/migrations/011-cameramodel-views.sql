CREATE
    OR REPLACE ALGORITHM=UNDEFINED
VIEW `camera_chooser` AS
    SELECT 
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`,
        `CAMERAMODEL`.`manufacturer_id` AS `manufacturer_id`,
        `CAMERAMODEL`.`mount_id` AS `mount_id`,
        `CAMERAMODEL`.`format_id` AS `format_id`,
        `CAMERAMODEL`.`focus_type_id` AS `focus_type_id`,
        `CAMERAMODEL`.`metering` AS `metering`,
        `CAMERAMODEL`.`coupled_metering` AS `coupled_metering`,
        `CAMERAMODEL`.`metering_type_id` AS `metering_type_id`,
        `CAMERAMODEL`.`body_type_id` AS `body_type_id`,
        `CAMERAMODEL`.`weight` AS `weight`,
        `CAMERA`.`manufactured` AS `manufactured`,
        `CAMERAMODEL`.`negative_size_id` AS `negative_size_id`,
        `CAMERAMODEL`.`shutter_type_id` AS `shutter_type_id`,
        `CAMERAMODEL`.`shutter_model` AS `shutter_model`,
        `CAMERAMODEL`.`cable_release` AS `cable_release`,
        `CAMERAMODEL`.`power_drive` AS `power_drive`,
        `CAMERAMODEL`.`continuous_fps` AS `continuous_fps`,
        `CAMERAMODEL`.`video` AS `video`,
        `CAMERAMODEL`.`digital` AS `digital`,
        `CAMERAMODEL`.`fixed_mount` AS `fixed_mount`,
        `CAMERA`.`lens_id` AS `lens_id`,
        `CAMERAMODEL`.`battery_qty` AS `battery_qty`,
        `CAMERAMODEL`.`battery_type` AS `battery_type`,
        `CAMERAMODEL`.`min_shutter` AS `min_shutter`,
        `CAMERAMODEL`.`max_shutter` AS `max_shutter`,
        `CAMERAMODEL`.`bulb` AS `bulb`,
        `CAMERAMODEL`.`time` AS `time`,
        `CAMERAMODEL`.`min_iso` AS `min_iso`,
        `CAMERAMODEL`.`max_iso` AS `max_iso`,
        `CAMERAMODEL`.`af_points` AS `af_points`,
        `CAMERAMODEL`.`int_flash` AS `int_flash`,
        `CAMERAMODEL`.`int_flash_gn` AS `int_flash_gn`,
        `CAMERAMODEL`.`ext_flash` AS `ext_flash`,
        `CAMERAMODEL`.`flash_metering` AS `flash_metering`,
        `CAMERAMODEL`.`pc_sync` AS `pc_sync`,
        `CAMERAMODEL`.`hotshoe` AS `hotshoe`,
        `CAMERAMODEL`.`coldshoe` AS `coldshoe`,
        `CAMERAMODEL`.`x_sync` AS `x_sync`,
        `CAMERAMODEL`.`meter_min_ev` AS `meter_min_ev`,
        `CAMERAMODEL`.`meter_max_ev` AS `meter_max_ev`,
        `CAMERAMODEL`.`dof_preview` AS `dof_preview`,
        `CAMERAMODEL`.`tripod` AS `tripod`,
        `CAMERA`.`display_lens` AS `display_lens`
    FROM
        (((((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON ((`CAMERA`.`camera_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`camera_id`)))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON ((`CAMERA`.`camera_id` = `METERING_MODE_AVAILABLE`.`camera_id`)))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERA`.`camera_id` = `SHUTTER_SPEED_AVAILABLE`.`camera_id`)))
    WHERE
        (`CAMERA`.`own` = 1)
    GROUP BY `CAMERA`.`camera_id`
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);





CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`,
        `CAMERA`.`mount_id` AS `mount_id`
    FROM
        (`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `MANUFACTURER` ON (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        (`CAMERA`.`own` = 1)
    ORDER BY (CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`) COLLATE utf8mb4_general_ci);


CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_by_film` AS
    SELECT
        `C`.`camera_id` AS `id`,
        CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`) AS `opt`,
        `F`.`film_id` AS `film_id`
    FROM
        ((`CAMERA` `C`
        JOIN `CAMERAMODEL` `CM` ON ((`C`.`cameramodel_id` = `CM`.`cameramodel_id`))
        JOIN `FILM` `F` ON (`F`.`format_id` = `C`.`format_id`)
        JOIN `MANUFACTURER` `M` ON (`C`.`manufacturer_id` = `M`.`manufacturer_id`)))
    WHERE
        ((`C`.`own` = 1))
    ORDER BY CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`);



CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `cameralens_compat` AS
    SELECT
        `CAMERA`.`camera_id` AS `camera_id`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `camera`,
        `LENS`.`lens_id` AS `lens_id`,
        CONCAT(`LM`.`manufacturer`, ' ', `LENS`.`model`) AS `lens`
    FROM
        ((((`CAMERA`
        JOIN CAMERAMODEL ON ((CAMERA.cameramodel_id = CAMERAMODEL.cameramodel_id))
        JOIN `MOUNT` ON ((`CAMERA`.`mount_id` = `MOUNT`.`mount_id`)))
        JOIN `LENS` ON ((`MOUNT`.`mount_id` = `LENS`.`mount_id`)))
        JOIN `MANUFACTURER` `CM` ON ((`CAMERA`.`manufacturer_id` = `CM`.`manufacturer_id`)))
        JOIN `MANUFACTURER` `LM` ON ((`LENS`.`manufacturer_id` = `LM`.`manufacturer_id`)))
    WHERE
        ((`CAMERA`.`own` = 1)
            AND (`LENS`.`own` = 1));


CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_lens_by_film` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        `LENS`.`model` AS `opt`,
        `FILM`.`film_id` AS `film_id`
    FROM
        (((`FILM`
        JOIN `CAMERA` ON ((`FILM`.`camera_id` = `CAMERA`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `LENS` ON ((`CAMERAMODEL`.`mount_id` = `LENS`.`mount_id`)));


CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_movie_camera` AS
    SELECT
        `C`.`camera_id` AS `id`,
        CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`) AS `opt`
    FROM
        ((`CAMERA` `C`
        JOIN `CAMERAMODEL` `CM` ON (`C`.`cameramodel_id` = `CM`.`cameramodel_id`))
        JOIN `MANUFACTURER` `M` ON (`C`.`manufacturer_id` = `M`.`manufacturer_id`))
    WHERE
        ((`C`.`own` = 1) AND (`CM`.`video` = 1)
            AND (`CM`.`digital` = 0))
    ORDER BY CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`);



CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_teleconverter_by_film` AS
    SELECT
        `T`.`teleconverter_id` AS `id`,
        CONCAT(`M`.`manufacturer`,
                ' ',
                `T`.`model`,
                ' (',
                `T`.`factor`,
                'x)') AS `opt`,
        `F`.`film_id` AS `film_id`
    FROM
        ((((`TELECONVERTER` `T`
        JOIN `CAMERAMODEL` `CM` on ((`CM`.`mount_id` = `T`.`mount_id`)))
        JOIN `CAMERA` `C` ON ((`C`.`cameramodel_id` = `CM`.`cameramodel_id`)))
        JOIN `FILM` `F` ON ((`F`.`camera_id` = `C`.`camera_id`)))
        JOIN `MANUFACTURER` `M` ON ((`M`.`manufacturer_id` = `T`.`manufacturer_id`)));



CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `current_films` AS
    SELECT
        `FILM`.`film_id` AS `id`,
        CONCAT(`FM`.`manufacturer`,
                ' ',
                `FILMSTOCK`.`name`,
                IFNULL(CONCAT(' loaded into ',
                                `CM`.`manufacturer`,
                                ' ',
                                `CAMERAMODEL`.`model`),
                        ''),
                IFNULL(CONCAT(' on ', `FILM`.`date_loaded`), ''),
                ', ',
                COUNT(`NEGATIVE`.`film_id`),
                IFNULL(CONCAT('/', `FILM`.`frames`), ''),
                ' frames registered') AS `opt`
    FROM
        ((((((`FILM`
        JOIN `CAMERA` ON ((`FILM`.`camera_id` = `CAMERA`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` `CM` ON ((`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`)))
        JOIN `FILMSTOCK` ON ((`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`)))
        JOIN `MANUFACTURER` `FM` ON ((`FILMSTOCK`.`manufacturer_id` = `FM`.`manufacturer_id`)))
        LEFT JOIN `NEGATIVE` ON ((`FILM`.`film_id` = `NEGATIVE`.`film_id`)))
    WHERE
        ISNULL(`FILM`.`date`)
    GROUP BY `FILM`.`film_id`;



CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `exifdata` AS
    SELECT
        `f`.`film_id` AS `film_id`,
        `n`.`negative_id` AS `negative_id`,
        `PRINT`.`print_id` AS `print_id`,
        `cm`.`manufacturer` AS `Make`,
        CONCAT(`cm`.`manufacturer`, ' ', `cmod`.`model`) AS `Model`,
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
        ((((((((((((((((`scans_negs` `n`
        JOIN `FILM` `f` ON ((`n`.`film_id` = `f`.`film_id`)))
        JOIN `FILMSTOCK` `fs` ON ((`f`.`filmstock_id` = `fs`.`filmstock_id`)))
        JOIN `PERSON` `p` ON ((`n`.`photographer_id` = `p`.`person_id`)))
        JOIN `CAMERA` `c` ON ((`f`.`camera_id` = `c`.`camera_id`)))
        JOIN `CAMERAMODEL` `cmod` on ((`c`.`cameramodel_id` = `cmod`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` `cm` ON ((`cmod`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `LENS` `l` ON ((`n`.`lens_id` = `l`.`lens_id`)))
        LEFT JOIN `MANUFACTURER` `lm` ON ((`l`.`manufacturer_id` = `lm`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` `ep` ON ((`n`.`exposure_program` = `ep`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE` `mm` ON ((`n`.`metering_mode` = `mm`.`metering_mode_id`)))
        JOIN `SCAN` `s` ON ((`n`.`scan_id` = `s`.`scan_id`)))
        LEFT JOIN `PRINT` ON ((`s`.`print_id` = `PRINT`.`print_id`)))
        LEFT JOIN `NEGATIVE_SIZE` ON ((`cmod`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`)))
        LEFT JOIN `MANUFACTURER` `fsm` ON ((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`)))
        LEFT JOIN `PAPER_STOCK` `ps` ON ((`PRINT`.`paper_stock_id` = `ps`.`paper_stock_id`)))
        LEFT JOIN `MANUFACTURER` `psm` ON ((`ps`.`manufacturer_id` = `psm`.`manufacturer_id`)));


CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_camera` AS
    SELECT
        `CAMERA`.`camera_id` AS `Camera ID`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERA`.`model`) AS `Camera`,
        `NEGATIVE_SIZE`.`negative_size` AS `Negative size`,
        `BODY_TYPE`.`body_type` AS `Body type`,
        `MOUNT`.`mount` AS `Mount`,
        `FORMAT`.`format` AS `Film format`,
        `FOCUS_TYPE`.`focus_type` AS `Focus type`,
        PRINTBOOL(`CAMERA`.`metering`) AS `Metering`,
        `CAMERA`.`coupled_metering` AS `Coupled metering`,
        `METERING_TYPE`.`metering` AS `Metering type`,
        CONCAT(`CAMERA`.`weight`, 'g') AS `Weight`,
        `CAMERA`.`acquired` AS `Date acquired`,
        CONCAT('£', `CAMERA`.`cost`) AS `Cost`,
        CONCAT(`CAMERA`.`introduced`,
                '-',
                IFNULL(`CAMERA`.`discontinued`, '?')) AS `Manufactured between`,
        `CAMERA`.`serial` AS `Serial number`,
        `CAMERA`.`datecode` AS `Datecode`,
        `CAMERA`.`manufactured` AS `Year of manufacture`,
        `SHUTTER_TYPE`.`shutter_type` AS `Shutter type`,
        `CAMERA`.`shutter_model` AS `Shutter model`,
        PRINTBOOL(`CAMERA`.`cable_release`) AS `Cable release`,
        CONCAT(`CAMERA`.`viewfinder_coverage`, '%') AS `Viewfinder coverage`,
        PRINTBOOL(`CAMERA`.`power_drive`) AS `Power drive`,
        `CAMERA`.`continuous_fps` AS `continuous_fps`,
        PRINTBOOL(`CAMERA`.`video`) AS `Video`,
        PRINTBOOL(`CAMERA`.`digital`) AS `Digital`,
        PRINTBOOL(`CAMERA`.`fixed_mount`) AS `Fixed mount`,
        `LENS`.`model` AS `Lens`,
        CONCAT(`CAMERA`.`battery_qty`,
                ' x ',
                `BATTERY`.`battery_name`) AS `Battery`,
        `CAMERA`.`notes` AS `Notes`,
        `CAMERA`.`lost` AS `Lost`,
        `CAMERA`.`lost_price` AS `Lost price`,
        `CAMERA`.`source` AS `Source`,
        `CAMERA`.`bulb` AS `Bulb`,
        `CAMERA`.`time` AS `Time`,
        CONCAT(`CAMERA`.`min_iso`,
                '-',
                `CAMERA`.`max_iso`) AS `ISO range`,
        `CAMERA`.`af_points` AS `Autofocus points`,
        PRINTBOOL(`CAMERA`.`int_flash`) AS `Internal flash`,
        `CAMERA`.`int_flash_gn` AS `Internal flash guide number`,
        PRINTBOOL(`CAMERA`.`ext_flash`) AS `External flash`,
        `CAMERA`.`flash_metering` AS `Flash metering`,
        PRINTBOOL(`CAMERA`.`pc_sync`) AS `PC sync socket`,
        PRINTBOOL(`CAMERA`.`hotshoe`) AS `Hotshoe`,
        PRINTBOOL(`CAMERA`.`coldshoe`) AS `Coldshoe`,
        `CAMERA`.`x_sync` AS `X-sync speed`,
        CONCAT(`CAMERA`.`meter_min_ev`,
                '-',
                `CAMERA`.`meter_max_ev`) AS `Meter range`,
        `CONDITION`.`name` AS `Condition`,
        PRINTBOOL(`CAMERA`.`dof_preview`) AS `Depth of field preview`,
        GROUP_CONCAT(DISTINCT `EXPOSURE_PROGRAM`.`exposure_program`
            SEPARATOR ', ') AS `Exposure programs`,
        GROUP_CONCAT(DISTINCT `METERING_MODE`.`metering_mode`
            SEPARATOR ', ') AS `Metering modes`,
        GROUP_CONCAT(DISTINCT `SHUTTER_SPEED_AVAILABLE`.`shutter_speed`
            SEPARATOR ', ') AS `Shutter speeds`,
        IF(`LENS`.`zoom`,
            CONCAT(`LENS`.`min_focal_length`,
                    '-',
                    `LENS`.`max_focal_length`,
                    'mm'),
            CONCAT(`LENS`.`min_focal_length`, 'mm')) AS `Focal length`,
        CONCAT('f/', `LENS`.`max_aperture`) AS `Maximum aperture`,
        COUNT(DISTINCT `FILM`.`film_id`) AS `Films loaded`,
        COUNT(DISTINCT `NEGATIVE`.`negative_id`) AS `Frames shot`
    FROM
        (((((((((((((((((((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `NEGATIVE_SIZE` ON ((`CAMERAMODEL`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`)))
        LEFT JOIN `BODY_TYPE` ON ((`CAMERAMODEL`.`body_type_id` = `BODY_TYPE`.`body_type_id`)))
        LEFT JOIN `BATTERY` ON ((`CAMERAMODEL`.`battery_type` = `BATTERY`.`battery_type`)))
        LEFT JOIN `METERING_TYPE` ON ((`CAMERAMODEL`.`metering_type_id` = `METERING_TYPE`.`metering_type_id`)))
        LEFT JOIN `SHUTTER_TYPE` ON ((`CAMERAMODEL`.`shutter_type_id` = `SHUTTER_TYPE`.`shutter_type_id`)))
        LEFT JOIN `CONDITION` ON ((`CAMERA`.`condition_id` = `CONDITION`.`condition_id`)))
        LEFT JOIN `FOCUS_TYPE` ON ((`CAMERAMODEL`.`focus_type_id` = `FOCUS_TYPE`.`focus_type_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`camera_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` ON ((`EXPOSURE_PROGRAM_AVAILABLE`.`exposure_program_id` = `EXPOSURE_PROGRAM`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`camera_id`)))
        LEFT JOIN `METERING_MODE` ON ((`METERING_MODE_AVAILABLE`.`metering_mode_id` = `METERING_MODE`.`metering_mode_id`)))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`camera_id`)))
        LEFT JOIN `FORMAT` ON ((`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `LENS` ON ((`CAMERA`.`lens_id` = `LENS`.`lens_id`)))
        LEFT JOIN `FILM` ON ((`CAMERA`.`camera_id` = `FILM`.`camera_id`)))
        LEFT JOIN `NEGATIVE` ON ((`FILM`.`film_id` = `NEGATIVE`.`film_id`)))
    WHERE
        (`CAMERA`.`own` = 1)
    GROUP BY `CAMERA`.`camera_id`;

