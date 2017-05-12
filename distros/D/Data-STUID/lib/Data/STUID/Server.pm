package Data::STUID::Server;
use strict;
use base qw(Net::Server::PreFork);
use Data::STUID;
use Data::STUID::Generator;
use IO::Handle;
use Class::Accessor::Lite
    rw => [ qw(generator host_id) ]
;

sub pre_loop_hook {
    my $self = shift;
    if (Data::STUID::DEBUG) {
        $self->log(2, "Create a new generateor");
    }
    my $generator = Data::STUID::Generator->new(host_id => $self->host_id);
    $generator->prepare;
    $self->generator($generator);
}

sub pre_server_close_hook {
    my $self = shift;
    if (Data::STUID::DEBUG) {
        $self->log(2, "Cleaning up generateor");
    }
    $self->generator()->cleanup;
    $self->generator(undef);
}

sub process_request {
    my $self = shift;

    while (read(STDIN, my $buf, 1) == 1) {
        my $id = $self->generator->create_id;
        if (Data::STUID::DEBUG) {
            $self->log(2, "Generated ID: $id");
        }
        print STDOUT pack("Q", $id);
        STDOUT->flush();
    }
}

1;

__END__

=head1 NAME

Data::STUID::Server - Simplistic STUID Server

=head1 SYNOPSIS

    use Data::STUID::Server;

    Data::STUID::Server->run(
        host_id => 1, # must be unique
    );

=head1 DESCRIPTION

Data::STUID::Server is a very simplistic server that implements a unique
ID generator. The ONLY thing this server can do is to generate a unique ID:
Nothing else. 

All you need to do is to send this server I<some> data. For each byte received,
Data::STUID::Server will just give you a 64-bit ID.

=cut