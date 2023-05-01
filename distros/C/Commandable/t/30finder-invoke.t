#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Finder::Packages;
use Commandable::Invocation;

my $cmd_opts;
my $cmd_args;

package MyTest::Command::cmd {
   use constant COMMAND_NAME => "cmd";
   use constant COMMAND_DESC => "the cmd command";

   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument", optional => 1 }
   );

   use constant COMMAND_OPTS => (
      { name => "verbose|v", description => "verbose option" },
      { name => "target|t=", description => "target option" },
   );

   sub run {
      $cmd_opts = shift;
      $cmd_args = [ @_ ];
   }
}

my $cmd2_args;
package MyTest::Command::cmd2 {
   use constant COMMAND_NAME => "cmd2";
   use constant COMMAND_DESC => "the cmd2 command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument" },
   );
   sub run {
      $cmd2_args = [ @_ ];
   }
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",

   allow_multiple_commands => 1,
);

# no args
{
   undef $cmd_args;

   $finder->find_and_invoke( Commandable::Invocation->new( "cmd" ) );

   ok( defined $cmd_args, 'cmd command invoked' );
   is( $cmd_args, [], 'cmd command given no args' );
}

# one arg
{
   undef $cmd_args;

   $finder->find_and_invoke( Commandable::Invocation->new( "cmd argument" ) );

   is( $cmd_args, [ "argument" ], 'cmd command given one arg' );
}

# one option
{
   undef $cmd_args;
   undef $cmd_opts;

   $finder->find_and_invoke( Commandable::Invocation->new( "cmd --verbose" ) );

   is( $cmd_args, [], 'cmd command given one option' );
   is( $cmd_opts, { verbose => 1 }, 'cmd command given one option' );
}

# two options
{
   undef $cmd_args;
   undef $cmd_opts;

   $finder->find_and_invoke( Commandable::Invocation->new( "cmd --verbose --target=red" ) );

   is( $cmd_args, [], 'cmd command given two options' );
   is( $cmd_opts, { verbose => 1, target => "red" }, 'cmd command given two options' );
}

# multiple commands
{
   undef $cmd_args;
   undef $cmd_opts;

   $finder->find_and_invoke( Commandable::Invocation->new( "cmd arg cmd2 arg2" ) );
}

done_testing;
