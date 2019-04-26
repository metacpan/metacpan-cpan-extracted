/* Set right lens_id for all negatives taken with fixed-lens cameras */
DROP procedure IF EXISTS `update_lens_id_fixed_camera`;
CREATE PROCEDURE `update_lens_id_fixed_camera` ()
BEGIN
UPDATE NEGATIVE,
    LENS,
    CAMERA,
    FILM 
SET 
    NEGATIVE.lens_id = LENS.lens_id
WHERE
    NEGATIVE.film_id = FILM.film_id
        AND FILM.camera_id = CAMERA.camera_id
        AND CAMERA.fixed_mount = 1
        AND CAMERA.lens_id = LENS.lens_id;
END ;;


/* Update lens focal length per negative */
DROP procedure IF EXISTS `update_focal_length`;
CREATE PROCEDURE `update_focal_length` ()
BEGIN
UPDATE
    NEGATIVE left join TELECONVERTER on (NEGATIVE.teleconverter_id=TELECONVERTER.teleconverter_id),
    LENS
SET
    NEGATIVE.focal_length=round(LENS.min_focal_length * coalesce(TELECONVERTER.factor,1))
WHERE
   NEGATIVE.lens_id=LENS.lens_id
   and LENS.zoom = 0
   and LENS.min_focal_length is not null
   and NEGATIVE.focal_length is null;
END ;;


/* Update dates of fixed lenses */
DROP procedure IF EXISTS `update_dates_of_fixed_lenses`;
CREATE PROCEDURE `update_dates_of_fixed_lenses` ()
BEGIN
UPDATE
    LENS,
    CAMERA
SET
    LENS.acquired=CAMERA.acquired
WHERE
    LENS.lens_id = CAMERA.lens_id
        and CAMERA.fixed_mount = 1
        and CAMERA.acquired is not null
        and LENS.acquired!=CAMERA.acquired;
END ;;


/* Set metering mode for negatives taken with cameras with only one metering mode */
DROP procedure IF EXISTS `update_metering_modes`;
CREATE PROCEDURE `update_metering_modes` ()
BEGIN
UPDATE
    NEGATIVE,
    FILM,
    CAMERA,
    METERING_MODE_AVAILABLE,
    (SELECT
        CAMERA.camera_id
    FROM
        CAMERA, METERING_MODE_AVAILABLE
    where
        CAMERA.camera_id = METERING_MODE_AVAILABLE.camera_id
    group by camera_id
    having count(METERING_MODE_AVAILABLE.metering_mode_id) = 1
    ) as VALIDCAMERA
SET
    NEGATIVE.metering_mode = METERING_MODE_AVAILABLE.metering_mode_id
WHERE
    CAMERA.camera_id = METERING_MODE_AVAILABLE.camera_id
        and METERING_MODE_AVAILABLE.metering_mode_id <> 0
        and NEGATIVE.film_id=FILM.film_id
        and FILM.camera_id=CAMERA.camera_id
        and CAMERA.camera_id = VALIDCAMERA.camera_id
        and NEGATIVE.metering_mode is null;
END ;;


/* Set exposure program for negatives taken with cameras with only one exposure program */
DROP procedure IF EXISTS `update_exposure_programs`;
CREATE PROCEDURE `update_exposure_programs` ()
BEGIN
UPDATE
    NEGATIVE,
    FILM,
    CAMERA,
    EXPOSURE_PROGRAM_AVAILABLE,
    (SELECT
        CAMERA.camera_id
    FROM
        CAMERA, EXPOSURE_PROGRAM_AVAILABLE
    where
        CAMERA.camera_id = EXPOSURE_PROGRAM_AVAILABLE.camera_id
    group by camera_id
    having count(exposure_program_id) = 1
    ) as VALIDCAMERA
    set
        NEGATIVE.exposure_program = EXPOSURE_PROGRAM_AVAILABLE.exposure_program_id
    where
        CAMERA.camera_id = EXPOSURE_PROGRAM_AVAILABLE.camera_id
            and EXPOSURE_PROGRAM_AVAILABLE.exposure_program_id <> 0
            and NEGATIVE.film_id=FILM.film_id
            and FILM.camera_id=CAMERA.camera_id
            and CAMERA.camera_id = VALIDCAMERA.camera_id
            and NEGATIVE.exposure_program is null;
END ;;


/* Set fixed lenses as lost when their camera is lost */
DROP procedure IF EXISTS `set_fixed_lenses`;
CREATE PROCEDURE `set_fixed_lenses` ()
BEGIN
UPDATE
    LENS,
    CAMERA
SET
    LENS.own=0,
    LENS.lost=CAMERA.lost
WHERE
    LENS.lens_id=CAMERA.lens_id
        and CAMERA.own=0
        and CAMERA.fixed_mount=1;
END ;;


/* Set crop factor, area, and aspect ratio for negative sizes that lack it */
DROP procedure IF EXISTS `update_negative_sizes`;
CREATE PROCEDURE `update_negative_sizes` ()
BEGIN
UPDATE
    NEGATIVE_SIZE
SET
    crop_factor = round(sqrt(24*24 + 36*36)/sqrt(width*width + height*height),2),
    area = width*height,
    aspect_ratio = round(width/height, 2)
WHERE
    width is not null
        and height is not null;
END ;;


/* Set no flash for negatives taken with cameras that don't support flash */
DROP procedure IF EXISTS `update_negative_flash`;
CREATE PROCEDURE `update_negative_flash` ()
BEGIN
UPDATE
    CAMERA
    join FILM on FILM.camera_id=CAMERA.camera_id
    join NEGATIVE on NEGATIVE.film_id = FILM.film_id
SET
    NEGATIVE.flash = 0
WHERE
    int_flash=0
    and ext_flash=0
    and NEGATIVE.flash is null;
END ;;


/* Delete log entries older than 90 days */
DROP procedure IF EXISTS `delete_logs`;
CREATE PROCEDURE `delete_logs` ()
BEGIN
DELETE from LOG
WHERE datetime < date_sub(now(), interval 90 day);
END ;;
