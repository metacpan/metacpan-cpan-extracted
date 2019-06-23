CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `info_cameramodel` AS
    SELECT 
        `CAMERAMODEL`.`cameramodel_id` AS `Camera Model ID`,
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
        CONCAT(`CAMERAMODEL`.`introduced`,
                '-',
                IFNULL(`CAMERAMODEL`.`discontinued`, '?')) AS `Manufactured between`,
        `SHUTTER_TYPE`.`shutter_type` AS `Shutter type`,
        `CAMERAMODEL`.`shutter_model` AS `Shutter model`,
        PRINTBOOL(`CAMERAMODEL`.`cable_release`) AS `Cable release`,
        CONCAT(`CAMERAMODEL`.`viewfinder_coverage`, '%') AS `Viewfinder coverage`,
        PRINTBOOL(`CAMERAMODEL`.`power_drive`) AS `Power drive`,
        `CAMERAMODEL`.`continuous_fps` AS `Continuous framerate`,
        PRINTBOOL(`CAMERAMODEL`.`video`) AS `Video`,
        PRINTBOOL(`CAMERAMODEL`.`digital`) AS `Digital`,
        PRINTBOOL(`CAMERAMODEL`.`fixed_mount`) AS `Fixed mount`,
        `LENSMODEL`.`model` AS `Lens`,
        CONCAT(`CAMERAMODEL`.`battery_qty`,
                ' x ',
                `BATTERY`.`battery_name`) AS `Battery`,
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
        CONCAT('f/', `LENSMODEL`.`max_aperture`) AS `Maximum aperture`
    FROM
        (((((((((((((((`CAMERAMODEL`
        LEFT JOIN `MANUFACTURER` ON (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
        LEFT JOIN `NEGATIVE_SIZE` ON (`CAMERAMODEL`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))
        LEFT JOIN `BODY_TYPE` ON (`CAMERAMODEL`.`body_type_id` = `BODY_TYPE`.`body_type_id`))
        LEFT JOIN `BATTERY` ON (`CAMERAMODEL`.`battery_type` = `BATTERY`.`battery_type`))
        LEFT JOIN `METERING_TYPE` ON (`CAMERAMODEL`.`metering_type_id` = `METERING_TYPE`.`metering_type_id`))
        LEFT JOIN `SHUTTER_TYPE` ON (`CAMERAMODEL`.`shutter_type_id` = `SHUTTER_TYPE`.`shutter_type_id`))
        LEFT JOIN `FOCUS_TYPE` ON (`CAMERAMODEL`.`focus_type_id` = `FOCUS_TYPE`.`focus_type_id`))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`))
        LEFT JOIN `EXPOSURE_PROGRAM` ON (`EXPOSURE_PROGRAM_AVAILABLE`.`exposure_program_id` = `EXPOSURE_PROGRAM`.`exposure_program_id`))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`cameramodel_id`))
        LEFT JOIN `METERING_MODE` ON (`METERING_MODE_AVAILABLE`.`metering_mode_id` = `METERING_MODE`.`metering_mode_id`))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`))
        LEFT JOIN `FORMAT` ON (`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`))
        LEFT JOIN `MOUNT` ON (`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`))
        LEFT JOIN `LENSMODEL` ON (`LENSMODEL`.`lensmodel_id` = `CAMERAMODEL`.`lensmodel_id`))
    GROUP BY `CAMERAMODEL`.`cameramodel_id`;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `info_lensmodel` AS
    SELECT
        `LENSMODEL`.`lensmodel_id` AS `Lens Model ID`,
        `MOUNT`.`mount` AS `Mount`,
        IF(`LENSMODEL`.`zoom`,
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
        CONCAT(IFNULL(`LENSMODEL`.`introduced`, '?'),
                '-',
                IFNULL(`LENSMODEL`.`discontinued`, '?')) AS `Manufactured between`,
        `NEGATIVE_SIZE`.`negative_size` AS `Negative size`,
        `LENSMODEL`.`coating` AS `Coating`,
        `LENSMODEL`.`hood` AS `Hood`,
        `LENSMODEL`.`exif_lenstype` AS `EXIF LensType`,
        PRINTBOOL(`LENSMODEL`.`rectilinear`) AS `Rectilinear`,
        CONCAT(`LENSMODEL`.`length`,
                '×',
                `LENSMODEL`.`diameter`,
                'mm') AS `Dimensions (l×w)`,
        CONCAT(`LENSMODEL`.`image_circle`, 'mm') AS `Image circle`,
        `LENSMODEL`.`formula` AS `Optical formula`,
        `LENSMODEL`.`shutter_model` AS `Shutter model`
    FROM
        (((`LENSMODEL`
        LEFT JOIN `MOUNT` ON (`LENSMODEL`.`mount_id` = `MOUNT`.`mount_id`))
        LEFT JOIN `MANUFACTURER` ON (`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
        LEFT JOIN `NEGATIVE_SIZE` ON (`LENSMODEL`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))
    WHERE
        `LENSMODEL`.`fixed_mount` = 0
    GROUP BY `LENSMODEL`.`lensmodel_id`;
