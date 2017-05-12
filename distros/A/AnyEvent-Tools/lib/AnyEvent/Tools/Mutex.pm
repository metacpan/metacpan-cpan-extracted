package AnyEvent::Tools::Mutex;
use Carp;
use AnyEvent::Util;

sub new
{
    my ($class) = @_;
    return bless {
        queue   => [],
        cache   => {},
        hno     => 0,
        process => 0,
    } => ref($class) || $class;
}

sub lock
{
    my ($self, $cb) = @_;
    croak 'Usage: $mutex->lock(sub { something })' unless 'CODE' eq ref $cb;

    my $name = $self->_add_client($cb);
    $self->_check_mutex;
    return unless defined wantarray;
    return unless keys %{ $self->{cache} };
    return guard {
        $self->_check_mutex if $self and $self->_delete_client($name)
    };
}

sub is_locked
{
    my ($self) = @_;
    return $self->{process};
}

sub _add_client
{
    my ($self, $cb) = @_;
    my $name = ++$self->{hno};
    $self->{cache}{$name} = @{ $self->{queue} };
    push @{ $self->{queue} }, [ $name, $cb ];
    return $name;
}

sub _delete_client
{
    my ($self, $name) = @_;
    return 0 unless exists $self->{cache}{$name};
    my $idx = delete $self->{cache}{$name};
    if ($idx == $#{ $self->{queue} }) {
        pop @{ $self->{queue} };
        return 1;
    }

    splice @{ $self->{queue} }, $idx, 1;
    for (values %{ $self->{cache} }) {
        next unless $_ > $idx;
        $_--;
    }
    return 1;
}

sub _check_mutex
{
    my ($self) = @_;
    return if $self->is_locked;
    return unless @{ $self->{queue} };
    $self->{process}++;
    my $info = $self->{queue}[0];
    $self->_delete_client($info->[0]);
    my $guard = guard {
        if ($self) {    # it can be aleady destroyed
            $self->{process}--;
            $self->_check_mutex;
        }
    };
    $info->[1]->($guard);
}

1;
