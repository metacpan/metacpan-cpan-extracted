
package Delegator1;

use strict;
use warnings 'all';
use Class::Delegation::Simple({
    send => 'steer',
    to   => 'wheel',
    as   => 'turn',
});
use Class::Delegation::Simple({
    send => 'wipe',
    to   => [qw/ left_wiper right_wiper /]
});

sub new
{
  my ($class, %args) = @_;
  
  return bless {
    wheel       => Echo->new('wheel'),
    left_wiper  => Echo->new('left_wiper'),
    right_wiper => Echo->new('right_wiper'),
  }, $class;
}# end new()



package Echo;

sub new
{
  my ($class, $name) = @_;
  return bless { name => $name }, $class;
}# end new()

sub AUTOLOAD
{
  my ($s, @args) = @_;
  our $AUTOLOAD;
  my ($method) = $AUTOLOAD =~ m/::([^:]+)$/;
  return "Method '$method'(@args) called on '$s->{name}'!";
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:

