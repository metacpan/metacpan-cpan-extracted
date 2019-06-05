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
        (((((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        JOIN `LENS` ON ((`MOUNT`.`mount_id` = `LENS`.`mount_id`)))
        JOIN `MANUFACTURER` `CM` ON ((`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`)))
        JOIN `MANUFACTURER` `LM` ON ((`LENS`.`manufacturer_id` = `LM`.`manufacturer_id`)))
    WHERE
        ((`CAMERA`.`own` = 1)
            AND (`LENS`.`own` = 1));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`,
        `CAMERAMODEL`.`mount_id` AS `mount_id`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
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
        (((`CAMERA` `C`
        JOIN `CAMERAMODEL` `CM` ON ((`C`.`cameramodel_id` = `CM`.`cameramodel_id`)))
        JOIN `FILM` `F` ON ((`F`.`format_id` = `CM`.`format_id`)))
        JOIN `MANUFACTURER` `M` ON ((`CM`.`manufacturer_id` = `M`.`manufacturer_id`)))
    WHERE
        (`C`.`own` = 1)
    ORDER BY CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`);



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_exposure_programs` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERA`.`camera_id` IN (SELECT
                `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`
            FROM
                `EXPOSURE_PROGRAM_AVAILABLE`)))
            AND (`CAMERA`.`own` = 1)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_metering_data` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERA`.`camera_id` IN (SELECT
                `METERING_MODE_AVAILABLE`.`cameramodel_id`
            FROM
                `METERING_MODE_AVAILABLE`)))
            AND (`CAMERA`.`own` = 1)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_shutter_data` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERA`.`camera_id` IN (SELECT
                `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`
            FROM
                `SHUTTER_SPEED_AVAILABLE`)))
            AND (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)
            AND (`CAMERA`.`own` = 1)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_mount_adapter_by_film` AS
    SELECT
        `MA`.`mount_adapter_id` AS `id`,
        `M`.`mount` AS `opt`,
        `F`.`film_id` AS `film_id`
    FROM
        ((((`MOUNT_ADAPTER` `MA`
        JOIN `CAMERAMODEL` `CM` ON ((`CM`.`mount_id` = `MA`.`camera_mount`)))
        JOIN `CAMERA` `C` ON ((`C`.`cameramodel_id` = `CM`.`cameramodel_id`)))
        JOIN `FILM` `F` ON ((`F`.`camera_id` = `C`.`camera_id`)))
        JOIN `MOUNT` `M` ON ((`M`.`mount_id` = `MA`.`lens_mount`)));



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_movie_camera` AS
    SELECT
        `C`.`camera_id` AS `id`,
        CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`) AS `opt`
    FROM
        ((`CAMERA` `C`
        JOIN `CAMERAMODEL` `CM` ON ((`C`.`cameramodel_id` = `CM`.`cameramodel_id`)))
        JOIN `MANUFACTURER` `M` ON ((`CM`.`manufacturer_id` = `M`.`manufacturer_id`)))
    WHERE
        ((`C`.`own` = 1) AND (`CM`.`video` = 1)
            AND (`CM`.`digital` = 0))
    ORDER BY CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`);



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_film` AS
    SELECT
        `FILM`.`film_id` AS `Film ID`,
        CONCAT('Box speed ',
                `FILMSTOCK`.`iso`,
                ' exposed at EI ',
                `FILM`.`exposed_at`,
                IF(`FILM`.`dev_n`,
                    CONCAT(' (',
                            IF(SIGN(`FILM`.`dev_n`),
                                CONCAT('N+', `FILM`.`dev_n`),
                                CONCAT('N-', `FILM`.`dev_n`)),
                            ')'),
                    '')) AS `ISO`,
        `FILM`.`date` AS `Date`,
        `FILM`.`notes` AS `Title`,
        `FILM`.`frames` AS `Frames`,
        `FILM`.`dev_time` AS `dev_time`,
        `FILM`.`dev_temp` AS `dev_temp`,
        `FILM`.`development_notes` AS `Development notes`,
        `FILM`.`processed_by` AS `Processed by`,
        CONCAT(`fm`.`manufacturer`,
                ' ',
                `FILMSTOCK`.`name`) AS `Filmstock`,
        CONCAT(`cm`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        CONCAT(`dm`.`manufacturer`,
                ' ',
                `DEVELOPER`.`name`) AS `Developer`,
        `ARCHIVE`.`name` AS `Archive`
    FROM
        (((((((((`FILM`
        LEFT JOIN `FILMSTOCK` ON ((`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`)))
        LEFT JOIN `MANUFACTURER` `fm` ON ((`FILMSTOCK`.`manufacturer_id` = `fm`.`manufacturer_id`)))
        LEFT JOIN `FORMAT` ON ((`FILM`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `DEVELOPER` ON ((`FILM`.`developer_id` = `DEVELOPER`.`developer_id`)))
        LEFT JOIN `CAMERA` `c` ON ((`FILM`.`camera_id` = `c`.`camera_id`)))
        LEFT JOIN `CAMERAMODEL` ON ((`c`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `MANUFACTURER` `cm` ON ((`CAMERAMODEL`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `MANUFACTURER` `dm` ON ((`DEVELOPER`.`manufacturer_id` = `dm`.`manufacturer_id`)))
        LEFT JOIN `ARCHIVE` ON ((`FILM`.`archive_id` = `ARCHIVE`.`archive_id`)));



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_movie` AS
    SELECT
        `MOVIE`.`movie_id` AS `Movie ID`,
        `MOVIE`.`title` AS `Title`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        CONCAT(`LM`.`manufacturer`, ' ', `LENS`.`model`) AS `Lens`,
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
        (((((((((`MOVIE`
        LEFT JOIN `CAMERA` ON ((`MOVIE`.`camera_id` = `CAMERA`.`camera_id`)))
        LEFT JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `FILMSTOCK` ON ((`MOVIE`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`)))
        LEFT JOIN `LENS` ON ((`MOVIE`.`lens_id` = `LENS`.`lens_id`)))
        LEFT JOIN `MANUFACTURER` `CM` ON ((`CM`.`manufacturer_id` = `CAMERAMODEL`.`manufacturer_id`)))
        LEFT JOIN `MANUFACTURER` `FM` ON ((`FM`.`manufacturer_id` = `FILMSTOCK`.`manufacturer_id`)))
        LEFT JOIN `MANUFACTURER` `LM` ON ((`LM`.`manufacturer_id` = `LENS`.`manufacturer_id`)))
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
        CONCAT(`lm`.`manufacturer`, ' ', `l`.`model`) AS `Lens`,
        `p`.`name` AS `Photographer`,
        CONCAT('f/', `n`.`aperture`) AS `Aperture`,
        `n`.`description` AS `Caption`,
        IF((`l`.`min_focal_length` = `l`.`max_focal_length`),
            CONCAT(`l`.`min_focal_length`, 'mm'),
            CONCAT(`n`.`focal_length`, 'mm')) AS `Focal length`,
        `ep`.`exposure_program` AS `Exposure program`,
        COUNT(`PRINT`.`print_id`) AS `Prints made`,
        CONCAT(`cm`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        CONCAT(`fsm`.`manufacturer`, ' ', `fs`.`name`) AS `Filmstock`
    FROM
        (((((((((((((`NEGATIVE` `n`
        JOIN `FILM` `f` ON ((`n`.`film_id` = `f`.`film_id`)))
        JOIN `FILMSTOCK` `fs` ON ((`f`.`filmstock_id` = `fs`.`filmstock_id`)))
        JOIN `CAMERA` `c` ON ((`f`.`camera_id` = `c`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`c`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` `cm` ON ((`CAMERAMODEL`.`manufacturer_id` = `cm`.`manufacturer_id`)))
        LEFT JOIN `PERSON` `p` ON ((`n`.`photographer_id` = `p`.`person_id`)))
        LEFT JOIN `MANUFACTURER` `fsm` ON ((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`)))
        LEFT JOIN `LENS` `l` ON ((`n`.`lens_id` = `l`.`lens_id`)))
        LEFT JOIN `MANUFACTURER` `lm` ON ((`l`.`manufacturer_id` = `lm`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` `ep` ON ((`n`.`exposure_program` = `ep`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE` `mm` ON ((`n`.`metering_mode` = `mm`.`metering_mode_id`)))
        LEFT JOIN `PRINT` ON ((`n`.`negative_id` = `PRINT`.`negative_id`)))
        LEFT JOIN `SCAN` `s` ON ((`n`.`negative_id` = `s`.`negative_id`)))
    WHERE
        (`s`.`filename` IS NOT NULL)
    GROUP BY `n`.`negative_id`;



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_cameras_by_decade` AS
    SELECT
        (FLOOR((`CAMERAMODEL`.`introduced` / 10)) * 10) AS `Decade`,
        COUNT(`CAMERA`.`camera_id`) AS `Cameras`
    FROM
        (`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
    WHERE
        (`CAMERAMODEL`.`introduced` IS NOT NULL)
    GROUP BY (FLOOR((`CAMERAMODEL`.`introduced` / 10)) * 10);



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_never_used_cameras` AS
    SELECT
        CONCAT('#',
                `CAMERA`.`camera_id`,
                ' ',
                `MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`
    FROM
        (((`CAMERA`
        LEFT JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        LEFT JOIN `FILM` ON ((`CAMERA`.`camera_id` = `FILM`.`camera_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        (ISNULL(`FILM`.`camera_id`)
            AND (`CAMERA`.`own` <> 0)
            AND (`CAMERAMODEL`.`digital` = 0)
            AND (`CAMERAMODEL`.`video` = 0));



CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_total_negatives_per_camera` AS
    SELECT
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        COUNT(`NEGATIVE`.`negative_id`) AS `Frames shot`
    FROM
        ((((`CAMERA`
        LEFT JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `FILM` ON ((`CAMERA`.`camera_id` = `FILM`.`camera_id`)))
        JOIN `NEGATIVE` ON ((`FILM`.`film_id` = `NEGATIVE`.`film_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    GROUP BY `CAMERA`.`camera_id`
    ORDER BY COUNT(`NEGATIVE`.`negative_id`) DESC;
