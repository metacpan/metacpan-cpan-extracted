

package Class::Delegation::Simple;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.02';

sub import
{
  my ($class, @args) = @_;
  my ($caller) = caller;
  
  # Install the handler(s):
  no strict 'refs';
  no warnings 'redefine';
  while( my $set = shift(@args) )
  {
    my $to = $set->{to};
    my $method = $set->{send};
    my $as = $set->{as} || $method;
    *{"$caller\::$method"} = sub {
      my $s = shift;
      if( ref($to) )
      {
        my @res;
        push @res, $s->{$_}->$as( @_ ) foreach @$to;
        return @res if defined(wantarray);
      }
      else
      {
        $s->{$to}->$as( @_ );
      }# end if()
    };
  }# end while()
}# end import()

1;# return true:

__END__

=pod

=head1 NAME

Class::Delegation::Simple - Simple delegation for Perl

=head1 SYNOPSIS

  package Delegator1;

  use strict;
  use warnings 'all';
  use Class::Delegation::Simple {
      send => 'steer',
      to   => 'wheel',
      as   => 'turn',
    },
    {
      send => 'wipe',
      to   => [qw/ left_wiper right_wiper /]
    };

  sub new
  {
    my ($class, %args) = @_;
    
    return bless {
      wheel       => Echo->new('wheel'),
      left_wiper  => Echo->new('left_wiper'),
      right_wiper => Echo->new('right_wiper'),
    }, $class;
  }# end new()

The "Echo" class:

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

The test script:

  #!perl -w
  
  use strict;
  use warnings 'all';
  use Delegator1;
  
  my $del = Delegator1->new();
  
  $del->steer('right');  # "Method 'steer'(right) called on 'wheel'!"
  $del->steer('left');   # "Method 'steer'(left) called on 'wheel'!"
  $del->wipe('medium');  # "Method 'wipe'(medium) called on 'left_wiper'! Method 'wipe'(medium) called on 'right_wiper'!"

=head1 DESCRIPTION

Class delegation is simply a way to get around some of the problems presented by class inheritance.

You can specify that you want some method calls to be handled by one or more attributes of your own choosing.

This is much cleaner than constantly hacking out the following:

  sub steer
  {
    my ($s) = shift;
    $s->{wheel}->steer( @_ );
  }
  
  sub wipe
  {
    my ($s) = shift;
    my @result = (
      $s->{left_wiper}->wipe( @_ ),
      $s->{right_wiper}->wipe( @_ )
    );
    return @result;
  }

=head1 BUT DOES IT WORK IN MOD_PERL?

Yes - it works in mod_perl.  Unlike some other Perl Delegation modules on CPAN, this
module does not depend on the C<INIT> phase to get the work done.  This means that
it should work just fine in persistent environments such as mod_perl.

=head1 COPYRIGHT

Copyright 2008 John Drago jdrago_999@yahoo.com

=head1 LICENSE

This software is Free software and may be used and redistributed under the same terms as perl itself.

=cut

