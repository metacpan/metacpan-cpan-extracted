package AnyEvent::Tools::RWMutex;
use Carp;
use AnyEvent::Util;

sub new
{
    my ($class) = @_;
    return bless {
        rlock       => [],
        wlock       => [],
        hno         => 0,
        rprocess    => 0,
        wprocess    => 0,
        cache       => {},
        rlock_limit => 0,
    } => ref($class) || $class;
}


for my $m (qw(wlock rlock)) {
    no strict 'refs';
    * { __PACKAGE__ . "::$m" } = sub {
        my ($self, $cb) = @_;
        croak "Usage: \$mutex->$m(sub { something })" unless 'CODE' eq ref $cb;

        my $name = $self->_add_client($m, $cb);
        $self->_check_mutex;
        return unless defined wantarray;
        return unless keys %{ $self->{cache} };
        return guard {
            $self->_check_mutex if $self and $self->_delete_client($name)
        };
    }
}

sub rlock_limit
{
    my ($self, $value) = @_;
    return $self->{rlock_limit} if @_ == 1;
    return $self->{rlock_limit} = $value || 0;
}

sub is_wlocked
{
    my ($self) = @_;
    return $self->{wprocess};
}

sub is_rlocked
{
    my ($self) = @_;
    return $self->{rprocess};
}

sub is_locked
{
    my ($self) = @_;
    return $self->is_wlocked || $self->is_rlocked;
}

sub _add_client
{
    my ($self, $queue, $cb) = @_;
    my $name = ++$self->{hno};
    $self->{cache}{$name} = [ $queue, scalar @{ $self->{$queue} } ];
    push @{ $self->{$queue} }, [ $name, $cb ];
    return $name;
}

sub _delete_client
{
    my ($self, $name) = @_;
    return 0 unless exists $self->{cache}{$name};
    my ($queue, $idx)  = @{ delete $self->{cache}{$name} };

    if ($idx == $#{ $self->{$queue} }) {
        pop @{ $self->{$queue} };
        return 1;
    }

    splice @{ $self->{$queue} }, $idx, 1;

    for (values %{ $self->{cache} }) {
        next unless $_->[1] > $idx;
        next unless $_->[0] eq $queue;
        $_->[1]--;
    }
    return 1;
}

sub _check_mutex
{
    my ($self) = @_;
    return if $self->is_wlocked;

    my $info;

    if ($self->is_rlocked) {
        return if @{ $self->{wlock} };
        return unless @{ $self->{rlock} };
        goto LOCK_RMUTEX;
    }

    if (@{ $self->{wlock} }) {
        $info = $self->{wlock}[0];
        $self->_delete_client($info->[0]);
        $self->{wprocess}++;
        my $guard = guard {
            if ($self) {    # it can be already destroyed
                $self->{wprocess}--;
                $self->_check_mutex;
            }
        };
        $info->[1]->($guard);
        return;
    }

    goto LOCK_RMUTEX if @{ $self->{rlock} };

    return;
    LOCK_RMUTEX:
        return if $self->rlock_limit
            and $self->{rprocess} >= $self->rlock_limit;

        $info = $self->{rlock}[0];
        $self->_delete_client($info->[0]);
        $self->{rprocess}++;
        my $guard = guard {
            if ($self) {    # it can be already destroyed
                $self->{rprocess}--;
                $self->_check_mutex;
            }
        };
        $info->[1]->($guard);
        goto &_check_mutex if @{ $self->{rlock} };
        return;
}

1;
