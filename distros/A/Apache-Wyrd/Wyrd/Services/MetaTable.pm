#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
package Apache::Wyrd::Services::MetaTable;
use strict;
use DBI;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Services::MetaTable - MySQL-backed Namespace-based data store

=head1 SYNOPSIS

	use base qw(Apache::Wyrd);
	use Apache::Wyrd::Services::MetaTable;
	my $mt = Apache::Wyrd::Services::MetaTable->new($self->dbl->dbh);
	my $lastrun = $mt->lastrun;

	... do something with $lastrun value ...

	my $thisrun = `localtime`
	$mt->lastrun($thisrun);

=head1 DESCRIPTION

MetaTable is an SQL-backed version of Apache::Wyrd::Services::Tree in
terms of functionality, but is persistent across connections, as it
stores its data in a MySQL server.

It can store hashes, arrays, and scalars.  Pass the first two as references,
the scalars as single values.  It uses the namespace of the caller to decide
the lookup key, so only the base name of the key need be specified, by
referring to $meta_table->valuename (where $metatable stores a reference to
an instance of this class).  To retreive the value of 'valuename', call the
method valuename().  To set it, call the method with a single argument.

Be careful to dispose the MetaTable handler properly across connections,
or you run the risk of "leaking" database handles into your Apache
memory space.  The best way to avoid this is to invoke the MetaTable into
a scoped lexical only.

METHOD

=item new(dbh handle, scalar name)

invoke a new MetaTable.  The dbh handle connection must have create and
insert rights on the database.  The name is optional, and defaults to
_wyrd_meta.

=cut

sub new {
	my ($class, $dbh, $name) = @_;
	goto &AUTOLOAD if (ref($class) && &UNIVERSAL::isa($class, 'Apache::Wyrd::Services::MetaTable'));
	if (ref($dbh)) {
		if (&UNIVERSAL::isa($dbh, 'DBI::db')) {
			unless ($dbh->ping) {
				die "provided DBH handle is inactive.";
			}
		} else {
			die "please provide a valid DBI Database handle as param dbh.  This is a ". ref($dbh);
		}
	} else {
		die "please provide a valid DBI Database handle as param dbh";
	}
	$name = '' if ($name =~ /[^a-z0-9_]/);
	$name ||= '_wyrd_meta';
	my $tables = $dbh->selectall_arrayref('show tables');
	unless (grep {$name eq $_->[0]} @$tables) {
		$dbh->do("create table $name (id char(255) unique not null primary key, value text) ENGINE=MyISAM CHARSET=UTF8");
		if ($dbh->err) {
			die "Could not create table $name";
		}
	}
	return bless {
		dbh => $dbh,
		table => $name
	}, $class;
}

sub AUTOLOAD {
	no strict 'vars';
	return undef if $AUTOLOAD =~ /DESTROY$/;
	my ($package, $filename, $line) = caller;
	die "Method call to undefined sub: $AUTOLOAD" if ($package eq 'Apache::Wyrd::Services::MetaTable');
	my ($self, $newval) = @_;
	$AUTOLOAD =~ s/.+::(.+)/$1/;
	my $parent = $package . '::' . $AUTOLOAD;
	$newval = undef unless (scalar(@_) == 2);
	if ($newval) {
		$self->put_entry($parent, $newval);
		return;
	}
	return $self->get_entry($parent);
}

sub dbh {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self) = @_;
	return $self->{'dbh'};
}

sub table {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self) = @_;
	return $self->{'table'};
}

sub put_entry {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self, $id, $value) = @_;
	die "meta value name must be non-null." unless ($id);
	die "meta value name must be a valid scalar ([_A-Za-z0-9:] only).  You submitted: '$id'" if (ref($id) or ($id =~ /[^_A-Za-z0-9:]/));
	my $table = $self->table;
	my $dbh = $self->dbh;
	my $sh = $dbh->prepare("select value from $table where id=?");
	$sh->execute($id);
	if ($sh->fetchrow_arrayref) {
		$self->purge_entry($id);
	}
	my $ref = ref($value);
	my $error = 0;
	if ($ref eq 'ARRAY') {
		$error = $self->insert_arrayref($id, $value);
	} elsif ($ref eq 'HASH') {
		$error = $self->insert_hashref($id, $value);
	} elsif ($ref) {
		$error = "Only scalars, hashrefs, and arrayrefs can be stored in a MetaTable";
	} else {
		die qq(no storable value can begin with "{HASH}" or "{ARRAY}") if ($value =~ /^\{(HASH|ARRAY)\}/sm);
		my $sh = $dbh->prepare("insert into $table set id=?, value=?");
		$sh->execute($id, $value);
		$error = $sh->errstr;
	}
	$self->purge_entry($id) if ($error);
	return $error;
}

sub get_entry {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self, $id) = @_;
	die "meta value name must be non-null." unless ($id);
	die "meta value name must be a valid scalar ([_A-Za-z0-9:] only).  You submitted: '$id'" if (ref($id) or ($id =~ /[^_A-Za-z0-9:]/));
	my $table = $self->table;
	my $dbh = $self->dbh;
	my $sh = $dbh->prepare("select value from $table where id=?");
	$sh->execute($id);
	my $error = $sh->errstr;
	die $error if ($error);
	my $value = $sh->fetchrow_arrayref;
	$error = $sh->errstr;
	die $error if ($error);
	if ($value) {
		$value = $value->[0];
		if ($value eq '{HASH}') {
			$value = {};
			my $name = $id . ':HASH:';
			$sh = $dbh->prepare("select id from $table where id like ?");
			$sh->execute("$name%");
			$error = $sh->errstr;
			die $error if ($error);
			while (my $item = $sh->fetchrow_arrayref) {
				$error = $sh->errstr;
				die $error if ($error);
				my $id = $item->[0];
				my $key = $id;
				$key =~ s/^$name//;
				next if ($key =~/:(ARRAY|HASH):/);
				$value->{$key} = $self->get_entry($id);
			}
			return $value;
		} elsif ($value eq '{ARRAY}') {
			$value = [];
			my $name = $id . ':ARRAY:';
			$sh = $dbh->prepare("select id from $table where id like ?");
			$sh->execute("$name%");
			$error = $sh->errstr;
			die $error if ($error);
			while (my $item = $sh->fetchrow_arrayref) {
				$error = $sh->errstr;
				die $error if ($error);
				my $id = $item->[0];
				my $key = $id;
				$key =~ s/^$name//;
				next if ($key =~/:(ARRAY|HASH):/);
				$value->[$key] = $self->get_entry($id);
			}
			return $value;
		} else {
			return $value
		}
	} else {
		#Auto-vivify
		$sh = $dbh->prepare("insert into $table set id=?, value=?");
		$sh->execute($id, undef);
		$error = $sh->errstr;
		die $error if ($error);
	}
	return;
}

sub insert_arrayref {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self, $id, $array) = @_;
	my $table = $self->table;
	my $dbh = $self->dbh;
	my $sh = $dbh->prepare("insert into $table set id=?, value='{ARRAY}'");
	$sh->execute($id);
	my $error = $sh->errstr;
	return $error if ($error);
	for (my $i = 0; $i < @$array; $i++) {
		my $name = $id . ':ARRAY:' . "$i";
		my $error = $self->put_entry($name, $array->[$i]);
		return $error if ($error);
	}
	return;
}

sub insert_hashref {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self, $id, $hash) = @_;
	my $table = $self->table;
	my $dbh = $self->dbh;
	my $sh = $dbh->prepare("insert into $table set id=?, value='{HASH}'");
	$sh->execute($id);
	my $error = $sh->errstr;
	return $error if ($error);
	foreach my $key (keys %$hash) {
		my $name = $id . ':HASH:' . $key;
		my $error = $self->put_entry($name, $hash->{$key});
		return $error if ($error);
	}
	return;
}

sub purge_entry {
	my ($package, $filename, $line) = caller;
	goto &AUTOLOAD if ($package ne 'Apache::Wyrd::Services::MetaTable');
	my ($self, $id) = @_;
	my $table = $self->table;
	my $dbh = $self->dbh;
	my $sh = $dbh->prepare("delete from $table where id like ?");
	$sh->execute("$id%");
	my $error = $sh->errstr;
	return $error;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;