package CPAN::MetaCurator::Util::Database;

use 5.40.0;
use parent 'CPAN::MetaCurator::Util::Config';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;

use File::Spec;

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Object Str/;

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

has input_path =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
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

our $VERSION = '1.00';

# -----------------------------------------------

sub build_pad
{
	my($self)			= @_;
	my($pad)			= {};
	$$pad{leaf_count}	= 0;
	$$pad{topic_count}	= 0;

	for (@{$self -> table_names}) {$$pad{$_} = $self -> read_table($_) };

	# Constants.

	my($key);

	for $key (@{$$pad{constants} })
	{
		for (qw/domain_name encoding logo_path page_name time_zone title_font_path title_font_size/)
		{
			$$pad{$_} = $$key{value} if ($$key{name} eq $_);
		}
	}

	$self -> logger -> info('Constants:');

	for (qw/domain_name encoding logo_path page_name time_zone title_font_path title_font_size/)
	{
		$self -> logger -> info("$_ => $$pad{$_}");
	}

	$self -> logger -> info($self -> separator);

	# Topics.
	# There is a db table called topics so we need another name for the hash
	# where the keys are the names of the topics and the values are db ids.

	$$pad{topic_names} = {};

	for $_ (@{$$pad{topics} })
	{
		$$pad{topic_names}{$$_{title} } = $$_{id};
	}

	$self -> logger -> info('Topics:');

	for (sort keys %{$$pad{topic_names} })
	{
		$self -> logger -> info("$_ => $$pad{topic_names}{$_}");
	}

	$self -> logger -> info($self -> separator);

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
		AutoCommit 			=> $$config{AutoCommit},
		mysql_enable_utf8	=> $$config{mysql_enable_utf8},	#Ignored if not using MySQL.
		RaiseError 			=> $$config{RaiseError},
		sqlite_unicode		=> $$config{sqlite_unicode},	#Ignored if not using SQLite.
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
