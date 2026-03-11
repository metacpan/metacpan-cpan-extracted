package Moses;
# ABSTRACT: A framework for building IRC bots quickly and easily.
our $VERSION = '1.003';
use MooseX::POE ();
use Moose::Exporter;
use Adam;

Moose::Exporter->setup_import_methods(
    with_caller => [
        qw(
          nickname
          server
          port
          channels
          plugins
          username
          owner
          flood
          password
          poco_irc_args
          poco_irc_options
          )
    ],
    also => [qw(MooseX::POE)],
);


sub init_meta {
    my ( $class, %args ) = @_;

    my $for = $args{for_class};
    eval qq{
        package $for;
        use POE;
        use POE::Component::IRC::Common qw( :ALL );
    };

    Moose->init_meta(
        for_class  => $for,
        base_class => 'Adam'
    );
}

sub nickname {
    my ( $caller, $name ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_nickname' => sub { return $name } );
}


sub server {
    my ( $caller, $name ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_server' => sub { return $name } );
}


sub port {
    my ( $caller, $port ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_port' => sub { return $port } );
}


sub channels {
    my ( $caller, @channels ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_channels' => sub { return \@channels } );
}


sub plugins {
    my ( $caller, %plugins ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'custom_plugins' => sub { return \%plugins } );
}


sub username {
    my ( $caller, $username ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_username' => sub { return $username } );
}


sub password {
    my ( $caller, $password ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_password' => sub { return $password } );
}


sub flood {
    my ( $caller, $flood ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_flood' => sub { return $flood } );
}


sub owner {
    my ( $caller, $owner ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_owner' => sub { return $owner } );
}


sub poco_irc_args {
    my ( $caller, %extra_args ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_poco_irc_args' => sub { return \%extra_args }
    );
}


sub poco_irc_options {
    my ( $caller, %options ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_poco_irc_options' => sub { return \%options }
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moses - A framework for building IRC bots quickly and easily.

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    package SampleBot;
    use Moses;
    use namespace::autoclean;

    server 'irc.perl.org';
    nickname 'sample-bot';
    channels '#bots';

    has message => (
        isa     => 'Str',
        is      => 'rw',
        default => 'Hello',
    );

    event irc_bot_addressed => sub {
        my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
        my ($nick) = split /!/, $nickstr;
        $self->privmsg( $channel => "$nick: ${ \$self->message }" );
    };

    # Run with POE (default)
    __PACKAGE__->run unless caller;

    # Or run with IO::Async (requires IO::Async::Loop::POE)
    # __PACKAGE__->async unless caller;

=head1 DESCRIPTION

Moses is declarative sugar for building IRC bots based on the L<Adam> IRC bot
framework. Moses is designed to minimize the amount of work you have to do to
make an IRC bot functional, and to make the process as declarative as possible.

Bots can run in two modes: the default L<POE> event loop via C<run()>, or an
L<IO::Async> mode via C<async()> that enables integration with
L<IO::Async>-based components such as L<Net::Async::MCP> or
L<Net::Async::HTTP>. The async mode requires L<IO::Async::Loop::POE>.

=head2 nickname

    nickname 'sample-bot';

Set the nickname for the bot. Defaults to the current package name.

=head2 server

    server 'irc.perl.org';

Set the IRC server for the bot to connect to.

=head2 port

    port 6667;

Set the port for the bot's server. Defaults to C<6667>.

=head2 channels

    channels '#bots', '#perl';

Supply a list of channels for the bot to join upon connecting.

=head2 plugins

    plugins MyPlugin => 'MyBot::Plugin::Foo';

Extra L<POE::Component::IRC::Plugin> objects or class names to load into the bot.

=head2 username

    username 'mybot';

The username to use for IRC connection.

=head2 password

    password 'secret';

The server password to use for IRC connection.

=head2 flood

    flood 1;

Disable flood protection. Defaults to false.

=head2 owner

    owner 'nick!user@host';

The hostmask of the owner of the bot. The owner can control the bot's plugins
through IRC using the L<POE::Component::IRC::Plugin::PlugMan> interface.

=head2 poco_irc_args

    poco_irc_args LocalAddr => '127.0.0.1';

Extra arguments to pass to the IRC component constructor.

=head2 poco_irc_options

    poco_irc_options trace => 1;

Options to pass to the IRC component constructor.

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
