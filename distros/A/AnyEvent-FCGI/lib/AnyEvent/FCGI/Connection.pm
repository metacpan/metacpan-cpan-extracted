package AnyEvent::FCGI::Connection;

=head1 NAME

AnyEvent::FCGI::Connection - a single connection handle for L<AnyEvent::FCGI>

=head1 DESCRIPTION

This module represents a single connection for L<AnyEvent::FCGI>
This module would not be used directly by a program using C<AnyEvent::FCGI>.

=cut

use strict;
use warnings;

use Scalar::Util qw/weaken refaddr/;

use AnyEvent::Handle;
use AnyEvent::FCGI::Request;

use constant MAX_DATA_SIZE => 65535;

sub new {
    my ($class, %params) = @_;
    
    my $self = bless {
        fcgi => $params{fcgi},
        requests => {},
    }, $class;
    
    $self->{io} = new AnyEvent::Handle(
        fh => $params{fh},
        on_error => sub {$self->_on_error(@_)},
    );
    $self->{io}->push_read(chunk => 8, sub {$self->_on_read_header(@_)});
    
    weaken($self->{fcgi});
    
    return $self;
}

sub _on_error {
    my ($self, $io, $fatal, $message) = @_;
    
    if ($fatal) {
        $self->_shutdown;
    }
}

sub _shutdown {
    my ($self) = @_;
    
    $self->{requests} = {};
    delete $self->{fcgi}->{connections}->{refaddr($self)};
}

sub _on_read_header {
    my ($self, $io, $header) = @_;
    
    my %record;
    (
        $record{version},
        $record{type},
        $record{request_id},
        $record{length},
        $record{padding},
        undef
    ) = unpack('ccnncc', $header);
    $self->{record} = \%record;
    
    $io->push_read(chunk => ($record{length} + $record{padding}), sub {$self->_on_read_content(@_)});
}

sub _on_read_content {
    my ($self, $io, $data) = @_;
    
    $self->{record}->{content} = substr($data, 0, $self->{record}->{length});
    $self->_process_record($self->{record});
    
    $io->push_read(chunk => 8, sub {$self->_on_read_header(@_)});
}

sub _process_record {
    my ($self, $record) = @_;
    
    return unless $record->{version} == AnyEvent::FCGI->FCGI_VERSION_1;
    
    my $request = $self->{requests}->{$record->{request_id}};
    if ($record->{type} == AnyEvent::FCGI->FCGI_BEGIN_REQUEST) {
        unless (defined $request) {
            my ($role, $flags) = unpack('nc', $record->{content});
            
            if ($role == AnyEvent::FCGI->FCGI_RESPONDER) {
                $self->{requests}->{$record->{request_id}} = new AnyEvent::FCGI::Request(
                    fcgi => $self->{fcgi},
                    connection => $self,
                    flags => $flags,
                    id => $record->{request_id},
                );
            } else {
                warn 'AnyEvent::FCGI supports only responder role';
            }
        } else {
            warn "Request '$record->{request_id}' already running";
        }
    } elsif ($record->{type} == AnyEvent::FCGI->FCGI_STDIN && defined $request) {
        $request->_process_stdin_record($record);
    } elsif ($record->{type} == AnyEvent::FCGI->FCGI_PARAMS && defined $request) {
        $request->_process_params_record($record);
    } elsif ($record->{type} == AnyEvent::FCGI->FCGI_ABORT_REQUEST && defined $request) {
        delete $request->{connection};
        delete $self->{requests}->{$request->{id}};
    }
}

sub send_record {
    my ($self, $record) = @_;
    
    if (length $record->{content} > MAX_DATA_SIZE) {
        warn 'Record content length > MAX_DATA_SIZE, truncating';
        $record->{content} = substr($record->{content}, 0, MAX_DATA_SIZE);
    }
    
    $self->{io}->push_write(
        pack('ccnncc',
            AnyEvent::FCGI->FCGI_VERSION_1,
            $record->{type},
            $record->{request_id},
            length $record->{content},
            0,
            0,
        ) . $record->{content}
    );
}

sub DESTROY {
    my ($self) = @_;
    
    if ($self) {
        $self->_shutdown;
    }
}

1;
