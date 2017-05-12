package Archlinux::Term;

use warnings;
use strict;

use Term::ANSIColor qw(color);
use Text::Wrap      qw(wrap);
use Exporter;

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(msg status substatus warning error);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );
our $VERSION     = '0.03';

our ($Columns, $Mono) = (78, undef);

sub _word_wrap
{
    my ($prefix, $msg) = @_;

    if ( eval { $Columns > 0 } ) {
        my $spaces = q{ } x length $prefix;

        local $Text::Wrap::columns = $Columns + 1;
        return wrap( $prefix, $spaces, $msg );
    }

    return $prefix . $msg;
}

sub _color_wrap
{
    my ($color, $prefix, @messages) = @_;

    # Wrap the uncolored first because ANSI color chars mess up wrap()
    # (it doesn't know the ANSI color codes are invisible)
    my $msg          = join q{}, @messages;
    $msg             =~ s/\s*\n\s*/ /g;

    my $result       = _word_wrap( $prefix, $msg );
    my $prefix_match = quotemeta $prefix;

    return $result if ( $Mono );

    # Now colorize the prefix and stuff...
    $result =~ s{ \A $prefix_match } # Use \033[0;1m cuz Term::ANSIColor
                { color( 'BOLD', $color ) . $prefix . "\e[0;1m" }exms;
    $result .= color( 'RESET' );     # ... doesnt have very bright white!

    return $result;
}

sub msg
{
    my @messages = @_;
    chomp $messages[-1];

    my $prefix = q{ } x 4;

    print _word_wrap( $prefix, join q{}, @messages ), "\n";
}

sub status
{
    print _color_wrap( 'GREEN' => q{==> }, @_ ), "\n";
}

sub substatus
{
    print _color_wrap( 'BLUE' => q{  -> }, @_ ), "\n";
}

sub warning
{
    my @args = @_;
    chomp $args[-1];
    warn _color_wrap( 'YELLOW' => q{==> WARNING: }, @args ), "\n";
}

sub error
{
    my @args = @_;
    chomp $args[-1];
    die _color_wrap( 'RED' => q{==> ERROR: }, @args ), "\n";
}

1;

__END__

=head1 NAME

Archlinux::Term - Print messages to the terminal in Archlinux style

=head1 SYNOPSIS

  use Archlinux::Term;

  status( 'This is a status message' );
  substatus( 'This is a substatus message' );
  warning( 'This is a warning message' );
  error( 'This is a fatal error message' ); # Also exits the program
  msg( 'This is just an indented message' );

Outputs:

  ==> This is a status message
    -> This is a substatus message
  ==> WARNING: This is a warning message
  ==> ERROR: This is a fatal error message
      This is just an indented message

=for html
 <div style="width: 500px; background:black; font-family:monospace;
             color:white; white-space:pre; border: solid white 1px;
             margin: 15px; padding: 10px;"
 > EXAMPLE:
 <span style="color:green">==></span> This is a status message
 <span style="color:blue">  -></span> This is a substatus message
 <span style="color:yellow">==> WARNING:</span> This is a warning message
 <span style="color:red">==> ERROR:</span> This is a fatal error message
     This is just an indented message  
</div>

=head1 DESCRIPTION

Archlinux has a distinctive and simple style for displaying messages
on the terminal. This style is used in the init scripts and pacman
to give a cohesive look to Archlinux's terminal. This module makes
it easy to use that style in your perl scripts.

=head1 EXPORTED FUNCTIONS

No functions are exported by default. This is different from the
first incarnation of this module. In order to import all functions
from this module you can use the C<:all> export tag like so:

  use Archlinux::Term qw(:all);

Every function takes a list of multiple arguments which are C<join>ed
together, word-wrapped and printed to the screen.  If a message goes
past the screen limit it is wordwrapped and indented past the prefix.

=head2 msg( text1 [ , text2, ... ] )

Prints a simple message.  There is no coloring it is merely
wordwrapped and indented by four spaces.

=head2 status( text1 [ , text2, ... ] )

Prints a status message.  These are basically like major headings in a
document.  The message is prefixed with a green arrow:

=head2 substatus( text1 [ , text2, ... ] )

Prints a sub-status message.  These are like minor headings in a
document.  The message is prefixed with a little blue arrow.

=head2 warning( text1 [ , text2, ... ] )

Prints a warning message.  These are non-fatal warning messages; the
program will keep running.  Warnings are printed to STDERR by using
C<warn>.  The message is prefixed with a yellow arrow and capital
WARNING.

=head2 error( text1 [ , text2, ... ] )

Prints a fatal error message B<AND DIES, EXITING>.  There is no line
number appended to the C<die> message. C<$@> or C<$EVAL_ERROR> is the
colorized output.  Errors are printed to STDERR by using C<die>.  The
message is prefixed with a red arrow and capital ERROR.

The error can be caught with an enclosing C<eval> block.  If the error
isn't caught it is displayed on the screen and the program exits.

=head3 Example

  eval {
      if ( $stuff eq 'bad' ) {
          error( q{Stuff went bad!} );
      }
  };

  if ( $@ =~ /Stuff went bad!/ ) {
      warning( q{Stuff went bad, but it's okay now!} );
  }

=head1 TWEAKING

You can change the default settings of I<Archlinux::Term> by changing
some package variables:

=head2 Word-wrap columns

C<$Archlinux::Term::Columns> Determines at which column
word-wrapping occurs.  However, if it is set to a false or negative
value, it will turn off word-wrapping all-together.

=head2 Monochrome

If C<$Archlinux::Term::Mono> is set to a true value then ANSI
terminal colors are disabled.

=head2 Example

  use Archlinux::Term;

  sub mysub
  {
      # It's usually a good idea to use local for this stuff...
      local $Archlinux::Term::Columns = 144;
      local $Archlinux::Term::Mono    = 1;

      status( 'Here is an uncolorful really long status message ... '  .
              'no it's not over with yet!  We wrap at 144 characters ' .
              'so I have to keep typing.' );
 
  }

=head1 SEE ALSO

=over

=item * Archlinux

L<http://www.archlinux.org>

=item * Git Repository

L<http://github.com/juster/perl-archlinux-term>

=back

=head1 AUTHOR

Justin Davis C<< <juster at cpan dot org> >>

=head1 LICENSE

Copyright 2011 Justin Davis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
