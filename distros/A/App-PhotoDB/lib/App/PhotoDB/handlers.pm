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

use App::PhotoDB::funcs qw(/./);

our @EXPORT_OK = qw(
	film_add film_load film_archive film_develop film_tag film_locate film_bulk film_annotate film_stocks film_current film_choose film_info film_search
	cameramodel_add cameramodel_shutterspeeds cameramodel_exposureprogram cameramodel_meteringmode cameramodel_accessory cameramodel_series cameramodel_info
	camera_add camera_displaylens camera_sell camera_repair camera_addbodytype camera_info camera_choose camera_edit camera_search
	mount_add mount_info mount_adapt
	negative_add negative_bulkadd negative_prints negative_info negative_tag negative_search
	lens_add lens_sell lens_repair lens_info lens_edit lens_search
	lensmodel_add lensmodel_accessory lensmodel_series lensmodel_info
	print_add print_tone print_sell print_order print_fulfil print_archive print_unarchive print_locate print_info print_exhibit print_label print_worklist print_tag
	paperstock_add
	developer_add
	toner_add
	run_task run_report run_migrations
	filmstock_add
	teleconverter_add
	filter_add filter_adapt
	manufacturer_add
	accessory_add accessory_category accessory_info accessory_search
	enlarger_add enlarger_info enlarger_sell
	flash_add
	battery_add
	format_add format_compat
	negativesize_add negative_size_compat
	lightmeter_add
	process_add
	person_add
	projector_add
	movie_add movie_info
	series_add series_info series_list series_need
	archive_add archive_films archive_info archive_list archive_seal archive_unseal archive_move
	shuttertype_add focustype_add flashprotocol_add meteringtype_add shutterspeed_add
	audit_shutterspeeds audit_exposureprograms audit_meteringmodes audit_displaylenses
	exhibition_add exhibition_info
	choose_manufacturer
	db_stats db_logs db_test
	scan_add scan_edit scan_delete scan_search scan_rename
);

# Add a new film to the database
sub film_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	if ($href->{bulk_loaded} // &prompt({default=>'no', prompt=>'Is this film bulk-loaded?', type=>'boolean'}) == 1) {
		# These are filled in only for bulk-loaded films
		$data{film_bulk_id} = $href->{film_bulk_id} // &listchoices({db=>$db, table=>'choose_bulk_film', required=>1});
		$data{film_bulk_loaded} = $href->{film_bulk_loaded} // &prompt({default=>&today, prompt=>'When was the film bulk-loaded?'});
		# These are deduced automagically for bulk-loaded films
		$data{film_batch} = $href->{film_batch} // &lookupval({db=>$db, col=>'batch', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{film_expiry} = $href->{film_expiry} // &lookupval({db=>$db, col=>'expiry', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{purchase_date} = $href->{purchase_date} // &lookupval({db=>$db, col=>'purchase_date', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{filmstock_id} = $href->{filmstock_id} // &lookupval({db=>$db, col=>'filmstock_id', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
		$data{format_id} = $href->{format_id} // &lookupval({db=>$db, col=>'format_id', table=>'FILM_BULK', where=>{film_bulk_id=>$data{'film_bulk_id'}}});
	} else {
		# These are filled in only for standalone films
		$data{film_batch} = $href->{film_batch} // &prompt({prompt=>'Film batch number'});
		$data{film_expiry} = $href->{film_expiry} // &prompt({prompt=>'Film expiry date', type=>'date'});
		$data{purchase_date} = $href->{purchase_date} // &prompt({default=>&today, prompt=>'Purchase date', type=>'date'});
		$data{filmstock_id} = $href->{filmstock_id} // &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add, required=>1});
		$data{format_id} = $href->{format_id} // &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add}, required=>1);
	}
	$data{frames} = $href->{frames} // &prompt({prompt=>'How many frames?', type=>'integer'});
	$data{price} = $href->{price} // &prompt({prompt=>'Purchase price', type=>'decimal'});
	my $film_id = &newrecord({db=>$db, data=>\%data, table=>'FILM'});
	if (&prompt({default=>'no', prompt=>'Load this film into a camera now?', type=>'boolean'})) {
		&film_load({db=>$db, film_id=>$film_id});
	}
	return $film_id;
}

# Load a film into a camera
sub film_load {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &listchoices({db=>$db, table=>'choose_film_to_load', required=>1});
	my %data;
	$data{camera_id} = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_camera_by_film', where=>{film_id=>$film_id}, required=>1});
	$data{exposed_at} = $href->{exposed_at} // &prompt({default=>&lookupval({db=>$db, col=>"iso", table=>'FILM join FILMSTOCK on FILM.filmstock_id=FILMSTOCK.filmstock_id', where=>{film_id=>$film_id}}), prompt=>'What ISO?', type=>'integer'});
	$data{date_loaded} = $href->{date_loaded} // &prompt({default=>&today, prompt=>'What date was this film loaded?', type=>'date'});
	$data{notes} = $href->{notes} // &prompt({prompt=>'Notes'});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>{film_id=>$film_id}});
}

# Put a film in a physical archive
sub film_archive {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});
	my %data;
	$data{archive_id} = $href->{archive_id} // &listchoices({db=>$db, table=>'ARCHIVE', cols=>['archive_id as id', 'name as opt'], where=>['archive_type_id in (1,2)', 'sealed = 0'], inserthandler=>\&archive_add, required=>1});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>{film_id=>$film_id}});
}

# Develop a film
sub film_develop {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &listchoices({db=>$db, table=>'choose_film_to_develop', required=>1});
	my %data;
	$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'What date was this film processed?', type=>'date'});
	$data{developer_id} = $href->{developer_id} // &listchoices({db=>$db, table=>'DEVELOPER', cols=>['developer_id as id', 'name as opt'], where=>{'for_film'=>1}, inserthandler=>\&developer_add});
	$data{directory} = $href->{directory} // &prompt({prompt=>'What directory are these scans in?'});
	$data{dev_uses} = $href->{dev_uses} // &prompt({prompt=>'How many previous uses has the developer had?', type=>'integer'});
	$data{dev_time} = $href->{dev_time} // &prompt({prompt=>'How long was the film developed for?', type=>'time'});
	$data{dev_temp} = $href->{dev_temp} // &prompt({prompt=>'What temperature was the developer?', type=>'decimal'});
	$data{dev_n} = $href->{dev_n} // &prompt({default=>0, prompt=>'What push/pull was used?', type=>'integer'});
	$data{development_notes} = $href->{development_notes} // &prompt({prompt=>'Any other development notes'});
	$data{processed_by} = $href->{processed_by} // &prompt({prompt=>'Who developed the film?'});
	&updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>{film_id=>$film_id}});
	if (&prompt({default=>'no', prompt=>'Archive this film now?', type=>'boolean'})) {
		&film_archive({db=>$db, film_id=>$film_id});
	}
	return;
}

# Show information about a negative
sub film_info {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});
	print Dump(&lookupcol({db=>$db, table=>'info_film', where=>{'`Film ID`'=>$film_id}}));
	return;
}

# Write EXIF tags to scans from a film
sub film_tag {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});
	&tag({db=>$db, where=>{film_id=>$film_id}});
	return;
}

# Locate where this film is
sub film_locate {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});

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
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{filmstock_id} = &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add, required=>1});
	$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add, required=>1});
	$data{batch} = &prompt({prompt=>'Film batch number'});
	$data{expiry} = &prompt({prompt=>'Film expiry date', type=>'date'});
	$data{purchase_date} = &prompt({default=>&today, prompt=>'Purchase date', type=>'date'});
	$data{cost} = &prompt({prompt=>'Purchase price', type=>'decimal'});
	$data{source} = &prompt({prompt=>'Where was this bulk film purchased from?'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILM_BULK'});
}

# Write out a text file with the scans from the film
sub film_annotate {
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});
	&annotatefilm({db=>$db, film_id=>$film_id});
	return;
}

# List the films that are currently in stock
sub film_stocks {
	my $href = shift;
	my $db = $href->{db};
	print "Films currently in stock:\n";
	my $rows = &tabulate({db=>$db, view=>'view_film_stocks'});

	if ($rows > 0) {
		if (&prompt({default=>'yes', prompt=>'Load a film into a camera now?', type=>'boolean'})) {
			&film_load({db=>$db});
		}
	} else {
		print "No films currently in stock\n";
	}
	return;
}

# List films that are currently loaded into cameras
sub film_current {
	my $href = shift;
	my $db = $href->{db};
	&printlist({db=>$db, msg=>"current films", table=>'current_films'});
	return;
}

sub film_choose {
	my $href = shift;
	my $db = $href->{db};
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

# Search for a film
sub film_search {
	my $href = shift;
	my $db = $href->{db};
	my $searchterm = $href->{searchterm} // &prompt({prompt=>'Enter search term'});

	# Perform search
	my $id = &search({
		db         => $db,
		cols       => ['film_id as id', 'notes as opt'],
		table      => 'FILM',
		where      => "notes like '%$searchterm%' collate utf8mb4_general_ci",
		searchterm => $searchterm,
		choices    => [
			{ desc => 'Do nothing' },
			{ handler => \&film_annotate, desc => 'Write out a text file with the scans from the film', id=>'film_id' },
			{ handler => \&film_archive,  desc => 'Put this film in a physical archive',                id=>'film_id' },
			{ handler => \&film_develop,  desc => 'Develop this film',                                  id=>'film_id' },
			{ handler => \&film_info,     desc => 'Show information about this film',                   id=>'film_id' },
			{ handler => \&film_locate,   desc => 'Locate where this film is',                          id=>'film_id' },
			{ handler => \&film_tag,      desc => 'Write EXIF tags to scans from this film',            id=>'film_id' },
		],
	});
	return $id;
}

# Add a new camera model to the database
sub cameramodel_add {
	my $href = shift;
	my $db = $href->{db};

	# Gather data from user
	my $datahr = &camera_prompt({db=>$db});
	my %data = %$datahr;

	# Insert new record into DB
	my $cameramodel_id = &newrecord({db=>$db, data=>\%data, table=>'CAMERAMODEL'});

	# Now we have a camera model ID, we can insert rows in auxiliary tables
	if (&prompt({default=>'yes', prompt=>'Add exposure programs for this camera model?', type=>'boolean'})) {
		&cameramodel_exposureprogram({db=>$db, cameramodel_id=>$cameramodel_id});
	}

	if (&prompt({default=>'yes', prompt=>'Add metering modes for this camera model?', type=>'boolean'})) {
		if ($data{metering}) {
			&cameramodel_meteringmode({db=>$db, cameramodel_id=>$cameramodel_id});
		} else {
			my %mmdata = ('cameramodel_id' => $cameramodel_id, 'metering_mode_id' => 0);
			&newrecord({db=>$db, data=>\%mmdata, table=>'METERING_MODE_AVAILABLE'});
		}
	}

	if (&prompt({default=>'yes', prompt=>'Add shutter speeds for this camera model?', type=>'boolean'})) {
		&cameramodel_shutterspeeds({db=>$db, cameramodel_id=>$cameramodel_id});
	}

	if (&prompt({default=>'yes', prompt=>'Add accessory compatibility for this camera model?', type=>'boolean'})) {
		&cameramodel_accessory({db=>$db, cameramodel_id=>$cameramodel_id});
	}

	if (&prompt({default=>'no', prompt=>'Add this camera model to a series?', type=>'boolean'})) {
		&cameramodel_series({db=>$db, cameramodel_id=>$cameramodel_id});
	}
	return $cameramodel_id;
}


# Show information about a cameramodel
sub cameramodel_info {
        my $href = shift;
        my $db = $href->{db};

        # Choose camera
        my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});

        # Get camera data
        my $cameradata = &lookupcol({db=>$db, table=>'info_cameramodel', where=>{'`Camera Model ID`'=>$cameramodel_id}});

        # Show compatible accessories
        my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{cameramodel_id=>$cameramodel_id}});
        ${@$cameradata[0]}{'Accessories'} = $accessories;

        print Dump($cameradata);
        return;
}

# Add a new camera to the database
sub camera_add {
	my $href = shift;
	my $db = $href->{db};

	# Gather data from user
	my %data;

	my $manufacturer_id = &choose_manufacturer({db=>$db});
	$data{cameramodel_id} = &listchoices({db=>$db, table=>'choose_cameramodel', where=>{'manufacturer_id'=>$manufacturer_id}, required=>1, inserthandler=>\&cameramodel_add});
	$data{acquired} = &prompt({default=>&today, prompt=>'When was it acquired?', type=>'date'});
	$data{cost} = &prompt({prompt=>'What did the camera cost?', type=>'decimal'});
	$data{serial} = &prompt({prompt=>'What is the camera\'s serial number?'});
	$data{datecode} = &prompt({prompt=>'What is the camera\'s datecode?'});

	# Attempt to decode datecode for Canon cameras
	my $manufactured;
	if ($manufacturer_id == 3 && $data{datecode}) {
		my $introduced = &lookupval({db=>$db, col=>'introduced', table=>'CAMERAMODEL', where=>{cameramodel_id=>$data{cameramodel_id}}});
		my $discontinued = &lookupval({db=>$db, col=>'discontinued', table=>'CAMERAMODEL', where=>{cameramodel_id=>$data{cameramodel_id}}});
		$manufactured = &canondatecode({datecode=>$data{datecode}, introduced=>$introduced, discontinued=>$discontinued});
	}

	$data{manufactured} = &prompt({prompt=>'When was the camera manufactured?', type=>'integer', default=>$manufactured});
	$data{own} = &prompt({default=>'yes', prompt=>'Do you own this camera?', type=>'boolean'});
	$data{notes} = &prompt({prompt=>'Additional notes'});
	$data{source} = &prompt({prompt=>'Where was the camera acquired from?'});
	$data{condition_id} = &listchoices({db=>$db, keyword=>'condition', cols=>['condition_id as id', 'name as opt'], table=>'`CONDITION`'});

	if (&lookupval({db=>$db, col=>'fixed_mount', table=>'CAMERAMODEL', where=>{cameramodel_id=>$data{cameramodel_id}}})) {
		# Attempt to figure out the lensmodel that comes with this cameramodel
		my $lensmodel_id = &lookupval({db=>$db, col=>'lensmodel_id', table=>'CAMERAMODEL', where=>{cameramodel_id=>$data{cameramodel_id}}});

		# Get info about lens
		print "Please enter some information about the lens\n";
		$data{lens_id} = &lens_add({db=>$db, cost=>0, own=>$data{own}, lensmodel_id=>$lensmodel_id, acquired=>$data{acquired}, source=>$data{source}});
	}

	if (defined($data{mount_id})) {
		$data{display_lens} = &listchoices({db=>$db, table=>'choose_display_lens', where=>{mount_id=>$data{mount_id}}, skipok=>1});
	}
	# Insert new record into DB
	my $camera_id = &newrecord({db=>$db, data=>\%data, table=>'CAMERA'});

	return $camera_id;
}

# Edit an existing camera
sub camera_edit {
	my $href = shift;
	my $db = $href->{db};
	my $camera_id = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_camera', required=>1});
	my $existing = &lookupcol({db=>$db, table=>'CAMERA', where=>{camera_id=>$camera_id}});
	$existing = @$existing[0];

	# Gather data from user
	my %data;
	$data{acquired} = &prompt({default=>$$existing{acquired}//&today, prompt=>'When was it acquired?', type=>'date'});
	$data{cost} = &prompt({prompt=>'What did the camera cost?', type=>'decimal', default=>$$existing{cost}});
	$data{serial} = &prompt({prompt=>'What is the camera\'s serial number?', default=>$$existing{serial}});
	$data{datecode} = &prompt({prompt=>'What is the camera\'s datecode?', default=>$$existing{datecode}});
	$data{manufactured} = &prompt({prompt=>'When was the camera manufactured?', type=>'integer', default=>$$existing{manufactured}});
	$data{own} = &prompt({default=>$$existing{own}//'yes', prompt=>'Do you own this camera?', type=>'boolean'});
	$data{notes} = &prompt({prompt=>'Additional notes', default=>$$existing{notes}});
	$data{source} = &prompt({prompt=>'Where was the camera acquired from?', default=>$$existing{source}});
	$data{condition_id} = &listchoices({db=>$db, keyword=>'condition', cols=>['condition_id as id', 'name as opt'], table=>'`CONDITION`', default=>$$existing{condition_id}});

	# Compare new and old data to find changed fields
	my $changes = &hashdiff($existing, \%data);

	# Update the DB
	return &updaterecord({db=>$db, data=>$changes, table=>'CAMERA', where=>{camera_id=>$camera_id}});
}

sub camera_prompt {
	my $href = shift;
	my $db = $href->{db};
	my $defaults = $href->{defaults};
	my %data;
	$data{manufacturer_id} = &choose_manufacturer({db=>$db, default=>$$defaults{manufacturer_id}});
	$data{model} = &prompt({prompt=>'What model is the camera?', required=>1, default=>$$defaults{model}});
	$data{fixed_mount} = &prompt({prompt=>'Does this camera have a fixed lens?', type=>'boolean', required=>1, default=>$$defaults{fixed_mount}});
	if (defined($data{fixed_mount}) && $data{fixed_mount} == 1 && !defined($$defaults{lens_id})) {
		# Get info about lens
		print "Please select the lens model that this camera has\n";
		$data{lensmodel_id} = &listchoices({db=>$db, table=>'choose_lensmodel', required=>1, inserthandler=>\&lensmodel_add});
	} else {
		$data{mount_id} = &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{purpose=>'Camera'}, inserthandler=>\&mount_add, default=>$$defaults{mount_id}});
	}
	$data{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add, required=>1, default=>$$defaults{format_id}});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'choose_negativeformat', where=>{format_id=>$data{format_id}}, inserthandler=>\&negative_size_compat, default=>$$defaults{negative_size_id}});
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
	$data{introduced} = &prompt({prompt=>'What year was the camera introduced?', type=>'integer', default=>$$defaults{introduced}});
	$data{discontinued} = &prompt({prompt=>'What year was the camera discontinued?', type=>'integer', default=>$$defaults{discontinued}});
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
	$data{dof_preview} = &prompt({prompt=>'Does this camera have a depth-of-field preview feature?', type=>'boolean', default=>$$defaults{dof_preview}});
	$data{tripod} = &prompt({prompt=>'Does this camera have a tripod bush?', type=>'boolean', default=>$$defaults{tripod}});
	return \%data;
}

# Add accessory compatibility info to a camera
sub cameramodel_accessory {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});
	while (1) {
		my %compatdata;
		$compatdata{accessory_id} = &listchoices({db=>$db, table=>'choose_accessory'});
		$compatdata{cameramodel_id} = $cameramodel_id;
		&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT', silent=>1});
		last if (!&prompt({default=>'yes', prompt=>'Add more accessory compatibility info?', type=>'boolean'}));
	}
	return;
}

# Add a compatible negative size to a known film format
sub negative_size_compat {
	my $href = shift;
	my $db = $href->{db};
	my %compatdata;
	$compatdata{format_id} = $href->{format_id} // &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT'});
	$compatdata{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add});
	&newrecord({db=>$db, data=>\%compatdata, table=>'NEGATIVEFORMAT_COMPAT', silent=>1});
	return $compatdata{negative_size_id};
}

# Add a compatible film format to a known negative size
sub format_compat {
        my $href = shift;
        my $db = $href->{db};
        my %compatdata;
        $compatdata{negative_size_id} = $href->{negative_size_id} // &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE'});
        $compatdata{format_id} = &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add});
        &newrecord({db=>$db, data=>\%compatdata, table=>'NEGATIVEFORMAT_COMPAT', silent=>1});
        return $compatdata{format_id};
}

# Add available shutter speed info to a camera model
sub cameramodel_shutterspeeds {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});
	my $min_shutter_speed = &listchoices({db=>$db, keyword=>'min (fastest) shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where shutter_speed not in ('B', 'T') and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where cameramodel_id=$cameramodel_id) order by duration", type=>'text', inserthandler=>\&shutterspeed_add, required=>1});
	&newrecord({db=>$db, data=>{cameramodel_id=>$cameramodel_id, shutter_speed=>$min_shutter_speed}, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});
	my $min_shutter_speed_duration = &duration($min_shutter_speed);
	my $max_shutter_speed = &listchoices({db=>$db, keyword=>'max (slowest) shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where shutter_speed not in ('B', 'T') and duration > $min_shutter_speed_duration and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where cameramodel_id=$cameramodel_id) order by duration", type=>'text', inserthandler=>\&shutterspeed_add, required=>1});
	my $max_shutter_speed_duration = &duration($max_shutter_speed);
	&newrecord({db=>$db, data=>{cameramodel_id=>$cameramodel_id, shutter_speed=>$max_shutter_speed}, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});

	while (1) {
		my %shutterdata;
		$shutterdata{shutter_speed} = &listchoices({db=>$db, keyword=>'shutter speed', query=>"SELECT shutter_speed as id, '' as opt FROM SHUTTER_SPEED where duration > $min_shutter_speed_duration and duration < $max_shutter_speed_duration and shutter_speed not in (select shutter_speed from SHUTTER_SPEED_AVAILABLE where cameramodel_id=$cameramodel_id) order by duration", type=>'text', inserthandler=>\&shutterspeed_add, required=>0});
		last if (!$shutterdata{shutter_speed});
		$shutterdata{cameramodel_id} = $cameramodel_id;
		&newrecord({db=>$db, data=>\%shutterdata, table=>'SHUTTER_SPEED_AVAILABLE', silent=>1});
	}
	return;
}

# Add available exposure program info to a camera
sub cameramodel_exposureprogram {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});
	my $exposureprograms = &lookupcol({db=>$db, table=>'EXPOSURE_PROGRAM'});
	foreach my $exposureprogram (@$exposureprograms) {
		# Skip 'creative' AE modes
		next if $exposureprogram->{exposure_program_id} == 5;
		next if $exposureprogram->{exposure_program_id} == 6;
		next if $exposureprogram->{exposure_program_id} == 7;
		next if $exposureprogram->{exposure_program_id} == 8;
		if (&prompt({default=>'no', prompt=>"Does this camera have $exposureprogram->{exposure_program} exposure program?", type=>'boolean'})) {
			my %epdata = ('cameramodel_id' => $cameramodel_id, 'exposure_program_id' => $exposureprogram->{exposure_program_id});
			&newrecord({db=>$db, data=>\%epdata, table=>'EXPOSURE_PROGRAM_AVAILABLE', silent=>1});
			last if $exposureprogram->{exposure_program_id} == 0;
		}
	}
	return;
}

# Add available metering mode info to a camera
sub cameramodel_meteringmode {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});
	my $meteringmodes = &lookupcol({db=>$db, table=>'METERING_MODE'});
	foreach my $meteringmode (@$meteringmodes) {
		if (&prompt({default=>'no', prompt=>"Does this camera have $meteringmode->{metering_mode} metering?", type=>'boolean'})) {
			my %mmdata = ('cameramodel_id' => $cameramodel_id, 'metering_mode_id' => $meteringmode->{metering_mode_id});
			&newrecord({db=>$db, data=>\%mmdata, table=>'METERING_MODE_AVAILABLE', silent=>1});
			last if $meteringmode->{metering_mode_id} == 0;
		}
	}
	return;
}

# Add a cameramodel to a series
sub cameramodel_series {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{cameramodel_id} = $href->{cameramodel_id} // &listchoices({db=>$db, table=>'choose_cameramodel', required=>1});
	$data{series_id} = $href->{series_id} // &listchoices({db=>$db, cols=>['series_id as id', 'name as opt'], table=>'SERIES', required=>1, inserthandler=>\&series_add});
	return &newrecord({db=>$db, data=>\%data, table=>'SERIES_MEMBER'});
}

# Associate a camera with a lens for display purposes
sub camera_displaylens {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $camera_id = $href->{camera_id} // &listchoices({db=>$db, keyword=>'camera', table=>'choose_camera', where=>{mount_id=>{'!=', undef}}, required=>1 });
	my $mount = &lookupval({db=>$db, col=>'mount_id', table=>'choose_camera', where=>{id=>$camera_id}});
	$data{display_lens} = &listchoices({db=>$db, table=>'choose_display_lens', where=>{camera_id=>[$camera_id, undef], mount_id=>$mount}, default=>&lookupval({db=>$db, col=>'display_lens', table=>'CAMERA', where=>{camera_id=>$camera_id}})});
	return &updaterecord({db=>$db, data=>\%data, table=>'CAMERA', where=>{camera_id=>$camera_id}});
}

# Search for a camera
sub camera_search {
	my $href = shift;
	my $db = $href->{db};
	my $searchterm = $href->{searchterm} // &prompt({prompt=>'Enter camera search term'});

	# Perform search
	my $id = &search({
		db         => $db,
		table      => 'choose_camera',
		searchterm => $searchterm,
		choices    => [
			{ desc => 'Do nothing' },
			{ handler => \&camera_info,                 desc => 'Get camera info',                     id=>'camera_id' },
			{ handler => \&cameramodel_accessory,       desc => 'Add accessory compatibility info',    id=>'camera_id' },
			{ handler => \&camera_displaylens,          desc => 'Associate with a lens for display',   id=>'camera_id' },
			{ handler => \&camera_edit,                 desc => 'Edit this camera',                    id=>'camera_id' },
			{ handler => \&cameramodel_exposureprogram, desc => 'Add available exposure program info', id=>'camera_id' },
			{ handler => \&cameramodel_meteringmode,    desc => 'Add available metering mode info',    id=>'camera_id' },
			{ handler => \&camera_repair,               desc => 'Repair this camera',                  id=>'camera_id' },
			{ handler => \&cameramodel_shutterspeeds,   desc => 'Add available shutter speed info',    id=>'camera_id' },
			{ handler => \&camera_sell,                 desc => 'Sell this camera',                    id=>'camera_id' },
			{ handler => \&film_load,                   desc => 'Load a film',                         id=>'camera_id' },
		],
	});
	return $id;
}

# Sell a camera
sub camera_sell {
	my $href = shift;
	my $db = $href->{db};
	my $camera_id = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_camera'});
	my %data;
	$data{own} = 0;
	$data{lost} = $href->{lost} // &prompt({default=>&today, prompt=>'What date was this camera sold?', type=>'date'});
	$data{lost_price} = $href->{lost_price} // &prompt({prompt=>'How much did this camera sell for?', type=>'decimal'});
	&updaterecord({db=>$db, data=>\%data, table=>'CAMERA', where=>{camera_id=>$camera_id}});
	&unsetdisplaylens({db=>$db, camera_id=>$camera_id});
	if (my $lens_id = &lookupval({db=>$db, col=>'lens_id', table=>'CAMERA', where=>{camera_id=>$camera_id}})) {
		my %lensdata;
		$lensdata{own} = 0;
		$lensdata{lost} = $data{lost};
		$lensdata{lost_price} = 0;
		&updaterecord({db=>$db, data=>\%lensdata, table=>'LENS', where=>{lens_id=>$lens_id}});
	}
	return;
}

# Repair a camera
sub camera_repair {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{camera_id} = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_camera'});
	$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'What date was this camera repaired?', type=>'date'});
	$data{summary} = $href->{summary} // &prompt({prompt=>'Short summary of repair'});
	$data{description} = $href->{description} // &prompt({prompt=>'Longer description of repair'});
	return &newrecord({db=>$db, data=>\%data, table=>'REPAIR'});
}

# Show information about a camera
sub camera_info {
	my $href = shift;
	my $db = $href->{db};

	# Choose camera
	my $camera_id = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_camera', required=>1});

	# Get camera data
	my $cameradata = &lookupcol({db=>$db, table=>'info_camera', where=>{'`Camera ID`'=>$camera_id}});

	# Get camera model
	my $cameramodel_id = ${@$cameradata[0]}{'Camera Model ID'};

	# Show compatible accessories
	my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{cameramodel_id=>$cameramodel_id}});
	${@$cameradata[0]}{'Accessories'} = $accessories;

	# Show compatible lenses
	my $lenses = &lookuplist({db=>$db, col=>'lens', table=>'cameralens_compat', where=>{camera_id=>$camera_id}});
	${@$cameradata[0]}{'Lenses'} = $lenses;

	print Dump($cameradata);
	return;
}

# Choose a camera based on several criteria
sub camera_choose {
	my $href = shift;
	my $db = $href->{db};
	my %where;
	$where{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$where{format_id} = $href->{format_id} // &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT'});
	$where{bulb} = $href->{bulb} // &prompt({prompt=>'Do you need Bulb (B) shutter speed?', type=>'boolean'});
	$where{time} = $href->{time} // &prompt({prompt=>'Do you need Time (T) shutter speed?', type=>'boolean'});
	$where{fixed_mount} = $href->{fixed_mount} // &prompt({prompt=>'Do you need a camera with an interchangeable lens?', type=>'boolean'});
	if ($where{fixed_mount} && $where{fixed_mount} != 1) {
		$where{mount_id} = $href->{mount_id} // &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}});
	}
	$where{focus_type_id} = $href->{focus_type_id} // &listchoices({db=>$db, cols=>['focus_type_id as id', 'focus_type as opt'], table=>'FOCUS_TYPE', 'integer'});
	$where{metering} = $href->{metering} // &prompt({prompt=>'Do you need a camera with metering?', type=>'boolean'});
	if ($where{metering} && $where{metering} == 1) {
		$where{coupled_metering} = $href->{coupled_metering} // &prompt({prompt=>'Do you need coupled metering?', type=>'boolean'});
		$where{metering_type_id} = $href->{metering_type_id} // &listchoices({db=>$db, cols=>['metering_type_id as id', 'metering as opt'], table=>'METERING_TYPE'});
	}
	$where{body_type_id} = $href->{body_type_id} // &listchoices({db=>$db, cols=>['body_type_id as id', 'body_type as opt'], table=>'BODY_TYPE'});
	$where{negative_size_id} = $href->{negative_size_id} // &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE'});
	$where{cable_release} = $href->{cable_release} // &prompt({prompt=>'Do you need a camera with cable release?', type=>'boolean'});
	$where{power_drive} = $href->{power_drive} // &prompt({prompt=>'Do you need a camera with power drive?', type=>'boolean'});
	$where{int_flash} = $href->{int_flash} // &prompt({prompt=>'Do you need a camera with internal flash?', type=>'boolean'});
	$where{ext_flash} = $href->{ext_flash} // &prompt({prompt=>'Do you need a camera that supports an external flash?', type=>'boolean'});
	if ($where{ext_flash} && $where{ext_flash} == 1) {
		$where{pc_sync} = $href->{pc_sync} // &prompt({prompt=>'Do you need a PC sync socket?', type=>'boolean'});
		$where{hotshoe} = $href->{hotshoe} // &prompt({prompt=>'Do you need a hot shoe?', type=>'boolean'});
	}
	if (($where{int_flash} && $where{int_flash} == 1) || ($where{ext_flash} && $where{ext_flash} == 1)) {
		$where{coldshoe} = $href->{coldshoe} // &prompt({prompt=>'Do you need a cold/accessory shoe?', type=>'boolean'});
		$where{flash_metering} = $href->{flash_metering} // &listchoices({db=>$db, table=>'choose_flash_protocol'});
	}
	$where{dof_preview} = $href->{dof_preview} // &prompt({prompt=>'Do you need a depth-of-field preview feature?', type=>'boolean'});
	$where{tripod} = $href->{tripod} // &prompt({prompt=>'Do you need a tripod bush?', type=>'boolean'});

	my $thinwhere = &thin(\%where);
	&printlist({db=>$db, msg=>"cameras that match your criteria", table=>'camera_chooser', where=>$thinwhere});
	return;
}

# Add a new negative to the database as part of a film
sub negative_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{film_id} = $href->{film_id} // &film_choose({db=>$db});
	if (!&lookupval({db=>$db, col=>'camera_id', table=>'FILM', where=>{film_id=>$data{film_id}}})) {
		print 'Film must be loaded into a camera before you can add negatives\n';
		if (&prompt({default=>'yes', prompt=>'Load film into a camera now?', type=>'boolean'})) {
			&film_load({db=>$db, film_id=>$data{film_id}});
		} else {
			return;
		}
	}
	$data{frame} = $href->{frame} // &prompt({prompt=>'Frame number'});
	$data{description} = $href->{description} // &prompt({prompt=>'Caption'});
	$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'What date was this negative taken?', type=>'date'});
	$data{lens_id} = $href->{lens_id} // &listchoices({db=>$db, keyword=>'lens', table=>'choose_lens_by_film', where=>{film_id=>$data{film_id}}});
	$data{shutter_speed} = $href->{shutter_speed} // &choose_shutterspeed({db=>$db, film_id=>$data{film_id}});
	$data{aperture} = $href->{aperture} // &prompt({prompt=>'Aperture', type=>'decimal'});
	my $filter_dia = 0;
	if ($data{lens_id}) {
		$filter_dia = &lookupval({db=>$db, col=>'if(filter_thread, filter_thread, 0)', table=>'LENS join LENSMODEL on LENS.lensmodel_id=LENSMODEL.lensmodel_id', where=>{lens_id=>$data{lens_id}}});
	}
	$data{filter_id} = $href->{filter_id} // &listchoices({db=>$db, table=>'choose_filter', where=>{'thread'=>{'>=', $filter_dia}}, inserthandler=>\&filter_add, skipok=>1, autodefault=>0});
	$data{teleconverter_id} = $href->{teleconverter_id} // &listchoices({db=>$db, keyword=>'teleconverter', table=>'choose_teleconverter_by_film', where=>{film_id=>$data{film_id}}, inserthandler=>\&teleconverter_add, skipok=>1, autodefault=>0});
	$data{notes} = $href->{notes} // &prompt({prompt=>'Extra notes'});
	$data{mount_adapter_id} = $href->{mount_adapter_id} // &listchoices({db=>$db, table=>'choose_mount_adapter_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
	$data{focal_length} = $href->{focal_length} // &prompt({default=>&lookupval({db=>$db, col=>'min_focal_length', table=>'LENS', where=>{lens_id=>$data{'lens_id'}}}), prompt=>'Focal length', type=>'integer'});
	$data{latitude} = $href->{latitude} // &prompt({prompt=>'Latitude', type=>'decimal'});
	$data{longitude} = $href->{longitude} // &prompt({prompt=>'Longitude', type=>'decimal'});
	$data{flash} = $href->{flash} // &prompt({default=>'no', prompt=>'Was flash used?', type=>'boolean'});
	$data{metering_mode} = $href->{metering_mode} // &listchoices({db=>$db, cols=>['metering_mode_id as id', 'metering_mode as opt'], table=>'METERING_MODE'});
	$data{exposure_program} = $href->{exposure_program} // &listchoices({db=>$db, cols=>['exposure_program_id as id', 'exposure_program as opt'], table=>'EXPOSURE_PROGRAM'});
	$data{photographer_id} = $href->{photographer_id} // &listchoices({db=>$db, keyword=>'photographer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
	if (&prompt({prompt=>'Is this negative duplicated from another?', type=>'boolean', default=>'no'})) {
		$data{copy_of} = $href->{copy_of} // &chooseneg({db=>$db, oktoreturnundef=>1});
	}
	return &newrecord({db=>$db, data=>\%data, table=>'NEGATIVE'});
}

# Bulk add multiple negatives to the database as part of a film
sub negative_bulkadd {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{film_id} = $href->{film_id} // &film_choose({db=>$db});
	my $num = &prompt({prompt=>'How many frames to add?', type=>'integer'});
	if (&prompt({default=>'no', prompt=>"Add any other attributes to all $num negatives?", type=>'boolean'})) {
		$data{description} = $href->{description} // &prompt({prompt=>'Caption'});
		$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'What date was this negative taken?', type=>'date'});
		$data{lens_id} = $href->{lens_id} // &listchoices({db=>$db, keyword=>'lens', table=>'choose_lens_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
		$data{shutter_speed} = $href->{shutter_speed} // &choose_shutterspeed({db=>$db, film_id=>$data{film_id}});
		$data{aperture} = $href->{aperture} // &prompt({prompt=>'Aperture', type=>'decimal'});
		$data{filter_id} = $href->{filter_id} // &listchoices({db=>$db, table=>'choose_filter', inserthandler=>\&filter_add, skipok=>1, autodefault=>0});
		$data{teleconverter_id} = $href->{teleconverter_id} // &listchoices({db=>$db, keyword=>'teleconverter', table=>'choose_teleconverter_by_film', where=>{film_id=>$data{film_id}}, inserthandler=>\&teleconverter_add, skipok=>1, autodefault=>0});
		$data{notes} = $href->{notes} // &prompt({prompt=>'Extra notes'});
		$data{mount_adapter_id} = $href->{mount_adapter_id} // &listchoices({db=>$db, table=>'choose_mount_adapter_by_film', where=>{film_id=>$data{film_id}}, skipok=>1});
		$data{focal_length} = $href->{focal_length} // &prompt({default=>&lookupval({db=>$db, col=>'min_focal_length', table=>'LENS', where=>{lens_id=>$data{lens_id}}}), prompt=>'Focal length', type=>'integer'});
		$data{latitude} = $href->{latitude} // &prompt({prompt=>'Latitude', type=>'decimal'});
		$data{longitude} = $href->{longitude} // &prompt({prompt=>'Longitude', type=>'decimal'});
		$data{flash} = $href->{flash} // &prompt({default=>'no', prompt=>'Was flash used?', type=>'boolean'});
		$data{metering_mode} = $href->{metering_mode} // &listchoices({db=>$db, cols=>['metering_mode_id as id', 'metering_mode as opt'], table=>'METERING_MODE'});
		$data{exposure_program} = $href->{exposure_program} // &listchoices({db=>$db, cols=>['exposure_program_id as id', 'exposure_program as opt'], table=>'EXPOSURE_PROGRAM'});
		$data{photographer_id} = $href->{photographer_id} // &listchoices({db=>$db, keyword=>'photographer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
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
	my $href = shift;
	my $db = $href->{db};
	my $negative_id = $href->{negative_id} // &chooseneg({db=>$db});
	print Dump(&lookupcol({db=>$db, table=>'info_negative', where=>{'`Negative ID`'=>$negative_id}}));
	return;
}

# Find all prints made from a negative
sub negative_prints {
	my $href = shift;
	my $db = $href->{db};
	my $neg_id = &chooseneg({db=>$db});
	&printlist({db=>$db, msg=>"prints from negative $neg_id", cols=>'Print as id, concat(Size, \' - \', Location) as opt', table=>'info_print', where=>{'`Negative ID`'=>$neg_id}});
	return;
}

# Write EXIF tags to scans from a negative
sub negative_tag {
	my $href = shift;
	my $db = $href->{db};
	my $neg_id = $href->{negative_id} // &chooseneg({db=>$db});
	&tag({db=>$db, where=>{negative_id=>$neg_id}});
	return;
}

# Search for a negative
sub negative_search {
	my $href = shift;
	my $db = $href->{db};
	my $searchterm = $href->{searchterm} // &prompt({prompt=>'Enter search term'});

	# Perform search
	my $id = &search({
	db         => $db,
		cols       => ["concat(film_id, '/', frame) as id", 'description as opt'],
		table      => 'NEGATIVE',
		where      => "description like '%$searchterm%' collate utf8mb4_general_ci",
		searchterm => $searchterm,
		choices    => [
			{ desc => 'Do nothing' },
			{ handler => \&negative_info,   desc => 'Show information about this  negative',       id=>'negative_id' },
			{ handler => \&negative_prints, desc => 'Find all prints made from this negative',     id=>'negative_id' },
			{ handler => \&negative_tag,    desc => 'Write EXIF tags to scans from this negative', id=>'negative_id' },
		],
	});
	return $id;
}

# Add a new lens to the database
sub lens_add {
	my $href = shift;
	my $db = $href->{db};

	my %data;
	my $manufacturer_id = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{lensmodel_id} = $href->{lensmodel_id} // &listchoices({db=>$db, table=>'choose_lensmodel', where=>{'manufacturer_id'=>$manufacturer_id}, required=>1, inserthandler=>\&lensmodel_add});
	$data{cost} = $href->{cost} // &prompt({prompt=>'How much did this lens cost?', type=>'decimal'});
	$data{serial} = $href->{serial} // &prompt({prompt=>'What is the serial number of the lens?'});
	$data{date_code} = $href->{date_code} // &prompt({prompt=>'What is the date code of the lens?'});

	# Attempt to decode datecode for Canon lenses
	my $manufactured;
	if ($manufacturer_id == 3 && $data{date_code}) {
		my $introduced = &lookupval({db=>$db, col=>'introduced', table=>'LENSMODEL', where=>{lensmodel_id=>$data{lensmodel_id}}});
		my $discontinued = &lookupval({db=>$db, col=>'discontinued', table=>'LENSMODEL', where=>{lensmodel_id=>$data{lensmodel_id}}});
		$manufactured = &canondatecode({datecode=>$data{date_code}, introduced=>$introduced, discontinued=>$discontinued});
	}

	$data{manufactured} = $href->{manufactured} // &prompt({prompt=>'When was this lens manufactured?', type=>'integer', default=>$manufactured});
	$data{acquired} = $href->{acquired} // &prompt({prompt=>'When was this lens acquired?', type=>'date', default=>&today});
	$data{own} = $href->{own} // &prompt({prompt=>'Do you own this lens?', type=>'boolean', default=>'yes'});
	$data{source} = $href->{source} // &prompt({prompt=>'Where was this lens sourced from?'});
	$data{condition_id} = $href->{condition_id} // &listchoices({db=>$db, keyword=>'condition', cols=>['condition_id as id', 'name as opt'], table=>'`CONDITION`'});

	my $lens_id = &newrecord({db=>$db, data=>\%data, table=>'LENS'});
	return $lens_id;
}

# Add a new lens model to the database
sub lensmodel_add {
	my $href = shift;
	my $db = $href->{db};

	# Gather data from user
	my $datahr = &lensmodel_prompt({db=>$db});
	my %data = %$datahr;

	my $lensmodel_id = &newrecord({db=>$db, data=>\%data, table=>'LENSMODEL'});

	if (&prompt({default=>'yes', prompt=>'Add accessory compatibility for this lens model?', type=>'boolean'})) {
		&lensmodel_accessory({db=>$db, lensmodel_id=>$lensmodel_id});
	}

	if (&prompt({default=>'no', prompt=>'Add this lens model to a series?', type=>'boolean'})) {
		&lensmodel_series({db=>$db, lensmodel_id=>$lensmodel_id});
	}
	return $lensmodel_id;
}

# Edit an existing lens model
sub lensmodel_edit {
	my $href = shift;
	my $db = $href->{db};
	my $lens_id = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lens', required=>1});
	my $existing = &lookupcol({db=>$db, table=>'LENS', where=>{lens_id=>$lens_id}});
	$existing = @$existing[0];

	# Gather data from user
	my $data = &lens_prompt({db=>$db, defaults=>$existing});

	# Compare new and old data to find changed fields
	my $changes = &hashdiff($existing, $data);

	# Update the DB
	return &updaterecord({db=>$db, data=>$changes, table=>'LENS', where=>{lens_id=>$lens_id}});
}

sub lensmodel_prompt {
	my $href = shift;
	my $db = $href->{db};
	my $defaults = $href->{defaults};
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
	$data{introduced} = &prompt({prompt=>'When was this lens introduced?', type=>'integer', default=>$$defaults{introduced}});
	$data{discontinued} = &prompt({prompt=>'When was this lens discontinued?', type=>'integer', default=>$$defaults{discontinued}});
	$data{negative_size_id} = &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add, default=>$$defaults{negative_size_id}});
	$data{notes} = &prompt({prompt=>'Notes', default=>$$defaults{notes}});
	$data{coating} = &prompt({prompt=>'What coating does this lens have?', default=>$$defaults{coating}});
	$data{hood} = &prompt({prompt=>'What is the model number of the suitable hood for this lens?', default=>$$defaults{hood}});
	$data{exif_lenstype} = &prompt({prompt=>'EXIF lens type code', default=>$$defaults{exif_lenstype}});
	$data{rectilinear} = &prompt({prompt=>'Is this a rectilinear lens?', type=>'boolean', default=>$$defaults{rectilinear}//'yes'});
	$data{image_circle} = &prompt({prompt=>'What is the diameter of the image circle?', type=>'integer', default=>$$defaults{image_circle}});
	$data{formula} = &prompt({prompt=>'Does this lens have a named optical formula?', default=>$$defaults{formula}});
	$data{shutter_model} = &prompt({prompt=>'What shutter does this lens incorporate?', default=>$$defaults{shutter_model}});
	return \%data;
}

# Add accessory compatibility info to a lens
sub lensmodel_accessory {
	my $href = shift;
	my $db = $href->{db};
	my $lensmodel_id = $href->{lensmodel_id} // &listchoices({db=>$db, table=>'choose_lensmodel', required=>1});
	while (1) {
		my %compatdata;
		$compatdata{accessory_id} = $href->{accessory_id} // &listchoices({db=>$db, table=>'choose_accessory'});
		$compatdata{lensmodel_id} = $lensmodel_id;
		&newrecord({db=>$db, data=>\%compatdata, table=>'ACCESSORY_COMPAT'});
		last if (!&prompt({default=>'yes', prompt=>'Add more accessory compatibility info?', type=>'boolean'}));
	}
	return;
}

# Add a lensmodel to a series
sub lensmodel_series {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{lensmodel_id} = $href->{lensmodel_id} // &listchoices({db=>$db, table=>'choose_lensmodel', required=>1});
	$data{series_id} = $href->{series_id} // &listchoices({db=>$db, cols=>['series_id as id', 'name as opt'], table=>'SERIES', required=>1, inserthandler=>\&series_add});
	return &newrecord({db=>$db, data=>\%data, table=>'SERIES_MEMBER'});
}

# Show information about a lensmodel
sub lensmodel_info {
        my $href = shift;
        my $db = $href->{db};

        # Choose lens
        my $lensmodel_id = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lensmodel', required=>1});

        # Get lens data
        my $lensdata = &lookupcol({db=>$db, table=>'info_lensmodel', where=>{'`Lens Model ID`'=>$lensmodel_id}});

        # Show compatible accessories
        my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{lensmodel_id=>$lensmodel_id}});
        ${@$lensdata[0]}{'Accessories'} = $accessories;

        # Show compatible cameras
        my $cameras = &lookuplist({db=>$db, col=>'camera', table=>'cameralens_compat', where=>{lensmodel_id=>$lensmodel_id}});
        ${@$lensdata[0]}{'Cameras'} = $cameras;

        print Dump($lensdata);
        return;
}

# Search for a lens
sub lens_search {
	my $href = shift;
	my $db = $href->{db};
	my $searchterm = $href->{searchterm} // &prompt({prompt=>'Enter search term'});

	# Perform search
	my $id = &search({
		db         => $db,
		cols       => ['id', 'opt'],
		table      => 'choose_lens',
		where      => "opt like '%$searchterm%' collate utf8mb4_general_ci",
		searchterm => $searchterm,
		choices    => [
			{ desc => 'Do nothing' },
			{ handler => \&lens_accessory, desc => 'Add accessory compatibility info to this lens', id=>'lens_id' },
			{ handler => \&lens_edit,      desc => 'Edit this lens',                                id=>'lens_id' },
			{ handler => \&lens_info,      desc => 'Show information about this lens',              id=>'lens_id' },
			{ handler => \&lens_repair,    desc => 'Repair this lens',                              id=>'lens_id' },
			{ handler => \&lens_sell,      desc => 'Sell this lens',                                id=>'lens_id' },
		],
	});
	return $id;
}

# Sell a lens
sub lens_sell {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $lens_id = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lens', required=>1});
	$data{own} = 0;
	$data{lost} = $href->{lost} // &prompt({default=>&today, prompt=>'What date was this lens sold?', type=>'date'});
	$data{lost_price} = $href->{lost_price} // &prompt({prompt=>'How much did this lens sell for?', type=>'decimal'});
	&unsetdisplaylens({db=>$db, lens_id=>$lens_id});
	return &updaterecord({db=>$db, data=>\%data, table=>'LENS', where=>{lens_id=>$lens_id}});
}

# Repair a lens
sub lens_repair {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{lens_id} = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lens', required=>1});
	$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'What date was this lens repaired?', type=>'date'});
	$data{summary} = $href->{summary} // &prompt({prompt=>'Short summary of repair'});
	$data{description} = $href->{description} // &prompt({prompt=>'Longer description of repair'});
	return &newrecord({db=>$db, data=>\%data, table=>'REPAIR'});
}

# Show information about a lens
sub lens_info {
	my $href = shift;
	my $db = $href->{db};

	# Choose lens
	my $lens_id = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lens', required=>1});

	# Get lens data
	my $lensdata = &lookupcol({db=>$db, table=>'info_lens', where=>{'`Lens ID`'=>$lens_id}});

	# Get lens model
	my $lensmodel_id = ${@$lensdata[0]}{'Lens Model ID'};

	# Show compatible accessories
	my $accessories = &lookuplist({db=>$db, col=>'opt', table=>'choose_accessory_compat', where=>{lensmodel_id=>$lensmodel_id}});
	${@$lensdata[0]}{'Accessories'} = $accessories;

	# Show compatible cameras
	my $cameras = &lookuplist({db=>$db, col=>'camera', table=>'cameralens_compat', where=>{lens_id=>$lens_id}});
	${@$lensdata[0]}{'Cameras'} = $cameras;

	print Dump($lensdata);

	# Generate and print lens statistics
	my $lens = ${@$lensdata[0]}{'Lens'};
	print "\tShowing statistics for $lens\n";
	my $maxaperture = &lookupval({db=>$db, col=>'max_aperture', table=>'LENSMODEL', where=>{lensmodel_id=>$lensmodel_id}});
	my $modeaperture = &lookupval({db=>$db, query=>"select aperture from NEGATIVE where aperture is not null and lens_id=$lens_id group by aperture order by count(aperture) desc limit 1"});
	print "\tThis lens has a maximum aperture of f/$maxaperture but you most commonly use it at f/$modeaperture\n";
	if (&lookupval({db=>$db, col=>'zoom', table=>'LENSMODEL', where=>{lensmodel_id=>$lensmodel_id}})) {
		my $minf = &lookupval({db=>$db, col=>'min_focal_length', table=>'LENSMODEL', where=>{lensmodel_id=>$lensmodel_id}});
		my $maxf = &lookupval({db=>$db, col=>'max_focal_length', table=>'LENSMODEL', where=>{lensmodel_id=>$lensmodel_id}});
		my $meanf = &lookupval({db=>$db, col=>'avg(focal_length)', table=>'NEGATIVE', where=>{lens_id=>$lens_id}});
		print "\tThis is a zoom lens with a range of ${minf}-${maxf}mm, but the average focal length you used is ${meanf}mm\n";
	}
	return;
}

# Add a new print that has been made from a negative
sub print_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $todo_id = $href->{todo_id} // &listchoices({db=>$db, keyword=>'print from the order queue', table=>'choose_todo'});
	if ($todo_id) {
		$data{negative_id} = $href->{negative_id} // &lookupval({db=>$db, col=>'negative_id', table=>'TO_PRINT', where=>{id=>$todo_id}});
	} else {
		$data{negative_id} = $href->{negative_id} // &chooseneg({db=>$db});
	}
	my $qty = $href->{qty} // &prompt({default=>1, prompt=>'How many similar prints did you make from this negative?', type=>'integer'});
	print "Enter some data about all the prints in the run:\n" if ($qty > 1);
	$data{date} = $href->{date} // &prompt({default=>&today, prompt=>'Date that the print was made', type=>'date'});
	$data{paper_stock_id} = $href->{paper_stock_id} // &listchoices({db=>$db, keyword=>'paper stock', table=>'choose_paper', inserthandler=>\&paperstock_add});
	$data{height} = $href->{height} // &prompt({prompt=>'Height of the print (inches)', type=>'integer'});
	$data{width} = $href->{width} // &prompt({prompt=>'Width of the print (inches)', type=>'integer'});
	$data{enlarger_id} = $href->{enlarger_id} // &listchoices({db=>$db, table=>'choose_enlarger', inserthandler=>\&enlarger_add});
	$data{lens_id} = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_enlarger_lens'});
	$data{developer_id} = $href->{developer_id} // &listchoices({db=>$db, cols=>['developer_id as id', 'name as opt'], table=>'DEVELOPER', where=>{'for_paper'=>1}, inserthandler=>\&developer_add});
	$data{printer_id} = $href->{printer_id} // &listchoices({db=>$db, keyword=>'printer', cols=>['person_id as id', 'name as opt'], table=>'PERSON', inserthandler=>\&person_add});
	my @prints;
	for my $n (1..$qty) {
		print "\nEnter some data about print $n of $qty in this run:\n" if ($qty > 1);
		$data{aperture} = $href->{aperture} // &prompt({prompt=>'Aperture used on enlarging lens', type=>'decimal'});
		$data{exposure_time} = $href->{exposure_time} // &prompt({prompt=>'Exposure time (s)', type=>'integer'});
		$data{filtration_grade} = $href->{filtration_grade} // &prompt({prompt=>'Filtration grade', type=>'decimal'});
		$data{development_time} = $href->{development_time} // &prompt({default=>'60', prompt=>'Development time (s)', type=>'integer'});
		$data{fine} = $href->{fine} // &prompt({prompt=>'Is this a fine print?', type=>'boolean'});
		$data{notes} = $href->{notes} // &prompt({prompt=>'Notes'});
		my $print_id = &newrecord({db=>$db, data=>\%data, table=>'PRINT'});
		push @prints, $print_id;

		&print_tone({db=>$db, print_id=>$print_id}) if (&prompt({default=>'no', prompt=>'Did you tone this print?', type=>'boolean'}));
		&print_archive({db=>$db, print_id=>$print_id}) if (&prompt({default=>'no', prompt=>'Archive this print?', type=>'boolean'}));
	}

	print "\nAdded $qty prints in this run, numbered #$prints[0]-$prints[-1]\n" if ($qty > 1);

	# Mark is as complete in the todo list
	&updaterecord({db=>$db, data=>{printed=>1, print_id=>$prints[-1]}, table=>'TO_PRINT', where=>{id=>$todo_id}}) if ($todo_id);

	# Return ID of the last print in the run
	return $prints[-1];
}

# Fulfil an order for a print
sub print_fulfil {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $todo_id = $href->{todo_id} // &listchoices({db=>$db, keyword=>'print from the queue', table=>'choose_todo', required=>1});
	$data{printed} = $href->{printed} // &prompt({default=>'yes', prompt=>'Is this print order now fulfilled?', type=>'boolean'});
	$data{print_id} = $href->{print_id} // &prompt({prompt=>'Which print fulfilled this order?', type=>'integer'});
	return &updaterecord({db=>$db, data=>\%data, table=>'TO_PRINT', where=>{id=>$todo_id}});
}

# Add toning to a print
sub print_tone {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print did you tone?', type=>'integer', required=>1});
	$data{bleach_time} = $href->{bleach_time} // &prompt({default=>'00:00:00', prompt=>'How long did you bleach for? (HH:MM:SS)', type=>'time'});
	$data{toner_id} = $href->{toner_id} // &listchoices({db=>$db, cols=>['toner_id as id', 'toner as opt'], table=>'TONER', inserthandler=>\&toner_add});
	my $dilution1 = &lookupval({db=>$db, col=>'stock_dilution', table=>'TONER', where=>{toner_id=>$data{toner_id}}});
	$data{toner_dilution} = $href->{toner_dilution} // &prompt({default=>$dilution1, prompt=>'What was the dilution of the first toner?'});
	$data{toner_time} = $href->{toner_time} // &prompt({prompt=>'How long did you tone for? (HH:MM:SS)', type=>'time'});
	if (&prompt({default=>'no', prompt=>'Did you use a second toner?', type=>'boolean'}) == 1) {
		$data{'2nd_toner_id'} = $href->{'2nd_toner_id'} // &listchoices({db=>$db, cols=>['toner_id as id', 'toner as opt'], table=>'TONER', inserthandler=>\&toner_add});
		my $dilution2 = &lookupval({db=>$db, col=>'stock_dilution', table=>'TONER', where=>{toner_id=>$data{'2nd_toner_id'}}});
		$data{'2nd_toner_dilution'} = $href->{'2nd_toner_dilution'} // &prompt({default=>$dilution2, prompt=>'What was the dilution of the second toner?'});
		$data{'2nd_toner_time'} = $href->{'2nd_toner_time'} // &prompt({prompt=>'How long did you tone for? (HH:MM:SS)', type=>'time'});
	}
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>{print_id=>$print_id}});
}

# Sell a print
sub print_sell {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print did you sell?', type=>'integer', required=>1});
	$data{own} = 0;
	$data{location} = $href->{location} // &prompt({prompt=>'What happened to the print?'});
	$data{sold_price} = $href->{sold_price} // &prompt({prompt=>'What price was the print sold for?', type=>'decimal'});
	&print_unarchive({db=>$db, print_id=>$print_id});
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>{print_id=>$print_id}});
}

# Register an order for a print
sub print_order {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{negative_id} = $href->{negative_id} // &chooseneg({db=>$db});
	$data{height} = $href->{height} // &prompt({prompt=>'Height of the print (inches)', type=>'integer'});
	$data{width} = $href->{width} // &prompt({prompt=>'Width of the print (inches)', type=>'integer'});
	$data{recipient} = $href->{recipient} // &prompt({prompt=>'Who is the print for?'});
	$data{added} = $href->{added} // &prompt({default=>&today, prompt=>'Date that this order was placed', type=>'date'});
	return &newrecord({db=>$db, data=>\%data, table=>'TO_PRINT'});
}

# Add a print to a physical archive
sub print_archive {
	# Archive a print for storage
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print did you archive?', type=>'integer', required=>1});
	$data{archive_id} = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{'archive_type_id'=>3, 'sealed'=>0}, inserthandler=>\&archive_add, required=>1});
	$data{own} = 1;
	$data{location} = 'Archive';
	return &updaterecord({db=>$db, data=>\%data, table=>'PRINT', where=>{print_id=>$print_id}});
}

# Remove a print from a physical archive
sub print_unarchive {
	# Remove a print from an archive
	my $href = shift;
	my $db = $href->{db};
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print did you remove from its archive?', type=>'integer', required=>1});
	return &call({db=>$db, procedure=>'print_unarchive', args=>[$print_id]});
}

# Locate a print in an archive
sub print_locate {
	my $href = shift;
	my $db = $href->{db};
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print do you want to locate?', type=>'integer', required=>1});

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
	my $href = shift;
	my $db = $href->{db};
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print do you want info on?', type=>'integer', required=>1});
	print Dump(&lookupcol({db=>$db, table=>'info_print', where=>{Print=>$print_id}}));
	return;
}

# Exhibit a print in an exhibition
sub print_exhibit {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{print_id} = &prompt({prompt=>'Which print do you want to exhibit?', type=>'integer', required=>1});
	$data{exhibition_id} = &listchoices({db=>$db, cols=>['exhibition_id as id', 'title as opt'], table=>'EXHIBITION', inserthandler=>\&exhibition_add, required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'EXHIBIT'});
}

# Generate text to label a print
sub print_label {
	my $href = shift;
	my $db = $href->{db};
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print do you want to label?', type=>'integer', required=>1});
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
	my $href = shift;
	my $db = $href->{db};
	my $data = &lookupcol({db=>$db, table=>'choose_todo'});

	foreach my $row (@$data) {
		print "\t$row->{opt}\n";
	}
	return;
}

# Write EXIF tags to scans from a print
sub print_tag {
	my $href = shift;
	my $db = $href->{db};
	my $print_id = $href->{print_id} // &prompt({prompt=>'Which print do you want to tag?', type=>'integer', required=>1});
	&tag({db=>$db, where=>{print_id=>$print_id}});
	return;
}

# Add a new type of photo paper to the database
sub paperstock_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{name} = $href->{name} // &prompt({prompt=>'What model is the paper?'});
	$data{resin_coated} = $href->{resin_coated} // &prompt({prompt=>'Is this paper resin-coated?', type=>'boolean'});
	$data{tonable} = $href->{tonable} // &prompt({prompt=>'Is this paper tonable?', type=>'boolean'});
	$data{colour} = $href->{colour} // &prompt({prompt=>'Is this a colour paper?', type=>'boolean'});
	$data{finish} = $href->{finish} // &prompt({prompt=>'What surface finish does this paper have?'});
	return &newrecord({db=>$db, data=>\%data, table=>'PAPER_STOCK'});
}

# Add a new developer to the database
sub developer_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{name} = $href->{name} // &prompt({prompt=>'What model is the developer?'});
	$data{for_paper} = $href->{for_paper} // &prompt({prompt=>'Is this developer suitable for paper?', type=>'boolean'});
	$data{for_film} = $href->{for_film} // &prompt({prompt=>'Is this developer suitable for film?', type=>'boolean'});
	$data{chemistry} = $href->{chemistry} // &prompt({prompt=>'What type of chemistry is this developer based on?'});
	return &newrecord({db=>$db, data=>\%data, table=>'DEVELOPER'});
}

# Add a new lens mount to the database
sub mount_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{mount} = $href->{mount} // &prompt({prompt=>'What is the name of this lens mount?'});
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{fixed} = $href->{fixed} // &prompt({default=>'no', prompt=>'Is this a fixed mount?', type=>'boolean'});
	$data{shutter_in_lens} = $href->{shutter_in_lens} // &prompt({default=>'no', prompt=>'Does this mount contain the shutter in the lens?', type=>'boolean'});
	$data{type} = $href->{type} // &prompt({prompt=>'What type of mounting does this mount use? (e.g. bayonet, screw, etc)'});
	$data{purpose} = $href->{purpose} // &prompt({default=>'camera', prompt=>'What is the intended purpose of this mount? (e.g. camera, enlarger, projector, etc)'});
	$data{digital_only} = $href->{digital_only} // &prompt({default=>'no', prompt=>'Is this a digital-only mount?', type=>'boolean'});
	$data{notes} = $href->{notes} // &prompt({prompt=>'Notes about this mount'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOUNT'});
}

# View compatible cameras and lenses for a mount
sub mount_info {
	my $href = shift;
	my $db = $href->{db};
	my $mountid = $href->{mount_id} // &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', required=>1});
	my $mount = &lookupval({db=>$db, col=>'mount', table=>'choose_mount', where=>{mount_id=>${mountid}}});
	print "Showing data for $mount mount\n";
	&printlist({db=>$db, msg=>"cameras with $mount mount", cols=>"distinct camera_id as id, camera as opt", table=>'cameralens_compat', where=>{mount_id=>$mountid}, order=>'opt'});
	&printlist({db=>$db, msg=>"lenses with $mount mount", cols=>"distinct lens_id as id, lens as opt", table=>'cameralens_compat', where=>{mount_id=>$mountid}, order=>'opt'});
	return;
}

# Add a new chemical toner to the database
sub toner_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{toner} = $href->{toner} // &prompt({prompt=>'What is the name of this toner?'});
	$data{formulation} = $href->{formulation} // &prompt({prompt=>'What is the chemical formulation of this toner?'});
	$data{stock_dilution} = $href->{stock_dilution} // &prompt({prompt=>'What is the stock dilution of this toner?'});
	return &newrecord({db=>$db, data=>\%data, table=>'TONER'});
}

# Add a new type of filmstock to the database
sub filmstock_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{name} = $href->{name} // &prompt({prompt=>'What is the name of this filmstock?'});
	$data{iso} = $href->{iso} // &prompt({prompt=>'What is the box ISO/ASA speed of this filmstock?', type=>'integer'});
	$data{colour} = $href->{colour} // &prompt({prompt=>'Is this a colour film?', type=>'boolean'});
	if ($data{colour} == 1) {
		$data{panchromatic} = 1;
	} else {
		$data{panchromatic} = $href->{panchromatic} // &prompt({default=>'yes', prompt=>'Is this a panchromatic film?', type=>'boolean'});
	}
	$data{process_id} = $href->{process_id} // &listchoices({db=>$db, cols=>['process_id as id', 'name as opt'], table=>'PROCESS', inserthandler=>\&process_add});
	return &newrecord({db=>$db, data=>\%data, table=>'FILMSTOCK'});
}

# Add a new teleconverter to the database
sub teleconverter_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{model} = $href->{model} // &prompt({prompt=>'What is the model of this teleconverter?'});
	$data{factor} = $href->{factor} // &prompt('', 'What is the magnification factor of this teleconverter?', 'decimal');
	$data{mount_id} = $href->{mount_id} // &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{elements} = $href->{elements} // &prompt({prompt=>'How many elements does this teleconverter have?', type=>'integer'});
	$data{groups} = $href->{groups} // &prompt({prompt=>'How many groups are the elements arranged in?', type=>'integer'});
	$data{multicoated} = $href->{multicoated} // &prompt({prompt=>'Is this teleconverter multicoated?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'TELECONVERTER'});
}

# Add a new (optical) filter to the database
sub filter_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{type} = $href->{type} // &prompt({prompt=>'What type of filter is this?'});
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{attenuation} = $href->{attenuation} // &prompt({prompt=>'What attenutation (in stops) does this filter have?', type=>'decimal'});
	$data{thread} = $href->{thread} // &prompt({prompt=>'What diameter mounting thread does this filter have?', type=>'decimal'});
	$data{qty} = $href->{qty} // &prompt({default=>1, prompt=>'How many of these filters do you have?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILTER'});
}

# Add a new development process to the database
sub process_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{name} = $href->{name} // &prompt({prompt=>'What is the name of this film process?'});
	$data{colour} = $href->{colour} // &prompt({prompt=>'Is this a colour process?', type=>'boolean'});
	$data{positive} = $href->{positive} // &prompt({prompt=>'Is this a reversal process?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'PROCESS'});
}

# Add a filter adapter to the database
sub filter_adapt {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{camera_thread} = $href->{camera_thread} // &prompt({prompt=>'What diameter thread faces the camera on this filter adapter?', type=>'decimal'});
	$data{filter_thread} = $href->{filter_thread} // &prompt({prompt=>'What diameter thread faces the filter on this filter adapter?', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'FILTER_ADAPTER'});
}

# Add a new manufacturer to the database
sub manufacturer_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer} = $href->{manufacturer} // &prompt({prompt=>'What is the name of the manufacturer?', required=>1});
	$data{country} = $href->{country} // &prompt({prompt=>'What country is the manufacturer based in?'});
	$data{city} = $href->{city} // &prompt({prompt=>'What city is the manufacturer based in?'});
	$data{url} = $href->{url} // &prompt({prompt=>'What is the main website of the manufacturer?'});
	$data{founded} = $href->{founded} // &prompt({prompt=>'When was the manufacturer founded?', type=>'integer'});
	$data{dissolved} = $href->{dissolved} // &prompt({prompt=>'When was the manufacturer dissolved?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'MANUFACTURER'});
}

# Add a new "other" accessory to the database
sub accessory_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{accessory_type_id} = $href->{accessory_type_id} // &listchoices({db=>$db, cols=>['accessory_type_id as id', 'accessory_type as opt'], table=>'ACCESSORY_TYPE', inserthandler=>\&accessory_type});
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{model} = $href->{model} // &prompt({prompt=>'What is the model of this accessory?'});
	$data{acquired} = $href->{acquired} // &prompt({default=>&today, prompt=>'When was this accessory acquired?', type=>'date'});
	$data{cost} = $href->{cost} // &prompt({prompt=>'What did this accessory cost?', type=>'decimal'});
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
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{accessory_type} = $href->{accessory_type} // &prompt({prompt=>'What category of accessory do you want to add?'});
	return &newrecord({db=>$db, data=>\%data, table=>'ACCESSORY_TYPE'});
}

# Display info about an accessory
sub accessory_info {
	my $href = shift;
	my $db = $href->{db};
	my $accessory_id = $href->{accessory_id} // &listchoices({db=>$db, table=>'choose_accessory'});
	print Dump(&lookupcol({db=>$db, table=>'info_accessory', where=>{'`Accessory ID`'=>$accessory_id}}));
	return;
}

# Search for an accessory
sub accessory_search {
	my $href = shift;
	my $db = $href->{db};
	my $searchterm = $href->{searchterm} // &prompt({prompt=>'Enter search term'});

	# Perform search
	my $id = &search({
		db         => $db,
		cols       => ['id', 'opt'],
		table      => 'choose_accessory',
		where      => "opt like '%$searchterm%' collate utf8mb4_general_ci",
		searchterm => $searchterm,
		choices    => [
			{ desc => 'Do nothing' },
			{ handler => \&accessory_info, desc => 'Display info about an accessory', id=>'accessory_id' },
		],
	});
	return $id;
}

# Add a new enlarger to the database
sub enlarger_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{enlarger} = $href->{enlarger} // &prompt({prompt=>'What is the model of this enlarger?'});
	$data{negative_size_id} = $href->{negative_size_id} // &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add});
	$data{introduced} = $href->{introduced} // &prompt({prompt=>'What year was this enlarger introduced?', type=>'integer'});
	$data{discontinued} = $href->{discontinued} // &prompt({prompt=>'What year was this enlarger discontinued?', type=>'integer'});
	$data{acquired} = $href->{acquired} // &prompt({default=>&today, prompt=>'Purchase date', type=>'date'});
	$data{cost} = $href->{cost} // &prompt({prompt=>'Purchase price', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'ENLARGER'});
}

# Display info about an enlarger
sub enlarger_info {
	my $href = shift;
	my $db = $href->{db};
	my $enlarger_id = $href->{enlarger_id} // &listchoices({db=>$db, table=>'choose_enlarger', required=>1});
	print Dump(&lookupcol({db=>$db, table=>'info_enlarger', where=>{'`Enlarger ID`'=>$enlarger_id}}));
	return;
}

# Sell an enlarger
sub enlarger_sell {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $enlarger_id = $href->{enlarger_id} // &listchoices({db=>$db, table=>'choose_enlarger', required=>1});
	$data{lost} = $href->{lost} // &prompt({default=>&today, prompt=>'What date was this enlarger sold?', type=>'date'});
	$data{lost_price} = $href->{lost_price} // &prompt({prompt=>'How much did this enlarger sell for?', type=>'decimal'});
	return &updaterecord({db=>$db, data=>\%data, table=>'ENLARGER', where=>{enlarger_id=>$enlarger_id}});
}

# Add a new flash to the database
sub flash_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{model} = $href->{model} // &prompt({prompt=>'What is the model of this flash?'});
	$data{guide_number} = $href->{guide_number} // &prompt({prompt=>'What is the guide number of this flash?', type=>'integer'});
	$data{gn_info} = $href->{gn_info} // &prompt({default=>'ISO 100', prompt=>'What are the conditions of the guide number?'});
	$data{battery_powered} = $href->{battery_powered} // &prompt({default=>'yes', prompt=>'Is this flash battery-powered?', type=>'boolean'});
	if ($data{battery_powered} == 1) {
		$data{battery_type_id} = $href->{battery_type_id} // &listchoices({db=>$db, keyword=>'battery type', table=>'choose_battery', inserthandler=>\&battery_add});
		$data{battery_qty} = $href->{battery_qty} // &prompt({prompt=>'How many batteries does this flash need?', type=>'integer'});
	}
	$data{pc_sync} = $href->{pc_sync} // &prompt({default=>'yes', prompt=>'Does this flash have a PC sync socket?', type=>'boolean'});
	$data{hot_shoe} = $href->{hot_shoe} // &prompt({default=>'yes', prompt=>'Does this flash have a hot shoe connector?', type=>'boolean'});
	$data{light_stand} = $href->{light_stand} // &prompt({default=>'yes', prompt=>'Can this flash be fitted onto a light stand?', type=>'boolean'});
	$data{manual_control} = $href->{manual_control} // &prompt({default=>'yes', prompt=>'Does this flash have manual power control?', type=>'boolean'});
	$data{swivel_head} = $href->{swivel_head} // &prompt({default=>'yes', prompt=>'Does this flash have a left/right swivel head?', type=>'boolean'});
	$data{tilt_head} = $href->{tilt_head} // &prompt({default=>'yes', prompt=>'Does this flash have an up/down tilt head?', type=>'boolean'});
	$data{zoom} = $href->{zoom} // &prompt({default=>'yes', prompt=>'Does this flash have a zoom head?', type=>'boolean'});
	$data{dslr_safe} = $href->{dslr_safe} // &prompt({default=>'yes', prompt=>'Is this flash safe to use on a DSLR?', type=>'boolean'});
	$data{ttl} = $href->{ttl} // &prompt({default=>'yes', prompt=>'Does this flash support TTL metering?', type=>'boolean'});
	if ($data{ttl} == 1) {
		$data{flash_protocol_id} = $href->{flash_protocol_id} // &listchoices({db=>$db, table=>'choose_flash_protocol'});
	}
	$data{trigger_voltage} = $href->{trigger_voltage} // &prompt({prompt=>'What is the measured trigger voltage?', type=>'decimal'});
	$data{own} = 1;
	$data{acquired} = $href->{acquired} // &prompt({default=>&today, prompt=>'When was it acquired?', type=>'date'});
	$data{cost} = $href->{cost} // &prompt({prompt=>'What did this flash cost?', type=>'decimal'});
	return &newrecord({db=>$db, data=>\%data, table=>'FLASH'});
}

# Add a new type of battery to the database
sub battery_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{battery_name} = $href->{battery_name} // &prompt({prompt=>'What is the name of this battery?'});
	$data{voltage} = $href->{voltage} // &prompt({prompt=>'What is the nominal voltage of this battery?', type=>'decimal'});
	$data{chemistry} = $href->{chemistry} // &prompt({prompt=>'What type of chemistry is this battery based on?'});
	$data{other_names} = $href->{other_names} // &prompt({prompt=>'Does this type of battery go by any other names?'});
	return &newrecord({db=>$db, data=>\%data, table=>'BATTERY'});
}

# Add a new film format to the database
sub format_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{format} = $href->{format} // &prompt({prompt=>'What is the name of this film format?'});
	$data{digital} = $href->{digital} // &prompt({default=>'no', prompt=>'Is this a digital format?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'FORMAT'});
}

# Add a size of negative to the database
sub negativesize_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{negative_size} = $href->{negative_size} // &prompt({prompt=>'What is the name of this negative size?'});
	$data{width} = $href->{width} // &prompt({prompt=>'What is the width of this negative size in mm?', type=>'decimal'});
	$data{height} = $href->{height} // &prompt({prompt=>'What is the height of this negative size in mm?', type=>'decimal'});
	if ($data{width} > 0 && $data{height} > 0) {
		$data{crop_factor} = round(sqrt($data{width}*$data{width} + $data{height}*$data{height}) / sqrt(36*36 + 24*24), 2);
		$data{area} = $data{width} * $data{height};
		$data{aspect_ratio} = round($data{width} / $data{height}, 2);
	}
	return &newrecord({db=>$db, data=>\%data, table=>'NEGATIVE_SIZE'});
}

# Add a new mount adapter to the database
sub mount_adapt {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{lens_mount} = $href->{lens_mount} // &listchoices({db=>$db, keyword=>'lens-facing mount', cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{camera_mount} = $href->{camera_mount} // &listchoices({db=>$db, keyword=>'camera-facing mount', cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Camera'}, inserthandler=>\&mount_add});
	$data{has_optics} = $href->{has_optics} // &prompt({prompt=>'Does this mount adapter have corrective optics?', type=>'boolean'});
	$data{infinity_focus} = $href->{infinity_focus} // &prompt({prompt=>'Does this mount adapter have infinity focus?', type=>'boolean'});
	$data{notes} = $href->{notes} // &prompt({prompt=>'Notes'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOUNT_ADAPTER'});
}

# Add a new light meter to the database
sub lightmeter_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{model} = $href->{model} // &prompt({prompt=>'What is the model of this light meter?'});
	$data{metering_type} = $href->{metering_type} // &listchoices({db=>$db, cols=>['metering_type_id as id', 'metering as opt'], table=>'METERING_TYPE', inserthandler=>\&meteringtype_add});
	$data{reflected} = $href->{reflected} // &prompt({prompt=>'Can this meter take reflected light readings?', type=>'boolean'});
	$data{incident} = $href->{incident} // &prompt({prompt=>'Can this meter take incident light readings?', type=>'boolean'});
	$data{spot} = $href->{spot} // &prompt({prompt=>'Can this meter take spot readings?', type=>'boolean'});
	$data{flash} = $href->{flash} // &prompt({prompt=>'Can this meter take flash readings?', type=>'boolean'});
	$data{min_asa} = $href->{min_asa} // &prompt({prompt=>'What\'s the lowest ISO/ASA setting this meter supports?', type=>'integer'});
	$data{max_asa} = $href->{max_asa} // &prompt({prompt=>'What\'s the highest ISO/ASA setting this meter supports?', type=>'integer'});
	$data{min_lv} = $href->{min_lv} // &prompt({prompt=>'What\'s the lowest light value (LV) reading this meter can give?', type=>'integer'});
	$data{max_lv} = $href->{max_lv} // &prompt({prompt=>'What\'s the highest light value (LV) reading this meter can give?', type=>'integer'});
	return &newrecord({db=>$db, data=>\%data, table=>'LIGHT_METER'});
}

# Add a new camera body type
sub camera_addbodytype {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{body_type} = $href->{body_type} // &prompt({prompt=>'Enter new camera body type'});
	return &newrecord({db=>$db, data=>\%data, table=>'BODY_TYPE'});
}

# Add a new series of camera/lens models
sub series_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{name} = $href->{name} // &prompt({prompt=>'What is the name of this series?'});
	return &newrecord({db=>$db, data=>\%data, table=>'SERIES'});
}

# Print info about a series
sub series_info {
	my $href = shift;
	my $db = $href->{db};
	my $series_id = $href->{series_id} // &listchoices({db=>$db, cols=>['series_id as id', 'name as opt'], table=>'SERIES', required=>1});
	my $seriesname = &lookupval({db=>$db, col=>'name', table=>'SERIES', where=>{series_id=>$series_id}});
	my $total = &printlist({db=>$db, msg=>"camera and lens models in series '$seriesname'", table=>'info_series', cols=>["Got as id", 'Model as opt'], where=>{'`Series ID`'=>$series_id}});
	my $got = &lookupval({db=>$db, col=>'count(*)', table=>'info_series', where=>{'`Series ID`'=>$series_id, Got=>'✓'}});

	if ($total > 0) {
		my $need = $total - $got;
		my $percentcomplete = round(100 * $got/$total);
		print "Series '$seriesname' is $percentcomplete% complete (got $got, need $need)\n";
	}
	return;
}

# Summarise all series
sub series_list {
	my $href = shift;
	my $db = $href->{db};
	my $rows = &tabulate({db=>$db, view=>'summary_series'});
	return $rows;
}

# List all models we need
sub series_need {
	my $href = shift;
	my $db = $href->{db};
	my $rows = &printlist({db=>$db, msg=>'models needed to complete series', cols=>["'' as id", 'Model as opt'], table=>'info_series', where=>{'Got'=>'✗'}});
	return $rows;
}

# Add a new physical archive for prints or films
sub archive_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{archive_type_id} = $href->{archive_type_id} // &listchoices({db=>$db, cols=>['archive_type_id as id', 'archive_type as opt'], table=>'ARCHIVE_TYPE'});
	$data{name} = $href->{name} // &prompt({prompt=>'What is the name of this archive?'});
	$data{max_width} = $href->{max_width} // &prompt({prompt=>'What is the maximum width of media that this archive can accept (if applicable)?'});
	$data{max_height} = $href->{max_height} // &prompt({prompt=>'What is the maximum height of media that this archive can accept (if applicable)?'});
	$data{location} = $href->{location} // &prompt({prompt=>'What is the location of this archive?'});
	$data{storage} = $href->{storage} // &prompt({prompt=>'What is the storage type of this archive? (e.g. box, folder, ringbinder, etc)'});
	$data{sealed} = $href->{sealed} // &prompt({default=>'no', prompt=>'Is this archive sealed (closed to new additions)?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'ARCHIVE'});
}

# Bulk-add multiple films to an archive
sub archive_films {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $minfilm = $href->{minfilm} // &prompt({prompt=>'What is the lowest film ID in the range?', type=>'integer'});
	my $maxfilm = $href->{maxfilm} // &prompt({prompt=>'What is the highest film ID in the range?', type=>'integer'});
	if (($minfilm =~ m/^\d+$/) && ($maxfilm =~ m/^\d+$/)) {
		if ($maxfilm le $minfilm) {
			print "Highest film ID must be higher than lowest film ID\n";
			return;
		}
	} else {
		print "Must provide highest and lowest film IDs\n";
		return;
	}
	$data{archive_id} = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>'archive_type_id in (1,2) and sealed = 0', inserthandler=>\&archive_add});
	return &updaterecord({db=>$db, data=>\%data, table=>'FILM', where=>"film_id >= $minfilm and film_id <= $maxfilm and archive_id is null"});
}

# Display info about an archive
sub archive_info {
	my $href = shift;
	my $db = $href->{db};
	my $archive_id = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	print Dump(&lookupcol({db=>$db, table=>'info_archive', where=>{'`Archive ID`'=>$archive_id}}));
	return;
}

# List the contents of an archive
sub archive_list {
	my $href = shift;
	my $db = $href->{db};
	my $archive_id = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	my $archive_name = &lookupval({db=>$db, col=>'name', table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
	&printlist({db=>$db, msg=>"items in archive $archive_name", table=>'archive_contents', where=>{archive_id=>$archive_id}});
	return;
}

# Seal an archive and prevent new items from being added to it
sub archive_seal {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $archive_id = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{sealed=>0}, required=>1});
	$data{sealed} = 1;
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
}

# Unseal an archive and allow new items to be added to it
sub archive_unseal {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $archive_id = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', where=>{sealed=>1}, required=>1});
	$data{sealed} = 0;
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
}

# Move an archive to a new location
sub archive_move {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	my $archive_id = $href->{archive_id} // &listchoices({db=>$db, cols=>['archive_id as id', 'name as opt'], table=>'ARCHIVE', required=>1});
	my $oldlocation = &lookupval({db=>$db, col=>'location', table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
	$data{location} = $href->{location} // &prompt({default=>$oldlocation, prompt=>'What is the new location of this archive?'});
	return &updaterecord({db=>$db, data=>\%data, table=>'ARCHIVE', where=>{archive_id=>$archive_id}});
}

# Add a new type of shutter to the database
sub shuttertype_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{shutter_type} = $href->{shutter_type} // &prompt({prompt=>'What type of shutter do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'SHUTTER_TYPE'});
}

# Add a new type of focus system to the database
sub focustype_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{focus_type} = $href->{focus_type} // &prompt({prompt=>'What type of focus system do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'FOCUS_TYPE'});
}

# Add a new flash protocol to the database
sub flashprotocol_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{name} = $href->{name} // &prompt({prompt=>'What flash protocol do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'FLASH_PROTOCOL'});
}

# Add a new type of metering system to the database
sub meteringtype_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{metering} = $href->{metering} // &prompt({prompt=>'What type of metering system do you want to add?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'METERING_TYPE'});
}

# Add a new shutter speed to the database
sub shutterspeed_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{shutter_speed} = $href->{shutter_speed} // &prompt({prompt=>'What shutter speed do you want to add?', required=>1});
	$data{duration} = &duration($data{shutter_speed});
	return &newrecord({db=>$db, data=>\%data, table=>'SHUTTER_SPEED'});
}

# Add a new person to the database
sub person_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{name} = $href->{name} // &prompt({prompt=>'What is this person\'s name?', required=>1});
	return &newrecord({db=>$db, data=>\%data, table=>'PERSON'});
}

# Add a new projector to the database
sub projector_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{manufacturer_id} = $href->{manufacturer_id} // &choose_manufacturer({db=>$db});
	$data{model} = $href->{model} // &prompt({prompt=>'What is the model of this projector?'});
	$data{mount_id} = $href->{mount_id} // &listchoices({db=>$db, cols=>['mount_id as id', 'mount as opt'], table=>'choose_mount', where=>{'purpose'=>'Projector'}, inserthandler=>\&mount_add});
	$data{negative_size_id} = $href->{negative_size_id} // &listchoices({db=>$db, cols=>['negative_size_id as id', 'negative_size as opt'], table=>'NEGATIVE_SIZE', inserthandler=>\&negativesize_add});
	$data{own} = 1;
	$data{cine} = $href->{cine} // &prompt({prompt=>'Is this a cine/movie projector?', type=>'boolean'});
	return &newrecord({db=>$db, data=>\%data, table=>'PROJECTOR'});
}

# Add a new movie to the database
sub movie_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{title} = $href->{title} // &prompt({prompt=>'What is the title of this movie?'});
	$data{camera_id} = $href->{camera_id} // &listchoices({db=>$db, table=>'choose_movie_camera'});
	if (&lookupval({db=>$db, col=>'fixed_mount', table=>'CAMERA', where=>{camera_id=>$data{camera_id}}})) {
		$data{lens_id} = &lookupval({db=>$db, col=>'lens_id', table=>'CAMERA', where=>{camera_id=>$data{camera_id}}});
	} else {
		$data{lens_id} = $href->{lens_id} // &listchoices({db=>$db, table=>'choose_lens'});
	}
	$data{format_id} = $href->{format_id} // &listchoices({db=>$db, cols=>['format_id as id', 'format as opt'], table=>'FORMAT', inserthandler=>\&format_add});
	$data{sound} = $href->{sound} // &prompt({prompt=>'Does this movie have sound?', type=>'boolean'});
	$data{fps} = $href->{fps} // &prompt({prompt=>'What is the framerate of this movie in fps?', type=>'integer'});
	$data{filmstock_id} = $href->{filmstock_id} // &listchoices({db=>$db, table=>'choose_filmstock', inserthandler=>\&filmstock_add});
	$data{feet} = $href->{feet} // &prompt({prompt=>'What is the length of this movie in feet?', type=>'integer'});
	$data{date_loaded} = $href->{date_loaded} // &prompt({default=>&today, prompt=>'What date was the film loaded?', type=>'date'});
	$data{date_shot} = $href->{date_shot} // &prompt({default=>&today, prompt=>'What date was the movie shot?', type=>'date'});
	$data{date_processed} = $href->{date_processed} // &prompt({default=>&today, prompt=>'What date was the movie processed?', type=>'date'});
	$data{process_id} = $href->{process_id} // &listchoices({db=>$db, keyword=>'process', cols=>['process_id as id', 'name as opt'], table=>'PROCESS', inserthandler=>\&process_add});
	$data{description} = $href->{description} // &prompt({prompt=>'Please enter a description of the movie'});
	return &newrecord({db=>$db, data=>\%data, table=>'MOVIE'});
}

# Show info about a movie
sub movie_info {
	my $href = shift;
	my $db = $href->{db};
	my $movie_id = $href->{movie_id} // &listchoices({db=>$db, cols=>['movie_id as id', 'title as opt'], table=>'MOVIE', required=>1});
	print Dump(&lookupcol({db=>$db, table=>'info_movie', where=>{'`Movie ID`'=>$movie_id}}));
	return;
}

# Audit cameras without shutter speed data
sub audit_shutterspeeds {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, keyword=>'camera model without shutter speed data', table=>'choose_cameramodel_without_shutter_data', required=>1});
	&cameramodel_shutterspeeds({db=>$db, cameramodel_id=>$cameramodel_id});
	return;
}

# Audit cameras without exposure program data
sub audit_exposureprograms {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, keyword=>'camera model without exposure program data', table=>'choose_cameramodel_without_exposure_programs', required=>1});
	&cameramodel_exposureprogram({db=>$db, cameramodel_id=>$cameramodel_id});
	return;
}

# Audit cameras without metering mode data
sub audit_meteringmodes {
	my $href = shift;
	my $db = $href->{db};
	my $cameramodel_id = $href->{cameramodel_id} // &listchoices({db=>$db, keyword=>'camera without metering mode data', table=>'choose_cameramodel_without_metering_data', required=>1});
	&cameramodel_meteringmode({db=>$db, cameramodel_id=>$cameramodel_id});
	return;
}

# Add a new exhibition to the database
sub exhibition_add {
	my $href = shift;
	my $db = $href->{db};
	my %data;
	$data{title} = $href->{title} // &prompt({prompt=>'What is the title of this exhibition?', required=>1});
	$data{location} = $href->{location} // &prompt({prompt=>'Where is this exhibition?'});
	$data{start_date} = $href->{start_date} // &prompt({prompt=>'What date does the exhibition start?', type=>'date'});
	$data{end_date} = $href->{end_date} // &prompt({prompt=>'What date does the exhibition end?', type=>'date'});
	return &newrecord({db=>$db, data=>\%data, table=>'EXHIBITION'});
}

# Review which prints were exhibited at an exhibition
sub exhibition_info {
	my $href = shift;
	my $db = $href->{db};
	my $exhibition_id = &listchoices({db=>$db, cols=>['exhibition_id as id', 'title as opt'], table=>'EXHIBITION', required=>1});
	my $title = &lookupval({db=>$db, col=>'title', table=>'EXHIBITION', where=>{exhibition_id=>$exhibition_id}});

	&printlist({db=>$db, msg=>"prints exhibited at $title", table=>'exhibits', where=>{exhibition_id=>$exhibition_id}});
	return;
}

# Run a selection of maintenance tasks on the database
sub run_task {
	my $href = shift;
	my $db = $href->{db};

	my @choices = (
		{ desc => 'Set right lens_id for all negatives taken with fixed-lens cameras',                    proc => 'update_lens_id_fixed_camera' },
		{ desc => 'Update lens focal length per negative',                                                proc => 'update_focal_length' },
		{ desc => 'Update dates of fixed lenses',                                                         proc => 'update_dates_of_fixed_lenses' },
		{ desc => 'Set metering mode for negatives taken with cameras with only one metering mode',       proc => 'update_metering_modes' },
		{ desc => 'Set exposure program for negatives taken with cameras with only one exposure program', proc => 'update_exposure_programs' },
		{ desc => 'Set fixed lenses as lost when their camera is lost',                                   proc => 'set_fixed_lenses' },
		{ desc => 'Set crop factor, area, and aspect ratio for negative sizes that lack it',              proc => 'update_negative_sizes' },
		{ desc => 'Set no flash for negatives taken with cameras that don\'t support flash',              proc => 'update_negative_flash' },
		{ desc => 'Delete log entries older than 90 days',                                                proc => 'delete_logs' },
		{ desc => 'Update copied negatives with inherited data',                                          proc => 'update_copied_negs'},
	);

	my $action = &multiplechoice({choices => \@choices});

	if (defined($action) && $choices[$action]->{proc}) {
		my $rows = &call({db=>$db, procedure=>$choices[$action]->{proc}});
		$rows = &unsci($rows);
		print "Updated $rows rows\n";
		return $rows;
	}
	return;
}

# Run a selection of reports on the database
sub run_report {
	my $href = shift;
	my $db = $href->{db};

	my @choices = (
		{ desc => 'How many cameras in the collection are from each decade', view => 'report_cameras_by_decade', },
		{ desc => 'Lenses have been used to take most frames',               view => 'report_most_popular_lenses_relative', },
		{ desc => 'Cameras that have never been to used to take a frame',    view => 'report_never_used_cameras', },
		{ desc => 'Lenses that have never been used to take a frame',        view => 'report_never_used_lenses', },
		{ desc => 'Cameras that have taken most frames',                     view => 'report_total_negatives_per_camera', },
		{ desc => 'Lenses that have taken most frames',                      view => 'report_total_negatives_per_lens', },
		{ desc => 'Negatives that have not been scanned',                    view => 'report_unscanned_negs', },
		{ desc => 'Potential duplicate camera models',                       view => 'report_duplicate_cameramodels', },
		{ desc => 'Potential duplicate lens models',                         view => 'report_duplicate_lensmodels', },
		{ desc => 'Duplicate cameras',                                       view => 'report_duplicate_cameras', },
		{ desc => 'Duplicate lenses',                                        view => 'report_duplicate_lenses', },
	);

	my $action = &multiplechoice({choices => \@choices});

	if (defined($action) && $choices[$action]->{view}) {
		&tabulate({db=>$db, view=>$choices[$action]->{view}});
	}
	return;
}

# Run database migrations to upgrade the schema
sub run_migrations {
	my $href = shift;
	my $db = $href->{db};
	&runmigrations($db);
	return;
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
	my $href = shift;
	my $db = $href->{db};
	my $camera_id = $href->{camera_id} // &listchoices({db=>$db, keyword=>'camera', table=>'camera_chooser', where=>{mount_id=>{'!=', undef}, display_lens=>{'=', undef}}, required=>1 });
	&camera_displaylens({db=>$db, camera_id=>$camera_id});
	return;
}

# Show statistics about the database
sub db_stats {
	my $href = shift;
	my $db = $href->{db};
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
	my $href = shift;
	my $db = $href->{db};
	print Dump(&lookuplist({db=>$db, col=>"concat(datetime, ' ', type, ' ', message) as log", table=>'LOG'}));
	return;
}

# Print basic database info
sub db_test {
	my $href = shift;
	my $db = $href->{db};
	my $hostname = $db->{'mysql_hostinfo'};
	my $version = $db->{'mysql_serverinfo'};
	my $stats = $db->{'mysql_stat'};
	$stats =~ s/  /\n\t/g;
	print "\tConnected to $hostname\n\tRunning version $version\n\t$stats\n";
	return;
}

# Add a new scan of a negative or print
sub scan_add {
	my $href = shift;
	my $db = $href->{db};

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
	my $href = shift;
	my $db = $href->{db};

	# Prompt user for filename of scan
	my $scan_id = $href->{scan_id} // &choosescan({db=>$db});

	# Work out negative_id or print_id
	my $scan_data = &lookupcol({db=>$db, cols=>['negative_id', 'print_id'], table=>'SCAN', where=>{scan_id=>$scan_id}});
	$scan_data = &thin($$scan_data[0]);

	# Insert new scan from same source
	return &scan_add({db=>$db, scan_data=>$scan_data});
}

# Delete a scan from the database and optionally from the filesystem
sub scan_delete {
	my $href = shift;
	my $db = $href->{db};

	# Prompt user for filename of scan
	my $scan_id = $href->{scan_id} // &choosescan({db=>$db});

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
	my $href = shift;
	my $db = $href->{db};

	# Search filesystem basepath & DB to enumerate all *.jpg scans
	my @fsfiles = &fsfiles;
	my @dbfiles = &dbfiles({db=>$db});

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

						# Test for non-null subdir
						if ($subdir =~ m/.+/) {
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
						&scan_add({db=>$db, filename=>$filename});
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
	@dbfiles = &dbfiles({db=>$db});

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

# Rename scans to include their caption in the filename
sub scan_rename {
	# Read in cmdline args
	my $href = shift;
	my $db = $href->{db};
	my $film_id = $href->{film_id} // &film_choose({db=>$db});

	# Make sure basepath is valid
	my $basepath = &basepath;

	# Find matching scans
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select('scans_negs', '*', {film_id=>$film_id});
	my $sth = $db->prepare($stmt) or die "Couldn't prepare statement: " . $db->errstr;
	my $rows = $sth->execute(@bind);
	$rows = &unsci($rows);
	return if ($rows == 0);

	# Loop through our result set
	while (my $ref = $sth->fetchrow_hashref()) {
		# First check the path is defined in MySQL
		if (defined($ref->{'filename'})) {
			# Now make sure the path actually exists on the system
			if (-e "$basepath/$ref->{'directory'}/$ref->{'filename'}") {

				# Sanitise description with fs-safe chars
				my $safedesc = $ref->{'description'};
				$safedesc =~ s/[^a-zA-Z0-9-_ ]//g;

				# Generate theoretical new filename
				my $newname;
				if ($ref->{'print_id'}) {
					# For prints
					$newname = "P$ref->{print_id}-$safedesc.jpg";
				} else {
					# For negatives
					$newname = "$ref->{film_id}-$ref->{frame}-$safedesc.jpg";
				}

				# Check if a change is needed
				if ($ref->{'filename'} ne $newname) {
					print "\t$ref->{'filename'} => $newname\n";

					# Move file on fs
					rename(&untaint("$basepath/$ref->{'directory'}/$ref->{'filename'}"), &untaint("$basepath/$ref->{'directory'}/$newname"));

					# Update scan in db
					&updaterecord({db=>$db, data=>{filename=>$newname}, table=>'SCAN', where=>{scan_id=>$ref->{scan_id}}, silent=>1});
				}
			}
		}
	}
	return $rows;
}

# This ensures the lib loads smoothly
1;
