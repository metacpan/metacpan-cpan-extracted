#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

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
      { name => "target|t:", description => "target option" },
   );
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
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
help: Display a list of available commands
one : the one command
two : the two command
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
    <<--target>>, <<-t>>
      target option

    <<--verbose>>, <<-v>>
      verbose option

* ARGUMENTS: *
  <<$ARG>>    the argument
EOF
}

done_testing;
