package App::FileSync::Ignore;

# .gitignore-style exclusion patterns, compiled once per session and matched
# against every path in the tree.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Readonly;
use Sub::Private { mode => 'enforce' };

use App::FileSync::Args qw(named);

use version; our $VERSION = version->declare('0.001.5');

# A line that is blank or a comment ("# note", or a lone "#").  "#*#" is a
# pattern (Emacs autosave files), as .gitignore allows with a backslash.
Readonly my $COMMENT => qr/\A\s*(?:#\s|#\z|\z)/;

=encoding utf8

=head1 NAME

App::FileSync::Ignore - .gitignore-style path exclusion

=head1 SYNOPSIS

	my $ignore = App::FileSync::Ignore->new(patterns => [ '*.tmp', '!keep.tmp', 'build/' ]);
	print "skip\n" if $ignore->match('src/a.tmp');

=head1 DESCRIPTION

Patterns follow .gitignore: C<*> matches within one component, C<**/>
matches any number of directories, C<?> one character, a leading C<!>
re-includes, a leading C</> anchors at the root, and a pattern without a slash
matches at any depth.  Later patterns win.  A path inside an ignored directory
is ignored.

=head1 METHODS

=head2 new

Purpose: compile a list of patterns.

Args: C<patterns> (arrayref of strings; undefined entries, blanks and comments
are skipped), C<case_insensitive> (boolean).

Returns: an C<App::FileSync::Ignore> object.

Side Effects: none.  The caller's list is not modified.

Usage:

	my $ignore = App::FileSync::Ignore->new(patterns => $config->{ignore});

=head3 EXAMPLE

	my $ignore = App::FileSync::Ignore->new(
		patterns         => [ '*.bak', '# editor files', '*~' ],
		case_insensitive => 1,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		patterns         => { type => 'arrayref', optional => 1 },
		case_insensitive => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Ignore' }

=head3 MESSAGES

	Key            Meaning                     Resolution
	args.invalid   patterns is not a list      pass an arrayref

=head3 FORMAL SPECIFICATION

	new(ps, ci) = ⟨compiled ↦ ⟨(neg(p), re(p, ci)) | p ← ps, ¬ comment(p)⟩⟩
	ps' = ps

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		patterns         => { type => 'arrayref', optional => 1 },
		case_insensitive => { type => 'boolean', optional => 1 },
	}, 'Ignore->new');

	my @compiled;
	for my $given (@{ $args->{patterns} || [] }) {
		next unless defined $given;
		next if $given =~ $COMMENT;

		# Work on a copy: the list usually belongs to the repo config, which
		# the server sends on to the client after building this object.
		my $raw = $given;
		my $negated = $raw =~ s/\A!// ? 1 : 0;
		$raw =~ s/\A\s+//;
		$raw =~ s/\s+\z//;
		next unless length $raw;

		my $re = _glob_to_re($raw);
		push @compiled, {
			negated => $negated,
			re      => $args->{case_insensitive} ? qr/\A$re\z/i : qr/\A$re\z/,
		};
	}

	return bless { compiled => \@compiled }, $class;
}

=head2 match

Purpose: decide whether a path is excluded.

Args: C<$path>, relative and C</>-separated.

Returns: 1 when the path, or any directory above it, is ignored; otherwise 0.

Side Effects: none.

Usage:

	next if $ignore->match($relative_path);

=head3 EXAMPLE

	my $ignore = App::FileSync::Ignore->new(patterns => [ 'build' ]);
	print $ignore->match('build/out/a.o'), "\n";	# 1

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self', type => 'object' },
		{ name => 'path', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 1 }

=head3 MESSAGES

None.  Called once per path, so arguments are checked by hand.

=head3 FORMAL SPECIFICATION

	ignored(c) ⇔ last ⟨ ¬neg(p) | p ← compiled, c ∈ re(p) ⟩ = true
	match(path) ⇔ ∃ a : {path} ∪ ancestors(path) • ignored(a)

=head3 PSEUDOCODE

	candidates := path, then each directory above it
	for each candidate:
		state := not ignored
		for each pattern in order: if it matches, state := not negated
		if state is ignored: return 1
	return 0

=cut

sub match {
	my ($self, $path) = @_;

	return 0 unless defined $path && length $path;

	# A path inside an ignored directory is ignored too, even if the caller
	# only asks about the file (the scanner prunes at the directory, but this
	# keeps the answer correct for every caller).
	my @candidates = ($path);
	my $prefix = $path;
	push @candidates, $prefix while $prefix =~ s{/[^/]+\z}{};

	for my $candidate (@candidates) {
		my $ignored = 0;
		for my $pattern (@{ $self->{compiled} }) {
			$ignored = $pattern->{negated} ? 0 : 1 if $candidate =~ $pattern->{re};
		}
		return 1 if $ignored;
	}

	return 0;
}

# _glob_to_re
# Purpose:     translate one .gitignore-style glob into a regex body.
# Entry:       $pattern has had its "!" and surrounding blanks removed.
# Exit:        returns the regex source (not anchored; new() anchors it).
# Side effects: none.  Hand-written rather than Text::Glob, which has no
#              "**" and no "slash-less pattern matches at any depth" rule.
sub _glob_to_re :Private {
	my ($pattern) = @_;

	# A leading slash anchors; a trailing one (.gitignore's directory marker)
	# does not, so "build/" matches "build" at any depth as git users expect.
	$pattern =~ s{/\z}{};
	my $anchored = $pattern =~ s{\A/}{} ? 1 : 0;
	my $has_slash = $pattern =~ m{/} ? 1 : 0;

	# Translate token by token: "**/" any directories, "**" anything, "*"
	# within a component, "?" one character, everything else literally.
	my $re = '';
	while (length $pattern) {
		if ($pattern =~ s{\A\*\*/}{}) {
			$re .= '(?:.*/)?';
		} elsif ($pattern =~ s{\A\*\*}{}) {
			$re .= '.*';
		} elsif ($pattern =~ s{\A\*}{}) {
			$re .= '[^/]*';
		} elsif ($pattern =~ s{\A\?}{}) {
			$re .= '[^/]';
		} else {
			$re .= quotemeta(substr($pattern, 0, 1, ''));
		}
	}

	# A pattern without a slash matches any path segment, like .gitignore.
	return ($anchored || $has_slash) ? $re : "(?:.*/)?$re";
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Character classes (C<[abc]>) and backslash escapes are taken
literally.  A trailing C</> is dropped, so C<build/> matches C<build> at any depth;
as C<match> has no type information it matches a file of that name too.

=item * Matching is per path and linear in the number of patterns.  Combining
them into one alternation would be faster but would lose "later patterns win".

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
