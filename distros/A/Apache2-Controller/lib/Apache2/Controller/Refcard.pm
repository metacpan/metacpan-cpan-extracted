=head1 NAME

Apache2::Controller::Refcard - reference card for Apache2::Controller

=head1 SYNOPSYS

=over 2

=item HTTP return code reference

=back

=head1 DESCRIPTION

Apache2::Controller::Refcard contains only documentation
for L<Apache2::Controller>.

=head1 SECTIONS

=head2 status

If you're like me, you get confused as to which status codes are http
status codes and which ones are used internally by Apache2 to signal the
&handler subroutine exit status and return or deny further control to 
the server.

$r->status is set with the right value, usually HTTP_OK or 
HTTP_(which might be overridden by an error in case an
exception is thrown somewhere with ), and then handler() returns 
Apache2::Const::OK in any case.  So far.  This might change if
someone gets me wise to what's actually going on.

  RC                Apache2::Const::*  HTTP::Status::status_message($RC)
 -----------------------------------------------------------------------
 -02                               DONE                             -
 -01                           DECLINED                             -
 000                                 OK                             -
 100                      HTTP_CONTINUE                      Continue
 101           HTTP_SWITCHING_PROTOCOLS           Switching Protocols
 102                    HTTP_PROCESSING                    Processing
 200                            HTTP_OK                            OK
 201                       HTTP_CREATED                       Created
 202                      HTTP_ACCEPTED                      Accepted
 203             HTTP_NON_AUTHORITATIVE Non-Authoritative Information
 204                    HTTP_NO_CONTENT                    No Content
 205                 HTTP_RESET_CONTENT                 Reset Content
 206               HTTP_PARTIAL_CONTENT               Partial Content
 207                  HTTP_MULTI_STATUS                  Multi-Status
 300              HTTP_MULTIPLE_CHOICES              Multiple Choices
 301             HTTP_MOVED_PERMANENTLY             Moved Permanently
 302             HTTP_MOVED_TEMPORARILY                         Found
 302                           REDIRECT                         Found
 303                     HTTP_SEE_OTHER                     See Other
 304                  HTTP_NOT_MODIFIED                  Not Modified
 305                     HTTP_USE_PROXY                     Use Proxy
 307            HTTP_TEMPORARY_REDIRECT            Temporary Redirect
 400                   HTTP_BAD_REQUEST                   Bad Request
 401                      AUTH_REQUIRED                  Unauthorized
 401                  HTTP_UNAUTHORIZED                  Unauthorized
 402              HTTP_PAYMENT_REQUIRED              Payment Required
 403                          FORBIDDEN                     Forbidden
 403                     HTTP_FORBIDDEN                     Forbidden
 404                     HTTP_NOT_FOUND                     Not Found
 404                          NOT_FOUND                     Not Found
 405            HTTP_METHOD_NOT_ALLOWED            Method Not Allowed
 406                HTTP_NOT_ACCEPTABLE                Not Acceptable
 407 HTTP_PROXY_AUTHENTICATION_REQUIRED Proxy Authentication Required
 408              HTTP_REQUEST_TIME_OUT               Request Timeout
 409                      HTTP_CONFLICT                      Conflict
 410                          HTTP_GONE                          Gone
 411               HTTP_LENGTH_REQUIRED               Length Required
 412           HTTP_PRECONDITION_FAILED           Precondition Failed
 413      HTTP_REQUEST_ENTITY_TOO_LARGE      Request Entity Too Large
 414         HTTP_REQUEST_URI_TOO_LARGE         Request-URI Too Large
 415        HTTP_UNSUPPORTED_MEDIA_TYPE        Unsupported Media Type
 416         HTTP_RANGE_NOT_SATISFIABLE Request Range Not Satisfiable
 417            HTTP_EXPECTATION_FAILED            Expectation Failed
 500         HTTP_INTERNAL_SERVER_ERROR         Internal Server Error
 500                       SERVER_ERROR         Internal Server Error
 501               HTTP_NOT_IMPLEMENTED               Not Implemented
 502                   HTTP_BAD_GATEWAY                   Bad Gateway
 503           HTTP_SERVICE_UNAVAILABLE           Service Unavailable
 504              HTTP_GATEWAY_TIME_OUT               Gateway Timeout
 506           HTTP_VARIANT_ALSO_VARIES       Variant Also Negotiates
 507          HTTP_INSUFFICIENT_STORAGE          Insufficient Storage
 510                  HTTP_NOT_EXTENDED                  Not Extended


For reference, a utility script has been included in the build directory,
utils/apache2_http_response_reference_list.pl.  This dumps the :common
and :http constants from Apache2::Const and lists their names alongside the
corresponding status_message() strings from HTTP::Status.  This is the
resulting list of codes and corresponding HTTP::Status messages.

 use strict;
 use warnings;
 
 use HTTP::Status;
 use Apache2::Const qw( 
     :common :http 
 );
 
 my @tags;
 
 my %syms = %Apache2::Const:: ;
 CONST_SYM:
 for my $sym ( sort keys %syms ) {
     my $code = *{$syms{$sym}}{CODE};
     push @tags, $sym if defined $code && uc $sym eq $sym;
 }
 
 my %numbers;
 
 for my $tag (@tags) {
     my $number;
     eval '$number = Apache2::Const::'.$tag.';';
     $numbers{$tag} = $number;
 }
 
 print sprintf(
     "%3s %35s %33s", 'RC', 'Apache2::Const::*', 'HTTP::Status::status_message'
 ), "\n", '-' x 77, "\n";
 
 for my $tag (sort { $numbers{$a} <=> $numbers{$b} } @tags) {
     my $number = $numbers{$tag};
     my $lookup = status_message($number) || '-';
     print sprintf("%03d %35s %35s", $number, $tag, $lookup), "\n";
 }

=head1 SEE ALSO

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut

1;
