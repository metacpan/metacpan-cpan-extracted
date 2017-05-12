package AnyEvent::Callback;

use 5.010001;
use strict;
use warnings;

require Exporter;
use base 'Exporter';
use Carp;

our @EXPORT = qw(CB CBS);

our $VERSION = '0.05';


=head1 NAME

AnyEvent::Callback - callback aggregator for L<AnyEvent> watchers.

=head1 SYNOPSIS

    use AnyEvent::Callback;


    # usually watchers are looked as:
    AE::something @args, sub { ... };
    AE::something
        @args,
        sub { ... },    # result
        sub { ... };    # error


    use AnyEvent::Callback;

    AE::something @args, CB { ... };
    AE::something @args,
        CB sub { ... },     # result
            sub { ... };    # error

Inside Your callback You can:

    sub my_watcher {
        my $cb = pop;
        my @args = @_;

        # ...

        $cb->error( @error );   # error callback will be called
        # or:
        $cb->( $value );        # result callback will be called
    }


Callbacks stack

    my $cbs = CBS;

    for (1 .. $n) {
        AE::something @args, $cbs->cb;
    }

    $cbs->wait(sub {
        for (@_) {
            if ($_->is_error) {     # handle one error
                my @err = $_->errors; # or:
                my $errstr = $_->errstr;
            } else {                # results
                my @res = $_->results;
            }
        }

    });

=head1 DESCRIPTION

The module allows You to create callback's hierarchy. Also the module groups
error and result callbacks into one object.

Also the module checks if one callback was called by watcher or not.
If a watcher doesn't call result or error callback, error callback will be
called automatically.

Also the module checks if a callback was called reentrant. In the case the
module will complain (using L<Carp/carp>).

If a watcher touches error callback and if superior didn't define error
callback, the module will call error callback upwards hierarchy. Example:

    AE::something @args, CB \&my_watcher, \&on_error;

    sub on_error {

    }

    sub my_watcher {
        my $cb = pop;

        ...

        the_other_watcher $cb->CB( sub { # error callback wasn't defined
            my $cb = pop;
            ...
            yet_another_watcher1 $cb->CB( sub {
                my $cb = pop;
                ...
                $cb->( 123 );   # upwards callback

            });
            yet_another_watcher2 $cb->CB( sub {
                my $cb = pop;
                ...

                $cb->error( 456 );  # on_error will be called

            });
        });
    }


=head1 METHODS

=head2 'CODE' (overloaded fake method)

    $cb->( ... );

You can use the object as usually B<CODEREF>.

=cut

use overload
    '&{}' => sub {
        my ($self) = shift;
        sub {
            $self->{called}++;
            carp "Repeated callback calling: $self->{called}"
                if $self->{called} > 1;
            carp "Calling result callback after error callback"
                if $self->{ecalled};
            $self->{cb}->(@_) if $self->{cb};
            delete $self->{cb};
            delete $self->{ecb};
            delete $self->{parent};
            return;
        };
    },
    bool => sub { 1 } # for 'if ($cb)'
;


=head2 CB

Creates new callback object that have binding on parent callback.

    my $new_cb = $cb->CB(sub { ... });   # the cb doesn't catch errors

    my $new_cb = CB(sub { ... }, sub { ... }); # the cb catches errors

    my $new_cb = $cb->CB(sub { ... }, sub { ... }); # the same

=cut

sub CB(&;&) {

    my $parent;
    my ($cb, $ecb) = @_;

    ($parent, $cb, $ecb) = @_ unless 'CODE' eq ref $cb;

    croak 'Callback must be CODEREF' unless 'CODE' eq ref $cb;
    croak 'Error callback must be CODEREF or undef'
        unless 'CODE' eq ref $ecb or !defined $ecb;

    # don't translate erorrs upwards if error callback if exists
    $parent = undef if $ecb;

    my $self = bless {
        cb      => $cb,
        ecb     => $ecb,
        parent  => $parent,
        called  => 0,
        ecalled => 0,
    } => __PACKAGE__;

    $self;
}

sub CBS {
    return AnyEvent::Callback::Stack->new;
}


=head2 error

Calls error callback. If the object has no registered error callbacks,
parent object's error callback will be called.

    $cb->error('WTF?');

=cut

sub error {
    my ($self, @error) = @_;

    $self->{ecalled}++;
    carp "Repeated error callback calling: $self->{ecalled}"
        if $self->{ecalled} > 1;
    carp "Calling error callback after result callback"
        if $self->{called};

    if ($self->{ecb}) {
        $self->{ecb}( @error );
        delete $self->{ecb};
        delete $self->{cb};
        delete $self->{parent};
        return;
    }

    delete $self->{ecb};
    delete $self->{cb};
    my $parent = delete $self->{parent};

    unless($parent) {
        carp "Uncaught error: @error";
        return;
    }

    $parent->error( @error );
    return;
}


sub DESTROY {
    my ($self) = @_;
    return if $self->{called} or $self->{ecalled};
    $self->error("no one touched registered callback");
    delete $self->{cb};
    delete $self->{ecb};
}


package AnyEvent::Callback::Stack;
use Scalar::Util 'weaken';
use Carp;

sub new {
    my ($class) = @_;
    return bless { stack => [], done => 0 } => ref($class) || $class;
}

sub cb {
    my ($self) = @_;
    my $idx = @{ $self->{stack} };
    my $cb = AnyEvent::Callback::CB
        sub {
            $self->{stack}[$idx] = AnyEvent::Callback::Stack::Result->new(@_);
            $self->{done}++;
            $self->_check_if_done;
        },
        sub {
            $self->{stack}[$idx] = AnyEvent::Callback::Stack::Result->err(@_);
            $self->{done}++;
            $self->_check_if_done;
        }
    ;
    push @{ $self->{stack} } => $cb;
    weaken $self->{stack}[$idx];
    return $self->{stack}[$idx];
}


sub _check_if_done {
    my ($self) = @_;
    return unless $self->{waiter};
    return unless $self->{done} >= @{ $self->{stack} };
    my $cb = delete $self->{waiter};
    $cb->(@{ $self->{stack} });
    $self->{stack} = [];
    $self->{done} = 0;
}

sub wait :method {
    my ($self, $cb) = @_;
    croak 'Usage: $cbs->wait(sub { ... })' unless 'CODE' eq ref $cb;
    croak 'You have already initiated wait process' if $self->{waiter};
    $self->{waiter} = $cb;
    $self->_check_if_done;
}

package AnyEvent::Callback::Stack::Result;

sub new {
    my ($class, @res) = @_;
    return bless { res => \@res } => ref($class) || $class;
}

sub err {
    my ($class, @res) = @_;
    return bless { err => \@res, res => [] } => ref($class) || $class;
}

sub is_error {
    my ($self) = @_;
    return exists $self->{err};
}

sub results {
    my ($self) = @_;
    return $self->{res} unless wantarray;
    return @{ $self->{res} };
}

sub errors {
    my ($self) = @_;
    return unless $self->is_error;
    return $self->{err} unless wantarray;
    return @{ $self->{err} };
}

sub errstr {
    my ($self) = @_;
    return join ' ' => $self->errors;
}

=head1 COPYRIGHT AND LICENCE

 Copyright (C) 2012 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
