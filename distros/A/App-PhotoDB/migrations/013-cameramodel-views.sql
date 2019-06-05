CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
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
        LEFT JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`)))
    WHERE
        (`CAMERA`.`own` = 1)
    GROUP BY `CAMERA`.`camera_id`
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);


CREATE
     OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_accessory_compat` AS
    SELECT
        `ACCESSORY`.`accessory_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `ACCESSORY`.`model`,
                ' (',
                `ACCESSORY_TYPE`.`accessory_type`,
                ')') AS `opt`,
        `ACCESSORY_COMPAT`.`cameramodel_id` AS `cameramodel_id`,
        `ACCESSORY_COMPAT`.`lens_id` AS `lens_id`
    FROM
        (((`ACCESSORY`
        JOIN `ACCESSORY_COMPAT` ON ((`ACCESSORY_COMPAT`.`accessory_id` = `ACCESSORY`.`accessory_id`)))
        JOIN `ACCESSORY_TYPE` ON ((`ACCESSORY`.`accessory_type_id` = `ACCESSORY_TYPE`.`accessory_type_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`ACCESSORY`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)));


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_exposure_programs` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERA`.`model`) AS `opt`
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
            `CAMERA`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_metering_data` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERA`.`model`) AS `opt`
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
            `CAMERA`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_camera_without_shutter_data` AS
    SELECT
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERA`.`model`) AS `opt`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERA`.`camera_id` IN (SELECT
                `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`
            FROM
                `SHUTTER_SPEED_AVAILABLE`)))
            AND (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)
            AND (`CAMERA`.`own` = 1)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERA`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_shutter_speed_by_film` AS
    SELECT
        `SHUTTER_SPEED`.`shutter_speed` AS `id`,
        '' AS `opt`,
        `FILM`.`film_id` AS `film_id`
    FROM
        ((((`FILM`
        JOIN `CAMERA` ON ((`FILM`.`camera_id` = `CAMERA`.`camera_id`)))
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`)))
        JOIN `SHUTTER_SPEED` ON ((`SHUTTER_SPEED_AVAILABLE`.`shutter_speed` = `SHUTTER_SPEED`.`shutter_speed`)))
    ORDER BY `SHUTTER_SPEED`.`duration`;


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
        `LENS`.`model` AS `Lens`,
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
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `EXPOSURE_PROGRAM` ON ((`EXPOSURE_PROGRAM_AVAILABLE`.`exposure_program_id` = `EXPOSURE_PROGRAM`.`exposure_program_id`)))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `METERING_MODE` ON ((`METERING_MODE_AVAILABLE`.`metering_mode_id` = `METERING_MODE`.`metering_mode_id`)))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON ((`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`)))
        LEFT JOIN `FORMAT` ON ((`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `LENS` ON ((`CAMERA`.`lens_id` = `LENS`.`lens_id`)))
        LEFT JOIN `FILM` ON ((`CAMERA`.`camera_id` = `FILM`.`camera_id`)))
        LEFT JOIN `NEGATIVE` ON ((`FILM`.`film_id` = `NEGATIVE`.`film_id`)))
    WHERE
        (`CAMERA`.`own` = 1)
    GROUP BY `CAMERA`.`camera_id`;
