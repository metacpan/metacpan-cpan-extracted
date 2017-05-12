package Apache2::Autocomplete;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Log;

use base qw(JavaScript::Autocomplete::Backend);

our $VERSION = 0.12;

sub new {
  my ($class, $r) = @_;
  die qq{Please supply an Apache request object \$r}
    unless (defined $r and ref($r) eq 'Apache2::RequestRec');
  return $class if (ref($class) eq __PACKAGE__);
  my $cgi;
  eval {require CGI::Apache2::Wrapper;};
  if (not $@) {
    $cgi = CGI::Apache2::Wrapper->new($r);
  }
  else {
    eval {require CGI;};
    if (not $@) {
      if ($CGI::VERSION < 2.93) {
	$r->log_error("A minimal CGI.pm version of 2.93 is required");
	return;
      }
      $cgi = CGI->new($r);
    }
    else {
      $r->log_error("A suitable CGI object isn't available");
      return;
    }
  }
  my $self = {cgi => $cgi, r => $r};
  bless $self, $class;
}

sub r { return shift->{r};}

sub run {
  my ($self, $header_extra) = @_;
  my $r = $self->r;
  if (defined $header_extra) {
    unless (ref($header_extra) eq 'HASH') {
      $r->log_error("Extra headers must be a hash ref");
      return;
    }
  }
  $self->header($header_extra);
  unless ($self->param('js')) {
    $r->print($self->no_js);
    return;
  }
  my ($query, $names, $values, $prefix) = $self->expand($self->query);
  $r->print($self->output($query, $names, $values, $prefix));
}

sub header { shift->cgi->header( @_ ) }

sub no_js {
  my $no_js = <<HTML;
<html>
<head>
<script>
function bodyLoad() {
  if (parent == window) return;
  var frameElement = this.frameElement;
  parent.sendRPCDone(frameElement, "", new Array(), new Array(), new Array(""));
}
</script></head><body onload='bodyLoad();'></body></html>
HTML
  return $no_js;
}

1;

__END__

=head1 NAME

Apache2::Autocomplete - Autocomplete service backend via mod_perl

=head1 SYNOPSIS

Given some form that using Google's autocomplete that receives
suggestions from I<http://localhost/complete/search>:

  ######################################################
  # in httpd.conf
  PerlModule Apache2::MyAutoComplete
  <Location /complete/search>
     SetHandler perl-script
     PerlResponseHandler Apache2::MyAutoComplete
  </Location>
  ######################################################
  
  ###################################################### 
  # module file Apache2/MyAutoComplete.pm
  package Apache2::MyAutoComplete;
  use base qw(Apache2::Autocomplete);
  # use whatever else
  
  my @NAMES = qw(bob carol ted alice);
  sub expand {
    my ($self, $query) = @_;
    my $re = qr/^\Q$query\E/i;
    my @names = grep /$re/, @NAMES;
    my @values = map {"some description"} @names;
    (lc $query, \@names, \@values, [""]);
  }
  
  sub handler {
    my $r = shift;
    my $ac = __PACKAGE__->new($r);
    $ac->run();
    return Apache2::Const::OK;
  }
  ######################################################

=head1 DESCRIPTION

This module is a mod_perl2 interface to
L<JavaScript::Autocomplete::Backend>, which is a base
class for implementing an autocomplete service
for a form using the Google Suggest protocol.
See L<http://www.google.com/webhp?complete=1&hl=en>
for an illustration of Google Suggest in operation,
as well as
L<http://serversideguy.blogspot.com/2004/12/google-suggest-dissected.html>
for a description of how the JavaScript code works.

As well as L<mod_perl2>, this package requires
L<JavaScript::Autocomplete::Backend>, as well as a CGI.pm-compatible
CGI module for supplying the I<param()> and I<header()> methods.
If available, L<CGI::Apache2::Wrapper> will be used,
which is a minimal module that uses methods of L<mod_perl2>
and L<Apache2::Request> to provide these methods; if this
is not available, L<CGI> (version 2.93 or greater) will be used.

Operation of this service requires inclusion of the
Autocomplete JavaScript code; a copy of this is included
in this distribution, the latest version of which is available at
L<http://www.google.com/ac.js>.

=head1 Example Form

An example form for which autocompletion is desired has the
the following structure:

 <html><head>
 <title>Search</title>
 </head>
 <body onload="document.f.query.focus();">
 <form action="/search_handler" name=f>
 <br>
 <input autocomplete="off" maxlength=2048 
   name="query" size="25" title="Search" value="">&nbsp;
 <input name="btnG" type="submit" value="Search">
 </form>
 </body>
 <SCRIPT src="/js/ac.js"></SCRIPT>
 <SCRIPT>
 InstallAC(document.f,document.f.query,document.f.btnG,"search","en");
 </SCRIPT></html>

The Autocomplete JavaScript code is made available as I</js/ac.js>.

The basic operation of the autocompletion is controlled
by the JavaScript function I<InstallAC> (available in I<ac.js>).
This is called with 5 arguments:

=over

=item * document.f

This specifies the name of the form

=item * document.f.query

This specifies the name of the form element where the autocompletion occurs

=item * document.f.btnG

This specified the name of the submit button of the form

=item * search

This specifies that I<http://localhost/complete/search> will be used to
get results for the autocompletion; if a value of, for example,
I<my_handler> was used instead of I<search>, then
I<http://localhost/complete/my_handler> will be used.

=item * en

When the user types something into the form (after a specified
timeout), a call to the specified handler is made in order to get
the results to be displayed for the autocompletion. This will be
of the form
I<http://localhost/complete/search?hl=en&client=suggest&js=true&qu=a>,
where I<qu> is the query typed so far and I<en> is the value specified
for the variable I<hl> by this argument. If you need a value from
the form to be sent to the autocompletion handler, you can do so
in the following way: suppose we wanted to send the value of a
form element with name I<extra>:

 <input name="extra" type="hidden" value="secret">

If we specify the last argument to I<InstallAC> as
I<document.f.extra.value> (with no quotes), rather than I<"en">, then the
autocompletion handler will be called as
I<http://localhost/complete/search?hl=secret&client=suggest&js=true&qu=a>,
so that the value of I<hl> will be the value of the I<extra> element
of the originating form.

=back

=head1 Apache Handler

The autocompletion handler is specified through an
Apache configuration directive such as

  PerlModule Apache2::MyAutoComplete
  <Location /complete/search>
     SetHandler perl-script
     PerlResponseHandler Apache2::MyAutoComplete
  </Location>

Here, I<search> is the value specified by the fourth argument
to I<InstallAC>, as discussed above - the I<complete> part
of the location is hard-coded in I<ac.js>. The Perl module
which handles requests for this location has the form

  # module file Apache2/MyAutoComplete.pm
  package Apache2::MyAutoComplete;
  use base qw(Apache2::Autocomplete);
  # use whatever else
  
  sub expand {
    my ($self, $query) = @_;
    # decide what completions to return, based on the $query
    (lc $query, $names, $values, [""]);
  }
  
  sub handler {
    my $r = shift;
    my $ac = __PACKAGE__->new($r);
    $ac->run();
    return Apache2::Const::OK;
  }

This must inherit from I<Apache2::Autocomplete>. Within this
handler must be an I<expand> method:

  sub expand {
    my ($self, $query) = @_;
    # decide what completions to return, based on the $query
    (lc $query, $names, $values, [""]);
  }

which is to return a list of 4 elements
to be used for autocompletion of the I$query> argument
passed in from the form. This list has the
following elements:

=over

=item * $query

This is the query as returned to the frontend script
(typically converted to lowercase)

=item * $names

This is an array reference of results to be used as the list of
suggested completions.

=item * $values

This is an array reference of values that are usually shown on
the right-hand side of the drop-down box in the front end;
Google uses it for the estimated result count.

=item * $prefix

As discussed in L<JavaScript::Autocomplete::Backend>,
the purpose of I<$prefix> is not certain at this time. It
appears that if the array is empty, the drop-down menu appears
but the word in the input box itself is not completed,
while if the array is not empty (for example,
contains an empty string as its only element), the word
in the input box is completed as well.

=back

The Apache handler itself:

  sub handler {
    my $r = shift;
    my $ac = __PACKAGE__->new($r);
    $ac->run();
    return Apache2::Const::OK;
  }

creates the object and calls the I<run> method on it, which
returns the autocomplete results in the form of JavaScript code that
the original form then uses to fill in the suggestions.

=head1 Methods

The following methods are available.

=over

=item * my $ac = __PACKAGE__-E<gt>new($r);

This creates the object, and takes a mandatory
argument of the L<Apache2::RequestRec> object I<$r>.

=item * $ac-E<gt>run();

This is the main method which calls the I<expand> method
to find and format the results to be returned for the
autocompletion.

By default, the only header Apache::Autocomplete sets is
the I<Content-Type>, for which I<text/html> is used.
If additional headers are required, they may
be passed as an optional argument into I<run()>in the
form of a hash reference, as in

  my $header = {'Content-Type' => 'text/html; charset=utf-8',
		'X-err_header_out' => 'err_headers_out',
	       };
  $ac->run($header);

=item * my $r = $ac-E<gt>r;

This returns the L<Apache2::RequestRec> object passed into
the I<new> method.

=item * my $cgi = $ac-E<gt>cgi;

This returns the CGI.pm-compatible object used to
supply the I<param()> and I<header()> methods needed
by L<JavaScript::Autocomplete::Backend>.

=back

=head1 SEE ALSO

For a description of the JavaScript backend, see
L<JavaScript::Autocomplete::Backend> and
L<http://serversideguy.blogspot.com/2004/12/google-suggest-dissected.html>.

If using L<CGI> is a concern due to the memory
footprint, see L<CGI::Apache2::Wrapper>
for a minimal CGI.pm-compatible module
that uses methods of L<mod_perl2>
and L<Apache2::Request>.

Development of this package takes place at
L<http://cpan-search.svn.sourceforge.net/viewvc/cpan-search/Apache2-Autocomplete/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::Autocomplete

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-Autocomplete>

=item * CPAN::Forum: Discussion forum

L<http:///www.cpanforum.com/dist/Apache2-Autocomplete>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-Autocomplete>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-Autocomplete>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-Autocomplete>

=item * UWinnipeg CPAN Search

L<http://cpan.uwinnipeg.ca/dist/Apache2-Autocomplete>

=back

=head1 COPYRIGHT

The Perl software is copyright 2007 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself;
see L<http://www.perl.com/pub/a/language/misc/Artistic.html>.
The JavaScript autocomplete code contained in I<ac.js>
of this distribution is Copyright 2004 and onwards by Google Inc.

=cut
