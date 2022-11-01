package App::Base::Script::OnlyOne;
use strict;
use warnings;
use Moose::Role;

use Path::Tiny;
use File::Flock::Tiny;

our $VERSION = '0.08';    ## VERSION

=head1 NAME

App::Base::Script::OnlyOne - do not allow more than one instance running

=head1 SYNOPSIS

    use Moose;
    extends 'App::Base::Script';
    with 'App::Base::Script::OnlyOne';

=head1 DESCRIPTION

With this role your script will refuse to start if another copy of the script
is running already (or if it is deadlocked or entered an infinite loop because
of programming error). After start it tries to lock pid file, and if this is
not possible, it dies.

=cut

around script_run => sub {
    my $orig = shift;
    my $self = shift;

    my $class   = ref $self;
    my $piddir  = $ENV{APP_BASE_DAEMON_PIDDIR} || '/var/run';
    my $pidfile = path($piddir)->child("$class.pid");
    my $lock    = File::Flock::Tiny->write_pid("$pidfile");
    die "Couldn't lock pid file, probably $class is already running" unless $lock;

    return $self->$orig(@_);
};

no Moose::Role;
1;

__END__
