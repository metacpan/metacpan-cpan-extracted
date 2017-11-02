package App::Office::CMS::Database;

use strict;
use warnings;

use App::Office::CMS::Database::Asset;
use App::Office::CMS::Database::Content;
use App::Office::CMS::Database::Design;
use App::Office::CMS::Database::Event;
use App::Office::CMS::Database::Menu;
use App::Office::CMS::Database::Page;
use App::Office::CMS::Database::Site;
use App::Office::CMS::Util::Config;
use App::Office::CMS::Util::Logger;

use DBI;

use DBIx::Admin::CreateTable;

use DBIx::Simple;

use File::Slurper 'read_lines';

use Moo;

use Try::Tiny;

use Types::Standard qw/Any HashRef/;

has asset =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Asset',
);

has config =>
(
	is  => 'rw',
	isa => HashRef,
);

has content =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Content',
);

has dbh =>
(
	is  => 'rw',
	isa => Any,
);

has design =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Design',
);

has event =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Event',
);

has event_type_name2id_map =>
(
	is  => 'rw',
	isa => HashRef,
);

has logger =>
(
	is  => 'rw',
	isa => Any,
);

has menu =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Menu',
);

has page =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Page',
);

has session =>
(
	is  => 'rw',
	isa => Any,
);

has simple =>
(
	is  => 'rw',
	isa => Any,
);

has site =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::Database::Site',
);

our $VERSION = '0.93';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> config;
	my($attr)   =
	{
		AutoCommit => $$config{AutoCommit},
		RaiseError => $$config{RaiseError},
	};

	if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode})
	{
		$$attr{sqlite_unicode} = 1;
	}

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr) );

=pod

use Modern::Perl;
use DBI;
use Exception::Class::DBI;

my $dbh = DBI->connect('DBI:mysql:test', 'user', pass, {
PrintError => 0,
RaiseError => 0,
HandleError => Exception::Class::DBI->handler,
});


eval {
$dbh->do('insert into non_extistent_table values(1)')
};

if (my $e = Exception::Class->caught('Exception::Class::DBI')) {
say $e->err;
say $e->errstr;
} else {
# Check for other exceptions as required
}

=cut

	if ($$config{dsn} =~ /SQLite/i)
	{
		$self -> dbh -> do('PRAGMA foreign_keys = ON');
	}

	$self -> asset(App::Office::CMS::Database::Asset -> new(db => $self) );
	$self -> content(App::Office::CMS::Database::Content -> new(db => $self) );
	$self -> design(App::Office::CMS::Database::Design -> new(db => $self) );
	$self -> event(App::Office::CMS::Database::Event -> new(db => $self) );
	$self -> logger(App::Office::CMS::Util::Logger -> new(db => $self) );
	$self -> menu(App::Office::CMS::Database::Menu -> new(db => $self) );
	$self -> page(App::Office::CMS::Database::Page -> new(db => $self) );
	$self -> simple(DBIx::Simple -> new($self -> dbh) );
	$self -> site(App::Office::CMS::Database::Site -> new(db => $self) );

	return $self;

}	# End of BUILD.

# --------------------------------------------------

sub build_context
{
	my($self, $site_id, $design_id) = @_;

	$self -> log(debug => "build_context($site_id, $design_id)");

	return "$site_id/$design_id";

} # End of build_context.

# --------------------------------------------------

sub build_default_asset
{
	my($self, $page) = @_;

	$self -> log(debug => 'build_default_asset()');

	my($home_asset) = ${$self -> config}{homepage_template};
	my($asset_type) = $self -> asset -> get_asset_types;
	$asset_type     = [grep{$$_{file_name} =~ /$home_asset/} @$asset_type];

	if ($#$asset_type != 0)
	{
		die "Error: asset_types table must have precisely one template called '$home_asset'";
	}

	# Note: Hide $asset_path from user.

	try
	{
		my($asset_path) = ${$self -> config}{page_template_path} . "/$home_asset";
		my($asset)      = read_lines($asset_path);
	}
	catch
	{
		die "Error: Homepage template file '$home_asset' is missing";
	};

	return
	{
		asset_type_id => $$asset_type[0]{id},
		design_id     => $$page{design_id},
		page_id       => $$page{id}, # For a default page, this is undef.
		site_id       => $$page{site_id},
	};

} # End of build_default_asset.

# --------------------------------------------------

sub build_default_content
{
	my($self, $site_id, $design_id, $page_id) = @_;

	$self -> log(debug => "build_default_content($site_id, $design_id, $page_id)");

	return
	{
		body_text => '',
		design_id => $design_id,
		head_text => '',
		page_id   => $page_id,
		site_id   => $site_id,
	};

} # End of build_default_content.

# --------------------------------------------------

sub build_default_design
{
	my($self, $site_id, $name, $menu_orientation_id, $os_type_id, $output_directory, $output_doc_root) = @_;

	$self -> log(debug => "build_default_design($site_id, $name, ...)");

	return
	{
		menu_orientation_id => $menu_orientation_id,
		os_type_id          => $os_type_id,
		output_directory    => $output_directory,
		output_doc_root     => $output_doc_root,
		name                => $name,
		site_id             => $site_id,
	};

} # End of build_default_design.

# --------------------------------------------------

sub build_default_page
{
	my($self, $site, $design, $name) = @_;

	$self -> log(debug => "build_default_page($$site{name}, $$design{name}, $name)");

	return
	{
		context      => '', # Filled in by Database::Page.add() or .update().
		design_id    => $$design{id},
		design_name  => $$design{name},
		homepage     => 'No',
		name         => $name,
		site_id      => $$site{id},
		site_name    => $$site{name},
	};

} # End of build_default_page.

# --------------------------------------------------

sub build_default_site
{
	my($self, $name) = @_;

	$self -> log(debug => "build_default_site($name)");

	return
	{
		name => $name,
	};

} # End of build_default_site.

# --------------------------------------------------

sub build_event_type_name_map
{
	my($self) = @_;

	$self -> event_type_name2id_map($self -> get_name2id_map('event_types') );

} # End of build_event_type_name_map.

# --------------------------------------------------
# Copied from File::Spec.

sub get_default_os_type_id
{
	my($self)        = @_;
	my($name2id_map) = $self -> get_name2id_map('os_types');
	my(%type)        =
		(
		 MacOS   => 'Mac',
		 MSWin32 => 'Win32',
		 os2     => 'OS2',
		 VMS     => 'VMS',
		 epoc    => 'Epoc',
		 NetWare => 'Win32', # Yes, File::Spec::Win32 works on NetWare.
		 symbian => 'Win32', # Yes, File::Spec::Win32 works on symbian.
		 dos     => 'OS2',   # Yes, File::Spec::OS2 works on DJGPP.
		 cygwin  => 'Cygwin',
		);

	return $$name2id_map{$type{$^O} || 'Unix'};

} # End of get_default_os_type_id.

# --------------------------------------------------

sub get_design_count
{
	my($self) = @_;

	return $self -> simple -> query('select count(*) from designs') -> list;

} # End of get_design_count.

# --------------------------------------------------

sub get_id2name_map
{
	my($self, $table_name) = @_;

	return $self -> select_map("select id, name from $table_name");

} # End of get_id2name_map.

# --------------------------------------------------

sub get_menu_orientations
{
	my($self) = @_;

	return [$self -> simple -> query('select * from menu_orientations') -> hashes];

} # End of get_menu_orientations.

# --------------------------------------------------

sub get_name2id_map
{
	my($self, $table_name) = @_;

	return $self -> select_map("select name, id from $table_name");

} # End of get_name2id_map.

# --------------------------------------------------

sub get_os_type
{
	my($self, $os_type_id) = @_;
	my($id2name_map) = $self -> get_id2name_map('os_types');

	return $$id2name_map{$os_type_id};

} # End of get_os_type.

# --------------------------------------------------

sub get_page_count
{
	my($self) = @_;

	return $self -> simple -> query('select count(*) from designs') -> list;

} # End of get_page_count.

# --------------------------------------------------

sub get_site_count
{
	my($self) = @_;

	return $self -> simple -> query('select count(*) from sites') -> list;

} # End of get_site_count.

# -----------------------------------------------

sub insert_hash
{
	my($self, $table_name, $field_values) = @_;

	$self -> log(debug => "insert_hash($table_name)");

	my(@fields) = sort keys %$field_values;
	my(@values) = @{$field_values}{@fields};
	my($sql)    = sprintf 'insert into %s (%s) values (%s)', $table_name, join(',', @fields), join(',', ('?') x @fields);

	$self -> dbh -> do($sql, {}, @values);

	$self -> log(debug => 'Record inserted');

} # End of insert_hash.

# -----------------------------------------------

sub insert_hash_get_id
{
	my($self, $table_name, $field_values) = @_;

	$self -> log(debug => "insert_hash_get_id($table_name)");

	$self -> insert_hash($table_name, $field_values);
	$self -> last_insert_id($table_name);

} # End of insert_hash_get_id.

# -----------------------------------------------

sub last_insert_id
{
	my($self, $table_name) = @_;

	return $self -> dbh -> last_insert_id(undef, undef, $table_name, undef);

} # End of last_insert_id.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level, $s);

} # End of log;

# -----------------------------------------------

sub select_map
{
	my($self, $sql) = @_;

	return {@{$self -> dbh -> selectcol_arrayref($sql, {Columns=>[1, 2]}) } };

} # End of select_map.

# -----------------------------------------------

sub set_session
{
	my($self, $session) = @_;

	$self -> session($session);

} # End of set_session.

# --------------------------------------------------

sub validate_asset_type
{
	my($self, $value) = @_;

	$self -> log(debug => 'validate_asset_type()');

	my($id) = $self -> dbh -> selectrow_hashref('select id from asset_types where id = ?', {}, $value);

	return $id ? $$id{id} : 0;

} # End of validate_asset_type.

# --------------------------------------------------

sub validate_id
{
	my($self, $class_name, $id) = @_;

	$self -> log(debug => "validate_id($class_name, $id)");

	my(@row) = $self -> simple -> map({id => $id});

	return $#row < 0 ? 0 : 1;

} # End of validate_id.

# --------------------------------------------------

1;
