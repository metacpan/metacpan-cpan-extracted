package App::BCSSH;
use strictures 1;

our $VERSION = '0.002002';
$VERSION = eval $VERSION;

use Try::Tiny;
use Module::Runtime qw(require_module);
use App::BCSSH::Util qw(command_to_package rc_dir);
use Module::Find ();

sub run_script { exit($_[0]->new(@ARGV)->run ? 0 : 1) }

sub new { bless { args => [@_[1..$#_]] }, $_[0] }

sub run {
    my $self = shift;
    my @args = @{ $self->{args} };
    $self->load_plugins(rc_dir);
    my $command = shift @args
        or die "Command required.\n" . $self->_commands_msg;
    $command =~ /^[a-z]+(?:-[a-z]+)+$/
        or $self->invalid_command($command);
    return try {
        my $pack = command_to_package($command);
        require_module($pack);
        return($pack->can('new') ? $pack->new(@args)->run : $pack->run(@args));
    }
    catch {
        if (/Can't locate .+? in \@INC/ && tr/\n// < 2 ) {
            $self->invalid_command($command);
        }
        else {
            die $_;
        }
    };
}

sub invalid_command {
    my $self = shift;
    my $command = shift;
    die "Invalid command $command!\n" . $self->_commands_msg;
}

sub _commands_msg {
    require App::BCSSH::Command::commands;
    App::BCSSH::Command::commands->new->commands_message;
}

sub load_plugins {
    my $self = shift;
    my $dir = shift;
    return unless -d $dir;
    require File::Find;
    File::Find::find({ no_chdir => 1, wanted => sub {
        return unless -f;
        return unless /\.pm$/;
        require $_;
    }}, $dir);
}

1;

__END__

=head1 NAME

App::BCSSH - Back channel SSH messaging

=head1 SYNOPSIS

    client$ bcssh ssh host
    host$ bcssh vi file

    # bashrc
    alias ssh=bcssh ssh
    bcssh ping && alias vi=bcssh vi

    # help
    bcssh commands
    bcssh help ssh

=head1 BETA RELEASE

This is a beta release and there is no guarantee the API will not change.

=head1 DESCRIPTION

This module enables commands on run on a server to be forwarded
back to the client that established the SSH connection.  Specifically,
it is meant to enable opening files in a local editor via commands
run on the server.

This is same concept that bcvi uses, but using a different messaging
protocol to fix some issues with it's design.

bcvi uses remote port forwards to enable communicating with the
local machine.  These may not be enabled on the server.  It also
overloads the TERM environment variable to pass information to the
server, but this is problematic if the server doesn't have bcvi set
up on it to fix TERM.

SSH already provides a mechanism for the server to communicate with
the client machine in the form of ssh agent forwarding.  bcssh
abuses this protocol to allow passing custom messages.  It sets
itself up as a proxy for the messages, passing through most messages.
It can identify messages intended for BCSSH though, and use this
to pass arbitrary information back and forth to the server.  This
also allows the server to probe the agent for BCSSH support, removing
the need to overload TERM.

=head1 CAVEATS

This is all probably a terrible idea.

=head1 SEE ALSO

=over 8

=item L<App::BCVI> - The inspiration for this concept

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2013 the App::BCSSH L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
