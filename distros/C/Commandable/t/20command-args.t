#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Commandable::Invocation;
use Commandable::Finder::Packages;

package MyTest::Command::one {
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "the one command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument" }
   );
}

package MyTest::Command::optarg {
   use constant COMMAND_NAME => "optarg";
   use constant COMMAND_DESC => "the optarg command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument", optional => 1 }
   );
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

# mandatory arg
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "value" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [qw( value )],
      '$cmd->parse_invocation with mandatory argument' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );

   like(
      exception { $cmd->parse_invocation( Commandable::Invocation->new( "" ) ) },
      qr/^Expected a value for 'arg' argument/,
      '$cmd->parse_invocation fails with no argument' );
}

# optional arg
{
   my $cmd = $finder->find_command( "optarg" );

   my $inv = Commandable::Invocation->new( "value" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [qw( value )],
      '$cmd->parse_invocation with optional argument present' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );

   is_deeply( [ $cmd->parse_invocation( Commandable::Invocation->new( "" ) ) ], [],
      '$cmd->parse_invocation with optional argument absent' );
}

done_testing;
