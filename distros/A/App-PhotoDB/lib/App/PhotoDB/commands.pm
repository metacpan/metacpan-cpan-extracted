package App::PhotoDB::commands;

# This package contains the authoritative list of commands and subcommands
# It is used by the app and also to generate docs
# Please keep this list alphabetised!

use strict;
use warnings;
use App::PhotoDB::handlers qw(/./);

=head1 USAGE

This section of the documentation focuses on using PhotoDB
after it has been installed. Every command requires a command and subcommand, e.g.

    camera add

After providing a command and subcommand, PhotoDB then asks relevant questions interactively with helpful guidance.

=cut

# Define handlers for each command
our %handlers;

=head2 accessory

The C<accessory> command provides subcommands for adding photographic accessories to the database.

=head3 accessory add

Add a new general accessory to the database

=head3 accessory battery

Add a new type of battery to the database

=head3 accessory filter

Add a new (optical) filter to the database

=head3 accessory filteradapter

Add a filter adapter to the database

=head3 accessory flash

Add a new flash to the database

=head3 accessory info

Display info about an accessory

=head3 accessory meter

Add a new light meter to the database

=head3 accessory mountadapter

Add a new mount adapter to the database

=head3 accessory projector

Add a new projector to the database

=head3 accessory search

Search for an accessory

=head3 accessory teleconverter

Add a new teleconverter to the database

=head3 accessory category

Add a new category of general accessory to the database

=cut
	$handlers{accessory} = {
		'add'           => { 'handler' => \&accessory_add,      'desc' => 'Add a new general accessory to the database' },
		'battery'       => { 'handler' => \&battery_add,        'desc' => 'Add a new type of battery to the database' },
		'filter'        => { 'handler' => \&filter_add,         'desc' => 'Add a new (optical) filter to the database' },
		'filteradapter' => { 'handler' => \&filter_adapt,       'desc' => 'Add a filter adapter to the database' },
		'flash'         => { 'handler' => \&flash_add,          'desc' => 'Add a new flash to the database' },
		'info'          => { 'handler' => \&accessory_info,     'desc' => 'Display info about an accessory' },
		'meter'         => { 'handler' => \&lightmeter_add,     'desc' => 'Add a new light meter to the database' },
		'mountadapter'  => { 'handler' => \&mount_adapt,        'desc' => 'Add a new mount adapter to the database' },
		'projector'     => { 'handler' => \&projector_add,      'desc' => 'Add a new projector to the database' },
		'teleconverter' => { 'handler' => \&teleconverter_add,  'desc' => 'Add a new teleconverter to the database' },
		'category'      => { 'handler' => \&accessory_category, 'desc' => 'Add a new category of general accessory to the database' },
		'search'        => { 'handler' => \&accessory_search,   'desc' => 'Search for an accessory' },
	};

=head2 series

=head3 series add

Add a new series of camera or lens models

=head3 series info

View information about a series of camera or lens models

=head3 series list

Summarise series of camera or lens models

=head3 series need

View list of models needed to complete series

=cut

	$handlers{series} = {
		'add'  => { 'handler' => \&series_add,  'desc' => 'Add a new series of camera or lens models' },
		'info' => { 'handler' => \&series_info, 'desc' => 'View information about a series of camera or lens models' },
		'list' => { 'handler' => \&series_list, 'desc' => 'Summarise series of camera or lens models' },
		'need' => { 'handler' => \&series_need, 'desc' => 'View list of models needed to complete series' },
	};

=head2 archive

=head3 archive add

Add a new physical archive for prints or films

=head3 archive films

Bulk-add multiple films to an archive

=head3 archive info

Show information about an archive

=head3 archive list

List the contents of an archive

=head3 archive move

Move an archive to a new location

=head3 archive seal

Seal an archive and prevent new items from being added to it

=head3 archive unseal

Unseal an archive and allow new items to be added to it

=cut
	$handlers{archive} = {
		'add'    => { 'handler' => \&archive_add,    'desc' => 'Add a new physical archive for prints or films' },
		'films'  => { 'handler' => \&archive_films,  'desc' => 'Bulk-add multiple films to an archive' },
		'info'   => { 'handler' => \&archive_info,   'desc' => 'Show information about an archive'},
		'list'   => { 'handler' => \&archive_list,   'desc' => 'List the contents of an archive' },
		'move'   => { 'handler' => \&archive_move,   'desc' => 'Move an archive to a new location' },
		'seal'   => { 'handler' => \&archive_seal,   'desc' => 'Seal an archive and prevent new items from being added to it' },
		'unseal' => { 'handler' => \&archive_unseal, 'desc' => 'Unseal an archive and allow new items to be added to it' },
	};

=head2 audit

The C<audit> command provides a set of subcommands for checking and entering incomplete data.

=head3 audit displaylenses

Audit cameras without a display lens set

=head3 audit exposureprograms

Audit cameras without exposure program data

=head3 audit meteringmodes

Audit cameras without metering mode data

=head3 audit shutterspeeds

Audit cameras without shutter speed data

=cut
	$handlers{audit} = {
		'displaylenses'    => { 'handler' => \&audit_displaylenses,    'desc' => 'Audit cameras without display lenses set' },
		'exposureprograms' => { 'handler' => \&audit_exposureprograms, 'desc' => 'Audit cameras without exposure program data' },
		'meteringmodes'    => { 'handler' => \&audit_meteringmodes,    'desc' => 'Audit cameras without metering mode data' },
		'shutterspeeds'    => { 'handler' => \&audit_shutterspeeds,    'desc' => 'Audit cameras without shutter speed data' },
	};

=head2 camera

The C<camera> command provides subcommands for working with cameras.

=head3 camera add

Add a new camera to the database

=head3 camera choose

Choose a camera based on multiple usage criteria

=head3 camera display-lens

Associate a camera with a lens for display purposes

=head3 camera edit

Edit an existing camera

=head3 camera info

Show information about a camera

=head3 camera repair

Repair a camera

=head3 camera search

Search for a camera

=head3 camera sell

Sell a camera

=head3 camera show-lenses

C<camera show-lenses> shows all lenses which are compatible with a camera.

=cut
	$handlers{camera} = {
		'add'          => { 'handler' => \&camera_add,         'desc' => 'Add a new camera to the database' },
		'choose'       => { 'handler' => \&camera_choose,      'desc' => 'Choose a camera based on several criteria' },
		'display-lens' => { 'handler' => \&camera_displaylens, 'desc' => 'Associate a camera with a lens for display purposes' },
		'edit'         => { 'handler' => \&camera_edit,        'desc' => 'Edit an existing camera' },
		'info'         => { 'handler' => \&camera_info,        'desc' => 'Show information about a camera' },
		'repair'       => { 'handler' => \&camera_repair,      'desc' => 'Repair a camera' },
		'search'       => { 'handler' => \&camera_search,      'desc' => 'Search for a camera' },
		'sell'         => { 'handler' => \&camera_sell,        'desc' => 'Sell a camera' },
		'show-lenses'  => { 'handler' => \&notimplemented,     'desc' => 'Not yet implemented' },
	};

=head2 cameramodel

The C<cameramodel> command provides a set of subcommands for working with camera models.

=head3 cameramodel add

Add a new camera model to PhotoDB

=head3 cameramodel accessory

Add accessory compatibility info to a camera model

=head3 cameramodel exposureprogram

Add available exposure program info to a camera model

=head3 cameramodel info

View information about a camera model

=head3 cameramodel meteringmode

Add available metering mode info to a camera model

=head3 cameramodel series

Add a camera model to a series

=head3 cameramodel shutterspeeds

Add available shutter speed info to a camera model

=cut

	$handlers{cameramodel} = {
		'accessory'       => { 'handler' => \&cameramodel_accessory,       'desc' => 'Add accessory compatibility info to a camera model' },
		'add'             => { 'handler' => \&cameramodel_add,             'desc' => 'Add a new camera model to PhotoDB' },
		'exposureprogram' => { 'handler' => \&cameramodel_exposureprogram, 'desc' => 'Add available exposure program info to a camera model' },
		'info'            => { 'handler' => \&cameramodel_info,            'desc' => 'View information about a camera model' },
		'meteringmode'    => { 'handler' => \&cameramodel_meteringmode,    'desc' => 'Add available metering mode info to a camera model' },
		'series'          => { 'handler' => \&cameramodel_series,          'desc' => 'Add a camera model to a series' },
		'shutterspeeds'   => { 'handler' => \&cameramodel_shutterspeeds,   'desc' => 'Add available shutter speed info to a camera model' },
	};

=head2 data

The C<data> command provides a set of subcommands for entering sundry data. You shouldn't really need these as data can be entered inline at the point of use.

=head3 data bodytype

Add a new camera body type

=head3 data flashprotocol

Add a new flash protocol to the database

=head3 data focustype

Add a new type of focus system to the database

=head3 data format

Add a new film format to the database

=head3 data manufacturer

Add a new manufacturer to the database

=head3 data meteringtype

Add a new type of metering system to the database

=head3 data negsize

Add a size of negative to the database

=head3 data process

Add a new development process to the database

=head3 data shutterspeed

Add a new shutter speed to the database

=head3 data shuttertype

Add a new type of shutter to the database

=cut
	$handlers{data} = {
		'bodytype'      => { 'handler' => \&camera_addbodytype, 'desc' => 'Add a new camera body type' },
		'flashprotocol' => { 'handler' => \&flashprotocol_add,  'desc' => 'Add a new flash protocol to the database' },
		'focustype'     => { 'handler' => \&focustype_add,      'desc' => 'Add a new type of focus system to the database' },
		'format'        => { 'handler' => \&format_add,         'desc' => 'Add a new film format to the database' },
		'manufacturer'  => { 'handler' => \&manufacturer_add,   'desc' => 'Add a new manufacturer to the database' },
		'meteringtype'  => { 'handler' => \&meteringtype_add,   'desc' => 'Add a new type of metering system to the database' },
		'negsize'       => { 'handler' => \&negativesize_add,   'desc' => 'Add a size of negative to the database' },
		'process'       => { 'handler' => \&process_add,        'desc' => 'Add a new development process to the database' },
		'shutterspeed'  => { 'handler' => \&shutterspeed_add,   'desc' => 'Add a new shutter speed to the database' },
		'shuttertype'   => { 'handler' => \&shuttertype_add,    'desc' => 'Add a new type of shutter to the database' },
	};

=head2 db

The C<db> command provides a set of subcommands for managing the database backend.

=head3 db backup

Back up the contents of the database

=head3 db logs

Show activity logs from the database

=head3 db stats

Show statistics about database usage

=head3 db test

Test database connectivity

=head3 db upgrade

Upgrade database to the latest schema

=cut
	$handlers{db} = {
		'backup' => { 'handler' => \&notimplemented, 'desc' => 'Back up the contents of the database' },
		'logs'   => { 'handler' => \&db_logs,        'desc' => 'Show activity logs from the database' },
		'stats'  => { 'handler' => \&db_stats,       'desc' => 'Show statistics about database usage' },
		'test'   => { 'handler' => \&db_test,        'desc' => 'Test database connectivity' },
	};


=head2 enlarger

=head3 enlarger add

Add a new enlarger to the database

=head3 enlarger info

Show information about an enlarger

=head3 enlarger sell

Sell an enlarger

=cut
	$handlers{enlarger} = {
		'add'  => { 'handler' => \&enlarger_add,  'desc' => 'Add a new enlarger to the database' },
		'info' => { 'handler' => \&enlarger_info, 'desc' => 'Show information about an enlarger' },
		'sell' => { 'handler' => \&enlarger_sell, 'desc' => 'Sell an enlarger' },
	};

=head2 exhibition

The C<exhibition> command provides a set of subcommands for managing exhibitions.

=head3 exhibition add

Add a new exhibition to the database

=head3 exhibition info

Show information about an exhibition

=cut
	$handlers{exhibition} = {
		'add'  => { 'handler' => \&exhibition_add,  'desc' => 'Add a new exhibition to the database' },
		'info' => { 'handler' => \&exhibition_info, 'desc' => 'Show information about an exhibition' },
	};

=head2 film

The C<film> command provides subcommands for working with individual rolls (or sets of sheets) of film.

=head3 film add

Adds a new film to the database, e.g. when it is purchased.

=head3 film annotate

Create a text file in the film scan directory with summary info about the film & negatives

=head3 film archive

Put the film in a physical archive

=head3 film bulk

Add a new bulk film to the database

=head3 film current

List films that are currently loaded into cameras

=head3 film develop

Develop a film

=head3 film info

Show information about a film

=head3 film load

Load a film into a camera

=head3 film locate

Locate where this film is

=head3 film search

Search for a film

=head3 film stocks

List the films that are currently in stock

=head3 film tag

Write EXIF tags to scans from a film

=cut
	$handlers{film}	= {
		'add'      => { 'handler' => \&film_add,      'desc' => 'Add a new film to the database' },
		'annotate' => { 'handler' => \&film_annotate, 'desc' => 'Write out a text file with the scans from the film' },
		'archive'  => { 'handler' => \&film_archive,  'desc' => 'Put a film in a physical archive' },
		'bulk'     => { 'handler' => \&film_bulk,     'desc' => 'Add a new bulk film to the database' },
		'current'  => { 'handler' => \&film_current,  'desc' => 'List films that are currently loaded into cameras' },
		'develop'  => { 'handler' => \&film_develop,  'desc' => 'Develop a film' },
		'info'     => { 'handler' => \&film_info,     'desc' => 'Show information about a film' },
		'load'     => { 'handler' => \&film_load,     'desc' => 'Load a film into a camera' },
		'locate'   => { 'handler' => \&film_locate,   'desc' => 'Locate where this film is' },
		'search'   => { 'handler' => \&film_search,   'desc' => 'Search for a film' },
		'stocks'   => { 'handler' => \&film_stocks,   'desc' => 'List the films that are currently in stock' },
		'tag'      => { 'handler' => \&film_tag,      'desc' => 'Write EXIF tags to scans from a film' },
	};

=head2 lensmodel

The C<lensmodel> command provides a set of subcommands for working with lens models.

=head3 lensmodel add

Add a new lens model to PhotoDB

=head3 lensmodel accessory

Add accessory compatibility info to a lens model

=head3 lensmodel info

View information about a lens model

=head3 lensmodel series

Add a lens model to a series

=cut

        $handlers{lensmodel} = {
                'accessory' => { 'handler' => \&lensmodel_accessory, 'desc' => 'Add accessory compatibility info to a lens model' },
                'add'       => { 'handler' => \&lensmodel_add,       'desc' => 'Add a new lens model to PhotoDB' },
                'info'      => { 'handler' => \&lensmodel_info,      'desc' => 'View information about a lens model' },
                'series'    => { 'handler' => \&lensmodel_series,    'desc' => 'Add a lens model to a series' },
        };

=head2 lens

The C<lens> command provides subcommands for working with lenses (for cameras, enlargers and projectors).

=head3 lens add

Add a new lens to the database

=head3 lens info

Show information about a lens

=head3 lens repair

Repair a lens

=head3 lens search

Search for a lens

=head3 lens sell

Sell a lens

=cut
	$handlers{lens} = {
		'add'       => { 'handler' => \&lens_add,       'desc' => 'Add a new lens to the database' },
		'info'      => { 'handler' => \&lens_info,      'desc' => 'Show information about a lens' },
		'repair'    => { 'handler' => \&lens_repair,    'desc' => 'Repair a lens' },
		'search'    => { 'handler' => \&lens_search,    'desc' => 'Search for a lens' },
		'sell'      => { 'handler' => \&lens_sell,      'desc' => 'Sell a lens' },
	};

=head2 material

The C<material> command provides subcommands for adding materials, i.e. film, paper and chemicals to the database.

=head3 material developer

Add a new developer to the database

=head3 material filmstock

Add a new type of filmstock to the database

=head3 material paperstock

Add a new type of photo paper to the database

=head3 material toner

Add a new chemical toner to the database

=cut
	$handlers{material} = {
		'developer'  => { 'handler' => \&developer_add,  'desc' => 'Add a new developer to the database' },
		'filmstock'  => { 'handler' => \&filmstock_add,  'desc' => 'Add a new type of filmstock to the database' },
		'paperstock' => { 'handler' => \&paperstock_add, 'desc' => 'Add a new type of photo paper to the database' },
		'toner'      => { 'handler' => \&toner_add,      'desc' => 'Add a new chemical toner to the database' },
	};

=head2 mount

The C<mount> command provides subcommands for working with lens mounts (aka camera systems)

=head3 mount add

Add a new lens mount to the database

=head3 mount info

View compatible cameras and lenses for a mount

=cut
	$handlers{mount} = {
		'add'  => { 'handler' => \&mount_add,  'desc' => 'Add a new lens mount to the database' },
		'info' => { 'handler' => \&mount_info, 'desc' => 'View compatible cameras and lenses for a mount' },
	};

=head2 movie

The C<movie> command provides subcommands for working with movies (cine films)

=head3 movie add

Add a new movie to the database

=head3 movie info

Show information about a movie

=cut
	$handlers{movie} = {
		'add'  => { 'handler' => \&movie_add,  'desc' => 'Add a new movie to the database' },
		'info' => { 'handler' => \&movie_info, 'desc' => 'Show information about a movie' },
	};

=head2 negative

The C<negative> command provides subcommands for working with negatives (or slides, etc) which are part of a film.

=head3 negative add

Add a new negative to the database as part of a film

=head3 negative bulk-add

C<negative bulk-add> registers a number of negatives to an existing film, but doesn't collect any data.
It is useful only for blocking out e.g. 24 negatives for a 24-exp film. They will need to have data added later.
Bulk add multiple negatives to the database as part of a film

=head3 negative info

Show information about a negative

=head3 negative prints

Find all prints made from a negative

=head3 negative search

Search for a negative

=head3 negative tag

Write EXIF tags to scans from a negative

=cut
	$handlers{negative} = {
		'add'      => { 'handler' => \&negative_add,     'desc' => 'Add a new negative to the database as part of a film' },
		'bulk-add' => { 'handler' => \&negative_bulkadd, 'desc' => 'Bulk add multiple negatives to the database as part of a film' },
		'info'     => { 'handler' => \&negative_info,    'desc' => 'Show information about a negative' },
		'prints'   => { 'handler' => \&negative_prints,  'desc' => 'Find all prints made from a negative' },
		'search'   => { 'handler' => \&negative_search,  'desc' => 'Search for a negative' },
		'tag'      => { 'handler' => \&negative_tag,     'desc' => 'Write EXIF tags to scans from a negative' },
	};

=head2 person

The C<person> command provides a set of subcommands for managing data about people (e.g. photographers)

=head3 person add

Add a new person to the database

=cut
	$handlers{person} = {
		'add' => { 'handler' => \&person_add, 'desc' => 'Add a new person to the database' },
	};

=head2 print

The C<print> command provides subcommands for working with prints which have been made from negatives.

=head3 print add

Add a new print that has been made from a negative

=head3 print archive

Add a print to a physical archive

=head3 print exhibit

Exhibit a print at an exhibition

=head3 print fulfil

Fulfil an order for a print

=head3 print info

Show details about a print

=head3 print label

Generate text to label a print

=head3 print locate

Locate a print in an archive

=head3 print tone

Add toning to a print

=head3 print order

Register an order for a print

=head3 print sell

Sell a print

=head3 print unarchive

Remove a print from a physical archive

=head3 print worklist

Display print todo list

=head3 print tag

Write EXIF tags to scans from a print

=cut
	$handlers{print} = {
		'add'       => { 'handler' => \&print_add,       'desc' => 'Add a new print that has been made from a negative' },
		'archive'   => { 'handler' => \&print_archive,   'desc' => 'Add a print to a physical archive' },
		'exhibit'   => { 'handler' => \&print_exhibit,   'desc' => 'Exhibit a print in an exhibition' },
		'fulfil'    => { 'handler' => \&print_fulfil,    'desc' => 'Fulfil an order for a print' },
		'info'      => { 'handler' => \&print_info,      'desc' => 'Show details about a print' },
		'label'     => { 'handler' => \&print_label,     'desc' => 'Generate text to label a print' },
		'locate'    => { 'handler' => \&print_locate,    'desc' => 'Locate a print in an archive' },
		'tone'      => { 'handler' => \&print_tone,      'desc' => 'Add toning to a print' },
		'order'     => { 'handler' => \&print_order,     'desc' => 'Register an order for a print' },
		'sell'      => { 'handler' => \&print_sell,      'desc' => 'Sell a print' },
		'unarchive' => { 'handler' => \&print_unarchive, 'desc' => 'Remove a print from a physical archive' },
		'worklist'  => { 'handler' => \&print_worklist,  'desc' => 'Display print todo list' },
		'tag'       => { 'handler' => \&print_tag,       'desc' => 'Write EXIF tags to scans from a print' },
	};

=head2 scan

=head3 scan add

Add a new scan of a negative or print to the database

=head3 scan edit

Add a new scan which is a derivative of an existing one

=head3 scan delete

Delete a scan from the database and optionally from the filesystem

=head3 scan search

Search the filesystem for scans which are not in the database, and import them

=head3 scan rename

Rename scans to include the caption in the filename

=cut
	$handlers{scan} = {
		'add'    => { 'handler' => \&scan_add,    'desc' => 'Add a new scan of a negative or print to the database' },
		'edit'   => { 'handler' => \&scan_edit,   'desc' => 'Add a new scan which is a derivative of an existing one' },
		'delete' => { 'handler' => \&scan_delete, 'desc' => 'Delete a scan from the database and optionally from the filesystem' },
		'search' => { 'handler' => \&scan_search, 'desc' => 'Search the filesystem for scans which are not in the database, and import them' },
		'rename' => { 'handler' => \&scan_rename, 'desc' => 'Rename scans to include the caption in the filename', },
	};

=head2 run

The C<task> command provides a set of useful tasks for reporting/fixing/cleaning data in the database.

=head3 run task

Run a selection of maintenance tasks on the database

=head3 run report

Run a selection of reports on the database

=head3 run migrations

Run migrations to upgrade the database schema to the latest version

=cut
	$handlers{run} = {
		'task'       => { 'handler' => \&run_task,       'desc' => 'Run a selection of maintenance tasks on the database' },
		'report'     => { 'handler' => \&run_report,     'desc' => 'Run a selection of reports on the database' },
		'migrations' => { 'handler' => \&run_migrations, 'desc' => 'Run migrations to upgrade the database schema to the latest version' },
	};

# This ensures the lib loads smoothly
1;
