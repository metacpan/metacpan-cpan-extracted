#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Commandable::Finder::Packages;

my $cmd_opts;

package MyTest::Command::cmd {
   use constant COMMAND_NAME => "cmd";
   use constant COMMAND_DESC => "the cmd command";

   use constant COMMAND_OPTS => (
      { name => "verbose|v", description => "verbose option" },
      { name => "target|t=", description => "target option" },
   );

   sub run {
      $cmd_opts = shift;
   }
}

my $finder = Commandable::Finder::Packages->new(
   base => "MyTest::Command",
);

my $THREE;
$finder->add_global_options(
   { name => "one", into => \my $ONE },
   { name => "two=", into => \my $TWO, default => 444 },
   { name => "three=", into => sub { $THREE = $_[1] } },
);

{
   undef $ONE; undef $TWO; undef $THREE;

   $finder->find_and_invoke_list( qw( --one --two=222 --three=three cmd ) );

   is( $ONE, T(), '$ONE is true after --one' );
   is( $TWO, 222, '$TWO is 222 after --two=222' );
   is( $THREE, "three", '$THREE is three after --three=three' );
}

# mixed ordering
{
   undef $ONE; undef $TWO; undef $THREE;

   $finder->find_and_invoke_list( qw( cmd --three=later ) );

   is( $THREE, "later", '$THREE is parsed even after command name' );
}

# command-specific opts still work
{
   undef $TWO; undef $cmd_opts;

   $finder->find_and_invoke_list( qw( cmd --three=abc --target=def ) );

   is( $THREE, "abc",                  '$THREE is parsed with command opt' );
   is( $cmd_opts, { target => "def" }, 'target is parsed with command opt' );
}

# defaults
{
   undef $ONE; undef $TWO;

   $finder->find_and_invoke_list( qw( cmd ) );

   is( $ONE, F(), '$ONE defaults false' );
   is( $TWO, 444, '$TWO defaults to 444' );
}

done_testing;
