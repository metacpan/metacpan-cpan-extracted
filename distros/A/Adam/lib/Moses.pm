package Moses;
BEGIN {
  $Moses::VERSION = '0.91';
}
# ABSTRACT: A framework for building IRC bots quickly and easily.
# Dist::Zilla: +PodWeaver
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


=pod

=head1 NAME

Moses - A framework for building IRC bots quickly and easily.

=head1 VERSION

version 0.91

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

	__PACKAGE__->run unless caller;

=head1 DESCRIPTION

Moses is some declarative sugar for building an IRC bot based on the
L<Adam|Adam> IRC Bot. Moses is designed to minimize the amount of work you
have to do to make an IRC bot functional, and to make the process as
declarative as possible. 

=head1 FUNCTIONS

=head2 nickname (Str $name)

Set the nickname for the bot. Default's to the current package.

=head2 username(Str)

The username which we should use

=head2 password(Str)

The server password which we shoulduse

=head2 server (Str $server)

Set the server for the bot.

=head2 port (Int $port)

Set the port for the bot's server. Default's to 6667.

=head2 owner (Str)

The hostmask of the ower of the bot. The owner can control the bot's plugins
through IRC using the <POE::Component::IRC::Plugin::Plugman|Plugman>
interface.

=head2 flood (Bool)

Disable flood protection. Defaults to False.

=head2 channels (@channels)

Supply a list of channels for the bot to join upon connecting.

=head2 plugins (@plugins)

Extra L<POE::Component::IRC::Plugin|POE::Component::IRC::Plugin> objects or
class names to load into the bot.

=head2 extra_args (HashRef)

A list of extra arguments to pass to the irc constructor.

=head1 DEPENDENCIES

The same dependencies as L<Adam|Adam>. 

L<MooseX::POE|MooseX::POE>, L<namespace::autoclean|namespace::autoclean>,
L<MooseX::Alias|MooseX::Alias>, L<POE::Component::IRC|POE::Component::IRC>,
L<MooseX::Getopt|MooseX::Getopt>,
L<MooseX::SimpleConfig|MooseX::SimpleConfig>,
L<MooseX::LogDispatch|MooseX::LogDispatch>

=head1 BUGS AND LIMITATIONS

None known currently, please report bugs to L<https://rt.cpan.org/Ticket/Create.html?Queue=Adam>

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

