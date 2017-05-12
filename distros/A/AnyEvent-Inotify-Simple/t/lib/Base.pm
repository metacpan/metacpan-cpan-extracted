use MooseX::Declare;

role t::lib::Base {
    use AnyEvent;
    use AnyEvent::Inotify::Simple;
    use Directory::Scratch;

    has 'tmpdir' => (
        is       => 'ro',
        isa      => 'Directory::Scratch',
        required => 1,
        default  => sub { Directory::Scratch->new },
        handles  => [qw/base exists/],
    );

    has 'condvar' => (
        is       => 'ro',
        isa      => 'AnyEvent::CondVar',
        lazy     => 1,
        default  => sub { AnyEvent->condvar },
        handles  => [qw/begin end send recv/],
    );

    has 'state' => (
        is      => 'ro',
        isa     => 'ArrayRef',
        lazy    => 1,
        default => sub { +[] },
    );

    has 'type_filter' => (
        is         => 'ro',
        isa        => 'RegexpRef',
        lazy_build => 1,
    );

    has 'watcher' => (
        is       => 'ro',
        lazy     => 1,
        handles  => [qw/poll/],
        default  => sub {
            my $self = shift;
            AnyEvent::Inotify::Simple->new(
                directory      => $self->base,
                event_receiver => sub {
                    my ($type, @args) = @_;
                    my $f = $self->type_filter;
                    return if $type !~ /$f/;
                    push @{$self->state}, [
                        $type,
                        map { $_->stringify } @args,
                    ];
                    $self->end;
                },
            );
        },
    );

    requires 'do_test';
    requires 'check_result';

    method BUILD($) { $self->watcher }

    method op($op, @args) {
        $self->begin;
        $self->tmpdir->$op(@args);
        $self->poll;
    }

    method main {
        $self->begin;
        $self->do_test;
        $self->end;
        $self->recv;
        $self->check_result;
    }
}
