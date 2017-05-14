
# $Id: Handler.pm,v 1.3 2000/09/12 19:43:02 nwiger Exp $
#################################################################
#
# Copyright (c) 2000, Nathan Wiger <nate@sun.com>
#
# Class::Handler - Create Apache-like pseudoclass event handlers
#
#################################################################

require 5.003;
package Class::Handler;

use strict;
no strict 'refs';
use vars qw(@EXPORT @ISA $VERSION $AUTOLOAD);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(handler nohandler);

# Internal recordkeeping
my %HANDLERS;

# Both of these functions are exported, and basically just work by
# pushing stuff in and out of arrays and hashes. The AUTOLOAD
# routine is then used for the meat of everything.

sub handler ($@) {

   my($handler, @classes) = @_;

   # If no package name, we simply prefix the caller's
   # package name to it.

   my $pkg  = caller;
   $handler = "$pkg\::$handler" unless $handler =~ /^\w+::\w+/;

   # If the handler is new, all we have to do is add Class::Handler
   # to @ISA for the handler name, since we want our own AUTOLOAD
   # to handle method dispatch.

   @{"${handler}::ISA"} = ('Class::Handler') unless exists $HANDLERS{$handler};

   # We push the new classes onto the end of the handler list.
   # We do not allow multiple instances of the same class because
   # this is most likely an error caused by duplicate or overlapping
   # importing of modules.

   for my $c (@classes) {
       next if grep /^$c$/, @{$HANDLERS{$handler}};
       push @{$HANDLERS{$handler}}, $c or return undef;
   }
   return 1;
}


sub nohandler ($@) {

   my($handler, @classes) = @_;

   # First, remove the selected classes from the handler list
   # Again, first check to make sure we have a full pkg name

   my $pkg  = caller;
   $handler = "$pkg\::$handler" unless $handler =~ /^\w+::\w+/;

   my @tmp_classes;
   for my $c (@classes) {
       for my $ec (@{$HANDLERS{$handler}}) {
           next if $c eq $ec;
           push @tmp_classes, $ec;
       }
       $HANDLERS{$handler} = \@tmp_classes;
   }

   # Check to see if we have anything left; if not, remove the
   # @ISA array and delete the %HANDLERS hash entry. Testing
   # @tmp_classes instead of the handlers list will implicitly
   # catch the single-arg syntax used for removing handlers.

   unless (@tmp_classes) {
      undef @{"${handler}::ISA"};
      delete $HANDLERS{$handler};
   }

   return 1;
}

sub AUTOLOAD {

   # This does all the real work, attempting to use each of the
   # methods from a given handler's classes in turn.
   my($ret, @ret);

   # Chop our $AUTOLOAD down
   my($handler, $method) = $AUTOLOAD =~ m/^(.*)::(\w+)$/g;

   # For each class listed in the %HANDLERS list, we try to use
   # its method in turn. If it doesn't exist or returns undef,
   # we go to the next one in line.

   for my $c (@{$HANDLERS{$handler}}) {
       next unless ${c}->can($method);

       # This is the only way we can catch different return contexts
       if (wantarray()) {
           (@ret = ${c}->$method(@_)) ? return(@ret) : next;
       } else {
           ($ret = ${c}->$method(@_)) ? return($ret) : next;
       }
   }
   return undef;
}

1;

__END__ 

=head1 NAME

Class::Handler - Create Apache-like pseudoclass event handlers

=head1 SYNOPSIS

  use Class::Handler;

  handler http => 'My::Module';
  handler http => 'My::OtherModule';
  http->dostuff(@args);           # Tries My::Module->dostuff,
                                  # then My::OtherModule->dostuff
                                  # if it fails or is not found

  nohandler http => 'My::Module'; # Remove My::Module from the
                                  # list of modules to try

  nohandler http;                 # Remove http handler entirely

=head1 DESCRIPTION

=head2 Overview

This module can be used to create and maintain pseudoclass event
handlers, which are simply special classes which inherit from
multiple modules but provide no methods of their own. These handlers
can be used just like normal classes, with the added benefit that
they are able to decline or partially handle requests, allowing
multiple classes to act on the same data through the same interface.

This serves the dual purpose of acting as both a complete Perl 5
module as well as a prototype for a proposed Perl 6 feature.

=head2 Adding and Using Handlers

To add a handler, you simply use the handler() method which is
automatically exported by this module. handler() takes two arguments,
the first being the name of the handler and the second the name of
a class which should be added to that handler:

   handler signal => 'Signal::DoStuff';

This would install a new handler called C<signal> which would have
one class, C<Signal::DoStuff>, in it. You can install multiple
handlers at the same time:

   handler exception => 'My::Catch', 'Site::Failsafe';

or as multiple subsequent commands:

   handler exception => 'My::Catch';
   handler exception => 'Site::Failsafe';

The theory behind these handlers is much like the theory behind
Apache handlers. Whatever the name of the method is that is called
on the pseudoclass, is the name of the method that is called on
the actual classes. For example, assuming this code:

   handler http => 'My::HTTP';
   handler http => 'LWP::UserAgent';
   $FH = http->open("http://www.yahoo.com");

Then the following sequence of events would occur:

  $FH         http->open                            undef
   ^              |                                   ^
   |              |                                   |
   |  Does My::HTTP->open exist?                      |
   |        YES/     \NO                              |
   |          /       \                               |
   |      Try it     Does LWP::UserAgent->open exist? |
   |       / \        ^      YES/     \NO             |
   |    OK/   \UNDEF /         /       ----------------
   -------     ------       Try it                    |
   |                         /  \                     |
   |                      OK/    \UNDEF               |
   -------------------------      ---------------------

Some highlights:

   1. Each class's open() method is tried in turn, since
      that is the name of the method called on the handler

   2. If undef is returned, the next one in sequence is
      tried.

   3. If 'OK' (simply meaning 1 or some other true value,
      like $FH) is returned, that is propagated out and
      returned by the top-level handler.

   4. All classes are tried until 'OK' is returned or the
      last one is reached.
      
This allows you to easily chain classes and methods together with a
couple key benefits over an inline C<||>:

   1. Each handler can partially handle the request, but
      still return undef, deferring to the next one in line.

   2. The handlers can be reordered internally at-will
      without the main program having to be redone.

   3. Different class open() methods can use internal
      rules, such as "only open .com URLs", without
      you having to put checks for this all over the
      place in the top-level program.

For more details, please see the Perl 6 RFC listed below.

=head2 Removing Handlers

In addition to handlers being added, they need to be removed as well.
This is where nohandler() comes in:

   nohandler http => 'My::HTTP'; # remove My::HTTP from list
   nohandler http;               # remove http handler

The first example removes C<My::HTTP> from the list of classes used
by the C<http> handler. The second syntax removes the C<http> handler
entirely, meaning that this call:

   $FO = http->open("http://www.yahoo.com");

will result in the familiar error:

   Can't locate object method "open" via package "http"

Currently, there is no way to reorder handlers without removing and
then re-adding them.

=head2 Automatic Handler Registration and Removal

Sometimes, you may find that you want a class to automatically
register as a member of a given handler. To do so, you simply need
to C<use Class::Handler> in your module and then prefix the package
C<main::> (or whatever package you want to affect) to the start
of the handler name:

   package Custom::Module;

   use Class::Handler;
   handler 'main::stuff' => 'Custom::Module';

This will make it so that in your main script you can now do this:

   use Custom::Module;
   stuff->method(@args);

And it will call the Custom::Module->method function as expected.

However, this feature should be used with caution. It borders right
on the edge of scary action-at-a-distance.

=head1 REFERENCES

For more details on the complete Perl 6 proposal, please visit
http://dev.perl.org/rfc/101.html. Comments are welcome.

=head1 AUTHOR 

Copyright (c) 2000, Nathan Wiger <nate@sun.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

