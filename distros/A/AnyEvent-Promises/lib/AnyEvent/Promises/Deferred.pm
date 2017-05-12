package AnyEvent::Promises::Deferred;
$AnyEvent::Promises::Deferred::VERSION = '0.06';
use strict;
use warnings;

# ABSTRACT: deferred and promises objects

use AnyEvent;
use Scalar::Util qw(blessed);


# state 
# 0 .. pending
# 1 .. resolved
# 2 .. rejected
# -1 .. reserved for the state when deferred is resolved by promise
# is waiting for the promise (thus pending) but cannot be resolved
# by anything else

sub new { return bless( { then => [], state => 0 }, shift() ); }

sub resolve {
    my $this = shift;

    if ( my $then = delete $this->{then} ) {
        $this->{state} = 1;
        $this->{value} = [ @_ ];
        $this->_do_then(@$_) for @$then;
    }
    return $this;
}

sub reject {
    my ($this, $reason) = @_; 

    die "You can't reject deferred object without a reason" if !$reason;

    if ( my $then = delete $this->{then} ) {
        $this->{state} = 2;
        $this->{reason} = $reason;
        $this->_do_then(@$_) for @$then;
    }
    return $this;
}

sub _promise_state {
    my $state = shift()->{state};
    return
          $state == 1 ? 'fulfilled'
        : $state == 2 ? 'rejected'
        :               'pending';
}

sub _promise_is_pending { return shift()->{state} <= 0 }

sub _promise_is_fulfilled { shift()->{state} == 1 }

sub _promise_is_rejected { shift()->{state} == 2 }

sub _promise_value {
    my $this = shift;
    return $this->{state} == 1? $this->{value}[0]: undef;
}

sub _promise_values {
    my $this = shift;
    return $this->{state} == 1? @{$this->{value}}: ();
}

sub _promise_reason {
    my $this = shift;
    return $this->{state} == 2? $this->{reason}: undef;
}

# Promise is a mere handle defined here
{
    my $promise_class = __PACKAGE__ . '::_promise';

    sub promise {
        my $this = shift;

        return bless( \$this, $promise_class );
    }

    for my $method (
        qw(then state is_pending is_fulfilled is_rejected value
        values reason done sync)
        )
    {
        my $d_method = '_promise_' . $method;
        no strict 'refs';
        *{ join '::', $promise_class, $method } = sub {
            my $deferred = ${ shift() };
            return $deferred->$d_method(@_);
        };
    }
}


sub _promise_done {
    my $this = shift;

    $this->deferred->then(
        undef,
        sub {
            my $err = shift;
            die $err;
        }
    );
}


sub _promise_then {
    my $this = shift;

    my $d = ref($this)->new;
    if ( my $then = $this->{then} ) {
        push @$then, [ $d, @_ ];
    }
    else {
        $this->_do_then( $d, @_ );
    }
    return $d->promise;
}

# runs the promise synchronously
sub _promise_sync {
    my $this = shift;
    my $timeout = shift || 5;

    my $cv      = AE::cv;
    my $tm      = AE::timer $timeout, 0, sub { $cv->send("TIMEOUT\n") };
    $this->_promise_then( sub { $cv->send( undef, @_ ); }, sub { $cv->send(@_) } );
    my ( $error, @res ) = $cv->recv;

    die $error if $error;
    return wantarray? @res: $res[0];
}

# can be used with AnyEvent < 6 having no postpone 
my $postpone;
if (defined &AE::postpone){
    $postpone = \&AE::postpone;
}
else {
    my $POSTPONE_W;
    my @POSTPONE;

    my $postpone_exec = sub {
        undef $POSTPONE_W;

        &{ shift @POSTPONE } while @POSTPONE;
    };

    $postpone = sub {
        push @POSTPONE, shift;
        $POSTPONE_W ||= AE::timer( 0, 0, $postpone_exec );
        ();
    };
};

sub _do_then {
    my ( $this, $d, $on_fulfill, $on_reject ) = @_;

    my $rejected = $this->{state} == 2;
    my ( $value, $reason ) = @$this{qw(value reason)};
    if ( my $f = $rejected ? $on_reject : $on_fulfill ) {
        $postpone->(sub {
            my @values = eval { $f->( $rejected ? $reason : @$value ) };
            if ( my $err = $@ ) {
                $d->reject($err);
            }
            elsif (@values == 1
                && blessed( $values[0] )
                && $values[0]->can('then') )
            {
                $values[0]->then(
                    sub { $d->resolve(@_); return; },
                    sub { $d->reject(@_);  return; }
                );
            }
            else {
                $d->resolve(@values);
            }
        });
    }
    elsif ($rejected) {
        $d->reject($reason);
    }
    else {
        $d->resolve(@$value);
    }
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

__END__

=pod

=head1 NAME

AnyEvent::Promises::Deferred - deferred and promises objects

=head1 VERSION

version 0.06

=head1 DESCRIPTION

No user servicable parts here. See L<AnyEvent::Promises> for documentation.

=head1 AUTHOR

Roman Daniel <roman.daniel@davosro.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
