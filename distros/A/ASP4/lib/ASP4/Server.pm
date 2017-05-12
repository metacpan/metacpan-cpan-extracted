
package ASP4::Server;

use strict;
use warnings 'all';
use ASP4::HTTPContext;
use ASP4::Error;
use Mail::Sendmail;

sub new
{
  return bless { }, shift;
}# end new()


sub context { ASP4::HTTPContext->current }


sub URLEncode
{
  ASP4::HTTPContext->current->cgi->escape( $_[1] );
}# end URLEncode()


sub URLDecode
{
  ASP4::HTTPContext->current->cgi->unescape( $_[1] );
}# end URLDecode()


sub HTMLEncode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/'/&#39;/g;
  return $str;
}# end HTMLEncode()


sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  $str =~ s/&#39;/'/g;
  return $str;
}# end HTMLDecode()


sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  ASP4::HTTPContext->current->config->web->www_root . $path;
}# end MapPath()


sub Mail
{
  my $s = shift;
  
  Mail::Sendmail::sendmail( @_ );
  die $Mail::Sendmail::error if $Mail::Sendmail::error;
  return $Mail::Sendmail::log;
}# end Mail()


sub RegisterCleanup
{
  my ($s, $sub, @args) = @_;
  
  $s->context->r->pool->cleanup_register( $sub, \@args );
}# end RegisterCleanup()


sub Error
{
  my $s = shift;
  
  my $error = ref($_[0]) && $_[0]->isa('ASP4::Error') ? $_[0] : ASP4::Error->new( @_ );

  $s->context->stash->{error} = $error;
  $s->context->config->load_class( $s->context->config->errors->error_handler );
  my $error_handler = $s->context->config->errors->error_handler->new();
  $error_handler->init_asp_objects( $s->context );
  $error_handler->run( $s->context );
  return $error;
}# end Error()


1;# return true:

=pod

=head1 NAME

ASP4::Server - Utility Methods

=head1 SYNOPSIS

  # Get the full disk path to /contact/form.asp:
  $Server->MapPath("/contact/form.asp");
  
  # Email someone:
  $Server->Mail(
    To      => 'jim@bob.com',
    From    => 'Joe Jangles <joe@jangles.net>',
    Subject => 'Test Email',
    Message => "Hello There!",
  );
  
  # Avoid XSS:
  <input type="text" name="foo" value="<%= $Server->HTMLEncode( $Form->{foo} ) %>" />
  
  # Proper URLs:
  <a href="foo.asp?bar=<%= $Server->URLEncode($Form->{bar}) %>">Click</a>

=head1 DESCRIPTION

The C<$Server> object provides some utility methods that don't really fit anywhere
else, but are still important.

=head1 PUBLIC METHODS

=head2 HTMLEncode( $str )

Performs a simple string substitution to sanitize C<$str> for inclusion on HTML pages.

Removes the threat of cross-site-scripting (XSS).

Eg:

  <tag/>

Becomes:

  &lt;tag/&gt;

=head2 HTMLDecode( $str )

Does exactly the reverse of HTMLEncode.

Eg:

  &lt;tag/&gt;

Becomes:

  <tag/>

=head2 URLEncode( $str )

Converts a string for use within a URL.

eg:

  test@test.com

becomes:

  test%40test.com

=head2 URLDecode( $str )

Converts a url-encoded string to a normal string.

eg:

  test%40test.com

becomes:

  test@test.com

=head2 MapPath( $file )

Converts a relative path to a full disk path.

eg:

  /contact/form.asp

becomes:

  /var/www/mysite.com/htdocs/contact/form.asp

=head2 Mail( %args )

Sends email - uses L<Mail::Sendmail>'s C<sendmail(...)> function.

=head2 RegisterCleanup( \&code, @args )

The supplied coderef will be executed with its arguments as the request enters
its Cleanup phase.

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler> for details.

=head2 Error( [%args] )

Calling C<<$Server->Error()>> without arguments will use the value of C<$@> and
generate a L<ASP4::Error> object from it, then pass it to the C<run(...)> method
of your C<<$Config->errors->error_handler>> for processing.

Please take a look at the documentation for L<ASP4::Error>, L<ASP4::ErrorHandler>
and L<ASP4::ErrorHandler::Remote> for details on how errors are handled.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

