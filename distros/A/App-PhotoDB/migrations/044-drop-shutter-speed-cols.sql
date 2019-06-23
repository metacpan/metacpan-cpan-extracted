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
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        LEFT JOIN `MANUFACTURER` ON (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
        LEFT JOIN `EXPOSURE_PROGRAM_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`))
        LEFT JOIN `METERING_MODE_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `METERING_MODE_AVAILABLE`.`cameramodel_id`))
        LEFT JOIN `SHUTTER_SPEED_AVAILABLE` ON (`CAMERAMODEL`.`cameramodel_id` = `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`))
    WHERE
        `CAMERA`.`own` = 1
    GROUP BY `CAMERA`.`camera_id`
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);


ALTER TABLE `CAMERAMODEL` 
DROP COLUMN `max_shutter`,
DROP COLUMN `min_shutter`,
DROP INDEX `fk_CAMERA_2_idx` ,
DROP INDEX `fk_CAMERA_1_idx` ;
