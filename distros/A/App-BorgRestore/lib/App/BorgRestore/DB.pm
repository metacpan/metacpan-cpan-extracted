package App::BorgRestore::DB;
use v5.14;
use strict;
use warnings;

use App::BorgRestore::Helper;

use autodie;
use DBI;
use Function::Parameters;
use Log::Any qw($log);

=encoding utf-8

=head1 NAME

App::BorgRestore::DB - Database layer

=head1 DESCRIPTION

App::BorgRestore::DB abstracts the database storage used internally by L<App::BorgRestore>.

=cut

method new($class: $db_path, $cache_size) {
	my $self = {};
	bless $self, $class;

	if (! -f $db_path) {
		my $db = $self->_open_db($db_path, $cache_size);
		$self->initialize_db();
	} else {
		$self->_open_db($db_path, $cache_size);
	}

	return $self;
}

method _open_db($dbfile, $cache_size) {
	$log->debugf("Opening database at %s", $dbfile);
	$self->{dbh} = DBI->connect("dbi:SQLite:dbname=$dbfile","","", {RaiseError => 1, Taint => 1});
	$self->{dbh}->do("PRAGMA cache_size=-".$cache_size);
	$self->{dbh}->do("PRAGMA strict=ON");
}

method initialize_db() {
	$log->debug("Creating initial database");
	$self->{dbh}->do('create table `files` (`path` text, primary key (`path`)) without rowid;');
	$self->{dbh}->do('create table `archives` (`archive_name` text unique);');
}

method get_archive_names() {
	my @ret;

	my $st = $self->{dbh}->prepare("select `archive_name` from `archives`;");
	$st->execute();
	while (my $result = $st->fetchrow_hashref) {
		push @ret, $result->{archive_name};
	}
	return \@ret;
}

method get_archive_row_count() {
	my $st = $self->{dbh}->prepare("select count(*) count from `files`;");
	$st->execute();
	my $result = $st->fetchrow_hashref;
	return $result->{count};
}

method add_archive_name($archive) {
	$archive = App::BorgRestore::Helper::untaint_archive_name($archive);

	my $st = $self->{dbh}->prepare('insert into `archives` (`archive_name`) values (?);');
	$st->execute($archive);

	$self->_add_column_to_table("files", $archive);
}

method _add_column_to_table($table, $column) {
	my $st = $self->{dbh}->prepare('alter table `'.$table.'` add column `'._prefix_archive_id($column).'` integer;');
	$st->execute();
}

method remove_archive($archive) {
	$archive = App::BorgRestore::Helper::untaint_archive_name($archive);

	my $archive_id = $self->get_archive_id($archive);

	my @keep_archives = grep {$_ ne $archive;} @{$self->get_archive_names()};

	$self->{dbh}->do('create table `files_new` (`path` text, primary key (`path`)) without rowid;');
	for my $archive (@keep_archives) {
		$self->_add_column_to_table("files_new", $archive);
	}

	my @columns_to_copy = map {'`'._prefix_archive_id($_).'`'} @keep_archives;
	@columns_to_copy = ('`path`', @columns_to_copy);
	$self->{dbh}->do('insert into `files_new` select '.join(',', @columns_to_copy).' from files');

	$self->{dbh}->do('drop table `files`');

	$self->{dbh}->do('alter table `files_new` rename to `files`');

	my $sql = 'delete from `files` where ';
	$sql .= join(' is null and ', grep {$_ ne '`path`' } @columns_to_copy);
	$sql .= " is null";

	my $st = $self->{dbh}->prepare($sql);
	my $rows = $st->execute();

	$st = $self->{dbh}->prepare('delete from `archives` where `archive_name` = ?;');
	$st->execute($archive);
}

fun _prefix_archive_id($archive) {
	$archive = App::BorgRestore::Helper::untaint_archive_name($archive);

	return 'timestamp-'.$archive;
}

method get_archive_id($archive) {
	return _prefix_archive_id($archive);
}

method get_archives_for_path($path) {
	my $st = $self->{dbh}->prepare('select * from `files` where `path` = ?;');
	$st->execute(App::BorgRestore::Helper::untaint($path, qr(.*)));

	my @ret;

	my $result = $st->fetchrow_hashref;
	my $archives = $self->get_archive_names();

	for my $archive (@$archives) {
		my $archive_id = $self->get_archive_id($archive);
		my $timestamp = $result->{$archive_id};

		push @ret, {
			modification_time => $timestamp,
			archive => $archive,
		};
	}

	return \@ret;
}


method add_path($archive_id, $path, $time) {
	my $st = $self->{dbh}->prepare_cached('insert or ignore into `files` (`path`, `'.$archive_id.'`)
		values(?, ?)');
	$st->execute($path, $time);

	$st = $self->{dbh}->prepare_cached('update files set `'.$archive_id.'` = ? where `path` = ?');
	$st->execute($time, $path);
}

method begin_work() {
	$self->{dbh}->begin_work();
}

method commit() {
	$self->{dbh}->commit();
}

method vacuum() {
	$self->{dbh}->do("vacuum");
}


1;

__END__
