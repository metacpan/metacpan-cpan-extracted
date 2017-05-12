package TESTCLIENT::Page4;
use strict;
use base qw(Apache::Wyrd::Interfaces::Indexable TESTCLIENT::Wyrd);
use Apache::Wyrd::Services::MySQLIndex;

sub _format_output {
	my ($self) = @_;
	my $dbh = DBI->connect('DBI:mysql:test', 'test', '');
	my $index = Apache::Wyrd::Services::MySQLIndex->new({
		dbh => $dbh,
		attributes => [qw(regular map)],
		maps => [qw(map)],
		strict => 1,
		debug => 1
	});
	$index->update_entry($self);
}


sub index_name {
	my ($self) = @_;
	return $self->{'name'};
}

sub index_regular {
	my ($self) = @_;
	return $self->{'regular'};
}

sub index_map {
	my ($self) = @_;
	return $self->{'map'};
}

sub index_timestamp {
	my ($self) = @_;
	return $self->dbl->mtime unless($self->_flags->now);
	return time;
}

1;