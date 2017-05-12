package TAP::Parser::Iterator::Worker::SSH;
use strict;
use File::Spec;

use TAP::Parser::Iterator::Worker           ();
use TAP::Parser::SourceHandler::Worker::SSH ();
use vars qw($VERSION @ISA);
@ISA = 'TAP::Parser::Iterator::Worker';

=head1 DESCRIPTION

This is the SSH iterator worker.  
The ssh to the specified hosts must be able 
to be ssh to by the user without authenticate 
by password.

=cut

# new() implementation supplied by TAP::Object

sub _initialize {
    my ( $self, $args ) = @_;
    $self->SUPER::_initialize($args);

=cut
    my $out          = $self->{out};
    my $pid = <$out>;
    if ( $pid ) {
        $self->{ssh_pid} = $pid;
    }
    else {
        print STDERR "failed to start an SSH job.\n";
        return;
    }
=cut

    return $self;
}

=head1 NAME

TAP::Parser::Iterator::Worker::SSH - Iterator for SSH worker TAP sources

=head1 VERSION

Version 0.03

=cut

$VERSION = '0.03';

=head3 C<initialize_worker_command>

Initialize the command to be used to initialize worker.

For your specific command, you can subclass this to put your command in this method.

=cut

sub initialize_worker_command {
    my $self     = shift;
    my $commands = $self->SUPER::initialize_worker_command;
    my $hostname = TAP::Parser::SourceHandler::Worker::SSH->get_next_host();
    my $cwd      = File::Spec->rel2abs('.');

    my $escaped_command = "cd $cwd;" . $commands->[0];
    $escaped_command =~ s/'/'"'"'/g;
    $commands->[0] = "ssh $hostname '" . $escaped_command . "'";
    $self->{host} = $hostname;
    return $commands;
}

1;

__END__

##############################################################################
