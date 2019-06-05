CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `cameralens_compat` AS
    SELECT 
        `CAMERA`.`camera_id` AS `camera_id`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `camera`,
        `LENS`.`lens_id` AS `lens_id`,
        CONCAT(`LM`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `lens`
    FROM
        ((((((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        JOIN `LENS` ON ((`MOUNT`.`mount_id` = `LENS`.`mount_id`)))
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MANUFACTURER` `CM` ON ((`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`)))
        JOIN `MANUFACTURER` `LM` ON ((`LENSMODEL`.`manufacturer_id` = `LM`.`manufacturer_id`)))
    WHERE
        ((`CAMERA`.`own` = 1)
            AND (`LENS`.`own` = 1));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_display_lens` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `opt`,
        `CAMERA`.`camera_id` AS `camera_id`,
        `LENSMODEL`.`mount_id` AS `mount_id`
    FROM
        (((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        LEFT JOIN `CAMERA` ON ((`LENS`.`lens_id` = `CAMERA`.`display_lens`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((`LENSMODEL`.`mount_id` IS NOT NULL)
            AND (`LENS`.`own` = 1))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `LENSMODEL`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_enlarger_lens` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `opt`
    FROM
        (((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MOUNT` ON ((`LENSMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((`MOUNT`.`purpose` = 'Enlarger')
            AND (`LENS`.`own` = 1));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_lens_by_film` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        `LENSMODEL`.`model` AS `opt`,
        `FILM`.`film_id` AS `film_id`
    FROM
        ((((`FILM`
        JOIN `CAMERA` ON ((`FILM`.`camera_id` = `CAMERA`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `LENS` ON ((`CAMERAMODEL`.`mount_id` = `LENS`.`mount_id`)))
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_lens` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `opt`
    FROM
        ((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((`LENS`.`own` = 1)
            AND (`LENSMODEL`.`fixed_mount` = 0))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `LENSMODEL`.`model`);


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
        CONCAT(`lm`.`manufacturer`, ' ', `lmod`.`model`) AS `LensModel`,
        CONCAT(`lm`.`manufacturer`, ' ', `lmod`.`model`) AS `Lens`,
        `l`.`serial` AS `LensSerialNumber`,
        `c`.`serial` AS `SerialNumber`,
        CONCAT(`f`.`directory`, '/', `s`.`filename`) AS `path`,
        `lmod`.`max_aperture` AS `MaxApertureValue`,
        `f`.`directory` AS `directory`,
        `s`.`filename` AS `filename`,
        `n`.`shutter_speed` AS `ExposureTime`,
        `n`.`aperture` AS `FNumber`,
        `n`.`aperture` AS `ApertureValue`,
        IF((`lmod`.`min_focal_length` = `lmod`.`max_focal_length`),
            CONCAT(`lmod`.`min_focal_length`, '.0 mm'),
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
        (((((((((((((((((`scans_negs` `n`
        JOIN `FILM` `f` ON ((`n`.`film_id` = `f`.`film_id`)))
        JOIN `FILMSTOCK` `fs` ON ((`f`.`filmstock_id` = `fs`.`filmstock_id`)))
        JOIN `PERSON` `p` ON ((`n`.`photographer_id` = `p`.`person_id`)))
        JOIN `CAMERA` `c` ON ((`f`.`camera_id` = `c`.`camera_id`)))
        JOIN `CAMERAMODEL` `cmod` ON ((`c`.`cameramodel_id` = `cmod`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` `cm` ON ((`cmod`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `LENS` `l` ON ((`n`.`lens_id` = `l`.`lens_id`)))
        JOIN `LENSMODEL` `lmod` ON ((`l`.`lensmodel_id` = `lmod`.`lensmodel_id`)))
        LEFT JOIN `MANUFACTURER` `lm` ON ((`lmod`.`manufacturer_id` = `lm`.`manufacturer_id`)))
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
                `CAMERAMODEL`.`model`) AS `Camera`,
        `NEGATIVE_SIZE`.`negative_size` AS `Negative size`,
        `BODY_TYPE`.`body_type` AS `Body type`,
        `MOUNT`.`mount` AS `Mount`,
        `FORMAT`.`format` AS `Film format`,
        `FOCUS_TYPE`.`focus_type` AS `Focus type`,
        PRINTBOOL(`CAMERAMODEL`.`metering`) AS `Metering`,
        `CAMERAMODEL`.`coupled_metering` AS `Coupled metering`,
        `METERING_TYPE`.`metering` AS `Metering type`,
        CONCAT(`CAMERAMODEL`.`weight`, 'g') AS `Weight`,
        `CAMERA`.`acquired` AS `Date acquired`,
        CONCAT('£', `CAMERA`.`cost`) AS `Cost`,
        CONCAT(`CAMERAMODEL`.`introduced`,
                '-',
                IFNULL(`CAMERAMODEL`.`discontinued`, '?')) AS `Manufactured between`,
        `CAMERA`.`serial` AS `Serial number`,
        `CAMERA`.`datecode` AS `Datecode`,
        `CAMERA`.`manufactured` AS `Year of manufacture`,
        `SHUTTER_TYPE`.`shutter_type` AS `Shutter type`,
        `CAMERAMODEL`.`shutter_model` AS `Shutter model`,
        PRINTBOOL(`CAMERAMODEL`.`cable_release`) AS `Cable release`,
        CONCAT(`CAMERAMODEL`.`viewfinder_coverage`, '%') AS `Viewfinder coverage`,
        PRINTBOOL(`CAMERAMODEL`.`power_drive`) AS `Power drive`,
        `CAMERAMODEL`.`continuous_fps` AS `continuous_fps`,
        PRINTBOOL(`CAMERAMODEL`.`video`) AS `Video`,
        PRINTBOOL(`CAMERAMODEL`.`digital`) AS `Digital`,
        PRINTBOOL(`CAMERAMODEL`.`fixed_mount`) AS `Fixed mount`,
        `LENSMODEL`.`model` AS `Lens`,
        CONCAT(`CAMERAMODEL`.`battery_qty`,
                ' x ',
                `BATTERY`.`battery_name`) AS `Battery`,
        `CAMERA`.`notes` AS `Notes`,
        `CAMERA`.`lost` AS `Lost`,
        `CAMERA`.`lost_price` AS `Lost price`,
        `CAMERA`.`source` AS `Source`,
        PRINTBOOL(`CAMERAMODEL`.`bulb`) AS `Bulb`,
        PRINTBOOL(`CAMERAMODEL`.`time`) AS `Time`,
        CONCAT(`CAMERAMODEL`.`min_iso`,
                '-',
                `CAMERAMODEL`.`max_iso`) AS `ISO range`,
        `CAMERAMODEL`.`af_points` AS `Autofocus points`,
        PRINTBOOL(`CAMERAMODEL`.`int_flash`) AS `Internal flash`,
        `CAMERAMODEL`.`int_flash_gn` AS `Internal flash guide number`,
        PRINTBOOL(`CAMERAMODEL`.`ext_flash`) AS `External flash`,
        `CAMERAMODEL`.`flash_metering` AS `Flash metering`,
        PRINTBOOL(`CAMERAMODEL`.`pc_sync`) AS `PC sync socket`,
        PRINTBOOL(`CAMERAMODEL`.`hotshoe`) AS `Hotshoe`,
        PRINTBOOL(`CAMERAMODEL`.`coldshoe`) AS `Coldshoe`,
        `CAMERAMODEL`.`x_sync` AS `X-sync speed`,
        CONCAT(`CAMERAMODEL`.`meter_min_ev`,
                '-',
                `CAMERAMODEL`.`meter_max_ev`) AS `Meter range`,
        `CONDITION`.`name` AS `Condition`,
        PRINTBOOL(`CAMERAMODEL`.`dof_preview`) AS `Depth of field preview`,
        GROUP_CONCAT(DISTINCT `EXPOSURE_PROGRAM`.`exposure_program`
            SEPARATOR ', ') AS `Exposure programs`,
        GROUP_CONCAT(DISTINCT `METERING_MODE`.`metering_mode`
            SEPARATOR ', ') AS `Metering modes`,
        GROUP_CONCAT(DISTINCT `SHUTTER_SPEED_AVAILABLE`.`shutter_speed`
            SEPARATOR ', ') AS `Shutter speeds`,
        IF(`LENSMODEL`.`zoom`,
            CONCAT(`LENSMODEL`.`min_focal_length`,
                    '-',
                    `LENSMODEL`.`max_focal_length`,
                    'mm'),
            CONCAT(`LENSMODEL`.`min_focal_length`, 'mm')) AS `Focal length`,
        CONCAT('f/', `LENSMODEL`.`max_aperture`) AS `Maximum aperture`,
        COUNT(DISTINCT `FILM`.`film_id`) AS `Films loaded`,
        COUNT(DISTINCT `NEGATIVE`.`negative_id`) AS `Frames shot`
    FROM
        ((((((((((((((((((((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `NEGATIVE_SIZE` ON ((`CAMERAMODEL`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`)))
        LEFT JOIN `BODY_TYPE` ON ((`CAMERAMODEL`.`body_type_id` = `BODY_TYPE`.`body_type_id`)))
        LEFT JOIN `BATTERY` ON ((`CAMERAMODEL`.`battery_type` = `BATTERY`.`battery_type`)))
        LEFT JOIN `METERING_TYPE` ON ((`CAMERAMODEL`.`metering_type_id` = `METERING_TYPE`.`metering_type_id`)))
        LEFT JOIN `SHUTTER_TYPE` ON ((`CAMERAMODEL`.`shutter_type_id` = `SHUTTER_TYPE`.`shutter_type_id`)))
        LEFT JOIN `CONDITION` ON ((`CAMERA`.`condition_id` = `CONDITION`.`condition_id`)))
        LEFT JOIN `FOCUS_TYPE` ON ((`CAMERAMODEL`.`focus_type_id` = `FOCUS_TYPE`.`focus_type_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` ON ((`EXPOSURE_PROGRAM_AVAILABLE`.`exposure_program_id` = `EXPOSURE_PROGRAM`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `METERING_MODE` ON ((`METERING_MODE_AVAILABLE`.`metering_mode_id` = `METERING_MODE`.`metering_mode_id`)))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `FORMAT` ON ((`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `LENS` ON ((`CAMERA`.`lens_id` = `LENS`.`lens_id`)))
        LEFT JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        LEFT JOIN `FILM` ON ((`CAMERA`.`camera_id` = `FILM`.`camera_id`)))
        LEFT JOIN `NEGATIVE` ON ((`FILM`.`film_id` = `NEGATIVE`.`film_id`)))
    WHERE
        (`CAMERA`.`own` = 1)
    GROUP BY `CAMERA`.`camera_id`;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_lens` AS
    SELECT
        `LENS`.`lens_id` AS `Lens ID`,
        `MOUNT`.`mount` AS `Mount`,
        IF(`LENS`.`zoom`,
            CONCAT(`LENSMODEL`.`min_focal_length`,
                    '-',
                    `LENSMODEL`.`max_focal_length`,
                    'mm'),
            CONCAT(`LENSMODEL`.`min_focal_length`, 'mm')) AS `Focal length`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`,
        CONCAT(`LENSMODEL`.`closest_focus`, 'cm') AS `Closest focus`,
        CONCAT('f/', `LENSMODEL`.`max_aperture`) AS `Maximum aperture`,
        CONCAT('f/', `LENSMODEL`.`min_aperture`) AS `Minimum aperture`,
        CONCAT(`LENSMODEL`.`elements`,
                '/',
                `LENSMODEL`.`groups`) AS `Elements/Groups`,
        CONCAT(`LENSMODEL`.`weight`, 'g') AS `Weight`,
        IF(`LENSMODEL`.`zoom`,
            CONCAT(`LENSMODEL`.`nominal_max_angle_diag`,
                    '°-',
                    `LENSMODEL`.`nominal_min_angle_diag`,
                    '°'),
            CONCAT(`LENSMODEL`.`nominal_max_angle_diag`,
                    '°')) AS `Angle of view`,
        `LENSMODEL`.`aperture_blades` AS `Aperture blades`,
        PRINTBOOL(`LENSMODEL`.`autofocus`) AS `Autofocus`,
        CONCAT(`LENSMODEL`.`filter_thread`, 'mm') AS `Filter thread`,
        CONCAT(`LENSMODEL`.`magnification`, '×') AS `Maximum magnification`,
        `LENSMODEL`.`url` AS `URL`,
        `LENS`.`serial` AS `Serial number`,
        `LENS`.`date_code` AS `Date code`,
        CONCAT(IFNULL(`LENSMODEL`.`introduced`, '?'),
                '-',
                IFNULL(`LENSMODEL`.`discontinued`, '?')) AS `Manufactured between`,
        `LENS`.`manufactured` AS `Year of manufacture`,
        `NEGATIVE_SIZE`.`negative_size` AS `Negative size`,
        `LENS`.`acquired` AS `Date acquired`,
        CONCAT('£', `LENS`.`cost`) AS `Cost`,
        `LENS`.`notes` AS `Notes`,
        `LENS`.`lost` AS `Date lost`,
        CONCAT('£', `LENS`.`lost_price`) AS `Price sold`,
        `LENS`.`source` AS `Source`,
        `LENSMODEL`.`coating` AS `Coating`,
        `LENSMODEL`.`hood` AS `Hood`,
        `LENSMODEL`.`exif_lenstype` AS `EXIF LensType`,
        PRINTBOOL(`LENSMODEL`.`rectilinear`) AS `Rectilinear`,
        CONCAT(`LENSMODEL`.`length`,
                '×',
                `LENSMODEL`.`diameter`,
                'mm') AS `Dimensions (l×w)`,
        `CONDITION`.`name` AS `Condition`,
        CONCAT(`LENSMODEL`.`image_circle`, 'mm') AS `Image circle`,
        `LENSMODEL`.`formula` AS `Optical formula`,
        `LENSMODEL`.`shutter_model` AS `Shutter model`,
        COUNT(`NEGATIVE`.`negative_id`) AS `Frames shot`
    FROM
        ((((((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        LEFT JOIN `MOUNT` ON ((`LENSMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `CONDITION` ON ((`LENS`.`condition_id` = `CONDITION`.`condition_id`)))
        LEFT JOIN `NEGATIVE_SIZE` ON ((`LENSMODEL`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`)))
        LEFT JOIN `NEGATIVE` ON ((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`)))
    WHERE
        ((`LENS`.`own` = 1)
            AND (`LENSMODEL`.`fixed_mount` = 0))
    GROUP BY `LENS`.`lens_id`;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_movie` AS
    SELECT
        `MOVIE`.`movie_id` AS `Movie ID`,
        `MOVIE`.`title` AS `Title`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        CONCAT(`LM`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`,
        `FORMAT`.`format` AS `Format`,
        PRINTBOOL(`MOVIE`.`sound`) AS `Sound`,
        `MOVIE`.`fps` AS `Frame rate`,
        CONCAT(`FM`.`manufacturer`,
                ' ',
                `FILMSTOCK`.`name`) AS `Filmstock`,
        `MOVIE`.`feet` AS `Length (feet)`,
        `MOVIE`.`date_loaded` AS `Date loaded`,
        `MOVIE`.`date_shot` AS `Date shot`,
        `MOVIE`.`date_processed` AS `Date processed`,
        `PROCESS`.`name` AS `Process`,
        `MOVIE`.`description` AS `Description`
    FROM
        ((((((((((`MOVIE`
        LEFT JOIN `CAMERA` ON ((`MOVIE`.`camera_id` = `CAMERA`.`camera_id`)))
        LEFT JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `FILMSTOCK` ON ((`MOVIE`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`)))
        LEFT JOIN `LENS` ON ((`MOVIE`.`lens_id` = `LENS`.`lens_id`)))
        LEFT JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        LEFT JOIN `MANUFACTURER` `CM` ON ((`CM`.`manufacturer_id` = `CAMERAMODEL`.`manufacturer_id`)))
        LEFT JOIN `MANUFACTURER` `FM` ON ((`FM`.`manufacturer_id` = `FILMSTOCK`.`manufacturer_id`)))
        LEFT JOIN `MANUFACTURER` `LM` ON ((`LM`.`manufacturer_id` = `LENSMODEL`.`manufacturer_id`)))
        LEFT JOIN `FORMAT` ON ((`MOVIE`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `PROCESS` ON ((`MOVIE`.`process_id` = `PROCESS`.`process_id`)));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_negative` AS
    SELECT
        `n`.`negative_id` AS `Negative ID`,
        `n`.`film_id` AS `Film ID`,
        `n`.`frame` AS `Frame`,
        `mm`.`metering_mode` AS `Metering mode`,
        DATE_FORMAT(`n`.`date`, '%Y-%m-%d %H:%i:%s') AS `Date`,
        CONCAT(`n`.`latitude`, ', ', `n`.`longitude`) AS `Location`,
        `s`.`filename` AS `Filename`,
        `n`.`shutter_speed` AS `Shutter speed`,
        CONCAT(`lm`.`manufacturer`, ' ', `lmod`.`model`) AS `Lens`,
        `p`.`name` AS `Photographer`,
        CONCAT('f/', `n`.`aperture`) AS `Aperture`,
        `n`.`description` AS `Caption`,
        IF((`lmod`.`min_focal_length` = `lmod`.`max_focal_length`),
            CONCAT(`lmod`.`min_focal_length`, 'mm'),
            CONCAT(`n`.`focal_length`, 'mm')) AS `Focal length`,
        `ep`.`exposure_program` AS `Exposure program`,
        COUNT(`PRINT`.`print_id`) AS `Prints made`,
        CONCAT(`cm`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        CONCAT(`fsm`.`manufacturer`, ' ', `fs`.`name`) AS `Filmstock`
    FROM
        ((((((((((((((`NEGATIVE` `n`
        JOIN `FILM` `f` ON ((`n`.`film_id` = `f`.`film_id`)))
        JOIN `FILMSTOCK` `fs` ON ((`f`.`filmstock_id` = `fs`.`filmstock_id`)))
        JOIN `CAMERA` `c` ON ((`f`.`camera_id` = `c`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`c`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` `cm` ON ((`CAMERAMODEL`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `PERSON` `p` ON ((`n`.`photographer_id` = `p`.`person_id`)))
        LEFT JOIN `MANUFACTURER` `fsm` ON ((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`)))
        LEFT JOIN `LENS` `l` ON ((`n`.`lens_id` = `l`.`lens_id`)))
        LEFT JOIN `LENSMODEL` `lmod` ON ((`l`.`lensmodel_id` = `lmod`.`lensmodel_id`)))
        LEFT JOIN `MANUFACTURER` `lm` ON ((`lmod`.`manufacturer_id` = `lm`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` `ep` ON ((`n`.`exposure_program` = `ep`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE` `mm` ON ((`n`.`metering_mode` = `mm`.`metering_mode_id`)))
        LEFT JOIN `PRINT` ON ((`n`.`negative_id` = `PRINT`.`negative_id`)))
        LEFT JOIN `SCAN` `s` ON ((`n`.`negative_id` = `s`.`negative_id`)))
    WHERE
        (`s`.`filename` IS NOT NULL)
    GROUP BY `n`.`negative_id`;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_print` AS
    SELECT
        CONCAT(`NEGATIVE`.`film_id`,
                '/',
                `NEGATIVE`.`frame`) AS `Negative`,
        `NEGATIVE`.`negative_id` AS `Negative ID`,
        `PRINT`.`print_id` AS `Print`,
        `NEGATIVE`.`description` AS `Description`,
        DISPLAYSIZE(`PRINT`.`width`, `PRINT`.`height`) AS `Size`,
        CONCAT(`PRINT`.`exposure_time`, 's') AS `Exposure time`,
        CONCAT('f/', `PRINT`.`aperture`) AS `Aperture`,
        `PRINT`.`filtration_grade` AS `Filtration grade`,
        CONCAT(`PAPER_STOCK_MANUFACTURER`.`manufacturer`,
                ' ',
                `PAPER_STOCK`.`name`) AS `Paper`,
        CONCAT(`ENLARGER_MANUFACTURER`.`manufacturer`,
                ' ',
                `ENLARGER`.`enlarger`) AS `Enlarger`,
        CONCAT(`LENS_MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Enlarger lens`,
        CONCAT(`FIRSTTONER_MANUFACTURER`.`manufacturer`,
                ' ',
                `FIRSTTONER`.`toner`,
                IF((`PRINT`.`toner_dilution` IS NOT NULL),
                    CONCAT(' (', `PRINT`.`toner_dilution`, ')'),
                    ''),
                IF((`PRINT`.`toner_time` IS NOT NULL),
                    CONCAT(' for ', `PRINT`.`toner_time`),
                    '')) AS `First toner`,
        CONCAT(`SECONDTONER_MANUFACTURER`.`manufacturer`,
                ' ',
                `SECONDTONER`.`toner`,
                IF((`PRINT`.`2nd_toner_dilution` IS NOT NULL),
                    CONCAT(' (', `PRINT`.`2nd_toner_dilution`, ')'),
                    ''),
                IF((`PRINT`.`2nd_toner_time` IS NOT NULL),
                    CONCAT(' for ', `PRINT`.`2nd_toner_time`),
                    '')) AS `Second toner`,
        DATE_FORMAT(`PRINT`.`date`, '%M %Y') AS `Print date`,
        DATE_FORMAT(`NEGATIVE`.`date`, '%M %Y') AS `Photo date`,
        `PERSON`.`name` AS `Photographer`,
        (CASE `PRINT`.`own`
            WHEN
                1
            THEN
                IFNULL(`ARCHIVE`.`name`,
                        'Owned; location unknown')
            WHEN
                0
            THEN
                IFNULL(`PRINT`.`location`,
                        'Not owned; location unknown')
            ELSE 'No location information'
        END) AS `Location`
    FROM
        ((((((((((((((`PRINT`
        JOIN `PAPER_STOCK` ON ((`PRINT`.`paper_stock_id` = `PAPER_STOCK`.`paper_stock_id`)))
        JOIN `MANUFACTURER` `PAPER_STOCK_MANUFACTURER` ON ((`PAPER_STOCK`.`manufacturer_id` = `PAPER_STOCK_MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `ENLARGER` ON ((`PRINT`.`enlarger_id` = `ENLARGER`.`enlarger_id`)))
        JOIN `MANUFACTURER` `ENLARGER_MANUFACTURER` ON ((`ENLARGER`.`manufacturer_id` = `ENLARGER_MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `LENS` ON ((`PRINT`.`lens_id` = `LENS`.`lens_id`)))
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MANUFACTURER` `LENS_MANUFACTURER` ON ((`LENS`.`manufacturer_id` = `LENS_MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `TONER` `FIRSTTONER` ON ((`PRINT`.`toner_id` = `FIRSTTONER`.`toner_id`)))
        LEFT JOIN `MANUFACTURER` `FIRSTTONER_MANUFACTURER` ON ((`FIRSTTONER`.`manufacturer_id` = `FIRSTTONER_MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `TONER` `SECONDTONER` ON ((`PRINT`.`2nd_toner_id` = `SECONDTONER`.`toner_id`)))
        LEFT JOIN `MANUFACTURER` `SECONDTONER_MANUFACTURER` ON ((`SECONDTONER`.`manufacturer_id` = `SECONDTONER_MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `NEGATIVE` ON ((`PRINT`.`negative_id` = `NEGATIVE`.`negative_id`)))
        LEFT JOIN `PERSON` ON ((`NEGATIVE`.`photographer_id` = `PERSON`.`person_id`)))
        LEFT JOIN `ARCHIVE` ON ((`PRINT`.`archive_id` = `ARCHIVE`.`archive_id`)));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_most_popular_lenses_relative` AS
    SELECT
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`,
        (TO_DAYS(CURDATE()) - TO_DAYS(`LENS`.`acquired`)) AS `Days owned`,
        COUNT(`NEGATIVE`.`negative_id`) AS `Frames shot`,
        (COUNT(`NEGATIVE`.`negative_id`) / (TO_DAYS(CURDATE()) - TO_DAYS(`LENS`.`acquired`))) AS `Frames shot per day`
    FROM
        ((((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        JOIN `NEGATIVE` ON ((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`)))
        JOIN `MOUNT` ON ((`LENS`.`mount_id` = `MOUNT`.`mount_id`)))
    WHERE
        ((`LENS`.`acquired` IS NOT NULL)
            AND (`MOUNT`.`fixed` = 0))
    GROUP BY `LENS`.`lens_id`
    ORDER BY (COUNT(`NEGATIVE`.`negative_id`) / (TO_DAYS(CURDATE()) - TO_DAYS(`LENS`.`acquired`))) DESC;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_never_used_lenses` AS
    SELECT
        CONCAT('#',
                `LENS`.`lens_id`,
                ' ',
                `MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`
    FROM
        ((((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        JOIN `MOUNT` ON ((`LENS`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `NEGATIVE` ON ((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`)))
    WHERE
        ((`LENSMODEL`.`fixed_mount` = 0)
            AND (`MOUNT`.`purpose` = 'Camera')
            AND (`MOUNT`.`digital_only` = 0)
            AND (`LENS`.`own` = 1)
            AND ISNULL(`NEGATIVE`.`negative_id`))
    ORDER BY `LENS`.`lens_id`;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_total_negatives_per_lens` AS
    SELECT
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`,
        COUNT(`NEGATIVE`.`negative_id`) AS `Frames shot`
    FROM
        ((((`LENS`
        JOIN `LENSMODEL` ON ((`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`)))
        JOIN `NEGATIVE` ON ((`LENS`.`lens_id` = `NEGATIVE`.`lens_id`)))
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        JOIN `MOUNT` ON ((`LENSMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
    WHERE
        ((`LENS`.`fixed_mount` = 0)
            AND (`MOUNT`.`purpose` = 'Camera'))
    GROUP BY `LENS`.`lens_id`
    ORDER BY COUNT(`NEGATIVE`.`negative_id`) DESC;
