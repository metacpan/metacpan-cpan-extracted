
package ASP4::ErrorHandler::Remote;

use strict;
use warnings 'all';
use base 'ASP4::ErrorHandler';
use vars __PACKAGE__->VARS;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Date 'time2iso';
use JSON::XS;
use Data::Dumper;
require ASP4;

our $ua;

sub run
{
  my ($s, $context) = @_;
  
  my $error = $Stash->{error};
  
  $s->print_error( $error );
  $s->send_error($error);
}# end run()


sub send_error
{
  my ($s, $error) = @_;
  
  $ua ||= LWP::UserAgent->new();
  $ua->agent( ref($s) . " $ASP4::VERSION" );
  my %clone = %$error;
  my $req = POST $Config->errors->post_errors_to, \%clone;
  $ua->request( $req );
}# end send_error()

1;# return true:

=pod

=head1 NAME

ASP4::ErrorHandler::Remote - Send your errors someplace else via http.

=head1 SYNOPSIS

In your C<asp4-config.json>:

  ...
    "errors": {
      "error_handler":    "ASP4::ErrorHandler::Remote",
      "post_errors_to":   "http://errors.ohno.com/post/errors/here/"
    },
  ...

=head1 DESCRIPTION

This class provides a default error handler which does the following:

1) Makes a simple HTML page and prints it to the browser, telling the user
that an error has just occurred.

2) Sends an error notification to the web address specified in the config.

The data contained within the POST will match the public properties of L<ASP4::Error>, like this:

  $VAR1 = {
            'remote_addr' => '127.0.0.1',
            'request_uri' => '/',
            'user_agent' => 'test-useragent v2.0',
            'file' => '/home/john/Projects/myapp/www/htdocs/index.asp',
            'session_data' => '{}',
            'message' => 'A fake error has occurred',
            'http_code' => '500',
            'stacktrace' => 'A fake error has occurred at /tmp/PAGE_CACHE/TSR_WWW/__index_asp.pm line 2.
  ',
            'domain' => 'www.tsr.local',
            'form_data' => '{}',
            'http_referer' => '',
            'code' => 'line 1: <h1>Hello, world!</h1>
  line 2: <%
  line 3:   die "A fake error has occurred";
  line 4: %>
  ',
            'line' => '2'
  };


=head1 PUBLIC METHODS

=head2 send_error( $error )

Sends the error data to the web address specified in C<<$Config->errors->post_errors_to>>.

The field names and values will correspond to the properties of an C<ASP4::Error> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

