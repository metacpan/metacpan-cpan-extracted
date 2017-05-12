package CGI::PrintWrapper;

# This is a lightweight wrapper for CGI so that you can call its
# methods, but have the results printed to the request object (passing
# through the Template object, of course).

use strict;

use Carp ( );
use CGI ( );
use CGI::Pretty;


$CGI::PrintWrapper::VERSION = (substr q$Revision: 1.8 $, 10) - 1;
my $rcs = '$Id: PrintWrapper.pm,v 1.8 1999/12/30 13:38:06 binkley Exp $';


sub new ($$;@) {
  my ($this, $h, @cgi_args) = @_;
  @cgi_args = ('') unless @cgi_args;

  $h or Carp::croak ('No print handle');
  $h->can ('print') or Carp::croak ("'$h' is not a print handle");

  my $class = ref ($this) || $this;
  # Need to create an empty CGI object to avoid CGI trying to read in
  # the parameters -- we are using CGI for printing forms, not for
  # processing scripts:
  my $cgi;
  eval { $cgi = CGI->new (@cgi_args); };
  $@ and Carp::croak ("Couldn't create CGI object because $@");

  bless [$h, $cgi], $class;
}

sub io ($;$) {
  if (scalar @_ == 1) {
    $_[0]->[0];
  } else {
    $_[0]->[0] = $_[1];
  }
}

# Modify CGI without printing:
sub cgi ($;$) {
  if (scalar @_ == 1) {
    $_[0]->[1];
  } else {
    $_[0]->[1] = $_[1];
  }
}

sub AUTOLOAD {
  no strict qw(refs);

  my $sub = $CGI::PrintWrapper::AUTOLOAD;
  $sub =~ s/.*:://; # strip package
  # We don't particularly want to print this:  :-)
  return if $sub eq 'DESTROY';

  # Fixup our call to invoke the same-named CGI function, but to print
  # the resulting string to our handle.  Update our symbol table so
  # that future calls can bypass AUTOLOAD entirely.  Be careful to
  # capture the handle ($$self) inside the sub--not outside--so that
  # calls from other instances don't reuse a previous handle (correct
  # scoping):
  *{$CGI::PrintWrapper::AUTOLOAD} = sub {
    my $self = shift;
    my $cgi_sub = "CGI::$sub";

    $self->[0]->print ($self->[1]->$cgi_sub (@_));

    return $self;
  };

  goto &$CGI::PrintWrapper::AUTOLOAD;
}

1;


__END__


=head1 NAME

CGI::PrintWrapper - CGI methods output to a print handle

=head1 SYNOPSIS

    use CGI::PrintHandle;
    use IO::Scalar; # just an example
    use HTML::Stream; # continuing the example

    # Fine, there really is no such tag as "WEAK":
    HTML::Stream->accept_tag ('WEAK');

    my $content = '';
    my $handle = IO::Scalar->new (\$content);
    my $cgi = CGI::PrintHandle ($handle);
    my $html = HTML::Stream->new ($handle);

    # Not a very exciting example:
    $cgi->start_form;
    $html->WEAK->t ('I am form: hear me submit.')->_WEAK;
    $cgi->submit;
    $cgi->end_form;

    print "$content\n";
<FORM METHOD="POST"  ENCTYPE="application/x-www-form-urlencoded">
<WEAK>I am form: hear me submit.</WEAK><INPUT TYPE="submit" NAME=".submit"></FORM>

=head1 DESCRIPTION

B<CGI::PrintWrapper> arranges for CGI methods to output their results
by printing onto an arbitrary handle.  This gets around the problem
that the B<CGI>'s subs return strings, which may be inconvient when
you wish to use B<CGI> for something besides CGI script processing.

You could just call C<print> yourself on the appropriate file handle,
but there are many contexts in which it is cleaner to provide the
extra abstraction (such as mixing B<CGI> with B<HTML::Stream>, the
problem which prompted my solution, illustrated above).

B<CGI::PrintWrapper> creates the necessary callbacks for printing
dynamically, updating the symbol table as it encounters a new B<CGI>
method.

=head1 CONSTRUCTOR

=over

=item C<new ($h)>

Creates a new B<CGI::PrintWrapper>, printing the results of B<CGI>
methods onto the print handle object, C<$h>.

=item C<new ($h, @cgi_args)>

Creates a new B<CGI::PrintWrapper>, printing the results of B<CGI>
methods onto the print handle object, C<$h>, and using the additional
arguments to construct the B<CGI> object.

=back

=head1 METHODS

=over

=item C<cgi ( )>

Returns the underlying CGI object.  This is handy for invoking methods
on the object whose result you do not wish to print, such as
C<param()>.

=item C<io ( )>

Returns the underlying print handle object.

=item C<AUTOLOAD>

Initially, B<CGI::PrintWrapper> has no methods (except as mentioned
above).  As the caller invokes B<CGI> methods, C<AUTOLOAD> creates
anonymous subroutines to perform the actual B<CGI> method call
indirection and print the results with the print handle object.  It
also updates the symbol table for B<CGI::PrintWrapper> so that future
calls can bypass C<AUTOLOAD>.  This makes a B<CGI::PrintWrapper>
object transparently a B<CGI> object, usable as a drop-in replacement.

=back

=head1 SEE ALSO

L<CGI>, L<IO::Scalar>, L<HTML::Stream>, L<perlfunc/print>

B<CGI> is the canonical package for working with fill-out forms on the
web.  It is particularly useful for generating HTML for such forms.

B<IO::Scalar> is a handy package for treating a string as an object
supporting IO handle semantics.

B<HTML::Stream> is a nice package for writing HTML markup and content
into an IO handle with stream semantics.  It's main drawback is lack
of support for HTML 4.0.

=head1 DIAGNOSTICS

The following are the diagnostics generated by B<Class::Class>.  Items
marked "(W)" are non-fatal (invoke C<Carp::carp>); those marked "(F)"
are fatal (invoke C<Carp::croak>).

=over

=item No print handle

(F) The caller tried to create a new C<CGI::PrintWrapper> without
supplying the mandatory first argument, a print handle:

    $cgi = CGI::PrintWrapper->new;

=item '%s' is not a print handle

(F) The caller tried to create a new C<CGI::PrintWrapper> using an
object which does not support C<print> as the mandatory first
argument.

=item Couldn't create CGI object because %s

(F) The caller tried to create a new C<CGI::PrintWrapper> using bad
addtional arguments to the constructor for B<CGI>.

=back

=head1 BUGS AND CAVEATS

There is no way of controlling now to C<use> B<CGI>, for example, if
you wished to precompile all the methods.  Instead, you should make
the appropriate call to C<use> yourself for B<CGI>, in addition to
that for B<CGI::PrintWrapper>, thus:

    use CGI qw(:compile);
    use CGI::PrintWrapper;

=head1 AUTHORS

B. K. Oxley (binkley) at Home E<lt>binkley@bigfoot.comE<gt>.  I am
grateful to my employer, DataCraft, Inc., for time spent preparing
this package for public consumption.

=head1 COPYRIGHT

  $Id: PrintWrapper.pm,v 1.8 1999/12/30 13:38:06 binkley Exp $

  Copyright 1999, B. K. Oxley (binkley).

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
