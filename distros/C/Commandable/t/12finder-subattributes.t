#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Commandable::Finder::SubAttributes;

BEGIN {
   Commandable::Finder::SubAttributes::HAVE_ATTRIBUTE_STORAGE or
      plan skip_all => "Attribute::Storage is not available";
}

package MyTest::Commands {
   use Commandable::Finder::SubAttributes ':attrs';

   sub command_one
      :Command_description("the one command")
      :Command_arg("arg", "the argument")
   {
      # command
   }

   sub command_two
      :Command_description("the two command")
   {
      # command
   }
}

my $finder = Commandable::Finder::SubAttributes->new(
   package => "MyTest::Commands",
);

# find_commands
{

   is_deeply( [ sort map { $_->name } $finder->find_commands ],
      [qw( help one two )],
      '$finder->find_commmands' );
}

# a single command
{
   my $one = $finder->find_command( "one" );
   is_deeply( { map { $_, $one->$_ } qw( name description package code ) },
      {
         name        => "one",
         description => "the one command",
         package     => "MyTest::Commands",
         code        => \&MyTest::Commands::command_one,
      },
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
