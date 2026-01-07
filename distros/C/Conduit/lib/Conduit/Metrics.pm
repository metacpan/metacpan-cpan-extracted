#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.36;
package Conduit::Metrics 0.02;

use experimental 'builtin';
use builtin qw( refaddr );

=head1 NAME

C<Conduit::Metrics> - collect metrics on C<Conduit> using L<Metrics::Any>

=head1 DESCRIPTION

This module contains the implementation of metrics-reporting code from
C<Conduit> to provide information about its operation into L<Metrics::Any>.

=cut

use Metrics::Any 0.05 '$metrics',
   strict      => 1,
   name_prefix => [qw( http server )];

use Time::HiRes qw( gettimeofday tv_interval );

$metrics->make_gauge( requests_in_flight =>
   description => "Count of the number of requests received that have not yet been completed",
   # no labels
);
$metrics->make_counter( requests  =>
   description => "Number of HTTP requests received",
   labels      => [qw( method )],
);
$metrics->make_counter( responses =>
   description => "Number of HTTP responses served",
   labels      => [qw( method code )],
);
$metrics->make_timer( request_duration =>
   description => "Duration of time spent processing requests",
   # no labels
);
$metrics->make_distribution( response_bytes =>
   description => "The size in bytes of responses sent",
   units       => "bytes",
   # no labels
);

my %request_started_time;

sub received_request ( $, $request )
{
   if( $metrics ) {
      $request_started_time{refaddr $request} = [ gettimeofday ];

      $metrics->inc_gauge( requests_in_flight => );

      $metrics->inc_counter( requests => { method => $request->method } );
   }
}

sub sent_response ( $, $response, $bytes_written )
{
   if( $metrics ) {
      $metrics->dec_gauge( requests_in_flight => );

      my $request = $response->request;
      my $started_time = delete $request_started_time{refaddr $request};

      $metrics->inc_counter( responses => { method => $request->method, code => $response->code } );
      $metrics->report_timer( request_duration => tv_interval $started_time );
      $metrics->report_distribution( response_bytes => $bytes_written );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
