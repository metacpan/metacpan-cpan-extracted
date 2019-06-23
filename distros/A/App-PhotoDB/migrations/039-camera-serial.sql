CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `cameralens_compat` AS
    SELECT 
        `CAMERA`.`camera_id` AS `camera_id`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`,
                IF(`CAMERA`.`serial`,
                    CONCAT(' (#', `CAMERA`.`serial`, ')'),
                    '')) AS `camera`,
        `LENS`.`lens_id` AS `lens_id`,
        CONCAT(`LM`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`,
                IF(`LENS`.`serial`,
                    CONCAT(' (#', `LENS`.`serial`, ')'),
                    '')) AS `lens`,
        `MOUNT`.`mount_id` AS `mount_id`
    FROM
        ((((((`CAMERA`
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `MOUNT` ON (`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`))
        JOIN `LENSMODEL` ON (`MOUNT`.`mount_id` = `LENSMODEL`.`mount_id`))
        JOIN `LENS` ON (`LENSMODEL`.`lensmodel_id` = `LENS`.`lensmodel_id`))
        JOIN `MANUFACTURER` `CM` ON (`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`))
        JOIN `MANUFACTURER` `LM` ON (`LENSMODEL`.`manufacturer_id` = `LM`.`manufacturer_id`))
    WHERE
        `CAMERA`.`own` = 1 AND `LENS`.`own` = 1;


CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_display_lens` AS
    SELECT 
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`,
                IF(`LENS`.`serial`,
                    CONCAT(' (#', `LENS`.`serial`, ')'),
                    '')) AS `opt`,
        `CAMERA`.`camera_id` AS `camera_id`,
        `LENSMODEL`.`mount_id` AS `mount_id`
    FROM
        (((`LENS`
        JOIN `LENSMODEL` ON (`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`))
        LEFT JOIN `CAMERA` ON (`LENS`.`lens_id` = `CAMERA`.`display_lens`))
        JOIN `MANUFACTURER` ON (`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        `LENSMODEL`.`mount_id` IS NOT NULL
            AND `LENS`.`own` = 1
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `LENSMODEL`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_camera_by_film` AS
    SELECT
        `C`.`camera_id` AS `id`,
        CONCAT(`M`.`manufacturer`,
                ' ',
                `CM`.`model`,
                IF(`C`.`serial`,
                    CONCAT(' (#', `C`.`serial`, ')'),
                    '')) AS `opt`,
        `F`.`film_id` AS `film_id`
    FROM
        (((`CAMERA` `C`
        JOIN `CAMERAMODEL` `CM` ON (`C`.`cameramodel_id` = `CM`.`cameramodel_id`))
        JOIN `FILM` `F` ON (`F`.`format_id` = `CM`.`format_id`))
        JOIN `MANUFACTURER` `M` ON (`CM`.`manufacturer_id` = `M`.`manufacturer_id`))
    WHERE
        `C`.`own` = 1
    ORDER BY CONCAT(`M`.`manufacturer`, ' ', `CM`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_lens_by_film` AS
    SELECT
        `LENS`.`lens_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`,
                IF(`LENS`.`serial`,
                    CONCAT(' (#', `LENS`.`serial`, ')'),
                    '')) AS `opt`,
        `FILM`.`film_id` AS `film_id`
    FROM
        (((((`FILM`
        JOIN `CAMERA` ON (`FILM`.`camera_id` = `CAMERA`.`camera_id`))
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `LENSMODEL` ON (`CAMERAMODEL`.`mount_id` = `LENSMODEL`.`mount_id`))
        JOIN `MANUFACTURER` ON (`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
        JOIN `LENS` ON (`LENSMODEL`.`lensmodel_id` = `LENS`.`lensmodel_id`));
