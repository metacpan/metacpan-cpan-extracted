
package ASP4::Error;

use strict;
use warnings 'all';
use ASP4::HTTPContext;
use JSON::XS;


sub new
{
  my $class = shift;
  my ($err_str, %args);
  if( @_ )
  {
    if( @_ == 1 )
    {
      $err_str = shift;
    }
    else
    {
      %args = @_;
    }# end if()
  }
  elsif( $@ )
  {
    $err_str = $@;
  }# end if()
  
  my $context   = ASP4::HTTPContext->current;
  my $Config    = $context->config;
  my $Response  = $context->response;
  my $Session   = $context->session;
  my $Form      = $context->request->Form;
  
  my %session_data = %$Session;
  
  my $error;
  if( $err_str )
  {
    my ($main, $message, $file, $line) = $err_str =~ m/^((.*?)\s(?:at|in)\s(.*?)\sline\s(\d+))/;
    $error = {
      message     => $err_str,
      file        => $file,
      line        => $line,
      stacktrace  => $err_str,
    };
    
    if( $error->{file} =~ m{_asp\.pm$} )
    {
      $error->{file} = -f $ENV{SCRIPT_FILENAME} ? $ENV{SCRIPT_FILENAME} : $error->{file};
    }# end if()
  }
  else
  {
    $error = \%args;
  }# end if()
    
  # Get the line of code that's breaking:
  # And maybe a few before and after:
  my $code;
  if( -f $error->{file} )
  {
    if( open my $ifh, '<', $error->{file} )
    {
      my $max = 0;
      $max++ while <$ifh>;
      close($ifh);
      open $ifh, '<', $error->{file};
      
      my $padding = 10;
      my ($low, $high) = $class->_number_range($error->{line}, $max, $padding);

      my $line_number = 0;
      my @lines = ( );
      while( my $line = <$ifh> )
      {
        $line_number++;
        next unless $line_number >= $low;
        last if $line_number > $high;
        push @lines, "line $line_number: $line";
      }# end while()
      close($ifh);
      $code = join "", @lines;
    }# end if()
  }# end if()
  
  my %info = (
    # Defaults:
    domain        => eval { $Config->errors->domain } || $ENV{HTTP_HOST},
    request_uri   => $ENV{REQUEST_URI},
    file          => $error->{file},
    line          => $error->{line},
    message       => $error->{message},
    stacktrace    => $error->{stacktrace},
    code          => $code,
    form_data     => encode_json($Form) || "{}",
    session_data  => eval { encode_json(\%session_data) } || "{}",
    http_referer  => $ENV{HTTP_REFERER},
    user_agent    => $ENV{HTTP_USER_AGENT},
    http_code     => ($Response->Status =~ m{^(\d+)})[0],
    remote_addr   => $ENV{REMOTE_ADDR} || '127.0.0.1',
    # Allow overrides:
    %args
  );
  
  return bless \%info, $class;
}# end new()


sub domain        { $_[0]->{domain} }
sub request_uri   { $_[0]->{request_uri} }
sub file          { $_[0]->{file} }
sub line          { $_[0]->{line} }
sub message       { $_[0]->{message} }
sub stacktrace    { $_[0]->{stacktrace} }
sub code          { $_[0]->{code} }
sub form_data     { $_[0]->{form_data} }
sub session_data  { $_[0]->{session_data} }
sub http_referer  { $_[0]->{http_referer} }
sub user_agent    { $_[0]->{user_agent} }
sub http_code     { $_[0]->{http_code} }
sub remote_addr   { $_[0]->{remote_addr} }


# Find the numbers within a given range, but not less than 1 and not greater than max.
sub _number_range
{
  my ($s, $number, $max, $padding) = @_;
  
  my $low = $number - $padding > 0 ? $number - $padding : 1;
  my $high = $number + $padding <= $max ? $number + $padding : $max;
  return ($low, $high);
}# end _number_range()

1;# return true:

=pod

=head1 NAME

ASP4::Error - Representation of a server-side error

=head1 SYNOPSIS

  use ASP4::Error;
  
  # Pass in the $@ value after something dies or confesses:
  eval { die "Foo" };
  if( $@ ) {
    my $error = ASP4::Error->new( $@ )
  }
  
  # Pass in your own info:
  unless( $something ) {
    my $error = ASP4::Error->new(
      message => "If can, can.  If no can, no can!"
    );
  }
  
=head1 DESCRIPTION

ASP4 provides a simple means of dealing with errors.  It emails them, by default,
to an email address you specify.

Sometimes that is not convenient.  Maybe you want to do something special with
the error - like log it someplace special.

ASP4::Error is a simple representation of a server-side error.

=head1 PUBLIC READ-ONLY PROPERTIES

=head2 domain

C<<$Config->errors->domain>> or C<$ENV{HTTP_HOST}>

=head2 request_uri

C<$ENV{REQUEST_URI}>

=head2 file

The name of the file in which the error occurred.  This is gleaned from C<$@> unless C<file> is
passed to the constructor.

=head2 line

The line number within the file that the error occurred.  This is gleaned from C<$@> unless
C<line> is passed to the constructor.

=head2 code

A string.  Includes the 5 lines of code before and after the line of code where the error occurred.

=head2 message

Defaults to the first part of C<$@> unless otherwise specified.

=head2 stacktrace

A string - defaults to the value of C<$@>.

=head2 form_data

JSON-encoded C<$Form> object.

=head2 session_data

JSON-encoded C<$Session> object.

=head2 http_referer

Default value is C<$ENV{HTTP_REFERER}>

=head2 user_agent

Default value is C<$ENV{HTTP_USER_AGENT}>

=head2 http_code

The current value of C<<$Response->Status>>

=head2 remote_addr

Default value is C<$ENV{REMOTE_ADDR}> -- the IP address of the remote client.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

