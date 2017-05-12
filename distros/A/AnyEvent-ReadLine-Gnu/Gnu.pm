=head1 NAME

AnyEvent::ReadLine::Gnu - event-based interface to Term::ReadLine::Gnu

=head1 SYNOPSIS

 use AnyEvent::ReadLine::Gnu;

 # works always, prints message to stdout
 AnyEvent::ReadLine::Gnu->print ("message\n");

 # now initialise readline
 my $rl = new AnyEvent::ReadLine::Gnu prompt => "hi> ", on_line => sub {
    # called for each line entered by the user
    AnyEvent::ReadLine::Gnu->print ("you entered: $_[0]\n");
 };

 # asynchronously print something
 my $t = AE::timer 1, 1, sub {
    $rl->hide;
    print "async message 1\n"; # mind the \n
    $rl->show;

    # the same, but shorter:
    $rl->print ("async message 2\n");
 };

 # do other eventy stuff...
 AE::cv->recv;

=head1 DESCRIPTION

The L<Term::ReadLine> module family is bizarre (and you are encouraged not
to look at its sources unless you want to go blind). It does support
event-based operations, somehow, but it's hard to figure out.

It also has some utility functions for printing messages asynchronously,
something that, again, isn't obvious how to do.

This module has figured it all out for you, once and for all.

=over 4

=cut

package AnyEvent::ReadLine::Gnu;

use common::sense;
use AnyEvent;

BEGIN {
   # we try our best
   local $ENV{PERL_RL} = "Gnu";

   require Term::ReadLine;
   require Term::ReadLine::Gnu;
}

use base Term::ReadLine::;

our $VERSION = '1.0';

=item $rl = new AnyEvent::ReadLine::Gnu key => value...

Creates a new AnyEvent::ReadLine object.

Actually, it only configures readline and provides a convenient way to
call the show and hide methods, as well as readline methods - this is a
singleton.

The returned object is the standard L<Term::ReadLine::Gnu> object, all
methods that are documented (or working) for that module should work on
this object.

Once initialised, this module will also restore the terminal settings on a
normal program exit.

The callback will be installed with the C<CallbackHandlerInstall>, which
means it handles history expansion and history, among other things.

The following key-value pairs are supported:

=over 4

=item on_line => $cb->($string)

The only mandatory parameter - passes the callback that will receive lines
that are completed by the user.

The string will be in locale-encoding (a multibyte character string). For
example, in an utf-8 using locale it will be utf-8. There is no portable
way known to the author to convert this into e.g. a unicode string.

=item prompt => $string

The prompt string to use, defaults to C<< >  >>.

=item name => $string

The readline application name, defaults to C<$0>.

=item in => $glob

The input filehandle (should be a glob): defaults to C<*STDIN>.

=item out => $glob

The output filehandle (should be a glob): defaults to C<*STDOUT>.

=back

=cut

our $self;
our $prompt;
our $cb;
our $hidden;
our $rw;
our ($in, $out);

our $saved_point;
our $saved_line;

# we postpone calling the user clalback here because readline
# still has the input buffer at this point, so calling hide and
# show might not have the desired effect.
sub on_line {
   my $line = shift;
   my $point = $self->{point};

   AE::postpone sub {
      $cb->($line, $point);
   };
}

sub new {
   my ($class, %arg) = @_;

   $in     = $arg{in}  || *STDIN;
   $out    = $arg{out} || *STDOUT;
   $prompt = $arg{prompt} || "> ";
   $cb     = $arg{on_line} || $arg{cb}
      or do { require Carp; Carp::croak ("AnyEvent::ReadLine::Gnu->new on_line callback argument mandatry, but missing") };

   $self = $class->SUPER::new ($arg{name} || $0, $in, $out);

   $Term::ReadLine::Gnu::Attribs{term_set} = ["", "", "", ""];
   $self->CallbackHandlerInstall ($prompt, \&on_line);

   $hidden = 1;
   $self->show;

   $self
}

=item $rl->hide

=item AnyEvent::ReadLine::Gnu->hide

These methods I<hide> the readline prompt and text. Basically, it removes
the readline feedback from your terminal.

It is safe to call even when AnyEvent::ReadLine::Gnu has not yet been
initialised.

This is immensely useful in an event-based program when you want to output
some stuff to the terminal without disturbing the prompt - just C<hide>
readline, output your thing, then C<show> it again.

Since user input will not be processed while readline is hidden, you
should call C<show> as soon as possible.

=cut

sub hide {
   return if !$self || $hidden++;

   undef $rw;

   $saved_point = $self->{point};
   $saved_line  = $self->{line_buffer};

   $self->rl_set_prompt ("");
   $self->{line_buffer} = "";
   $self->rl_redisplay;
}

=item $rl->show

=item AnyEvent::ReadLine::Gnu->show

Undos any hiding. Every call to C<hide> has to be followed to a call to
C<show>. The last call will redisplay the readline prompt, current input
line and cursor position. Keys entered while the prompt was hidden will be
processed again.

=cut

sub show {
   return if !$self || --$hidden;

   if (defined $saved_point) {
      $self->rl_set_prompt ($prompt);
      $self->{line_buffer} = $saved_line;
      $self->{point}       = $saved_point;
      $self->redisplay;
   }

   $rw = AE::io $in, 0, sub {
      $self->rl_callback_read_char;
   };
}

=item $rl->print ($string, ...)

=item AnyEvent::ReadLine::Gnu->print ($string, ...)

Prints the given strings to the terminal, by first hiding the readline,
printing the message, and showing it again.

This function can be called even when readline has never been initialised.

The last string should end with a newline.

=cut

sub print {
   shift;

   hide;
   my $out = $out || *STDOUT;
   print $out @_;
   show;
}

END {
   return unless $self;

   $self->hide;
   $self->callback_handler_remove;
}

1;

=back

=head1 CAVEATS

There are some issues with readline that can be problematic in event-based
programs:

=over 4

=item blocking I/O

Readline uses blocking terminal I/O. Under most circumstances, this does
not cause big delays, but ttys have the potential to block programs
indefinitely (e.g. on XOFF).

=item unexpected disk I/O

By default, readline does filename completion on TAB, and reads its
config files.

Tab completion can be disabled by calling C<< $rl->unbind_key (9) >>.

=item tty settings

After readline has been initialised, it will mangle the termios tty
settings. This does not normally affect output very much, but should be
taken into consideration.

=item output intermixing

Your program might wish to print messages (for example, log messages) to
STDOUT or STDERR. This will usually cause confusion, unless readline is
hidden with the hide method.

=back

Oh, and the above list is probably not complete.

=head1 AUTHOR, CONTACT, SUPPORT

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/AnyEvent-ReadLine-Gnu.html

=head1 SEE ALSO

L<rltelnet> - a simple tcp_connect-with-readline program using this module.

=cut

