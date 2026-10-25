package App::FileSync::Verify;

# Compare a tree with the record of what it should hold (the server index, or
# the client's cached base) and report the differences.  Read-only.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Spec;
use List::Util 1.54 qw(sample);
use Sub::Private { mode => 'enforce' };

use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($TYPE_FILE $TYPE_DIR);
use App::FileSync::I18N qw(message throw);
use App::FileSync::IO qw(sha256_file);
use App::FileSync::Scan;

use version; our $VERSION = version->declare('0.001.2');

# The type of a manifest entry; older entries without "t" are files.  Lexical
# because it runs several times per path.
my $type_of = sub {
	my ($entry) = @_;
	return (ref($entry) eq 'HASH' && defined $entry->{t}) ? $entry->{t} : $TYPE_FILE;
};

=encoding utf8

=head1 NAME

App::FileSync::Verify - check a tree against its recorded manifest

=head1 SYNOPSIS

	my $report = App::FileSync::Verify::verify(
		root => $master, entries => $index, ignore => $ignore, sample => 50,
	);
	print $report->{ok} ? "clean\n" : "drift\n";

=head1 FUNCTIONS

=head2 verify

Purpose: report where a tree no longer matches its record.

Args: C<root> (required, a directory), C<entries> (the recorded manifest),
C<ignore> (an L<App::FileSync::Ignore>), C<deep> (rehash every file),
C<sample> (without C<deep>, rehash this many unchanged-looking files chosen at
random).

Without C<deep>, entries whose size and mtime still match are trusted, which
is what makes a verify of a large tree cheap.

Returns: a hashref:

	root, ok (1 when nothing differs), deep, files (regular files found),
	known (entries in the record), rehashed, trusted, sampled,
	modified => [ { p, expected, got } | { p, reason } | { p, expected, got, sampled } ],
	missing  => [ { p, t } ],
	extra    => [ { p, t } ]

Each list is sorted by path.

Side Effects: reads files; never writes.

Usage:

	my $report = App::FileSync::Verify::verify(root => $root, entries => $base, deep => 1);

=head3 EXAMPLE

	my $report = App::FileSync::Verify::verify(root => '/srv/filesync/master/docs', entries => $index);
	print "missing: $_->{p}\n" for @{ $report->{missing} };

=head3 API SPECIFICATION

=head4 INPUT

	{
		root    => { type => 'string', min => 1 },
		entries => { type => 'hashref', optional => 1 },
		ignore  => { type => 'object', optional => 1 },
		deep    => { type => 'boolean', optional => 1 },
		sample  => { type => 'integer', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			ok       => { type => 'integer', min => 0, max => 1 },
			modified => { type => 'arrayref' },
			missing  => { type => 'arrayref' },
			extra    => { type => 'arrayref' },
		},
	}

=head3 MESSAGES

	Key                    Meaning                        Resolution
	verify.no_root         root is not a directory        check the path
	verify.type_changed    (a reason in "modified")       a file became a directory or back

=head3 FORMAL SPECIFICATION

	let M = scan(root).manifest ; E = entries
	missing  = { p ∈ dom E | p ∉ dom M ∧ ¬(E(p).t = d ∧ isdir(root/p)) }
	modified = { p ∈ dom E ∩ dom M | E(p).t ≠ M(p).t ∨ (E(p).t = f ∧ E(p).h ≠ M(p).h) }
	extra    = dom M \ dom E \ (missing ∪ modified)
	ok ⇔ missing = modified = extra = ∅

=head3 PSEUDOCODE

	scan the tree, reusing recorded hashes unless deep
	for each recorded path: missing, type changed, or hash differs
	every scanned path not recorded is extra
	if sampling: rehash that many trusted files and add any that differ
	sort the three lists and count

=cut

sub verify {
	my $args = named(\@_, {
		root    => { type => 'string', min => 1 },
		entries => { type => 'hashref', optional => 1 },
		ignore  => { type => 'object', optional => 1 },
		deep    => { type => 'boolean', optional => 1 },
		sample  => { type => 'integer', min => 0, optional => 1 },
	}, 'Verify::verify');

	my $root = $args->{root};
	throw('verify.no_root', { root => $root }) unless -d $root;

	my $entries = $args->{entries} || {};
	my $deep    = $args->{deep} ? 1 : 0;

	my $scan = App::FileSync::Scan::scan(
		root   => $root,
		ignore => $args->{ignore},
		cache  => $deep ? {} : $entries,
	);
	my $manifest = $scan->{manifest};

	my $found = _compare($root, $entries, $manifest);
	my $sampled = ($deep || !$args->{sample})
		? 0
		: _sample_check($root, $entries, $manifest, $args->{sample}, $found);

	my %sorted = map {
		my $list = $found->{$_};
		$_ => [ sort { $a->{p} cmp $b->{p} } @{$list} ];
	} qw(modified missing extra);

	return {
		root     => $root,
		ok       => (@{ $sorted{modified} } || @{ $sorted{missing} } || @{ $sorted{extra} }) ? 0 : 1,
		deep     => $deep,
		files    => scalar(grep { $type_of->($manifest->{$_}) eq $TYPE_FILE } keys %{$manifest}),
		known    => scalar(keys %{$entries}),
		rehashed => $scan->{stats}{hashed} + $sampled,
		trusted  => $scan->{stats}{cached},
		sampled  => $sampled,
		%sorted,
	};
}

# _compare
# Purpose:     compare the record with what the scan found.
# Entry:       $entries is the record; $manifest the fresh scan.
# Exit:        returns { modified, missing, extra, seen } (lists unsorted;
#              seen is the set of paths already reported).
# Side effects: none; stats one directory per recorded empty dir that is gone
#              from the manifest.
sub _compare :Private {
	my ($root, $entries, $manifest) = @_;

	my (%found, %seen);
	@found{qw(modified missing extra)} = ([], [], []);

	for my $path (sort keys %{$entries}) {
		my $entry = $entries->{$path};
		next unless ref($entry) eq 'HASH';

		my $type = $type_of->($entry);
		my $have = $manifest->{$path};
		my $problem;

		if (!$have) {
			# The scanner only reports directories that are empty, so an empty
			# directory that has since gained a file is not missing.
			next if $type eq $TYPE_DIR && -d File::Spec->catfile($root, split m{/}, $path);
			push @{ $found{missing} }, { p => $path, t => $type };
		} elsif ($type ne $type_of->($have)) {
			push @{ $found{modified} }, { p => $path, reason => message('verify.type_changed') };
		} elsif ($type eq $TYPE_FILE && defined $entry->{h} && defined $have->{h} && $entry->{h} ne $have->{h}) {
			push @{ $found{modified} }, { p => $path, expected => $entry->{h}, got => $have->{h} };
		} else {
			next;
		}
		$seen{$path} = 1;
	}

	for my $path (sort keys %{$manifest}) {
		next if $entries->{$path} || $seen{$path};
		push @{ $found{extra} }, { p => $path, t => $type_of->($manifest->{$path}) };
	}

	$found{seen} = \%seen;
	return \%found;
}

# _sample_check
# Purpose:     rehash a random sample of files the scan trusted.
# Entry:       $wanted > 0; $found is _compare's result, updated in place.
# Exit:        returns how many files were rehashed.
# Side effects: reads the sampled files; appends to $found->{modified}.
sub _sample_check :Private {
	my ($root, $entries, $manifest, $wanted, $found) = @_;

	# Only a file on both sides can be compared by content.
	my @candidates = grep {
		ref($entries->{$_}) eq 'HASH'
			&& $type_of->($entries->{$_}) eq $TYPE_FILE
			&& $manifest->{$_}
			&& $type_of->($manifest->{$_}) eq $TYPE_FILE
	} sort keys %{$entries};

	my $sampled = 0;
	for my $path (sample($wanted, @candidates)) {
		my $got = sha256_file(File::Spec->catfile($root, split m{/}, $path));
		next unless defined $got;
		$sampled++;

		my $expected = $entries->{$path}{h};
		next if !defined $expected || $got eq $expected || $found->{seen}{$path};

		push @{ $found->{modified} }, { p => $path, expected => $expected, got => $got, sampled => 1 };
		$found->{seen}{$path} = 1;
	}

	return $sampled;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * A shallow verify trusts size and mtime, so it cannot see a change that
kept both; use C<deep> or C<sample> for that.

=item * The report says what differs, not which side is right.  After a
restore from backup the index, not the tree, is usually the stale one; see
C<filesync-admin reindex>.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
