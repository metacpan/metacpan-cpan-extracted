#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Finder::MethodAttributes;

BEGIN {
   Commandable::Finder::SubAttributes::HAVE_ATTRIBUTE_STORAGE or
      plan skip_all => "Attribute::Storage is not available";
}

my @called;

package MyTest::Commands {
   use Commandable::Finder::MethodAttributes ':attrs';

   sub command_one
      :Command_description("the one command")
      :Command_arg("arg", "the argument")
   {
      my $self = shift;
      my ( $arg ) = @_;

      push @called, { self => $self, arg => $arg };
   }
}

my $finder = Commandable::Finder::MethodAttributes->new(
   object => my $object = bless {}, "MyTest::Commands",
);

# find_commands
{

   is( [ sort map { $_->name } $finder->find_commands ],
      [qw( help one )],
      '$finder->find_commmands' );
}

# a single command
{
   my $one = $finder->find_command( "one" );
   # can't test 'code' directly
   is( { map { $_, $one->$_ } qw( name description package ) },
      {
         name        => "one",
         description => "the one command",
         package     => "MyTest::Commands",
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

   $one->code->( "the argument" );
   is( \@called, [ { self => $object, arg => "the argument" } ],
      'Invoked code sees invocant object' );
}

done_testing;
