CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_camera` AS
    SELECT 
        `CAMERA`.`camera_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`,
                IF(`CAMERA`.`serial`,
                    CONCAT(' (#', `CAMERA`.`serial`, ')'),
                    '')) AS `opt`,
        `CAMERAMODEL`.`mount_id` AS `mount_id`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `MANUFACTURER` ON (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        `CAMERA`.`own` = 1
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`) COLLATE utf8mb4_general_ci;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_lens` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`,
                IF(`LENS`.`serial`,
                    CONCAT(' (#', `LENS`.`serial`, ')'),
                    '')) AS `opt`
    FROM
        ((`LENS`
        JOIN `LENSMODEL` ON (`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`))
        JOIN `MANUFACTURER` ON (`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        `LENS`.`own` = 1
            AND `LENSMODEL`.`fixed_mount` = 0
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `LENSMODEL`.`model`);
