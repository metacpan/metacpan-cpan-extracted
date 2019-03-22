package App::PhotoDB::queries;

# This package contains reusable SQL queries as single variables
# This keeps the rest of the project clean

use strict;
use warnings;

our @tasks = (
	{
		desc => 'Set right lens_id for all negatives taken with fixed-lens cameras',
		query => 'update
			NEGATIVE,
			LENS,
			CAMERA,
			FILM
		set
			NEGATIVE.lens_id=LENS.lens_id
		where
			NEGATIVE.film_id=FILM.film_id
			and FILM.camera_id=CAMERA.camera_id
			and CAMERA.fixed_mount=1
			and CAMERA.lens_id=LENS.lens_id'
	},
	{
		desc => 'Update lens focal length per negative',
		query => 'update
			NEGATIVE left join TELECONVERTER on(NEGATIVE.teleconverter_id=TELECONVERTER.teleconverter_id),
			LENS
		set
			NEGATIVE.focal_length=round(LENS.min_focal_length * coalesce(TELECONVERTER.factor,1))
		where
			NEGATIVE.lens_id=LENS.lens_id
			and LENS.zoom = 0
			and LENS.min_focal_length is not null
			and NEGATIVE.focal_length is null'
	},
	{
		desc => 'Update dates of fixed lenses',
		query => 'update
			LENS,
			CAMERA
		set
			LENS.acquired=CAMERA.acquired
		where
			LENS.lens_id = CAMERA.lens_id
			and CAMERA.fixed_mount = 1
			and CAMERA.acquired is not null
			and LENS.acquired!=CAMERA.acquired'
	},
	{
		desc => 'Set metering mode for negatives taken with cameras with only one metering mode',
		query => 'UPDATE
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
		set
			NEGATIVE.metering_mode = METERING_MODE_AVAILABLE.metering_mode_id
		where
			CAMERA.camera_id = METERING_MODE_AVAILABLE.camera_id
			and METERING_MODE_AVAILABLE.metering_mode_id <> 0
			and NEGATIVE.film_id=FILM.film_id
			and FILM.camera_id=CAMERA.camera_id
			and CAMERA.camera_id = VALIDCAMERA.camera_id
			and NEGATIVE.metering_mode is null'
	},
	{
		desc => 'Set exposure program for negatives taken with cameras with only one exposure program',
		query => 'UPDATE
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
			and NEGATIVE.exposure_program is null'
	},
	{
		desc => 'Set fixed lenses as lost when their camera is lost',
		query => 'update
			LENS,
			CAMERA
		set
			LENS.own=0,
			LENS.lost=CAMERA.lost
		where
			LENS.lens_id=CAMERA.lens_id
			and CAMERA.own=0
			and CAMERA.fixed_mount=1'
	},
	{
		desc => 'Set crop factor, area, and aspect ratio for negative sizes that lack it',
		query => 'update
			NEGATIVE_SIZE
		set
			crop_factor = round(sqrt(24*24 + 36*36)/sqrt(width*width + height*height),2),
			area = width*height,
			aspect_ratio = round(width/height, 2)
		where
			width is not null
			and height is not null'
	},
	{
		desc => 'Set no flash for negatives taken with cameras that don\'t support flash',
		query => 'UPDATE
			CAMERA
			join FILM on FILM.camera_id=CAMERA.camera_id
			join NEGATIVE on NEGATIVE.film_id = FILM.film_id
		SET
			NEGATIVE.flash = 0
		WHERE
			int_flash=0
			and ext_flash=0
			and NEGATIVE.flash is null'
	},
);

our @reports = (
	{
		desc => 'Report on how many cameras in the collection are from each decade',
		view => 'report_cameras_by_decade',
	},
	{
		desc => 'Report on which lenses have been used to take most frames',
		view => 'report_most_popular_lenses_relative',
	},
	{
		desc => 'Report on cameras that have never been to used to take a frame',
		view => 'report_never_used_cameras',
	},
	{
		desc => 'Report on lenses that have never been used to take a frame',
		view => 'report_never_used_lenses',
	},
	{
		desc => 'Report on the cameras that have taken most frames',
		view => 'report_total_negatives_per_camera',
	},
	{
		desc => 'Report on the lenses that have taken most frames',
		view => 'report_total_negatives_per_lens',
	},
	{
		desc => 'Report on negatives that have not been scanned',
		view => 'report_unscanned_negs',
	}
);

# This ensures the lib loads smoothly
1;
