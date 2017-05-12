use strict;
use warnings;

package AnyEvent::Proc;

# ABSTRACT: Run external commands

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Util ();
use Try::Tiny;
use Class::Load;
use Exporter qw(import);
use Carp;
use POSIX;

our $VERSION = '0.105';    # VERSION

our @EXPORT_OK = qw(run run_cb reader writer);

sub _rpipe {
    my ( $R, $W ) = AnyEvent::Util::portable_pipe;
    (
        $R,
        AnyEvent::Handle->new(
            fh       => $W,
            on_error => sub {
                my ( $handle, $fatal, $message ) = @_;
                AE::log warn => "error writing to handle: $message";
                $handle->destroy;
            },
        ),
    );
}

sub _wpipe {
    my ( $R, $W ) = AnyEvent::Util::portable_pipe;
    (
        AnyEvent::Handle->new(
            fh       => $R,
            on_error => sub {
                my ( $handle, $fatal, $message ) = @_;
                AE::log warn => "error reading from handle: $message"
                  unless $message =~ m{unexpected end-of-file}i;
                $handle->destroy;
            },
        ),
        $W,
    );
}

sub _on_read_helper {
    my ( $aeh, $sub ) = @_;
    $aeh->on_read(
        sub {
            my $x = $_[0]->rbuf;
            $_[0]->rbuf = '';
            $sub->($x);
        }
    );
}

sub _read_on_scalar {
    my ( $var, $sub ) = @_;
    my $old = $$var || '';
    tie $$var, __PACKAGE__ . '::TiedScalar', $sub;
    $$var = $old;
    $var;
}

sub _reaper {
    my ( $self, $waiters ) = @_;
    my $sub = sub {

        # my $message = shift; # currently unused
        foreach my $waiter (@$waiters) {
            AE::log debug => "reap $waiter";
            if ( ref $waiter eq 'CODE' ) {
                $waiter->(undef);
            }
            elsif ( ref $waiter eq 'AnyEvent::CondVar' ) {
                $waiter->send(undef);
            }
            elsif ( ref $waiter eq 'Coro::Channel' ) {
                $waiter->shutdown;
            }
            else {
                AE::log note => "cannot reap $waiter";
            }
        }
    };
    push @{ $self->{reapers} } => $sub;
    $sub;
}

sub _push_waiter {
    my ( $self, $what, $var ) = @_;
    push @{ $self->{waiters}->{$what} } => $var;
}

sub _run_cmd {
    my ( $cmd, $redir, $pidref ) = @_;

    my $cv = AE::cv;

    my %redir = %$redir;

    my $pid = fork;
    AE::log error => "cannot fork: $!" unless defined $pid;

    unless ($pid) {

        # move any existing fd's out of the way
        # this also ensures that dup2 is never called with fd1==fd2
        # so the cloexec flag is always cleared
        my ( @oldfh, @close );
        for my $fh ( values %redir ) {
            push @oldfh, $fh;    # make sure we keep it open
            $fh = fileno $fh;    # we only want the fd

            # dup if we are in the way
            # if we "leak" fds here, they will be dup2'ed over later
            defined( $fh = POSIX::dup($fh) )
              or POSIX::_exit(124)
              while exists $redir{$fh};
        }

        # execute redirects
        while ( my ( $k, $v ) = each %redir ) {
            defined POSIX::dup2( $v, $k )
              or POSIX::_exit(123);
        }

        AnyEvent::Util::close_all_fds_except( keys %redir );

        my $bin = $cmd->[0];

        no warnings;    ## no critic

        exec {$bin} @$cmd;

        POSIX::_exit(126);
    }

    $$pidref = $pid;

    my $w;
    $w = AE::child $pid => sub {
        my $status   = $_[1] >> 8;
        my $signal   = $_[1] & 127;
        my $coredump = $_[1] & 128;
        AE::log info  => "child exited with status $status" if $status;
        AE::log debug => "child exited with signal $signal" if $signal;
        AE::log note  => "child exited with coredump"       if $coredump;
        undef $w;
        map { close $_ } values %redir;
        $cv->send($status);
    };

    $cv;
}

sub new {
    my ( $class, %options ) = @_;

    $options{args} ||= [];

    my ( $rIN,  $wIN )  = _rpipe;
    my ( $rOUT, $wOUT ) = _wpipe;
    my ( $rERR, $wERR ) = _wpipe;

    my @xhs = @{ delete( $options{extras} ) || [] };

    my @args = map { "$_" } @{ delete $options{args} };

    my $pid;

    my %redir = (
        0 => $rIN,
        1 => $wOUT,
        2 => $wERR,
        map { ( "$_" => $_->B ) } @xhs
    );

    my $cv = _run_cmd( [ delete $options{bin} => @args ], \%redir, \$pid );
    my $waiter = AE::cv;

    my $self = bless {
        handles => {
            in  => $wIN,
            out => $rOUT,
            err => $rERR,
            map { ( "$_" => $_->A ) } @xhs,
        },
        pid       => $pid,
        listeners => {
            exit       => delete $options{on_exit},
            ttl_exceed => delete $options{on_ttl_exceed},
        },
        eol     => "\n",
        cv      => $cv,
        alive   => 1,
        waiter  => $waiter,
        waiters => {
            in  => [],
            out => [],
            err => [],
            map { ( "$_" => [] ) } @xhs
        },
        reapers => [],
      } => ref $class
      || $class;

    map { $_->{proc} = $self } @xhs;

    {
        my $eol = quotemeta $self->_eol;
        $self->{reol} = delete $options{reol} || qr{$eol};
    }

    if ( $options{ttl} ) {
        $self->{timer} = AnyEvent->timer(
            after => delete $options{ttl},
            cb    => sub {
                return unless $self->alive;
                $self->kill;
                $self->_emit('ttl_exceed');
            }
        );
    }

    my $kill = sub { $self->end };

    if ( $options{timeout} ) {
        $wIN->timeout( $options{timeout} );
        $rOUT->timeout( $options{timeout} );
        $rERR->timeout( $options{timeout} );
        delete $options{timeout};

        $self->_on( timeout => ( delete( $options{on_timeout} ) || $kill ) );
        my $cb = sub { $self->_emit('timeout') };
        $wIN->on_timeout($cb);
        $rOUT->on_timeout($cb);
        $rERR->on_timeout($cb);
    }

    if ( $options{wtimeout} ) {
        $wIN->wtimeout( delete $options{wtimeout} );

        $self->_on( wtimeout => ( delete( $options{on_wtimeout} ) || $kill ) );
        my $cb = sub { $self->_emit('wtimeout') };
        $wIN->on_wtimeout($cb);
    }

    if ( $options{rtimeout} ) {
        $rOUT->rtimeout( delete $options{rtimeout} );

        $self->_on( rtimeout => ( delete( $options{on_rtimeout} ) || $kill ) );
        my $cb = sub { $self->_emit('rtimeout') };
        $rOUT->on_rtimeout($cb);
    }

    if ( $options{etimeout} ) {
        $rERR->rtimeout( delete $options{etimeout} );

        $self->_on( etimeout => ( delete( $options{on_etimeout} ) || $kill ) );
        my $cb = sub { $self->_emit('etimeout') };
        $rERR->on_rtimeout($cb);
    }

    if ( $options{errstr} ) {
        my $sref = delete $options{errstr};
        $$sref = '';
        $self->pipe( err => $sref );
    }

    if ( $options{outstr} ) {
        my $sref = delete $options{outstr};
        $$sref = '';
        $self->pipe( out => $sref );
    }

    $waiter->begin;
    $cv->cb(
        sub {
            $self->{status} = shift->recv;
            $self->{alive}  = 0;
            undef $self->{timer};
            $waiter->end;
            $self->_emit( exit => $self->{status} );
        }
    );

    if ( keys %options ) {
        AE::log note => "unknown left-over option(s): " . join ', ' =>
          keys %options;
    }

    $self;
}

sub reader {
    my ( $r, $w ) = _wpipe;
    bless {
        r      => $r,
        w      => $w,
        fileno => fileno( $r->fh )
      } => __PACKAGE__
      . '::R';
}

sub writer {
    my ( $r, $w ) = _rpipe;
    bless {
        r      => $r,
        w      => $w,
        fileno => fileno( $w->fh )
      } => __PACKAGE__
      . '::W';
}

sub run {
    my $cv = AE::cv;
    run_cb(
        @_,
        sub {
            $cv->send( \@_ );
        }
    )->recv;
    my ( $out, $err, $status ) = @{ $cv->recv };
    $? = $status << 8;
    if (wantarray) {
        return ( $out, $err );
    }
    else {
        carp $err if $err;
        return $out;
    }
}

sub run_cb {
    my $bin  = shift;
    my $cb   = pop;
    my @args = @_;
    my ( $out, $err ) = ( '', '' );
    my $proc = __PACKAGE__->new(
        bin    => $bin,
        args   => \@args,
        outstr => \$out,
        errstr => \$err
    );
    $proc->finish;
    $proc->wait(
        sub {
            my $status = $proc->{status};
            $? = $status << 8;
            $cb->( $out, $err, $status );
        }
    );
}

sub _on {
    my ( $self, $name, $handler ) = @_;
    $self->{listeners}->{$name} = $handler;
}

sub in { shift->_geth('in') }

sub out { shift->_geth('out') }

sub err { shift->_geth('err') }

sub _geth {
    shift->{handles}->{ pop() };
}

sub _eol  { shift->{eol} }
sub _reol { shift->{reol} }

sub _emit {
    my ( $self, $name, @args ) = @_;
    AE::log debug => "trapped $name";
    if ( exists $self->{listeners}->{$name}
        and defined $self->{listeners}->{$name} )
    {
        $self->{listeners}->{$name}->( $self, @args );
    }
}

sub pid {
    shift->{pid};
}

sub fire {
    my ( $self, $signal ) = @_;
    $signal = 'TERM' unless defined $signal;
    $signal =~ s{^sig}{}i;
    AE::log debug   => "fire SIG$signal";
    kill uc $signal => $self->pid;
}

sub kill {
    my ($self) = @_;
    $self->fire('kill');
}

sub fire_and_kill {
    my $self   = shift;
    my $cb     = ( ref $_[-1] eq 'CODE' ? pop : undef );
    my $time   = pop;
    my $signal = uc( pop || 'TERM' );
    my $w      = AnyEvent->timer(
        after => $time,
        cb    => sub {
            return unless $self->alive;
            $self->kill;
        }
    );
    $self->fire($signal);
    if ($cb) {
        return $self->wait(
            sub {
                undef $w;
                $cb->(@_);
            }
        );
    }
    else {
        my $exit = $self->wait;
        undef $w;
        return $exit;
    }
}

sub alive {
    my $self = shift;
    return 0 unless $self->{alive};
    $self->fire(0) ? 1 : 0;
}

sub wait {
    my ( $self, $cb ) = @_;

    my $next = sub {
        my $cv = shift;
        $cv->recv;
        waitpid $self->{pid} => 0;
        $cb->( $self->{status} ) if ref $cb eq 'CODE';
        $self->end;
        $self->{status};
    };
    AE::log debug => "waiting for "
      . ( $self->{waiter}->{_ae_counter} ) . " ends";
    if ($cb) {
        $self->{waiter}->cb($next);
        return $self->{waiter};
    }
    else {
        $self->{waiter}->recv;
        return $next->( $self->{waiter} );
    }
}

sub finish {
    my ($self) = @_;
    $self->in->destroy;
    $self;
}

sub end {
    my ($self) = @_;
    map { $_->destroy } values %{ $self->{handles} };
    map { $_->() } @{ $self->{reapers} };
    $self;
}

sub stop_timeout {
    my ($self) = @_;
    $self->in->timeout(0);
    $self->out->timeout(0);
    $self->err->timeout(0);
}

sub stop_wtimeout {
    my ($self) = @_;
    $self->in->wtimeout(0);
}

sub stop_rtimeout {
    my ($self) = @_;
    $self->out->rtimeout(0);
}

sub stop_etimeout {
    my ($self) = @_;
    $self->err->rtimeout(0);
}

sub write {
    my ( $self, $type, @args ) = @_;
    my $ok = 0;
    try {
        $self->_geth('in')->push_write( $type => @args );
        $ok = 1;
    }
    catch {
        AE::log warn => $_;
    };
    $ok;
}

sub writeln {
    my ( $self, @lines ) = @_;
    $self->write( $_ . $self->_eol ) for @lines;
    $self;
}

sub pipe {
    my $self = shift;
    my $peer = pop;
    my $what = ( pop || 'out' );
    if ( ref $what ) {
        $what = "$what";
    }
    else {
        $what = lc $what;
        $what =~ s{^std}{};
    }
    use Scalar::Util qw(blessed);
    my $sub;
    if ( blessed $peer) {
        if ( $peer->isa(__PACKAGE__) ) {
            $sub = sub {
                $peer->write(shift);
              }
        }
        elsif ( $peer->isa('AnyEvent::Handle') ) {
            $sub = sub {
                $peer->push_write(shift);
              }
        }
        elsif ( $peer->isa('Coro::Channel') ) {
            $sub = sub {
                $peer->put(shift);
              }
        }
        elsif ( $peer->can('print') ) {
            $sub = sub {
                $peer->print(shift);
              }
        }
    }
    elsif ( ref $peer eq 'SCALAR' ) {
        $sub = sub {
            $$peer .= shift;
          }
    }
    elsif ( ref $peer eq 'GLOB' ) {
        $sub = sub {
            print $peer shift();
          }
    }
    elsif ( ref $peer eq 'CODE' ) {
        $sub = $peer;
    }
    if ($sub) {
        AE::log debug => "pipe $peer from $what";
        my $aeh = $self->_geth($what);
        $aeh->on_eof(
            sub {
                AE::log debug => "eof: $what";
                shift->destroy;
                $self->{waiter}->end;
            }
        );
        $self->{output}->{$what} = _on_read_helper( $aeh, $sub );
        $self->{waiter}->begin;
    }
    else {
        AE::log fatal => "cannot pipe $peer from $what";
    }
}

sub pull {
    my ( $self, $peer ) = @_;
    $self->{input} = $peer;
    AE::log debug => "pull $peer to stdin";
    use Scalar::Util qw(blessed);
    my $sub;
    if ( blessed $peer) {
        if ( $peer->isa(__PACKAGE__) ) {
            return $peer->pipe($self);
        }
        elsif ( $peer->isa('AnyEvent::Handle') ) {
            $peer->on_eof(
                sub {
                    AE::log debug => "pull($peer)->on_eof";
                    shift->destroy;
                    $self->finish;
                }
            );
            $peer->on_error(
                sub {
                    AE::log error => "pull($peer)->on_error(" . $_[2] . ")";
                    shift->destroy;
                }
            );
            return _on_read_helper(
                $peer,
                sub {
                    AE::log debug => "pull($peer)->on_read";
                    $self->write( shift() );
                }
            );
        }
        elsif ( $peer->isa('IO::Handle') ) {
            return $self->pull( AnyEvent::Handle->new( fh => $peer ) );
        }
        elsif ( $peer->isa('Coro::Channel') ) {
            if ( my $class = load_class('Coro') ) {
                return $class->new(
                    sub {
                        while ( my $x = $peer->get ) {
                            $self->write($x) or last;
                            Coro::cede();
                        }
                        $self->finish;
                    }
                );
            }
        }
    }
    elsif ( ref $peer eq 'SCALAR' ) {
        return _read_on_scalar(
            $peer,
            sub {
                AE::log debug => "pull($peer)->STORE";
                $self->write( shift() );
            }
        );
    }
    elsif ( ref $peer eq 'GLOB' ) {
        return $self->pull( AnyEvent::Handle->new( fh => $peer ) );
    }
    AE::log fatal => "cannot pull $peer to stdin";
}

sub _push_read {
    my ( $self, $what, @args ) = @_;
    my $ok = 0;
    try {
        $self->_geth($what)->push_read(@args);
        $ok = 1;
    }
    catch {
        AE::log note => "cannot push_read from std$what: $_";
    };
    $ok;
}

sub _unshift_read {
    my ( $self, $what, @args ) = @_;
    my $ok = 0;
    try {
        $self->_geth($what)->unshift_read(@args);
        $ok = 1;
    }
    catch {
        AE::log note => "cannot unshift_read from std$what: $_";
    };
    $ok;
}

sub _readline {
    my ( $self, $what, $sub ) = @_;
    $self->_push_read( $what => line => $self->_reol, $sub );
}

sub _readchunk {
    my ( $self, $what, $bytes, $sub ) = @_;
    $self->_push_read( $what => chunk => $bytes => $sub );
}

sub _sub_cb {
    my ($cb) = @_;
    sub { $cb->( $_[1] ) }
}

sub _sub_cv {
    my ($cv) = @_;
    sub { $cv->send( $_[1] ) }
}

sub _sub_ch {
    my ($ch) = @_;
    sub { $ch->put( $_[1] ) }
}

sub _readline_cb {
    my ( $self, $what, $cb ) = @_;
    $self->_push_waiter( $what => $cb );
    $self->_readline( $what => _sub_cb($cb) );
}

sub _readline_cv {
    my ( $self, $what, $cv ) = @_;
    $cv ||= AE::cv;
    $self->_push_waiter( $what => $cv );
    $cv->send unless $self->_readline( $what => _sub_cv($cv) );
    $cv;
}

sub _readline_ch {
    my ( $self, $what, $channel ) = @_;
    unless ($channel) {
        if ( my $class = load_class('Coro::Channel') ) {
            $channel ||= $class->new;
        }
    }
    $self->_push_waiter( $what => $channel );
    $channel->shutdown unless $self->_readline( $what => _sub_ch($channel) );
    $channel;
}

sub _readlines_cb {
    my ( $self, $what, $cb ) = @_;
    $self->_push_waiter( $what => $cb );
    $self->_geth($what)->on_read(
        sub {
            $self->_readline( $what => _sub_cb($cb) );
        }
    );
}

sub _readlines_ch {
    my ( $self, $what, $channel ) = @_;
    unless ($channel) {
        if ( my $class = load_class('Coro::Channel') ) {
            $channel ||= $class->new;
        }
    }
    $self->_push_waiter( $what => $channel );
    $channel->shutdown unless $self->_geth($what)->on_read(
        sub {
            $self->_readline( $what => _sub_ch($channel) );
        }
    );
    $channel;
}

sub _readchunk_cb {
    my ( $self, $what, $bytes, $cb ) = @_;
    $self->_push_waiter( $what => $cb );
    $self->_readchunk( $what, $bytes, _sub_cb($cb) );
}

sub _readchunk_cv {
    my ( $self, $what, $bytes, $cv ) = @_;
    $cv ||= AE::cv;
    $self->_push_waiter( $what => $cv );
    $self->_readchunk( $what, $bytes, _sub_cv($cv) );
    $cv;
}

sub _readchunk_ch {
    my ( $self, $what, $bytes, $channel ) = @_;
    unless ($channel) {
        if ( my $class = load_class('Coro::Channel') ) {
            $channel ||= $class->new;
        }
    }
    $self->_push_waiter( $what => $channel );
    $channel->shutdown unless $self->_readline( $what => _sub_ch($channel) );
    $channel;
}

sub _readchunks_ch {
    my ( $self, $what, $bytes, $channel ) = @_;
    unless ($channel) {
        if ( my $class = load_class('Coro::Channel') ) {
            $channel ||= $class->new;
        }
    }
    $self->_push_waiter( $what => $channel );
    $channel->shutdown unless $self->_geth($what)->on_read(
        sub {
            $self->_readline( $what => _sub_ch($channel) );
        }
    );
    $channel;
}

sub readline_cb {
    my ( $self, $cb ) = @_;
    $self->_readline_cb( out => $cb );
}

sub readline_cv {
    my ( $self, $cv ) = @_;
    $self->_readline_cv( out => $cv );
}

sub readline_ch {
    my ( $self, $ch ) = @_;
    $self->_readline_ch( out => $ch );
}

sub readlines_cb {
    my ( $self, $cb ) = @_;
    $self->_readlines_cb( out => $cb );
}

sub readlines_ch {
    my ( $self, $ch ) = @_;
    $self->_readlines_ch( out => $ch );
}

sub readline {
    shift->readline_cv->recv;
}

sub readline_error_cb {
    my ( $self, $cb ) = @_;
    $self->_readline_cb( err => $cb );
}

sub readline_error_cv {
    my ( $self, $cv ) = @_;
    $self->_readline_cv( err => $cv );
}

sub readline_error_ch {
    my ( $self, $ch ) = @_;
    $self->_readline_ch( err => $ch );
}

sub readlines_error_cb {
    my ( $self, $cb ) = @_;
    $self->_readlines_cb( out => $cb );
}

sub readlines_error_ch {
    my ( $self, $ch ) = @_;
    $self->_readlines_ch( out => $ch );
}

sub readline_error {
    shift->readline_error_cv->recv;
}

# AnyEvent::Impl::Perl has some issues with POSIX::dup.
# This statement solves the problem.
AnyEvent::post_detect {
    AE::child $$ => sub { };
};

1;

package    # hidden
  AnyEvent::Proc::R;

use overload '""' => sub { shift->{fileno} };

sub A { shift->{r} }
sub B { shift->{w} }

sub on_timeout {
    shift->A->on_wtimeout(pop);
}

sub stop_timeout {
    shift->A->stop_wtimeout;
}

sub pipe {
    my ( $self, $peer ) = @_;
    $self->{proc}->pipe( $self => $peer );
}

sub readline_cb {
    my ( $self, $cb ) = @_;
    $self->{proc}->_readline_cb( $self => $cb );
}

sub readline_cv {
    my ( $self, $cv ) = @_;
    $self->{proc}->_readline_cv( $self => $cv );
}

sub readline_ch {
    my ( $self, $ch ) = @_;
    $self->{proc}->_readline_ch( $self => $ch );
}

sub readlines_cb {
    my ( $self, $cb ) = @_;
    $self->{proc}->_readlines_cb( $self => $cb );
}

sub readlines_ch {
    my ( $self, $ch ) = @_;
    $self->{proc}->_readlines_cb( $self => $ch );
}

sub readline {
    shift->readline_cv->recv;
}

1;

package    # hidden
  AnyEvent::Proc::W;

use overload '""' => sub { shift->{fileno} };

use Try::Tiny;

sub A { shift->{w} }
sub B { shift->{r} }

sub finish {
    shift->A->destroy;
}

sub on_timeout {
    shift->A->on_rtimeout(pop);
}

sub stop_timeout {
    shift->A->stop_rtimeout;
}

sub write {
    my ( $self, $type, @args ) = @_;
    my $ok = 0;
    try {
        $self->A->push_write( $type => @args );
        $ok = 1;
    }
    catch {
        AE::log note => $_;
    };
    $ok;
}

sub writeln {
    my ( $self, @lines ) = @_;
    my $eol = $self->{proc}->_eol;
    $self->write( $_ . $eol ) for @lines;
    $self;
}

sub pull { die 'UNIMPLEMENTED' }

1;

package    # hidden
  AnyEvent::Proc::TiedScalar;

use Tie::Scalar;

our @ISA = ('Tie::Scalar');

sub TIESCALAR {
    bless pop, shift;
}

sub FETCH {
    undef;
}

sub STORE {
    shift->(pop);
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Proc - Run external commands

=head1 VERSION

version 0.105

=head1 SYNOPSIS

	my $proc = AnyEvent::Proc->new(bin => 'cat');
	$proc->writeln('hello');
	my $hello = $proc->readline;
	$proc->fire;
	$proc->wait;

=head1 DESCRIPTION

AnyEvent::Proc is a L<AnyEvent>-based helper class for running external commands with full control over STDIN, STDOUT and STDERR.

=head1 METHODS

=head2 new(%options)

=over 4

=item * I<bin> (mandatory)

Name (or path) to a binary

=item * I<args>

ArrayRef with command arguments

=item * I<ttl>

Time-to-life timeout after the process automatically gets killed

See also I<on_ttl_exceed> callback handler.

=item * I<timeout>

Inactive timeout value (fractional seconds) for all handlers.

See also I<on_timeout> callback handler. If omitted, after exceeding timeout all handlers will be closed and the subprocess can finish.

=item * I<wtimeout>

Like I<timeout> but sets only the write timeout value for STDIN.

Corresponding callback handler: I<on_wtimeout>

=item * I<rtimeout>

Like I<timeout> but sets only the read timeout value for STDOUT.

Corresponding callback handler: I<on_rtimeout>

=item * I<etimeout>

Like I<timeout> but sets only the read timeout value for STDERR.

Corresponding callback handler: I<on_etimeout>

=item * I<outstr>

When set to a ScalarRef, any output (STDOUT) will be appended to this scalar

=item * I<errstr>

Same as I<outstr>, but for STDERR.

=item * I<on_exit>

Callback handler called when process exits

=item * I<on_ttl_exceed>

Callback handler called when I<ttl> exceeds

=item * I<on_timeout>

Callback handler called when any inactivity I<timeout> value exceeds

=item * I<on_wtimeout>

Callback handler called when STDIN write inactivity I<wtimeout> value exceeds

=item * I<on_rtimeout>

Callback handler called when STDOUT read inactivity I<rtimeout> value exceeds

=item * I<on_etimeout>

Callback handler called when STDERR read inactivity I<etimeout> value exceeds

=back

=head2 in()

Returns a L<AnyEvent::Handle> for STDIN

Useful for piping data into us:

	$socket->print($proc->in->fh)

=head2 out()

Returns a L<AnyEvent::Handle> for STDOUT

=head2 err()

Returns a L<AnyEvent::Handle> for STDERR

=head2 pid()

Returns the PID of the subprocess

=head2 fire([$signal])

Sends a named signal to the subprocess. C<$signal> defaults to I<TERM> if omitted.

=head2 kill()

Kills the subprocess the most brutal way. Equals to

	$proc->fire('kill')

=head2 fire_and_kill([$signal, ]$time[, $callback])

Fires specified signal C<$signal> (or I<TERM> if omitted) and after C<$time> seconds kills the subprocess.

See L</wait> for the meaning of the callback parameter and return value.

Without calllback, this is a synchronous call. After this call, the subprocess can be considered to be dead. Returns the exit code of the subprocess.

=head2 alive()

Check whether is subprocess is still alive. Returns I<1> or I<0>

In fact, the method equals to

	$proc->fire(0)

=head2 wait([$callback])

Waits for the subprocess to be finished call the callback with the exit code. Returns a condvar.

Without callback, this is a synchronous call directly returning the exit code.

=head2 finish()

Closes STDIN of subprocess

=head2 end()

Closes all handles of subprocess

=head2 stop_timeout()

Stopps read/write timeout for STDIN, STDOUT and STDERR.

See I<timeout> and I<on_timeout> options in I<new()>.

=head2 stop_wtimeout()

Stopps write timeout for STDIN.

See I<wtimeout> and I<on_wtimeout> options in I<new()>.

=head2 stop_rtimeout()

Stopps read timeout for STDIN.

See I<rtimeout> and I<on_rtimeout> options in I<new()>.

=head2 stop_etimeout()

Stopps read timeout for STDIN.

See I<etimeout> and I<on_etimeout> options in I<new()>.

=head2 write($scalar)

Queues the given scalar to be written.

=head2 write($type => @args)

See L<AnyEvent::Handle>::push_write for more information.

=head2 writeln(@lines)

Queues one or more line to be written.

=head2 pipe([$fd, ]$peer)

Pipes any output of STDOUT to another handle. C<$peer> maybe another L<AnyEvent::Proc> instance, an L<AnyEvent::Handle>, a L<Coro::Channel>, an object that implements the I<print> method (like L<IO::Handle>, including any subclass), a ScalarRef or a GlobRef or a CodeRef.

C<$fd> defaults to I<stdout>.

	$proc->pipe(stderr => $socket);

=head2 pull($peer)

Pulls any data from another handle to STDIN. C<$peer> maybe another L<AnyEvent::Proc> instance, an L<AnyEvent::Handle>, an L<IO::Handle> (including any subclass), a L<Coro::Channel>, a ScalarRef or a GlobRef.

	$proc->pull($socket);

=head2 readline_cb($callback)

Reads a single line from STDOUT and calls C<$callback>

=head2 readline_cv([$condvar])

Reads a single line from STDOUT and send the result to C<$condvar>. A condition variable will be created and returned, if C<$condvar> is omitted.

=head2 readline_ch([$channel])

Reads a singe line from STDOUT and put the result to coro channel C<$channel>. A L<Coro::Channel> will be created and returned, if C<$channel> is omitted.

=head2 readlines_cb($callback)

Read lines continiously from STDOUT and calls on every line the handler C<$callback>.

=head2 readlines_ch([$channel])

Read lines continiously from STDOUT and put every line to coro channel C<$channel>. A L<Coro::Channel> will be created and returned, if C<$channel> is omitted.

=head2 readline()

Reads a single line from STDOUT synchronously and return the result.

Same as

	$proc->readline_cv->recv

=head2 readline_error_cb($callback)

Bevahes equivalent as I<readline_cb>, but for STDERR.

=head2 readline_error_cv([$condvar])

Bevahes equivalent as I<readline_cv>, but for STDERR.

=head2 readline_error_ch([$channel])

Bevahes equivalent as I<readline_ch>, but for STDERR.

=head2 readlines_error_cb($callback)

Bevahes equivalent as I<readlines_cb>, but for STDERR.

=head2 readlines_error_ch([$channel])

Bevahes equivalent as I<readlines_ch>, but for STDERR.

=head2 readline_error()

Bevahes equivalent as I<readline>, but for STDERR.

=head1 FUNCTIONS

=head2 reader()

Creates a new file descriptor for pulling data from process.

	use AnyEvent::Proc qw(reader);
	my $reader = reader();
	my $proc = AnyEvent::Proc->new(
		bin => '/bin/sh',
		args => [ -c => "echo hi >&$reader" ] # overloads to fileno
		extras => [ $reader ], # unordered list of all extra descriptors
	);
	my $out;
	$reader->pipe(\$out);
	$proc->wait;
	# $out contains now 'hi'

This calls C<< /bin/sh -c "echo hi >&3" >>, so that any output will be dupped into fd #3.

C<$reader> provides following methods:

=over 4

=item * L</on_timeout>

=item * L</stop_timeout>

=item * L</pipe>

=item * L</readline_cb>

=item * L</readline_cv>

=item * L</readline_ch>

=item * L</readlines_cb>

=item * L</readlines_ch>

=item * L</readline>

=back

=head2 writer()

Creates a new file descriptor for pushing data to process.

	use AnyEvent::Proc qw(writer);
	my $writer = writer();
	my $out;
	my $proc = AnyEvent::Proc->new(
		bin => '/bin/sh',
		args => [ -c => "cat <&$writer" ] # overloads to fileno
		extras => [ $writer ], # unordered list of all extra descriptors
		outstr => \$out,
	);
	my $out;
	$writer->writeln('hi');
	$writer->finish;
	$proc->wait;
	# $out contains now 'hi'

This calls C</bin/sh -c "cat <&3">, so that any input will be dupped from fd #3.

C<$writer> provides following methods:

=over 4

=item * L</finish>

=item * L</on_timeout>

=item * L</stop_timeout>

=item * L</write>

=item * L</writeln>

=back

Unfortunally L</pull> is unimplemented.

=head2 run($bin[, @args])

Bevahes similar to L<perlfunc/system>. In scalar context, it returns STDOUT of the subprocess. STDERR will be passed-through by L<perlfunc/warn>.

	$out = AnyEvent::Proc::run(...)

In list context, STDOUT and STDERR will be separately returned.

	($out, $err) = AnyEvent::Proc::run(...)

The exit-code is stored in C<$?>. Please keep in mind that for portability reasons C<$?> is shifted by 8 bits.

	$exitcode = $? >> 8

=head2 run_cb($bin[, @args], $callback)

Like L</run>, but asynchronous with callback handler. Returns the condvar. See L</wait> for more information.

	AnyEvent::Proc::run_cb($bin, @args, sub {
		my ($out, $err, $status) = @_;
		...;
	});

=head1 LIMITATIONS

Use L<EV>. The fallback module L<AnyEvent::Impl::Perl> has some issues with pipes. In some cases, L<AnyEvent::Handle> don't receive data from its pipe peer and the application will block forever. I haven't a solution yet, so don't rely on pipes when you use AE's pure-perl backend.

=head1 EXPORTS

Nothing by default. The following functions will be exported on request:

=over 4

=item * L</run>

=item * L</run_cb>

=item * L</reader>

=item * L</writer>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libanyevent-proc-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
