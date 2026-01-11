package Claude::Agent::Message;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

# Load subclasses
use Claude::Agent::Message::Base;
use Claude::Agent::Message::User;
use Claude::Agent::Message::Assistant;
use Claude::Agent::Message::System;
use Claude::Agent::Message::Result;

=head1 NAME

Claude::Agent::Message - Message types for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Message;

    # Messages are returned from query iteration
    while (my $msg = $iter->next) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print $msg->result, "\n";
        }
    }

=head1 DESCRIPTION

This module contains all message types returned by the Claude Agent SDK.

=head1 MESSAGE TYPES

=over 4

=item * L<Claude::Agent::Message::User> - User messages

=item * L<Claude::Agent::Message::Assistant> - Claude's responses

=item * L<Claude::Agent::Message::System> - System messages (init, status)

=item * L<Claude::Agent::Message::Result> - Final result

=back

=head1 METHODS

=head2 from_json

    my $msg = Claude::Agent::Message->from_json($data);

Factory method to create the appropriate message type from JSON data.

=cut

# Convert camelCase to snake_case
# Handles consecutive uppercase letters correctly (e.g., 'UUID' -> 'uuid', 'getHTTPURL' -> 'get_http_url')
sub _camel_to_snake {
    my ($str) = @_;
    return $str unless defined $str;
    # Handle consecutive uppercase followed by lowercase (e.g., 'HTTPUrl' -> 'HTTP_Url')
    $str =~ s/([A-Z]+)([A-Z][a-z])/${1}_$2/g;
    # Handle lowercase/digit followed by uppercase (e.g., 'getId' -> 'get_Id')
    $str =~ s/([a-z\d])([A-Z])/${1}_$2/g;
    return lc($str);
}

# Map camelCase JSON keys to snake_case Perl attributes
sub _normalize_data {
    my ($data) = @_;

    my %normalized;
    for my $key (keys %$data) {
        my $new_key = _camel_to_snake($key);
        $normalized{$new_key} = $data->{$key};
    }

    return \%normalized;
}

sub from_json {
    my ($class, $data) = @_;

    my $normalized = _normalize_data($data);
    my $type = $normalized->{type} // '';

    if ($type eq 'user') {
        return Claude::Agent::Message::User->new(%$normalized);
    }
    elsif ($type eq 'assistant') {
        return Claude::Agent::Message::Assistant->new(%$normalized);
    }
    elsif ($type eq 'system') {
        return Claude::Agent::Message::System->new(%$normalized);
    }
    elsif ($type eq 'result') {
        return Claude::Agent::Message::Result->new(%$normalized);
    }
    else {
        # Return generic message for unknown types
        return Claude::Agent::Message::Base->new(%$normalized);
    }
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
