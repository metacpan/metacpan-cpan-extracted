package App::PhotoDB::handlers;

# This package provides reusable handlers to be interact with the user

use strict;
use warnings;

use Exporter qw(import);
use Config::IniHash;
use YAML;
use Array::Utils qw(:all);
use Path::Iterator::Rule;
use File::Basename;
use Text::TabularDisplay;

use App::PhotoDB::funcs qw(/./);
use App::PhotoDB::queries;

our @EXPORT_OK = qw(
	film_add film_load film_archive film_develop film_tag film_locate film_bulk film_annotate film_stocks film_current film_choose film_info
	camera_add camera_displaylens camera_sell camera_repair camera_addbodytype camera_exposureprogram camera_shutterspeeds camera_accessory camera_meteringmode camera_info camera_choose camera_edit
	mount_add mount_info mount_adapt
	negative_add negative_bulkadd negative_prints negative_info negative_tag
	lens_add lens_sell lens_repair lens_accessory lens_info lens_edit
	print_add print_tone print_sell print_order print_fulfil print_archive print_unarchive print_locate print_info print_exhibit print_label print_worklist print_tag
	paperstock_add
	developer_add
	toner_add
	run_task run_report
	filmstock_add
	teleconverter_add
	filter_add filter_adapt
	manufacturer_add
	accessory_add accessory_category accessory_info
	enlarger_add enlarger_info enlarger_sell
	flash_add
	battery_add
	format_add
	negativesize_add
	lightmeter_add
	process_add
	person_add
	projector_add
	movie_add movie_info
	archive_add archive_films archive_info archive_list archive_seal archive_unseal archive_move
	shuttertype_add focustype_add flashprotocol_add meteringtype_add shutterspeed_add
	audit_shutterspeeds audit_exposureprograms audit_meteringmodes audit_displaylenses
	exhibition_add exhibition_info
	choose_manufacturer
	db_stats db_logs db_test
	scan_add scan_edit scan_delete scan_search
);

# Add a new film to the database
sub film_add {
	my $db = shift;
	my %data;
	if (&prompt({default=>'no', prompt=>'Is this film bulk-loaded?', type=>'boolean'}) == 1) {
		# These are filled in only for bulk-loaded films
		$data{film_bulk_id} = &listchoices({db=>$db, table=>'choose_bulk_film', required=>1});
		$data{film_bulk_loaded} = &prompt({default=>&today($db), prompt=>'When was the film bulk-loaded?'});
		# These are deduced automagically for bulk-loaded films
		$data{film_batch} = &lookupval({db=>$db, col=>'batch', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{film_expiry} = &lookupval({db=>$db, col=>'expiry', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{purchase_date} = &lookupval({db=>$db, col=>'purchase_date', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{filmstock_id} = &lookupval({db=>$db, col=>'filmstock_id', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{format_id} = &lookupval({db=>$db, col=>'format_id', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
	} else {
		# These are filled in only for standalone films
		$data{film_batch} = &prompt({prompt=>'Film batch number'});
		$data{film_expiry} = &prompt({prompt=>'Film expiry date', type=>'date'});
		$data{purchase_date} = &prompt({default=>&today($db), prompt=>'Purchase date', type=>'date'});
		$data{filmstock_id} = &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add, required=>1});
		$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add}, required=>1);
	}
	$data{frames} = &prompt({prompt=>'How many frames?', type=>'integer'});
	$data{price} = &prompt({prompt=>'Purchase price', type=>'decimal'});
	my $filmid = &newrecord({db=>$db, data=>\%data, table=>'FILM'});
	if (&prompt({default=>'no', prompt=>'Load this film into a camera now?', type=>'boolean'})) {
		&film_load($db, $filmid);
	}
	return $filmid;
}

# Load a film into a camera
sub film_load {
	my $db = shift;
	my $film_id = shift || &listchoices({db=>$db, table=>'choose_film_to_load', required=>1});
	my %data;
	$data{camera_id} = &listchoices({db=>$db, table=>'choose_camera_by_film', where=>{film_id=>$film_id}, required=>1});
	$data{exposed_at} = &prompt({default=>&lookupval({db=>$db, col=>"iso", table=>'FILM join FILMSTOCK on FILM.filmstock_id=FILMSTOCK.filmstock_id', where=>{film_id=>$film_id}}), prompt=>'What ISO?', type=>'integer'});
	$data{date_loaded} = &prompt({default=>&today($db), prompt=>'What date was this film loaded?', type=>'date'});
	$data{notes} = &prompt({prompt=>'Notes'});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>"film_id=$film_id"});
}

# Put a film in a physical archive
sub film_archive {
	my $db = shift;
	my $film_id = shift || &film_choose($db);
	my %data;
	$data{archive_id} = &listchoices({db=>$db, table=>'ARCHIVE', cols=>['archive_id as id', 'name as opt'], where=>['archive_type_id in (1,2)', 'sealed = 0'], inserthandler=>\&archive_add, required=>1});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>"film_id=$film_id"});
}

# Develop a film
sub film_develop {
	my $db = shift;
	my $film_id = shift || &listchoices({db=>$db, table=>'choose_film_to_develop', required=>1});
	my %data;
	$data{date} = &prompt({default=>&today($db), prompt=>'What date was this film processed?', type=>'date'});
	$data{developer_id} = &listchoices({db=>$db, table=>'DEVELOPER', cols=>['developer_id as id', 'name as opt'], where=>{'for_film'=>1}, inserthandler=>\&developer_add});
	$data{directory} = &prompt({prompt=>'What directory are these scans in?'});
	$data{photographer_id} = &listchoices({db=>$db, keyword=>'photographer', table=> 'PERSON', cols=>['person_id as id', 'name as opt'], inserthandler=>\&person_add});
	$data{dev_uses} = &prompt({prompt=>'How many previous uses has the developer had?', type=>'integer'});
	$data{dev_time} = &prompt({prompt=>'How long was the film developed for?', type=>'time'});
	$data{dev_temp} = &prompt({prompt=>'What temperature was the developer?', type=>'decimal'});
	$data{dev_n} = &prompt({default=>0, prompt=>'What push/pull was used?', type=>'integer'});
	$data{development_notes} = &prompt({prompt=>'Any other development notes'});
	$data{processed_by} = &prompt({prompt=>'Who developed the film?'});
	&updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>"film_id=$film_id"});
	if (&prompt({default=>'no', prompt=>'Archive this film now?', type=>'boolean'})) {
		&film_archive($db, $film_id);
	}
	return;
}

# Show information about a negative
sub film_info {
	my $db = shift;
	my $film_id = shift || &film_choose($db);
	my $filmdata = &lookupcol({db=>$db, table=>'info_film', where=>{'`Film ID`'=>$film_id}});
	print Dump($filmdata);
	return;
}

# Write EXIF tags to scans from a film
sub film_tag {
	my $db = shift;
	my $film_id = shift || &film_choose($db);
	&tag($db, {film_id=>$film_id});
	return;
}

# Locate where this film is
sub film_locate {
	my $db = shift;
	my $film_id = shift || &film_choose($db);

	if (my $archiveid = &lookupval({db=>$db, col=>'archive_id', table=>'FILM', where=>{film_id=>$film_id}})) {
		my $archive = &lookupval({db=>$db, col=>"concat(name, ' (', location, ')') as archive", table=>'ARCHIVE', where=>{archive_id=> $archiveid}});
		print "Film #${film_id} is in $archive\n";
	} else {
		print "The location of film #${film_id} is unknown\n";
	}
	return;
}

# Add a new bulk film to the database
sub film_bulk {
	my $db = shift;
	my %data;
	$data{filmstock_id} = &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add, required=>1});
	$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add, required=>1});
	$data{batch} = &prompt({prompt=>'Film batch number'});
	$data{expiry} = &prompt({prompt=>'Film expiry date', type=>'date'});
	$data{purchase_date} = &prompt({default=>&today($db), prompt=>'Purchase date', type=>'date'});
	$data{cost} = &prompt({prompt=>'Purchase price', type=>'decimal'});
	$data{source} = &prompt({prompt=>'Where was this bulk film purchased from?'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILM_BULK'});
}

# Write out a text file with the scans from the film
sub film_annotate {
	my $db = shift;
	my $film_id = shift || &film_choose($db);
	&annotatefilm($db, $film_id);
	return;
}

# List the films that are currently in stock
sub film_stocks {
	my $db = shift;
	my $data = &lookupcol({db=>$db, table=>'view_film_stocks'});
	my $rows = @$data;
	if ($rows >= 0) {
		print "Films currently in stock:\n";
		foreach my $row (@$data) {
			print "\t$row->{qty}  x\t$row->{film}\n";
		}
		if (&prompt({default=>'yes', prompt=>'Load a film into a camera now?', type=>'boolean'})) {
			&film_load($db);
		}
	} else {
		print "No films currently in stock\n";
	}
	return;
}

# List films that are currently loaded into cameras
sub film_current {
	my $db = shift;
	&printlist({db=>$db, msg=>"current films", table=>'current_films'});
	return;
}

sub film_choose {
	my $db = shift;
	while (1) {
		my $film_id = &prompt({prompt=>'Enter film ID if you know it, or leave blank to choose', type=>'integer'});
		if ($film_id ne '') {
			my $info = &lookupval({db=>$db, col=>'notes', table=>'FILM', where=>{film_id=>$film_id}});
			return $film_id if &prompt({default=>'yes', prompt=>"This film is entitled $info. Is this the right film?", type=>'boolean'})
		} else {
			my %where;
			#narrow by format
			if (&prompt({default=>'no', prompt=>'Narrow search by film format?', type=>'boolean'})) {
				$where{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT'});
			}
			if (&prompt({default=>'no', prompt=>'Narrow search by filmstock?', type=>'boolean'})) {
				$where{filmstock_id} = &listchoices({db=>$db, table=>'choose_filmstock'});
			}
			if (&prompt({default=>'no', prompt=>'Narrow search by the camera the film was loaded into?', type=>'boolean'})) {
				$where{camera_id} = &listchoices({db=>$db, table=>'choose_camera'});
			}
			#listchoices
			$where{notes} = {'!=',undef};
			my $thinwhere = &thin(\%where);
			return &listchoices({db=>$db, cols=>['film_id as id', 'notes as opt'], table=>'FILM', where=>$thinwhere, required=>1});
		}
	}
	return;
}

# Add a new camera to the database
sub camera_add {
	my $db = shift;

	# Gather data from user
	my $datahr = &camera_prompt($db);
	my %data = %$datahr;

	# Insert new record into DB
	my $cameraid = &newrecord({db=>$db, data=>\%data, table=>'CAMERA'});

	# Now we have a camera ID, we can insert rows in auxiliary tables
	if (&prompt({default=>'yes', prompt=>'Add exposure programs for this camera?', type=>'boolean'})) {
		&camera_exposureprogram($db, $cameraid);
	}

	if (&prompt({default=>'yes', prompt=>'Add metering modes for this camera?', type=>'boolean'})) {
		if ($data{metering}) {
			&camera_meteringmode($db, $cameraid);
		} else {
			my %mmdata = ('camera_id' => $cameraid, 'metering_mode_id' => 0);
			&newrecord({db=>$db, data=>\%mmdata, table=>'METERING_MODE_AVAILABLE'});
		}
	}

	if (&prompt({default=>'yes', prompt=>'Add shutter speeds for this camera?', type=>'boolean'})) {
		&camera_shutterspeeds($db, $cameraid);
	}

	if (&prompt({default=>'yes', prompt=>'Add accessory compatibility for this camera?', type=>'boolean'})) {
		&camera_accessory($db, $cameraid);
	}
	return $cameraid;
}

# Edit an existing camera
sub camera_edit {
	my $db = shift;
	my $camera_id = shift || &listchoices({db=>$db, table=>'choose_camera', required=>1});
	my $existing = &lookupcol({db=>$db, table=>'CAMERA', where=>{camera_id=>$camera_id}});
	$existing = @$existing[0];

	# Gather data from user
	my $data = &camera_prompt($db, $existing);

	# Compare new and old data to find changed fields
	my $changes = &hashdiff($existing, $data);

	# Update the DB
	return &updaterecord({db=>$db, data=>$changes, table=>'CAMERA', where=>"camera_id=$camera_id"});
}

sub camera_prompt {
	my $db = shift;
	my $defaults = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db, default=>$$defaults{manufacturer_id}});
	$data{model} = &prompt({prompt=>'What model is the camera?', required=>1, default=>$$defaults{model}});
	$data{fixed_mount} = &prompt({prompt=>'Does this camera have a fixed lens?', type=>'boolean', required=>1, default=>$$defaults{fixed_mount}});
	if (defined($data{fixed_mount}) && $data{fixed_mount} == 1 && !defined($$defaults{lens_id})) {
		# Get info about lens
		print "Please enter some information about the lens\n";
		$data{lens_id} = &lens_add($db);
	} else {
		$data{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{purpose=>'Camera'}, inserthandler=>\&mount_add, default=>$$defaults{mount_id}});
	}
	$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add, required=>1, default=>$$defaults{format_id}});
	$data{focus_type_id} = &listchoices({db=>$db, cols=>['focus_type_id as id', 'focus_type as opt'], table=>'FOCUS_TYPE', inserthandler=>\&focustype_add, default=>$$defaults{focus_type_id}});
	$data{metering} = &prompt({prompt=>'Does this camera have metering?', type=>'boolean', default=>$$defaults{metering}});
	if (defined($data{metering}) && $data{metering} == 1) {
		$data{coupled_metering} = &prompt({prompt=>'Is the metering coupled?', type=>'boolean', default=>$$defaults{coupled_metering}});
		$data{metering_type_id} = &listchoices({db=>$db, cols=>['metering_type_id as id', 'metering as opt'], table=>'METERING_TYPE', inserthandler=>\&meteringtype_add, default=>$$defaults{metering_type_id}});
		$data{meter_min_ev} = &prompt({prompt=>'What\'s the lowest EV the meter can handle?', type=>'integer', default=>$$defaults{meter_min_ev}});
		$data{meter_max_ev} = &prompt({prompt=>'What\'s the highest EV the meter can handle?', type=>'integer', default=>$$defaults{meter_max_ev}});
	}
	$data{body_type_id} = &listchoices({db=>$db, cols=>['body_type_id as id', 'body_type as opt'], table=>'BODY_TYPE', inserthandler=>\&camera_addbodytype, default=>$$defaults{body_type_id}});
	$data{weight} = &prompt({prompt=>'What does it weigh? (g)', type=>'integer', default=>$$defaults{weight}});
	$data{acquired} = &prompt({default=>$$defaults{acquired}//&today($db), prompt=>'When was it acquired?', type=>'date'});
	$data{cost} = &prompt({prompt=>'What did the camera cost?', type=>'decimal', default=>$$defaults{cost}});
	$data{introduced} = &prompt({prompt=>'What year was the camera introduced?', type=>'integer', default=>$$defaults{introduced}});
	$data{discontinued} = &prompt({prompt=>'What year was the camera discontinued?', type=>'integer', default=>$$defaults{discontinued}});
	$data{serial} = &prompt({prompt=>'What is the camera\'s serial number?', default=>$$defaults{serial}});
	$data{datecode} = &prompt({prompt=>'What is the camera\'s datecode?', default=>$$defaults{datecode}});
	$data{manufactured} = &prompt({prompt=>'When was the camera manufactured?', type=>'integer', default=>$$defaults{manufactured}});
	$data{own} = &prompt({default=>$$defaults{own}//'yes', prompt=>'Do you own this camera?', type=>'boolean'});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add, default=>$$defaults{negative_size_id}});
	$data{shutter_type_id} = &listchoices({db=>$db, cols=>['shutter_type_id as id', 'shutter_type as opt'], table=>'SHUTTER_TYPE', inserthandler=>\&shuttertype_add, default=>$$defaults{shutter_type_id}});
	$data{shutter_model} = &prompt({prompt=>'What is the shutter model?', default=>$$defaults{shutter_model}});
	$data{cable_release} = &prompt({prompt=>'Does this camera have a cable release?', type=>'boolean', default=>$$defaults{cable_release}});
	$data{viewfinder_coverage} = &prompt({prompt=>'What is the viewfinder coverage?', type=>'integer', default=>$$defaults{viewfinder_coverage}});
	$data{power_drive} = &prompt({prompt=>'Does this camera have power drive?', type=>'boolean', default=>$$defaults{power_drive}});
	if (defined($data{power_drive}) && $data{power_drive} == 1) {
		$data{continuous_fps} = &prompt({prompt=>'How many frames per second can this camera manage?', type=>'decimal', default=>$$defaults{continuous_fps}});
	}
	$data{video} = &prompt({default=>$$defaults{video}//'no', prompt=>'Does this camera have a video/movie function?', type=>'boolean'});
	$data{digital} = &prompt({default=>$$defaults{digital}//'no', prompt=>'Is this a digital camera?', type=>'boolean'});
	$data{battery_qty} = &prompt({prompt=>'How many batteries does this camera take?', type=>'integer', default=>$$defaults{battery_qty}});
	if (defined($data{battery_qty}) && $data{battery_qty} > 0) {
		$data{battery_type} = &listchoices({db=>$db, keyword=>'battery type', table=>'choose_battery', inserthandler=>\&battery_add, default=>$$defaults{battery_type}});
	}
	$data{notes} = &prompt({prompt=>'Additional notes', default=>$$defaults{notes}});
	$data{source} = &prompt({prompt=>'Where was the camera acquired from?', default=>$$defaults{source}});
	$data{min_shutter} = &prompt({prompt=>'What\'s the fastest shutter speed?', default=>$$defaults{min_shutter}});
	$data{max_shutter} = &prompt({prompt=>'What\'s the slowest shutter speed?', default=>$$defaults{max_shutter}});
	$data{bulb} = &prompt({prompt=>'Does the camera have bulb exposure mode?', type=>'boolean', default=>$$defaults{bulb}});
	$data{time} = &prompt({prompt=>'Does the camera have time exposure mode?', type=>'boolean', default=>$$defaults{time}});
	$data{min_iso} = &prompt({prompt=>'What\'s the lowest ISO the camera can do?', type=>'integer', default=>$$defaults{min_iso}});
	$data{max_iso} = &prompt({prompt=>'What\'s the highest ISO the camera can do?', type=>'integer', default=>$$defaults{max_iso}});
	$data{af_points} = &prompt({prompt=>'How many autofocus points does the camera have?', type=>'integer', default=>$$defaults{af_points}});
	$data{int_flash} = &prompt({prompt=>'Does the camera have an internal flash?', type=>'boolean', default=>$$defaults{int_flash}});
	if (defined($data{int_flash}) && $data{int_flash} == 1) {
		$data{int_flash_gn} = &prompt({prompt=>'What\'s the guide number of the internal flash?', type=>'integer', default=>$$defaults{int_flash_gn}});
	}
	$data{ext_flash} = &prompt({prompt=>'Does the camera support an external flash?', type=>'boolean', default=>$$defaults{ext_flash}});
	if ($data{ext_flash} == 1) {
		$data{pc_sync} = &prompt({prompt=>'Does the camera have a PC sync socket?', type=>'boolean', default=>$$defaults{pc_sync}});
		$data{hotshoe} = &prompt({prompt=>'Does the camera have a hot shoe?', type=>'boolean', default=>$$defaults{hotshoe}});
	}
	if ($data{int_flash} == 1 || $data{ext_flash} == 1) {
		$data{coldshoe} = &prompt({prompt=>'Does the camera have a cold/accessory shoe?', type=>'boolean', default=>$$defaults{coldshoe}});
		$data{x_sync} = &prompt({prompt=>'What\'s the X-sync speed?', type=>'text', default=>$$defaults{x_sync}});
		$data{flash_metering} = &listchoices({db=>$db, table=>'choose_flash_protocol', inserthandler=>\&flashprotocol_add, default=>$$defaults{flash_metering}});
	}
	$data{condition_id} = &listchoices({db=>$db, keyword=>'condition', cols=>['condition_id as id', 'name as opt'], table=>'`CONDITION`', default=>$$defaults{condition_id}});
	$data{dof_preview} = &prompt({prompt=>'Does this camera have a depth-of-field preview feature?', type=>'boolean', default=>$$defaults{dof_preview}});
	$data{tripod} = &prompt({prompt=>'Does this camera have a tripod bush?', type=>'boolean', default=>$$defaults{tripod}});
	if (defined($data{mount_id})) {
		$data{display_lens} = &listchoices({db=>$db, table=>'choose_display_lens', where=>{mount_id=>$data{mount_id}}, default=>$$defaults{display_lens}, skipok=>1});
	}
	return \%data;
}

# Add accessory compatibility info to a camera
sub camera_accessory {
	my $db = shift;
	my $cameraid = shift || &listchoices({db=>$db, table=>'choose_camera', required=>1});
	while (1) {
		my %compatdata;
		$compatdata{accessory_id} = &listchoices({db=>$db, table=>'choose_accessory'});
		$compatdata{camera_id} = $cameraid;
		&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT', silent=>1});
		last if (!&prompt({default=>'yes', prompt=>'Add more accessory compatibility info?', type=>'boolean'}));
	}
	return;
}

# Add available shutter speed info to a camera
sub camera_shutterspeeds {
	my $db = shift;
	my $cameraid = shift || &listchoices({db=>$db, table=>'choose_camera', required=>1});
	my $min_shutter_speed = &listchoices({db=>$db, keyword=>'min (fastest) shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where shutter_speed not in ('B', 'T') and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where camera_id=$cameraid) order by duration", type=>'text', insert_handler=>\&shutterspeed_add, required=>1});
	&newrecord({db=>$db, data=>{camera_id=>$cameraid, shutter_speed=>$min_shutter_speed}, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});
	my $min_shutter_speed_duration = &duration($min_shutter_speed);
	my $max_shutter_speed = &listchoices({db=>$db, keyword=>'max (slowest) shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where shutter_speed not in ('B', 'T') and duration > $min_shutter_speed_duration and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where camera_id=$cameraid) order by duration", type=>'text', insert_handler=>\&shutterspeed_add, required=>1});
	my $max_shutter_speed_duration = &duration($max_shutter_speed);
	&newrecord({db=>$db, data=>{camera_id=>$cameraid, shutter_speed=>$max_shutter_speed}, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});

	while (1) {
		my %shutterdata;
		$shutterdata{shutter_speed} = &listchoices({db=>$db, keyword=>'shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where shutter_speed not in ('B', 'T') and duration > $min_shutter_speed_duration and duration < $max_shutter_speed_duration and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where camera_id=$cameraid) order by duration", type=>'text', insert_handler=>\&shutterspeed_add, required=>1});
		$shutterdata{camera_id} = $cameraid;
		&newrecord({db=>$db, data=>\%shutterdata, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});
		last if (!&prompt({default=>'yes', prompt=>'Add another shutter speed?', type=>'boolean'}));
	}
	return;
}

# Add available exposure program info to a camera
sub camera_exposureprogram {
	my $db = shift;
	my $cameraid = shift || &listchoices({db=>$db, table=>'choose_camera', required=>1});
	my $exposureprograms = &lookupcol({db=>$db, table=>'EXPOSURE_PROGRAM'});
	foreach my $exposureprogram (@$exposureprograms) {
		# Skip 'creative' AE modes
		next if $exposureprogram->{exposure_program_id} == 5;
		next if $exposureprogram->{exposure_program_id} == 6;
		next if $exposureprogram->{exposure_program_id} == 7;
		next if $exposureprogram->{exposure_program_id} == 8;
		if (&prompt({default=>'no', prompt=>"Does this camera have $exposureprogram->{exposure_program} exposure program?", type=>'boolean'})) {
			my %epdata = ('camera_id' => $cameraid, 'exposure_program_id' => $exposureprogram->{exposure_program_id});
			&newrecord({db=>$db, data=>\%epdata, table=>'EXPOSURE_PROGRAM_AVAILABLE', silent=>1});
			last if $exposureprogram->{exposure_program_id} == 0;
		}
	}
	return;
}

# Add available metering mode info to a camera
sub camera_meteringmode {
	my $db = shift;
	my $cameraid = shift || &listchoices({db=>$db, table=>'choose_camera', required=>1});
	my $meteringmodes = &lookupcol({db=>$db, table=>'METERING_MODE'});
	foreach my $meteringmode (@$meteringmodes) {
		if (&prompt({default=>'no', prompt=>"Does this camera have $meteringmode->{metering_mode} metering?", type=>'boolean'})) {
			my %mmdata = ('camera_id' => $cameraid, 'metering_mode_id' => $meteringmode->{metering_mode_id});
			&newrecord({db=>$db, data=>\%mmdata, table=>'METERING_MODE_AVAILABLE', silent=>1});
			last if $meteringmode->{metering_mode_id} == 0;
		}
	}
	return;
}

# Associate a camera with a lens for display purposes
sub camera_displaylens {
	my $db = shift;
	my %data;
	my $camera_id = shift || &listchoices({db=>$db, keyword=>'camera', table=>'choose_camera', where=>{mount_id=>{'!=', undef}}, required=>1 });
	my $mount = &lookupval({db=>$db, col=>'mount_id', table=>'CAMERA', where=>{camera_id=>$camera_id}});
	$data{display_lens} = &listchoices({db=>$db, table=>'choose_display_lens', where=>{camera_id=>[$camera_id, undef], mount_id=>$mount}, default=>&lookupval({db=>$db, col=>'display_lens', table=>'CAMERA', where=>{camera_id=>$camera_id}})});
	return &updaterecord({db=>$db, data=>\%data, table=>'CAMERA', where=>"camera_id=$camera_id"});
}

# Sell a camera
sub camera_sell {
	my $db = shift;
	my $cameraid = shift || &listchoices({db=>$db, table=>'choose_camera'});
	my %data;
	$data{own} = 0;
	$data{lost} = &prompt({default=>&today($db), prompt=>'What date was this camera sold?', type=>'date'});
	$data{lost_price} = &prompt({prompt=>'How much did this camera sell for?', type=>'decimal'});
	&updaterecord({db=>$db, data=>\%data, table=>'CAMERA', where=>"camera_id=$cameraid"});
	&unsetdisplaylens({db=>$db, camera_id=>$cameraid});
	if (&lookupval({db=>$db, col=>'fixed_mount', table=>'CAMERA', where=>{camera_id=>$cameraid}})) {
		my $lensid = &lookupval({db=>$db, col=>'lens_id', table=>'CAMERA', where=>{camera_id=>$cameraid}});
		if ($lensid) {
			my %lensdata;
			$lensdata{own} = 0;
			$lensdata{lost} = $data{lost};
			$lensdata{lost_price} = 0;
			&updaterecord({db=>$db, data=>\%lensdata, table=>'LENS', where=>"lens_id=$lensid"});
		}
	}
	return;
}

# Repair a camera
sub camera_repair {
	my $db = shift;
	my %data;
	$data{camera_id} = shift || &listchoices({db=>$db, table=>'choose_camera'});
	$data{date} = &prompt({default=>&today($db), prompt=>'What date was this camera repaired?', type=>'date'});
	$data{summary} = &prompt({prompt=>'Short summary of repair'});
	$data{description} = &prompt({prompt=>'Longer description of repair'});
	return &newrecord({db=>$db, data=>\%data, table=>'REPAIR'});
}

# Show information about a camera
sub camera_info {
	my $db = shift;

	# Choose camera
	my $camera_id = &listchoices({db=>$db, table=>'choose_camera', required=>1});

	# Get camera data
	my $cameradata = &lookupcol({db=>$db, table=>'info_camera', where=>{'`Camera ID`'=>$camera_id}});

	# Show compatible accessories
	my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{camera_id=>$camera_id}});
	${@$cameradata[0]}{'Accessories'} = $accessories;

	# Show compatible lenses
	my $lenses = &lookuplist({db=>$db, col=>'lens', table=>'cameralens_compat', where=>{camera_id=>$camera_id}});
	${@$cameradata[0]}{'Lenses'} = $lenses;

	print Dump($cameradata);
	return;
}

# Choose a camera based on several criteria
sub camera_choose {
	my $db = shift;
	my %where;
	$where{manufacturer_id} = &choose_manufacturer({db=>$db});
	$where{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT'});
	$where{bulb} = &prompt({prompt=>'Do you need Bulb (B) shutter speed?', type=>'boolean'});
	$where{time} = &prompt({prompt=>'Do you need Time (T) shutter speed?', type=>'boolean'});
	$where{fixed_mount} = &prompt({prompt=>'Do you need a camera with an interchangeable lens?', type=>'boolean'});
	if ($where{fixed_mount} && $where{fixed_mount} != 1) {
		$where{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}});
	}
	$where{focus_type_id} = &listchoices({db=>$db, cols=>['focus_type_id as id', 'focus_type as opt'], table=>'FOCUS_TYPE', 'integer'});
	$where{metering} = &prompt({prompt=>'Do you need a camera with metering?', type=>'boolean'});
	if ($where{metering} && $where{metering} == 1) {
		$where{coupled_metering} = &prompt({prompt=>'Do you need coupled metering?', type=>'boolean'});
		$where{metering_type_id} = &listchoices({db=>$db, cols=>['metering_type_id as id', 'metering as opt'], table=>'METERING_TYPE'});
	}
	$where{body_type_id} = &listchoices({db=>$db, cols=>['body_type_id as id', 'body_type as opt'], table=>'BODY_TYPE'});
	$where{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE'});
	$where{cable_release} = &prompt({prompt=>'Do you need a camera with cable release?', type=>'boolean'});
	$where{power_drive} = &prompt({prompt=>'Do you need a camera with power drive?', type=>'boolean'});
	$where{int_flash} = &prompt({prompt=>'Do you need a camera with internal flash?', type=>'boolean'});
	$where{ext_flash} = &prompt({prompt=>'Do you need a camera that supports an external flash?', type=>'boolean'});
	if ($where{ext_flash} && $where{ext_flash} == 1) {
		$where{pc_sync} = &prompt({prompt=>'Do you need a PC sync socket?', type=>'boolean'});
		$where{hotshoe} = &prompt({prompt=>'Do you need a hot shoe?', type=>'boolean'});
	}
	if (($where{int_flash} && $where{int_flash} == 1) || ($where{ext_flash} && $where{ext_flash} == 1)) {
		$where{coldshoe} = &prompt({prompt=>'Do you need a cold/accessory shoe?', type=>'boolean'});
		$where{flash_metering} = &listchoices({db=>$db, table=>'choose_flash_protocol'});
	}
	$where{dof_preview} = &prompt({prompt=>'Do you need a depth-of-field preview feature?', type=>'boolean'});
	$where{tripod} = &prompt({prompt=>'Do you need a tripod bush?', type=>'boolean'});

	my $thinwhere = &thin(\%where);
	&printlist({db=>$db, msg=>"cameras that match your criteria", table=>'camera_chooser', where=>$thinwhere});
	return;
}

# Add a new negative to the database as part of a film
sub negative_add {
	my $db = shift;
	my %data;
	$data{film_id} = &film_choose($db);
	if (!&lookupval({db=>$db, col=>'camera_id', table=>'FILM', where=>{film_id=>$data{film_id}}})) {
		print 'Film must be loaded into a camera before you can add negatives\n';
		if (&prompt({default=>'yes', prompt=>'Load film into a camera now?', type=>'boolean'})) {
			&film_load($db, $data{film_id});
		} else {
			return;
		}
	}
	$data{frame} = &prompt({prompt=>'Frame number'});
	$data{description} = &prompt({prompt=>'Caption'});
	$data{date} = &prompt({default=>&today($db), prompt=>'What date was this negative taken?', type=>'date'});
	$data{lens_id} = &listchoices({db=>$db, keyword=>'lens', table=>'choose_lens_by_film', where=>{film_id=>$data{film_id}}});
	$data{shutter_speed} = &listchoices({db=>$db, keyword=>'shutter speed', table=>'choose_shutter_speed_by_film', where=>{film_id=>$data{film_id}}, type=>'text'});
	$data{aperture} = &prompt({prompt=>'Aperture', type=>'decimal'});
	my $filter_dia = 0;
	if ($data{lens_id}) {
		$filter_dia = &lookupval({db=>$db, col=>'if(filter_thread, filter_thread, 0)', table=>'LENS', where=>{lens_id=>$data{lens_id}}});
	}
	$data{filter_id} = &listchoices({db=>$db, table=>'choose_filter', where=>{'thread'=>{'>=', $filter_dia}}, inserthandler=>\&filter_add, skipok=>1, autodefault=>0});
	$data{teleconverter_id} = &listchoices({db=>$db, keyword=>'teleconverter', table=>'choose_teleconverter_by_film', where=>{film_id=>$data{film_id}}, inserthandler=>\&teleconverter_add, skipok=>1, autodefault=>0});
	$data{notes} = &prompt({prompt=>'Extra notes'});
	$data{mount_adapter_id} = &listchoices({db=>$db, table=>'choose_mount_adapter_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
	$data{focal_length} = &prompt({default=>&lookupval({db=>$db, col=>'min_focal_length', table=>'LENS', where=>{lens_id=>$data{'lens_id'}}}), prompt=>'Focal length', type=>'integer'});
	$data{latitude} = &prompt({prompt=>'Latitude', type=>'decimal'});
	$data{longitude} = &prompt({prompt=>'Longitude', type=>'decimal'});
	$data{flash} = &prompt({default=>'no', prompt=>'Was flash used?', type=>'boolean'});
	$data{metering_mode} = &listchoices({db=>$db, cols=>['metering_mode_id as id', 'metering_mode as opt'], table=>'METERING_MODE'});
	$data{exposure_program} = &listchoices({db=>$db, cols=>['exposure_program_id as id', 'exposure_program as opt'], table=>'EXPOSURE_PROGRAM'});
	$data{photographer_id} = &listchoices({db=>$db, keyword=>'photographer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
	if (&prompt({prompt=>'Is this negative duplicated from another?', type=>'boolean', default=>'no'})) {
		$data{copy_of} = &chooseneg({db=>$db, oktoreturnundef=>1});
	}
	return &newrecord({db=>$db, data=>\%data, table=>'NEGATIVE'});
}

# Bulk add multiple negatives to the database as part of a film
sub negative_bulkadd {
	my $db = shift;
	my %data;
	$data{film_id} = shift || &film_choose($db);
	my $num = &prompt({prompt=>'How many frames to add?', type=>'integer'});
	if (&prompt({default=>'no', prompt=>"Add any other attributes to all $num negatives?", type=>'boolean'})) {
		$data{description} = &prompt({prompt=>'Caption'});
		$data{date} = &prompt({default=>&today($db), prompt=>'What date was this negative taken?', type=>'date'});
		$data{lens_id} = &listchoices({db=>$db, keyword=>'lens', table=>'choose_lens_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
		$data{shutter_speed} = &listchoices({db=>$db, keyword=>'shutter speed', table=>'choose_shutter_speed_by_film', where=>{film_id=>$data{film_id}}});
		$data{aperture} = &prompt({prompt=>'Aperture', type=>'decimal'});
		$data{filter_id} = &listchoices({db=>$db, table=>'choose_filter', inserthandler=>\&filter_add, skipok=>1, autodefault=>0});
		$data{teleconverter_id} = &listchoices({db=>$db, keyword=>'teleconverter', table=>'choose_teleconverter_by_film', where=>{film_id=>$data{film_id}}, inserthandler=>\&teleconverter_add, skipok=>1, autodefault=>0});
		$data{notes} = &prompt({prompt=>'Extra notes'});
		$data{mount_adapter_id} = &listchoices({db=>$db, table=>'choose_mount_adapter_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
		$data{focal_length} = &prompt({default=>&lookupval({db=>$db, col=>'min_focal_length', table=>'LENS', where=>{lens_id=>$data{lens_id}}}), prompt=>'Focal length', type=>'integer'});
		$data{latitude} = &prompt({prompt=>'Latitude', type=>'decimal'});
		$data{longitude} = &prompt({prompt=>'Longitude', type=>'decimal'});
		$data{flash} = &prompt({default=>'no', prompt=>'Was flash used?', type=>'boolean'});
		$data{metering_mode} = &listchoices({db=>$db, cols=>['metering_mode_id as id', 'metering_mode as opt'], table=>'METERING_MODE'});
		$data{exposure_program} = &listchoices({db=>$db, cols=>['exposure_program_id as id', 'exposure_program as opt'], table=>'EXPOSURE_PROGRAM'});
		$data{photographer_id} = &listchoices({db=>$db, keyword=>'photographer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
	}

	# Delete empty strings from data hash
	my $thindata = &thin(\%data);

	# Build query
	my $sql = SQL::Abstract->new;

	# Final confirmation
	if (!&prompt({default=>'yes', prompt=>'Proceed?', type=>'boolean'})) {
		print "Aborted!\n";
		return;
	}

	# Execute query
	for my $i (1..$num) {
		# Now inside the loop, add an incremented frame number for each neg
		$$thindata{frame} = $i;

		# Create a new row
		&newrecord({db=>$db, data=>\%$thindata, table=>'NEGATIVE', silent=>1});
	}

	print "Inserted $num negatives into film #$$thindata{film_id}\n";
	return;
}

# Show information about a negative
sub negative_info {
	my $db = shift;
	my $negative_id = shift || &chooseneg({db=>$db});
	my $negativedata = &lookupcol({db=>$db, table=>'info_negative', where=>{'`Negative ID`'=>$negative_id}});
	print Dump($negativedata);
	return;
}

# Find all prints made from a negative
sub negative_prints {
	my $db = shift;
	my $neg_id = &chooseneg({db=>$db});
	&printlist({db=>$db, msg=>"prints from negative $neg_id", cols=>'Print as id, concat(Size, \' - \', Location) as opt', table=>'info_print', where=>{'`Negative ID`'=>$neg_id}});
	return;
}

# Write EXIF tags to scans from a negative
sub negative_tag {
        my $db = shift;
	my $neg_id = &chooseneg({db=>$db});
        &tag($db, {negative_id=>$neg_id});
        return;
}

# Add a new lens to the database
sub lens_add {
	my $db = shift;

	# Gather data from user
	my $datahr = &lens_prompt($db);
	my %data = %$datahr;

	my $lensid = &newrecord({db=>$db, data=>\%data, table=>'LENS'});

	if (&prompt({default=>'yes', prompt=>'Add accessory compatibility for this lens?', type=>'boolean'})) {
		&lens_accessory($db, $lensid);
	}
	return $lensid;
}

# Edit an existing lens
sub lens_edit {
	my $db = shift;
	my $lensid = shift || &listchoices({db=>$db, table=>'choose_lens', required=>1});
	my $existing = &lookupcol({db=>$db, table=>'LENS', where=>{lens_id=>$lensid}});
	$existing = @$existing[0];

	# Gather data from user
	my $data = &lens_prompt($db, $existing);

	# Compare new and old data to find changed fields
	my $changes = &hashdiff($existing, $data);

	# Update the DB
	return &updaterecord({db=>$db, data=>$changes, table=>'LENS', where=>"lens_id=$lensid"});
}

sub lens_prompt {
	my $db = shift;
	my $defaults = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db, default=>$$defaults{manufacturer_id}});
	$data{model} = &prompt({prompt=>'What is the lens model?', default=>$$defaults{model}});
	$data{zoom} = &prompt({prompt=>'Is this a zoom lens?', type=>'boolean', default=>$$defaults{zoom}//&parselensmodel($data{model}, 'zoom')});
	if ($data{zoom} == 0) {
		$data{min_focal_length} = &prompt({prompt=>'What is the focal length?', type=>'integer', default=>$$defaults{min_focal_length}//&parselensmodel($data{model}, 'minfocal')});
		$data{max_focal_length} = $data{min_focal_length};
		$data{nominal_min_angle_diag} = &prompt({prompt=>'What is the diagonal angle of view?', type=>'integer', default=>$$defaults{nominal_min_angle_diag}});
		$data{nominal_max_angle_diag} = $data{nominal_min_angle_diag};
	} else {
		$data{min_focal_length} = &prompt({prompt=>'What is the minimum focal length?', type=>'integer', default=>$$defaults{min_focal_length}//&parselensmodel($data{model}, 'minfocal')});
		$data{max_focal_length} = &prompt({prompt=>'What is the maximum focal length?', type=>'integer', default=>$$defaults{max_focal_length}//&parselensmodel($data{model}, 'maxfocal')});
		$data{nominal_min_angle_diag} = &prompt({prompt=>'What is the minimum diagonal angle of view?', type=>'integer', default=>$$defaults{nominal_min_angle_diag}});
		$data{nominal_max_angle_diag} = &prompt({prompt=>'What is the maximum diagonal angle of view?', type=>'integer', default=>$$defaults{nominal_max_angle_diag}});
	}
	$data{fixed_mount} = &prompt({prompt=>'Does this lens have a fixed mount?', type=>'boolean', default=>$$defaults{fixed_mount}//'no'});
	if ($data{fixed_mount} == 0) {
		$data{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', inserthandler=>\&mount_add, default=>$$defaults{mount_id}});
		$data{weight} = &prompt({prompt=>'What is the weight of the lens? (g)', type=>'integer', default=>$$defaults{weight}});
		$data{cost} = &prompt({prompt=>'How much did this lens cost?', type=>'decimal', default=>$$defaults{cost}});
		$data{length} = &prompt({prompt=>'How long is this lens? (mm)', type=>'integer', default=>$$defaults{length}});
		$data{diameter} = &prompt({prompt=>'How wide is this lens? (mm)', type=>'integer', default=>$$defaults{diameter}});
	}
	$data{max_aperture} = &prompt({prompt=>'What is the largest lens aperture?', type=>'decimal', default=>$$defaults{max_aperture}//&parselensmodel($data{model}, 'aperture')});
	$data{min_aperture} = &prompt({prompt=>'What is the smallest lens aperture?', type=>'decimal', default=>$$defaults{min_aperture}});
	$data{closest_focus} = &prompt({prompt=>'How close can the lens focus? (cm)', type=>'integer', default=>$$defaults{closest_focus}});
	$data{elements} = &prompt({prompt=>'How many elements does the lens have?', type=>'integer', default=>$$defaults{elements}});
	$data{groups} = &prompt({prompt=>'How many groups are these elements in?', type=>'integer', default=>$$defaults{groups}});
	$data{aperture_blades} = &prompt({prompt=>'How many aperture blades does the lens have?', type=>'integer', default=>$$defaults{aperture_blades}});
	$data{autofocus} = &prompt({prompt=>'Does this lens have autofocus?', type=>'boolean', default=>$$defaults{autofocus}});
	$data{filter_thread} = &prompt({prompt=>'What is the diameter of the filter thread? (mm)', type=>'decimal', default=>$$defaults{filter_thread}});
	$data{magnification} = &prompt({prompt=>'What is the maximum magnification possible with this lens?', type=>'decimal', default=>$$defaults{magnification}});
	$data{url} = &prompt({prompt=>'Informational URL for this lens', default=>$$defaults{url}});
	$data{serial} = &prompt({prompt=>'What is the serial number of the lens?', default=>$$defaults{serial}});
	$data{date_code} = &prompt({prompt=>'What is the date code of the lens?', default=>$$defaults{date_code}});
	$data{introduced} = &prompt({prompt=>'When was this lens introduced?', type=>'integer', default=>$$defaults{introduced}});
	$data{discontinued} = &prompt({prompt=>'When was this lens discontinued?', type=>'integer', default=>$$defaults{discontinued}});
	$data{manufactured} = &prompt({prompt=>'When was this lens manufactured?', type=>'integer', default=>$$defaults{manufactured}});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add, default=>$$defaults{negative_size_id}});
	$data{acquired} = &prompt({prompt=>'When was this lens acquired?', type=>'date', default=>$$defaults{acquired}//&today($db)});
	$data{notes} = &prompt({prompt=>'Notes', default=>$$defaults{notes}});
	$data{own} = &prompt({prompt=>'Do you own this lens?', type=>'boolean', default=>$$defaults{own}//'yes'});
	$data{source} = &prompt({prompt=>'Where was this lens sourced from?', default=>$$defaults{source}});
	$data{coating} = &prompt({prompt=>'What coating does this lens have?', default=>$$defaults{coating}});
	$data{hood} = &prompt({prompt=>'What is the model number of the suitable hood for this lens?', default=>$$defaults{hood}});
	$data{exif_lenstype} = &prompt({prompt=>'EXIF lens type code', default=>$$defaults{exif_lenstype}});
	$data{rectilinear} = &prompt({prompt=>'Is this a rectilinear lens?', type=>'boolean', default=>$$defaults{rectilinear}//'yes'});
	$data{condition_id} = &listchoices({db=>$db, keyword=>'condition', cols=>['condition_id as id', 'name as opt'], table=>'`CONDITION`', default=>$$defaults{condition_id}});
	$data{image_circle} = &prompt({prompt=>'What is the diameter of the image circle?', type=>'integer', default=>$$defaults{image_circle}});
	$data{formula} = &prompt({prompt=>'Does this lens have a named optical formula?', default=>$$defaults{formula}});
	$data{shutter_model} = &prompt({prompt=>'What shutter does this lens incorporate?', default=>$$defaults{shutter_model}});
	return \%data;
}

# Add accessory compatibility info to a lens
sub lens_accessory {
	my $db = shift;
	my $lensid = shift || &listchoices({db=>$db, table=>'choose_lens', required=>1});
	while (1) {
		my %compatdata;
		$compatdata{accessory_id} = &listchoices({db=>$db, table=>'choose_accessory'});
		$compatdata{lens_id} = $lensid;
		&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT'});
		last if (!&prompt({default=>'yes', prompt=>'Add more accessory compatibility info?', type=>'boolean'}));
	}
	return;
}

# Sell a lens
sub lens_sell {
	my $db = shift;
	my %data;
	my $lensid = shift || &listchoices({db=>$db, table=>'choose_lens', required=>1});
	$data{own} = 0;
	$data{lost} = &prompt({default=>&today($db), prompt=>'What date was this lens sold?', type=>'date'});
	$data{lost_price} = &prompt({prompt=>'How much did this lens sell for?', type=>'decimal'});
	&unsetdisplaylens({db=>$db, lens_id=>$lensid});
	return &updaterecord({db=>$db, data=>\%data, table=>'LENS', where=>"lens_id=$lensid"});
}

# Repair a lens
sub lens_repair {
	my $db = shift;
	my %data;
	$data{lens_id} = shift || &listchoices({db=>$db, table=>'choose_lens', required=>1});
	$data{date} = &prompt({default=>&today($db), prompt=>'What date was this lens repaired?', type=>'date'});
	$data{summary} = &prompt({prompt=>'Short summary of repair'});
	$data{description} = &prompt({prompt=>'Longer description of repair'});
	return &newrecord({db=>$db, data=>\%data, table=>'REPAIR'});
}

# Show information about a lens
sub lens_info {
	my $db = shift;

	# Choose lens
	my $lens_id = &listchoices({db=>$db, table=>'choose_lens', required=>1});

	# Get lens data
	my $lensdata = &lookupcol({db=>$db, table=>'info_lens', where=>{'`Lens ID`'=>$lens_id}});

	# Show compatible accessories
	my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{lens_id=>$lens_id}});
	${@$lensdata[0]}{'Accessories'} = $accessories;

	# Show compatible cameras
	my $cameras = &lookuplist({db=>$db, col=>'camera', table=>'cameralens_compat', where=>{lens_id=>$lens_id}});
	${@$lensdata[0]}{'Cameras'} = $cameras;

	print Dump($lensdata);

	# Generate and print lens statistics
	my $lens = &lookupval({db=>$db, col=>"concat(manufacturer, ' ',model) as opt", table=>'LENS join MANUFACTURER on LENS.manufacturer_id=MANUFACTURER.manufacturer_id', where=>{lens_id=>$lens_id}});
	print "\tShowing statistics for $lens\n";
	my $maxaperture = &lookupval({db=>$db, col=>'max_aperture', table=>'LENS', where=>{lens_id=>$lens_id}});
	my $modeaperture = &lookupval({db=>$db, query=>"select aperture from NEGATIVE where aperture is not null and lens_id=$lens_id group by aperture order by count(aperture) desc limit 1"});
	print "\tThis lens has a maximum aperture of f/$maxaperture but you most commonly use it at f/$modeaperture\n";
	if (&lookupval({db=>$db, col=>'zoom', table=>'LENS', where=>{lens_id=>$lens_id}})) {
		my $minf = &lookupval({db=>$db, col=>'min_focal_length', table=>'LENS', where=>{lens_id=>$lens_id}});
		my $maxf = &lookupval({db=>$db, col=>'max_focal_length', table=>'LENS', where=>{lens_id=>$lens_id}});
		my $meanf = &lookupval({db=>$db, col=>'avg(focal_length)', table=>'NEGATIVE', where=>{lens_id=>$lens_id}});
		print "\tThis is a zoom lens with a range of ${minf}-${maxf}mm, but the average focal length you used is ${meanf}mm\n";
	}
	return;
}

# Add a new print that has been made from a negative
sub print_add {
	my $db = shift;
	my %data;
	my $todo_id = &listchoices({db=>$db, keyword=>'print from the order queue', table=>'choose_todo'});
	if ($todo_id) {
		$data{negative_id} = &lookupval({db=>$db, col=>'negative_id', table=>'TO_PRINT', where=>{id=>$todo_id}});
	} else {
		$data{negative_id} = &chooseneg({db=>$db});
	}
	my $qty = &prompt({default=>1, prompt=>'How many similar prints did you make from this negative?', type=>'integer'});
	print "Enter some data about all the prints in the run:\n" if ($qty > 1);
	$data{date} = &prompt({default=>&today($db), prompt=>'Date that the print was made', type=>'date'});
	$data{paper_stock_id} = &listchoices({db=>$db, keyword=>'paper stock', table=>'choose_paper', inserthandler=>\&paperstock_add});
	$data{height} = &prompt({prompt=>'Height of the print (inches)', type=>'integer'});
	$data{width} = &prompt({prompt=>'Width of the print (inches)', type=>'integer'});
	$data{enlarger_id} = &listchoices({db=>$db, table=>'choose_enlarger', inserthandler=>\&enlarger_add});
	$data{lens_id} = &listchoices({db=>$db, table=>'choose_enlarger_lens'});
	$data{developer_id} = &listchoices({db=>$db, cols=>['developer_id as id', 'name as opt'], table=>'DEVELOPER', where=>{'for_paper'=>1}, inserthandler=>\&developer_add});
	$data{printer_id} = &listchoices({db=>$db, keyword=>'printer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
	my @prints;
	for my $n (1..$qty) {
		print "\nEnter some data about print $n of $qty in this run:\n" if ($qty > 1);
		$data{aperture} = &prompt({prompt=>'Aperture used on enlarging lens', type=>'decimal'});
		$data{exposure_time} = &prompt({prompt=>'Exposure time (s)', type=>'integer'});
		$data{filtration_grade} = &prompt({prompt=>'Filtration grade', type=>'decimal'});
		$data{development_time} = &prompt({default=>'60', prompt=>'Development time (s)', type=>'integer'});
		$data{fine} = &prompt({prompt=>'Is this a fine print?', type=>'boolean'});
		$data{notes} = &prompt({prompt=>'Notes'});
		my $printid = &newrecord({db=>$db, data=>\%data, table=>'PRINT'});
		push @prints, $printid;

		&print_tone($db, $printid) if (&prompt({default=>'no', prompt=>'Did you tone this print?', type=>'boolean'}));
		&print_archive($db, $printid) if (&prompt({default=>'no', prompt=>'Archive this print?', type=>'boolean'}));
	}

	print "\nAdded $qty prints in this run, numbered #$prints[0]-$prints[-1]\n" if ($qty > 1);

	# Mark is as complete in the todo list
	&updaterecord({db=>$db, data=>{printed=>1, print_id=>$prints[-1]}, table=>'TO_PRINT', where=>"id=$todo_id"}) if ($todo_id);

	# Return ID of the last print in the run
	return $prints[-1];
}

# Fulfil an order for a print
sub print_fulfil {
	my $db = shift;
	my %data;
	my $todo_id = &listchoices({db=>$db, keyword=>'print from the queue', table=>'choose_todo', required=>1});
	$data{printed} = &prompt({default=>'yes', prompt=>'Is this print order now fulfilled?', type=>'boolean'});
	$data{print_id} = &prompt({prompt=>'Which print fulfilled this order?', type=>'integer'});
	return &updaterecord({db=>$db, data=>\%data, table=>'TO_PRINT', where=>"id=$todo_id"});
}

# Add toning to a print
sub print_tone {
	my $db = shift;
	my %data;
	my $print_id = shift || &prompt({prompt=>'Which print did you tone?', type=>'integer', required=>1});
	$data{bleach_time} = &prompt({default=>'00:00:00', prompt=>'How long did you bleach for? (HH:MM:SS)', type=>'time'});
	$data{toner_id} = &listchoices({db=>$db, cols=>['toner_id as id', 'toner as opt'], table=>'TONER', inserthandler=>\&toner_add});
	my $dilution1 = &lookupval({db=>$db, col=>'stock_dilution', table=>'TONER', where=>{toner_id=>$data{toner_id}}});
	$data{toner_dilution} = &prompt({default=>$dilution1, prompt=>'What was the dilution of the first toner?'});
	$data{toner_time} = &prompt({prompt=>'How long did you tone for? (HH:MM:SS)', type=>'time'});
	if (&prompt({default=>'no', prompt=>'Did you use a second toner?', type=>'boolean'}) == 1) {
		$data{'2nd_toner_id'} = &listchoices({db=>$db, cols=>['toner_id as id', 'toner as opt'], table=>'TONER', inserthandler=>\&toner_add});
		my $dilution2 = &lookupval({db=>$db, col=>'stock_dilution', table=>'TONER', where=>{toner_id=>$data{'2nd_toner_id'}}});
		$data{'2nd_toner_dilution'} = &prompt({default=>$dilution2, prompt=>'What was the dilution of the second toner?'});
		$data{'2nd_toner_time'} = &prompt({prompt=>'How long did you tone for? (HH:MM:SS)', type=>'time'});
	}
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>"print_id=$print_id"});
}

# Sell a print
sub print_sell {
	my $db = shift;
	my %data;
	my $print_id = shift || &prompt({prompt=>'Which print did you sell?', type=>'integer', required=>1});
	$data{own} = 0;
	$data{location} = &prompt({prompt=>'What happened to the print?'});
	$data{sold_price} = &prompt({prompt=>'What price was the print sold for?', type=>'decimal'});
	&print_unarchive($db, $print_id);
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>"print_id=$print_id"});
}

# Register an order for a print
sub print_order {
	my $db = shift;
	my %data;
	$data{negative_id} = &chooseneg({db=>$db});
	$data{height} = &prompt({prompt=>'Height of the print (inches)', type=>'integer'});
	$data{width} = &prompt({prompt=>'Width of the print (inches)', type=>'integer'});
	$data{recipient} = &prompt({prompt=>'Who is the print for?'});
	$data{added} = &prompt({default=>&today($db), prompt=>'Date that this order was placed', type=>'date'});
	return &newrecord({db=>$db, data=>\%data, table=>'TO_PRINT'});
}

# Add a print to a physical archive
sub print_archive {
	# Archive a print for storage
	my $db = shift;
	my %data;
	my $print_id = shift || &prompt({prompt=>'Which print did you archive?', type=>'integer', required=>1});
	$data{archive_id} = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{'archive_type_id'=>3, 'sealed'=>0}, inserthandler=>\&archive_add, required=>1});
	$data{own} = 1;
	$data{location} = 'Archive';
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>"print_id=$print_id"});
}

# Remove a print from a physical archive
sub print_unarchive {
	# Remove a print from an archive
	my $db = shift;
	my $print_id = shift || &prompt({prompt=>'Which print did you remove from its archive?', type=>'integer', required=>1});
	return &call({db=>$db, procedure=>'print_unarchive', args=>[$print_id]});
}

# Locate a print in an archive
sub print_locate {
	my $db = shift;
	my $print_id = &prompt({prompt=>'Which print do you want to locate?', type=>'integer', required=>1});

	if (my $archiveid = &lookupval({db=>$db, col=>'archive_id', table=>'PRINT', where=>{print_id=>$print_id}})) {
		my $archive = &lookupval({db=>$db, col=>"concat(name, ' (', location, ')') as archive", table=>'ARCHIVE', where=>{archive_id=>$archiveid}});
		print "Print #${print_id} is in $archive\n";
	} elsif (my $location = &lookupval({db=>$db, col=>'location', table=>'PRINT', where=>{print_id=>$print_id}})) {
		if (my $own = &lookupval({db=>$db, col=>'own', table=>'PRINT', where=>{print_id=>$print_id}})) {
			print "Print #${print_id} is in the collection. Location: $location\n";
		} else {
			print "Print #${print_id} is not in the collection. Location: $location\n";
		}
	} else {
		print "The location of print #${print_id} is unknown\n";
	}
	return;
}

# Show details about a print
sub print_info {
	my $db = shift;
	my $print_id = &prompt({prompt=>'Which print do you want info on?', type=>'integer', required=>1});
	my $data = &lookupcol({db=>$db, table=>'info_print', where=>{Print=>$print_id}});
	print Dump($data);
	return;
}

# Exhibit a print in an exhibition
sub print_exhibit {
	my $db = shift;
	my %data;
	$data{print_id} = &prompt({prompt=>'Which print do you want to exhibit?', type=>'integer', required=>1});
	$data{exhibition_id} = &listchoices({db=>$db, cols=>['exhibition_id as id', 'title as opt'], table=>'EXHIBITION', inserthandler=>\&exhibition_add, required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'EXHIBIT'});
}

# Generate text to label a print
sub print_label {
	my $db = shift;
	my $print_id = &prompt({prompt=>'Which print do you want to label?', type=>'integer', required=>1});
	my $data = &lookupcol({db=>$db, table=>'info_print', where=>{Print=>$print_id}});
	my $row = @$data[0];
	print "\t#$row->{'Print'} $row->{'Description'}\n" if ($row->{'Print'} && $row->{Description});
	print "\tPhotographed $row->{'Photo date'}\n" if ($row->{'Photo date'});
	print "\tPrinted $row->{'Print date'}\n" if ($row->{'Print date'});
	print "\tby $row->{Photographer}\n" if ($row->{Photographer});
	return;
}

# Display print todo list
sub print_worklist {
	my $db = shift;
	my $data = &lookupcol({db=>$db, table=>'choose_todo'});

	foreach my $row (@$data) {
		print "\t$row->{opt}\n";
	}
	return;
}

# Write EXIF tags to scans from a print
sub print_tag {
	my $db = shift;
	my $print_id = &prompt({prompt=>'Which print do you want to tag?', type=>'integer', required=>1});
	&tag($db, {print_id=>$print_id});
	return;
}

# Add a new type of photo paper to the database
sub paperstock_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{name} = &prompt({prompt=>'What model is the paper?'});
	$data{resin_coated} = &prompt({prompt=>'Is this paper resin-coated?', type=>'boolean'});
	$data{tonable} = &prompt({prompt=>'Is this paper tonable?', type=>'boolean'});
	$data{colour} = &prompt({prompt=>'Is this a colour paper?', type=>'boolean'});
	$data{finish} = &prompt({prompt=>'What surface finish does this paper have?'});
	return &newrecord({db=>$db, data=>\%data, table=>'PAPER_STOCK'});
}

# Add a new developer to the database
sub developer_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{name} = &prompt({prompt=>'What model is the developer?'});
	$data{for_paper} = &prompt({prompt=>'Is this developer suitable for paper?', type=>'boolean'});
	$data{for_film} = &prompt({prompt=>'Is this developer suitable for film?', type=>'boolean'});
	$data{chemistry} = &prompt({prompt=>'What type of chemistry is this developer based on?'});
	return &newrecord({db=>$db, data=>\%data, table=>'DEVELOPER'});
}

# Add a new lens mount to the database
sub mount_add {
	my $db = shift;
	my %data;
	$data{mount} = &prompt({prompt=>'What is the name of this lens mount?'});
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{fixed} = &prompt({default=>'no', prompt=>'Is this a fixed mount?', type=>'boolean'});
	$data{shutter_in_lens} = &prompt({default=>'no', prompt=>'Does this mount contain the shutter in the lens?', type=>'boolean'});
	$data{type} = &prompt({prompt=>'What type of mounting does this mount use? (e.g. bayonet, screw, etc)'});
	$data{purpose} = &prompt({default=>'camera', prompt=>'What is the intended purpose of this mount? (e.g. camera, enlarger, projector, etc)'});
	$data{digital_only} = &prompt({default=>'no', prompt=>'Is this a digital-only mount?', type=>'boolean'});
	$data{notes} = &prompt({prompt=>'Notes about this mount'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOUNT'});
}

# View compatible cameras and lenses for a mount
sub mount_info {
	my $db = shift;
	my $mountid = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', required=>1});
	my $mount = &lookupval({db=>$db, col=>'mount', table=>'choose_mount', where=>{mount_id=>${mountid}}});
	print "Showing data for $mount mount\n";
	&printlist({db=>$db, msg=>"cameras with $mount mount", cols=>"camera_id as id, concat(manufacturer, ' ', model) as opt", table=>'CAMERA join MANUFACTURER on CAMERA.manufacturer_id=MANUFACTURER.manufacturer_id', where=>{own=>1, mount_id=>$mountid}, order=>'opt'});
	&printlist({db=>$db, msg=>"lenses with $mount mount", cols=>"lens_id as id, concat(manufacturer, ' ', model) as opt", table=>'LENS join MANUFACTURER on LENS.manufacturer_id=MANUFACTURER.manufacturer_id', where=>{mount_id=>$mountid, own=>1}, order=>'opt'});
	return;
}

# Add a new chemical toner to the database
sub toner_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{toner} = &prompt({prompt=>'What is the name of this toner?'});
	$data{formulation} = &prompt({prompt=>'What is the chemical formulation of this toner?'});
	$data{stock_dilution} = &prompt({prompt=>'What is the stock dilution of this toner?'});
	return &newrecord({db=>$db, data=>\%data, table=>'TONER'});
}

# Add a new type of filmstock to the database
sub filmstock_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{name} = &prompt({prompt=>'What is the name of this filmstock?'});
	$data{iso} = &prompt({prompt=>'What is the box ISO/ASA speed of this filmstock?', type=>'integer'});
	$data{colour} = &prompt({prompt=>'Is this a colour film?', type=>'boolean'});
	if ($data{colour} == 1) {
		$data{panchromatic} = 1;
	} else {
		$data{panchromatic} = &prompt({default=>'yes', prompt=>'Is this a panchromatic film?', type=>'boolean'});
	}
	$data{process_id} = &listchoices({db=>$db, cols=>['process_id as id', 'name as opt'], table=>'PROCESS', inserthandler=>\&process_add});
	return &newrecord({db=>$db, data=>\%data, table=>'FILMSTOCK'});
}

# Add a new teleconverter to the database
sub teleconverter_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{model} = &prompt({prompt=>'What is the model of this teleconverter?'});
	$data{factor} = &prompt('', 'What is the magnification factor of this teleconverter?', 'decimal');
	$data{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{elements} = &prompt({prompt=>'How many elements does this teleconverter have?', type=>'integer'});
	$data{groups} = &prompt({prompt=>'How many groups are the elements arranged in?', type=>'integer'});
	$data{multicoated} = &prompt({prompt=>'Is this teleconverter multicoated?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'TELECONVERTER'});
}

# Add a new (optical) filter to the database
sub filter_add {
	my $db = shift;
	my %data;
	$data{type} = &prompt({prompt=>'What type of filter is this?'});
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{attenuation} = &prompt({prompt=>'What attenutation (in stops) does this filter have?', type=>'decimal'});
	$data{thread} = &prompt({prompt=>'What diameter mounting thread does this filter have?', type=>'decimal'});
	$data{qty} = &prompt({default=>1, prompt=>'How many of these filters do you have?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILTER'});
}

# Add a new development process to the database
sub process_add {
	my $db = shift;
	my %data;
	$data{name} = &prompt({prompt=>'What is the name of this film process?'});
	$data{colour} = &prompt({prompt=>'Is this a colour process?', type=>'boolean'});
	$data{positive} = &prompt({prompt=>'Is this a reversal process?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'PROCESS'});
}

# Add a filter adapter to the database
sub filter_adapt {
	my $db = shift;
	my %data;
	$data{camera_thread} = &prompt({prompt=>'What diameter thread faces the camera on this filter adapter?', type=>'decimal'});
	$data{filter_thread} = &prompt({prompt=>'What diameter thread faces the filter on this filter adapter?', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILTER_ADAPTER'});
}

# Add a new manufacturer to the database
sub manufacturer_add {
	my $db = shift;
	my %data;
	$data{manufacturer} = &prompt({prompt=>'What is the name of the manufacturer?', required=>1});
	$data{country} = &prompt({prompt=>'What country is the manufacturer based in?'});
	$data{city} = &prompt({prompt=>'What city is the manufacturer based in?'});
	$data{url} = &prompt({prompt=>'What is the main website of the manufacturer?'});
	$data{founded} = &prompt({prompt=>'When was the manufacturer founded?', type=>'integer'});
	$data{dissolved} = &prompt({prompt=>'When was the manufacturer dissolved?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'MANUFACTURER'});
}

# Add a new "other" accessory to the database
sub accessory_add {
	my $db = shift;
	my %data;
	$data{accessory_type_id} = &listchoices({db=>$db, cols=>['accessory_type_id as id', 'accessory_type as opt'], table=>'ACCESSORY_TYPE', inserthandler=>\&accessory_type});
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{model} = &prompt({prompt=>'What is the model of this accessory?'});
	$data{acquired} = &prompt({default=>&today($db), prompt=>'When was this accessory acquired?', type=>'date'});
	$data{cost} = &prompt({prompt=>'What did this accessory cost?', type=>'decimal'});
	my $accessoryid = &newrecord({db=>$db, data=>\%data, table=>'ACCESSORY'});

	if (&prompt({default=>'yes', prompt=>'Add camera compatibility info for this accessory?', type=>'boolean'})) {
		while (1) {
			my %compatdata;
			$compatdata{accessory_id} = $accessoryid;
			$compatdata{camera_id} = &listchoices({db=>$db, table=>'choose_camera', required=>1});
			&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT', silent=>1});
			last if (!&prompt({default=>'yes', prompt=>'Add another compatible camera?', type=>'boolean'}));
		}
	}
	if (&prompt({default=>'yes', prompt=>'Add lens compatibility info for this accessory?', type=>'boolean'})) {
		while (1) {
			my %compatdata;
			$compatdata{accessory_id} = $accessoryid;
			$compatdata{lens_id} = &listchoices({db=>$db, table=>'choose_lens', required=>1});
			&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT', silent=>1});
			last if (!&prompt({default=>'yes', prompt=>'Add another compatible lens?', type=>'boolean'}));
		}
	}
	return $accessoryid;
}

# Add a new type of "other" accessory to the database
sub accessory_category {
	my $db = shift;
	my %data;
	$data{accessory_type} = &prompt({prompt=>'What category of accessory do you want to add?'});
	return &newrecord({db=>$db, data=>\%data, table=>'ACCESSORY_TYPE'});
}

# Display info about an accessory
sub accessory_info {
	my $db = shift;
	my $accessory_id = &listchoices({db=>$db, table=>'choose_accessory'});
	my $accessorydata = &lookupcol({db=>$db, table=>'info_accessory', where=>{'`Accessory ID`'=>$accessory_id}});
	print Dump($accessorydata);
	return;
}

# Add a new enlarger to the database
sub enlarger_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{enlarger} = &prompt({prompt=>'What is the model of this enlarger?'});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add});
	$data{introduced} = &prompt({prompt=>'What year was this enlarger introduced?', type=>'integer'});
	$data{discontinued} = &prompt({prompt=>'What year was this enlarger discontinued?', type=>'integer'});
	$data{acquired} = &prompt({default=>&today($db), prompt=>'Purchase date', type=>'date'});
	$data{cost} = &prompt({prompt=>'Purchase price', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'ENLARGER'});
}

# Display info about an enlarger
sub enlarger_info {
	my $db = shift;
	my $enlarger_id = shift || &listchoices({db=>$db, table=>'choose_enlarger', required=>1});
	my $enlargerdata = &lookupcol({db=>$db, table=>'info_enlarger', where=>{'`Enlarger ID`'=>$enlarger_id}});
	print Dump($enlargerdata);
	return;
}

# Sell an enlarger
sub enlarger_sell {
	my $db = shift;
	my %data;
	my $enlarger_id = shift || &listchoices({db=>$db, table=>'choose_enlarger', required=>1});
	$data{lost} = &prompt({default=>&today($db), prompt=>'What date was this enlarger sold?', type=>'date'});
	$data{lost_price} = &prompt({prompt=>'How much did this enlarger sell for?', type=>'decimal'});
	return &updaterecord({db=>$db, data=>\%data, table=>'ENLARGER', where=>"enlarger_id=$enlarger_id"});
}

# Add a new flash to the database
sub flash_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{model} = &prompt({prompt=>'What is the model of this flash?'});
	$data{guide_number} = &prompt({prompt=>'What is the guide number of this flash?', type=>'integer'});
	$data{gn_info} = &prompt({default=>'ISO 100', prompt=>'What are the conditions of the guide number?'});
	$data{battery_powered} = &prompt({default=>'yes', prompt=>'Is this flash battery-powered?', type=>'boolean'});
	if ($data{battery_powered} == 1) {
		$data{battery_type_id} = &listchoices({db=>$db, keyword=>'battery type', table=>'choose_battery', inserthandler=>\&battery_add});
		$data{battery_qty} = &prompt({prompt=>'How many batteries does this flash need?', type=>'integer'});
	}
	$data{pc_sync} = &prompt({default=>'yes', prompt=>'Does this flash have a PC sync socket?', type=>'boolean'});
	$data{hot_shoe} = &prompt({default=>'yes', prompt=>'Does this flash have a hot shoe connector?', type=>'boolean'});
	$data{light_stand} = &prompt({default=>'yes', prompt=>'Can this flash be fitted onto a light stand?', type=>'boolean'});
	$data{manual_control} = &prompt({default=>'yes', prompt=>'Does this flash have manual power control?', type=>'boolean'});
	$data{swivel_head} = &prompt({default=>'yes', prompt=>'Does this flash have a left/right swivel head?', type=>'boolean'});
	$data{tilt_head} = &prompt({default=>'yes', prompt=>'Does this flash have an up/down tilt head?', type=>'boolean'});
	$data{zoom} = &prompt({default=>'yes', prompt=>'Does this flash have a zoom head?', type=>'boolean'});
	$data{dslr_safe} = &prompt({default=>'yes', prompt=>'Is this flash safe to use on a DSLR?', type=>'boolean'});
	$data{ttl} = &prompt({default=>'yes', prompt=>'Does this flash support TTL metering?', type=>'boolean'});
	if ($data{ttl} == 1) {
		$data{flash_protocol_id} = &listchoices({db=>$db, table=>'choose_flash_protocol'});
	}
	$data{trigger_voltage} = &prompt({prompt=>'What is the measured trigger voltage?', type=>'decimal'});
	$data{own} = 1;
	$data{acquired} = &prompt({default=>&today($db), prompt=>'When was it acquired?', type=>'date'});
	$data{cost} = &prompt({prompt=>'What did this flash cost?', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'FLASH'});
}

# Add a new type of battery to the database
sub battery_add {
	my $db = shift;
	my %data;
	$data{battery_name} = &prompt({prompt=>'What is the name of this battery?'});
	$data{voltage} = &prompt({prompt=>'What is the nominal voltage of this battery?', type=>'decimal'});
	$data{chemistry} = &prompt({prompt=>'What type of chemistry is this battery based on?'});
	$data{other_names} = &prompt({prompt=>'Does this type of battery go by any other names?'});
	return &newrecord({db=>$db, data=>\%data, table=>'BATTERY'});
}

# Add a new film format to the database
sub format_add {
	my $db = shift;
	my %data;
	$data{format} = &prompt({prompt=>'What is the name of this film format?'});
	$data{digital} = &prompt({default=>'no', prompt=>'Is this a digital format?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'FORMAT'});
}

# Add a size of negative to the database
sub negativesize_add {
	my $db = shift;
	my %data;
	$data{negative_size} = &prompt({prompt=>'What is the name of this negative size?'});
	$data{width} = &prompt({prompt=>'What is the width of this negative size in mm?', type=>'decimal'});
	$data{height} = &prompt({prompt=>'What is the height of this negative size in mm?', type=>'decimal'});
	if ($data{width} > 0 && $data{height} > 0) {
		$data{crop_factor} = round(sqrt($data{width}*$data{width} + $data{height}*$data{height}) / sqrt(36*36 + 24*24), 2);
		$data{area} = $data{width} * $data{height};
		$data{aspect_ratio} = round($data{width} / $data{height}, 2);
	}
	return &newrecord({db=>$db, data=>\%data, table=>'NEGATIVE_SIZE'});
}

# Add a new mount adapter to the database
sub mount_adapt {
	my $db = shift;
	my %data;
	$data{lens_mount} = &listchoices({db=>$db, keyword=>'lens-facing mount', cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{camera_mount} = &listchoices({db=>$db, keyword=>'camera-facing mount', cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{has_optics} = &prompt({prompt=>'Does this mount adapter have corrective optics?', type=>'boolean'});
	$data{infinity_focus} = &prompt({prompt=>'Does this mount adapter have infinity focus?', type=>'boolean'});
	$data{notes} = &prompt({prompt=>'Notes'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOUNT_ADAPTER'});
}

# Add a new light meter to the database
sub lightmeter_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{model} = &prompt({prompt=>'What is the model of this light meter?'});
	$data{metering_type} = &listchoices({db=>$db, cols=>['metering_type_id as id', 'metering as opt'], table=>'METERING_TYPE', inserthandler=>\&meteringtype_add});
	$data{reflected} = &prompt({prompt=>'Can this meter take reflected light readings?', type=>'boolean'});
	$data{incident} = &prompt({prompt=>'Can this meter take incident light readings?', type=>'boolean'});
	$data{spot} = &prompt({prompt=>'Can this meter take spot readings?', type=>'boolean'});
	$data{flash} = &prompt({prompt=>'Can this meter take flash readings?', type=>'boolean'});
	$data{min_asa} = &prompt({prompt=>'What\'s the lowest ISO/ASA setting this meter supports?', type=>'integer'});
	$data{max_asa} = &prompt({prompt=>'What\'s the highest ISO/ASA setting this meter supports?', type=>'integer'});
	$data{min_lv} = &prompt({prompt=>'What\'s the lowest light value (LV) reading this meter can give?', type=>'integer'});
	$data{max_lv} = &prompt({prompt=>'What\'s the highest light value (LV) reading this meter can give?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'LIGHT_METER'});
}

# Add a new camera body type
sub camera_addbodytype {
	my $db = shift;
	my %data;
	$data{body_type} = &prompt({prompt=>'Enter new camera body type'});
	return &newrecord({db=>$db, data=>\%data, table=>'BODY_TYPE'});
}

# Add a new physical archive for prints or films
sub archive_add {
	my $db = shift;
	my %data;
	$data{archive_type_id} = &listchoices({db=>$db, cols=>['archive_type_id as id', 'archive_type as opt'], table=>'ARCHIVE_TYPE'});
	$data{name} = &prompt({prompt=>'What is the name of this archive?'});
	$data{max_width} = &prompt({prompt=>'What is the maximum width of media that this archive can accept (if applicable)?'});
	$data{max_height} = &prompt({prompt=>'What is the maximum height of media that this archive can accept (if applicable)?'});
	$data{location} = &prompt({prompt=>'What is the location of this archive?'});
	$data{storage} = &prompt({prompt=>'What is the storage type of this archive? (e.g. box, folder, ringbinder, etc)'});
	$data{sealed} = &prompt({default=>'no', prompt=>'Is this archive sealed (closed to new additions)?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'ARCHIVE'});
}

# Bulk-add multiple films to an archive
sub archive_films {
	my $db = shift;
	my %data;
	my $minfilm = &prompt({prompt=>'What is the lowest film ID in the range?', type=>'integer'});
	my $maxfilm = &prompt({prompt=>'What is the highest film ID in the range?', type=>'integer'});
	if (($minfilm =~ m/^\d+$/) && ($maxfilm =~ m/^\d+$/)) {
		if ($maxfilm le $minfilm) {
			print "Highest film ID must be higher than lowest film ID\n";
			return;
		}
	} else {
		print "Must provide highest and lowest film IDs\n";
		return;
	}
	$data{archive_id} = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>'archive_type_id in (1,2) and sealed = 0', inserthandler=>\&archive_add});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>"film_id >= $minfilm and film_id <= $maxfilm and archive_id is null"});
}

# Display info about an archive
sub archive_info {
	my $db = shift;
	my $archive_id = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	my $archivedata = &lookupcol({db=>$db, table=>'info_archive', where=>{'`Archive ID`'=>$archive_id}});
	print Dump($archivedata);
	return;
}

# List the contents of an archive
sub archive_list {
	my $db = shift;
	my $archive_id = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	my $archive_name = &lookupval({db=>$db, col=>'name', table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
	&printlist({db=>$db, msg=>"items in archive $archive_name", table=>'archive_contents', where=>{archive_id=>$archive_id}});
	return;
}

# Seal an archive and prevent new items from being added to it
sub archive_seal {
	my $db = shift;
	my %data;
	my $archive_id = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{sealed=>0}, required=>1});
	$data{sealed} = 1;
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>"archive_id = $archive_id"});
}

# Unseal an archive and allow new items to be added to it
sub archive_unseal {
	my $db = shift;
	my %data;
	my $archive_id = &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{sealed=>1}, required=>1});
	$data{sealed} = 0;
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>"archive_id = $archive_id"});
}

# Move an archive to a new location
sub archive_move {
	my $db = shift;
	my %data;
	my $archive_id = shift || &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	my $oldlocation = &lookupval({db=>$db, col=>'location', table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
	$data{location} = &prompt({default=>$oldlocation, prompt=>'What is the new location of this archive?'});
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>"archive_id = $archive_id"});
}

# Add a new type of shutter to the database
sub shuttertype_add {
	my $db = shift;
	my %data;
	$data{shutter_type} = &prompt({prompt=>'What type of shutter do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'SHUTTER_TYPE'});
}

# Add a new type of focus system to the database
sub focustype_add {
	my $db = shift;
	my %data;
	$data{focus_type} = &prompt({prompt=>'What type of focus system do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'FOCUS_TYPE'});
}

# Add a new flash protocol to the database
sub flashprotocol_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{name} = &prompt({prompt=>'What flash protocol do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'FLASH_PROTOCOL'});
}

# Add a new type of metering system to the database
sub meteringtype_add {
	my $db = shift;
	my %data;
	$data{metering} = &prompt({prompt=>'What type of metering system do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'METERING_TYPE'});
}

# Add a new shutter speed to the database
sub shutterspeed_add {
	my $db = shift;
	my %data;
	$data{shutter_speed} = &prompt({prompt=>'What shutter speed do you want to add?', required=>1});
	$data{duration} = &duration($data{shutter_speed});
	return &newrecord({db=>$db, data=>\%data, table=>'SHUTTER_SPEED'});
}

# Add a new person to the database
sub person_add {
	my $db = shift;
	my %data;
	$data{name} = &prompt({prompt=>'What is this person\'s name?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'PERSON'});
}

# Add a new projector to the database
sub projector_add {
	my $db = shift;
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db});
	$data{model} = &prompt({prompt=>'What is the model of this projector?'});
	$data{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Projector'}, inserthandler=>\&mount_add});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add});
	$data{own} = 1;
	$data{cine} = &prompt({prompt=>'Is this a cine/movie projector?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'PROJECTOR'});
}

# Add a new movie to the database
sub movie_add {
	my $db = shift;
	my %data;
	$data{title} = &prompt({prompt=>'What is the title of this movie?'});
	$data{camera_id} = &listchoices({db=>$db, table=>'choose_movie_camera'});
	if (&lookupval({db=>$db, col=>'fixed_mount', table=>'CAMERA', where=>{camera_id=>$data{camera_id}}})) {
		$data{lens_id} = &lookupval({db=>$db, col=>'lens_id', table=>'CAMERA', where=>{camera_id=>$data{camera_id}}});
	} else {
		$data{lens_id} = &listchoices({db=>$db, table=>'choose_lens'});
	}
	$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add});
	$data{sound} = &prompt({prompt=>'Does this movie have sound?', type=>'boolean'});
	$data{fps} = &prompt({prompt=>'What is the framerate of this movie in fps?', type=>'integer'});
	$data{filmstock_id} = &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add});
	$data{feet} = &prompt({prompt=>'What is the length of this movie in feet?', type=>'integer'});
	$data{date_loaded} = &prompt({default=>&today($db), prompt=>'What date was the film loaded?', type=>'date'});
	$data{date_shot} = &prompt({default=>&today($db), prompt=>'What date was the movie shot?', type=>'date'});
	$data{date_processed} = &prompt({default=>&today($db), prompt=>'What date was the movie processed?', type=>'date'});
	$data{process_id} = &listchoices({db=>$db, keyword=>'process', cols=>['process_id as id', 'name as opt'], table=>'PROCESS', inserthandler=>\&process_add});
	$data{description} = &prompt({prompt=>'Please enter a description of the movie'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOVIE'});
}

# Show info about a movie
sub movie_info {
	my $db = shift;
	my $movie_id = &listchoices({db=>$db, cols=>['movie_id as id', 'title as opt'], table=>'MOVIE', required=>1});
	my $moviedata = &lookupcol({db=>$db, table=>'info_movie', where=>{'`Movie ID`'=>$movie_id}});
	print Dump($moviedata);
	return;
}

# Audit cameras without shutter speed data
sub audit_shutterspeeds {
	my $db = shift;
	my $cameraid = &listchoices({db=>$db, keyword=>'camera without shutter speed data', table=>'choose_camera_without_shutter_data', required=>1});
	&camera_shutterspeeds($db, $cameraid);
	return;
}

# Audit cameras without exposure program data
sub audit_exposureprograms {
	my $db = shift;
	my $cameraid = &listchoices({db=>$db, keyword=>'camera without exposure program data', table=>'choose_camera_without_exposure_programs', required=>1});
	&camera_exposureprogram($db, $cameraid);
	return;
}

# Audit cameras without metering mode data
sub audit_meteringmodes {
	my $db = shift;
	my $cameraid = &listchoices({db=>$db, keyword=>'camera without metering mode data', table=>'choose_camera_without_metering_data', required=>1});
	&camera_meteringmode($db, $cameraid);
	return;
}

# Add a new exhibition to the database
sub exhibition_add {
	my $db = shift;
	my %data;
	$data{title} = &prompt({prompt=>'What is the title of this exhibition?', required=>1});
	$data{location} = &prompt({prompt=>'Where is this exhibition?'});
	$data{start_date} = &prompt({prompt=>'What date does the exhibition start?', type=>'date'});
	$data{end_date} = &prompt({prompt=>'What date does the exhibition end?', type=>'date'});
	return &newrecord({db=>$db, data=>\%data, table=>'EXHIBITION'});
}

# Review which prints were exhibited at an exhibition
sub exhibition_info {
	my $db = shift;
	my $exhibition_id = &listchoices({db=>$db, cols=>['exhibition_id as id', 'title as opt'], table=>'EXHIBITION', required=>1});
	my $title = &lookupval({db=>$db, col=>'title', table=>'EXHIBITION', where=>{exhibition_id=>$exhibition_id}});

	&printlist({db=>$db, msg=>"prints exhibited at $title", table=>'exhibits', where=>{exhibition_id=>$exhibition_id}});
	return;
}

# Run a selection of maintenance tasks on the database
sub run_task {
	my $db = shift;

	my @tasks = @photodb::queries::tasks;
	for my $i (0 .. $#tasks) {
		print "\t$i\t$tasks[$i]{desc}\n";
	}

	# Wait for input
	my $input = &prompt({prompt=>'Please select a task', type=>'integer', required=>1});

	my $sql = $tasks[$input]{'query'};
	my $rows = &updatedata($db, $sql);
	print "Updated $rows rows\n";
	return;
}

# Run a selection of reports on the database
sub run_report {
	my $db = shift;

	my @reports = @photodb::queries::reports;
	for my $i (0 .. $#reports) {
		print "\t$i\t$reports[$i]{desc}\n";
	}

	# Wait for input
	my $input = &prompt({prompt=>'Please select a report', type=>'integer', required=>1});

	my $view = $reports[$input]{'view'};

	# Use SQL::Abstract
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select($view);

	my $sth = $db->prepare($stmt);
	my $rows = $sth->execute(@bind);
	my $cols = $sth->{'NAME'};
	my @array;
	my $table = Text::TabularDisplay->new(@$cols);
	while (my @row = $sth->fetchrow) {
		$table->add(@row);
	}

	print "$reports[$input]{'desc'}\n";
	print $table->render;
	print "\n";
	return $rows;
}

# Select a manufacturer using the first initial
sub choose_manufacturer {
	my $href = shift;
	my $db = $href->{db};
	my $default = $href->{default};

	if ($default) {
		my $manufacturer = &lookupval({db=>$db, col=>'manufacturer', table=>'MANUFACTURER', where=>{manufacturer_id=>$default}});
		return $default if (!&prompt({prompt=>"Current manufacturer is $manufacturer. Change this?", type=>'boolean', default=>'no'}));
	}

	# Loop until we get valid input
	my $initial;
	do {
		$initial = &prompt({prompt=>'Enter the first initial of the manufacturer', type=>'text'});
	} while (!($initial =~ m/^[a-z]$/i || $initial eq ''));
	$initial = lc($initial);
	return &listchoices({db=>$db, cols=>['manufacturer_id as id', 'manufacturer as opt'], table=>'MANUFACTURER', where=>{'lower(left(manufacturer, 1))'=>$initial}, inserthandler=>\&handlers::manufacturer_add, required=>1});
}

# Audit cameras without display lenses set
sub audit_displaylenses {
	my $db = shift;
	my $camera_id = &listchoices({db=>$db, keyword=>'camera', table=>'camera_chooser', where=>{mount_id=>{'!=', undef}, display_lens=>{'=', undef}}, required=>1 });
	&camera_displaylens($db, $camera_id);
	return;
}

# Show statistics about the database
sub db_stats {
	my $db = shift;
	my %data;
	$data{'Total cameras'} = &lookupval({db=>$db, col=>'count(camera_id)', table=>'CAMERA'});
	$data{'Total lenses'} = &lookupval({db=>$db, col=>'count(lens_id)', table=>'LENS'});
	$data{'Total negatives'} = &lookupval({db=>$db, col=>'count(negative_id)', table=>'NEGATIVE'});
	$data{'Total prints'} = &lookupval({db=>$db, col=>'count(print_id)', table=>'PRINT'});
	print Dump(\%data);
	return;
}

# Show database logs
sub db_logs {
	my $db = shift;
	my $logs = &lookuplist({db=>$db, col=>"concat(datetime, ' ', type, ' ', message) as log", table=>'LOG'});
	print Dump($logs);
	return;
}

# Print basic database info
sub db_test {
	my $db = shift;
	my $hostname = $db->{'mysql_hostinfo'};
	my $version = $db->{'mysql_serverinfo'};
	my $stats = $db->{'mysql_stat'};
	print "\tConnected to $hostname\n\tRunning version $version\n\t$stats\n";
	return;
}

# Add a new scan of a negative or print
sub scan_add {
	my $db = shift;
	my $href = shift;

	my %data;
	$data{negative_id} = $href->{negative_id};
	$data{print_id} = $href->{print_id};

	if (!defined($href->{negative_id}) && !defined($href->{print_id})) {
		if (&prompt({prompt=>'Is this a scan of a negative?', type=>'boolean'})) {
			# choose negative
			$data{negative_id} = &chooseneg({db=>$db});

		} else {
			# choose print
			$data{print_id} = &prompt({prompt=>'Which print did you scan?', type=>'integer'});
		}
	}
	$data{filename} = $href->{filename} // &prompt({prompt=>'Enter the filename of this scan', type=>'text'});
	return &newrecord({db=>$db, data=>\%data, table=>'SCAN'});
}

# Add a new scan which is a derivative of an existing one
sub scan_edit {
	my $db = shift;
	my $href = shift;

	# Prompt user for filename of scan
	my $scan_id = &choosescan($db);

	# Work out negative_id or print_id
	my $scan_data = &lookupcol({db=>$db, cols=>['negative_id', 'print_id'], table=>'SCAN', where=>{scan_id=>$scan_id}});
	$scan_data = &thin($$scan_data[0]);

	# Insert new scan from same source
	return &scan_add($db, $scan_data);
}

# Delete a scan from the database and optionally from the filesystem
sub scan_delete {
	my $db = shift;
	my $href = shift;

	# Prompt user for filename of scan
	my $scan_id = &choosescan($db);

	# Work out file path
	my $basepath = &basepath;
	my $relativepath = &lookupval({db=>$db, col=>"concat(directory, '/', filename)", table=>'scans_negs', where=>{scan_id=>$scan_id}});
	my $fullpath = "$basepath/$relativepath";

	# Offer to delete the file
	if (&prompt({prompt=>"Delete the file $fullpath ?", type=>'boolean', default=>'no'})) {
		unlink $fullpath or print "Could not delete file $fullpath: $!\n";
	}

	# Remove record from SCAN
	return &deleterecord({db=>$db, table=>'SCAN', where=>{scan_id=>$scan_id}});
}

# Search the filesystem for scans which are not in the database
sub scan_search {
	my $db = shift;
	my $href = shift;

	# Search filesystem basepath & DB to enumerate all *.jpg scans
	my @fsfiles = &fsfiles;
	my @dbfiles = &dbfiles($db);

	# Find the scans only on the filesystem
	my @fsonly = array_minus(@fsfiles, @dbfiles);
	my $numfsonly = scalar @fsonly;

	# Scans only on the fs
	if ($numfsonly>0 && &prompt({prompt=>"Audit $numfsonly scans that exist only on the filesystem and not in the database?", type=>'boolean', default=>'yes', required=>1})) {
		my $auto = &prompt({prompt=>'Auto-add scans to the database that can be auto-matched to a negative or print?', type=>'boolean', required=>1});
		my $x = 0;
		for my $fsonlyfile (@fsonly) {
			if ($auto || &prompt({prompt=>"Add $fsonlyfile to the database?", type=>'boolean', required=>1})) {
				my $filename = fileparse($fsonlyfile);

				# Test to see if this is from a negative, e.g. 123-12-image012.jpg
				if ($filename =~ m/^(\d+)-([0-9a-z]+)-.+\.jpg$/i) {
					my $film_id = $1;
					my $frame = $2;
					if ($auto || &prompt({prompt=>"This looks like a scan of negative $film_id/$frame. Add it?", type=>'boolean', default=>'yes', required=>1})) {
						my $neg_id = &lookupval({db=>$db, col=>"lookupneg($film_id, '$frame')", table=>'NEGATIVE'});
						my $subdir = &lookupval({db=>$db, col=>'directory', table=>'FILM', where=>{film_id=>$film_id}});
						my $basepath = &basepath;
						my $correctpath = "$basepath/$subdir/$filename";

						# Test to make sure it's in a valid directory
						if ($fsonlyfile ne $correctpath) {
							if (&prompt({prompt=>"Move scan $fsonlyfile to its correct path $correctpath?", type=>'boolean', default=>'yes'})) {
								# Rename it to the correct dir and continue using the new path
								rename(&untaint($fsonlyfile), &untaint($correctpath));
								$fsonlyfile = $correctpath;
							}
						}

						if (!$neg_id || $neg_id !~ /\d+/) {
							print "Could not determine negative ID for negative $film_id/$frame, skipping\n";
							next;
						}
						&newrecord({db=>$db, data=>{negative_id=>$neg_id, filename=>$filename}, table=>'SCAN', silent=>$auto});
						print "Added $filename as scan of negative $film_id/$frame\n" if $auto;
						$x++;
					}
				# Test to see if this is from a print, e.g. P232-image012.jpg
				} elsif ($filename =~ m/^p(rint)?(\d+).*\.jpg$/i) {
					my $print_id = $2;
					if ($auto || &prompt({prompt=>"This looks like a scan of print #$print_id. Add it?", type=>'boolean', default=>'yes', required=>1})) {
						&newrecord({db=>$db, data=>{print_id=>$print_id, filename=>$filename}, table=>'SCAN', silent=>$auto});
						print "Added $filename as scan of print #$print_id\n" if $auto;
						$x++;
					}
				} else {
					next if $auto;
					if (&prompt({prompt=>"Can't automatically determine the source of this scan. Add it manually?", type=>'boolean', default=>'yes', required=>1})) {
						&scan_add($db, {filename=>$filename});
					}
				}
			}
		}
		my $stillfsonly = $numfsonly - $x;
		print "Added $x scans to the database. There are $stillfsonly scans on the filesystem but not in the database.\n";
	} else {
		print "All scans on the filesystem are already in the database\n";
	}

	# Re-search filesystem basepath & DB in case it was updated above
	@fsfiles = &fsfiles;
	@dbfiles = &dbfiles($db);

	# Find scans only in the database
	my @dbonly = array_minus(@dbfiles, @fsfiles);
	my $numdbonly = scalar @dbonly;

	# Scans only in the db
	if ($numdbonly>0 && &prompt({prompt=>"Audit $numdbonly scans that exist only in the database and not on the filesystem?", type=>'boolean', default=>'no', required=>1})) {
		my $x = 0;
		for my $dbonlyfile (@dbonly) {
			if (&prompt({prompt=>"Delete $dbonlyfile from the database?", type=>'boolean', default=>'no', required=>1})) {
				my $filename = fileparse($dbonlyfile);
				&deleterecord({db=>$db, table=>'SCAN', where=>{filename=>$filename}, silent=>1});
				$x++;
			}
		}
		my $stilldbonly = $numdbonly - $x;
		print "Deleted $x scans from the database. There are $stilldbonly scans in the database but not on the filesystem.\n";
	} else {
		print "All scans in the database exist on the filesystem\n";
	}
	return;
}

# This ensures the lib loads smoothly
1;
