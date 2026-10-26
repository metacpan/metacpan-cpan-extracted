use v5.40;
#
# Base class for cancellable-wait diagnostics. Thrown inside a fiber when a parked wait is
# interrupted; the object survives on the fiber's error slot and is what an awaiting parent sees
# via ->error.
package Acme::Parataxis::Error v0.1.1 {
    use overload '""' => sub { $_[0]->message }, fallback => 1;
    sub message     ($self) { $self->{message} }
    sub wait_reason ($self) { $self->{wait_reason} }    # the [reason, file, line, backtrace] the interrupted wait parked with

    # Shared constructor: blessed into the calling subclass. $label seeds the default message.
    sub _new ( $class, $label, %args ) {
        my $reason = delete $args{wait_reason};
        my $site   = 'an unknown wait';
        $site = sprintf '%s (%s line %d)', @{$reason}[ 0 .. 2 ] if ref $reason eq 'ARRAY' && @$reason >= 3;
        bless { label => $label, message => "$label at $site", wait_reason => $reason, %args, }, $class;
    }

    # Thrown at the re-entry of a parked wait when an explicit cancellation token was cancelled while
    # the fiber was waiting.
    package Acme::Parataxis::Error::Cancelled v0.1.1 {
        use parent 'Acme::Parataxis::Error';
        sub new   ( $class, %args ) { Acme::Parataxis::Error::_new( $class, 'The operation was cancelled', %args ) }
        sub throw ( $class, %args ) { die $class->new(%args) }
        sub kind  ($self)           {'cancelled'}
    }

    # Thrown at the re-entry of a parked wait when a with_timeout deadline fired before the block was
    # able to finish.
    package Acme::Parataxis::Error::Timeout v0.1.1 {
        use parent 'Acme::Parataxis::Error';

        sub new ( $class, %args ) {
            my $seconds = delete $args{seconds};
            my $label   = defined $seconds ? "The operation timed out after ${seconds}s" : 'The operation timed out';
            Acme::Parataxis::Error::_new( $class, $label, seconds => $seconds, %args );
        }
        sub throw   ( $class, %args ) { die $class->new(%args) }
        sub kind    ($self)           {'timeout'}
        sub seconds ($self)           { $self->{seconds} }
    }

    # Thrown by nursery() when one or more enrolled children died. The complete failure list
    # is reachable via ->failures; ->primary is the first *non-cancellation* failure (i.e.
    # the real culprit, not the siblings it brought down). Plain-string dies survive too.
    package Acme::Parataxis::Error::Nursery v0.1.1 {
        use parent 'Acme::Parataxis::Error';

        sub new ( $class, %args ) {
            my $failures = delete $args{failures};
            $failures = [] unless ref $failures eq 'ARRAY';
            my @natural = grep {
                my $k;
                try { $k = $_->kind } catch ($e) {
                }    # plain string or object without ->kind
                !defined($k) || $k ne 'cancelled'
            } @$failures;
            my $primary = $natural[0] // $failures->[0];
            my $message = defined $primary ? "nursery failure: $primary" : 'nursery failure';
            bless { message => $message, label => 'nursery failure', wait_reason => undef, failures => $failures, primary => $primary, %args, },
                $class;
        }
        sub kind     ($self) {'nursery'}
        sub failures ($self) { @{ $self->{failures} // [] } }    # every child's error, in spawn order
        sub primary  ($self) { $self->{primary} }                # first natural (non-cancelled) failure
    }

    # Thrown by Acme::Parataxis::Supervisor->run when a supervised tree exhausts its restart
    # budget. Same shape as Error::Nursery: ->failures is every child death that counted against
    # the budget (in the order they happened), ->primary is the one that blew it, and ->child names
    # that child. The tree is already stopped by the time this is thrown.
    package Acme::Parataxis::Error::Supervisor v0.1.1 {
        use parent 'Acme::Parataxis::Error';

        sub new ( $class, %args ) {
            my $failures = delete $args{failures};
            $failures = [] unless ref $failures eq 'ARRAY';
            my $child   = delete $args{child};
            my $primary = delete $args{primary};
            $primary //= ( grep {defined} @$failures )[0];
            my $label   = 'supervisor failure';
            my $message = 'supervisor failure: restart budget exhausted';
            $message .= " by child '$child'" if defined $child;
            $message .= ": $primary"         if defined $primary;
            bless { message => $message, label => $label, wait_reason => undef, failures => $failures, primary => $primary, child => $child, %args, },
                $class;
        }
        sub kind     ($self) {'supervisor'}
        sub failures ($self) { @{ $self->{failures} // [] } }    # every death that counted against the budget
        sub primary  ($self) { $self->{primary} }                # the death that exhausted it
        sub child    ($self) { $self->{child} }                  # name of that child
    }

    # Control flow for STM, not a user-facing error: thrown by retry() inside an
    # atomically block and caught by atomically itself, which discards the transaction's
    # writes, parks on the read set, and re-runs the block. It never escapes atomically -
    # retry() outside a transaction croaks before this is constructed.
    package Acme::Parataxis::Error::STM_Retry v0.1.1 {
        use parent 'Acme::Parataxis::Error';
        sub new  ( $class, %args ) { bless { label => 'STM retry', message => 'STM retry (internal)', %args, }, $class }
        sub kind ($self)           {'stm_retry'}
    }
};
#
1;
