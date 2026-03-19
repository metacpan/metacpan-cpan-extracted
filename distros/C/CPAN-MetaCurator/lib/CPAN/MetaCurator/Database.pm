package CPAN::MetaCurator::Database;

use 5.36.0;
use parent 'CPAN::MetaCurator::Config';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;

use File::Spec;

use Moo;

use Types::Standard qw/Any ArrayRef Bool HashRef Object Str/;

has column_names =>
(
	default		=> sub{return []},
	is			=> 'rw',
	isa			=> ArrayRef,
	required	=> 0,
);

has creator =>
(
	is			=> 'rw',
	isa			=> Object, # 'DBIx::Admin::CreateTable'.
	required	=> 0,
);

has db =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has dbh =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has engine =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has include_packages =>
(
	default		=> sub{return 0},
	is			=> 'rw',
	isa			=> Bool,
	required	=> 0,
);

has input_path =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has metapackager_db =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has metapackager_dbh =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has output_path =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has pad =>
(
	default		=> sub{return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has time_option =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '1.13';

# -----------------------------------------------

sub build_pad
{
	my($self)			= @_;
	my($pad)			= {};
	$$pad{count}		= {};
	$$pad{count}{$_}	= 0 for (@{$self -> node_types});

	for (@{$self -> table_names}) {$$pad{$_} = $self -> read_table($_) };

	# Constants.

	$$pad{$$_{name} } = $$_{value} for (@{$$pad{constants} });

	# MetaPackager.

	if ($self -> include_packages)
	{
		my($table_name) = $self -> read_metapackager_table($pad);

		$self -> logger -> info("Including metapackager table 'packages'");
		$self -> logger -> info("Size of cpan.metapackager.sqlite table '$table_name': $$pad{count}{$table_name}");
	}
	else
	{
		$self -> logger -> info("Excluding metapackager table 'packages'");
	}

	# Modules.
	# There is a db table called modules so we need another name for the hash
	# where the keys are the names of the modules and the values are db ids.

	$$pad{module_names}				= {};
	$$pad{module_names}{$$_{name} }	= $$_{id} for (@{$$pad{modules} });

	# Topics.
	# There is a db table called topics so we need another name for the hash
	# where the keys are the names of the topics and the values are db ids.

	$$pad{topic_names}		= {};
	$$pad{topic_html_ids}	= {};

	for (@{$$pad{topics} })
	{
		$$pad{count}{topic}++;

		$$pad{topic_html_ids}{$$_{title} }	= $$pad{html_id_offset} * $$_{id};
		$$pad{topic_names}{$$_{title} }		= $$_{id};
	}

	# Dates.
	# DateTime::Tiny does not handle time_zone.

	$_					= DateTime::Tiny -> now;
	$$pad{now}			= $_ -> as_string;
	$$pad{current_year}	= substr($$pad{now}, 0, 4);

	return $self -> pad($pad);

} # End of build_pad.

# -----------------------------------------------

sub get_table_column_names
{
	my($self, $discard_id, $table_name)	= @_;
	my($sth) = $self -> dbh -> prepare("PRAGMA table_info($table_name)");

	$sth -> execute;

	my($row);
	my(@column_names);

	while ($row = $sth -> fetchrow_hashref)
	{
		push @column_names, $$row{name} if (! $discard_id);
	}

	$sth -> finish;
	$self -> column_names(\@column_names);

} # End of get_table_column_names;

# -----------------------------------------------

sub init_db
{
	my($self)		= @_;
	my($config)		= $self -> config;

	my(%attributes)	=
	(
		AutoCommit 				=> $$config{AutoCommit},
		mysql_enable_utf8		=> $$config{mysql_enable_utf8},		# Ignored if not using MySQL.
		mysql_enable_utf8mb4	=> $$config{mysql_enable_utf8mb4},	# Ignored if not using MySQL.
		pg_enable_utf8			=> $$config{pg_enable_utf8},		# Ignored if not using Pg.
		RaiseError 				=> $$config{RaiseError},
		sqlite_unicode			=> $$config{sqlite_unicode},		# Ignored if not using SQLite.
	);

	my(@dsn)	= split('=', $$config{dsn});
	$dsn[1]	 	= File::Spec -> catfile($self -> home_path, $dsn[1]);
	$dsn[0]		= "$dsn[0]=$dsn[1]";

	$self -> dbh(DBI -> connect($dsn[0], $$config{username}, $$config{password}, \%attributes) );
	$self -> dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);
	$self -> db(DBIx::Simple -> new($self -> dbh) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> dbh, verbose => 0)	);
	$self -> engine($self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : '');
	$self -> time_option($self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : '');
	$self -> logger -> info("Connected to $dsn[0]");
	$self -> logger -> info($self -> separator);

} # End of init_db.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	$self -> db -> insert($table_name, {map{($_ => $$hashref{$_})} keys %$hashref})
		|| die $self -> db -> error;

	return $self -> db -> last_insert_id(undef, undef, $table_name, undef);

} # End of insert_hashref.

# -----------------------------------------------

sub init_metapackager_db
{
	my($self)		= @_;
	my($config)		= $self -> metapackager_config;

	my(%attributes)	=
	(
		AutoCommit 				=> $$config{AutoCommit},
		mysql_enable_utf8		=> $$config{mysql_enable_utf8},		# Ignored if not using MySQL.
		mysql_enable_utf8mb4	=> $$config{mysql_enable_utf8mb4},	# Ignored if not using MySQL.
		pg_enable_utf8			=> $$config{pg_enable_utf8},		# Ignored if not using Pg.
		RaiseError 				=> $$config{RaiseError},
		sqlite_unicode			=> $$config{sqlite_unicode},		# Ignored if not using SQLite.
	);

	my(@dsn)	= split('=', $$config{dsn});
	$dsn[1]	 	= File::Spec -> catfile($dsn[1]);
	$dsn[0]		= "$dsn[0]=$dsn[1]";

	$self -> metapackager_dbh(DBI -> connect($dsn[0], $$config{username}, $$config{password}, \%attributes) );
	$self -> metapackager_dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);
	$self -> metapackager_db(DBIx::Simple -> new($self -> metapackager_dbh) );
	$self -> logger -> info("Connected to $dsn[0]");
	$self -> logger -> info($self -> separator);

} # End of init_metapackager_db.

# --------------------------------------------------

sub read_1_record
{
	my($self, $table_name, $id) = @_;
	my($sql)	= "select * from $table_name where id = $id";
	my($set)	= $self -> db -> query($sql) || die $self -> db -> error;

	# Return a hashref.

	return ${$set -> hashes}[0];

} # End of read_1_record.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name)	= @_;
	my($sql)				= "select * from $table_name";
	my($set)				= $self -> db -> query($sql) || die $self -> db -> error;

	# Return an arrayref of hashrefs.

	return [$set -> hashes];

} # End of read_table.

# --------------------------------------------------

sub read_metapackager_table
{
	my($self, $pad)	= @_;

	$self -> init_metapackager_config;
	$self -> init_metapackager_db;

	# Return an arrayref of hashrefs.

	my($table_name)					= 'packages';
	my($sql)						= "select * from $table_name";
	my($set)						= $self -> metapackager_db -> query($sql) || die $self -> metapackager_db -> error;
	$set							= [$set -> hashes];
	$$pad{count}{$table_name}		= $#$set + 1;
	$$pad{$table_name}				= {};
	$$pad{$table_name}{$$_{name} }	= $$_{id} for (@$set);

	$self -> metapackager_dbh -> disconnect;

	return $table_name;

} # End of read_metapackager_table.

# --------------------------------------------------

sub update_table
{
	my($self, $table_name, $id, $columns)	= @_;
	my($sql)	= "update $table_name set $columns where id = $id";
	my($set)	= $self -> db -> query($sql) || die $self -> db -> error;

	return $set;

} # End of update_table.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
