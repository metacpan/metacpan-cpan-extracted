#!/usr/bin/env perl
package
  Greetings_CLI_JSON;

use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [name => doc => 'Name of someone to be greeted'
      , default => 'world'
    ],
     qw/no-thanx x y/
   ];

sub hello :Doc(Say hello to someone) {
  my MY $self = shift;
  join " ", "Hello", $self->{name}
}

sub hi :Doc(Say Hi to someone) {
  my MY $self = shift; join " ", "Hi", $self->{name}
}

MY->cli_run(\@ARGV) unless caller;

1;
