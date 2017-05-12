package Apache2::Ajax;
use strict;
use warnings;
use CGI::Ajax;
use Apache2::Const -compile => qw(OK SERVER_ERROR TAKE1
                                  TAKE2 RSRC_CONF ACCESS_CONF);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Log;
use Apache2::Module ();

our $VERSION = '0.11';

my @directives = (
                  {name      => 'PJX_fn',
                   errmsg    => 'perl ajax function maps',
                   args_how  => Apache2::Const::TAKE2,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'PJX_html',
                   errmsg    => 'perl ajax html',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'PJX_JSDEBUG',
                   errmsg    => 'perl ajax JSDEBUG',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'PJX_DEBUG',
                   errmsg    => 'perl ajax DEBUG',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
		 );

Apache2::Module::add(__PACKAGE__, \@directives);

my $cfg;

sub new {
  my ($class, $r, %args) = @_;
  my $caller = caller;
  return $class if (ref($class) eq __PACKAGE__);
  unless (defined $r and ref($r) eq 'Apache2::RequestRec') {
    $r->log_error("Must supply an Apache2::RequestRec object \$r");
    return;
  }
  $cfg = Apache2::Module::get_config(__PACKAGE__,
				     $r->server,
				     $r->per_dir_config) || { };
  my $fns = $cfg->{fns};
  my %pfns;
  my $fns_by_cfg = (defined $fns and ref($fns) eq 'HASH') ?
    scalar keys %{$fns} : 0;
  my $fns_by_arg = (%args) ? scalar keys %args : 0;
  unless (($fns_by_cfg + $fns_by_arg) > 0) {
    $r->log_error("Must specify at least one Perl function");
    return;
  }
  if ($fns_by_cfg ) {
    foreach (keys %{$fns}) {
      $pfns{$_} = \&{$caller . '::' . $fns->{$_}};
    }
  }
  if ($fns_by_arg) {
    foreach (keys %args) {
      $pfns{$_} = $args{$_};
    }
  }

  my $html;
  if (defined $cfg->{html}) {
    $html = \&{$caller . '::' . $cfg->{html}};
  }

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
  my $pjx = CGI::Ajax->new(%pfns);
  $pjx->cgi($cgi);
  my $url = $cgi->url;
  foreach (keys %pfns) {
    $pjx->url_list->{$_} = $url;
  }

  for my $val (qw(JSDEBUG DEBUG)) {
    next unless $cfg->{$val};
    $pjx->$val($cfg->{$val});
  }

  my $self = {cgi => $cgi, pjx => $pjx, html => $html, r => $r};
  bless $self, $class;
}

sub r {return shift->{r};}

sub cgi {return shift->{cgi};}

sub pjx {return shift->{pjx};}

sub html {return shift->{html};}

sub build_html {
  my ($self, %args) = @_;
  my $header_extra = $args{header};
  my $r = $self->r;
  if (defined $header_extra) {
    unless (ref($header_extra) eq 'HASH') {
      $r->log_error("Extra headers must be a hash ref");
      return;
    }
  }
  my $html_source = $args{html};
  if (defined $html_source) {
    $self->{html} = $html_source;
  }
  unless (defined $self->html) {
    $r->log_error("Must supply the html source");
    return;
  }
  return $self->pjx->build_html($self->cgi, $self->html, $header_extra);
}

sub show_javascript {
  my $self = shift;
  return $self->pjx->show_javascript();
}

sub PJX_fn {
  my ($self, $parms, $arg1, $arg2) = @_;
  $self->{fns}->{$arg1} = $arg2;
}

sub PJX_html {
   my ($self, $parms, $arg1) = @_;
   $self->{html} = $arg1;
}

sub PJX_JSDEBUG {
   my ($self, $parms, $arg1) = @_;
   $self->{JSDEBUG} = $arg1;
}

sub PJX_DEBUG {
   my ($self, $parms, $arg1) = @_;
   $self->{DEBUG} = $arg1;
}

1;

__END__

=head1 NAME

Apache2::Ajax - mod_perl interface to CGI::Ajax

=head1 SYNOPSIS

  ######################################################
  # in httpd.conf
  PerlLoadModule Apache2::MyAjaxApp
  <Location /ajax>
     SetHandler perl-script
     PerlResponseHandler Apache2::MyAjaxApp
     PJX_fn js_function_name perl_function_name
     PJX_html Show_Form_sub
     PJX_JSDEBUG 2
     PJX_DEBUG 1
  </Location>
  ######################################################
  
  ######################################################
  # module file Apache2/MyAjaxApp.pm
  package Apache2::MyAjaxApp
  use Apache2::Ajax;
  # use whatever else
  
  sub perl_function_name {
    my @params = @_;
    # do whatever
    return $return_value;
  }
  
  sub Show_Form_sub {
    my $html = '';
    # construct html string
    return $html;
  }
  
  sub handler {
    my $r = shift;
    # do stuff
    my $ajax = Apache2::Ajax->new($r);
    $r->print($ajax->build_html());
    return Apache2::Const::OK;
  }
  1;
  ##################################################

=head1 DESCRIPTION

This module is a mod_perl2 interface to L<CGI::Ajax>,
which provides a mechanism for using perl code
asynchronously from javascript-enhanced HTML pages.

As well as L<mod_perl2>,
this package requires L<CGI::Ajax>, as well as a CGI.pm-compatible
CGI module for supplying the I<param()> and I<header()> methods.
If available, L<CGI::Apache2::Wrapper> will be used,
which is a minimal module that uses methods of L<mod_perl2>
and L<Apache2::Request> to provide these methods; if this
is not available, L<CGI> (version 2.93 or greater) will be used.

Setting things up can be illustrated by the following
example of L<CGI::Ajax>, which contains a more thorough
discussion, as well as a number of illustrative example
scripts.

=over

=item * Define a Perl subroutine

At least one Perl subroutine must be defined which
takes input from some form element and returns a
result. For example,

   sub evenodd_func {
     my $input = shift;
     # check that $input is defined and is a number
     $input % 2 == 0 ? return("EVEN") : return("ODD");
   }

will accept an argument from a form element and
return a string indicating if that number is even or odd.

Note that, in this module, only Perl subroutines
are used, whereas in L<CGI::Ajax>, references to
subroutines may also be used.

=item * Generate the web page

A subroutine is provided which generates the html for the
web page. Within this is a trigger which calls the Perl subroutine,
as well as the particular HTML div element to which the results
are sent. For example,

  sub Show_HTML {
    my $html = <<EOT;
  <HTML>
  <HEAD><title>A Simple Example</title>
  </HEAD>
  <BODY>
    Enter a number:&nbsp;
    <input type="text" name="somename" id="val1" size="6"
       OnKeyUp="evenodd( ['val1'], ['resultdiv'] );">
    <br>
    <hr>
    <div id="resultdiv">
    </div>
  </BODY>
  </HTML>
  EOT

    return $html;
  }

By means of either an Apache configuration directive
or arguments passed into the constructor for the
object, to be described later, the Perl subroutine
I<evenodd_func> defined earlier will be associated
with a JavaScript function I<evenodd>. This function
is triggered using the I<OnKeyUp> event handler of the
input HTML element. The subroutine
takes one value from the form, the input element I<val1>,
and returns the the result to an HTML div element with an id
of I<resultdiv>.

=back

There may be circumstances under which it is desireable
to generate the html page directly within a handler, rather
than through a subroutine as described above. This is
possible, but one is then responsible for inserting
the JavaScript code directly into the page, which can be
done with the I<show_javascript()> method described later.
The following is a a handler which illustrates this technique:

  sub handler {
    my $r = shift;
    my $my_func = sub {
      my $arg = shift;
      return ( $arg . " with some extra" );
    };
    my $ajax = Apache2::Ajax->new($r, tester => $my_func);
    my $html = "";
    $html .= "<HTML>";
    $html .= "<HEAD>";
    
    $html .= $ajax->show_javascript;
    
    $html .= <<EOT;
    </HEAD>
    <BODY>
    <FORM name="form">
    <INPUT type="text" id="inarg"
        onkeyup="tester(['inarg'],['output_div']); return true;">
    <hr>
    <div id="output_div"></div>
    </FORM>
    <br/><div id='pjxdebugrequest'></div><br/>
    </BODY>
    </HTML>
    EOT
    
    my $cgi = $ajax->cgi;
    my $pjx = $ajax->pjx;
    $cgi->header();
    
    if ( not $cgi->param('fname') ) {
      $r->print($html);
    }
    else {
      $r->print($pjx->handle_request());
    }
    return Apache2::Const::OK;
  }

=head1 mod_perl handler

The mod_perl response handler used must use
I<Apache2::Ajax>, and has the following general form:

  package Apache2::MyAjaxApp
  use Apache2::Ajax;
  # use whatever else
  
  sub perl_function_name {
    my @params = @_;
    # do whatever
    return $return_value;
  }
  
  sub Show_Form_sub {
    my $html = '';
    # construct html string
    return $html;
  }
  
  sub handler {
    my $r = shift;
    # do stuff
    my $ajax = Apache2::Ajax->new($r, %new_args);
    $r->print($ajax->build_html(%build_args));
    return Apache2::Const::OK;
  }

Apache2::Ajax makes available the following.

=head2 Methods

=over

=item my $ajax = Apache2::Ajax->new($r, %new_args);

The I<new()> method creates an I<Apache2::Ajax> object,
and takes a mandatory argument of
the L<Apache2::RequestRec> object I<$r>.
It can also accept an optional set of arguments,
in the form of a hash, specifying
the mapping of Perl subroutines to the automatically-generated
JavaScript functions:

    my $ajax = Apache2::Ajax->new($r, 'JSFUNC' => \&PERLFUNC);

or, using a coderef:

    my $ajax = Apache2::Ajax->new($r, 'JSFUNC' => $perlfunc);

This mapping can alternatively be done through the Apache
configuration directive I<PJX_fn>, to be described below.

=item * my $html = $ajax-E<gt>build_html(%build_args);

This returns the HTML used for the web page, either the
complete html for the whole page or the updated html;
this corresponds to the I<build_html()> method of
L<CGI::Ajax>. This method also accepts optional
arguments, in the form of a hash, of two types:

=over

=item * header =E<gt> $header

By default, the only header Apache2::Ajax sets is
the I<Content-Type>, for which I<text/html> is used.
If additional headers are required, they may
be passed as an optional argument in the
form of a hash reference, as in

  my $header = {'Content-Type' => 'text/html; charset=utf-8',
		'X-err_header_out' => 'err_headers_out',
	       };
  my $ajax = Apache2::Ajax->new($r);
  my $html = $ajax->build_html(header => $header);

=item * html =E<gt> \&Show_form

This option specifies the subroutine
provided which generates the html for the web page:

  my $ajax = Apache2::Ajax->new($r);
  $r->print($ajax->build_html(html => \&Show_form));

A coderef or a string containing the raw html can also be used.
This subroutine can alternatively be specified through
the I<PJX_html> Apache configuration directive, to be
described below.

=back

=item * my $js =  $ajax-E<gt>show_javascript();

This returns the javascript needed to be
inserted into the calling scripts html I<E<lt>headE<gt>> section;
this corresponds to the I<show_javascript()> method of
L<CGI::Ajax>.

=item * my $pjx = $ajax-E<gt>pjx;

This returns the L<CGI::Ajax> object created with the I<new> method.

=item * my $r = $ajax-E<gt>r;

This returns the L<Apache2::RequestRec> object passed into
the I<new> method.

=item * my $cgi = $ajax-E<gt>cgi;

This returns the CGI.pm-compatible object used to
supply the I<param()>, I<header()>, I<remote addr()>,
and I<url()> methods needed by L<CGI::Ajax>.

=item * my $html_ref = $ajax-E<gt>html;

This returns a reference to the subroutine specified by the
I<PJX_html> Apache directive for constructing the html for the
page.

=back

=head2 Configuration Directives

Apache configuration directives can be used to control aspects
of the operation of Apache2::Ajax, 
typically done within a I<E<lt>Location E<gt>> directive:

  PerlLoadModule Apache2::MyAjaxApp
  <Location /ajax>
     SetHandler perl-script
     PerlResponseHandler Apache2::MyAjaxApp
     PJX_fn js_function_name perl_function_name
     PJX_html Show_Form_sub
     PJX_JSDEBUG 2
     PJX_DEBUG 1
  </Location>

Note the use of I<PerlLoadModule> to load the custom
Apache handler; this must be done so as the custom
I<Apache2::Ajax> directives are understood. These
directives are as follows.

=over

=item * PJX_fn js_function_name perl_function_name

This directive is used to associate the Perl function I<perl_function_name>
defined in the handler with a JavaScript function
I<js_function_name>. This can be used as an alternative to passing
in this mapping within the I<new> method.

=item * PJX_html Show_Form_sub

This directive is used to
define the Perl subroutine which returns the html
string used for the page. This can be used as an alternative to passing
in this mapping within the I<build_html> method.

=item * PJX_JSDEBUG 2

This directive, which is optional, is used to control
the level of JavaScript debugging used. Available
levels are

=over

=item * 0 : turn javascript debugging off

=item * 1 : turn javascript debugging on, some javascript compression

=item * 2 : turn javascript debugging on, no javascript compression

=back

=item * PJX_DEBUG 1

This directive, which is optional, is used to control the
level of debugging information which will appear in the
web server logs. Available levels are

=over

=item * 0 : turn debugging off (default)

=item * 1 : turn debugging on

=back

=back

=head1 SEE ALSO

See L<CGI::Ajax> for more details of how this
works, as well as a number of useful examples.

If using L<CGI> is a concern due to the memory
footprint, see L<CGI::Apache2::Wrapper>
for a minimal CGI.pm-compatible module
that uses methods of L<mod_perl2>
and L<Apache2::Request>.

Development of this package takes place at
L<http://cpan-search.svn.sourceforge.net/viewvc/cpan-search/Apache2-Ajax/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::Ajax

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-Ajax>

=item * CPAN::Forum: Discussion forum

L<http:///www.cpanforum.com/dist/Apache2-Ajax>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-Ajax>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-Ajax>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-Ajax>

=item * UWinnipeg CPAN Search

L<http://cpan.uwinnipeg.ca/dist/Apache2-Ajax>

=back

=head1 COPYRIGHT

This software is copyright 2007 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself;
see L<http://www.perl.com/pub/a/language/misc/Artistic.html>.

=cut
