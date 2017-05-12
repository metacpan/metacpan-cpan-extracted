package SVN::Dump::AuthorExtractor;
BEGIN {
  $SVN::Dump::AuthorExtractor::VERSION = '1.000';
}

# Replay a Subversion dump.  Must be subclassed with something classy.

use Moose;
extends qw(SVN::Dump::Walker);

use Carp qw(confess);

has verbose => ( is => 'ro', isa => 'Bool', default => 0 );

has authors => ( is => 'rw', isa => 'HashRef[Str]', default => sub { {} });

### Low-level tracking.

sub on_revision {
	my ($self, $revision, $author, $date, $log_message) = @_;

	$author = "(no author)" unless defined $author and length $author;
	$self->authors()->{$author} = 1;
}

sub on_walk_done {
	my $self = shift;

	foreach my $author (sort keys %{$self->authors()}) {
		print "$author = <$author\@" . $self->svn_dump()->uuid() . ">\n";
	}
}

1;
