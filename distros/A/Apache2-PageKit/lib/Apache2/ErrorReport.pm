package Apache2::ErrorReport;

# $Id: ErrorReport.pm,v 1.10 2004/01/12 12:51:04 borisz Exp $

use integer;
use strict;

use Mail::Mailer;
use HTML::Entities ();

use Carp;

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Response ();

# trap warn
$main::SIG{__WARN__} = \&Apache2::ErrorReport::warn;

sub error_message {
  my ($E, $type) = @_;

  return if defined($Apache2::ErrorReport::disable)
    && $Apache2::ErrorReport::disable eq 'yes';

  # PerlOptions +GlobalRequest
  my $r = Apache2::RequestUtil->request;

  my $s = Apache2::ServerUtil->server;

  return unless $r;

  my $stacktrace;
  if(ref($E) && $E->isa('Error')){
    # Special handing for derived Error.pm classes
    $stacktrace = $E->stacktrace;
  } else {
#    $stacktrace = "$E\n";
#    my $i = 0;
#    while (my ($package, $filename, $line, $subr) = caller($i)){
#      $stacktrace .= "stack $i: $package $subr line $line\n";
#      $i++;
#    }
    $stacktrace = Carp::longmess($E);
  }

  if($r->dir_config('ErrorReportHandler') eq 'email'){

    my $uri = (split(' ',$r->the_request))[1];

    # include request parameters in POST requests
    $uri .= '?' . $r->notes('query_string') if $uri !~ /\?/;

    my $userID = $r->user;

    my $headers_in = $r->headers_in;
    my $host = $headers_in->{'Host'};
    my $remote_host = $headers_in->{'X-Forwarded-For'} || $r->get_remote_host;
    my $referer = $headers_in->{'Referer'};

    my $current_callback = $r->current_callback;

    my $message = <<END;
$uri
userID: $userID  host: $host  remote_host: $remote_host  referer: $referer
handler: $current_callback

$stacktrace
END

    my $mailer = new Mail::Mailer;
    $mailer->open({To => $s->server_admin,
		   Subject => "Website $_[1]"
		  });
    print $mailer $message;
    $mailer->close;
  } elsif ($r->dir_config('ErrorReportHandler') eq 'display') {
    my $color = $_[1] eq 'WARN' ? 'blue' : 'red';

    HTML::Entities::encode_entities( $stacktrace, '<>&"' );

    my $bytes_sent = $r->bytes_sent;
    my $repeat = ( 512 < $bytes_sent ) ? 0 : 512 - $bytes_sent ;

    # send a large comment in front of the page so MSIE displays it too.
    my $html_msg =
        '<!-- ' . ( ' ' ) x $repeat . " -->\n"
	. qq{<pre><font color="$color">$_[1]: $stacktrace</font></pre><br>};

    if ( $bytes_sent ) {
      print $html_msg;
    }
    else {
      $r->custom_response( 500, $html_msg );
    }
  }
}

sub warn {
  &error_message($_[0],"WARN");
}

sub fatal {
  &error_message($_[0],"FATAL");
}

1;

__END__

=head1 NAME

Apache2::ErrorReport - Error Reporting under mod_perl

=head1 SYNOPSIS

In your Apache configuration file:

  PerlOptions +GlobalRequest
  PerlModule Apache2::ErrorReport
  PerlSetVar ErrorReportHandler email

In your perl code

  eval {
    &foo($bar);
  };
  if($@){
    Apache2::ErrorReport::fatal($@);
  }

=head1 DESCRIPTION

Reports warnings and fatal errors to screen or e-mail.
Includes detailed information
including error message, call stack, uri, host, remote host, remote user,
referrer, and Apache handler.

If C<ErrorReportHandler> is set to I<display>, errors will be
displayed on the screen for easy debugging.
This should be used in a development
environment only.

If C<ErrorReportHandler> is set to I<email>, errors will be e-mailed to the site
adminstrator as specified in the Apache C<ServerAdmin> configuration directive.
This should be used on a production site.

This modules uses $SIG{__WARN__} to display warning messages and
the C<fatal> method to display fatal messages.

=head1 AUTHOR

T.J. Mather (tjmather@anidea.com)

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005 AnIdea Corporation.  All rights Reserved.
PageKit is a trademark of AnIdea Corporation.

=head1 LICENSE

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Ricoh Source Code Public License for more details.

You can redistribute this module and/or modify it only under the terms of the Ricoh Source Code Public License.

You should have received a copy of the Ricoh Source Code Public License along with this program; if not, obtain one at http://www.pagekit.org/license

=cut
