#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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
      :Command_opt("simple")
      :Command_opt("bool!")
      :Command_opt("multi@")
   {
      # command
   }

   sub command_with_hyphen
      :Command_description("command with hyphenated name")
   {
      # command
   }
}

my $finder = Commandable::Finder::SubAttributes->new(
   package => "MyTest::Commands",
);

# find_commands
{

   is( [ sort map { $_->name } $finder->find_commands ],
      [qw( help one two with-hyphen )],
      '$finder->find_commmands' );
}

# a single command
{
   my $one = $finder->find_command( "one" );
   is( { map { $_, $one->$_ } qw( name description package code ) },
      {
         name        => "one",
         description => "the one command",
         package     => "MyTest::Commands",
         code        => \&MyTest::Commands::command_one,
      },
      '$finder->find_command' );

   is( scalar $one->arguments, 1, '$one has an argument' );

   my ( $arg ) = $one->arguments;
   is( { map { $_ => $arg->$_ } qw( name description ) },
      {
         name        => "arg",
         description => "the argument",
      },
      'metadata of argument to one'
   );
}

# command options
{
   my $two = $finder->find_command( "two" );
   my %opts = $two->options;

   is( { map { my $opt = $opts{$_}; $_ => { map { $_ => $opt->$_ } qw( mode negatable ) } } keys %opts },
      {
         simple => { mode => "set",         negatable => F() },
         bool   => { mode => "set",         negatable => T() },
         multi  => { mode => "multi_value", negatable => F() },
      },
      'metadata of options to two' );
}

done_testing;
