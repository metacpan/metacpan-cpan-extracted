package Beekeeper::JSONRPC::AuthHeaders;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME
 
Beekeeper::JSONRPC::AuthHeaders - Access to request auth headers
 
=head1 VERSION
 
Version 0.01

=cut

use Exporter 'import';

our @EXPORT_OK = qw(
    connection_id
    get_auth_tokens
    has_auth_tokens
);

our %EXPORT_TAGS = ('all' => \@EXPORT_OK );


sub connection_id {
    my $self = shift;

    return $self->{_headers}->{'x-session'};
}

sub get_auth_tokens {
    my $self = shift;

    my $auth_hdr = $self->{_headers}->{'x-auth-tokens'};

    return unless defined $auth_hdr;

    return split(/\|/, $auth_hdr);
}

sub has_auth_tokens {
    my ($self, @check_tokens) = @_;

    my $auth_hdr = $self->{_headers}->{'x-auth-tokens'};

    return unless defined $auth_hdr;
    return unless @check_tokens;

    my @tokens = split(/\|/, $auth_hdr);

    foreach my $token (@check_tokens) {
        return unless defined $token && length $token;
        return unless grep { $token eq $_ } @tokens;
    }

    return 1;
}

1;

=encoding utf8

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
