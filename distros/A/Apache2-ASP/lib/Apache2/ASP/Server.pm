
package Apache2::ASP::Server;

use strict;
use warnings 'all';
use Mail::Sendmail;
use encoding 'utf8';


#==============================================================================
sub new
{
  my ($class, %args) = @_;

  my $s = bless {LastError => undef}, $class;
  
  return $s;
}# end new()


#==============================================================================
sub GetLastError
{
  $_[0]->{LastError};
}# end GetLastError()


#==============================================================================
sub context
{
  $Apache2::ASP::HTTPContext::ClassName->current;
}# end context()


#==============================================================================
# Shamelessly ripped off from Apache::ASP::Server, by Joshua Chamas,
# who shamelessly ripped it off from CGI.pm, by Lincoln D. Stein.
# :)
sub URLEncode
{
  my $toencode = $_[1];
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end URLEncode()


#==============================================================================
sub URLDecode
{
  my ($s, $todecode) = @_;
  return unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
  $todecode =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
  defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;
  return $todecode;
}# end URLDecode()


#==============================================================================
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


#==============================================================================
sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  return $str;
}# end HTMLEncode()


#==============================================================================
sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  $s->context->config->web->www_root . $path;
}# end MapPath()


#==============================================================================
sub Mail
{
  my ($s, %args) = @_;
  
  # XXX: Base64-encode the content, and update the content-type to reflect that
  # if content-type === 'text/html'.
  # XXX: Consider updating this so that we can send attachments as well.
  Mail::Sendmail::sendmail( %args );
}# end Mail()


#==============================================================================
sub RegisterCleanup
{
  my ($s, $sub, @args) = @_;
  
  # This works both in "testing" mode and within a live mod_perl environment.
  $s->context->get_prop('r')->pool->cleanup_register( $sub, \@args );
}# end RegisterCleanup()


#==============================================================================
sub _utf8_chr
{
  my ($c) = @_;
  require utf8;
  my $u = chr($c);
  utf8::encode($u); # drop utf8 flag
  return $u;
}# end _utf8_chr()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef(%$s);
}# end DESTROY()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::Server - Utility methods for Apache2::ASP

=head1 SYNOPSIS

  my $full_path = $Server->MapPath('/index.asp');
  
  $Server->URLEncode( 'user@email.com' );

  $Server->URLDecode( 'user%40email.com' );
  
  $Server->HTMLEncode( '<br />' );
  
  $Server->HTMLDecode( '&lt;br /&gt;' );
  
  $Server->Mail(
    To      => 'user@email.com',
    From    => '"Friendly Name" <friendly.name@email.com>',
    Subject => 'Hello World',
    Message => "E Pluribus Unum.\n"x777
  );
  
  $Server->RegisterCleanup( sub {
      my @args = @_;
      ...
    }, @args
  );

=head1 DESCRIPTION

The ASP Server object is historically a wrapper for a few utility functions that
don't belong anywhere else.

Keeping with that tradition, the Apache2::ASP Server object is a collection of
functions that don't belong anywhere else.

=head1 PUBLIC METHODS

=head2 URLEncode( $str )

Converts a string into its url-encoded equivalent.  This approximates to
JavaScript's C<escape()> function or L<CGI>'s C<escape()> function.

Example:

  <%= $Server->URLEncode( 'user@email.com' ) %>

Returns

  user%40email.com

=head2 URLDecode( $str )

Converts a url-encoded string into its non-url-encoded equivalent.  This works 
the same way as JavaScript's and L<CGI>'s C<unescape()> function.

Example:

  <%= $Server->URLDecode( 'user%40email.com' ) %>

Returns

  user@email.com

=head2 HTMLEncode( $str )

Safely converts <, > and & into C<&lt;>, C<&gt;> and C<&amp;>, respectively.

=head2 HTMLDecode( $str )

Converts C<&lt;>, C<&gt;> and C<&amp;> into <, > and &, respectively.

=head2 MapPath( $relative_path )

Given a relative path, C<MapPath> will return the absolute path for it, under the
document root of the current website.

For example, C</index.asp> might return C</usr/local/famicom/htdocs/index.asp>

=head2 Mail( %args )

Sends an email message.  The following arguments are required:

=over 4

=item To

The email address the message should be sent to.

=item From

The email address the message should be sent from.

=item Subject

The subject of the email.

=item Message

The content of the body.

=back

Other arguments are passed through to L<Mail::Sendmail>.

=head2 RegisterCleanup( \&code[, @args ] )

A wrapper around L<APR::Pool>'s C<cleanup_register> function.  Pass in a coderef
and (optionally) arguments to be passed to that coderef, and it is executed during
the cleanup phase of the current request.

If we were doing vanilla mod_perl, you could achieve the same effect with this:

  $r->pool->cleanup_register( sub { ... }, \@args );

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

