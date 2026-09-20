# ABSTRACT: karr-foundation question mailbox under refs/karr-foundation/questions/*

package App::karr::Foundation::Questions;
our $VERSION = '0.601';
use Moo;
use POSIX qw( strftime );
use Try::Tiny;
use App::karr::Error qw( user_error clean_error );
use App::karr::Encoding qw( yaml_dump yaml_load );



has git => (
  is       => 'ro',
  required => 1,
);

use constant QUESTION_ROOT => 'refs/karr-foundation/questions/';

# How long an answered question is kept. Days rather than a count, unlike the
# run logs: what bounds this namespace is that questions are asked by people
# and about people, not minted by every step of every run.
use constant KEEP_ANSWERED_DAYS => 30;

# How many ids a mint may walk past before it gives up. Every attempt means
# another writer took that id between this one's read and its write, so a
# handful is already generous -- and unbounded would mean a wedged ref turns
# into a loop nobody can see.
use constant MINT_ATTEMPTS => 16;

my %POLICY = map { $_ => 1 } qw( block use_default escalate_to_ai );

my %QUESTION_KEY = map { $_ => 1 } qw(
  id question context options default policy deadline step asked asked_by
);

my %ANSWER_KEY = map { $_ => 1 } qw(
  id question answer note answered answered_by
);

sub _now { return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime() ) }

# Ids are minted, never given, so this is narrow on purpose: a positive decimal
# with no leading zero, which is one ref component and reads back as itself.
sub _valid_id { return defined $_[0] && "$_[0]" =~ /\A[1-9][0-9]*\z/ }

# Two leaves under the id rather than one ref per question with a sibling
# suffix: git cannot hold refs/.../7 and refs/.../7/answer at the same time
# (a ref is a file and a directory would have to be the same name), so the id
# is the directory and both halves are leaves under it.
sub _ask_ref    { return QUESTION_ROOT . $_[1] . '/ask' }
sub _answer_ref { return QUESTION_ROOT . $_[1] . '/answer' }


has keep_answered_days => (
  is      => 'ro',
  default => sub { KEEP_ANSWERED_DAYS },
);


has auto_prune => (
  is      => 'ro',
  default => sub { 1 },
);

# ---------------------------------------------------------------------------
# Asking
# ---------------------------------------------------------------------------

sub _validate_question {
  my ( $self, $q ) = @_;
  user_error('A question must be a mapping') unless ref $q eq 'HASH';
  my %s = %$q;

  user_error('A question needs a question to ask')
    unless defined $s{question} && !ref $s{question} && $s{question} =~ /\S/;
  $s{question} = "$s{question}";

  for my $key ( qw( context step ) ) {
    next unless defined $s{$key};
    user_error("A question's $key must be a plain value") if ref $s{$key};
    delete $s{$key} unless length "$s{$key}";
  }

  # The same latitude the board's frontmatter and a chain step's `needs` give:
  # YAML writes a one-element list as a scalar often enough that refusing one
  # would be pedantry.
  if ( defined $s{options} ) {
    my $options = ref $s{options} ? $s{options} : [ $s{options} ];
    user_error("A question's options must be a list of answers")
      unless ref $options eq 'ARRAY';
    my @options;
    for my $o ( @$options ) {
      user_error("A question's options must be a list of answers")
        if ref $o || !defined $o || !length "$o";
      push @options, "$o";
    }
    if ( @options ) { $s{options} = \@options }
    else            { delete $s{options} }
  }

  if ( defined $s{default} ) {
    user_error("A question's default must be a plain value") if ref $s{default};
    $s{default} = "$s{default}";
    delete $s{default} unless length $s{default};
  }
  if ( defined $s{default} && $s{options} ) {
    user_error("The default '$s{default}' is not one of its options ("
      . join( ', ', @{ $s{options} } ) . ')')
      unless grep { $_ eq $s{default} } @{ $s{options} };
  }

  if ( defined $s{deadline} ) {
    user_error("A question's deadline must be a UTC stamp like "
      . _now() . ", not '$s{deadline}'")
      if ref $s{deadline}
      || "$s{deadline}" !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\z/;
    $s{deadline} = "$s{deadline}";
  }

  my $policy = $s{policy} // 'block';
  user_error("A question has unknown policy '$policy' (expected: "
    . join( ', ', sort keys %POLICY ) . ')')
    unless !ref $policy && $POLICY{$policy};
  $s{policy} = $policy;

  # Both of these are the same mistake seen from two sides: a question that
  # cannot be answered by the time it resolves. Refused here, where a planner
  # still hears about it, rather than in a runner that would quietly take the
  # fallback on the tick after it was asked.
  if ( $policy ne 'block' ) {
    user_error("Policy '$policy' needs a deadline: without one it would "
      . 'resolve the moment the question is asked and nobody could answer it')
      unless defined $s{deadline};
  }
  user_error("Policy 'use_default' needs a default to fall back on")
    if $policy eq 'use_default' && !defined $s{default};

  for my $key ( sort keys %s ) {
    next if $QUESTION_KEY{$key};
    warn "karr-foundation: question: unknown key '$key'\n";
  }
  return \%s;
}


sub ask {
  my ( $self, %arg ) = @_;

  my $wait = delete $arg{wait};
  if ( defined $wait ) {
    user_error("A question's wait and its deadline are two spellings of one "
      . 'thing; pass one of them') if defined $arg{deadline};
    user_error("A question's wait must be a whole number of seconds, not '$wait'")
      if ref $wait || "$wait" !~ /\A[0-9]+\z/;
    user_error('A question that waits no time at all cannot be answered by '
      . 'anybody') unless $wait > 0;
    $arg{deadline} = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( time + $wait ) );
  }

  $arg{asked} //= _now();
  my $who = $self->git->git_user_identity;
  $arg{asked_by} //= $who if length $who;

  my $question = $self->_validate_question( \%arg );

  # Before the write, never after: the only moment this namespace grows is the
  # one below, so a retention policy hung anywhere else bounds nothing.
  $self->prune_questions if $self->auto_prune;

  my $id = $self->_next_id;
  for ( 1 .. MINT_ATTEMPTS ) {
    $question->{id} = $id + 0;
    return $id
      if $self->git->write_ref_cas( $self->_ask_ref($id), yaml_dump($question), undef );
    $id++;
  }
  user_error( 'Could not find a free question id after ' . MINT_ATTEMPTS
    . " tries (last tried #$id)" );
}

# One past the highest id the mailbox has, answer refs included: an answer left
# behind by an interrupted delete still holds its id, and handing that id to a
# new question would pair the two.
sub _next_id {
  my ( $self ) = @_;
  my $next = 1;
  for my $id ( $self->ids ) { $next = $id + 1 if $id >= $next }
  return $next;
}


sub ids {
  my ( $self ) = @_;
  my %id;
  for my $ref ( $self->git->list_refs(QUESTION_ROOT) ) {
    my ( $id ) = substr( $ref, length QUESTION_ROOT ) =~ m{\A([^/]+)/(?:ask|answer)\z};
    $id{$id} = 1 if _valid_id($id);
  }
  my @ids = sort { $a <=> $b } keys %id;
  return @ids;
}


sub question {
  my ( $self, $id ) = @_;
  return undef unless _valid_id($id);
  my $q = $self->_read_yaml( $self->_ask_ref($id), "question #$id" ) or return undef;
  $q->{id} //= $id + 0;
  return $q;
}


sub questions {
  my ( $self ) = @_;
  return grep { defined } map { $self->question($_) } $self->ids;
}


sub open_questions {
  my ( $self ) = @_;
  return grep {
    my $r = $self->resolve($_);
    $r && $r->{state} ne 'answered';
  } $self->questions;
}

# ---------------------------------------------------------------------------
# Answering
# ---------------------------------------------------------------------------


sub answer {
  my ( $self, $id ) = @_;
  return undef unless _valid_id($id);
  return $self->_read_yaml( $self->_answer_ref($id), "answer to question #$id" );
}


sub settle {
  my ( $self, $id, $value, %opt ) = @_;
  user_error("'" . ( defined $id ? $id : '' ) . "' is not a question id")
    unless _valid_id($id);
  my $q = $self->question($id)
    or user_error("No question #$id is in the mailbox");

  user_error("An answer cannot be empty")
    unless defined $value && !ref $value && length "$value";
  $value = "$value";

  if ( my $options = $q->{options} ) {
    user_error("Question #$id offers " . join( ', ', @$options )
      . " (got '$value'); pass force to answer it with something else")
      unless $opt{force} || grep { $_ eq $value } @$options;
  }

  my $existing = $self->answer($id);
  user_error("Question #$id was already answered '$existing->{answer}'"
    . ( defined $existing->{answered} ? " at $existing->{answered}" : '' )
    . '; pass force to replace that answer')
    if $existing && !$opt{force} && $self->_answers( $q, $existing );

  my %a = (
    id       => $id + 0,
    question => $q->{question},
    answer   => $value,
    answered => _now(),
  );
  my $who = $self->git->git_user_identity;
  $a{answered_by} = $who if length $who;
  $a{note} = "$opt{note}" if defined $opt{note} && !ref $opt{note} && length $opt{note};

  for my $key ( sort keys %a ) {
    next if $ANSWER_KEY{$key};
    warn "karr-foundation: answer to question #$id: unknown key '$key'\n";
  }

  my $ref = $self->_answer_ref($id);
  if ( $existing || $opt{force} ) {
    $self->git->write_ref( $ref, yaml_dump( \%a ) )
      or user_error("Could not write the answer to question #$id");
  }
  else {
    $self->git->write_ref_cas( $ref, yaml_dump( \%a ), undef )
      or user_error("Question #$id was answered by somebody else just now");
  }
  return \%a;
}

# An answer belongs to the question standing beside it only if it says so. See
# "An answer names the question it answers" above: without this, two clones
# that minted the same id leave an answer attached to a question it was never
# given, and nothing about that looks wrong from the outside.
sub _answers {
  my ( $self, $q, $a ) = @_;
  return 0 unless ref $q eq 'HASH' && ref $a eq 'HASH';
  return 0 unless defined $a->{question} && defined $q->{question};
  return $a->{question} eq $q->{question} ? 1 : 0;
}


sub resolve {
  my ( $self, $id ) = @_;
  my $q = ref $id eq 'HASH' ? $id : $self->question($id) or return undef;
  $id = $q->{id};

  my $a = $self->answer($id);
  if ( $a && !$self->_answers( $q, $a ) ) {
    warn "karr-foundation: the answer stored under question #$id answers a "
       . "different question ('" . ( $a->{question} // '?' ) . "'); it is ignored\n";
    $a = undef;
  }
  if ( $a ) {
    my %r = ( state => 'answered', answer => $a->{answer} );
    for my $key ( qw( answered answered_by note ) ) {
      $r{$key} = $a->{$key} if defined $a->{$key};
    }
    return \%r;
  }

  my $policy = $q->{policy} // 'block';
  my $overdue = defined $q->{deadline} && "$q->{deadline}" le _now();
  return { state => 'open', policy => $policy } unless $overdue;
  return {
    state  => 'overdue',
    policy => $policy,
    ( $policy eq 'use_default' && defined $q->{default}
      ? ( answer => $q->{default} ) : () ),
  };
}

# ---------------------------------------------------------------------------
# Retention
# ---------------------------------------------------------------------------


sub delete_question {
  my ( $self, $id ) = @_;
  return 0 unless _valid_id($id);
  my $removed = $self->git->delete_ref( $self->_ask_ref($id) ) ? 1 : 0;
  $removed += $self->git->delete_ref( $self->_answer_ref($id) ) ? 1 : 0;
  return $removed;
}


sub prune_questions {
  my ( $self, %opt ) = @_;
  my $keep = defined $opt{keep_days} ? $opt{keep_days} : $self->keep_answered_days;
  return () unless $keep;

  my $cutoff = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( time - $keep * 86400 ) );
  my @gone;
  for my $id ( $self->ids ) {
    my $a = $self->answer($id) or next;
    my $when = $a->{answered};
    next unless defined $when && !ref $when && "$when" lt $cutoff;
    $self->delete_question($id);
    push @gone, $id;
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

App::karr::Foundation::Questions - karr-foundation question mailbox under refs/karr-foundation/questions/*

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    use App::karr::Foundation::Questions;

    my $mailbox = App::karr::Foundation::Questions->new(
        git => App::karr::Git->new( dir => $hub_repo ) );

    my $id = $mailbox->ask(
        question => 'Which registry do we publish to?',
        context  => 'The release gate is waiting on this.',
        options  => [ 'cpan', 'darkpan' ],
        default  => 'cpan',
        policy   => 'use_default',
        wait     => 3600,
    );

    $mailbox->settle( $id, 'darkpan' );        # from anywhere, by anyone
    my $r = $mailbox->resolve($id);            # { state => 'answered', ... }

=head1 DESCRIPTION

A question is a file with an answer field, not a dialogue. That one decision is
what removes the special case for "a human happens to be present": the chain
writes the question down and carries on with everything that does not depend on
it, and whoever answers -- a person at a terminal, a chat bridge, the
coordination agent -- writes into the same mailbox without knowing that a chain
exists at all. One mailbox, many writers.

    refs/karr-foundation/questions/<id>/ask       the question (YAML)
    refs/karr-foundation/questions/<id>/answer    the answer   (YAML)

Both live in the fleet namespace L<App::karr::Foundation::ChainStore> uses, so
C<karr sync> carries them to every machine (#190) and C<karr get-refs> reads
them.

=head2 The answer is its own ref

The question could have carried an C<answer:> field -- that is how the design
document draws it -- and it deliberately does not. C<refs/karr-foundation/*>
resolves a ref that both sides changed by taking the remote's version and B<not>
keeping the local one (L<App::karr::Git/pull_foundation>): a plan that lost a
race is re-planned, not read back, so nothing is parked. An answer is not a
plan. It is somebody's decision, typed once, and re-planning does not
reconstruct it. With the answer in its own ref the asker and the answerer never
write the same ref, so the case cannot arise from the ordinary use of this
mailbox at all; what is left is two people answering the same question at once,
where one answer winning is the right outcome and is decided here rather than by
whoever pushed last (see L</settle>).

The other half of that split is C</ask> being written B<once>. A question is
never rewritten -- L</ask> creates it or takes the next id -- which is what makes
"the two writers never collide" true rather than merely usual.

=head2 An answer names the question it answers

Ids are small integers, minted per clone from the refs that clone can see, so
two clones that both ask something between two syncs mint the same id. The
question that loses is lost (that is the same window the board's task ids have,
and L</ask> narrows it the same way: C<karr-foundation ask> pulls the namespace
first). What must not follow is an answer left standing beside somebody else's
question, so the answer records the question text it was given, and L</resolve>
refuses to pair them when it does not match. Loud, and one string comparison.

The same guard is what lets an id come round again. L</prune_questions> really
removes refs, so the highest id in an emptied mailbox drops, and the next
question takes an id some long-settled one had. The alternative is a counter
ref in a namespace whose conflict rule is "the remote wins", which can move a
counter backwards and would therefore need its own monotonic floor to do what
one string comparison already does.

=head2 Nobody answers

C<policy> says what happens when nobody does: C<block> (wait, the default and
the only one that never invents an answer), C<use_default> (the C<default>
becomes the answer), or C<escalate_to_ai> (the coordination agent decides).
The last two need a C<deadline>, because a policy with no deadline fires the
moment the question is asked and nobody would ever get to answer; C<use_default>
needs a C<default> for the same reason a step needs a repo. Both are refused
where they are written rather than discovered where they are read.

Acting on any of it is the runner's. This class answers what a question
currently resolves to (L</resolve>) and nothing else -- a mailbox does not
execute chains.

=head2 Retention

Deleting a settled question publishes a deletion the same way a pruned run log
does (#190), so a mailbox that grows without bound is a retention decision, not
a sync problem. The decision: B<answered questions age out, open ones never
do>. An open question is work nobody has done yet, whatever its age, and a
mailbox that quietly forgot one would be worse than a large one. L</ask> prunes
before it writes, for the same reason L<App::karr::Foundation::ChainStore>
prunes when a run log is opened -- a retention policy that only runs when
somebody types a command bounds nothing.

=head1 SEE ALSO

L<App::karr::Foundation>, L<App::karr::Foundation::ChainStore>, L<App::karr::Git>

=head2 git

The L<App::karr::Git> for the hub repository that carries the fleet namespace.
Required.

=head2 keep_answered_days

How many days an answered question is kept before L</prune_questions> drops it;
30 by default. C<0> means no age limit, the same spelling C<max_runtime> and
C<keep_days> use for "no limit". Open questions are never dropped, whatever
this says.

=head2 auto_prune

Whether L</ask> prunes before it writes; true by default. Once per question is
cheap and it is the only moment at which the mailbox grows.

=head2 ask

    my $id = $mailbox->ask(
        question => 'Which registry do we publish to?',
        context  => 'prose',            # optional
        options  => [ 'cpan', 'darkpan' ],   # optional
        default  => 'cpan',                  # optional
        policy   => 'use_default',      # block (default) | use_default | escalate_to_ai
        wait     => 3600,               # seconds; or deadline => '<UTC stamp>'
        step     => 12,                 # the chain step waiting on it, optional
    );

Raises a question and returns its id. C<wait> is the relative spelling of
C<deadline> and is what the CLI passes; the stored field is always the absolute
UTC stamp, because the two machines reading it are not the one that wrote it.
Passing both is refused.

The id is minted from the questions this clone can see, and the write is
create-only: a mint that loses the race to another tick takes the next id
instead of overwriting the winner. The runner is concurrent (#186), so that is
an ordinary case rather than a paranoid one.

Everything is validated first, and a refusal writes nothing at all.

=head2 ids

    my @ids = $mailbox->ids;

Every question id in the mailbox, lowest first, whether or not it has been
answered.

=head2 question

    my $q = $mailbox->question($id);

One question as it was asked, or C<undef> when there is no such ref (or it does
not parse -- an unreadable question is skipped with a warning rather than
taking a foundation tick down).

=head2 questions

    my @questions = $mailbox->questions;

Every question, lowest id first.

=head2 open_questions

    my @open = $mailbox->open_questions;

The questions nobody has answered -- L</resolve> state C<open> or C<overdue>,
lowest id first. An overdue question is in here even where its policy already
says what to fall back on: until a step consumes it, a person can still answer
it, and that is the point of the fallback being a policy rather than a deletion.

=head2 answer

    my $a = $mailbox->answer($id);

The answer ref of a question as it stands, or C<undef> when nobody has written
one. Raw: whether it answers B<this> question is L</resolve>'s business.

=head2 settle

    my $a = $mailbox->settle( $id, 'darkpan' );
    my $a = $mailbox->settle( $id, 'darkpan', note => 'why', force => 1 );

Answers a question. Returns the answer that was written.

The answer is checked against the question's C<options> where it has any, and an
empty answer is refused: a mailbox whose answers nobody vetted is a mailbox that
unblocks a step with a typo. C<force> is the way past both, and past the one
refusal that matters more -- a question that already has an answer. Answering is
create-only, so two people answering at once is one answer and one refusal
rather than whichever push happened to land second.

An answer that names a different question is not treated as an answer at all
(see L</resolve>) and is overwritten without C<force>: there is nothing there to
protect.

=head2 resolve

    my $r = $mailbox->resolve($id);
    # { state => 'answered', answer => 'darkpan', answered => ..., answered_by => ... }
    # { state => 'open',     policy => 'block' }
    # { state => 'overdue',  policy => 'use_default', answer => 'cpan' }

What a question currently resolves to, or C<undef> when there is no such
question. C<answered> beats everything, including a deadline that has passed.
C<open> is nobody has answered and there is either no deadline or it has not
passed. C<overdue> is nobody has answered and the deadline has, and then the
C<policy> says what follows: C<use_default> carries the default along as
C<answer>, C<block> and C<escalate_to_ai> carry no answer at all, because
neither of them has one to give.

Doing something about it -- waiting, taking the default, calling the
coordination agent -- is the runner's, not the mailbox's.

=head2 delete_question

    my $removed = $mailbox->delete_question($id);

Removes a question and its answer, and returns how many refs went. The question
goes first: a delete interrupted half-way then leaves an answer nothing reads
(L</resolve> needs a question) which the next prune clears, rather than a
question that looks open and invites a second answer.

The deletion is published like any other in this namespace -- a tombstone and an
explicit delete refspec on the next C<karr sync> (#190), never a pruning push.

=head2 prune_questions

    my @gone = $mailbox->prune_questions;                    # the configured policy
    my @gone = $mailbox->prune_questions( keep_days => 2 );   # or an explicit one

Drops every answered question whose answer is older than L</keep_answered_days>
and returns the ids it removed. An open question is never dropped, and neither
is an answer with no readable timestamp -- the two cases where forgetting costs
somebody their work rather than a stale record.

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
