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
   use constant COMMAND_OPTS => (
      { name => "verbose|v", description => "verbose option" },
      { name => "target|t:", description => "target option" },
   );
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
   use constant COMMAND_OPTS => (
      { name => "default", description => "default option", default => "value" },
   );
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

# no opt
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ {} ],
      '$cmd->parse_invocation with no options' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by longname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--verbose" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with longname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by shortname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with shortname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (space)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target TARG" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with space-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (equals)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target=TARG" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with equals-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with default value
{
   my $cmd = $finder->find_command( "two" );

   my $inv = Commandable::Invocation->new( "" );

   is_deeply( [ $cmd->parse_invocation( $inv ) ], [ { default => "value" } ],
      '$cmd->parse_invocation with default option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

done_testing;
