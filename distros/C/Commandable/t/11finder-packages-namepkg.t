#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Commandable::Finder::Packages;

package MyTest::Command::one {
   use constant COMMAND_DESC => "the one command";
   sub run {}
}

package MyTest::Command::two {
   use constant COMMAND_DESC => "the two command";
   sub run {}
}

package MyTest::Command::nothing {
   sub foo {} # not a command
}

{
   my $finder = Commandable::Finder::Packages->new(
      base => "MyTest::Command",
      named_by_package => 1,
   );

   is_deeply( [ sort map { $_->name } $finder->find_commands ],
      [qw( help one two )],
      '$finder->find_commands' );

   my $one = $finder->find_command( "one" );
   is_deeply( { map { $_, $one->$_ } qw( name description package ) },
      { name => "one", description => "the one command",
        package => "MyTest::Command::one", },
      '$finder->find_command' );
}

done_testing;
