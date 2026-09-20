# ABSTRACT: View or modify board configuration

package App::karr::Cmd::Config;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr config [show|get KEY|set KEY VALUE] '
    . '[--defaults] [--json] [--compact]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::CompactOutput;
use App::karr::Config;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::CompactOutput';


option defaults => (
  is  => 'ro',
  doc => "Print karr's built-in defaults instead of this board's config",
);

my %WRITABLE = map { $_ => 1 } qw(
  board.name board.description
  defaults.status defaults.priority defaults.class
  claim_timeout lock_timeout
  foundation.enabled foundation.reason
);

# The sentence the no-board refusal carries beyond `karr sync` / `karr init`.
# This command is the only read that has a third answer worth naming: the
# defaults it used to print silently are true of karr, just not of any board,
# and --defaults is where they are still available (#136).
my $DEFAULTS_HINT =
    "To see the values a board created here would start with, run\n"
  . "'karr config show --defaults' -- those are karr's, not any board's.\n";

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my @pos    = $self->positional_args($args_ref);
  my $action = $pos[0] // 'show';

  # Action-dependent arity: show=1, get KEY=2, set KEY VALUE=3 positionals
  # (the action itself is a positional). Reject surplus before any work/sync --
  # and reject an action that is not one of the three here rather than after the
  # config is loaded, so `karr config bogus` still says so in a repository that
  # has no board to refuse over.
  my %arity = ( show => 1, get => 2, set => 3 );
  die "Unknown action: $action (use show, get, or set)\n" unless $arity{$action};
  $self->check_positional_args($args_ref, $arity{$action});

  # Option validation before the board checks, so misuse still exits 2 (ADR
  # 0002) rather than being pre-empted by a refusal about the board.
  $self->usage_error('--defaults reads no board, so there is nothing to set')
    if $self->defaults && $action eq 'set';

  # `set` writes, so it pulls first and then requires a whole board. `get` and
  # `show` read, so they stay offline (#135) -- but they must still say whether
  # anything was read: printing the code defaults for a board that was never
  # loaded is the same lie for `board.name` that `0 tasks` was for the task
  # list, and in a fresh clone it is the normal case (#136). --defaults asks
  # for those defaults on purpose and touches neither store nor Git, so it
  # answers outside a repository too.
  my $config;
  if ( $self->defaults ) {
    $config = App::karr::Config->from_merged( App::karr::Config->default_config );
  }
  else {
    if ( $action eq 'set' ) {
      $self->sync_before;
      $self->require_board;
    }
    else {
      $self->require_local_board( hint => $DEFAULTS_HINT );
    }
    $config = App::karr::Config->from_merged($self->store->effective_config);
  }

  if ($action eq 'show') {
    $self->_show_all($config);
  } elsif ($action eq 'get') {
    # length, not truth, on both keys below: `or` reads the key "0" as no key
    # at all and answers a usage error (2) where an unknown key answers
    # "Unknown key" (1) -- the fourth and last site of the shape #153, #230 and
    # #239 closed elsewhere (#244). No config key is numeric, so nothing real
    # was unreachable; what was wrong is which side of the exit-code contract
    # (ADR 0002) a bad key falls on. The value below already used //, which
    # keeps `config set foundation.enabled 0` writable.
    my $key = $pos[1];
    die "Usage: karr config get KEY\n" unless defined $key && length $key;
    $self->_get_key($config, $key);
  } elsif ($action eq 'set') {
    my $key = $pos[1];
    die "Usage: karr config set KEY VALUE\n" unless defined $key && length $key;
    my $val = $pos[2] // die "Usage: karr config set KEY VALUE\n";
    $self->_set_key($config, $key, $val);
    $self->sync_after;
  }
}

sub _show_all {
  my ($self, $config) = @_;
  my $d = $config->data;

  if ($self->json) {
    $self->print_json($d);
    return;
  }

  my @keys = $self->_display_keys($d);

  # Same rows, no column: `key=value` is what a script cuts on, and the padded
  # table is what a person reads. Until #254 this command took --compact from
  # App::karr::Role::Output and printed the padded table for it anyway.
  if ($self->compact) {
    for my $entry (@keys) {
      my ($key, $val) = @$entry;
      printf "%s=%s\n", $key, $self->_format_value($val);
    }
    return;
  }

  for my $entry (@keys) {
    my ($key, $val) = @$entry;
    printf "%-25s %s\n", $key, $self->_format_value($val);
  }
}

sub _display_keys {
  my ($self, $d) = @_;
  # Every list and mapping guarded before it is dereferenced: `config show` is
  # how you find out that a config is broken, so it must not die dereferencing
  # the very key that is wrong (ticket #78).
  my $c = App::karr::Config->from_merged($d);
  my $board    = ref $d->{board} eq 'HASH'    ? $d->{board}    : {};
  my $defaults = ref $d->{defaults} eq 'HASH' ? $d->{defaults} : {};
  # The lists as configured, not just their names: `_format_value` renders the
  # mapping form legibly, and `show` and `get` should not disagree about what
  # the board's statuses are (ticket #130).
  my $statuses = ref $d->{statuses} eq 'ARRAY' ? $d->{statuses} : [];
  my $classes  = ref $d->{classes}  eq 'ARRAY' ? $d->{classes}  : [];
  # `defined`, not truth, on the six optional rows below. The question the
  # filter asks is "did this config set the key at all", and a user-set `0` is
  # a value, not an absence: `config set board.name 0` was accepted, `config get
  # board.name` answered 0 and `config show --json` carried it, while this table
  # dropped the row -- and with it the POD promise above that `diff <(karr
  # config show) <(karr config show --defaults)` is the set of keys this board
  # overrides, because `board.description` and `foundation.reason` have no
  # default row for the override to differ from (#255). `foundation.enabled`
  # already prints a bare `0` two lines down, unfiltered, so a zero row is
  # nothing new in this output.
  #
  # `defined` alone rather than `defined && length`: the empty string is the
  # same disagreement with a different value. `config set` cannot write one
  # (#243 refuses an empty argument), but `karr import` and a hand-edited
  # config.yml can, and there `config get board.description` prints an empty
  # line at exit 0 while `--json` carries "" -- both call the key present, so
  # the table does too. Rendering stays `_format_value`'s: it answers '' and
  # leaves the row's right-hand side blank, which is the same nothing `config
  # get` prints for it. A placeholder like `(empty)` would read better but is a
  # notation no other surface of this command has, and would put `show` and
  # `get` back in disagreement from the other side.
  my @out;
  push @out, ['version',            $d->{version}];
  push @out, ['board.name',         $board->{name}]        if defined $board->{name};
  push @out, ['board.description',  $board->{description}] if defined $board->{description};
  push @out, ['tasks_dir',          $d->{tasks_dir}];
  push @out, ['statuses',           $statuses];
  push @out, ['priorities',         [$c->priorities]];
  push @out, ['defaults.status',    $defaults->{status}]   if defined $defaults->{status};
  push @out, ['defaults.priority',  $defaults->{priority}] if defined $defaults->{priority};
  push @out, ['defaults.class',     $defaults->{class}]    if defined $defaults->{class};
  push @out, ['claim_timeout',      $d->{claim_timeout}];
  push @out, ['lock_timeout',       $d->{lock_timeout}];
  push @out, ['classes',            $classes];
  push @out, ['foundation.enabled', $c->foundation_enabled];
  push @out, ['foundation.reason',  $d->{foundation}{reason}]
    if ref $d->{foundation} eq 'HASH' && defined $d->{foundation}{reason};
  return @out;
}

sub _get_key {
  my ($self, $config, $key) = @_;
  my $val = $self->_resolve_key($config->data, $key);
  die "Unknown key: $key\n" unless defined $val;

  if ($self->json) {
    # Always wrapped in the requested key, scalar or not (#131). It used to hand
    # a list or mapping over bare, and then `config get board --json` answered
    # {"name":"..."} -- indistinguishable from the wrapped form of a scalar key
    # named `name`, with nothing in the payload saying which of the two it was.
    # Wrapping unconditionally also makes the answer a one-key subset of the
    # `config show --json` object rather than a second schema.
    $self->print_json({ $key => $val });
  } else {
    printf "%s\n", $self->_format_value($val);
  }
}

sub _set_key {
  my ($self, $config, $key, $val) = @_;
  die "Key '$key' is read-only\n" unless $WRITABLE{$key};

  my $d = $config->data;

  # Validate values. The same App::karr::Config validators the task write paths
  # use, so `karr config set defaults.status X` and `karr create --status X`
  # cannot disagree about what a legal status is (ticket #54).
  if ($key eq 'defaults.status') {
    $config->validate_status($val);
  } elsif ($key eq 'defaults.priority') {
    $config->validate_priority($val);
  } elsif ($key eq 'defaults.class') {
    $config->validate_class($val) if $val ne '';
  } elsif ($key eq 'claim_timeout') {
    # Both timeouts through the one Go-grammar parser, so `1h30m` means ninety
    # minutes here and in kanban-md (ticket #78). usage_error rather than a bare
    # die: an option value that parses but is not a duration is misuse, and the
    # exit-code contract says 2.
    $self->usage_error(
      qq{invalid claim_timeout "$val" (use e.g. 1h, 30m, 1h30m, 0s to disable)})
      unless defined App::karr::Config->parse_duration($val);
  } elsif ($key eq 'lock_timeout') {
    $self->usage_error(qq{invalid lock_timeout "$val" (use e.g. 5m, 30s, 0s to disable)})
      unless defined App::karr::Config->parse_duration($val);
  } elsif ($key eq 'foundation.enabled') {
    # A bare "false" from the command line is true in Perl -- coerce here so the
    # stored value is the same 1/0 `karr disable`/`karr enable` write.
    $val = App::karr::Config->parse_bool($val);
  }

  # Set the value
  if ($key =~ /^(\w+)\.(\w+)$/) {
    $d->{$1}{$2} = $val;
  } else {
    $d->{$key} = $val;
  }

  $self->store->save_config($d);

  if ($self->json) {
    $self->print_json({ key => $key, value => $val });
  } else {
    printf "Set %s = %s\n", $key, $val;
  }
}

sub _resolve_key {
  my ($self, $d, $key) = @_;
  if ($key =~ /^(\w+)\.(\w+)$/) {
    return $d->{$1}{$2};
  }
  return $d->{$key};
}

sub _format_value {
  my ($self, $val) = @_;
  return '' unless defined $val;
  if (ref $val eq 'ARRAY') {
    return join(', ', map { $self->_format_entry($_) } @$val);
  } elsif (ref $val eq 'HASH') {
    return $self->_format_settings($val, sort keys %$val);
  }
  return "$val";
}

# One entry of a config list. `statuses` and `classes` allow both a bare name
# and the mapping form ({ name => 'in-progress', require_claim => 1 }), and
# joining the raw list stringified every mapping as HASH(0x...) -- unreadable in
# the one output a reader consults to learn which columns a board has, which is
# how an "extended status set" nobody configures got invented (ticket #130). The
# name leads and its per-entry settings follow in parentheses, so the value
# stays a single greppable line and still says which status wants a claim. On a
# default board that claim flag is the only setting left to show: since #227 the
# four default classes are name-only mappings and karr models no WIP limits at
# all, so a class with settings in this rendering is one the board itself set or
# imported. --json is untouched by this: it carries the entries as configured,
# never a rendering of them.
sub _format_entry {
  my ($self, $entry) = @_;
  return $self->_format_value($entry) unless ref $entry eq 'HASH';
  my @settings = grep { $_ ne 'name' } sort keys %$entry;
  my $name = defined $entry->{name} ? $entry->{name} : '';
  return $name unless @settings;
  return sprintf '%s(%s)', length $name ? "$name " : '',
    $self->_format_settings($entry, @settings);
}

sub _format_settings {
  my ($self, $hash, @keys) = @_;
  return join(', ', map { "$_: " . $self->_format_value($hash->{$_}) } @keys);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Config - View or modify board configuration

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr config
    karr config get claim_timeout
    karr config set board.name "New Board Name"
    karr config show --defaults
    karr config --json
    karr config show --compact

=head1 DESCRIPTION

Reads and updates the board configuration stored canonically in
C<refs/karr/config>. The command supports whole-config display, individual key
lookup, and writes to a small set of explicitly writable keys. Internally it
works on the temporary materialized YAML view generated for the command run.

C<show> and C<get> answer for B<this repository's board> and refuse when there
is none, the way every other read command does
(L<App::karr::Role::BoardDiscovery/require_local_board>). They used to fall
back to the code defaults instead, and the fallback was silent: in a fresh
clone -- where C<git clone> has fetched none of C<refs/karr/*> and the board is
sitting on the remote -- C<karr config get board.name> answered C<Kanban Board>,
karr's placeholder, for a board that has a name (#136).

Those defaults are still worth printing; they were just answering a different
question. C<--defaults> asks it explicitly, so a caller can always tell the
board's value from the value karr would use if you made one:

    karr config show                # this board's config, or exit 1 if none
    karr config show --defaults     # what a board created here would start with

=head1 OPTIONS

=over 4

=item * C<--defaults>

Print L<App::karr::Config/default_config> instead of the board's config, for
C<show> and C<get> alike. Reads no board and needs no Git repository at all,
so it answers the same anywhere -- which is what makes it honest where the
fallback was not. Rejected on C<set>, which has nothing to write to.

Because it renders identically to a board read, C<< diff <(karr config show)
<(karr config show --defaults) >> is exactly the set of keys this board
overrides. That holds for every value a key can carry: the plain-text table
lists a key whenever the config defines it, C<0> and the empty string
included -- an empty value gets a row with a blank right-hand side, which is
what C<config get> prints for it too. Through 0.500 the optional rows were
filtered by truth, so a board that set C<board.name> to C<0> reported that key
through C<get> and C<--json> but dropped it from both sides of the diff (#255).

=item * C<--json>

Machine-readable rendering of whichever of the two the command answered.
C<show> prints the config as one object keyed by config key; C<get KEY> prints
that same object restricted to the one key asked for -- B<always> wrapped, so
the requested key is in the payload whatever its value is:

    karr config get claim_timeout --json    # {"claim_timeout":"1h"}
    karr config get board --json            # {"board":{"name":"..."}}
    karr config get statuses --json         # {"statuses":["backlog", ...]}

Through 0.402 only scalars were wrapped and lists and mappings were printed
bare, which left C<get board> answering C<{"name":"..."}> -- byte-identical to
the wrapped form of a scalar key called C<name>, and no key in the payload to
tell them apart (#131). Consumers that read the bare list or mapping must now
index the requested key first; a scalar read is unchanged.

=item * C<--compact>

C<show> prints C<key=value>, one key per line, instead of padding the key into
a 25-column field:

    karr config show --compact | grep '^claim_timeout='

Same keys, same order, and the same rendered values as the padded table --
only the frame changes, so the C<diff> of a board against C<--defaults>
described above holds for this rendering too. A value is still rendered for
people (a list joins with C<, >), because C<show> and C<--compact> disagreeing
about what a board's statuses are would be the trap of #130 again; the payload
notation is C<--json>, and C<--json> wins where both are given.

C<get> and C<set> are unchanged by it: C<get> already prints the bare value
and nothing else -- which is what C<$(karr config get claim_timeout)> relies
on and is as terse as an answer gets -- and C<set> already confirms in a single
short line. The option is accepted there and has nothing left to shorten.

=back

=head1 WRITABLE KEYS

=over 4

=item * C<board.name>, C<board.description>

Human-facing board metadata.

=item * C<defaults.status>, C<defaults.priority>, C<defaults.class>

Default values applied by L<App::karr::Cmd::Create>.

=item * C<claim_timeout>

Claim expiry duration in C<Nh> or C<Nm> format. Defaults to C<1h>; C<0s>
disables expiry, so a claim binds until it is released and no other agent can
pick or mutate the card in the meantime.

=item * C<lock_timeout>

How long a C<karr pick> lock ref may be held before another agent may break it,
in C<Nh>, C<Nm>, or C<Ns> format. This is not C<claim_timeout>: a claim covers a
work session, a lock covers one pick. Defaults to C<5m>; C<0s> disables expiry,
leaving L<App::karr::Cmd::Unlock> as the only way to clear a stale lock.

=item * C<foundation.enabled>, C<foundation.reason>

Board-level switch for automated agent runs (L<App::karr::Foundation>) and the
free-text reason recorded with it. C<foundation.enabled> takes a boolean word
(C<true>/C<false>, C<yes>/C<no>, C<on>/C<off>, C<1>/C<0>) and is the same state
L<App::karr::Cmd::Disable> and L<App::karr::Cmd::Enable> write.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Init>, L<App::karr::Cmd::Create>,
L<App::karr::Cmd::Context>, L<App::karr::Config>

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
