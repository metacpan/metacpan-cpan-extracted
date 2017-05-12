=head1 NAME

AnyEvent::Fork::Early - avoid having to exec another perl interpreter

=head1 SYNOPSIS

   # only usable in the main program, and must be called
   # as early as possible

   #!/usr/bin/perl
   use AnyEvent::Fork::Early;

   # now you can do other stuff

=head1 DESCRIPTION

L<AnyEvent::Fork> normally spawns a new perl process by executing the perl
binary. It does this because it is the only way to get a "clean state", as
the program using it might have loaded modules that are not fork friendly
(event loops, X11 interfaces and so on).

However, in some cases, there is no external perl interpreter to execute,
for example, when you use L<App::Staticperl> or L<PAR::Packer> to embed
perl into another program, and that program runs on another system without
perl installed.

And anyway, forking would still be more efficient, if it were possible.

And, as you hopefully guessed, this module makes this possible - it must
be run by the main program (i.e. to cannot be used in a module), and as
early as possible. How early? Well, early enough so that any other modules
can still be loaded and used, that is, before modules such as AnyEvent or
Gtk2 are being initialised.

Upon C<use>'ing the module, the process is forked, and the resulting
process is used as a template process for C<new> and C<new_exec>, so
everything should just work out.

Please resist the temptation to delay C<use>ing this module to
preload more modules that could be useful for your own purposes, see
L<AnyEvent::Fork::Template> for that.

=cut

package AnyEvent::Fork::Early;

# load stuff we need anyways
use AnyEvent::Fork ();

# this does not work on win32, due to the atrociously bad fake perl fork
unless ($^O eq "MSWin32") {
   # we preload certain modules because sooner or later, somebody will use them.
   # complain to me if that causes trouble.
   require common::sense;
   require strict;
   require warnings;
   require feature if $] >= 5.010;
   require Carp;

   require IO::FDPass;

   $AnyEvent::Fork::TEMPLATE =
   $AnyEvent::Fork::EARLY    = AnyEvent::Fork->_new_fork ("AnyEvent::Fork::Early");
}

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

