package Adam::Plugin;
# ABSTRACT: A base class for Adam/Moses plugins
our $VERSION = '1.002';
use Moose;
use namespace::autoclean;


has bot => (
    isa      => 'Adam',
    is       => 'ro',
    required => 1,
    handles  => [
        qw(
          log
          owner
          irc
          yield
          privmsg
          nick
          )
    ],
);


has _events => (
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    builder => 'default_events',
    handles => { _list_events => 'elements' }
);

sub default_events {
    [ grep { /^[SU]_\w+/ } shift->meta->get_all_method_names ];
}


sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;
    my @events = $self->_list_events;
    my @s_events = map { s/^S_//; $_ } grep { /^S_/ } @events;
    my @u_events = map { s/^U_//; $_ } grep { /^U_/ } @events;
    $irc->plugin_register($self, 'SERVER', @s_events) if @s_events;
    $irc->plugin_register($self, 'USER', @u_events) if @u_events;
    return 1;
}


sub PCI_unregister {
    my ( $self, $irc ) = @_;
    return 1;
}


sub _default {
    my ( $self, $irc, $event ) = @_;
    $self->log->notice("_default called for $event");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Adam::Plugin - A base class for Adam/Moses plugins

=head1 VERSION

version 1.002

=head1 DESCRIPTION

The Adam::Plugin class implements a base class for Adam/Moses IRC bot plugins.

=head2 bot

The L<Adam> bot instance. Required. Handles several methods from the bot
including C<log>, C<owner>, C<irc>, C<yield>, C<privmsg>, and C<nick>.

=head2 default_events

The default events that this plugin will listen to. Returns an ArrayRef of all
methods prefixed with C<S_> (server events) or C<U_> (user events) in the current
class.

=head2 PCI_register

Called when the plugin is registered with the IRC component. Automatically
registers server and user events based on method names.

=head2 PCI_unregister

Called when the plugin is unregistered from the IRC component.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
