package builder::MarkdownMaker;
use strict;
use warnings;
use parent qw/Pod::Markdown/;

my $markdown;

sub parse_from_file {
	my ($self, $path) = @_;
	$markdown = _read_file($path);
}

sub as_markdown {
	my $self = shift;
	return $markdown;
}

sub _read_file {
	my ($path) = @_;
	my $glue = "";
	my @body;
	open my $fh, '<', $path or die "Couldn't open $path";
	binmode $fh;
	while (my $line = <$fh>) {
		push @body, $line;
	}
	close $fh;
	return join $glue, @body;
}

1;