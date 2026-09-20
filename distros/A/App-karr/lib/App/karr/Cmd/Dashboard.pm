# ABSTRACT: Multi-board overview of every karr board under a directory tree

package App::karr::Cmd::Dashboard;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr dashboard [PATH] [--depth N] [--hide-no-board] [--show-no-board] [--json] [--compact]',
);
use Path::Tiny ();
use Term::ANSIColor qw( colored );
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Role::Color;

# Board-less on purpose (ticket #220): this walks a directory tree for
# repositories and opens each board directly through App::karr::Git /
# App::karr::BoardStore, the way App::karr::Foundation/_is_karr_board_root
# does. It composes neither App::karr::Role::BoardDiscovery nor
# App::karr::Role::BoardAccess -- there is no single board to discover here,
# and no --dir either: the positional PATH below already names the search
# root, and a second option with an unrelated meaning would only confuse.
# _reject_root_dir in execute() is what makes that decision hold for the root
# placement as well (#225); without it the option was accepted there and
# silently dropped.
with 'App::karr::Role::CliArgs', 'App::karr::Role::ExitCodes',
     'App::karr::Role::Output', 'App::karr::Role::CompactOutput',
     'App::karr::Role::Color';


option depth => (
  is      => 'ro',
  format  => 'i',
  default => sub { 4 },
  doc     => 'Maximum recursion depth below PATH (default 4)',
);

option hide_no_board => (
  is  => 'ro',
  doc => 'Hide the summarized list of repositories with no karr board',
);

option show_no_board => (
  is  => 'ro',
  doc => 'Always list the board-less repositories by name, wrapped over several lines',
);

# Same status -> colour mapping App::karr::Cmd::Board uses (see its own
# comment there): the same status must not look different between the two
# commands of this one distribution.
my %STATUS_COLOR = (
  backlog       => 'bright_black',
  todo          => 'cyan',
  'in-progress' => 'yellow',
  review        => 'magenta',
  done          => 'green',
  archived      => 'bright_black',
);

# Decision (documented on ticket #220, karr edit 220 -a "..."): blocked cards
# are pulled out of their status colour into their own trailing bar segment,
# always bold red -- the same colour App::karr::Cmd::Board uses for
# `blocked:reason` -- so a blocked card reads as blocked at a glance instead
# of disappearing into whichever status colour it happened to be sitting in.
use constant BLOCKED_COLOR => 'bold red';

# One block character per (unscaled) open task. Decision: capped at 10 blocks
# per bar (see _scale_segments) so a busy board's entry stays short enough for
# several columns to fit side by side at an ordinary 80-column terminal --
# the whole point of "mehrspaltig" being multiple repos per screen row, not
# one very wide repo taking the row on its own.
use constant BLOCK_CHAR      => "\x{2588}";
use constant MAX_BAR_BLOCKS  => 10;
use constant COLUMN_GAP      => 2;

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->_reject_root_dir($chain_ref);
  $self->check_positional_args($args_ref, 1);
  my ($pos) = $self->positional_args($args_ref);

  $self->usage_error( sprintf '--depth must be 0 or greater (got %d)', $self->depth )
    if $self->depth < 0;

  my $start = Path::Tiny::path( defined $pos ? $pos : '.' )->absolute;
  $self->usage_error("not a directory: $start") unless $start->is_dir;

  my @repo_dirs = sort { "$a" cmp "$b" } $self->_find_repos( $start, $self->depth );

  my ( @boards, @no_board );
  for my $dir (@repo_dirs) {
    my $info = $self->_probe_repo($dir);
    if ($info) { push @boards, $info }
    else       { push @no_board, $dir }
  }
  @boards = sort { $a->{name} cmp $b->{name} || "$a->{dir}" cmp "$b->{dir}" } @boards;

  my $total_open = 0;
  $total_open += $_->{open} for @boards;

  if ( $self->json ) {
    my %doc = (
      root    => "$start",
      summary => {
        repos => scalar(@repo_dirs),
        boards => scalar(@boards),
        open   => $total_open,
      },
      boards => [
        map {
          my $b = $_;
          +{
            path       => "$b->{dir}",
            name       => $b->{name},
            board_name => $b->{board_name},
            open       => $b->{open},
            blocked    => $b->{blocked},
            # Named $status, not $_: this is a map nested inside the outer
            # one, and reusing $_ here would shadow $b's own $_ alias with
            # the status name, breaking $b->{counts}{$_} silently.
            statuses => { map { my $status = $_; ( $status => $b->{counts}{$status} // 0 ) } @{ $b->{order} } },
          }
        } @boards
      ],
      ( $self->hide_no_board ? () : ( no_board => [ map { "$_" } @no_board ] ) ),
    );
    $self->print_json( \%doc );
    return;
  }

  if ( $self->compact ) {
    for my $b (@boards) {
      my @tokens = map { "$_:" . ( $b->{counts}{$_} // 0 ) } @{ $b->{order} };
      push @tokens, 'blocked:' . $b->{blocked};
      printf "%s\t%s\n", $b->{name}, join( ',', @tokens );
    }
    unless ( $self->hide_no_board ) {
      printf "%s\tno-board\n", $_->basename for @no_board;
    }
    return;
  }

  my $color = $self->_want_color;
  my $c = sub {
    my ( $text, $spec ) = @_;
    return $color ? colored( $text, $spec ) : $text;
  };

  # Every line printed below is fitted to this one width. Nothing may exceed
  # it: a line that is one character too long soft-wraps in the terminal, and
  # a soft-wrapped grid row destroys the column alignment this command exists
  # for -- worse than a plain one-column list would have been.
  my $width = $self->_term_width;

  print $c->( $self->_truncate( "Dashboard: $start", $width ), 'bold cyan' ), "\n\n";

  if (@boards) {
    my $name_width = 0;
    $name_width = length( $_->{name} ) > $name_width ? length( $_->{name} ) : $name_width
      for @boards;

    # The count column is the only other variable-width part; measure it so
    # the name cap below is exact rather than guessed.
    my $count_w = 0;
    for my $b (@boards) {
      my $l = length( '(' . $b->{open} . ')' );
      $count_w = $l if $l > $count_w;
    }

    # A cell is name + 2 spaces + bar + 1 space + count. On a terminal too
    # narrow to hold even one whole cell the grid falls back to a single
    # column, and a single column cannot shrink below its own content -- so
    # the content itself has to shrink. Names are capped first (they are the
    # only unbounded part), then the bar, so both stay inside $width. At any
    # ordinary width neither cap is reached and nothing is truncated.
    my $name_cap = $width - 3 - MAX_BAR_BLOCKS - $count_w;
    $name_cap = 4 if $name_cap < 4;
    $name_width = $name_cap if $name_width > $name_cap;

    my $bar_max = $width - $name_width - 3 - $count_w;
    $bar_max = 1 if $bar_max < 1;
    $bar_max = MAX_BAR_BLOCKS if $bar_max > MAX_BAR_BLOCKS;

    my @cells = map { $self->_entry_for_board( $_, $name_width, $bar_max, $c ) } @boards;
    print $self->_render_grid( \@cells, $width );
  }
  else {
    print $c->( '(no boards found)', 'bright_black' ), "\n";
  }

  # The board-less repositories are a footnote, and on a big tree there are
  # more of them than boards (46 of 91 under one real /home/getty/dev scan).
  # Joined into one line that was 837 characters -- seven soft-wrapped
  # terminal lines that buried the summary underneath them. Three cases now:
  # it fits on one line, or --show-no-board wraps it properly, or it collapses
  # to a count that says how to see the names.
  unless ( $self->hide_no_board || !@no_board ) {
    my @names = map { $_->basename } @no_board;
    my $one_line = 'No board: ' . join( ', ', @names );
    print "\n";
    if ( length($one_line) <= $width ) {
      print $c->( $one_line, 'bright_black' ), "\n";
    }
    elsif ( $self->show_no_board ) {
      print $c->( $_, 'bright_black' ), "\n"
        for $self->_wrap_items( 'No board: ', \@names, $width, 10 );
    }
    else {
      # The hint is worth a line only while it fits beside the count; on a
      # narrow terminal the count alone is what survives.
      my $hint  = sprintf( 'No board: %d repos (--show-no-board to list them)', scalar @names );
      my $short = sprintf( 'No board: %d repos',                                scalar @names );
      $hint = $short if length($hint) > $width;
      print $c->( $self->_truncate( $hint, $width ), 'bright_black' ), "\n";
    }
  }

  print "\n", $c->(
    $self->_truncate(
      sprintf( '%d repos  %d boards  %d open', scalar(@repo_dirs), scalar(@boards), $total_open ),
      $width ),
    'bold'
  ), "\n";
}

# `karr dashboard --dir PATH` was always rejected by MooX::Options (this
# command declares no such option) -- but `karr --dir PATH dashboard` was not:
# --dir is declared on App::karr::Role::BoardDiscovery, the root command
# composes it via BoardAccess, and MooX::Cmd leaves the parsed value on the
# root instance in the command chain, where nothing here ever looked. So the
# option was swallowed without a word and the scan ran on the current
# directory instead -- and a list of repositories with counts behind them
# looks like a valid answer no matter which tree it came from (#225).
#
# It is refused rather than adopted because the two paths are not the same
# path: --dir seeds a walk UPWARD to one repository's root
# (App::karr::Role::BoardDiscovery/_build_git_root, which is why it may name
# any directory inside the target repository), while the positional PATH here
# is the root of a walk DOWNWARD across a tree of repositories (_find_repos,
# bounded by --depth, never entering a repository's own work tree). Handed the
# same argument, the two would answer about different directories.
#
# The root is read from $chain_ref the way App::karr::Cmd::GetRefs reads it
# for the opposite purpose; a directly constructed instance (no MooX::Cmd
# dispatch, hence an empty chain) has no root option to reject.
sub _reject_root_dir {
  my ($self, $chain_ref) = @_;
  return unless $chain_ref && @$chain_ref;
  my $root = $chain_ref->[0];
  return unless $root && $root->can('has_dir') && $root->has_dir;
  # Wrapped to stay inside 80 columns with usage_error's own "Usage error: "
  # prefix on the first line: what to type comes first, the reason after it.
  $self->usage_error(
      "dashboard does not take --dir; its scan root is an argument:\n"
    . "karr dashboard PATH\n"
    . "(--dir seeds the search upward for one repository's board, while dashboard\n"
    . "searches downward for every board under a directory.)"
  );
}

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

# Iterative (not recursive) so a very deep or wide tree cannot blow the Perl
# call stack; order within a directory is irrelevant to the caller, which
# sorts the whole result afterwards.
sub _find_repos {
  my ( $self, $start, $max_depth ) = @_;
  my @found;
  my @stack = ( [ $start, 0 ] );

  while (@stack) {
    my ( $dir, $depth ) = @{ shift @stack };

    if ( $dir->child('.git')->exists ) {
      push @found, $dir;
      next;    # never search inside a repository's own working tree
    }
    next if $depth >= $max_depth;

    my @children = eval { grep { $_->is_dir } $dir->children };
    next unless @children;    # unreadable directory: skip, do not abort

    for my $child ( sort { "$a" cmp "$b" } @children ) {
      next if -l $child;      # never follow a symlinked directory (loops)
      push @stack, [ $child, $depth + 1 ];
    }
  }
  return @found;
}

# undef when $dir is not a Git repository at all, or holds none of
# refs/karr/*; a probing failure (a corrupt repository, an unreadable ref) is
# treated the same as "no board" rather than aborting the whole dashboard --
# App::karr::Foundation's own per-repo processing follows the same rule, see
# its "one broken board cannot stop the rest of the run". The actual work is
# in _probe_repo_or_die below, called through eval here rather than inline --
# a bare `return` inside `eval BLOCK` returns from the enclosing sub, not the
# eval, so the early `return undef`s that method needs would otherwise skip
# this catch entirely; a real named sub has no such surprise.
sub _probe_repo {
  my ( $self, $dir ) = @_;
  my $info = eval { $self->_probe_repo_or_die($dir) };
  if ($@) {
    print STDERR "karr dashboard: skipping $dir: $@";
    return undef;
  }
  return $info;
}

sub _probe_repo_or_die {
  my ( $self, $dir ) = @_;

  my $git = App::karr::Git->new( dir => "$dir" );
  return undef unless $git->is_repo;
  return undef unless $git->ref_exists('refs/karr/config');

  my $store = App::karr::BoardStore->new( git => $git );
  my $ec    = $store->effective_config;
  my @order = grep { !$store->is_terminal_status($_) } $store->all_status_names;
  my %in_order = map { $_ => 1 } @order;

  my %counts;
  my $blocked = 0;
  for my $t ( $store->load_tasks ) {
    next unless $in_order{ $t->status };
    if ( $t->has_blocked ) { $blocked++ }
    else                   { $counts{ $t->status }++ }
  }
  my $open = $blocked;
  $open += ( $counts{$_} // 0 ) for @order;

  return {
    dir        => $dir,
    name       => $dir->basename,
    board_name => $ec->{board}{name} // 'Kanban Board',
    order      => \@order,
    counts     => \%counts,
    blocked    => $blocked,
    open       => $open,
  };
}

# ---------------------------------------------------------------------------
# Bar rendering
# ---------------------------------------------------------------------------

# [ [ label, count, color ], ... ] for one board -- every non-terminal status
# with at least one open task, in the board's own status order, plus a
# trailing synthetic 'blocked' segment (see BLOCKED_COLOR above).
sub _bar_segments {
  my ( $self, $info ) = @_;
  my @segments;
  for my $status ( @{ $info->{order} } ) {
    my $n = $info->{counts}{$status} // 0;
    push @segments, [ $status, $n, $STATUS_COLOR{$status} // 'white' ] if $n;
  }
  push @segments, [ 'blocked', $info->{blocked}, BLOCKED_COLOR ] if $info->{blocked};
  return @segments;
}

# Scales @segments down to sum to at most $max blocks (largest-remainder /
# Hamilton apportionment), unscaled when they already fit. A nonzero
# 'blocked' segment is never rounded away to zero -- see BLOCKED_COLOR above
# for why that one category specifically must stay visible; every other
# segment is allowed to round down to nothing under heavy compression, which
# only loses precision the exact counts ( --json / --compact / the "N open"
# summary) still carry.
sub _scale_segments {
  my ( $self, $max, @segments ) = @_;
  my $total = 0;
  $total += $_->[1] for @segments;
  return @segments if $total <= $max;

  my @work;
  my $allocated = 0;
  for my $seg (@segments) {
    my $share = $seg->[1] * $max / $total;
    my $floor = int $share;
    push @work, { seg => $seg, blocks => $floor, remainder => $share - $floor };
    $allocated += $floor;
  }
  my $left = $max - $allocated;
  for my $w ( sort { $b->{remainder} <=> $a->{remainder} } @work ) {
    last unless $left > 0;
    $w->{blocks}++;
    $left--;
  }
  for my $w (@work) {
    next unless $w->{seg}[0] eq 'blocked';
    next if $w->{blocks} > 0 || $w->{seg}[1] == 0;
    my ($donor) = sort { $b->{blocks} <=> $a->{blocks} } grep { $_->{blocks} > 0 } @work;
    # $donor is always found here: $max blocks were allocated somewhere among
    # @work, and this branch only runs when blocked's own share is 0 of them,
    # so at least one other segment holds the rest. The guard is defensive.
    next unless $donor;
    $donor->{blocks}--;
    $w->{blocks}++;
  }
  return map { [ $_->{seg}[0], $_->{blocks}, $_->{seg}[2] ] } @work;
}

# One grid cell for a board: { width => visible character width, text => the
# (possibly coloured) string to print }. Names are left-padded to
# $name_width -- the longest name across the whole grid -- so every bar in
# every column starts at the same horizontal offset (a cheap readability win
# over plain per-cell width alignment, which only aligns whole entries).
sub _entry_for_board {
  my ( $self, $info, $name_width, $bar_max, $c ) = @_;

  my @segments = $self->_scale_segments( $bar_max, $self->_bar_segments($info) );

  my $bar_plain   = '';
  my $bar_colored = '';
  for my $seg (@segments) {
    my ( undef, $n, $color ) = @$seg;
    next unless $n;
    my $blocks = BLOCK_CHAR x $n;
    $bar_plain   .= $blocks;
    $bar_colored .= $c->( $blocks, $color );
  }

  my $name = $self->_truncate( $info->{name}, $name_width );
  my $name_padded = $name . ( ' ' x ( $name_width - length $name ) );
  my $count_str   = '(' . $info->{open} . ')';

  my $plain = $name_padded . '  ' . $bar_plain . ' ' . $count_str;
  my $text  = $name_padded . '  ' . $bar_colored . ' ' . $c->( $count_str, 'bright_black' );

  return { width => length($plain), text => $text };
}

# ---------------------------------------------------------------------------
# Grid layout
# ---------------------------------------------------------------------------

# ls -C style: one shared cell width (the widest entry) across the whole
# grid, as many columns as fit the terminal width, filled left to right, top
# to bottom (reading order) rather than ls's own top-to-bottom-then-across --
# a dashboard is read start to finish, not scanned by column.
sub _render_grid {
  my ( $self, $cells, $width ) = @_;
  return '' unless @$cells;

  my $cell_w = 0;
  $cell_w = $_->{width} > $cell_w ? $_->{width} : $cell_w for @$cells;

  my $ncols = int( ( $width + COLUMN_GAP ) / ( $cell_w + COLUMN_GAP ) );
  $ncols = 1 if $ncols < 1;

  my $out = '';
  my $i   = 0;
  for my $cell (@$cells) {
    $i++;
    if ( $i % $ncols == 0 || $i == @$cells ) {
      $out .= $cell->{text} . "\n";
    }
    else {
      $out .= $cell->{text} . ( ' ' x ( $cell_w - $cell->{width} ) ) . ( ' ' x COLUMN_GAP );
    }
  }
  return $out;
}

# Cuts $text down to at most $max visible characters, marking a cut with a
# trailing '..' so a truncated name never reads as a real (shorter) name.
# Only ever reached on a terminal too narrow to hold the untruncated content;
# at any ordinary width this returns $text unchanged.
sub _truncate {
  my ( $self, $text, $max ) = @_;
  return $text if length($text) <= $max;
  return substr( $text, 0, $max ) if $max <= 2;
  return substr( $text, 0, $max - 2 ) . '..';
}

# Wraps a comma-separated list to $width, indenting every continuation line by
# $indent so the items stay visually grouped under their prefix. Returns the
# lines without newlines. A single item longer than the available room is
# truncated rather than allowed to overhang -- the whole point here is that no
# produced line is ever wider than $width.
sub _wrap_items {
  my ( $self, $prefix, $items, $width, $indent ) = @_;
  my $pad  = ' ' x $indent;
  my $lead = length($prefix) > $indent ? length($prefix) : $indent;
  my $room = $width - $lead;
  $room = 1 if $room < 1;

  my @lines;
  my $cur   = $prefix;
  my $empty = 1;    # current line carries no item yet
  for my $i ( 0 .. $#$items ) {
    # Truncate the item AND its separator together: cutting the name to
    # $room and then appending the comma is one character too many, which is
    # exactly the kind of off-by-one that soft-wraps a line in the terminal.
    my $tok = $self->_truncate( $items->[$i] . ( $i < $#$items ? ',' : '' ), $room );
    my $add = $empty ? $tok : ' ' . $tok;
    if ( !$empty && length($cur) + length($add) > $width ) {
      push @lines, $cur;
      $cur = $pad . $tok;
    }
    else {
      $cur .= $add;
    }
    $empty = 0;
  }
  push @lines, $cur unless $empty;
  return @lines;
}

# Terminal width in columns. Checked ahead of any tty test -- COLUMNS lets a
# script or a piped capture (e.g. inside tmux) control the layout without a
# real pty, which also makes this deterministic to test. Falls back to `tput
# cols` (near-universal on the Unix systems karr already targets via
# libgit2/Git::Native) and then to 80, same fallback App::karr::Cmd::Board's
# neighbours use for "not determinable".
sub _term_width {
  my ($self) = @_;
  if ( defined $ENV{COLUMNS} && $ENV{COLUMNS} =~ /\A[0-9]+\z/ && $ENV{COLUMNS} > 0 ) {
    return $ENV{COLUMNS};
  }
  my $cols = eval {
    local $SIG{__WARN__} = sub { };
    my $out = `tput cols 2>/dev/null`;
    chomp $out;
    $out;
  };
  return ( $cols && $cols =~ /\A[0-9]+\z/ && $cols > 0 ) ? $cols : 80;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Dashboard - Multi-board overview of every karr board under a directory tree

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr dashboard
    karr dashboard ~/projects
    karr dashboard ~/projects --depth 2
    karr dashboard --hide-no-board
    karr dashboard --show-no-board
    karr dashboard --json
    karr dashboard --compact

=head1 DESCRIPTION

Walks a directory tree looking for Git repositories (a C<.git> marker), checks
each one for a karr board (C<refs/karr/config>), and prints a compact,
multi-column overview: one visual entry per repository, a bar of one block per
open task coloured by status, arranged side by side across the terminal width
rather than stacked one per line. It answers one question -- where is work
sitting, right now, across every board under here -- and touches nothing: it
never fetches, pushes, or writes to any board.

This is deliberately not L<App::karr::Foundation::Overview> (C<karr-foundation
--status>): that reads a fleet configuration and reports what agents are
doing. This command needs no configuration at all -- it finds what is there
and shows only where tickets are.

Only B<open> work is drawn: any status the board's own configuration marks
terminal (its own last status, or C<archived> -- see L<App::karr::Config>,
ticket #67) is left out of the bar and out of the per-board open count, the
same way L<App::karr::Cmd::Board> leaves finished work out of its default
view. Status names and which one is terminal are read from each board's own
config, never assumed -- two boards shown side by side may use entirely
different status lists.

=head1 SEARCH

The optional positional C<PATH> is the starting directory (default: the
current directory). From there the search is recursive: any directory
carrying a C<.git> entry counts as a repository and is not searched any
further (no diving into a repository's own working tree, and C<.git> itself is
never entered). C<--depth> bounds how many directory levels below C<PATH> are
descended into (default C<4>) -- unbounded would never finish under a home
directory. Symlinked directories are never followed, to avoid loops; a
directory that cannot be read (permissions) is skipped rather than aborting
the whole scan.

That positional C<PATH> is the only way to name the scan root. The root option
C<--dir> -- which every board command accepts in either placement, C<karr
--dir PATH list> as well as C<karr list --dir PATH> -- is B<refused> here in
both placements, and both exit C<2>: C<karr dashboard --dir PATH> is an
unknown option, printed with the usage line that names the positional
C<PATH>, and C<karr --dir PATH dashboard> is refused with a message saying
where the scan root goes. It is refused rather than accepted as a synonym
because it does not mean the same
thing: C<--dir> is the seed of a search B<upward> for the root of one
repository (which is why it may name any directory inside that repository),
while this command searches B<downward> for every board underneath a
directory. Handed one and the same path, the two would answer about different
directories. There is consequently no precedence rule for C<karr --dir A
dashboard B>: it is a usage error (exit C<2>), not a contest the positional
wins. Before ticket #225 the root placement was accepted and then discarded
without a word, so the command described the current directory while looking
like it had answered about the given one.

=head1 OPTIONS

=over 4

=item * C<--depth N>

Maximum recursion depth below C<PATH> (default C<4>). C<0> checks only C<PATH>
itself.

=item * C<--hide-no-board>

Omit the list of repositories that have no karr board entirely, including the
C<no_board> key under C<--json>. Wins over C<--show-no-board>.

=item * C<--show-no-board>

Always list the board-less repositories by name, wrapping over as many lines
as it takes. Without it, a list too long for one line collapses to a count
(C<No board: 46 repos (--show-no-board to list them)>) so it cannot bury the
summary line beneath it; a list that fits on one line is always shown in full
and needs no flag either way.

=item * C<--json>

Emits a structured document instead: C<< { root, summary, boards, no_board } >>.
Never coloured.

=item * C<--compact>

One plain line per repository (C<name>, a tab, then either C<no-board> or a
comma-separated list of C<status:count> tokens ending in C<blocked:count>),
for scripts and greps. Never coloured.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Board>, L<App::karr::Foundation::Overview>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
