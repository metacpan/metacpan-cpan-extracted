package TAP::Parser::Iterator::Worker::LSF;
use strict;

use TAP::Parser::Iterator::Worker ();

use vars qw($VERSION @ISA);
@ISA = 'TAP::Parser::Iterator::Worker';

# new() implementation supplied by TAP::Object

sub _initialize {
    my ( $self, $args ) = @_;
    $self->SUPER::_initialize($args);
    my $out          = $self->{out};
    my $lsf_job_info = <$out>;
    if ( $lsf_job_info && $lsf_job_info =~ /Job <(\d+)>/ ) {
        $self->{lsf_job_id} = $1;
    }
    else {
        print STDERR "failed to start an LSF job.\n";
        return;
    }
    return $self;
}

=head1 NAME

TAP::Parser::Iterator::Worker::LSF - Iterator for LSF worker TAP sources

=head1 VERSION

Version 0.01

=cut

$VERSION = '0.01';

=head3 C<initialize_worker_command>

Initialize the command to be used to initialize worker.

For your specific command, you can subclass this to put your command in this method.

=cut

sub initialize_worker_command {
    my $self     = shift;
    my $commands = $self->SUPER::initialize_worker_command;
    $commands->[0] = 'bsub ' . $commands->[0];
    return $commands;
}

1;

__END__

##############################################################################
