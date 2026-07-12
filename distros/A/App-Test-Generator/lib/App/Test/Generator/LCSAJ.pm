package App::Test::Generator::LCSAJ;

use strict;
use warnings;
use Carp qw(croak);
use File::Basename  qw(basename);
use File::Path qw(make_path);
use File::Spec;
use JSON::MaybeXS;
use PPI;
use Readonly;

# --------------------------------------------------
# Default output directory for LCSAJ JSON files
# --------------------------------------------------
Readonly my $DEFAULT_OUT_DIR => 'lcsaj';

our $VERSION = '0.43';

=head1 NAME

App::Test::Generator::LCSAJ - Static LCSAJ extraction for Perl

=head1 SYNOPSIS

    use App::Test::Generator::LCSAJ;

    my $paths = App::Test::Generator::LCSAJ->generate(
        'lib/MyModule.pm',
        'cover_html/mutation_html/lib',
    );

=head1 DESCRIPTION

Extracts Linear Code Sequence and Jump (LCSAJ) paths from Perl source
files using static analysis via L<PPI>. Each LCSAJ path describes a
linear sequence of statements followed by a jump to another sequence,
forming the basis for TER3 (third-level Test Effectiveness Ratio)
measurement.

The extracted paths are written as JSON to a C<.lcsaj.json> file under
the output directory, where they are consumed by
C<bin/test-generator-index> for dashboard display and TER3
calculation.

=head1 VERSION

Version 0.43

=head2 generate

Extract LCSAJ paths from all subroutines in a Perl source file and
write the results to a JSON file.

    my $paths = App::Test::Generator::LCSAJ->generate(
        'lib/MyModule.pm',
        'cover_html/mutation_html/lib',
    );

    printf "Extracted %d LCSAJ paths\n", scalar @{$paths};

=head3 Arguments

=over 4

=item * C<$file>

Path to the Perl source file to analyse.

=item * C<$out_dir>

Directory under which the C<.lcsaj.json> file will be written.
Optional — defaults to C<lcsaj>.

=back

=head3 Returns

An arrayref of LCSAJ path hashrefs, each with keys C<start>, C<end>,
and C<target> representing the first line, last line, and jump target
line of the path respectively.

=head3 Side effects

Creates C<$out_dir> if it does not exist. Writes a C<.lcsaj.json>
file to C<$out_dir>.

=head3 Notes

Only named subroutines are analysed. Anonymous subs and file-level
code are not included. The control flow graph is built using a
simplified model that treats branching compound statements as
split points — complex nested structures may not be fully represented.

=head3 API specification

=head4 input

    {
        class   => { type => SCALAR },
        file    => { type => SCALAR },
        out_dir => { type => SCALAR, optional => 1 },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => {
            type => HASHREF,
            keys => {
                start  => { type => SCALAR },
                end    => { type => SCALAR },
                target => { type => SCALAR },
            },
        },
    }

=cut

sub generate {
	my ($class, $file, $out_dir) = @_;

	# Apply default output directory if not supplied
	$out_dir //= $DEFAULT_OUT_DIR;

	# Parse the source file — croak early with a clear message
	my $doc = PPI::Document->new($file) or croak "Cannot parse $file";

	# Find all named subroutines in the document
	my $subs = $doc->find('PPI::Statement::Sub') || [];

	my @all_paths;

	for my $sub (@{$subs}) {
		# Build a simplified control flow graph for this sub
		my $blocks = _build_cfg($sub);

		# Convert the CFG to LCSAJ path records
		my $paths  = _cfg_to_lcsaj($blocks);
		push @all_paths, @{$paths};
	}

	# Write all extracted paths to a JSON file in the output directory
	_save_lcsaj($file, $out_dir, \@all_paths);

	return \@all_paths;
}

# --------------------------------------------------
# _build_cfg
#
# Purpose:    Build a simplified control flow graph
#             (CFG) for a single subroutine. Each
#             block in the CFG represents a linear
#             sequence of statements terminated by a
#             branch or the end of the sub.
#
# Entry:      $sub - a PPI::Statement::Sub node.
#
# Exit:       Returns an arrayref of block hashrefs,
#             each with keys id, lines, and edges.
#             Returns an empty arrayref if the sub
#             has no body.
#
# Side effects: None.
#
# Notes:      Only compound statements (if, unless,
#             while, for, foreach) are treated as
#             branch points. Complex nested structures
#             may not be fully represented.
# --------------------------------------------------
sub _build_cfg {
	my $sub = $_[0];

	# Return empty graph if the sub has no body block
	my $block = $sub->block() or return [];

	my @statements = $block->schildren();
	my @blocks;
	my $id = 1;

	# The frontier holds every block currently accumulating statement
	# lines. A branch forks the whole frontier into a true and a false
	# successor — every frontier member gets an edge to both, so
	# subsequent statements (appended to the new frontier) are recorded
	# against both arms, not just the true one. This keeps the false
	# arm of every branch populated with real lines/edges instead of
	# being silently dropped as an empty leaf.
	my $first = _new_block($id);
	push @blocks, $first;
	my @frontier = ($first);

	for my $stmt (@statements) {
		my $line = $stmt->line_number;
		push @{ $_->{lines} }, $line for @frontier;

		# Branch points fork the frontier into true/false successors
		if(_is_branch($stmt)) {
			my $true_block  = _new_block(++$id);
			my $false_block = _new_block(++$id);
			_connect_blocks($_, $true_block)  for @frontier;
			_connect_blocks($_, $false_block) for @frontier;

			push @blocks, $true_block, $false_block;
			@frontier = ($true_block, $false_block);
		}
	}

	return \@blocks;
}

# --------------------------------------------------
# _new_block
#
# Purpose:    Construct a new CFG block hashref with
#             an id, empty lines list, and empty
#             edges list.
#
# Entry:      $id - integer block identifier.
# Exit:       Returns a hashref.
# Side effects: None.
# --------------------------------------------------
sub _new_block {
	my $id = $_[0];

	return { id => $id, lines => [], edges => [] };
}

# --------------------------------------------------
# _connect_blocks
#
# Purpose:    Add a directed edge from one CFG block
#             to another by recording the target
#             block's id in the source block's edges.
#
# Entry:      $from - source block hashref.
#             $to   - target block hashref.
# Exit:       Modifies $from->{edges} in place.
# Side effects: Modifies $from.
# --------------------------------------------------
sub _connect_blocks {
	my ($from, $to) = @_;
	push @{ $from->{edges} }, $to->{id};
}

# --------------------------------------------------
# _is_branch
#
# Purpose:    Return true if a PPI statement node
#             represents a branching control structure
#             that should split the current CFG block.
#
# Entry:      $stmt - a PPI::Statement node.
# Exit:       Returns 1 if the statement is a branch,
#             0 otherwise.
# Side effects: None.
# Notes:      Only compound statement types are
#             considered — simple expressions are not.
# --------------------------------------------------
sub _is_branch {
	my $stmt = $_[0];

	# Only compound statements can be branch points
	return 0 unless $stmt->isa('PPI::Statement::Compound');

	my $type = $stmt->type // '';
	return $type =~ /^(?:if|unless|while|for|foreach)$/ ? 1 : 0;
}

# --------------------------------------------------
# _cfg_to_lcsaj
#
# Purpose:    Convert a CFG block list into a list of
#             LCSAJ path records. Each path represents
#             one linear sequence from a block's first
#             line to its last line, with a jump to
#             the first line of the target block.
#
# Entry:      $blocks - arrayref of CFG block hashrefs
#             as produced by _build_cfg.
#
# Exit:       Returns an arrayref of path hashrefs,
#             each with keys start, end, and target.
#
# Side effects: None.
#
# Notes:      Blocks with no lines (empty blocks) are
#             excluded from the id-to-line mapping and
#             their target lines default to 0.
# --------------------------------------------------
sub _cfg_to_lcsaj {
	my $blocks = $_[0];

	# Build a lookup from block id to its first line number
	my %id2line = map { $_->{id} => $_->{lines}[0] }
		grep { @{ $_->{lines} } } @{$blocks};

	my @paths;

	for my $b (@{$blocks}) {
		next unless @{ $b->{edges} };	# Skip blocks with no outgoing edges — they are leaf nodes
		next unless @{ $b->{lines} };   # skip empty blocks — avoids null-bounds paths

		my $start = $b->{lines}[0];
		my $end   = $b->{lines}[-1];

		# Emit one path record per outgoing edge
		for my $target_id (@{ $b->{edges} }) {
			push @paths, {
				start  => $start,
				end    => $end,
				target => $id2line{$target_id} // 0,
			};
		}
	}

	return \@paths;
}

# --------------------------------------------------
# _save_lcsaj
#
# Purpose:    Serialise LCSAJ path records to a JSON
#             file in the output directory. The
#             filename is derived from the source
#             file's basename.
#
# Entry:      $file  - path to the source .pm file.
#             $dir   - output directory path.
#             $paths - arrayref of path hashrefs.
#
# Exit:       Returns nothing. Writes a .lcsaj.json
#             file to $dir.
#
# Side effects: Creates $dir if it does not exist.
#               Writes a file to $dir.
#
# Notes:      Uses File::Basename::basename for
#             portability across operating systems.
# --------------------------------------------------
sub _save_lcsaj {
	my ($file, $dir, $paths) = @_;

	# Derive the module-relative path (strip leading .../lib/ prefix)
	my $rel = $file;

	# Strip leading path up to and including 'lib/' — handles both
	# absolute paths (/home/runner/.../lib/App/...) and relative (lib/App/...)
	# Handle both Unix / and Windows \ separators
	$rel =~ s{^(?:.*[/\\])?lib[/\\]}{};

	# If $file had no 'lib/' segment (e.g. a File::Temp tempfile), the
	# substitution above is a no-op and $rel is still $file's full
	# absolute path. Joining that onto $dir below would embed a second
	# absolute path — and, on Windows, a second drive letter — inside
	# the constructed directory name, which File::Path::make_path
	# rejects outright ("Invalid argument"). Fall back to the basename.
	$rel = basename($rel) if File::Spec->file_name_is_absolute($rel);

	my $base = basename($rel);

	# Mirror the directory structure expected by _lcsaj_coverage_for_file:
	# $dir / $rel.lcsaj / $base.lcsaj.json
	my $subdir  = File::Spec->catfile($dir, "$rel.lcsaj");

	# Create the output directory if it does not exist
	make_path($subdir) unless -d $subdir;
	my $out = File::Spec->catfile($subdir, "$base.lcsaj.json");

	# Remove degenerate paths (null bounds) and exact duplicates
	# before serialising — guards against empty CFG blocks producing
	# null start/end values, and branch splits creating identical records
	my %seen;
	my @clean = grep {
		defined $_->{start} && defined $_->{end}
		&& !$seen{"$_->{start}:$_->{end}:$_->{target}"}++
	} @{$paths};

	open my $fh, '>', $out or croak "Cannot write LCSAJ output to $out: $!";
	print $fh encode_json(\@clean);
	close $fh;
}

1;
