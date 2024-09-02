#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Invocation;
use Commandable::Finder::Packages;

package MyTest::Command::one {
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "the one command";
   use constant COMMAND_OPTS => (
      { name => "verbose|v", description => "verbose option", mode => "inc" },
      { name => "target|t=", description => "target option" },
      { name => "multi",     description => "multi option", multi => 1 },
      { name => "hyphenated-name|h", description => "option with hyphen in its name" },
      { name => "number|n=i", description => "number option" },
      { name => "count|c=u", description => "count option" },
      { name => "size=f", description => "float option" },
   );
   sub run {}
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
   use constant COMMAND_OPTS => (
      { name => "with-default", description => "default option", default => "value" },
   );
   sub run {}
}

package MyTest::Command::three {
   use constant COMMAND_NAME => "three";
   use constant COMMAND_DESC => "the three command";
   use constant COMMAND_OPTS => (
      { name => "silent", description => "silent option", mode => "bool", default => 1 },
   );
   sub run {}
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

# no opt
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ {} ],
      '$cmd->parse_invocation with no options' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by longname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--verbose" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with longname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by shortname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with shortname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# hyphen converts to underscore
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-h" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { hyphenated_name => 1 } ],
      '$cmd->parse_invocation with hyphenated name' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (space)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target TARG" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with space-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (equals)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target=TARG" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with equals-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# multi value
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--multi=one --multi two" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { multi => [ qw(one two) ] } ],
      '$cmd->parse_invocation with repeated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with default value
{
   my $cmd = $finder->find_command( "two" );

   my $inv = Commandable::Invocation->new( "" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { with_default => "value" } ],
      '$cmd->parse_invocation with default option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# negatable opt with default value
{
   my $cmd = $finder->find_command( "three" );

   my $inv = Commandable::Invocation->new( "" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { silent => 1 } ],
      '$cmd->parse_invocation with negatable option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# negated opt with default value
{
   my $cmd = $finder->find_command( "three" );

   my $inv = Commandable::Invocation->new( "--no-silent" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { silent => !!0 } ],
      '$cmd->parse_invocation with negated option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# incrementable opt
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v -v -v" );

   is( [ $finder->parse_invocation( $cmd, $inv ) ], [ { verbose => 3 } ],
      '$cmd->parse_invocation with repeated incrementable option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# incrementable opts can't take values
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v3" );

   like( dies { $finder->parse_invocation( $cmd, $inv ) },
      qr/^Unexpected value for parameter verbose/,
      '$cmd->parse_invocation fails with value to incrementable option' );
}

# typed options
{
   my $cmd = $finder->find_command( "one" );

   ok( lives {
      is( [ $finder->parse_invocation( $cmd,
               Commandable::Invocation->new( "-n1" ) ) ],
          [ { number => 1 } ],
         '$cmd->parse_invocation with integer-numerical option' );
      } );

   like( dies { $finder->parse_invocation( $cmd,
            Commandable::Invocation->new( "-nBAD" ) ) },
      qr/^Value for --number option must be an integer/,
      '$cmd->parse_invocation fails with non-integer value' );

   ok( lives {
      is( [ $finder->parse_invocation( $cmd,
               Commandable::Invocation->new( "-c5" ) ) ],
          [ { count => 5 } ],
         '$cmd->parse_invocation with integer count option' );
      } );

   like( dies { $finder->parse_invocation( $cmd,
            Commandable::Invocation->new( "-c-5" ) ) },
      qr/^Value for --count option must be a non-negative integer/,
      '$cmd->parse_invocation fails with negative count' );

   ok( lives {
      is( [ $finder->parse_invocation( $cmd,
               Commandable::Invocation->new( "--size=1.234" ) ) ],
          [ { size => 1.234 } ],
         '$cmd->parse_invocation with size option' );
      } );

   like( dies { $finder->parse_invocation( $cmd,
            Commandable::Invocation->new( "--size=BAD" ) ) },
      qr/^Value for --size option must be a floating-point number/,
      '$cmd->parse_invocation fails with bad size' );
}

done_testing;
