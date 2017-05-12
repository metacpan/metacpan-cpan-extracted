
package Contize;
use strict;
use Carp;

our $VERSION = '0.3';

our $AUTOLOAD;

=head1 NAME

Contize - Help an object be a continuation thingie (suspendable)

=head1 SYNOPSIS

  # Contize an object
  my $obj = new Contize(new Object);

  # An output-and-suspend method
  sub output {
    my ($self, $msg) = @_;
    print '<html><body><form method=post>'
    print $msg;
    print '</form></body></html>';
    $self->suspend;
  }

  # An input method
  sub input {
    my ($self, $msg) = @_;
    $self->output(
        $msg
      . '<input type="text" name="response">'
    );
    $q = new CGI;
    return $q->param('response');
  }

  # Now the magical bit!
  sub addTwo {
    my $self = shift;
    my $a = $self->input("Enter first number:");
    my $b = $self->input("Enter second number:");
    $self->output("Total of \$a + \$b = " . ($a + $b));
  }

  # This example would be completed with a wrapper script to save/restore the
  # object to disk between runs. See the WebGuess example

=head1 DESCRIPTION

Contize is primarily meant to be useful in the context of CGI programming. It
effectively alters the programmer's view of what is happening -- changing it
from a program which is run and re-run with each input/output into a program
which is continuously run, sending output and then pausing for input at certain
intervals. Documentation on using Contize for this style of CGI programming can
be found elsewhere, the remainder of this documentation will be more directly
on Contize (and who knows... maybe there is some other use for Contize of which
I haven't thought).

Contize helps an object to be suspendable and resumeable. For this to happen
the object must be Contized, which is a lot like being blessed or Memoized.
Once an object has been Contized several new methods are provided to it. The
two most important methods are suspend and resume.

The suspend method logically replaces the normal return statement. So instead
of a method returning its results directly it instead does
"$self->suspend(@results)". The suspend method contains an 'exit', so upon
suspend the entire process is terminated. In order to succesfully be resumed at
a later point, the owner of this object should have an END block which saves
the Contized object to long-term storage.

The resume method is called by the program after it has restored the Contized
object from long-term storage. This restores the objects internal state so that
subsequent calls to its methods will (more or less) pick up right where they
left off. So, if you have a CGI::Session object for example, you might have
something like this:

  my $obj = $session->param('obj') || new Contize(new MyObj);
  $obj->resume();
  $obj->run();

Fun, eh?

=head1 METHODS

=over

=item $thingie = new Contize($thingie)

Takes a $thingie object and continuizes it... we replace it with ourselves and
intercept all method calls.

Note that we take over the following elements of the hash:

=over

=item _child - our child object we've overtaken

=item _cache - count for how we are doing catch-up wise

=item _nocache - a list of methods not to cache

=item _callstack - the current call stack (array)

=item _callstack_count - the current count of the top callstack item

=back

So you probably should't use these as variables in the real object.

=cut

sub new {
  my $class = shift;
  my $child = shift;
  # For now we assume our child uses a hash as it's data. Lets take it's
  # existing data and make it ours
  my $self = { %{$child} };
  bless $self, $class;
  # Now we must save our child so we can actually call it's methods later
  $self->{_child} = $child;
  # Clear out the callstack and the count for a new trace
  undef $self->{_callstack};
  undef $self->{_callstack_count};
  return $self;
}


=item $thingie->nocache('methodname1', 'methodname2', ...)

Turn off caching for the given methods

=cut

sub nocache {
  my ($self, @methods) = @_;
  push @{$self->{_nocache}}, @methods;
}


=item $thingie->somemethod(@params) ... aka AUTOLOAD

AUTOLOAD actually does the work. We intercept method invocations and usually
cache the results. Difficult to explain...

=cut

sub AUTOLOAD {
  my ($self, @args) = @_;
  my $name = $AUTOLOAD;
  my $val;
  # Chop off the 'Contize::' namespace
  $name =~ s/.*://;
  # Figure out the method's full name
  my $method = (ref $self->{_child}) . "::$name";
  if($self->{_child}->can($method)) {

    # Keep track of this invocation through our internal stacks
    push @{$self->{_callstack}}, $name;
    my $callstack = "@{$self->{_callstack}}";
    my $count = ++$self->{_callstack_count}{$callstack};
    push @{$self->{_callstack}}, $count;

    # Check to see if we should cache the result
    if(grep {$_ eq $name} @{$self->{_nocache}}) {
      # We should NOT cache the result.
      $val = $self->$method(@args);
    } else {
      $callstack = "@{$self->{_callstack}}";
      if(exists $self->{_cache}{$callstack}) {
        # We've already cached this call, lets just return it
        $val = $self->{_cache}{$callstack};
      } else {
        # We've never done this before, lets run it...
        $val = $self->$method(@args);
        # Cache all method calls (direct AND inherited)
        $self->{_cache}{$callstack} = $val;

        use Data::Dumper;
      }
    }
    pop @{$self->{_callstack}}; # The num
    pop @{$self->{_callstack}}; # and the name
    return $val;
  } else {
    if($name ne 'DESTROY') {
      carp "Method '$method' not implemented.";
    }
  }
}


=item $thingie->suspend($retval)

This replaces the return function in a subroutine and suspends the object. When
the object is resumed it will give $retval to the caller.

=cut

sub suspend {
  my $self = shift;
  my $retval = shift;
  my $callstack = "@{$self->{_callstack}}";
  $self->{_cache}{$callstack} = $retval;
  #$self->{_child}->cleanup() if ($self->{_child}->can('cleanup'));
  $self->cleanup();
  exit;
}


=item $thingie->resume()

Reset the thingie so that it will be re-run. This clears the callstack and the
callstack_count so that it will begin returning cached results.

=cut

sub resume {
  my $self = shift;
  undef $self->{_callstack};
  undef $self->{_callstack_count};
}


=item DESTROY

Upon destruction we undef our child, thus calling the child's own DESTROY, if
such a thing exists. I'm pretty sure this is the proper way to do things, but
it might break if their DESTROY does more complicated activities.

=cut

sub DESTROY {
  my $self = shift;
  undef $self->{_child};
}
  

=back

=head1 BUGS/LIMITATIONS

Contize has quite a bit of overhead for internal caching of method invocations.

There should be a bit more documentation here on how Contize actuall works.

Contize will only work on objects which use a hash as their core thingie.

=head1 SEE ALSO

L<Coro::Cont>, L<http://thelackthereof.org/wiki.pl/Contize>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org>
  http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2004 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

1;

