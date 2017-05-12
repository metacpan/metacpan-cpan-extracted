package Cassandra::Client::TLSHandling;
use 5.010;
use strict;
use warnings;

# SSLeay needs initialization
use Net::SSLeay qw/die_now MODE_ENABLE_PARTIAL_WRITE MODE_ACCEPT_MOVING_WRITE_BUFFER/;
BEGIN {
    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
}

sub new {
    my ($class)= @_;

    my $ctx= Net::SSLeay::CTX_new() or die_now("Unable to create OpenSSL context");
    my $self= bless \$ctx, $class;

    Net::SSLeay::CTX_set_options($$self, Net::SSLeay::OP_ALL() | Net::SSLeay::OP_NO_SSLv2() | Net::SSLeay::OP_NO_SSLv3());
    Net::SSLeay::CTX_set_mode($$self, MODE_ENABLE_PARTIAL_WRITE | MODE_ACCEPT_MOVING_WRITE_BUFFER);
    return $self;
}

sub new_conn {
    my ($self)= @_;
    my $tls= Net::SSLeay::new($$self) or die_now("Unable to create OpenSSL SSL object");
    return bless \$tls, "Cassandra::Client::TLSHandling::conn";
}

sub DESTROY {
    local $@;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my $self= shift;

    Net::SSLeay::CTX_free($$self);
}

1;

package Cassandra::Client::TLSHandling::conn;
use 5.010;
use strict;
use warnings;

sub DESTROY {
    local $@;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my $self= shift;
    Net::SSLeay::free($$self);
}

1;
