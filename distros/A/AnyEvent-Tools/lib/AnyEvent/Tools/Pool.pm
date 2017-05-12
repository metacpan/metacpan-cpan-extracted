use utf8;
use strict;
use warnings;

package AnyEvent::Tools::Pool;
use Carp;
use AnyEvent::Util;

sub new
{
    my $class = shift;

    my $self = bless {
        pool    => {},
        no      => 0,
        queue   => [],
        free    => [],
        delete  => [],

    } => ref($class) || $class;

    $self->push($_) for @_;

    return $self;
}


sub delete
{
    my ($self, $no, $cb) = @_;
    croak "Can't find object: $no" unless exists $self->{pool}{$no};
    croak "Callback must be CODEREF" if $cb and ref($cb) ne 'CODE';
    push @{ $self->{delete} }, [ $no, $cb ];
    $self->_check_pool;
    return;
}

sub push :method
{
    croak 'usage: $pool->push($object)' unless @_ == 2;
    my ($self, $object) = @_;
    my $no = $self->{no}++;
    push @{ $self->{free} }, $no;
    $self->{pool}{$no} = $object;
    $self->_check_pool;
    return $no;
}


sub get
{
    croak 'usage: $pool->get(sub { ($g, $o) = @_ .. })' unless @_ == 2;
    my ($self, $cb) = @_;
    croak 'Callback must be coderef', unless 'CODE' eq ref $cb;
    push @{ $self->{queue} }, $cb;
    $self->_check_pool;
    return;
}

sub _check_pool
{
    my ($self) = @_;

    return unless @{ $self->{free} };

    # delete  object
    if (@{ $self->{delete} }) {
        CHECK_CYCLE:
            for (my $di = $#{ $self->{delete} }; $di >= 0; $di--) {
                for (my $fi = $#{ $self->{free} }; $fi >= 0; $fi--) {
                    if ($self->{free}[$fi] == $self->{delete}[$di][0]) {
                        my ($no, $cb) = @{ $self->{delete}[$di] };
                        splice @{ $self->{free} }, $fi, 1;
                        splice @{ $self->{delete} }, $di, 1;
                        delete $self->{pool}{$no};
                        if ($cb) {
                            $cb->();
                            goto &_check_pool if $self;
                            return;
                        }
                        next CHECK_CYCLE;
                    }
                }
            }

        return unless @{ $self->{free} };
    }

    return unless @{ $self->{queue} };

    my $ono = shift @{ $self->{free} };
    my $cb = shift @{ $self->{queue} };

    my $guard = guard {
        if ($self) {        # can be destroyed
            push @{ $self->{free} }, $ono;
            $self->_check_pool;
        }
    };

    $cb->($guard, $self->{pool}{$ono});
}
1;
