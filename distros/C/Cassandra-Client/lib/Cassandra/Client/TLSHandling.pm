package Cassandra::Client::TLSHandling;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::TLSHandling::VERSION = '0.17';
use 5.010;
use strict;
use warnings;

# SSLeay needs initialization
use Net::SSLeay 1.63 qw/die_now MODE_ENABLE_PARTIAL_WRITE MODE_ACCEPT_MOVING_WRITE_BUFFER/;
BEGIN {
    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
}

use Devel::GlobalDestruction;

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
    return if in_global_destruction;

    my $self= shift;

    Net::SSLeay::CTX_free($$self);
}

1;

package Cassandra::Client::TLSHandling::conn;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::TLSHandling::conn::VERSION = '0.17';
use 5.010;
use strict;
use warnings;

use Devel::GlobalDestruction;

sub DESTROY {
    local $@;
    return if in_global_destruction;

    my $self= shift;
    Net::SSLeay::free($$self);
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::TLSHandling

=head1 VERSION

version 0.17

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
