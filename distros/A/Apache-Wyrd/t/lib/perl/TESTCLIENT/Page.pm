package TESTCLIENT::Page;
use strict;
use base qw(Apache::Wyrd::Interfaces::Indexable TESTCLIENT::Wyrd);
use Apache::Wyrd::Services::Index;

sub _format_output {
	my ($self) = @_;
	my $file = $self->dbl->req->document_root . '/../data/testindex.db';
	my $index = Apache::Wyrd::Services::Index->new({
		file => $file,
		attributes => [qw(regular map)],
		maps => [qw(map)],
		strict => 1,
		bigfile => 0,
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