=head1 NAME

AnyEvent::Fork::Template - generate a template process from the main program

=head1 SYNOPSIS

   # only usable in the main program

   # preload some harmless modules (just examples)
   use Other::Module;
   use Some::Harmless::Module;
   use My::Worker::Module;

   # now fork and keep the template
   use AnyEvent::Fork::Template;

   # now do less harmless stuff (just examples)
   use Gtk2 -init;
   my $w = AE::io ...;

   # and finally, use the template to run some workers
   $AnyEvent::Fork::Template->fork->run ("My::Worker::Module::run_worker", sub { ... });

=head1 DESCRIPTION

By default, this module forks when it is used the first time and stores
the resulting L<AnyEvent::Fork> object in the C<$AnyEvent::Fork::Template>
variable (mnemonic: same name as the module itself).

It must only be used in the main program, and only once. Other than that,
the only requirement is that you can handle the results of a fork at that
time, i.e., when you use this module after AnyEvent has been initialised,
or use it after you opened some window with Gtk2 or Tk for example then
then you can't easily use these modules in the forked process. Choosing
the place to use this module wisely is key.

There is never a need for this module - you can always create a new empty
process and loading the modules you need into it.

=cut

package AnyEvent::Fork::Template;

use AnyEvent::Fork ();

# this does not work on win32, due to the atrociously bad fake perl fork
die "AnyEvent::Fork::Template does not work on WIN32 due to bugs in perl\n"
   if $^O eq "MSWin32";

$AnyEvent::Fork::Template = AnyEvent::Fork->_new_fork ("AnyEvent::Fork::Template");

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

