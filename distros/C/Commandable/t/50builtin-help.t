#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Finder::Packages;
use Commandable::Invocation;

package MyTest::Command::one {
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "the one command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument" }
   );
   use constant COMMAND_OPTS => (
      { name => "verbose|v", description => "verbose option" },
      { name => "target|t=", description => "target option" },
      { name => "silent",    description => "silent option", negatable => 1 },
   );
   sub run {}
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
   sub run {}
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

$finder->add_global_options(
   { name => "one", into => \my $ONE,
      description => "the 'one' option" },
   { name => "two=", into => \my $TWO, default => 444,
      description => "the 'two' option" },
);

sub output_from_command
{
   my ( $cmd ) = @_;

   my $output;

   no warnings 'redefine';
   local *Commandable::Output::printf = sub {
      shift;
      my ( $fmt, @args ) = @_;
      $output .= sprintf $fmt, @args;
   };

   $finder->find_and_invoke( Commandable::Invocation->new( $cmd ) );

   return $output;
}

# Output redirection
{
   my $output = output_from_command( "help" );

   is( $output, <<'EOF', 'Output from builtin help command' );
COMMANDS:
  help: Display a list of available commands
  one : the one command
  two : the two command

GLOBAL OPTIONS:
    --one
      the 'one' option

    --two <value>
      the 'two' option (default: 444)
EOF
}

# Output heading formatting
{
   no warnings 'redefine';
   local *Commandable::Output::format_heading = sub {
      shift;
      my ( $text, $level ) = @_;
      $level //= 1;

      return sprintf "%s %s %s", "*" x $level, $text, "*" x $level;
   };

   local *Commandable::Output::format_note = sub {
      shift;
      my ( $text, $level ) = @_;
      $level //= 0;

      return sprintf "%s%s%s", "<"x($level+1), $text, ">"x($level+1);
   };

   my $output = output_from_command( "help one" );

   is( $output, <<'EOF', 'Output from builtin "help one" command' );
<one> - the one command

* SYNOPSIS: *
  one [OPTIONS...] $ARG

* OPTIONS: *
    <<--[no-]silent>>
      silent option

    <<--target <value>>>, <<-t <value>>>
      target option

    <<--verbose>>, <<-v>>
      verbose option

* ARGUMENTS: *
  <<$ARG>>    the argument
EOF
}

done_testing;
