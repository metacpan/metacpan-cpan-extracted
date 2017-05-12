# -*- Mode: perl -*-
#
# $Id: Layout.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Layout.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Layout;

use Carp::Datum;
require CGI;

#
# ->make
#
# Creation routine.
#
sub make {
    DFEATURE my $f_;
    my $self = bless {}, shift;
    return DVAL $self;
}

#
# ->start_HTML
#
# Emit the HTML headers.
#
# NB: Can't call it "start_html", because if one uses CGI within heirs, that
# routine would no longer be visible (CGI exports a start_html routine).
#
sub start_HTML {
    DFEATURE my $f_;
    my $self = shift;

	print CGI::header(-nph => 0);
	print CGI::start_html(@_);

	return DVOID;
}

#
# ->end_HTML
#
# Emit the HTML trailers.
#
# NB: Can't call it "end_html", because if one uses CGI within heirs, that
# routine would no longer be visible (CGI exports an end_html routine).
#
sub end_HTML {
    DFEATURE my $f_;
    my $self = shift;

	print CGI::end_html;

	return DVOID;
}

#
# ->init
#
# Initialize yourself.
# Routine called before start_HTML() with the screen to display.
# In case of internal errors, screen may be undef.
#
# When bouncing from screen to screen, this routine may be called more than
# once, for each screen we bounce to.  In particular, the $screen variable
# may or may not be different each time.
#
sub init {
    DFEATURE my $f_;
    my $self = shift;
	my ($screen) = @_;
	### to be redefined, optionally
	return DVOID;
}

#
# ->preamble
#
# Emit layout preamble, before screen generates any output.
#
sub preamble {
    DFEATURE my $f_;
	### to be redefined, optionally
	return DVOID;
}

#
# ->postamble
#
# Emit layout postamble, after screen has generated its output.
#
sub postamble {
    DFEATURE my $f_;
	### to be redefined, optionally
	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Layout - ancestor for layout objects

=head1 SYNOPSIS

 use base qw(CGI::MxScreen::Layout);

 sub init {                  # redefine initialization
     my $self = shift;
     my ($screen) = @_;
     ...
 }

 sub preamble {              # redefine pre-amble
     my $self = shift;
     ...
 }

 sub postamble {             # redefine post-amble
     my $self = shift;
     ...
 }

=head1 DESCRIPTION

This class is meant to be the ancestor of all the layout objects
that can be given to the C<CGI::MxScreen> manager via the C<-layout>
argument.

In order to define your own layout, you must create a class inheriting
from C<CGI::MxScreen::Layout> and redefine the C<init()>, C<preamble()>
and C<postamble()> features, which do nothing by default.

Because this kind in inheritance is a I<specialization> of some behaviour,
you need to understand the various operations that get carried on, so
that you may plug your layout properly.

It works as follows:

=over 4

=item *

The C<init()> routine is called for each screen we are about to display.
It is given one argument, the screen object.  That object may be C<undef>
if we're displaying an internal error.  See L<CGI::MxScreen::Screen/INTERFACE>
to know what can be done with a screen object.

The C<display()> routine of a screen may request bouncing to some other
state, in which case C<init()> will be called again with another screen
object.  Therefore, you must not assume that C<init()> will be called
only once.

=item *

The C<start_HTML()> routine is called with the following arguments:

    -title      => $screen->screen_title,
    -bgcolor    => $screen->bgcolor,

when there is a screen object, or with simply a title for internal errors.
The default C<start_HTML()> routine does this:

    print CGI::header(-nph => 0);
    print CGI::start_html(@_);

but you may choose to optionally redefine it.

=item *

Immediately after, C<preamble()> is called.  It does nothing by default,
but this is a feature you're likely to redefine.

Since it is an object feature, it has access to everything you decided to
initialize in C<init()>, based on the screen or other internal variables.

If your C<preamble()> routine opens an HTML container tag, you must make
sure it is able to contain everything that can be generated during
C<display()>.

=item *

Unless we're generating an internal error, the CGI form is started.
Then C<$screen-E<gt>display(...)> is called.  This is where the regular
output is generated.

=item *

Upon return from C<display()>, the CGI form is closed, then C<postamble()
is called.

This is the opportunity to close any tag opened in C<preamble()>, or to
emit a common trailer to all your script outputs.

=item *

Finally, the C<end_HTML()> routine is called.  It does

    print CGI::end_html;

in case you would like to redefine that.  Don't make the mistake to
redefine C<end_HTML()> simply to add a postamble before closing the HTML tags.
You must use C<postamble()> for that.

You could conceivably need to redefine C<end_HTML()> when you redefined
C<start_HTML()>, but then again, it's a possibility, not a certitude.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3), CGI::MxScreen::Screen(3).

=cut

