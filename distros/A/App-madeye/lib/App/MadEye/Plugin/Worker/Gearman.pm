package App::MadEye::Plugin::Worker::Gearman;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use Gearman::Worker;
use Gearman::Client;
use App::MadEye::Util;
use Params::Validate;
use English;
use App::MadEye::Util;
use POSIX ":sys_wait_h";
use Storable qw/freeze thaw/;
use YAML;
use Scalar::Util qw/weaken/;

__PACKAGE__->mk_accessors(qw/task_set child_pids gearman_client/);

our $CHILD_TIMEOUT = 60;  # TODO: configurable

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $gearman_client = $self->get_gearman_client;
    $self->gearman_client( $gearman_client );
    my $task_set = $gearman_client->new_task_set;
    $self->task_set( $task_set );

    $self;
}

sub before_run_jobs : Hook {
    my ($self, $context) = @_;

    my @child_pids = $self->_run_workers($context);
    $self->child_pids(\@child_pids);

    $SIG{__DIE__} = sub {
        $self->kill_workers();
    };
}

sub _run_workers {
    my ($self, $context) = @_;

    my $parent_pid = $PID;
    my @child_pids;
    for my $i ( 0 .. $self->config->{config}->{fork_num}- 1 ) {
        my $pid = fork();
        if ($pid) {
            # parent process
            push @child_pids, $pid;
        } elsif ( defined $pid ) {
            # child process
            $context->log('debug', "start worker $i($parent_pid)");
            $self->run_worker($context, $parent_pid);
        } else {
            die "Cannot fork: $!";
        }
    }
    return wantarray ? @child_pids : \@child_pids;
}

sub run_job :Method {
    my ($self, $context, $args) = @_;

    $self->task_set->add_task(
        'watch',
        freeze($args), +{
            timeout => $self->task_timeout(),
            on_fail => sub {
                warn "GEARMAN ERROR: " . Dump($args);
            },
            on_complete => sub {
                my $args = thaw( ${ $_[0] } );

                if ( ref $args eq 'HASH' ) {
                    # this server was dead.
                    $context->add_result(
                        plugin  => $args->{plugin},
                        target  => $args->{target},
                        message => $args->{message},
                    );
                }
                elsif ( ref $args eq 'SCALAR' && not defined $$args ) {
                    # success case
                }
                else {
                    die "invalid value: " . Dump($args);
                }
              },
        }
    );
}

sub after_run_jobs : Hook {
    my ($self, $context, $args) = @_;

    $context->log(debug => 'wait children!');
    $self->task_set->wait;

    $context->log(debug => 'kill children!');
    $self->kill_workers();

    # DESTROYYYYYYYYY
    delete $self->{task_set};
    delete $self->{gearman_client};
}

sub kill_workers {
    my ( $self, ) = @_;

    my $INT = 2;
    my $killed = kill $INT, @{ $self->child_pids };
    if ($killed != scalar @{ $self->child_pids }) {
        die "Cannot kill the child process. $killed";
    }
}

sub get_gearman_client {
    my $self = shift;

    my $client = Gearman::Client->new;
    $client->job_servers( @{ $self->config->{config}->{gearman_servers} } );
    $client->prefix($PID);
    $client;
}

sub run_worker {
    my ($self, $context, $parent_pid) = @_;

    my $worker = Gearman::Worker->new;
    $worker->job_servers( @{ $self->config->{config}->{gearman_servers} } );
    $worker->prefix($parent_pid);
    $worker->register_function(
        'watch',
        sub {
            my $args = thaw( $_[0]->arg );

            $context->log( debug => "watching $args->{target} by $args->{plugin}" );
            my $result = \undef;
            timeout $self->task_timeout(), "watching $args->{target} $args->{plugin}", sub {
                if ( my $message = $args->{plugin}->is_dead( $args->{target} ) ) {
                    $result = +{
                        message => $message,
                        plugin  => $args->{plugin},
                        target  => $args->{target},
                    };
                }
            };
            return freeze($result);
        }
    );

    timeout $self->child_timeout(), 'work child', sub {
        $worker->work while 1;
    };
}

sub task_timeout {
    my $self = shift;
    $self->config->{config}->{task_timeout} || 10;
}

sub child_timeout {
    my $self = shift;
    $self->config->{config}->{child_timeout} || 60;
}

1;
__END__

=for stopwords gearman

=head1 NAME

App::MadEye::Plugin::Worker::Gearman - work with gearman

=head1 SCHEMA

    type: map
    mapping:
        fork_num:
            required: yes
            type: int
        gearman_servers:
            type: seq
            sequence:
                - type: str
            required: yes
        task_timeout:
            type: int
            required: no
        child_timeout:
            type: int
            required: no

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<Gearman::Client>, L<Gearman::Worker>

