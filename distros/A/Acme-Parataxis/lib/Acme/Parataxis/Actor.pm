use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';

# An actor is a named or anonymous mailbox behind a single private fiber, with a handler that
# runs at most one message at a time. spawn() builds and starts it (a class-level factory, since
# perlclass instances cannot be assembled by hand); the mailbox is created in ADJUST, the fiber
# and its weak self-capture in _start, so spawn() does the checks and plumbing a factory must.
class Acme::Parataxis::Actor v0.1.1 {
    use Acme::Parataxis qw[fiber];
    use Acme::Parataxis::Channel;
    use Acme::Parataxis::Future;
    use Carp qw[croak];
    our $STOP = \do { my $x = 1 };    # envelope value that tells the loop to shut down gracefully
    field $cap  : param;              # mailbox capacity
    field $code : param;              # the handler: ($self, $value) => result, run for each message
    field $done = 0;                  # set once at teardown
    field $error;                     # what killed the actor, or undef for a graceful stop
    field $fiber;                     # the private fiber the message loop runs on
    field $mailbox;                   # the Channel the messages queue through
    field $name : param = undef;      # the registered name, or undef for an unnamed actor
    field $on_death = [];             # death hooks, fired exactly once at teardown
    field $opts : param;              # the original spawn %opts, so respawn() can reproduce them
    field $stopping = 0;              # set by stop(), refuses new send()s/ask()s
    field $supervised : param;        # a supervised handler crash stops this actor and reports it
    ADJUST {
        $mailbox = Acme::Parataxis::Channel->new( capacity => $cap );
    }

    sub spawn : prototype($\&;$\%) ( $class, $code, $capacity = 16, %opts ) {
        croak 'Actor->spawn() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        croak "Actor->spawn() mailbox capacity must be >= 1 (got $capacity)" unless $capacity >= 1;
        #
        my %unknown = %opts;
        #
        delete @unknown{qw[supervised name]};
        croak 'Actor->spawn(): unknown options: ' . join ', ', sort keys %unknown if %unknown;
        my $name = $opts{name};
        if ( defined $name ) {
            croak 'Actor->spawn(): the name must be a non-empty string' unless !ref $name && length $name;
            my $existing = $Acme::Parataxis::ACTOR_REGISTRY{$name};
            croak "Actor->spawn(): an actor named '$name' is already registered" if $existing && $existing->is_alive;
        }
        my $self = $class->new( code => $code, cap => $capacity, name => $name, supervised => !!$opts{supervised}, opts => \%opts );
        $self->_start;
        return $self;
    }

    # Lives in its own method so the fiber closure only ever reaches the actor through field
    # values captured as lexicals (a perlclass closure cannot touch fields directly). The fiber
    # body captures a weak copy of $self, so a done actor is collectable.
    method _start () {
        my $weak = $self;    # the fiber body captures this weak copy, so a done actor is collectable
        builtin::weaken($weak);
        my $mb  = $mailbox;
        my $srv = $supervised;
        $fiber = fiber {
            my $crash;

            # The loop is guarded so teardown is reached on *every* exit path: an interrupt (a
            # cancellation token or a with_timeout deadline landing on this fiber) thrown from a
            # parked wait inside a handler escapes the loop and must not skip the drain below.
            my $ok = 1;
            my $interrupt;
            try {
                while (1) {
                    my $env = $mb->get;    # Park it here without holding $self
                    my ( $reply, $value ) = @$env;
                    last if defined $value && ref $value && $value == $STOP;
                    #
                    my $actor = $weak;
                    last unless defined $actor;    # Handle was dropped by user
                    my $err = $actor->_dispatch( $reply, $value );
                    if ( defined $err && $srv ) { $crash = $err; last }
                }
            }
            catch ($e) { $ok = 0; $interrupt = $e }
            $crash = $interrupt unless $ok;
            if ( my $actor = $weak ) { $actor->_finish($crash) }
        };
        $Acme::Parataxis::ACTOR_REGISTRY{$name} = $self if defined $name;    # only a spawned actor is registered
        return;
    }

    method _finish ($crash) {
        return if $done;
        $done  = 1;
        $error = $crash if defined $crash;

        # Release any registered name so a dead actor never answers a lookup. The guard (entry still == $self)
        # keeps an older actor's teardown from clobbering a same-named replacement that registered since.
        delete $Acme::Parataxis::ACTOR_REGISTRY{$name} if defined $name && ( $Acme::Parataxis::ACTOR_REGISTRY{$name} // 0 ) == $self;

        # The drain is best effort: a watcher must learn about this death even if an interrupt lands
        # on this fiber mid-teardown, or whoever is waiting for the report waits forever.
        my $msg = defined $crash ? "$crash" : 'actor stopped before this message was handled!';
        try { $self->_fail_queued($msg) } catch ($e) {
            warn "Acme::Parataxis::Actor: drain failed: $e"
        }
        for my $cb ( @{ $on_death // [] } ) {
            try { $cb->( $self, $error ) }
            catch ($e) { warn "Acme::Parataxis::Actor: death hook died: $e" }
        }
        return;
    }

    # Fail every ask still outstanding: whatever sits in the mailbox, plus any sender parked in
    # put() that an earlier take released. Each take frees one mailbox slot, which is what releases
    # a parked sender, so one yield per idle stretch lets a released sender land its envelope before
    # the mailbox is declared empty. Nothing new can arrive meanwhile: done is already set, so
    # _check_alive refuses it, and a sender between that check and the push never yields.
    method _fail_queued ($msg) {
        my $mb   = $mailbox;
        my $idle = 0;
        while ( $idle < 3 ) {
            my ( $ok, $env ) = $mb->try_get;
            if ($ok) {
                $idle = 0;
                my ($reply) = @$env;
                next unless defined $reply;
                next if $reply->is_ready;
                try { $reply->set_error($msg) }
                catch ($e) { warn 'Acme::Parataxis::Actor: failed to fail a queued ask: ' . $e }
                next;
            }
            $idle++;
            Acme::Parataxis->yield if $idle == 1;
        }
        return;
    }

    # Fires exactly once when this actor is gone: $err is what killed it, or undef for a graceful stop. An actor that
    # is already done calls back immediately, so a watcher never has to check.
    method on_death : prototype($&) ($cb) {
        if ($done) { $cb->( $self, $error ); return $self }
        push $on_death->@*, $cb;
        return $self;
    }
    method error () {$error}    # why it died, or undef if it stopped gracefully

    # A fresh, already-running actor with the same handler, mailbox size and options: what a supervisor starts in
    # place of this one. The new actor owns a new mailbox, so asks still outstanding here are failed here rather than
    # answered there.
    method respawn () {
        return ref($self)->spawn( $code, $cap, $opts->%* );
    }

    method _dispatch ( $reply, $value ) {
        my $err;
        my $ok = 1;
        try {
            my $rv = $code->( $self, $value );
            $reply->set_result($rv) if defined $reply;
        }
        catch ($e) {
            $ok  = 0;
            $err = $e;
        }
        if ( !$ok ) {
            if ( defined $reply ) {
                try {
                    $reply->set_error($err);
                }
                catch ($e) {
                }
            }
            elsif ( !$supervised ) {    # a supervised actor reports this death to its supervisor instead
                warn "Acme::Parataxis::Actor: handler died: $err";
            }
        }
        return $err;                    # undef when the handler returned normally; the caller turns it into a crash if supervised
    }

    method send ($value) {
        $self->_check_alive;
        $mailbox->put( [ undef, $value ] );
        return 1;
    }

    method ask ($value) {
        $self->_check_alive;
        my $reply = Acme::Parataxis::Future->new;
        $mailbox->put( [ $reply, $value ] );
        return $reply;
    }

    method stop () {
        return $self if $done || $stopping;
        $stopping = 1;

        # Non-blocking enqueue so DESTROY never yields or parks:
        $mailbox->put_priority( [ undef, $STOP ] );
        return $self;
    }
    method is_alive () { return !$done }
    method fid ()      { return $fiber->fid }
    method name ()     { return $name }         # the registered name, or undef for an unnamed actor

    # Hot code swap: atomically replace the handler for *subsequent* messages.
    method swap : prototype($\&) ($new) {
        croak 'requires a CODE ref' unless builtin::reftype($new) // '' eq 'CODE';
        croak 'swap(): this actor is no longer running' if $done;
        $code = $new;
        return $self;
    }

    method _check_alive () {
        croak 'send()/ask(): this actor is no longer running' if $done;
        croak 'send()/ask(): this actor is shutting down'     if $stopping;
        return;
    }

    method DESTROY () {
        return                                         if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        delete $Acme::Parataxis::ACTOR_REGISTRY{$name} if defined $name && ( $Acme::Parataxis::ACTOR_REGISTRY{$name} // 0 ) == $self;
        $self->stop unless $done;
        return;
    }
};
#
1;
