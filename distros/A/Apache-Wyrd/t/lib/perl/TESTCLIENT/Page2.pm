package TESTCLIENT::Page2;
use strict;
use base qw(TESTCLIENT::Page);
use Apache::Wyrd::Services::Index;

sub _format_output {
	my ($self) = @_;
	my $file = $self->dbl->req->document_root . '/../data/testindex2.db';
	my $index = Apache::Wyrd::Services::Index->new({
		file => $file,
		attributes => [qw(regular map)],
		maps => [qw(map)],
		strict => 1,
		dirty => 1,
		bigfile => 1,
		debug => 1
	});
	$index->update_entry($self);
}

1;