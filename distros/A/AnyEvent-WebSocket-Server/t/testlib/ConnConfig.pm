package testlib::ConnConfig;
use strict;
use warnings;
use Test::More;

sub _new {
    my ($class, %fields) = @_;
    my $self = bless {
        map { ($_ => $fields{$_}) } qw(label is_ok server_args client_args client_handle_base scheme address)
    }, $class;
    return $self;
}

sub all_conn_configs {
    my ($class) = @_;
    return (
        $class->_new(
            label => "conn:ws",
            is_ok => 1,
            server_args => [],
            client_args => [],
            client_handle_base => [],
            scheme => "ws",
            address => "127.0.0.1"
        ),
        
        $class->_new(
            label => "conn:wss, separate",
            is_ok => 1,
            server_args => [
                ssl_key_file => "t/data/ssl_test.key",
                ssl_cert_file => "t/data/ssl_test.crt"
            ],
            client_args => [
                ssl_ca_file => "t/data/ssl_test.crt"
            ],
            client_handle_base => [
                tls => "connect",
                tls_ctx => {
                    ca_file => "t/data/ssl_test.crt"
                }
            ],
            scheme => "wss",
            address => "127.0.0.1",
        ),
        
        $class->_new(
            label => "conn:wss, combined",
            is_ok => 1,
            server_args => [
                ssl_cert_file => "t/data/ssl_test.combined.key",
            ],
            client_args => [
                ssl_ca_file => "t/data/ssl_test.crt"
            ],
            client_handle_base => [
                tls => "connect",
                tls_ctx => {
                    ca_file => "t/data/ssl_test.crt"
                }
            ],
            scheme => "wss",
            address => "127.0.0.1"
        ),

        $class->_new(
            label => "client: tls, server: plain",
            is_ok => 0,
            server_args => [],
            client_args => [
                ssl_ca_file => "t/data/ssl_test.crt"
            ],
            client_handle_base => [
                tls => "connect",
                tls_ctx => {
                    ca_file => "t/data/ssl_test.crt"
                }
            ],
            scheme => "wss",
            address => "127.0.0.1",
        ),

        $class->_new(
            label => "client: plain, server: tls",
            is_ok => 0,
            server_args => [
                ssl_cert_file => "t/data/ssl_test.combined.key",
            ],
            client_args => [],
            client_handle_base => [],
            scheme => "ws",
            address => "127.0.0.1"
        ),
    );
}

my $optional_module_diaged = 0;

sub _optional_module {
    my ($module_load) = @_;
    my $ret = eval "use $module_load; 1";
    if(!$ret) {
        if(!$optional_module_diaged) {
            diag "Some tests require $module_load. Skipped them.";
            $optional_module_diaged = 1;
        }
        plan skip_all => "Test requires $module_load";
    }
}

sub _run_code {
    my ($self, $code) = @_;
    subtest $self->label, sub {
        if(!$self->is_plain_socket_transport) {
            _optional_module("Net::SSLeay");
            _optional_module("AnyEvent::TLS");
        }
        $code->($self);
    };
}

sub for_all_ok_conn_configs {
    my ($class, $code) = @_;
    foreach my $cconfig (grep { $_->is_ok } $class->all_conn_configs) {
        $cconfig->_run_code($code);
    }
}

sub for_all_ng_conn_configs {
    my ($class, $code) = @_;
    foreach my $cconfig (grep { !$_->is_ok } $class->all_conn_configs) {
        $cconfig->_run_code($code);
    }
}

sub label { $_[0]->{label} }
sub server_args { @{$_[0]->{server_args}} }
sub client_args { @{$_[0]->{client_args}} }
sub is_ok { $_[0]->{is_ok} }

sub client_handle_args {
    my ($self, $port) = @_;
    return (
        connect => [$self->{address}, $port],
        @{$self->{client_handle_base}}
    );
}

sub connect_url {
    my ($self, $port, $path) = @_;
    my $port_str = defined($port) ? ":$port" : "";
    my $path_str = defined($path) ? $path : "";
    return qq{$self->{scheme}://$self->{address}$port_str$path_str};
}

sub is_plain_socket_transport {
    my ($self) = @_;
    my %server_args = $self->server_args;
    return ($self->{scheme} eq "ws" && !defined($server_args{ssl_cert_file}) && !defined($server_args{ssl_key_file}));
}

1;
