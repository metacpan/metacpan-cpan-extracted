#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Invocation;
use Commandable::Finder::Packages;

package MyTest::Command::one {
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "a basic command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument" }
   );
   sub run {}
}

package MyTest::Command::optarg {
   use constant COMMAND_NAME => "optarg";
   use constant COMMAND_DESC => "a command with an optional argument";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument", optional => 1 }
   );
   sub run {}
}

package MyTest::Command::slurpyarg {
   use constant COMMAND_NAME => "slurpyarg";
   use constant COMMAND_DESC => "a command with a slurpy argument";
   use constant COMMAND_ARGS => (
      { name => "args", description => "the arguments", slurpy => 1 }
   );
   sub run {}
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

# mandatory arg
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "value" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [qw( value )],
      '$cmd->parse_invocation with mandatory argument' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );

   like(
      dies { $finder->parse_invocation( $cmd, Commandable::Invocation->new( "" ) ) },
      qr/^Expected a value for 'arg' argument/,
      '$cmd->parse_invocation fails with no argument' );
}

# optional arg
{
   my $cmd = $finder->find_command( "optarg" );

   my $inv = Commandable::Invocation->new( "value" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [qw( value )],
      '$cmd->parse_invocation with optional argument present' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );

   is( [ $finder->parse_invocation( $cmd, Commandable::Invocation->new( "" ) ) ], [],
      '$cmd->parse_invocation with optional argument absent' );
}

# slurpy arg
{
   my $cmd = $finder->find_command( "slurpyarg" );

   my $inv = Commandable::Invocation->new( "x y z" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ [qw( x y z )] ],
      '$cmd->parse_invocation with slurpy argument' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

done_testing;
