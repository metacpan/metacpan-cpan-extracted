package AnyEvent::DAAP::Server::Connection;
use Any::Moose;
use AnyEvent;
use AnyEvent::Handle;
use Net::DAAP::DMAP qw(dmap_pack);
use HTTP::Response;

has handle => (
    is  => 'rw',
    isa => 'AnyEvent::Handle',
    required => 1,
    lazy_build => 1,
);

sub _build_handle {
    my $self = shift;
    return AnyEvent::Handle->new(
        fh => $self->fh,
        on_eof => sub {},
        on_error => sub { warn "$_[2]" },
    );
}

has fh => (
    is  => 'rw',
    isa => 'FileHandle',
);

has server => (
    is  => 'rw',
    isa => 'AnyEvent::DAAP::Server',
    required => 1,
    weak_ref => 1,
);

has pause_cv => (
    is  => 'rw',
    isa => 'AnyEvent::CondVar',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub respond_dmap {
    my ($self, $dmap) = @_;
    my $content = dmap_pack $dmap;
    $self->respond(
        200, 'OK', [
            'Content-Type'   => 'application/x-dmap-tagged',
            'Content-Length' => length($content),
        ], $content,
    );
}

sub respond {
    my $self = shift;
    my $response = HTTP::Response->new(@_);
    $self->handle->push_write('HTTP/1.1 ' . $response->as_string("\r\n"));
}

sub pause {
    my ($self, $cb) = @_;
    return $self->{pause_cv} = AE::cv {
        $self->{pause_cv} = undef;
        $cb->();
    };
}

1;
