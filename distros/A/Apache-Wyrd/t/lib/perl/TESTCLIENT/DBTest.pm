#!/usr/bin/perl -w


package TESTCLIENT::DBTest;
use strict;
use base qw(TESTCLIENT::Wyrd);

sub _format_output {
	my ($self) = @_;
	my $file = $self->dbl->req->document_root . '/../data/testindex.db';
	my $index = Apache::Wyrd::Services::Index->new({
		file => $file,
		attributes => [qw(regular map)],
		maps => [qw(map)],
		strict => 1
	});
	$index->delete_index;
}

1;