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
   );
   sub run {}
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
   use constant COMMAND_OPTS => (
      { name => "default", description => "default option", default => "value" },
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

   is( [ $cmd->parse_invocation( $inv ) ], [ {} ],
      '$cmd->parse_invocation with no options' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by longname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--verbose" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with longname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt by shortname
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { verbose => 1 } ],
      '$cmd->parse_invocation with shortname' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# hyphen converts to underscore
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-h" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { hyphenated_name => 1 } ],
      '$cmd->parse_invocation with hyphenated name' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (space)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target TARG" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with space-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with value (equals)
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--target=TARG" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { target => "TARG" } ],
      '$cmd->parse_invocation with equals-separated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# multi value
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "--multi=one --multi two" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { multi => [ qw(one two) ] } ],
      '$cmd->parse_invocation with repeated value' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# opt with default value
{
   my $cmd = $finder->find_command( "two" );

   my $inv = Commandable::Invocation->new( "" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { default => "value" } ],
      '$cmd->parse_invocation with default option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# negatable opt with default value
{
   my $cmd = $finder->find_command( "three" );

   my $inv = Commandable::Invocation->new( "" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { silent => 1 } ],
      '$cmd->parse_invocation with negatable option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# negated opt with default value
{
   my $cmd = $finder->find_command( "three" );

   my $inv = Commandable::Invocation->new( "--no-silent" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { silent => undef } ],
      '$cmd->parse_invocation with negated option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# incrementable opt
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v -v -v" );

   is( [ $cmd->parse_invocation( $inv ) ], [ { verbose => 3 } ],
      '$cmd->parse_invocation with repeated incrementable option' );
   ok( !length $inv->peek_remaining, '->parse_invocation consumed input' );
}

# incrementable opts can't take values
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-v3" );

   like( dies { $cmd->parse_invocation( $inv ) },
      qr/^Unexpected value for parameter verbose/,
      '$cmd->parse_invocation fails with value to incrementable option' );
}

# i-typed options check for numerical
{
   my $cmd = $finder->find_command( "one" );

   my $inv = Commandable::Invocation->new( "-n1" );

   ok( lives {
      is( [ $cmd->parse_invocation( $inv ) ], [ { number => 1 } ],
         '$cmd->parse_invocation with integer-numerical option' );
      } );

   $inv = Commandable::Invocation->new( "-nBAD" );

   like( dies { $cmd->parse_invocation( $inv ) },
      qr/^Value for parameter number must be an integer/,
      '$cmd->parse_invocation fails with non-integer value' );
}

done_testing;
