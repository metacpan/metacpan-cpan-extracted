#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Commandable::Finder::Packages;

package MyTest::Command::one {
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "the one command";
   use constant COMMAND_ARGS => (
      { name => "arg", description => "the argument" }
   );
}

package MyTest::Command::two {
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";
}

package MyTest::Command::nothing {
   sub foo {} # not a command
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

# find_commands
{

   is_deeply( [ sort map { $_->name } $finder->find_commands ],
      [qw( help one two )],
      '$finder->find_commands' );
}

# a single command
{
   my $one = $finder->find_command( "one" );

   is_deeply( { map { $_, $one->$_ } qw( name description package ) },
      { name => "one", description => "the one command",
        package => "MyTest::Command::one", },
      '$finder->find_command' );

   is( scalar $one->arguments, 1, '$one has an argument' );

   my ( $arg ) = $one->arguments;
   is_deeply( { map { $_ => $arg->$_ } qw( name description ) },
      {
         name        => "arg",
         description => "the argument",
      },
      'metadata of argument to one'
   );
}

done_testing;
