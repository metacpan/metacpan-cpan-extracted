# Adam/Moses Bot Framework

A declarative framework for building IRC bots based on POE and Moose.

## Description

The Adam/Moses Bot Framework provides a simple, declarative way to create IRC bots in Perl. It's built on top of POE::Component::IRC and uses Moose for clean object-oriented design.

Moses provides declarative sugar that makes bot creation straightforward, while Adam is the underlying implementation class.

## Installation

From CPAN:

```bash
cpanm Adam
```

From source:

```bash
git clone https://github.com/perigrin/adam-bot-framework.git
cd adam-bot-framework
cpanm --installdeps .
```

## Basic Usage

```perl
package MyBot;
use Moses;
use namespace::autoclean;

server 'irc.perl.org';
nickname 'mybot';
channels '#bots';

event irc_bot_addressed => sub {
    my ($self, $nickstr, $channel, $msg) = @_[OBJECT, ARG0, ARG1, ARG2];
    my ($nick) = split /!/, $nickstr;
    $self->privmsg($channel => "$nick: Hello!");
};

__PACKAGE__->run unless caller;
```

## Features

- **Declarative syntax** - Simple DSL for bot configuration
- **Plugin system** - Easy to extend with POE::Component::IRC plugins
- **Multiple event loops** - Supports both POE (default) and IO::Async
- **Command-line options** - Built-in support via MooseX::Getopt
- **Logging** - Configurable logging via MooseX::LogDispatch

## IO::Async Support

You can use IO::Async as the event loop (requires IO::Async::Loop::POE):

```perl
package AsyncBot;
use Moses;
use namespace::autoclean;

server 'irc.perl.org';
nickname 'asyncbot';
channels '#ai';

event irc_join => sub {
    my ( $self, $nickstr, $channel ) = @_[ OBJECT, ARG0, ARG1 ];
    my ($nick) = split /!/, $nickstr;
    return unless $nick eq $self->get_nickname;
    $self->privmsg( $channel => "Hello, artificial humans!" );
};

__PACKAGE__->async unless caller;
```

Use `$bot->stop` to cleanly stop the event loop in both POE and IO::Async modes.

## Links

- [CPAN](https://metacpan.org/pod/Adam)
- [GitHub](https://github.com/perigrin/adam-bot-framework)
- [Documentation](https://metacpan.org/pod/Moses)
