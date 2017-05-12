package SVN::Dump::Walker;
BEGIN {
  $SVN::Dump::Walker::VERSION = '1.000';
}

# Base class for higher-level objects that process SVN::Dump streams.
# Does some fundamental handling of SVN::Dump events, then provides
# slightly higher level events to callbacks.

# TODO - Basically done.  Think twice if you think it requires
# modification.

use lib qw(../SVN-Dump/lib ./lib);

use Moose;
use SVN::Dump;

has svn_dump_filename => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has current_revision => (
	is      => 'rw',
	isa     => 'Int',
	reader  => 'get_current_revision',
	writer  => 'set_current_revision',
);

has svn_dump => (
	is      => 'ro',
	isa     => 'SVN::Dump',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return SVN::Dump->new(
			{ file => $self->svn_dump_filename() },
		);
	},
);

has include_regexp => (
	is	=> 'ro',
	isa	=> 'Maybe[RegexpRef]',
);

# ($self, $revision)
sub on_revision_done { undef }

# ($self, $revision, $author, $date, $log_message)
sub on_revision { undef }

# ($self, $revision, $path, $kind, $data)
sub on_node_add { undef }

# ($self, $revision, $path, $kind, $data)
sub on_node_change { undef }

# ($self, $revision, $path, $kind, $data)
sub on_node_replace { undef }

# ($self, $revision, $path)
sub on_node_delete { undef }

# ($self, $revision, $path, $kind, $from_rev, $from_path, $data)
sub on_node_copy { undef }

# ($self)
sub on_walk_begin { undef }

# ($self)
sub on_walk_done { undef }

sub walk {
	my $self = shift;

	$self->on_walk_begin();

	my $record;
	RECORD: while (
		$record = (
			$record && $record->get_included_record()
		) || $self->svn_dump()->next_record()
	) {
		my $type = $record->type();

		# Unsupported for now.  Does anyone need these?
		next RECORD if $type eq "format";
		next RECORD if $type eq "uuid";

		my $header = $record->get_headers_block();

		# Skip records that are not matched.
		if ($self->include_regexp()) {
			my $include_regexp = $self->include_regexp();
			my $node_path = $header->get('Node-path');
			next RECORD if defined $node_path and $node_path !~ /$include_regexp/;

			# Make sure we're not crossing the streams.
			my $copy_src_path = $header->get('Node-copyfrom-path');
			if (
				(defined $copy_src_path) and
				(length $copy_src_path) and
				($copy_src_path !~ /$include_regexp/)
			) {
				die(
					"copy from $copy_src_path ",
					"to $node_path ",
					"violates --include $include_regexp at revision ",
					$self->get_current_revision()
				);
			}
		}

		if ($type eq "revision") {
			$self->on_revision_done($self->get_current_revision()) if (
				defined $self->get_current_revision()
			);

			$self->set_current_revision($header->{'Revision-number'});

			my $author = $record->get_property("svn:author");
			$author = "(no author)" unless defined($author) and length($author);

			$self->on_revision(
				$self->get_current_revision(),
				$author,
				$record->get_property("svn:date"),
				$record->get_property("svn:log"),
			);
			next RECORD;
		}

		die "unexpected svn dump type '$type'" unless $type eq "node";

		my $action = $header->get('Node-action');

		# Can't copy a deletion, and deletion knows no kind.
		if ($action eq "delete") {
			my $path = $header->get('Node-path');
			$self->on_node_delete($self->get_current_revision(), $path);
			next RECORD;
		}

		my $text = $record->get_text_block();

		# Add can be plain or involve a copy operation.
		if ($action eq "add") {
			my $copy_from_rev = $header->get('Node-copyfrom-rev');
			if (defined $copy_from_rev) {
				$self->on_node_copy(
					$self->get_current_revision(),
					$header->get('Node-path'),
					$header->get('Node-kind'),
					$copy_from_rev,
					$header->get('Node-copyfrom-path'),
					($text ? $text->get() : undef),
				);
				next RECORD;
			}

			$self->on_node_add(
				$self->get_current_revision(),
				$header->get('Node-path'),
				$header->get('Node-kind'),
				($text ? $text->get() : undef),
			);
			next RECORD;
		}

		if ($action eq "change") {
			# I have read that "change" may also trigger a copy.
			my $copy_from_rev = $header->get('Node-copyfrom-rev');
			if (defined $copy_from_rev) {
				$self->on_node_copy(
					$self->get_current_revision(),
					$header->get('Node-path'),
					$header->get('Node-kind'),
					$copy_from_rev,
					$header->get('Node-copyfrom-path'),
					($text ? $text->get() : undef),
				);
				next RECORD;
			}

			$self->on_node_change(
				$self->get_current_revision(),
				$header->get('Node-path'),
				$header->get('Node-kind'),
				($text ? $text->get() : undef),
			);
			next RECORD;
		}

		if ($action eq "replace") {
			# I have read that "replace" may also trigger a copy.
			my $copy_from_rev = $header->get('Node-copyfrom-rev');
			if (defined $copy_from_rev) {
				$self->on_node_copy(
					$self->get_current_revision(),
					$header->get('Node-path'),
					$header->get('Node-kind'),
					$copy_from_rev,
					$header->get('Node-copyfrom-path'),
					($text ? $text->get() : undef),
				);
				next RECORD;
			}

			$self->on_node_replace(
				$self->get_current_revision(),
				$header->get('Node-path'),
				$header->get('Node-kind'),
				($text ? $text->get() : undef),
			);
			next RECORD;
		}

		die "strange action '$action'";
	}

	$self->on_revision_done($self->get_current_revision()) if (
		$self->get_current_revision()
	);

	$self->on_walk_done();

	# For chained methods.
	return $self;
}

1;

__END__

=head1 NAME

SVN::Dump::Walker - A callback interface for SVN::Dump.

=head1 SYNOPSIS

Subclass SVN::Dump::Walker to perform some task.  Moose is optional.
This is an abbreviated version of L<SVN::Dump::AuthorExtractor>:

	package SVN::Dump::AuthorExtractor;
	use Moose;
	extends qw(SVN::Dump::Walker);

	has authors => (
		is      => 'rw',
		isa     => 'HashRef[Str]',
		default => sub { {} }
	);

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

And the subclass is used.  This is an abbreviated version of
L<snauthors>:

	my $replayer = SVN::Dump::AuthorExtractor->new(
		svn_dump_filename => "subversion.dump",
	);

	$replayer->walk();
	exit;

=head1 DESCRIPTION

SVN::Dump::Walker walks a Subversion dump with SVN::Dump, calling back
specific methods for each record.

=head2 Construction

SVN::Dump::Walker takes a few basic constructor parameters.

C<svn_dump_filename> should contain the name of a Subversion dump
file.  It's required.

C<include_regexp> may contain a regular expression defining the
directories and files to include in the walk.  Those that don't match
won't trigger callbacks.  Optional.

=head2 Public Methods

=head3 walk

Start the walker's SVN::Dump loop.  Callbacks will be produced until
an error occurs or the file is completely traversed.

=head2 Callback Methods

=head3 on_walk_begin

An initial callback when walk() has begun.

Called with only one parameter, $self.

=head3 on_walk_done

A final callback when SVN::Dump is done and walk() is about to return.

Called with only one parameter, $self.

=head3 on_revision

Called whenever a new Subversion revision begins.

Called with five parameters: $self, the revision number, its author,
the time the revision was committed ("svn:date" property), and the
corresponding log message ("svn:log" property).

=head3 on_revision_done

Called whenever a Subversion revision has been committed.

Called with two parameters: $self and the revision number.

=head3 on_node_add

Called whenever SVN::Dump encounters an "add" action that is not a
copy.  For adds that are copies, see on_node_copy().

Called with five parameters: $self, the revision number, the path of
the thing being added, the kind of thing being added ("file" or
"dir"), and optionally the contents of the thing being added.

=head3 on_node_change

Called whenever SVN::Dump encounters a "change" action that is not a
copy.  For changes that are copies, see on_node_copy().

Called with five parameters: $self, the revision number, the path of
the thing being changed, the kind of thing being changed ("file" or
"dir"), and optionally the contents of the thing being changed.

=head3 on_node_replace

Called whenever SVN::Dump encounters a "replace" action that is not a
copy.  For replacements that are copies, see on_node_copy().

Called with five parameters: $self, the revision number, the path of
the thing being replaced, the kind of thing being replaced ("file" or
"dir"), and optionally the contents of the thing being replaced.

Subversion determines how "replace" differs from "change".

=head3 on_node_delete

Called whenever SVN::Dump encounters a "delete" action.

Called with three parameters: $self, the revision number, and the path
of the thing being deleted.

=head3 on_node_copy

Called whenever SVN::Dump encounters an action that results from a
copy.  The original actions may be "add", "change" or "replace", but
they're all considered copies if they have 'Node-copyfrom-path'
information.

Called with seven parameters: $self, the revision number, the
destination path, the kind of thing being copied ("file" or "dir"),
the copy source revision, the copy source path, and optionally the
contents of the thing being copied.

=head1 BUGS

on_node_copy() loses some data---whether the copy is the result of an
addition, a change, or a replacement.  This isn't significant for
SVN::Dump::Walker's original purpose, but it could be for someone
else's.  Please submit a bug if your use case requires the additional
information.

=head1 SEE ALSO

L<SVN::Dump> - SVN::Dump::Walker uses SVN::Dump to parse Subversion
dumps.

L<App::SnerpVortex> - SVN::Dump::Walker is used extensively in Snerp
Vortex.

L<SVN::Dump::AuthorExtractor> and L<snauthors> are full versions of
the SYNOPSIS examples.

=head1 AUTHORS AND LICENSE

Snerp Vortex is Copyright 2010 by Rocco Caputo and contributors.

It is released under the same terms as Perl itself.

=cut


