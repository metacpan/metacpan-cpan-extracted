use strict;
use warnings;

package Bot::Net::Script::Run;
use base qw/ App::CLI::Command /;

use Bot::Net;
use POE;
use UNIVERSAL::require;

=head1 NAME

Bot::Net::Script::Run - Run a single server or bot

=head1 SYNOPSIS

  # To run a server
  bin/botnet run --server ServerName

  # To run a bot
  bin/botnet run --bot BotName

=head1 DESCRIPTION

Starts a single server or bot process.

=head1 METHODS

=head2 options

Returns the options used by the scrip. See L<App::CLI::Command>.

=cut

sub options {
    (
        'bot'    => 'bot',
        'server' => 'server',
    )
}

=head2 run

Runs the requested server or bot.

=cut

sub run {
    my ($self, $name) = @_;

    die "No bot or server name given to the run command. Quitting.\n"
        unless $name;

    $name = ucfirst $name;
    my $class = $self->{bot}    ? Bot::Net->net_class('Bot', $name)
              : $self->{server} ? Bot::Net->net_class('Server', $name)
              : die "No --bot or --server option given.\n";

    $class->require;
    die "Failed to load $name: $@" if $@;

    $class->setup;
    POE::Kernel->run;
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
