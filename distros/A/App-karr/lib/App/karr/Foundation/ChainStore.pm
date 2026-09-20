# ABSTRACT: karr-foundation chain and run-log storage under refs/karr-foundation/*

package App::karr::Foundation::ChainStore;
our $VERSION = '0.601';
use Moo;
use POSIX qw( strftime );
use Digest::MD5 qw( md5_hex );
use Try::Tiny;
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( yaml_dump yaml_load json_encode json_decode );



has git => (
  is       => 'ro',
  required => 1,
);

use constant CHAIN_META => 'refs/karr-foundation/chain/meta';
use constant STEP_ROOT  => 'refs/karr-foundation/chain/step/';
use constant LOG_ROOT   => 'refs/karr-foundation/log/';

# The same cap App::karr::ActivityLog uses, for the same reason (#171): one
# append may never cost more than one blob of this size, so the bytes a run
# log writes grow linearly with its entries instead of quadratically.
use constant SEGMENT_MAX_BYTES => 8192;

# Retention. Days is what an operator thinks in; the count is what actually
# bounds the namespace, because a fleet that runs ten thousand steps a day
# would otherwise keep ten thousand refs inside its two weeks.
use constant KEEP_DAYS => 14;
use constant KEEP_RUNS => 500;

my %STEP_KIND = map { $_ => 1 } qw( ticket shell question plan );

# pending -> running -> done | failed, plus stale for a step whose precheck no
# longer holds. "blocked" is deliberately not a state: whether a step waits on
# another is read off the needs edges, and a second, stored copy of that would
# be one more thing that can disagree with the graph.
my %STEP_STATE = map { $_ => 1 } qw( pending running done failed stale );

# Keys a step may carry. Anything matching on_* is a policy and passes as well;
# what a policy value means is the runner's (#186), not this store's, so the
# vocabulary is not enumerated here.
my %STEP_KEY = map { $_ => 1 } qw(
  id kind repo ticket needs timeout precheck command note
  chain state stale_reason stale_at started finished attempts result
);

sub _now { return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime() ) }

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

sub _step_ref { return STEP_ROOT . $_[1] }

# Ids become ref components, so they are checked against something narrower
# than git's own grammar: no dots (git forbids '..', a leading dot, a trailing
# '.lock'), no slashes (a step id is one component), and a leading alphanumeric.
sub _valid_id { return defined $_[0] && "$_[0]" =~ /\A[A-Za-z0-9][A-Za-z0-9_-]*\z/ }

sub _validate_step {
  my ( $self, $step ) = @_;
  user_error('A chain step must be a mapping') unless ref $step eq 'HASH';
  my %s = %$step;

  my $id = $s{id};
  user_error('A chain step needs an id') unless defined $id && length "$id";
  user_error("Chain step id '$id' must be alphanumeric (letters, digits, '_', '-')")
    unless _valid_id($id);
  $id = "$id";
  $s{id} = $id;

  # The dividing line of this whole design, enforced where it is cheapest to
  # enforce. Ignoring the key would leave a chain that reads as if it routed
  # work, and a planner that never hears about it keeps writing more.
  user_error("Chain step '$id' names an agent: the chain is shared state and an "
    . 'agent is a property of a machine, so routing belongs in the local config')
    if exists $s{agent} || exists $s{agents};

  my $kind = $s{kind};
  user_error("Chain step '$id' has no kind (expected: "
    . join( ', ', sort keys %STEP_KIND ) . ')')
    unless defined $kind && length $kind;
  user_error("Chain step '$id' has unknown kind '$kind' (expected: "
    . join( ', ', sort keys %STEP_KIND ) . ')')
    unless $STEP_KIND{$kind};

  # A ticket step is an invocation in a repository, so both halves of "which
  # ticket, where" have to be there; a question or a plan is fleet-wide and
  # needs neither.
  if ( $kind eq 'ticket' || $kind eq 'shell' ) {
    user_error("Chain step '$id' ($kind) needs a repo")
      unless defined $s{repo} && length $s{repo};
  }
  if ( $kind eq 'ticket' ) {
    user_error("Chain step '$id' (ticket) needs a ticket id")
      unless defined $s{ticket} && length "$s{ticket}";
  }
  # And a shell step needs something to run, for the same reason a precheck is
  # parsed here rather than at execution time: a planning mistake the planner
  # still hears about beats a step the executor later cannot do anything with.
  if ( $kind eq 'shell' ) {
    user_error("Chain step '$id' (shell) needs a command")
      unless defined $s{command} && length "$s{command}";
  }

  # YAML writes a one-element list as a scalar often enough that refusing one
  # would be pedantry; the board's frontmatter accepts both spellings too.
  my $needs = $s{needs};
  if ( defined $needs && !ref $needs ) { $needs = [ $needs ] }
  $needs //= [];
  user_error("Chain step '$id': needs must be a list of step ids")
    unless ref $needs eq 'ARRAY';
  my @needs;
  for my $n ( @$needs ) {
    user_error("Chain step '$id': needs must be a list of step ids")
      if ref $n || !defined $n;
    user_error("Chain step '$id' needs '$n', which is not a valid step id")
      unless _valid_id($n);
    user_error("Chain step '$id' needs itself") if "$n" eq $id;
    push @needs, "$n";
  }
  $s{needs} = \@needs;

  if ( defined $s{timeout} ) {
    user_error("Chain step '$id': timeout must be a whole number of seconds")
      unless "$s{timeout}" =~ /\A[0-9]+\z/;
    $s{timeout} += 0;
  }

  # Parsed at write time so a precheck that cannot be read is a planning error
  # the planner still hears about, rather than a step the runner later cannot
  # decide about.
  $self->parse_precheck( $s{precheck}, "Chain step '$id'" ) if defined $s{precheck};

  my $state = $s{state} // 'pending';
  user_error("Chain step '$id' has unknown state '$state' (expected: "
    . join( ', ', sort keys %STEP_STATE ) . ')')
    unless $STEP_STATE{$state};
  $s{state} = $state;

  for my $key ( sort keys %s ) {
    next if $STEP_KEY{$key} || $key =~ /\Aon_/;
    warn "karr-foundation: chain step '$id': unknown key '$key'\n";
  }
  for my $key ( grep { /\Aon_/ } sort keys %s ) {
    user_error("Chain step '$id': policy '$key' must be a plain value")
      if ref $s{$key};
  }

  return \%s;
}


sub write_chain {
  my ( $self, $steps, %opt ) = @_;
  my @validated = @{ $self->validate_chain( $steps, %opt ) };

  my $chain_id = _new_chain_id();
  $self->_clear_steps;
  for my $step ( @validated ) {
    $step->{chain} = $chain_id;
    $self->git->write_ref( $self->_step_ref( $step->{id} ), yaml_dump($step) );
  }

  my %header = (
    id      => $chain_id,
    created => _now(),
    ( defined $opt{limits}  ? ( limits  => $opt{limits} )  : () ),
    ( defined $opt{note}    ? ( note    => $opt{note} )    : () ),
    ( defined $opt{planner} ? ( planner => $opt{planner} ) : () ),
  );
  $self->git->write_ref( CHAIN_META, yaml_dump( \%header ) );
  return $chain_id;
}


sub validate_chain {
  my ( $self, $steps, %opt ) = @_;
  user_error('A chain needs at least one step')
    unless ref $steps eq 'ARRAY' && @$steps;

  my @validated = map { $self->_validate_step($_) } @$steps;
  my %by_id;
  for my $step ( @validated ) {
    user_error("Chain step id '$step->{id}' is used twice")
      if $by_id{ $step->{id} }++;
  }
  for my $step ( @validated ) {
    for my $need ( @{ $step->{needs} } ) {
      user_error("Chain step '$step->{id}' needs '$need', which is not in this chain")
        unless $by_id{$need};
    }
  }
  _refuse_cycle( \@validated );

  unless ( $opt{force} ) {
    my @running = grep { ( $_->{state} // '' ) eq 'running' } $self->steps;
    user_error( 'The chain still has ' . @running . ' running step(s) ('
      . join( ', ', map { $_->{id} } @running )
      . '); pass force to replace it anyway' ) if @running;
  }

  return \@validated;
}

# What a chain document may say beside its steps. Closed, where the per-step
# key list is not: a step's on_* policies are the runner's open vocabulary,
# while a document header has exactly these, and an agent that misspells one is
# better told than warned -- a chain written with a 'limit:' typo would run at
# the wrong concurrency and look perfectly healthy doing it.
my %DOCUMENT_KEY = map { $_ => 1 } qw( steps limits note planner );


sub parse_chain_document {
  my ( $self, $doc ) = @_;
  user_error( 'A chain document is a list of steps, or a mapping with a '
    . "'steps:' list in it" )
    unless ref $doc eq 'ARRAY' || ref $doc eq 'HASH';

  return ( $doc ) if ref $doc eq 'ARRAY';

  for my $key ( sort keys %$doc ) {
    next if $DOCUMENT_KEY{$key};
    user_error( "A chain document has no '$key' key (it takes: "
      . join( ', ', sort keys %DOCUMENT_KEY ) . ')'
      . ( $key eq 'force'
          ? '; replacing a chain that is still running is --force on the '
            . 'command line, not something the plan grants itself'
          : '' ) );
  }

  my $steps = $doc->{steps};
  user_error("A chain document needs a 'steps:' list") unless defined $steps;
  user_error("A chain document's 'steps:' must be a list of steps")
    unless ref $steps eq 'ARRAY';

  my %opt;
  if ( defined $doc->{limits} ) {
    user_error( "A chain document's 'limits:' must be a mapping, for example "
      . "'concurrent: 4'" ) unless ref $doc->{limits} eq 'HASH';
    $opt{limits} = $doc->{limits};
  }
  for my $key ( qw( note planner ) ) {
    next unless defined $doc->{$key};
    user_error("A chain document's '$key:' must be a plain value")
      if ref $doc->{$key};
    $opt{$key} = $doc->{$key};
  }
  return ( $steps, %opt );
}

# Kahn's algorithm, run for its refusal rather than for its order: a chain
# whose steps cannot all be peeled off has a cycle, and a cycle is a chain
# where nothing ever becomes ready.
sub _refuse_cycle {
  my ( $steps ) = @_;
  my %pending = map { $_->{id} => { map { $_ => 1 } @{ $_->{needs} || [] } } } @$steps;
  my $moved = 1;
  while ( $moved ) {
    $moved = 0;
    for my $id ( sort keys %pending ) {
      next if grep { $pending{$_} } keys %{ $pending{$id} };
      delete $pending{$id};
      $moved = 1;
    }
  }
  user_error( 'The chain has a cycle through step(s) '
    . join( ', ', sort keys %pending ) ) if %pending;
  return;
}

sub _new_chain_id {
  return strftime( '%Y%m%dT%H%M%SZ', gmtime() ) . '-'
    . substr( md5_hex( $$, time, rand ), 0, 6 );
}


sub header {
  my ( $self ) = @_;
  return $self->_read_yaml( CHAIN_META, 'chain header' ) // {};
}


sub steps {
  my ( $self ) = @_;
  my @steps;
  for my $ref ( $self->git->list_refs(STEP_ROOT) ) {
    my $id = substr $ref, length STEP_ROOT;
    next unless _valid_id($id);
    my $step = $self->_read_yaml( $ref, "chain step '$id'" ) or next;
    push @steps, _as_step( $step, $id );
  }
  # Assigned before it is returned: sort() in scalar context is undefined
  # behaviour, and a caller asking how many steps there are is ordinary.
  my @sorted = sort { _id_sort_key( $a->{id} ) cmp _id_sort_key( $b->{id} ) } @steps;
  return @sorted;
}

# What a step ref holds, as the rest of this class expects to see it: the id
# filled in from the ref name it was found under, and needs always a list. A
# ref written by hand may spell a one-element needs as a scalar, and every
# reader here dereferences it -- normalising once on the way in is cheaper than
# guarding at each of them.
sub _as_step {
  my ( $step, $id ) = @_;
  $step->{id} //= "$id";
  my $needs = $step->{needs};
  $step->{needs} = ref $needs eq 'ARRAY' ? $needs
                 : ( defined $needs && length "$needs" ? [ $needs ] : [] );
  return $step;
}

# A total order over ids that are usually numbers and occasionally not: pad
# the numbers so they sort among themselves numerically, and leave names to
# sort after them (digits sort before letters).
sub _id_sort_key {
  my ( $id ) = @_;
  $id = defined $id ? "$id" : '';
  return $id =~ /\A[0-9]+\z/ ? sprintf( '%020d', $id ) : "~$id";
}


sub step {
  my ( $self, $id ) = @_;
  return undef unless _valid_id($id);
  my $step = $self->_read_yaml( $self->_step_ref($id), "chain step '$id'" )
    or return undef;
  return _as_step( $step, $id );
}


sub update_step {
  my ( $self, $id, $code ) = @_;
  return undef unless _valid_id($id);
  my $ref = $self->_step_ref($id);

  # retry_contended reads an empty return as "lost the race, read again"; a
  # one-element (undef) return is a committed answer and comes back as undef.
  return scalar $self->git->retry_contended( "chain step $id", sub {
    my ( $oid, $content ) = $self->git->read_ref_with_oid($ref);
    return undef unless defined $oid;
    my $step = $self->_decode_yaml( $content, "chain step '$id'" ) or return undef;
    $step = _as_step( $step, $id );

    my $updated = $code->($step);
    return undef unless ref $updated eq 'HASH';
    my $valid = $self->_validate_step($updated);
    user_error("Chain step '$id' cannot be renamed to '$valid->{id}'")
      unless $valid->{id} eq "$id";

    return $self->git->write_ref_cas( $ref, yaml_dump($valid), $oid )
      ? $valid : ();
  } );
}


sub mark_stale {
  my ( $self, $id, $reason ) = @_;
  return $self->update_step( $id, sub {
    my ( $step ) = @_;
    return undef if ( $step->{state} // 'pending' ) eq 'stale';
    $step->{state}    = 'stale';
    $step->{stale_at} = _now();
    if ( defined $reason && length $reason ) { $step->{stale_reason} = $reason }
    else                                     { delete $step->{stale_reason} }
    return $step;
  } );
}


sub ready_steps {
  my ( $self ) = @_;
  my $chain = $self->header->{id};
  return () unless defined $chain;

  my @steps = grep { ( $_->{chain} // '' ) eq $chain } $self->steps;
  my %state = map { $_->{id} => ( $_->{state} // 'pending' ) } @steps;
  return grep {
    my $step = $_;
    ( $state{ $step->{id} } eq 'pending' )
      && !grep { ( $state{$_} // '' ) ne 'done' } @{ $step->{needs} || [] };
  } @steps;
}


sub clear_chain {
  my ( $self ) = @_;
  my $removed = $self->git->delete_ref(CHAIN_META) ? 1 : 0;
  return $removed + $self->_clear_steps;
}

sub _clear_steps {
  my ( $self ) = @_;
  my $removed = 0;
  for my $ref ( $self->git->list_refs(STEP_ROOT) ) {
    $removed += $self->git->delete_ref($ref) ? 1 : 0;
  }
  return $removed;
}

# ---------------------------------------------------------------------------
# Prechecks
# ---------------------------------------------------------------------------


sub parse_precheck {
  my ( $self, $expr, $what ) = @_;
  return undef unless defined $expr && $expr =~ /\S/;
  $what ||= 'Precheck';
  user_error("$what: a precheck must be an expression, not a structure")
    if ref $expr;

  my ( $fact, $op, $value ) =
    "$expr" =~ /\A\s*([A-Za-z_][A-Za-z0-9_.]*)\s*(==|!=)\s*(.+?)\s*\z/
    or user_error("$what: cannot read precheck '$expr' "
      . '(expected: <fact> == <value>, or !=)');
  $value =~ s/\A(['"])(.*)\1\z/$2/s;
  return { fact => $fact, op => $op, value => $value };
}


sub precheck_holds {
  my ( $self, $step, $facts ) = @_;
  my $p = $self->parse_precheck( ref $step eq 'HASH' ? $step->{precheck} : $step )
    or return 1;
  my $have = ref $facts eq 'HASH' ? $facts->{ $p->{fact} } : undef;
  return 0 unless defined $have;
  return $p->{op} eq '==' ? ( "$have" eq $p->{value} ? 1 : 0 )
                          : ( "$have" ne $p->{value} ? 1 : 0 );
}

# ---------------------------------------------------------------------------
# Run logs
# ---------------------------------------------------------------------------


has segment_max_bytes => (
  is      => 'ro',
  default => sub { SEGMENT_MAX_BYTES },
);


has keep_days => (
  is      => 'ro',
  default => sub { KEEP_DAYS },
);


has keep_runs => (
  is      => 'ro',
  default => sub { KEEP_RUNS },
);


has auto_prune => (
  is      => 'ro',
  default => sub { 1 },
);


sub new_run_id {
  my ( $self ) = @_;
  # One gmtime call, not two: a run minted in the last second of a day would
  # otherwise take its date from before midnight and its time from after.
  return strftime( '%Y-%m-%d-%H%M%S', gmtime() )
    . substr( md5_hex( $$, time, rand ), 0, 6 );
}

sub _valid_run {
  my ( $run ) = @_;
  return defined $run && "$run" =~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9A-Za-z_]+\z/;
}

sub _run_base { return LOG_ROOT . $_[1] }

# The segment refs of one run, oldest first. The glob is the base name, so it
# also catches a run whose name merely starts with this one's; the anchored
# regex is what makes the match exact.
sub _run_segments {
  my ( $self, $run ) = @_;
  my $base = $self->_run_base($run);
  my %index;
  for my $ref ( $self->git->list_refs($base) ) {
    $index{$ref} = ( $1 // 0 ) + 0 if $ref =~ /\A\Q$base\E(?:\+([0-9]+))?\z/;
  }
  my @sorted = sort { $index{$a} <=> $index{$b} } keys %index;
  return @sorted;
}


sub log_run {
  my ( $self, $run, %entry ) = @_;
  user_error("'$run' is not a run name (expected <date>-<id>)")
    unless _valid_run($run);
  my $base = $self->_run_base($run);

  $self->prune_logs if $self->auto_prune && !$self->git->ref_exists($base);

  $entry{ts} //= _now();
  my $line = json_encode( \%entry );

  return try {
    $self->git->retry_contended( "run log $run", sub {
      my @segments = $self->_run_segments($run);
      my $segment  = @segments ? $segments[-1] : $base;
      my ( $oid, $content ) = @segments
        ? $self->git->read_ref_with_oid($segment) : ( undef, '' );
      $content //= '';

      # Rotate before the append, never after: no segment is written past the
      # cap, no entry is written twice, and a full segment is left alone from
      # then on. The next segment is opened with expected_old => undef, so two
      # writers rotating at once cannot clobber one another -- the loser
      # re-reads and appends to the segment the winner opened.
      if ( length($content)
        && length($content) + 1 + length($line) > $self->segment_max_bytes )
      {
        my ( $index ) = $segment =~ /\+([0-9]+)\z/;
        $segment = sprintf( '%s+%06d', $base, ( $index // 0 ) + 1 );
        ( $oid, $content ) = ( undef, '' );
      }

      my $new = length $content ? "$content\n$line" : $line;
      return $self->git->write_ref_cas( $segment, $new, $oid ) ? 1 : ();
    } );
  } catch {
    warn "karr-foundation: run log write to '$base' failed: " . clean_error($_) . "\n";
    0;
  };
}


sub run_ids {
  my ( $self ) = @_;
  my %run;
  for my $ref ( $self->git->list_refs(LOG_ROOT) ) {
    my $name = substr $ref, length LOG_ROOT;
    $name =~ s/\+[0-9]+\z//;
    $run{$name} = 1 if _valid_run($name);
  }
  my @runs = sort keys %run;
  return @runs;
}


sub run_entries {
  my ( $self, $run ) = @_;
  return () unless _valid_run($run);
  my @entries;
  for my $ref ( $self->_run_segments($run) ) {
    my $content = $self->git->read_ref($ref);
    next unless defined $content && length $content;
    for my $line ( split /\n/, $content ) {
      next unless length $line;
      my $decoded = try { json_decode($line) } catch { undef };
      push @entries, $decoded if $decoded;
    }
  }
  return @entries;
}


sub prune_logs {
  my ( $self, %opt ) = @_;
  my $keep_days = defined $opt{keep_days} ? $opt{keep_days} : $self->keep_days;
  my $keep_runs = defined $opt{keep_runs} ? $opt{keep_runs} : $self->keep_runs;

  my @runs = $self->run_ids;
  my %doomed;
  if ( $keep_days ) {
    my $cutoff = strftime( '%Y-%m-%d', gmtime( time - $keep_days * 86400 ) );
    $doomed{$_} = 1 for grep { substr( $_, 0, 10 ) lt $cutoff } @runs;
  }
  if ( $keep_runs && @runs > $keep_runs ) {
    $doomed{$_} = 1 for @runs[ 0 .. $#runs - $keep_runs ];
  }

  my @gone;
  for my $run ( sort keys %doomed ) {
    $self->git->delete_ref($_) for $self->_run_segments($run);
    push @gone, $run;
  }
  return @gone;
}

# ---------------------------------------------------------------------------
# Reading refs
# ---------------------------------------------------------------------------

sub _read_yaml {
  my ( $self, $ref, $what ) = @_;
  my $content = $self->git->read_ref($ref);
  return undef unless defined $content && length $content;
  return $self->_decode_yaml( $content, $what );
}

# A ref that does not parse is skipped with a warning rather than dying: one
# hand-edited step must not make the whole chain unreadable, and the runner's
# answer to a step it cannot see is to leave it alone.
sub _decode_yaml {
  my ( $self, $content, $what ) = @_;
  my $data = try { yaml_load($content) } catch {
    warn "karr-foundation: cannot read $what: " . clean_error($_) . "\n";
    undef;
  };
  return ref $data eq 'HASH' ? $data : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::ChainStore - karr-foundation chain and run-log storage under refs/karr-foundation/*

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    use App::karr::Foundation::ChainStore;

    my $chain = App::karr::Foundation::ChainStore->new(
        git => App::karr::Git->new( dir => $hub_repo ) );

    $chain->write_chain( [
        { id => 1, kind => 'ticket', repo => '/srv/karr',  ticket => 41 },
        { id => 2, kind => 'ticket', repo => '/srv/other', ticket => 12 },
        { id => 3, kind => 'plan',   needs => [ 1, 2 ],
          precheck => 'ticket_status == todo', on_stall => 'plan' },
    ], limits => { concurrent => 4 } );

    my @now = $chain->ready_steps;          # steps 1 and 2, concurrently

=head1 DESCRIPTION

The shared half of C<karr-foundation>'s fleet execution: the planned chain of
steps and the log of the runs that worked through it. Both live in git refs
under C<refs/karr-foundation/>, so every machine and every person sees the same
picture.

    refs/karr-foundation/chain/meta         the chain header (YAML)
    refs/karr-foundation/chain/step/<id>    one step (YAML)
    refs/karr-foundation/log/<date>-<id>    one run's log (JSON lines)

What does B<not> live here is just as deliberate. Which agent commands exist on
this machine, whether they currently work and when to try them again is
execution, it is local, and it belongs to
L<App::karr::Foundation::Agents> and F<agents.state>. That is why B<a step names
no agent> and why passing one is refused rather than ignored: a chain is shared
state, an agent is a property of a machine, and a chain that named one would
plan work that cannot run anywhere else.

A chain gets in through C<karr-foundation plan>, which reads one YAML or JSON
document and hands it to L</parse_chain_document> and L</write_chain> -- the
same path a Perl caller takes, and the only way in: C<karr set-refs> refuses
this namespace outright, because a schema, a cycle check and compare-and-swap
updates are not things a generic ref writer can honour.

=head2 The chain is a DAG

A step lists the step ids it C<needs>. Steps with no edge between them may run
concurrently, which is how the planner expresses parallelism: it leaves edges
out rather than serialising by hand. L</ready_steps> is the whole query -- the
pending steps whose needs are all C<done> -- and the runner (#186) is what turns
that into processes.

Cycles are refused at L</write_chain>, not discovered at run time: a chain with
a cycle has steps that can never become ready, and a store that accepted one
would answer "nothing to do" forever while looking healthy.

=head2 A stale precheck costs time, not correctness

A step may carry a C<precheck> -- C<ticket_status == todo> -- which is the
condition the planner assumed when it wrote the step. A step whose precheck no
longer holds is not executed: it is marked stale (L</mark_stale>) and the
planner is called again. This is what stops a chain that has gone out of date
from doing damage, and it is why an unreadable precheck (an unknown fact, a
missing fact) counts as B<not holding> -- every uncertainty falls to the side
that costs a planning round rather than the side that runs the wrong thing.

=head2 Run logs are segmented, like the activity log

C<refs/karr-foundation/log/E<lt>dateE<gt>-E<lt>idE<gt>> is one ref per run, and
an entry is appended to the newest segment of that ref until it reaches
L</segment_max_bytes>; the next entry opens
C<...E<lt>runE<gt>+000001>. A ref holds a blob and a blob is rewritten whole on
every append, so an uncapped log ref makes each entry cost a copy of the entire
history -- quadratic, and measured at about 4.6 GB of objects for a 1 MB log
(#171, L<App::karr::ActivityLog/Segments>). The C<+NNNNNN> spelling is
deliberately the same one the activity log uses; this store keeps its own copy
of the mechanism rather than sharing one, because the activity log's version is
tangled up with identity encoding and pre-#75 ref names that have no meaning
here.

Retention is the other half of that bound: L</prune_logs> drops runs older than
L</keep_days> and, whatever their age, everything past the newest L</keep_runs>.
It runs by itself when a run log is opened (L</auto_prune>), because a retention
policy that only runs when somebody types a command bounds nothing.

=head1 SEE ALSO

L<App::karr::Foundation>, L<App::karr::Foundation::Agents>,
L<App::karr::ActivityLog>, L<App::karr::Git>

=head2 git

The L<App::karr::Git> for the hub repository that carries the fleet namespace.
Required.

=head2 write_chain

    my $chain_id = $store->write_chain( \@steps, %opt );

Replaces the chain with C<@steps> and returns the new chain id. Options are
C<limits> (passed through to the header untouched -- what a limit means is the
runner's business), C<note>, C<planner>, and C<force>.

Every step is validated first (L</validate_chain>): anything wrong with the
chain raises a user error and B<nothing is written>.

The header ref is written B<last> and is the commit point: L</ready_steps> only
considers steps whose C<chain> matches the header, so a reader that arrives
half-way through a replacement sees the chain it saw before, then the new one,
and never a mixture. Both C<meta> and the step refs are separate refs, so this
is not a git-level atomic switch -- the window is one where nothing is ready,
not one where the wrong thing runs.

=head2 validate_chain

    my $steps = $store->validate_chain( \@steps, %opt );

Everything L</write_chain> checks before it writes a ref, and no ref written:
every step against the step schema, ids unique, every C<needs> entry naming a
step of the same chain, the graph acyclic, and -- unless C<force> is passed --
no step of the chain still in state C<running>. Returns the validated steps,
which are normalised copies rather than the caller's own hashes; anything else
raises a user error.

Split out of L</write_chain> because C<karr-foundation plan --dry-run> has to
be able to say "this chain is good" without writing it, and a dry run checking
a chain from its own copy of the rules would be a second opinion rather than
the same one.

=head2 parse_chain_document

    my ( $steps, %header ) = $store->parse_chain_document( $document );

Takes the decoded document C<karr-foundation plan> reads -- YAML or JSON, and
JSON only because a YAML parser reads it -- and returns the two arguments
L</write_chain> takes: the step list, and the header options C<limits>, C<note>
and C<planner>.

Two spellings are accepted, because both say the same thing: a mapping with a
C<steps:> list and the header keys beside it, or a bare list, which B<is> the
step list. The second is what L</write_chain>'s own first argument looks like,
so a planner writing only steps has written a whole document.

No step is looked at here -- that is L</validate_chain>, which the write path
runs whatever route the steps arrived by. What this checks is the envelope:
the document is one of the two shapes, C<steps:> is there and is a list,
C<limits:> is a mapping, C<note:> and C<planner:> are plain values, and no
other key is present. C<force> is deliberately not among them: replacing a
chain that still has a running step is a decision the caller makes on the
command line, not one the plan grants itself.

=head2 header

    my $header = $store->header;   # { id => ..., created => ..., limits => ... }

The chain header, or C<{}> when no chain is written. C<limits> comes back
exactly as it was handed in.

=head2 steps

    my @steps = $store->steps;

Every step ref that exists, oldest chain generation included, sorted by id
(numeric ids numerically, before named ones). Deliberately unfiltered so a
half-written or superseded chain can still be looked at; L</ready_steps> is
where the header decides what may actually run.

=head2 step

    my $step = $store->step($id);

One step, or C<undef> when there is no such ref.

=head2 update_step

    my $new = $store->update_step( $id, sub {
        my ($step) = @_;
        return undef unless ( $step->{state} // 'pending' ) eq 'pending';
        $step->{state} = 'running';
        return $step;
    } );

Read-modify-write on one step, compare-and-swap guarded. The callback receives
the step as it is on the ref and returns the step to write, or C<undef> to
decline. Returns the written step, or C<undef> when the step does not exist or
the callback declined.

The guard is what makes this usable from more than one foundation tick: two
callers that both read C<pending> do not both write C<running>: the loser's
write is refused, the callback is called again with what the winner left
behind, and it declines. That is the whole exclusion mechanism for a
concurrent runner, and it is the board's own (L<App::karr::Git/retry_contended>,
L<App::karr::Git/write_ref_cas>) rather than a second one.

The step handed to the callback carries the C<chain> it was written for, so a
caller that has been away long enough for the planner to replace the chain can
see that and decline.

=head2 mark_stale

    $store->mark_stale( $id, 'ticket 41 is no longer todo' );

Marks a step stale: its precheck no longer holds, so it must not be executed.
Records the reason and when. Returns the updated step, or C<undef> when the
step is gone or was already stale.

Calling the planner afterwards is the runner's move, not this store's -- what
is stored here is the fact, so that the next tick, on another machine, sees the
same one.

=head2 ready_steps

    my @ready = $store->ready_steps;

The steps of the current chain that may run right now: state C<pending>, and
every step they C<need> in state C<done>. They may all run at once -- that is
what the missing edges mean.

Only steps whose C<chain> matches L</header> are considered, so a chain with no
header, or the leftovers of one being replaced, is never run.

=head2 clear_chain

    my $removed = $store->clear_chain;

Removes the header and every step ref, and returns how many refs went. The
header goes first, so a reader in between finds a chain that is not ready
rather than one that is half there.

=head2 parse_precheck

    my $p = $store->parse_precheck('ticket_status == todo');
    # { fact => 'ticket_status', op => '==', value => 'todo' }

Reads a precheck expression. C<undef> or blank yields C<undef> -- a step
without a precheck has nothing to go stale on. Anything else must be
C<< <fact> == <value> >> or C<< <fact> != <value> >>, with the value optionally
quoted; a value that cannot be read raises a user error, which is why
L</write_chain> parses every precheck before it writes anything.

Which facts exist is not enumerated here on purpose: this store knows the
grammar, the runner (#186) knows what it can measure, and a fact this store had
to be taught about would put half of one decision in two places.

=head2 precheck_holds

    my $ok = $store->precheck_holds( $step, { ticket_status => 'todo' } );

True when the step's precheck still holds against the facts it is handed, and
true for a step that has none. The caller supplies the facts because measuring
them means reading a board, which is execution.

A fact the caller did not supply makes the precheck B<not> hold, whichever
operator it uses. There is no reading of C<!=> under which "I could not find
out" should let a step run: an unanswerable precheck is exactly the case this
mechanism exists for, and marking the step stale costs a planning round, while
running it costs whatever the step does.

=head2 segment_max_bytes

How large a run-log segment may grow before the next entry opens the following
one; 8192 by default, the same cap and the same reason as
L<App::karr::ActivityLog/segment_max_bytes>. Set explicitly only by tests,
which have to see a rotation without writing thousands of entries.

=head2 keep_days

How many days of run logs L</prune_logs> keeps; 14 by default. C<0> means no
age limit, the same spelling C<max_turns> and C<max_runtime> use for "no limit".

=head2 keep_runs

How many run logs L</prune_logs> keeps regardless of age, newest first; 500 by
default, C<0> for no ceiling. This is the one that actually bounds the
namespace: a fleet busy enough to matter fills two weeks with more refs than
anyone wants to fetch.

=head2 auto_prune

Whether opening a new run log prunes the old ones first; true by default. Once
per run is cheap (one ref listing) and it is the only moment at which the
namespace grows, so retention that hangs off it cannot be forgotten.

=head2 new_run_id

    my $run = $store->new_run_id;   # "2026-08-17-142530a3f91c"

Mints a run name: the UTC date, then the UTC time and six random hex digits.
The date leads so the refs sort chronologically, which is what makes retention
a matter of looking at the front of a sorted list.

=head2 log_run

    $store->log_run( $run, event => 'step', step => 3, detail => 'done' );

Appends one JSON entry to a run's log, timestamping it unless C<ts> is given.
Returns 1 when the entry landed and 0 after a warning when it could not: a run
log records what already happened, so failing to write it must not take the run
down with it -- the same rule L<App::karr::ActivityLog/log_entry> follows. A
C<$run> that is not a run name is the exception, and raises: that is a caller
mistake, not a write that failed.

The append is compare-and-swap guarded against the newest segment, re-resolved
on every attempt, so two writers cannot lose each other's entries and a rotation
is just another lost race. Opening a run (the first entry) prunes old runs first
when L</auto_prune> is set.

=head2 run_ids

    my @runs = $store->run_ids;

Every run that has a log, oldest first -- which is plain lexical order, because
the name starts with the date. Segments are folded back into the run they
belong to.

=head2 run_entries

    my @entries = $store->run_entries($run);

The decoded entries of one run, oldest first, read across every segment.

=head2 prune_logs

    my @gone = $store->prune_logs;                      # the configured policy
    my @gone = $store->prune_logs( keep_days => 2 );    # or an explicit one

Drops the run logs the retention policy no longer keeps -- everything older
than L</keep_days>, plus everything past the newest L</keep_runs> -- and
returns the run names it removed. Every segment of a removed run goes.

Deleting these refs leaves no tombstone: L<App::karr::Git/delete_ref> only
records those for C<refs/karr/*>, so a pruned run is gone locally and stays on
the remote until the sync of this namespace (#190) says otherwise.

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
