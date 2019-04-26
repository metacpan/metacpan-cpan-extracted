SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `archive_contents` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `archive_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `archive_contents`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `archive_contents` AS select concat('Film #',`FILM`.`film_id`) AS `id`,(`FILM`.`notes` collate utf8mb4_unicode_ci) AS `opt`,`FILM`.`archive_id` AS `archive_id` from `FILM` union select concat('Print #',`PRINT`.`print_id`) AS `id`,`NEGATIVE`.`description` AS `opt`,`PRINT`.`archive_id` AS `archive_id` from (`PRINT` join `NEGATIVE`) where (`PRINT`.`negative_id` = `NEGATIVE`.`negative_id`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `camera_chooser` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `manufacturer_id` tinyint NOT NULL,
  `mount_id` tinyint NOT NULL,
  `format_id` tinyint NOT NULL,
  `focus_type_id` tinyint NOT NULL,
  `metering` tinyint NOT NULL,
  `coupled_metering` tinyint NOT NULL,
  `metering_type_id` tinyint NOT NULL,
  `body_type_id` tinyint NOT NULL,
  `weight` tinyint NOT NULL,
  `manufactured` tinyint NOT NULL,
  `negative_size_id` tinyint NOT NULL,
  `shutter_type_id` tinyint NOT NULL,
  `shutter_model` tinyint NOT NULL,
  `cable_release` tinyint NOT NULL,
  `power_drive` tinyint NOT NULL,
  `continuous_fps` tinyint NOT NULL,
  `video` tinyint NOT NULL,
  `digital` tinyint NOT NULL,
  `fixed_mount` tinyint NOT NULL,
  `lens_id` tinyint NOT NULL,
  `battery_qty` tinyint NOT NULL,
  `battery_type` tinyint NOT NULL,
  `min_shutter` tinyint NOT NULL,
  `max_shutter` tinyint NOT NULL,
  `bulb` tinyint NOT NULL,
  `time` tinyint NOT NULL,
  `min_iso` tinyint NOT NULL,
  `max_iso` tinyint NOT NULL,
  `af_points` tinyint NOT NULL,
  `int_flash` tinyint NOT NULL,
  `int_flash_gn` tinyint NOT NULL,
  `ext_flash` tinyint NOT NULL,
  `flash_metering` tinyint NOT NULL,
  `pc_sync` tinyint NOT NULL,
  `hotshoe` tinyint NOT NULL,
  `coldshoe` tinyint NOT NULL,
  `x_sync` tinyint NOT NULL,
  `meter_min_ev` tinyint NOT NULL,
  `meter_max_ev` tinyint NOT NULL,
  `dof_preview` tinyint NOT NULL,
  `tripod` tinyint NOT NULL,
  `display_lens` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `camera_chooser`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `camera_chooser` AS select `CAMERA`.`camera_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `opt`,`CAMERA`.`manufacturer_id` AS `manufacturer_id`,`CAMERA`.`mount_id` AS `mount_id`,`CAMERA`.`format_id` AS `format_id`,`CAMERA`.`focus_type_id` AS `focus_type_id`,`CAMERA`.`metering` AS `metering`,`CAMERA`.`coupled_metering` AS `coupled_metering`,`CAMERA`.`metering_type_id` AS `metering_type_id`,`CAMERA`.`body_type_id` AS `body_type_id`,`CAMERA`.`weight` AS `weight`,`CAMERA`.`manufactured` AS `manufactured`,`CAMERA`.`negative_size_id` AS `negative_size_id`,`CAMERA`.`shutter_type_id` AS `shutter_type_id`,`CAMERA`.`shutter_model` AS `shutter_model`,`CAMERA`.`cable_release` AS `cable_release`,`CAMERA`.`power_drive` AS `power_drive`,`CAMERA`.`continuous_fps` AS `continuous_fps`,`CAMERA`.`video` AS `video`,`CAMERA`.`digital` AS `digital`,`CAMERA`.`fixed_mount` AS `fixed_mount`,`CAMERA`.`lens_id` AS `lens_id`,`CAMERA`.`battery_qty` AS `battery_qty`,`CAMERA`.`battery_type` AS `battery_type`,`CAMERA`.`min_shutter` AS `min_shutter`,`CAMERA`.`max_shutter` AS `max_shutter`,`CAMERA`.`bulb` AS `bulb`,`CAMERA`.`time` AS `time`,`CAMERA`.`min_iso` AS `min_iso`,`CAMERA`.`max_iso` AS `max_iso`,`CAMERA`.`af_points` AS `af_points`,`CAMERA`.`int_flash` AS `int_flash`,`CAMERA`.`int_flash_gn` AS `int_flash_gn`,`CAMERA`.`ext_flash` AS `ext_flash`,`CAMERA`.`flash_metering` AS `flash_metering`,`CAMERA`.`pc_sync` AS `pc_sync`,`CAMERA`.`hotshoe` AS `hotshoe`,`CAMERA`.`coldshoe` AS `coldshoe`,`CAMERA`.`x_sync` AS `x_sync`,`CAMERA`.`meter_min_ev` AS `meter_min_ev`,`CAMERA`.`meter_max_ev` AS `meter_max_ev`,`CAMERA`.`dof_preview` AS `dof_preview`,`CAMERA`.`tripod` AS `tripod`,`CAMERA`.`display_lens` AS `display_lens` from ((((`CAMERA` left join `MANUFACTURER` on((`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) left join `EXPOSURE_PROGRAM_AVAILABLE` on((`CAMERA`.`camera_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`camera_id`))) left join `METERING_MODE_AVAILABLE` on((`CAMERA`.`camera_id` = `METERING_MODE_AVAILABLE`.`camera_id`))) left join `SHUTTER_SPEED_AVAILABLE` on((`CAMERA`.`camera_id` = `SHUTTER_SPEED_AVAILABLE`.`camera_id`))) where (`CAMERA`.`own` = 1) group by `CAMERA`.`camera_id` order by concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cameralens_compat` (
  `camera_id` tinyint NOT NULL,
  `camera` tinyint NOT NULL,
  `lens_id` tinyint NOT NULL,
  `lens` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `cameralens_compat`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `cameralens_compat` AS select `CAMERA`.`camera_id` AS `camera_id`,concat(`CM`.`manufacturer`,' ',`CAMERA`.`model`) AS `camera`,`LENS`.`lens_id` AS `lens_id`,concat(`LM`.`manufacturer`,' ',`LENS`.`model`) AS `lens` from ((((`CAMERA` join `MOUNT` on((`CAMERA`.`mount_id` = `MOUNT`.`mount_id`))) join `LENS` on((`MOUNT`.`mount_id` = `LENS`.`mount_id`))) join `MANUFACTURER` `CM` on((`CAMERA`.`manufacturer_id` = `CM`.`manufacturer_id`))) join `MANUFACTURER` `LM` on((`LENS`.`manufacturer_id` = `LM`.`manufacturer_id`))) where ((`CAMERA`.`own` = 1) and (`LENS`.`own` = 1));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_accessory_compat` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `camera_id` tinyint NOT NULL,
  `lens_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_accessory_compat`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_accessory_compat` AS select `ACCESSORY`.`accessory_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`ACCESSORY`.`model`,' (',`ACCESSORY_TYPE`.`accessory_type`,')') AS `opt`,`ACCESSORY_COMPAT`.`camera_id` AS `camera_id`,`ACCESSORY_COMPAT`.`lens_id` AS `lens_id` from (((`ACCESSORY` join `ACCESSORY_COMPAT` on((`ACCESSORY_COMPAT`.`accessory_id` = `ACCESSORY`.`accessory_id`))) join `ACCESSORY_TYPE` on((`ACCESSORY`.`accessory_type_id` = `ACCESSORY_TYPE`.`accessory_type_id`))) left join `MANUFACTURER` on((`ACCESSORY`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_accessory` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_accessory`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_accessory` AS select `ACCESSORY`.`accessory_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`ACCESSORY`.`model`,' (',`ACCESSORY_TYPE`.`accessory_type`,')') AS `opt` from ((`ACCESSORY` join `MANUFACTURER`) join `ACCESSORY_TYPE`) where ((`ACCESSORY`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and (`ACCESSORY`.`accessory_type_id` = `ACCESSORY_TYPE`.`accessory_type_id`) and isnull(`ACCESSORY`.`lost`));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_battery` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_battery`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_battery` AS select `BATTERY`.`battery_type` AS `id`,concat(`BATTERY`.`battery_name`,ifnull(concat(' (',`BATTERY`.`voltage`,'V)'),'')) AS `opt` from `BATTERY`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_bulk_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_bulk_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_bulk_film` AS select `FILM_BULK`.`film_bulk_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,if(`FILM_BULK`.`batch`,concat(' (',`FILM_BULK`.`batch`,')'),'')) AS `opt` from ((`FILM_BULK` join `FILMSTOCK` on((`FILM_BULK`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`))) join `MANUFACTURER` on((`FILMSTOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_camera_by_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `film_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_camera_by_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_camera_by_film` AS select `C`.`camera_id` AS `id`,concat(`M`.`manufacturer`,' ',`C`.`model`) AS `opt`,`F`.`film_id` AS `film_id` from ((`CAMERA` `C` join `FILM` `F`) join `MANUFACTURER` `M`) where ((`F`.`format_id` = `C`.`format_id`) and (`C`.`manufacturer_id` = `M`.`manufacturer_id`) and (`C`.`own` = 1)) order by concat(`M`.`manufacturer`,' ',`C`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_camera` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `mount_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_camera`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_camera` AS select `CAMERA`.`camera_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `opt`,`CAMERA`.`mount_id` AS `mount_id` from (`CAMERA` join `MANUFACTURER`) where ((`CAMERA`.`own` = 1) and (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_camera_without_exposure_programs` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_camera_without_exposure_programs`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_camera_without_exposure_programs` AS select `CAMERA`.`camera_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `opt` from (`CAMERA` join `MANUFACTURER`) where ((not(`CAMERA`.`camera_id` in (select `EXPOSURE_PROGRAM_AVAILABLE`.`camera_id` from `EXPOSURE_PROGRAM_AVAILABLE`))) and (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and (`CAMERA`.`own` = 1) and (`MANUFACTURER`.`manufacturer_id` <> 20)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_camera_without_metering_data` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_camera_without_metering_data`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_camera_without_metering_data` AS select `CAMERA`.`camera_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `opt` from (`CAMERA` join `MANUFACTURER`) where ((not(`CAMERA`.`camera_id` in (select `METERING_MODE_AVAILABLE`.`camera_id` from `METERING_MODE_AVAILABLE`))) and (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and (`CAMERA`.`own` = 1) and (`MANUFACTURER`.`manufacturer_id` <> 20)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_camera_without_shutter_data` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_camera_without_shutter_data`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_camera_without_shutter_data` AS select `CAMERA`.`camera_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `opt` from (`CAMERA` join `MANUFACTURER`) where ((not(`CAMERA`.`camera_id` in (select `SHUTTER_SPEED_AVAILABLE`.`camera_id` from `SHUTTER_SPEED_AVAILABLE`))) and (`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and (`CAMERA`.`own` = 1) and (`MANUFACTURER`.`manufacturer_id` <> 20)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_display_lens` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `camera_id` tinyint NOT NULL,
  `mount_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_display_lens`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_display_lens` AS select `LENS`.`lens_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `opt`,`CAMERA`.`camera_id` AS `camera_id`,`LENS`.`mount_id` AS `mount_id` from ((`LENS` left join `CAMERA` on((`LENS`.`lens_id` = `CAMERA`.`display_lens`))) join `MANUFACTURER` on((`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) where ((`LENS`.`mount_id` is not null) and (`LENS`.`own` = 1)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_enlarger_lens` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_enlarger_lens`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_enlarger_lens` AS select `LENS`.`lens_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `opt` from ((`LENS` join `MOUNT`) join `MANUFACTURER`) where ((`LENS`.`mount_id` = `MOUNT`.`mount_id`) and (`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and (`MOUNT`.`purpose` = 'Enlarger') and (`LENS`.`own` = 1));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_enlarger` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_enlarger`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_enlarger` AS select `ENLARGER`.`enlarger_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`ENLARGER`.`enlarger`) AS `opt` from (`ENLARGER` join `MANUFACTURER`) where ((`ENLARGER`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) and isnull(`ENLARGER`.`lost`));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_filmstock` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_filmstock`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_filmstock` AS select `FILMSTOCK`.`filmstock_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`) AS `opt` from (`FILMSTOCK` join `MANUFACTURER`) where (`FILMSTOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) order by concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_film_to_develop` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_film_to_develop`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_film_to_develop` AS select `FILM`.`film_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,' (',`FORMAT`.`format`,' format, ',if(`FILMSTOCK`.`colour`,'colour','B&W'),')') AS `opt` from (((`FILM` join `FILMSTOCK`) join `FORMAT`) join `MANUFACTURER`) where ((`FILM`.`camera_id` is not null) and isnull(`FILM`.`date`) and (`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`) and (`FILM`.`format_id` = `FORMAT`.`format_id`) and (`FILMSTOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)) order by `FILM`.`film_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_film_to_load` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_film_to_load`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_film_to_load` AS select `FILM`.`film_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,' (',`FORMAT`.`format`,' format, ',if(`FILMSTOCK`.`colour`,'colour','B&W'),')') AS `opt` from (((`FILM` join `FILMSTOCK`) join `FORMAT`) join `MANUFACTURER`) where (isnull(`FILM`.`camera_id`) and isnull(`FILM`.`date`) and (`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`) and (`FILM`.`format_id` = `FORMAT`.`format_id`) and (`FILMSTOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_filter` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `thread` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_filter`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_filter` AS select `FILTER`.`filter_id` AS `id`,concat(`FILTER`.`type`,' (',`FILTER`.`thread`,'mm)') AS `opt`,`FILTER`.`thread` AS `thread` from `FILTER` order by concat(`FILTER`.`type`,' (',`FILTER`.`thread`,'mm)');
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_flash_protocol` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_flash_protocol`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_flash_protocol` AS select `FLASH_PROTOCOL`.`flash_protocol_id` AS `id`,if((isnull(`MANUFACTURER`.`manufacturer_id`) or (`MANUFACTURER`.`manufacturer` = 'Unknown')),`FLASH_PROTOCOL`.`name`,concat(`MANUFACTURER`.`manufacturer`,' ',`FLASH_PROTOCOL`.`name`)) AS `opt` from (`FLASH_PROTOCOL` left join `MANUFACTURER` on((`MANUFACTURER`.`manufacturer_id` = `FLASH_PROTOCOL`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_lens_by_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `film_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_lens_by_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_lens_by_film` AS select `LENS`.`lens_id` AS `id`,`LENS`.`model` AS `opt`,`FILM`.`film_id` AS `film_id` from ((`FILM` join `CAMERA` on((`FILM`.`camera_id` = `CAMERA`.`camera_id`))) join `LENS` on((`CAMERA`.`mount_id` = `LENS`.`mount_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_lens` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_lens`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_lens` AS select `LENS`.`lens_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `opt` from (`LENS` join `MANUFACTURER`) where ((`LENS`.`own` = 1) and (`LENS`.`fixed_mount` = 0) and (`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)) order by concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_mount_adapter_by_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `film_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_mount_adapter_by_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_mount_adapter_by_film` AS select `MA`.`mount_adapter_id` AS `id`,`M`.`mount` AS `opt`,`F`.`film_id` AS `film_id` from (((`MOUNT_ADAPTER` `MA` join `CAMERA` `C` on((`C`.`mount_id` = `MA`.`camera_mount`))) join `FILM` `F` on((`F`.`camera_id` = `C`.`camera_id`))) join `MOUNT` `M` on((`M`.`mount_id` = `MA`.`lens_mount`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_mount` (
  `mount_id` tinyint NOT NULL,
  `mount` tinyint NOT NULL,
  `purpose` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_mount`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_mount` AS select `MOUNT`.`mount_id` AS `mount_id`,ifnull(concat(`MANUFACTURER`.`manufacturer`,' ',`MOUNT`.`mount`),`MOUNT`.`mount`) AS `mount`,`MOUNT`.`purpose` AS `purpose` from (`MOUNT` left join `MANUFACTURER` on((`MOUNT`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) order by ifnull(concat(`MANUFACTURER`.`manufacturer`,' ',`MOUNT`.`mount`),`MOUNT`.`mount`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_movie_camera` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_movie_camera`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_movie_camera` AS select `C`.`camera_id` AS `id`,concat(`M`.`manufacturer`,' ',`C`.`model`) AS `opt` from (`CAMERA` `C` join `MANUFACTURER` `M`) where ((`C`.`manufacturer_id` = `M`.`manufacturer_id`) and (`C`.`own` = 1) and (`C`.`video` = 1) and (`C`.`digital` = 0)) order by concat(`M`.`manufacturer`,' ',`C`.`model`);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_paper` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_paper`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_paper` AS select `PAPER_STOCK`.`paper_stock_id` AS `id`,concat(`MANUFACTURER`.`manufacturer`,' ',`PAPER_STOCK`.`name`,ifnull(concat(' (',`PAPER_STOCK`.`finish`,')'),'')) AS `opt` from (`PAPER_STOCK` join `MANUFACTURER`) where (`PAPER_STOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`) order by concat(`MANUFACTURER`.`manufacturer`,' ',`PAPER_STOCK`.`name`,ifnull(concat(' (',`PAPER_STOCK`.`finish`,')'),''));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_scan` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `filename` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_scan`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_scan` AS select `SCAN`.`scan_id` AS `id`,ifnull(concat('Negative ',`NEGATIVE`.`film_id`,'/',`NEGATIVE`.`frame`,ifnull(concat(' ',`NEGATIVE`.`description`),'')),concat('Print #',`PRINT`.`print_id`,' ',`PRINTNEG`.`description`)) AS `opt`,`SCAN`.`filename` AS `filename` from (((`SCAN` left join `NEGATIVE` on((`SCAN`.`negative_id` = `NEGATIVE`.`negative_id`))) left join `PRINT` on((`SCAN`.`print_id` = `PRINT`.`print_id`))) left join `NEGATIVE` `PRINTNEG` on((`PRINT`.`negative_id` = `PRINTNEG`.`negative_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_shutter_speed_by_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `film_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_shutter_speed_by_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_shutter_speed_by_film` AS select `SHUTTER_SPEED`.`shutter_speed` AS `id`,'' AS `opt`,`FILM`.`film_id` AS `film_id` from (((`FILM` join `CAMERA` on((`FILM`.`camera_id` = `CAMERA`.`camera_id`))) join `SHUTTER_SPEED_AVAILABLE` on((`CAMERA`.`camera_id` = `SHUTTER_SPEED_AVAILABLE`.`camera_id`))) join `SHUTTER_SPEED` on((`SHUTTER_SPEED_AVAILABLE`.`shutter_speed` = `SHUTTER_SPEED`.`shutter_speed`))) order by `SHUTTER_SPEED`.`duration`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_teleconverter_by_film` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `film_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_teleconverter_by_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_teleconverter_by_film` AS select `T`.`teleconverter_id` AS `id`,concat(`M`.`manufacturer`,' ',`T`.`model`,' (',`T`.`factor`,'x)') AS `opt`,`F`.`film_id` AS `film_id` from (((`TELECONVERTER` `T` join `CAMERA` `C` on((`C`.`mount_id` = `T`.`mount_id`))) join `FILM` `F` on((`F`.`camera_id` = `C`.`camera_id`))) join `MANUFACTURER` `M` on((`M`.`manufacturer_id` = `T`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `choose_todo` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `choose_todo`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `choose_todo` AS select `TO_PRINT`.`id` AS `id`,concat(`NEGATIVE`.`film_id`,'/',`NEGATIVE`.`frame`,' ',`NEGATIVE`.`description`,' as ',ifnull(`TO_PRINT`.`width`,'?'),'x',ifnull(`TO_PRINT`.`height`,'?'),'"',if((`TO_PRINT`.`recipient` <> ''),concat(' for ',`TO_PRINT`.`recipient`),'')) AS `opt` from (`TO_PRINT` join `NEGATIVE`) where ((`TO_PRINT`.`negative_id` = `NEGATIVE`.`negative_id`) and (`TO_PRINT`.`printed` = 0)) order by `NEGATIVE`.`film_id`,`NEGATIVE`.`frame`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `current_films` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `current_films`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `current_films` AS select `FILM`.`film_id` AS `id`,concat(`FM`.`manufacturer`,' ',`FILMSTOCK`.`name`,ifnull(concat(' loaded into ',`CM`.`manufacturer`,' ',`CAMERA`.`model`),''),ifnull(concat(' on ',`FILM`.`date_loaded`),''),', ',count(`NEGATIVE`.`film_id`),ifnull(concat('/',`FILM`.`frames`),''),' frames registered') AS `opt` from (((((`FILM` join `CAMERA` on((`FILM`.`camera_id` = `CAMERA`.`camera_id`))) join `MANUFACTURER` `CM` on((`CAMERA`.`manufacturer_id` = `CM`.`manufacturer_id`))) join `FILMSTOCK` on((`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`))) join `MANUFACTURER` `FM` on((`FILMSTOCK`.`manufacturer_id` = `FM`.`manufacturer_id`))) left join `NEGATIVE` on((`FILM`.`film_id` = `NEGATIVE`.`film_id`))) where isnull(`FILM`.`date`) group by `FILM`.`film_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `exhibits` (
  `id` tinyint NOT NULL,
  `opt` tinyint NOT NULL,
  `exhibition_id` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `exhibits`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `exhibits` AS select `PRINT`.`print_id` AS `id`,concat(`NEGATIVE`.`description`,' (',`DISPLAYSIZE`(`PRINT`.`width`,`PRINT`.`height`),')') AS `opt`,`EXHIBIT`.`exhibition_id` AS `exhibition_id` from (((`NEGATIVE` join `PRINT` on((`PRINT`.`negative_id` = `NEGATIVE`.`negative_id`))) join `EXHIBIT` on((`EXHIBIT`.`print_id` = `PRINT`.`print_id`))) join `EXHIBITION` on((`EXHIBITION`.`exhibition_id` = `EXHIBIT`.`exhibition_id`))) order by `PRINT`.`print_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `scans_negs` (
  `scan_id` tinyint NOT NULL,
  `directory` tinyint NOT NULL,
  `filename` tinyint NOT NULL,
  `negative_id` tinyint NOT NULL,
  `film_id` tinyint NOT NULL,
  `frame` tinyint NOT NULL,
  `description` tinyint NOT NULL,
  `date` tinyint NOT NULL,
  `lens_id` tinyint NOT NULL,
  `shutter_speed` tinyint NOT NULL,
  `aperture` tinyint NOT NULL,
  `filter_id` tinyint NOT NULL,
  `teleconverter_id` tinyint NOT NULL,
  `notes` tinyint NOT NULL,
  `mount_adapter_id` tinyint NOT NULL,
  `focal_length` tinyint NOT NULL,
  `latitude` tinyint NOT NULL,
  `longitude` tinyint NOT NULL,
  `flash` tinyint NOT NULL,
  `metering_mode` tinyint NOT NULL,
  `exposure_program` tinyint NOT NULL,
  `photographer_id` tinyint NOT NULL,
  `copy_of` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `scans_negs`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `scans_negs` AS select `SCAN`.`scan_id` AS `scan_id`,`FILM`.`directory` AS `directory`,`SCAN`.`filename` AS `filename`,`NEGATIVE`.`negative_id` AS `negative_id`,`NEGATIVE`.`film_id` AS `film_id`,`NEGATIVE`.`frame` AS `frame`,`NEGATIVE`.`description` AS `description`,`NEGATIVE`.`date` AS `date`,`NEGATIVE`.`lens_id` AS `lens_id`,`NEGATIVE`.`shutter_speed` AS `shutter_speed`,`NEGATIVE`.`aperture` AS `aperture`,`NEGATIVE`.`filter_id` AS `filter_id`,`NEGATIVE`.`teleconverter_id` AS `teleconverter_id`,`NEGATIVE`.`notes` AS `notes`,`NEGATIVE`.`mount_adapter_id` AS `mount_adapter_id`,`NEGATIVE`.`focal_length` AS `focal_length`,`NEGATIVE`.`latitude` AS `latitude`,`NEGATIVE`.`longitude` AS `longitude`,`NEGATIVE`.`flash` AS `flash`,`NEGATIVE`.`metering_mode` AS `metering_mode`,`NEGATIVE`.`exposure_program` AS `exposure_program`,`NEGATIVE`.`photographer_id` AS `photographer_id`,`NEGATIVE`.`copy_of` AS `copy_of` from (((`SCAN` join `PRINT` on((`SCAN`.`print_id` = `PRINT`.`print_id`))) join `NEGATIVE` on((`PRINT`.`negative_id` = `NEGATIVE`.`negative_id`))) join `FILM` on((`NEGATIVE`.`film_id` = `FILM`.`film_id`))) union all select `SCAN`.`scan_id` AS `scan_id`,`FILM`.`directory` AS `directory`,`SCAN`.`filename` AS `filename`,`NEGATIVE`.`negative_id` AS `negative_id`,`NEGATIVE`.`film_id` AS `film_id`,`NEGATIVE`.`frame` AS `frame`,`NEGATIVE`.`description` AS `description`,`NEGATIVE`.`date` AS `date`,`NEGATIVE`.`lens_id` AS `lens_id`,`NEGATIVE`.`shutter_speed` AS `shutter_speed`,`NEGATIVE`.`aperture` AS `aperture`,`NEGATIVE`.`filter_id` AS `filter_id`,`NEGATIVE`.`teleconverter_id` AS `teleconverter_id`,`NEGATIVE`.`notes` AS `notes`,`NEGATIVE`.`mount_adapter_id` AS `mount_adapter_id`,`NEGATIVE`.`focal_length` AS `focal_length`,`NEGATIVE`.`latitude` AS `latitude`,`NEGATIVE`.`longitude` AS `longitude`,`NEGATIVE`.`flash` AS `flash`,`NEGATIVE`.`metering_mode` AS `metering_mode`,`NEGATIVE`.`exposure_program` AS `exposure_program`,`NEGATIVE`.`photographer_id` AS `photographer_id`,`NEGATIVE`.`copy_of` AS `copy_of` from ((`SCAN` join `NEGATIVE` on((`SCAN`.`negative_id` = `NEGATIVE`.`negative_id`))) join `FILM` on((`NEGATIVE`.`film_id` = `FILM`.`film_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `exifdata` (
  `film_id` tinyint NOT NULL,
  `negative_id` tinyint NOT NULL,
  `print_id` tinyint NOT NULL,
  `Make` tinyint NOT NULL,
  `Model` tinyint NOT NULL,
  `Author` tinyint NOT NULL,
  `LensMake` tinyint NOT NULL,
  `LensModel` tinyint NOT NULL,
  `Lens` tinyint NOT NULL,
  `LensSerialNumber` tinyint NOT NULL,
  `SerialNumber` tinyint NOT NULL,
  `path` tinyint NOT NULL,
  `MaxApertureValue` tinyint NOT NULL,
  `directory` tinyint NOT NULL,
  `filename` tinyint NOT NULL,
  `ExposureTime` tinyint NOT NULL,
  `FNumber` tinyint NOT NULL,
  `ApertureValue` tinyint NOT NULL,
  `FocalLength` tinyint NOT NULL,
  `ISO` tinyint NOT NULL,
  `ImageDescription` tinyint NOT NULL,
  `DateTimeOriginal` tinyint NOT NULL,
  `GPSLatitude` tinyint NOT NULL,
  `GPSLongitude` tinyint NOT NULL,
  `ExposureProgram` tinyint NOT NULL,
  `MeteringMode` tinyint NOT NULL,
  `Flash` tinyint NOT NULL,
  `FocalLengthIn35mmFormat` tinyint NOT NULL,
  `Copyright` tinyint NOT NULL,
  `UserComment` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `exifdata`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `exifdata` AS select `f`.`film_id` AS `film_id`,`n`.`negative_id` AS `negative_id`,`PRINT`.`print_id` AS `print_id`,`cm`.`manufacturer` AS `Make`,concat(`cm`.`manufacturer`,' ',`c`.`model`) AS `Model`,`p`.`name` AS `Author`,`lm`.`manufacturer` AS `LensMake`,concat(`lm`.`manufacturer`,' ',`l`.`model`) AS `LensModel`,concat(`lm`.`manufacturer`,' ',`l`.`model`) AS `Lens`,`l`.`serial` AS `LensSerialNumber`,`c`.`serial` AS `SerialNumber`,concat(`f`.`directory`,'/',`s`.`filename`) AS `path`,`l`.`max_aperture` AS `MaxApertureValue`,`f`.`directory` AS `directory`,`s`.`filename` AS `filename`,`n`.`shutter_speed` AS `ExposureTime`,`n`.`aperture` AS `FNumber`,`n`.`aperture` AS `ApertureValue`,if((`l`.`min_focal_length` = `l`.`max_focal_length`),concat(`l`.`min_focal_length`,'.0 mm'),concat(`n`.`focal_length`,'.0 mm')) AS `FocalLength`,if((`f`.`exposed_at` is not null),`f`.`exposed_at`,`fs`.`iso`) AS `ISO`,`n`.`description` AS `ImageDescription`,date_format(`n`.`date`,'%Y:%m:%d %H:%i:%s') AS `DateTimeOriginal`,if((`n`.`latitude` >= 0),concat('+',format(`n`.`latitude`,6)),format(`n`.`latitude`,6)) AS `GPSLatitude`,if((`n`.`longitude` >= 0),concat('+',format(`n`.`longitude`,6)),format(`n`.`longitude`,6)) AS `GPSLongitude`,if((`ep`.`exposure_program` > 0),`ep`.`exposure_program`,NULL) AS `ExposureProgram`,if((`mm`.`metering_mode` > 0),`mm`.`metering_mode`,NULL) AS `MeteringMode`,(case when isnull(`n`.`flash`) then NULL when (`n`.`flash` = 0) then 'No Flash' when (`n`.`flash` > 0) then 'Fired' end) AS `Flash`,if((`l`.`min_focal_length` = `l`.`max_focal_length`),concat(round((`l`.`min_focal_length` * `NEGATIVE_SIZE`.`crop_factor`),0),' mm'),concat(round((`n`.`focal_length` * `NEGATIVE_SIZE`.`crop_factor`),0),' mm')) AS `FocalLengthIn35mmFormat`,concat('Copyright ',`p`.`name`,' ',year(`n`.`date`)) AS `Copyright`,concat(`n`.`description`,'\nFilm: ',`fsm`.`manufacturer`,' ',`fs`.`name`,ifnull(concat('\n                                Paper: ',`psm`.`manufacturer`,' ',`ps`.`name`),'')) AS `UserComment` from (((((((((((((((`scans_negs` `n` join `FILM` `f` on((`n`.`film_id` = `f`.`film_id`))) join `FILMSTOCK` `fs` on((`f`.`filmstock_id` = `fs`.`filmstock_id`))) join `PERSON` `p` on((`f`.`photographer_id` = `p`.`person_id`))) join `CAMERA` `c` on((`f`.`camera_id` = `c`.`camera_id`))) left join `MANUFACTURER` `cm` on((`c`.`manufacturer_id` = `cm`.`manufacturer_id`))) left join `LENS` `l` on((`n`.`lens_id` = `l`.`lens_id`))) left join `MANUFACTURER` `lm` on((`l`.`manufacturer_id` = `lm`.`manufacturer_id`))) left join `EXPOSURE_PROGRAM` `ep` on((`n`.`exposure_program` = `ep`.`exposure_program_id`))) left join `METERING_MODE` `mm` on((`n`.`metering_mode` = `mm`.`metering_mode_id`))) join `SCAN` `s` on((`n`.`scan_id` = `s`.`scan_id`))) left join `PRINT` on((`s`.`print_id` = `PRINT`.`print_id`))) left join `NEGATIVE_SIZE` on((`c`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))) left join `MANUFACTURER` `fsm` on((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`))) left join `PAPER_STOCK` `ps` on((`PRINT`.`paper_stock_id` = `ps`.`paper_stock_id`))) left join `MANUFACTURER` `psm` on((`ps`.`manufacturer_id` = `psm`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_accessory` (
  `Accessory ID` tinyint NOT NULL,
  `Accessory type` tinyint NOT NULL,
  `Model` tinyint NOT NULL,
  `Acquired` tinyint NOT NULL,
  `Cost` tinyint NOT NULL,
  `Lost` tinyint NOT NULL,
  `Lost price` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_accessory`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_accessory` AS select `ACCESSORY`.`accessory_id` AS `Accessory ID`,`ACCESSORY_TYPE`.`accessory_type` AS `Accessory type`,if(`ACCESSORY`.`manufacturer_id`,concat(`MANUFACTURER`.`manufacturer`,' ',`ACCESSORY`.`model`),`ACCESSORY`.`model`) AS `Model`,`ACCESSORY`.`acquired` AS `Acquired`,`ACCESSORY`.`cost` AS `Cost`,`ACCESSORY`.`lost` AS `Lost`,`ACCESSORY`.`lost_price` AS `Lost price` from ((`ACCESSORY` left join `MANUFACTURER` on((`ACCESSORY`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) join `ACCESSORY_TYPE` on((`ACCESSORY_TYPE`.`accessory_type_id` = `ACCESSORY`.`accessory_type_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_archive` (
  `Archive ID` tinyint NOT NULL,
  `Archive name` tinyint NOT NULL,
  `Maximum size` tinyint NOT NULL,
  `Location` tinyint NOT NULL,
  `Storage type` tinyint NOT NULL,
  `Sealed` tinyint NOT NULL,
  `Archive type` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_archive`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_archive` AS select `ARCHIVE`.`archive_id` AS `Archive ID`,`ARCHIVE`.`name` AS `Archive name`,concat(`ARCHIVE`.`max_width`,'x',`ARCHIVE`.`max_height`) AS `Maximum size`,`ARCHIVE`.`location` AS `Location`,`ARCHIVE`.`storage` AS `Storage type`,`printbool`(`ARCHIVE`.`sealed`) AS `Sealed`,`ARCHIVE_TYPE`.`archive_type` AS `Archive type` from (`ARCHIVE` join `ARCHIVE_TYPE` on((`ARCHIVE`.`archive_type_id` = `ARCHIVE_TYPE`.`archive_type_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_camera` (
  `Camera ID` tinyint NOT NULL,
  `Camera` tinyint NOT NULL,
  `Negative size` tinyint NOT NULL,
  `Body type` tinyint NOT NULL,
  `Mount` tinyint NOT NULL,
  `Film format` tinyint NOT NULL,
  `Focus type` tinyint NOT NULL,
  `Metering` tinyint NOT NULL,
  `Coupled metering` tinyint NOT NULL,
  `Metering type` tinyint NOT NULL,
  `Weight` tinyint NOT NULL,
  `Date acquired` tinyint NOT NULL,
  `Cost` tinyint NOT NULL,
  `Manufactured between` tinyint NOT NULL,
  `Serial number` tinyint NOT NULL,
  `Datecode` tinyint NOT NULL,
  `Year of manufacture` tinyint NOT NULL,
  `Shutter type` tinyint NOT NULL,
  `Shutter model` tinyint NOT NULL,
  `Cable release` tinyint NOT NULL,
  `Viewfinder coverage` tinyint NOT NULL,
  `Power drive` tinyint NOT NULL,
  `continuous_fps` tinyint NOT NULL,
  `Video` tinyint NOT NULL,
  `Digital` tinyint NOT NULL,
  `Fixed mount` tinyint NOT NULL,
  `Lens` tinyint NOT NULL,
  `Battery` tinyint NOT NULL,
  `Notes` tinyint NOT NULL,
  `Lost` tinyint NOT NULL,
  `Lost price` tinyint NOT NULL,
  `Source` tinyint NOT NULL,
  `Bulb` tinyint NOT NULL,
  `Time` tinyint NOT NULL,
  `ISO range` tinyint NOT NULL,
  `Autofocus points` tinyint NOT NULL,
  `Internal flash` tinyint NOT NULL,
  `Internal flash guide number` tinyint NOT NULL,
  `External flash` tinyint NOT NULL,
  `Flash metering` tinyint NOT NULL,
  `PC sync socket` tinyint NOT NULL,
  `Hotshoe` tinyint NOT NULL,
  `Coldshoe` tinyint NOT NULL,
  `X-sync speed` tinyint NOT NULL,
  `Meter range` tinyint NOT NULL,
  `Condition` tinyint NOT NULL,
  `Depth of field preview` tinyint NOT NULL,
  `Exposure programs` tinyint NOT NULL,
  `Metering modes` tinyint NOT NULL,
  `Shutter speeds` tinyint NOT NULL,
  `Focal length` tinyint NOT NULL,
  `Maximum aperture` tinyint NOT NULL,
  `Films loaded` tinyint NOT NULL,
  `Frames shot` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_camera`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_camera` AS select `CAMERA`.`camera_id` AS `Camera ID`,concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `Camera`,`NEGATIVE_SIZE`.`negative_size` AS `Negative size`,`BODY_TYPE`.`body_type` AS `Body type`,`MOUNT`.`mount` AS `Mount`,`FORMAT`.`format` AS `Film format`,`FOCUS_TYPE`.`focus_type` AS `Focus type`,`printbool`(`CAMERA`.`metering`) AS `Metering`,`CAMERA`.`coupled_metering` AS `Coupled metering`,`METERING_TYPE`.`metering` AS `Metering type`,concat(`CAMERA`.`weight`,'g') AS `Weight`,`CAMERA`.`acquired` AS `Date acquired`,concat('£',`CAMERA`.`cost`) AS `Cost`,concat(`CAMERA`.`introduced`,'-',ifnull(`CAMERA`.`discontinued`,'?')) AS `Manufactured between`,`CAMERA`.`serial` AS `Serial number`,`CAMERA`.`datecode` AS `Datecode`,`CAMERA`.`manufactured` AS `Year of manufacture`,`SHUTTER_TYPE`.`shutter_type` AS `Shutter type`,`CAMERA`.`shutter_model` AS `Shutter model`,`PRINTBOOL`(`CAMERA`.`cable_release`) AS `Cable release`,concat(`CAMERA`.`viewfinder_coverage`,'%') AS `Viewfinder coverage`,`PRINTBOOL`(`CAMERA`.`power_drive`) AS `Power drive`,`CAMERA`.`continuous_fps` AS `continuous_fps`,`PRINTBOOL`(`CAMERA`.`video`) AS `Video`,`PRINTBOOL`(`CAMERA`.`digital`) AS `Digital`,`PRINTBOOL`(`CAMERA`.`fixed_mount`) AS `Fixed mount`,`LENS`.`model` AS `Lens`,concat(`CAMERA`.`battery_qty`,' x ',`BATTERY`.`battery_name`) AS `Battery`,`CAMERA`.`notes` AS `Notes`,`CAMERA`.`lost` AS `Lost`,`CAMERA`.`lost_price` AS `Lost price`,`CAMERA`.`source` AS `Source`,`CAMERA`.`bulb` AS `Bulb`,`CAMERA`.`time` AS `Time`,concat(`CAMERA`.`min_iso`,'-',`CAMERA`.`max_iso`) AS `ISO range`,`CAMERA`.`af_points` AS `Autofocus points`,`PRINTBOOL`(`CAMERA`.`int_flash`) AS `Internal flash`,`CAMERA`.`int_flash_gn` AS `Internal flash guide number`,`PRINTBOOL`(`CAMERA`.`ext_flash`) AS `External flash`,`CAMERA`.`flash_metering` AS `Flash metering`,`PRINTBOOL`(`CAMERA`.`pc_sync`) AS `PC sync socket`,`PRINTBOOL`(`CAMERA`.`hotshoe`) AS `Hotshoe`,`PRINTBOOL`(`CAMERA`.`coldshoe`) AS `Coldshoe`,`CAMERA`.`x_sync` AS `X-sync speed`,concat(`CAMERA`.`meter_min_ev`,'-',`CAMERA`.`meter_max_ev`) AS `Meter range`,`CONDITION`.`name` AS `Condition`,`PRINTBOOL`(`CAMERA`.`dof_preview`) AS `Depth of field preview`,group_concat(distinct `EXPOSURE_PROGRAM`.`exposure_program` separator ', ') AS `Exposure programs`,group_concat(distinct `METERING_MODE`.`metering_mode` separator ', ') AS `Metering modes`,group_concat(distinct `SHUTTER_SPEED_AVAILABLE`.`shutter_speed` separator ', ') AS `Shutter speeds`,if(`LENS`.`zoom`,concat(`LENS`.`min_focal_length`,'-',`LENS`.`max_focal_length`,'mm'),concat(`LENS`.`min_focal_length`,'mm')) AS `Focal length`,concat('f/',`LENS`.`max_aperture`) AS `Maximum aperture`,count(distinct `FILM`.`film_id`) AS `Films loaded`,count(distinct `NEGATIVE`.`negative_id`) AS `Frames shot` from ((((((((((((((((((`CAMERA` left join `MANUFACTURER` on((`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) left join `NEGATIVE_SIZE` on((`CAMERA`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))) left join `BODY_TYPE` on((`CAMERA`.`body_type_id` = `BODY_TYPE`.`body_type_id`))) left join `BATTERY` on((`CAMERA`.`battery_type` = `BATTERY`.`battery_type`))) left join `METERING_TYPE` on((`CAMERA`.`metering_type_id` = `METERING_TYPE`.`metering_type_id`))) left join `SHUTTER_TYPE` on((`CAMERA`.`shutter_type_id` = `SHUTTER_TYPE`.`shutter_type_id`))) left join `CONDITION` on((`CAMERA`.`condition_id` = `CONDITION`.`condition_id`))) left join `FOCUS_TYPE` on((`CAMERA`.`focus_type_id` = `FOCUS_TYPE`.`focus_type_id`))) left join `EXPOSURE_PROGRAM_AVAILABLE` on((`CAMERA`.`camera_id` = `EXPOSURE_PROGRAM_AVAILABLE`.`camera_id`))) left join `EXPOSURE_PROGRAM` on((`EXPOSURE_PROGRAM_AVAILABLE`.`exposure_program_id` = `EXPOSURE_PROGRAM`.`exposure_program_id`))) left join `METERING_MODE_AVAILABLE` on((`CAMERA`.`camera_id` = `METERING_MODE_AVAILABLE`.`camera_id`))) left join `METERING_MODE` on((`METERING_MODE_AVAILABLE`.`metering_mode_id` = `METERING_MODE`.`metering_mode_id`))) left join `SHUTTER_SPEED_AVAILABLE` on((`CAMERA`.`camera_id` = `SHUTTER_SPEED_AVAILABLE`.`camera_id`))) left join `FORMAT` on((`CAMERA`.`format_id` = `FORMAT`.`format_id`))) left join `MOUNT` on((`CAMERA`.`mount_id` = `MOUNT`.`mount_id`))) left join `LENS` on((`CAMERA`.`lens_id` = `LENS`.`lens_id`))) left join `FILM` on((`CAMERA`.`camera_id` = `FILM`.`camera_id`))) left join `NEGATIVE` on((`FILM`.`film_id` = `NEGATIVE`.`film_id`))) where (`CAMERA`.`own` = 1) group by `CAMERA`.`camera_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_enlarger` (
  `Enlarger ID` tinyint NOT NULL,
  `Manufacturer` tinyint NOT NULL,
  `Model` tinyint NOT NULL,
  `Negative size` tinyint NOT NULL,
  `Acquired` tinyint NOT NULL,
  `Lost` tinyint NOT NULL,
  `Introduced` tinyint NOT NULL,
  `Discontinued` tinyint NOT NULL,
  `Cost` tinyint NOT NULL,
  `Lost price` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_enlarger`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_enlarger` AS select `ENLARGER`.`enlarger_id` AS `Enlarger ID`,`MANUFACTURER`.`manufacturer` AS `Manufacturer`,`ENLARGER`.`enlarger` AS `Model`,`NEGATIVE_SIZE`.`negative_size` AS `Negative size`,`ENLARGER`.`acquired` AS `Acquired`,`ENLARGER`.`lost` AS `Lost`,`ENLARGER`.`introduced` AS `Introduced`,`ENLARGER`.`discontinued` AS `Discontinued`,`ENLARGER`.`cost` AS `Cost`,`ENLARGER`.`lost_price` AS `Lost price` from ((`ENLARGER` left join `NEGATIVE_SIZE` on((`ENLARGER`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))) left join `MANUFACTURER` on((`ENLARGER`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_film` (
  `Film ID` tinyint NOT NULL,
  `ISO` tinyint NOT NULL,
  `Date` tinyint NOT NULL,
  `Title` tinyint NOT NULL,
  `Frames` tinyint NOT NULL,
  `dev_time` tinyint NOT NULL,
  `dev_temp` tinyint NOT NULL,
  `Development notes` tinyint NOT NULL,
  `Processed by` tinyint NOT NULL,
  `Filmstock` tinyint NOT NULL,
  `Camera` tinyint NOT NULL,
  `Developer` tinyint NOT NULL,
  `Archive` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_film`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_film` AS select `FILM`.`film_id` AS `Film ID`,concat('Box speed ',`FILMSTOCK`.`iso`,' exposed at EI ',`FILM`.`exposed_at`,if(`FILM`.`dev_n`,concat(' (',if(sign(`FILM`.`dev_n`),concat('N+',`FILM`.`dev_n`),concat('N-',`FILM`.`dev_n`)),')'),'')) AS `ISO`,`FILM`.`date` AS `Date`,`FILM`.`notes` AS `Title`,`FILM`.`frames` AS `Frames`,`FILM`.`dev_time` AS `dev_time`,`FILM`.`dev_temp` AS `dev_temp`,`FILM`.`development_notes` AS `Development notes`,`FILM`.`processed_by` AS `Processed by`,concat(`fm`.`manufacturer`,' ',`FILMSTOCK`.`name`) AS `Filmstock`,concat(`cm`.`manufacturer`,' ',`c`.`model`) AS `Camera`,concat(`dm`.`manufacturer`,' ',`DEVELOPER`.`name`) AS `Developer`,`ARCHIVE`.`name` AS `Archive` from (((((`FILM` left join (`FILMSTOCK` left join `MANUFACTURER` `fm` on((`FILMSTOCK`.`manufacturer_id` = `fm`.`manufacturer_id`))) on((`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`))) left join `FORMAT` on((`FILM`.`format_id` = `FORMAT`.`format_id`))) left join (`CAMERA` `c` left join `MANUFACTURER` `cm` on((`c`.`manufacturer_id` = `cm`.`manufacturer_id`))) on((`FILM`.`camera_id` = `c`.`camera_id`))) left join (`DEVELOPER` left join `MANUFACTURER` `dm` on((`DEVELOPER`.`manufacturer_id` = `dm`.`manufacturer_id`))) on((`FILM`.`developer_id` = `DEVELOPER`.`developer_id`))) left join `ARCHIVE` on((`FILM`.`archive_id` = `ARCHIVE`.`archive_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_lens` (
  `Lens ID` tinyint NOT NULL,
  `Mount` tinyint NOT NULL,
  `Focal length` tinyint NOT NULL,
  `Lens` tinyint NOT NULL,
  `Closest focus` tinyint NOT NULL,
  `Maximum aperture` tinyint NOT NULL,
  `Minimum aperture` tinyint NOT NULL,
  `Elements/Groups` tinyint NOT NULL,
  `Weight` tinyint NOT NULL,
  `Angle of view` tinyint NOT NULL,
  `Aperture blades` tinyint NOT NULL,
  `Autofocus` tinyint NOT NULL,
  `Filter thread` tinyint NOT NULL,
  `Maximum magnification` tinyint NOT NULL,
  `URL` tinyint NOT NULL,
  `Serial number` tinyint NOT NULL,
  `Date code` tinyint NOT NULL,
  `Manufactured between` tinyint NOT NULL,
  `Year of manufacture` tinyint NOT NULL,
  `Negative size` tinyint NOT NULL,
  `Date acquired` tinyint NOT NULL,
  `Cost` tinyint NOT NULL,
  `Notes` tinyint NOT NULL,
  `Date lost` tinyint NOT NULL,
  `Price sold` tinyint NOT NULL,
  `Source` tinyint NOT NULL,
  `Coating` tinyint NOT NULL,
  `Hood` tinyint NOT NULL,
  `EXIF LensType` tinyint NOT NULL,
  `Rectilinear` tinyint NOT NULL,
  `Dimensions (l×w)` tinyint NOT NULL,
  `Condition` tinyint NOT NULL,
  `Image circle` tinyint NOT NULL,
  `Optical formula` tinyint NOT NULL,
  `Shutter model` tinyint NOT NULL,
  `Frames shot` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_lens`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_lens` AS select `LENS`.`lens_id` AS `Lens ID`,`MOUNT`.`mount` AS `Mount`,if(`LENS`.`zoom`,concat(`LENS`.`min_focal_length`,'-',`LENS`.`max_focal_length`,'mm'),concat(`LENS`.`min_focal_length`,'mm')) AS `Focal length`,concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `Lens`,concat(`LENS`.`closest_focus`,'cm') AS `Closest focus`,concat('f/',`LENS`.`max_aperture`) AS `Maximum aperture`,concat('f/',`LENS`.`min_aperture`) AS `Minimum aperture`,concat(`LENS`.`elements`,'/',`LENS`.`groups`) AS `Elements/Groups`,concat(`LENS`.`weight`,'g') AS `Weight`,if(`LENS`.`zoom`,concat(`LENS`.`nominal_max_angle_diag`,'°-',`LENS`.`nominal_min_angle_diag`,'°'),concat(`LENS`.`nominal_max_angle_diag`,'°')) AS `Angle of view`,`LENS`.`aperture_blades` AS `Aperture blades`,`printbool`(`LENS`.`autofocus`) AS `Autofocus`,concat(`LENS`.`filter_thread`,'mm') AS `Filter thread`,concat(`LENS`.`magnification`,'×') AS `Maximum magnification`,`LENS`.`url` AS `URL`,`LENS`.`serial` AS `Serial number`,`LENS`.`date_code` AS `Date code`,concat(ifnull(`LENS`.`introduced`,'?'),'-',ifnull(`LENS`.`discontinued`,'?')) AS `Manufactured between`,`LENS`.`manufactured` AS `Year of manufacture`,`NEGATIVE_SIZE`.`negative_size` AS `Negative size`,`LENS`.`acquired` AS `Date acquired`,concat('£',`LENS`.`cost`) AS `Cost`,`LENS`.`notes` AS `Notes`,`LENS`.`lost` AS `Date lost`,concat('£',`LENS`.`lost_price`) AS `Price sold`,`LENS`.`source` AS `Source`,`LENS`.`coating` AS `Coating`,`LENS`.`hood` AS `Hood`,`LENS`.`exif_lenstype` AS `EXIF LensType`,`printbool`(`LENS`.`rectilinear`) AS `Rectilinear`,concat(`LENS`.`length`,'×',`LENS`.`diameter`,'mm') AS `Dimensions (l×w)`,`CONDITION`.`name` AS `Condition`,concat(`LENS`.`image_circle`,'mm') AS `Image circle`,`LENS`.`formula` AS `Optical formula`,`LENS`.`shutter_model` AS `Shutter model`,count(`NEGATIVE`.`negative_id`) AS `Frames shot` from (((((`LENS` left join `MOUNT` on((`LENS`.`mount_id` = `MOUNT`.`mount_id`))) left join `MANUFACTURER` on((`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) left join `CONDITION` on((`LENS`.`condition_id` = `CONDITION`.`condition_id`))) left join `NEGATIVE_SIZE` on((`LENS`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`))) left join `NEGATIVE` on((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`))) where ((`LENS`.`own` = 1) and (`LENS`.`fixed_mount` = 0)) group by `LENS`.`lens_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_movie` (
  `Movie ID` tinyint NOT NULL,
  `Title` tinyint NOT NULL,
  `Camera` tinyint NOT NULL,
  `Lens` tinyint NOT NULL,
  `Format` tinyint NOT NULL,
  `Sound` tinyint NOT NULL,
  `Frame rate` tinyint NOT NULL,
  `Filmstock` tinyint NOT NULL,
  `Length (feet)` tinyint NOT NULL,
  `Date loaded` tinyint NOT NULL,
  `Date shot` tinyint NOT NULL,
  `Date processed` tinyint NOT NULL,
  `Process` tinyint NOT NULL,
  `Description` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_movie`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_movie` AS select `MOVIE`.`movie_id` AS `Movie ID`,`MOVIE`.`title` AS `Title`,concat(`CM`.`manufacturer`,' ',`CAMERA`.`model`) AS `Camera`,concat(`LM`.`manufacturer`,' ',`LENS`.`model`) AS `Lens`,`FORMAT`.`format` AS `Format`,`printbool`(`MOVIE`.`sound`) AS `Sound`,`MOVIE`.`fps` AS `Frame rate`,concat(`FM`.`manufacturer`,' ',`FILMSTOCK`.`name`) AS `Filmstock`,`MOVIE`.`feet` AS `Length (feet)`,`MOVIE`.`date_loaded` AS `Date loaded`,`MOVIE`.`date_shot` AS `Date shot`,`MOVIE`.`date_processed` AS `Date processed`,`PROCESS`.`name` AS `Process`,`MOVIE`.`description` AS `Description` from ((((((((`MOVIE` left join `CAMERA` on((`MOVIE`.`camera_id` = `CAMERA`.`camera_id`))) left join `FILMSTOCK` on((`MOVIE`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`))) left join `LENS` on((`MOVIE`.`lens_id` = `LENS`.`lens_id`))) left join `MANUFACTURER` `CM` on((`CM`.`manufacturer_id` = `CAMERA`.`manufacturer_id`))) left join `MANUFACTURER` `FM` on((`FM`.`manufacturer_id` = `FILMSTOCK`.`manufacturer_id`))) left join `MANUFACTURER` `LM` on((`LM`.`manufacturer_id` = `LENS`.`manufacturer_id`))) left join `FORMAT` on((`MOVIE`.`format_id` = `FORMAT`.`format_id`))) left join `PROCESS` on((`MOVIE`.`process_id` = `PROCESS`.`process_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_negative` (
  `Negative ID` tinyint NOT NULL,
  `Film ID` tinyint NOT NULL,
  `Frame` tinyint NOT NULL,
  `Metering mode` tinyint NOT NULL,
  `Date` tinyint NOT NULL,
  `Location` tinyint NOT NULL,
  `Filename` tinyint NOT NULL,
  `Shutter speed` tinyint NOT NULL,
  `Lens` tinyint NOT NULL,
  `Photographer` tinyint NOT NULL,
  `Aperture` tinyint NOT NULL,
  `Caption` tinyint NOT NULL,
  `Focal length` tinyint NOT NULL,
  `Exposure program` tinyint NOT NULL,
  `Prints made` tinyint NOT NULL,
  `Camera` tinyint NOT NULL,
  `Filmstock` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_negative`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_negative` AS select `n`.`negative_id` AS `Negative ID`,`n`.`film_id` AS `Film ID`,`n`.`frame` AS `Frame`,`mm`.`metering_mode` AS `Metering mode`,date_format(`n`.`date`,'%Y-%m-%d %H:%i:%s') AS `Date`,concat(`n`.`latitude`,', ',`n`.`longitude`) AS `Location`,`s`.`filename` AS `Filename`,`n`.`shutter_speed` AS `Shutter speed`,concat(`lm`.`manufacturer`,' ',`l`.`model`) AS `Lens`,`p`.`name` AS `Photographer`,concat('f/',`n`.`aperture`) AS `Aperture`,`n`.`description` AS `Caption`,if((`l`.`min_focal_length` = `l`.`max_focal_length`),concat(`l`.`min_focal_length`,'mm'),concat(`n`.`focal_length`,'mm')) AS `Focal length`,`ep`.`exposure_program` AS `Exposure program`,count(`PRINT`.`print_id`) AS `Prints made`,concat(`cm`.`manufacturer`,' ',`c`.`model`) AS `Camera`,concat(`fsm`.`manufacturer`,' ',`fs`.`name`) AS `Filmstock` from ((((((((((((`NEGATIVE` `n` join `FILM` `f` on((`n`.`film_id` = `f`.`film_id`))) join `FILMSTOCK` `fs` on((`f`.`filmstock_id` = `fs`.`filmstock_id`))) join `CAMERA` `c` on((`f`.`camera_id` = `c`.`camera_id`))) join `MANUFACTURER` `cm` on((`c`.`manufacturer_id` = `cm`.`manufacturer_id`))) left join `PERSON` `p` on((`n`.`photographer_id` = `p`.`person_id`))) left join `MANUFACTURER` `fsm` on((`fs`.`manufacturer_id` = `fsm`.`manufacturer_id`))) left join `LENS` `l` on((`n`.`lens_id` = `l`.`lens_id`))) left join `MANUFACTURER` `lm` on((`l`.`manufacturer_id` = `lm`.`manufacturer_id`))) left join `EXPOSURE_PROGRAM` `ep` on((`n`.`exposure_program` = `ep`.`exposure_program_id`))) left join `METERING_MODE` `mm` on((`n`.`metering_mode` = `mm`.`metering_mode_id`))) left join `PRINT` on((`n`.`negative_id` = `PRINT`.`negative_id`))) left join `SCAN` `s` on((`n`.`negative_id` = `s`.`negative_id`))) where (`s`.`filename` is not null) group by `n`.`negative_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_print` (
  `Negative` tinyint NOT NULL,
  `Negative ID` tinyint NOT NULL,
  `Print` tinyint NOT NULL,
  `Description` tinyint NOT NULL,
  `Size` tinyint NOT NULL,
  `Exposure time` tinyint NOT NULL,
  `Aperture` tinyint NOT NULL,
  `Filtration grade` tinyint NOT NULL,
  `Paper` tinyint NOT NULL,
  `Enlarger` tinyint NOT NULL,
  `Enlarger lens` tinyint NOT NULL,
  `First toner` tinyint NOT NULL,
  `Second toner` tinyint NOT NULL,
  `Print date` tinyint NOT NULL,
  `Photo date` tinyint NOT NULL,
  `Photographer` tinyint NOT NULL,
  `Location` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `info_print`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `info_print` AS select concat(`NEGATIVE`.`film_id`,'/',`NEGATIVE`.`frame`) AS `Negative`,`NEGATIVE`.`negative_id` AS `Negative ID`,`PRINT`.`print_id` AS `Print`,`NEGATIVE`.`description` AS `Description`,`DISPLAYSIZE`(`PRINT`.`width`,`PRINT`.`height`) AS `Size`,concat(`PRINT`.`exposure_time`,'s') AS `Exposure time`,concat('f/',`PRINT`.`aperture`) AS `Aperture`,`PRINT`.`filtration_grade` AS `Filtration grade`,concat(`PAPER_STOCK_MANUFACTURER`.`manufacturer`,' ',`PAPER_STOCK`.`name`) AS `Paper`,concat(`ENLARGER_MANUFACTURER`.`manufacturer`,' ',`ENLARGER`.`enlarger`) AS `Enlarger`,concat(`LENS_MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `Enlarger lens`,concat(`FIRSTTONER_MANUFACTURER`.`manufacturer`,' ',`FIRSTTONER`.`toner`,if((`PRINT`.`toner_dilution` is not null),concat(' (',`PRINT`.`toner_dilution`,')'),''),if((`PRINT`.`toner_time` is not null),concat(' for ',`PRINT`.`toner_time`),'')) AS `First toner`,concat(`SECONDTONER_MANUFACTURER`.`manufacturer`,' ',`SECONDTONER`.`toner`,if((`PRINT`.`2nd_toner_dilution` is not null),concat(' (',`PRINT`.`2nd_toner_dilution`,')'),''),if((`PRINT`.`2nd_toner_time` is not null),concat(' for ',`PRINT`.`2nd_toner_time`),'')) AS `Second toner`,date_format(`PRINT`.`date`,'%M %Y') AS `Print date`,date_format(`NEGATIVE`.`date`,'%M %Y') AS `Photo date`,`PERSON`.`name` AS `Photographer`,(case `PRINT`.`own` when 1 then ifnull(`ARCHIVE`.`name`,'Owned; location unknown') when 0 then ifnull(`PRINT`.`location`,'Not owned; location unknown') else 'No location information' end) AS `Location` from (((((((((((((`PRINT` join `PAPER_STOCK` on((`PRINT`.`paper_stock_id` = `PAPER_STOCK`.`paper_stock_id`))) join `MANUFACTURER` `PAPER_STOCK_MANUFACTURER` on((`PAPER_STOCK`.`manufacturer_id` = `PAPER_STOCK_MANUFACTURER`.`manufacturer_id`))) left join `ENLARGER` on((`PRINT`.`enlarger_id` = `ENLARGER`.`enlarger_id`))) join `MANUFACTURER` `ENLARGER_MANUFACTURER` on((`ENLARGER`.`manufacturer_id` = `ENLARGER_MANUFACTURER`.`manufacturer_id`))) left join `LENS` on((`PRINT`.`lens_id` = `LENS`.`lens_id`))) join `MANUFACTURER` `LENS_MANUFACTURER` on((`LENS`.`manufacturer_id` = `LENS_MANUFACTURER`.`manufacturer_id`))) left join `TONER` `FIRSTTONER` on((`PRINT`.`toner_id` = `FIRSTTONER`.`toner_id`))) left join `MANUFACTURER` `FIRSTTONER_MANUFACTURER` on((`FIRSTTONER`.`manufacturer_id` = `FIRSTTONER_MANUFACTURER`.`manufacturer_id`))) left join `TONER` `SECONDTONER` on((`PRINT`.`2nd_toner_id` = `SECONDTONER`.`toner_id`))) left join `MANUFACTURER` `SECONDTONER_MANUFACTURER` on((`SECONDTONER`.`manufacturer_id` = `SECONDTONER_MANUFACTURER`.`manufacturer_id`))) left join `NEGATIVE` on((`PRINT`.`negative_id` = `NEGATIVE`.`negative_id`))) left join `PERSON` on((`NEGATIVE`.`photographer_id` = `PERSON`.`person_id`))) left join `ARCHIVE` on((`PRINT`.`archive_id` = `ARCHIVE`.`archive_id`)));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_cameras_by_decade` (
  `Decade` tinyint NOT NULL,
  `Cameras` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_cameras_by_decade`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_cameras_by_decade` AS select (floor((`CAMERA`.`introduced` / 10)) * 10) AS `Decade`,count(`CAMERA`.`camera_id`) AS `Cameras` from `CAMERA` where (`CAMERA`.`introduced` is not null) group by (floor((`CAMERA`.`introduced` / 10)) * 10);
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_most_popular_lenses_relative` (
  `Lens` tinyint NOT NULL,
  `Days owned` tinyint NOT NULL,
  `Frames shot` tinyint NOT NULL,
  `Frames shot per day` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_most_popular_lenses_relative`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_most_popular_lenses_relative` AS select concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `Lens`,(to_days(curdate()) - to_days(`LENS`.`acquired`)) AS `Days owned`,count(`NEGATIVE`.`negative_id`) AS `Frames shot`,(count(`NEGATIVE`.`negative_id`) / (to_days(curdate()) - to_days(`LENS`.`acquired`))) AS `Frames shot per day` from (((`LENS` join `MANUFACTURER` on((`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) join `NEGATIVE` on((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`))) join `MOUNT` on((`LENS`.`mount_id` = `MOUNT`.`mount_id`))) where ((`LENS`.`acquired` is not null) and (`MOUNT`.`fixed` = 0)) group by `LENS`.`lens_id` order by (count(`NEGATIVE`.`negative_id`) / (to_days(curdate()) - to_days(`LENS`.`acquired`))) desc;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_never_used_cameras` (
  `Camera` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_never_used_cameras`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_never_used_cameras` AS select concat('#',`CAMERA`.`camera_id`,' ',`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `Camera` from ((`CAMERA` left join `FILM` on((`CAMERA`.`camera_id` = `FILM`.`camera_id`))) left join `MANUFACTURER` on((`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) where (isnull(`FILM`.`camera_id`) and (`CAMERA`.`own` <> 0) and (`CAMERA`.`digital` = 0) and (`CAMERA`.`video` = 0));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_never_used_lenses` (
  `Lens` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_never_used_lenses`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_never_used_lenses` AS select concat('#',`LENS`.`lens_id`,' ',`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `Lens` from (((`LENS` join `MANUFACTURER` on((`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) join `MOUNT` on((`LENS`.`mount_id` = `MOUNT`.`mount_id`))) left join `NEGATIVE` on((`NEGATIVE`.`lens_id` = `LENS`.`lens_id`))) where ((`LENS`.`fixed_mount` = 0) and (`MOUNT`.`purpose` = 'Camera') and (`MOUNT`.`digital_only` = 0) and (`LENS`.`own` = 1) and isnull(`NEGATIVE`.`negative_id`)) order by `LENS`.`lens_id`;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_total_negatives_per_camera` (
  `Camera` tinyint NOT NULL,
  `Frames shot` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_total_negatives_per_camera`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_total_negatives_per_camera` AS select concat(`MANUFACTURER`.`manufacturer`,' ',`CAMERA`.`model`) AS `Camera`,count(`NEGATIVE`.`negative_id`) AS `Frames shot` from (((`CAMERA` join `FILM` on((`CAMERA`.`camera_id` = `FILM`.`camera_id`))) join `NEGATIVE` on((`FILM`.`film_id` = `NEGATIVE`.`film_id`))) join `MANUFACTURER` on((`CAMERA`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) group by `CAMERA`.`camera_id` order by count(`NEGATIVE`.`negative_id`) desc;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_total_negatives_per_lens` (
  `Lens` tinyint NOT NULL,
  `Frames shot` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_total_negatives_per_lens`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_total_negatives_per_lens` AS select concat(`MANUFACTURER`.`manufacturer`,' ',`LENS`.`model`) AS `Lens`,count(`NEGATIVE`.`negative_id`) AS `Frames shot` from (((`LENS` join `NEGATIVE` on((`LENS`.`lens_id` = `NEGATIVE`.`lens_id`))) join `MANUFACTURER` on((`LENS`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))) join `MOUNT` on((`LENS`.`mount_id` = `MOUNT`.`mount_id`))) where ((`LENS`.`fixed_mount` = 0) and (`MOUNT`.`purpose` = 'Camera')) group by `LENS`.`lens_id` order by count(`NEGATIVE`.`negative_id`) desc;
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `report_unscanned_negs` (
  `negative_id` tinyint NOT NULL,
  `film_id` tinyint NOT NULL,
  `frame` tinyint NOT NULL,
  `description` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `report_unscanned_negs`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `report_unscanned_negs` AS select `NEGATIVE`.`negative_id` AS `negative_id`,`NEGATIVE`.`film_id` AS `film_id`,`NEGATIVE`.`frame` AS `frame`,`NEGATIVE`.`description` AS `description` from ((`NEGATIVE` left join `SCAN` on((`NEGATIVE`.`negative_id` = `SCAN`.`negative_id`))) left join `FILM` on((`NEGATIVE`.`film_id` = `FILM`.`film_id`))) where (isnull(`SCAN`.`negative_id`) and (`FILM`.`date` is not null));
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `view_film_stocks` (
  `film` tinyint NOT NULL,
  `qty` tinyint NOT NULL
) ENGINE=MyISAM;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `view_film_stocks`;
SET @saved_cs_client          = @@character_set_client;
SET @saved_cs_results         = @@character_set_results;
SET @saved_col_connection     = @@collation_connection;
SET character_set_client      = utf8;
SET character_set_results     = utf8;
SET collation_connection      = utf8_general_ci;
CREATE ALGORITHM=UNDEFINED
VIEW `view_film_stocks` AS select concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,' (',`FORMAT`.`format`,')') AS `film`,count(`FILMSTOCK`.`filmstock_id`) AS `qty` from (((`FILM` join `FILMSTOCK`) join `FORMAT`) join `MANUFACTURER`) where (isnull(`FILM`.`camera_id`) and isnull(`FILM`.`date`) and (`FILM`.`filmstock_id` = `FILMSTOCK`.`filmstock_id`) and (`FILM`.`format_id` = `FORMAT`.`format_id`) and (`FILMSTOCK`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)) group by concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,' (',`FORMAT`.`format`,')') order by concat(`MANUFACTURER`.`manufacturer`,' ',`FILMSTOCK`.`name`,' (',`FORMAT`.`format`,')');
SET character_set_client      = @saved_cs_client;
SET character_set_results     = @saved_cs_results;
SET collation_connection      = @saved_col_connection;
