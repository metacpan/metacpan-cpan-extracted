package App::BCSSH::Handler;
use Moo::Role;
use JSON qw(encode_json decode_json);
use App::BCSSH::Message;
use MooX::CaptainHook qw(on_application);

my %handlers;
sub handlers {
    return %handlers;
}
on_application {
    my $class = $_;
    $handlers{$class->command} = $class;
};

has host => (is => 'ro', required => 1);

sub command {
    my $class = ref $_[0] || $_[0];
    $class =~ s/^\Q${\__PACKAGE__}:://;
    return $class;
}

sub handle_message {
    my ($self, $args, $send, $socket) = @_;
    my $json_send = sub {
        my @response = @_;
        my $rmessage = @response ? encode_json(\@response) : '';
        $send->(BCSSH_SUCCESS, $rmessage);
        return $socket;
    };
    my $handler_args = decode_json($args);
    $self->handle($json_send, @$handler_args);
    return;
}

sub handler {
    my $self = shift;
    return sub {
        my ($args, $send, $socket) = @_;
        $self->handle_message($args, $send, $socket);
    }
}

1;
__END__

=head1 NAME

App::BCSSH::Handler - Role for command handlers

=head1 SYNOPSIS

    with 'App::BCSSH::Handler';
    sub handle {
        my ($self, $json_send, @args) = @_;
        my $socket = $json_send->(BCSSH_SUCCESS);
    }

=cut
