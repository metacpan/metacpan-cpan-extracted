# ABSTRACT: Board configuration management

package App::karr::Config;
our $VERSION = '0.500';
use Moo;
use YAML::XS qw( LoadFile DumpFile );
use JSON::MaybeXS qw( JSON );
use Path::Tiny;


has file => ( is => 'ro', required => 1 );
has data => ( is => 'lazy' );

sub _build_data {
  my ($self) = @_;
  my $file = $self->file;
  return LoadFile($file->stringify) if defined $file && -f $file;
  die "No file or data provided to Config\n";
}

sub from_merged {
  my ($class, $merged) = @_;
  return bless { data => $merged, file => undef }, $class;
}


sub save {
  my ($self) = @_;
  DumpFile($self->file->stringify, $self->data);
}


# The three list accessors below tolerate a malformed board config instead of
# dying inside a dereference. `karr config show` has to stay able to print a
# broken board so it can be fixed, and L</validate> checks the list shape
# explicitly before it calls them, so nothing that should fail stops failing
# (ticket #78).
sub _list {
  my ( $self, $key ) = @_;
  my $value = $self->data->{$key};
  return ref $value eq 'ARRAY' ? @$value : ();
}

sub statuses {
  my ($self) = @_;
  return map {
    ref $_ ? $_->{name} : $_
  } $self->_list('statuses');
}


sub status_config {
  my ($self, $name) = @_;
  for my $s ($self->_list('statuses')) {
    if (ref $s) {
      return $s if $s->{name} eq $name;
    } elsif ($s eq $name) {
      return { name => $s };
    }
  }
  return undef;
}


sub priorities {
  my ($self) = @_;
  return ref $self->data->{priorities} eq 'ARRAY'
    ? @{ $self->data->{priorities} }
    : qw( low medium high critical );
}


sub classes {
  my ($self) = @_;
  return map {
    ref $_ ? $_->{name} : $_
  } $self->_list('classes');
}


sub claim_timeout {
  my ($self) = @_;
  return $self->data->{claim_timeout} // '1h';
}


sub foundation_enabled {
  my ($self) = @_;
  my $f = $self->data->{foundation};
  return 1 unless ref $f eq 'HASH' && exists $f->{enabled};
  return $f->{enabled} ? 1 : 0;
}


sub foundation_reason {
  my ($self) = @_;
  my $f = $self->data->{foundation};
  return undef unless ref $f eq 'HASH';
  my $reason = $f->{reason};
  return ( defined $reason && length $reason ) ? $reason : undef;
}


sub parse_bool {
  my ($class, $value) = @_;
  die "Missing boolean value\n" unless defined $value;
  my $v = lc $value;
  $v =~ s/^\s+//;
  $v =~ s/\s+$//;
  return 1 if $v =~ /^(?:1|true|yes|on)$/;
  return 0 if $v =~ /^(?:0|false|no|off)$/;
  die "Invalid boolean: $value (use true/false, yes/no, on/off, 1/0)\n";
}


# Go's time.ParseDuration grammar, which is what kanban-md's claim_timeout is
# written in: an optional sign, then one or more decimal-number-plus-unit
# groups. Note there is no day unit -- "7d" is an error in Go too.
my %DURATION_UNIT = (
  ns    => 1e-9,
  us    => 1e-6,
  "\x{b5}s" => 1e-6,   # micro sign
  "\x{3bc}s" => 1e-6,  # greek small letter mu
  ms    => 1e-3,
  s     => 1,
  m     => 60,
  h     => 3600,
);

sub parse_duration {
  my ($class, $str) = @_;
  return undef unless defined $str && length $str;

  my $sign = 1;
  $sign = -1 if $str =~ s/\A-//;
  $str =~ s/\A\+//;

  # Go accepts a bare "0" (and only "0") without a unit.
  return 0 if $str =~ /\A0+\z/;

  my $seconds = 0;
  my $matched = 0;
  while ( length $str ) {
    $str =~ s/\A([0-9]*\.?[0-9]+)// or return undef;
    my $value = $1;
    return undef if $value eq '.';
    $str =~ s/\A(ns|us|\x{b5}s|\x{3bc}s|ms|s|m|h)// or return undef;
    $seconds += $value * $DURATION_UNIT{$1};
    $matched++;
  }
  return undef unless $matched;
  return $sign * $seconds;
}


# Every rejection here is a usage error (ADR 0002), so it carries the same
# "Usage error:" marker L<App::karr::Role::ExitCodes/usage_error> emits and
# F<bin/karr> maps to exit 2. These are plain class/instance methods rather than
# calls to that role's method because App::karr::Config is not a command and
# does not consume it -- the marker is the contract, not the caller.
sub _usage_error {
  my ($field, $value, $detail) = @_;
  die sprintf "Usage error: invalid %s %s (%s)\n",
    $field, defined $value ? qq{"$value"} : '(none)', $detail;
}

sub validate_status {
  my ($self, $value) = @_;
  my @statuses = $self->statuses;
  return $value if defined $value && grep { $_ eq $value } @statuses;
  _usage_error( 'status', $value, 'valid: ' . join(', ', @statuses) );
}


sub validate_priority {
  my ($self, $value) = @_;
  my @priorities = $self->priorities;
  return $value if defined $value && grep { $_ eq $value } @priorities;
  _usage_error( 'priority', $value, 'valid: ' . join(', ', @priorities) );
}


sub validate_class {
  my ($self, $value) = @_;
  my @classes = $self->classes;
  return $value if defined $value && grep { $_ eq $value } @classes;
  _usage_error( 'class', $value, 'valid: ' . join(', ', @classes) );
}


sub validate_due {
  my ($class, $value) = @_;
  _usage_error( 'due date', $value, 'expected YYYY-MM-DD' )
    unless defined $value && $value =~ /\A(\d{4})-(\d{2})-(\d{2})\z/;
  my ( $y, $m, $d ) = ( $1, $2, $3 );
  # Calendar-correct, not just well-shaped: Go's time.Parse rejects 2026-02-30
  # and so must karr, or the date sorts fine and means nothing.
  _usage_error( 'due date', $value, 'expected YYYY-MM-DD' )
    unless $m >= 1
    && $m <= 12
    && $d >= 1
    && $d <= _days_in_month( $y, $m );
  return $value;
}


sub _days_in_month {
  my ( $year, $month ) = @_;
  my @days = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
  return 29 if $month == 2 && ( $year % 4 == 0 && ( $year % 100 != 0 || $year % 400 == 0 ) );
  return $days[ $month - 1 ];
}

sub validate {
  my ( $class, $data ) = @_;
  die "Board config is invalid: not a mapping\n" unless ref $data eq 'HASH';

  my $config = $class->from_merged($data);

  die "Board config is invalid: board.name is required\n"
    unless ref $data->{board} eq 'HASH'
    && defined $data->{board}{name}
    && length $data->{board}{name};
  die "Board config is invalid: tasks_dir is required\n"
    unless defined $data->{tasks_dir} && length $data->{tasks_dir};

  die "Board config is invalid: statuses must be a list\n"
    unless ref $data->{statuses} eq 'ARRAY';
  my @statuses = $config->statuses;
  die "Board config is invalid: at least 2 statuses are required\n"
    unless @statuses >= 2;
  die "Board config is invalid: every status needs a name\n"
    if grep { !defined || !length } @statuses;
  die "Board config is invalid: statuses contain duplicates\n"
    if _has_duplicates(@statuses);

  die "Board config is invalid: priorities must be a list\n"
    unless ref $data->{priorities} eq 'ARRAY';
  my @priorities = $config->priorities;
  die "Board config is invalid: at least 1 priority is required\n"
    unless @priorities >= 1;
  die "Board config is invalid: priorities contain duplicates\n"
    if _has_duplicates(@priorities);

  if ( defined $data->{classes} ) {
    die "Board config is invalid: classes must be a list\n"
      unless ref $data->{classes} eq 'ARRAY';
    my @classes = $config->classes;
    die "Board config is invalid: every class needs a name\n"
      if grep { !defined || !length } @classes;
    die "Board config is invalid: classes contain duplicates\n"
      if _has_duplicates(@classes);
    for my $c ( @{ $data->{classes} } ) {
      next unless ref $c eq 'HASH' && defined $c->{wip_limit};
      die "Board config is invalid: class $c->{name} wip_limit must be >= 0\n"
        unless $c->{wip_limit} =~ /\A\d+\z/;
    }
  }

  my $defaults = $data->{defaults} // {};
  die "Board config is invalid: defaults must be a mapping\n"
    unless ref $defaults eq 'HASH';
  for my $spec (
    [ status   => \@statuses   ],
    [ priority => \@priorities ],
    ) {
    my ( $key, $allowed ) = @$spec;
    my $value = $defaults->{$key};
    next unless defined $value;
    die "Board config is invalid: defaults.$key $value is not in the $key list\n"
      unless grep { $_ eq $value } @$allowed;
  }
  if ( defined $defaults->{class} && length $defaults->{class} ) {
    my @classes = $config->classes;
    die "Board config is invalid: defaults.class $defaults->{class} is not in the classes list\n"
      if @classes && !grep { $_ eq $defaults->{class} } @classes;
  }

  if ( defined $data->{claim_timeout} && length $data->{claim_timeout} ) {
    die "Board config is invalid: claim_timeout $data->{claim_timeout} is not a duration\n"
      unless defined $class->parse_duration( $data->{claim_timeout} );
  }

  return 1;
}


sub _has_duplicates {
  my %seen;
  return scalar grep { $seen{$_}++ } @_;
}

# The status kanban-md calls "archived": always terminal, and the one name it
# hardcodes (internal/config/config.go, ArchivedStatus).
use constant ARCHIVED_STATUS => 'archived';

# What a class-method call answers with, i.e. when there is no board config to
# derive from. It is the default board's own pair, so nothing that has always
# asked App::karr::Config->is_terminal_status changes its answer.
use constant DEFAULT_TERMINAL_STATUSES => ( 'done', ARCHIVED_STATUS );

sub is_terminal_status {
  my ($self, $status) = @_;
  return 0 unless defined $status;
  return ( grep { $_ eq $status } $self->terminal_statuses ) ? 1 : 0;
}


sub terminal_statuses {
  my ($self) = @_;
  # No instance, no configured statuses: the default board's pair.
  return ( DEFAULT_TERMINAL_STATUSES ) unless ref $self;

  my @names = $self->statuses;
  # kanban-md returns false for every status, archived included, when the board
  # configures none (internal/config/config.go, IsTerminalStatus).
  return () unless @names;

  # kanban-md's rule: the last configured status is terminal, unless that is
  # `archived`, in which case the one before it is. `archived` is terminal
  # either way, whether or not the board lists it.
  my $last = $names[-1];
  my $final = ( $last eq ARCHIVED_STATUS && @names > 1 ) ? $names[-2] : $last;

  my %seen;
  return grep { !$seen{$_}++ } ( $final, ARCHIVED_STATUS );
}


sub handoff_status {
  my ($self) = @_;
  # Asked on the class there is no board to derive from, so answer for the
  # default one -- the same convention is_terminal_status documents.
  $self = $self->from_merged( $self->default_config ) unless ref $self;

  # kanban-md's handoff targets the literal `review` and refuses a board that
  # does not configure one (cmd/handoff.go:105-110: "board has no 'review'
  # status; add one to use handoff"). Where the board has a review column
  # karr targets exactly that, so every board kanban-md itself can hand off on
  # behaves the same here; where it has none the target is derived rather
  # than refused -- the column a card sits in right before it is finished,
  # i.e. the last non-terminal status (ticket #102).
  my @statuses = $self->statuses;
  return 'review' if grep { $_ eq 'review' } @statuses;

  my %terminal = map { $_ => 1 } $self->terminal_statuses;
  my @open = grep { !$terminal{$_} } @statuses;
  return $open[-1] if @open;

  _usage_error( 'status', 'review',
    'board configures no review column and has no non-terminal column to hand off to' );
}


sub status_requires_claim {
  my ($self, $status_name) = @_;
  # Through L</status_config> rather than walking `statuses` a second time
  # (ticket #121). The bare-string rule t/53-config-semantics.t records --
  # only an explicit require_claim flag demands a claim -- survives the fold
  # because status_config synthesizes { name => $s } for a bare entry, which
  # carries no require_claim key and so answers 0 here.
  my $sc = $self->status_config($status_name);
  return 0 unless $sc;
  return $sc->{require_claim} ? 1 : 0;
}


sub effective_config {
  my ($class, $overrides, %args) = @_;
  my $defaults = $class->default_config(%args);
  return _merge_hashes($defaults, $overrides // {});
}


sub default_config {
  my ($class, %args) = @_;
  return {
    version => 1,
    board => {
      name => $args{name} // 'Kanban Board',
    },
    tasks_dir => 'tasks',
    statuses => [
      'backlog',
      'todo',
      { name => 'in-progress', require_claim => 1 },
      { name => 'review', require_claim => 1 },
      'done',
      'archived',
    ],
    priorities => [qw( low medium high critical )],
    classes => [
      { name => 'expedite', wip_limit => 1, bypass_column_wip => 1 },
      { name => 'fixed-date' },
      { name => 'standard' },
      { name => 'intangible' },
    ],
    claim_timeout => '1h',
    # Deliberately not claim_timeout. A claim says "an agent owns this work"
    # and has to outlive a whole session; a lock only covers the few
    # milliseconds `karr pick` spends deciding on and writing one card, and it
    # is the thing an agent that dies mid-pick leaves behind. Reusing the 1h
    # claim window here would leave that task unpickable for an hour (#45).
    # Accepts Nh / Nm / Ns; an explicit zero (`0s`) disables lock expiry.
    lock_timeout => '5m',
    # Board-level switch for automated agent runs (karr-foundation). Boards are
    # enabled by default; `karr disable` writes enabled => 0 (plus an optional
    # reason) into refs/karr/config so the opt-out syncs with the board.
    foundation => {
      enabled => 1,
    },
    defaults => {
      status   => 'backlog',
      priority => 'medium',
      class    => 'standard',
    },
  };
}


# The config keys kanban-md's Go schema types as `bool`
# (internal/config/config.go): StatusConfig.RequireClaim / .ShowDuration,
# ClassConfig.BypassColumnWIP, TUIConfig.HideEmptyColumns -- plus karr's own
# foundation.enabled, which kanban-md ignores but which is a boolean all the
# same. Listed here, next to default_config, so the two stay in step.
my %BOOLEAN_KEY = map { $_ => 1 }
  qw( require_claim show_duration bypass_column_wip hide_empty_columns enabled );

sub file_view_config {
  my ($class, $effective, %args) = @_;
  my $view = _booleanize($effective);
  # kanban-md validates next_id >= 1 and refuses a config without it. karr keeps
  # the counter in refs/karr/meta/next-id instead, so materialize copies it into
  # the view; import drops it again and leaves the ref authoritative.
  my $next_id = $args{next_id};
  $view->{next_id} = ( defined $next_id && $next_id >= 1 ) ? $next_id : 1;
  return $view;
}


# The board-config keys a file view is allowed to speak for on the way back in,
# i.e. the ones karr itself models. `version` is deliberately absent: it is
# karr's own numbering, and kanban-md rewrites the view's to its own on every
# load. So are `tui` and `wip_limits` -- kanban-md regenerates those from its
# defaults whenever it migrates a config, and `karr config` can neither show nor
# set them, so adopting them would freeze another tool's defaults into
# refs/karr/config as invisible, uneditable overrides (ticket #88).
my %VIEW_KEY = map { $_ => 1 } qw(
  board tasks_dir statuses priorities classes
  claim_timeout lock_timeout foundation defaults
);

# The same question one level down, inside a status or class entry.
my %VIEW_STATUS_KEY = map { $_ => 1 } qw( name require_claim );
my %VIEW_CLASS_KEY  = map { $_ => 1 } qw( name wip_limit bypass_column_wip );

sub reconcile_view_config {
  my ( $class, $overrides, $view ) = @_;
  return _merge_hashes( $overrides // {}, _view_overrides($view) );
}


sub _view_overrides {
  my ($view) = @_;
  return {} unless ref $view eq 'HASH';
  my %kept = map { $_ => $view->{$_} } grep { $VIEW_KEY{$_} } keys %$view;
  $kept{statuses} = [ map { _view_entry( $_, \%VIEW_STATUS_KEY, 1 ) } @{ $kept{statuses} } ]
    if ref $kept{statuses} eq 'ARRAY';
  $kept{classes} = [ map { _view_entry( $_, \%VIEW_CLASS_KEY, 0 ) } @{ $kept{classes} } ]
    if ref $kept{classes} eq 'ARRAY';
  return \%kept;
}

# Prune one status or class entry to the keys karr models and -- for statuses --
# collapse a mapping that says nothing beyond its name back to the bare string
# L</default_config> uses in exactly that case. Both halves are needed to make a
# kanban-md config compare equal to karr's defaults instead of being stored as
# an override: kanban-md writes every status as a mapping, and its v7->v8
# migration decorates half of them with `show_duration`, which karr does not
# model. Classes are never collapsed -- karr's default classes stay mappings
# even when `name` is all they carry.
sub _view_entry {
  my ( $entry, $allowed, $collapse ) = @_;
  return $entry unless ref $entry eq 'HASH';
  my %kept = map { $_ => $entry->{$_} } grep { $allowed->{$_} } keys %$entry;
  return $kept{name} if $collapse && keys(%kept) == 1 && defined $kept{name};
  return \%kept;
}

sub _booleanize {
  my ($data, $key) = @_;
  my $ref = ref $data;
  return { map { $_ => _booleanize( $data->{$_}, $_ ) } keys %$data } if $ref eq 'HASH';
  # No key is passed down into array elements: boolean keys only ever name a
  # hash value, and a list member is a status/class hash or a plain string.
  return [ map { _booleanize($_) } @$data ] if $ref eq 'ARRAY';
  return $data if $ref;
  return $data unless defined $key && $BOOLEAN_KEY{$key};
  return $data unless defined $data;
  return $data ? JSON->true : JSON->false;
}

sub _merge_hashes {
  my ($left, $right) = @_;
  my %merged = %{$left // {}};
  for my $key (keys %{$right // {}}) {
    if (ref($merged{$key}) eq 'HASH' && ref($right->{$key}) eq 'HASH') {
      $merged{$key} = _merge_hashes($merged{$key}, $right->{$key});
    } else {
      $merged{$key} = $right->{$key};
    }
  }
  return \%merged;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Config - Board configuration management

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    my $config = App::karr::Config->new(
      file => path('/tmp/karr-materialized/config.yml'),
    );

    my @statuses = $config->statuses;

=head1 DESCRIPTION

L<App::karr::Config> wraps the board configuration file and centralises access
to derived values such as status names, priority order, and merged effective
defaults. It is used by command modules that need a structured view of the
materialized board config instead of working with raw YAML hashes. In the
ref-first architecture the canonical config lives in C<refs/karr/config>, while
this class works with the temporary YAML file generated for a command run.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::BoardStore>, L<App::karr::Task>,
L<App::karr::Git>

=head2 from_merged

  my $config = App::karr::Config->from_merged($effective_hash);

Wraps an already-effective config hash (defaults merged with overrides,
typically L<App::karr::BoardStore/effective_config>) directly as a
L<App::karr::Config> instance, with no file behind it -- C<< ->file >>
answers C<undef>. This is the entry point almost every command uses to get a
queryable config object for the current board:

  App::karr::Config->from_merged( $self->store->effective_config )

is the standard idiom (see L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::Pick>,
L<App::karr::Cmd::Edit>, among others). Because C<file> is unset, L</save> on
an instance built this way dies dereferencing it -- these instances are for
reading and validating, not for writing back; write through
L<App::karr::BoardStore/save_config> instead.

=head2 save

  $config->save;

Dumps C<< $self->data >> as YAML to C<< $self->file >>. Only meaningful for
an instance constructed with a real C<file> (C<< App::karr::Config->new(file
=> $path) >>); an instance from L</from_merged> has no file and this dies
dereferencing C<undef>. This is not how the board config is written in
normal operation -- C<refs/karr/config> is written by
L<App::karr::BoardStore/save_config>, which validates and diffs against
defaults first. C<save> writes C<data> verbatim to a YAML file and exists for
code that works with the temporary materialized config view directly.

=head2 statuses

  my @statuses = $config->statuses;

Returns the configured status names in board order, accepting both the
mapping form C<< { name => 'in-progress', require_claim => 1 } >> and a bare
string. L</classes> follows the same convention over the classes list.

This is the list L</validate> checks for a minimum of two entries and no
duplicates, and that L</validate_status> and C<status_requires_claim> look a
single name up against.

=head2 status_config

  my $sc = $config->status_config('in-progress');
  # { name => 'in-progress', require_claim => 1 }

Returns the full configuration entry for one status: the mapping as
configured, or a synthesized C<< { name => $name } >> when the board wrote it
as a bare string, or C<undef> when no status by that name exists. Contrast
with L</statuses>, which returns every name and none of the per-status
detail.

This is the one place a single status name is resolved to what the board says
about it; L</status_requires_claim> is a boolean view of the C<require_claim>
key of what it returns, and any further per-status option belongs here too
rather than in a second walk over C<statuses> (ticket #121). Note that the
synthesized entry for a bare string carries nothing but C<name> -- that is
what makes a bare status require no claim.

=head2 priorities

  my @priorities = $config->priorities;

Returns the configured priority names in order, or the built-in C<low medium
high critical> when the config carries none. Unlike L</statuses> and
L</classes>, entries are always bare strings -- kanban-md's priority list has
no per-entry options to carry.

=head2 classes

Returns the configured class-of-service names in board order, accepting both
the mapping form C<< { name => 'expedite', wip_limit => 1 } >> and a bare
string, the same way L</statuses> does.

    my @classes = $config->classes;

=head2 claim_timeout

  my $raw = $config->claim_timeout;   # '1h', unparsed

Returns the board's configured claim-expiry duration as the raw string from
the config (C<'1h'> when unset), in kanban-md's C<time.ParseDuration> grammar
-- not seconds. Pass it to L</parse_duration> to get a number. Governs how
long C<karr pick> and the C<move>/C<edit>/C<handoff> claim check
(L<App::karr::Role::ClaimTimeout>) honour an existing C<claimed_by> before
treating it as expired; distinct from C<lock_timeout>, which bounds a single
C<karr pick> transaction rather than a whole work session.

=head2 foundation_enabled

Returns true when automated agent runs (L<App::karr::Foundation>) are allowed on
this board. The flag lives in the board config under C<foundation.enabled> and
therefore travels with C<refs/karr/config>; a board that never set it is
enabled.

    if ($config->foundation_enabled) {
        # karr-foundation may drain this board
    }

=head2 foundation_reason

Returns the free-text reason recorded alongside C<foundation.enabled>, or undef
when none was given. Only meaningful while the board is disabled.

    my $why = $config->foundation_reason;

=head2 parse_bool

Coerces a CLI-supplied boolean string to C<1> or C<0>, dying on anything else.
Needed because a bare C<"false"> from the command line is true in Perl.

    my $bool = App::karr::Config->parse_bool('false');   # 0

=head2 parse_duration

Parses a Go C<time.ParseDuration> string into seconds, returning C<undef> when
it is not a duration at all. kanban-md writes C<claim_timeout> in that grammar,
so a compound value such as C<1h30m> has to mean ninety minutes on both sides
of the interop boundary (ticket #78).

    my $secs = App::karr::Config->parse_duration('1h30m');   # 5400
    my $secs = App::karr::Config->parse_duration('7d');      # undef -- no day unit

=head2 validate_status

Dies unless the value is one of the board's configured statuses, returning the
value otherwise so it can be used inline.

    $task->status( $config->validate_status($wanted) );

=head2 validate_priority

Dies unless the value is one of the board's configured priorities.

=head2 validate_class

Dies unless the value is one of the board's configured classes of service.

=head2 validate_due

Dies unless the value is a real calendar date in C<YYYY-MM-DD>, the only form
kanban-md's C<date.Date> accepts.

    App::karr::Config->validate_due('2026-02-30');   # dies

=head2 validate

Checks a fully merged board config and dies with a C<Board config is invalid:>
message on the first problem, mirroring kanban-md's C<Config.Validate>. Only the
parts karr actually models are checked -- karr keeps C<next_id> in a ref rather
than in the config, has no WIP limits or TUI section yet, and uses its own
C<version> numbering, so those three checks are deliberately absent.

Called from L<App::karr::BoardStore/save_config>, which is the single write
choke point for C<refs/karr/config>, so C<karr config set>, C<karr import> and
C<karr disable> all reject a broken schema instead of writing it (ticket #78).
It is B<not> called on the read path: a board that is already broken has to stay
loadable, or it could not be repaired with karr itself.

    App::karr::Config->validate( $store->load_config );

=head2 is_terminal_status

Returns true if the given status is terminal for this board.

    if ($config->is_terminal_status($task->status)) {
        # task is in a terminal state
    }

Called on the class it answers for the default board, C<done> and C<archived>;
call it on an instance to have the board's own C<statuses> decide. See
L</terminal_statuses> for why that matters (ticket #67).

=head2 terminal_statuses

Returns the board's terminal status names, C<done>-equivalent first.

    my @terminal = $config->terminal_statuses;   # ('shipped', 'archived')

karr used to hardcode C<done> and C<archived> here, which is right only for the
default board. A board imported from kanban-md may name its final column
anything at all, and on such a board C<list> did not hide finished work and
C<pick> handed it straight back out (ticket #67). The rule is kanban-md's, from
C<Config.IsTerminalStatus>: the last configured status is terminal, or the one
before it when the last is C<archived>, and C<archived> is terminal regardless.

Note that karr's C<statuses> are not settable from the CLI -- C<karr config set
statuses> refuses the key -- so a non-default status list only ever arrives
through C<karr import> of a kanban-md F<config.yml>.

=head2 handoff_status

Returns the status C<karr handoff> moves a task to on this board.

    my $target = $config->handoff_status;   # 'review' on the default board

That is C<review> whenever the board configures such a column -- kanban-md's
own target, which it validates rather than derives
(F<cmd/handoff.go>:105-110) -- and the last non-terminal status otherwise, so
a handoff always lands in the column a card sits in right before it is
finished. Called on the class it answers for the default board. Dies as a
usage error on a board with no working column at all.

=head2 status_requires_claim

  if ($config->status_requires_claim('in-progress')) {
      # move/pick into this status must carry --claim
  }

Returns true when the named status is configured with C<require_claim> set,
false both when it is configured without one and when no status by that name
exists at all -- never dies, unlike L</validate_status>. It is exactly
L</status_config>'s C<require_claim> key read as a boolean, and asks that
method for the entry rather than walking C<statuses> itself (ticket #121).

L<App::karr::BoardStore/status_requires_claim> wraps this with
L</from_merged> into the per-board form that L<App::karr::Role::TaskMutation>
and C<karr move>/C<karr pick> actually call to gate a status change.

=head2 effective_config

  my $ec = App::karr::Config->effective_config($overrides);
  my $ec = App::karr::Config->effective_config($overrides, name => 'My Board');

Deep-merges C<$overrides> (a board's sparse C<refs/karr/config> contents, or
C<{}>/C<undef> for none) over L</default_config>, with C<%args> forwarded to
it, and returns the merged result as a plain hash reference -- B<not> a
blessed L<App::karr::Config> instance. Wrap the result in L</from_merged> to
get one.

Not to be confused with L<App::karr::BoardStore/effective_config>, the
per-store cached wrapper most command code actually calls: that instance
method calls this class method once (via L<App::karr::BoardStore/load_config>)
and caches the hash it returns.

=head2 default_config

    my $defaults = App::karr::Config->default_config;
    my $defaults = App::karr::Config->default_config( name => 'My Board' );

Returns the hash reference of built-in defaults a board starts from: the
status/priority/class-of-service lists, C<claim_timeout> and
C<lock_timeout>, C<foundation.enabled>, and the C<defaults.status> /
C<defaults.priority> / C<defaults.class> triple new tasks are created with.
C<name> is the only override taken, for C<karr init --name>; everything else
is the fixed starting point.

C<effective_config> layers a board's sparse C<refs/karr/config> overrides on
top of this to answer what the board actually uses, and
L<App::karr::BoardStore> diffs against it the other way -- C<save_config>
only ever writes the keys that differ from these defaults, so a board that
never touched C<lock_timeout> does not carry a frozen copy of it forever.
C<BoardStore> also calls it directly to seed a fresh board on C<karr init>
and, on C<karr import> of a kanban-md tree with no F<config.yml>, to
bootstrap one that is not half a board (ticket #30).

It also stands in for a real board wherever a class-level call has none to
derive from -- L</handoff_status> is one such caller -- the same
class-vs-instance convention L</is_terminal_status> documents.

=head2 file_view_config

Returns the effective config reshaped for the materialized kanban-md file view:
boolean-typed keys become real YAML booleans instead of Perl's C<1>/C<0>, and
C<next_id> is filled in from the C<next_id> argument. Both are load-bearing --
go-yaml refuses to unmarshal C<1> into a C<bool> and kanban-md rejects a config
whose C<next_id> is below C<1>, so without either the whole board is unreadable
to kanban-md (ticket #60). The caller has to dump it under
C<local $YAML::XS::Boolean = 'JSON::PP'> for the booleans to survive.

    my $view = App::karr::Config->file_view_config( $effective, next_id => 7 );

=head2 reconcile_view_config

Folds a file view's F<config.yml> into the board's existing sparse overrides and
returns the reconciled overrides. The view wins for every key it carries and
karr models; every other key keeps whatever C<refs/karr/config> already said.

Import used to replace the board config with the file view outright, which only
works if the view can express everything the board holds -- and it cannot.
kanban-md rewrites F<config.yml> the moment it loads one, migrating it to its
own schema version and re-serializing it from its Go structs, so every key that
schema does not know is simply gone: karr's C<foundation> and C<lock_timeout>
among them. A board turned off with C<karr disable> came back B<on> from an
ordinary C<karr materialize> / C<kanban list> / C<karr import --yes> round trip
(ticket #87). Reading the view as "here is what changed" rather than "here is
the whole config" is what makes a key kanban-md never heard of survive it.

The same reconciliation is what keeps the migration itself out of the board
config: the view's keys are pruned to what karr models and normalized to the
shape L</default_config> uses, so kanban-md's migrated defaults compare equal to
karr's and are not recorded as deliberate per-board overrides (ticket #88).

    my $overrides = App::karr::Config->reconcile_view_config(
      $store->load_config_overrides, $file_config );

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
