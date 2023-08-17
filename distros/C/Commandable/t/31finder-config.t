#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Finder::Packages;

my $cmd_opts;
my $cmd_args;

package MyTest::Command::cmd {
   use constant COMMAND_NAME => "cmd";
   use constant COMMAND_DESC => "the cmd command";

   use constant COMMAND_ARGS => (
      { name => "args", description => "the argument", slurpy => 1 },
   );

   use constant COMMAND_OPTS => (
      { name => "opt", description => "the option", multi => 1 },
      { name => "verbose|v", description => "verbose", mode => "inc" },
   );

   sub run {
      $cmd_opts = shift;
      $cmd_args = [ @_ ];
   }
}

# don't require order
{
   my $finder = Commandable::Finder::Packages->new(
      base => "MyTest::Command",

      allow_multiple_commands => 1,
   );

   undef $cmd_opts;
   undef $cmd_args;
   $finder->find_and_invoke_list( qw( cmd --opt one arg --opt two more ) );

   is( $cmd_opts, { opt => [qw( one two) ] }, 'unordered options' );
   is( $cmd_args, [ [ qw( arg more ) ] ], 'unordered args' );

}

# require order
{
   my $finder = Commandable::Finder::Packages->new(
      base => "MyTest::Command",

      allow_multiple_commands => 1,
      require_order           => 1
   );

   undef $cmd_opts;
   undef $cmd_args;
   $finder->find_and_invoke_list( qw( cmd --opt one arg --opt two more ) );

   is( $cmd_opts, { opt => [qw( one ) ] }, 'ordered options' );
   is( $cmd_args, [ [ qw( arg --opt two more ) ] ], 'ordered args' );
}

# bundling
{
   my $finder = Commandable::Finder::Packages->new(
      base => "MyTest::Command",

      bundling => 1,
   );

   undef $cmd_opts;
   undef $cmd_args;
   $finder->find_and_invoke_list( qw( cmd -vvv arg ) );

   is( $cmd_opts, { verbose => 3 }, 'bundled options' );
   is( $cmd_args, [ [ qw( arg ) ] ], 'bundled args' );
}

done_testing();
