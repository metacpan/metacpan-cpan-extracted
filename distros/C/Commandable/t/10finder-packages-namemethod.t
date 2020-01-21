#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Commandable::Finder::Packages;

{
   package MyTest::Command::one;
   use constant COMMAND_NAME => "one";
   use constant COMMAND_DESC => "the one command";

   package MyTest::Command::two;
   use constant COMMAND_NAME => "two";
   use constant COMMAND_DESC => "the two command";

   package MyTest::Command::nothing;
   sub foo {}; # not a command
}

{
   my $finder = Commandable::Finder::Packages->new(
      base => "MyTest::Command",
   );

   is_deeply( [ sort map { $_->name } $finder->find_commands ],
      [qw( one two )],
      '$finder->find_commands' );

   my $one = $finder->find_command( "one" );
   is_deeply( { map { $_, $one->$_ } qw( name description package ) },
      { name => "one", description => "the one command",
        package => "MyTest::Command::one", },
      '$finder->find_command' );
}

done_testing;
