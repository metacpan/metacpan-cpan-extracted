package Alzabo::ChangeTracker;

use strict;

use vars qw( $VERSION $STACK @CHANGES );

$VERSION = 2.0;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    ++$STACK;

    my $self = $STACK;
    bless \$self, $class;
}

sub add
{
    my $self = shift;

    validate_pos( @_, { type => CODEREF } );

    push @CHANGES, shift;
}

sub backout
{
    my $self = shift;

    $_->() foreach @CHANGES;

    @CHANGES = ();
}

sub DESTROY
{
    --$STACK;

    @CHANGES = () unless $STACK;
}

__END__

=head1 NAME

Alzabo::ChangeTracker - Saves a set of changes as callbacks that can be backed out if needed

=head1 SYNOPSIS

  use Alzabo::ChangeTracker;

  my $x = 0;
  my $y = 1;
  sub foo
  {
     my $tracker = Alzabo::ChangeTracker->new;
     $tracker->add( sub { $x = 0; } );

     $x = 1;

     bar();

     eval { something; };

     $tracker->backout if $@;
  }

  sub bar
  {
     my $tracker = Alzabo::ChangeTracker->new;
     $tracker->add( sub { $y = 1; } );

     $y = 2;
  }


=head1 DESCRIPTION

The trick ...

We only want to have one object of this type at any one time.  In
addition, only the stack frame that created it should be able to clear
it (except through a backout).  Why?  Here's an example in pseudo-code
to help explain it:

 sub foo
 {
   create a tracker;
   store some change info in the tracker;

   call sub bar;

   store some change info in the tracker;

   # point Y

   clear changes in tracker;
 }

 sub bar
 {
   create a tracker; # internally, we really just increment our stack count

   store some change info in the tracker;

   clear changes in tracker; # point X
 }

If at point X we were to really clear out the changes, even the
changes just from sub bar, we'd have a problem.  Because if at point
Y, things go to hell and we want to back out the changes, we want to
back out the changes from sub foo _AND_ sub bar.  However, if bar is
also an entry point we want to be able to track changes in bar and
clear them from bar.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
