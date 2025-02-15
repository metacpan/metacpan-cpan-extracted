#!/usr/bin/env perl
use v5.38;
use experimental 'class';

class GreetingsClass;

field $name :param;

method hello {
  join " ", "Hello", $name;
};

method hi {
  join " ", "Hi", $name;
};

sub parse_args {
  my ($pack, $argList) = @_;
  my @args;
  while (@$argList and $argList->[0] =~ m{
    ^--
    (?:
     (?<name>[-\w]+)
     (?:
      =
      (?<value>.*)
    )?
   )?
    \z
  }xs) {
    shift @$argList;
    last if $& eq "--";
    push @args, $+{name}, $+{value} // 1;
  }
  @args;
}

unless (caller) {
  my @params = __PACKAGE__->parse_args(\@ARGV);

  my $cmd = shift @ARGV
    or die "Usage: $0 COMMAND ARGS...\n";

  my $self = __PACKAGE__->new(name => "world", @params);

  if (my $sub = $self->can("cmd_$cmd")) {
    $sub->($self, @ARGV)
  }
  elsif ($sub = $self->can("$cmd")) {
    print $self->$cmd(@ARGV), "\n";
  }
  else {
    die "Unknown command: $cmd\n";
  }
}

1;

