use strict;
use warnings;

package TestNet::Bot::AtoZ;

use Bot::Net::Bot;
use Bot::Net::Mixin::Bot::IRCD;

=head1 NAME

TestNet::Bot::AtoZ - A semi-autonomous agent that does something

=head1 SYNOPSIS

  bin/botnet run --bot AtoZ

=head1 DESCRIPTION

A semi-autonomous agent that does something. This documentation needs replacing.

=cut

on _start => run {
    remember alpha => 'A';
};

on [ qw/ bot_message_to_me bot_message_to_group / ] => run {
    my $event = get ARG0;
    my $alpha = recall 'alpha';
    recall('log')->info("Sending $event $alpha");
    yield reply_to_sender => $event => $alpha++;
    remember alpha => $alpha;
};

1;

