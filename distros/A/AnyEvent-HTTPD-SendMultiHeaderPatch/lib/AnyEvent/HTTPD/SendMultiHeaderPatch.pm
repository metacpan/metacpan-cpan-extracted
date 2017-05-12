package AnyEvent::HTTPD::SendMultiHeaderPatch;

use 5.006;
use strict;
use warnings FATAL => 'all';
no warnings 'redefine';

use AnyEvent::HTTPD::HTTPConnection;

=head1 NAME

AnyEvent::HTTPD::SendMultiHeaderPatch -
    Patch (hack) of AnyEvent::HTTPD for sending multiple headers with the same field name.

=head1 VERSION

Version 0.1.3

=cut

our $VERSION = '0.001003';

use AnyEvent::HTTPD;
use AnyEvent::HTTPD::Util;
use AnyEvent::HTTPD::HTTPConnection;

use Scalar::Util qw(weaken);

push @AnyEvent::HTTPD::Util::EXPORT, qw(header_add header_gets);

*AnyEvent::HTTPD::Util::header_add = sub {
    my ($hdrs, $name, $value) = @_;
    $name = AnyEvent::HTTPD::Util::_header_transform_case_insens ($hdrs, $name);
    if( exists $hdrs->{$name} ) {
        $hdrs->{$name} .= "\0".$value;
    }
    else {
       $hdrs->{$name} = $value;
    }
};

*AnyEvent::HTTPD::Util::header_gets = sub {
    my ($hdrs, $name) = @_;
    $name = AnyEvent::HTTPD::Util::_header_transform_case_insens ($hdrs, $name);
    exists $hdrs->{$name} ? [split /\0/, $hdrs->{$name}] : []
};

*AnyEvent::HTTPD::HTTPConnection::response = sub {
   my ($self, $code, $msg, $hdr, $content, $no_body) = @_;
   return if $self->{disconnected};
   return unless $self->{hdl};

   my $res = "HTTP/1.0 $code $msg\015\012";
   header_set ($hdr, 'Date' => AnyEvent::HTTPD::HTTPConnection::_time_to_http_date time)
      unless header_exists ($hdr, 'Date');
   header_set ($hdr, 'Expires' => header_get ($hdr, 'Date'))
      unless header_exists ($hdr, 'Expires');
   header_set ($hdr, 'Cache-Control' => "max-age=0")
      unless header_exists ($hdr, 'Cache-Control');
   header_set ($hdr, 'Connection' =>
                    ($self->{keep_alive} ? 'Keep-Alive' : 'close'));

   header_set ($hdr, 'Content-Length' => length "$content")
      unless header_exists ($hdr, 'Content-Length')
             || ref $content;

   unless (defined header_get ($hdr, 'Content-Length')) {
      # keep alive with no content length will NOT work.
      delete $self->{keep_alive};
      header_set ($hdr, 'Connection' => 'close');
   }

   while (my ($h, $v) = each %$hdr) {
      next unless defined $v;
      for my $vv ( split /\0/, $v ) {
          $res .= "$h: $vv\015\012";
      }
   }

   $res .= "\015\012";

   if ($no_body) { # for HEAD requests!
      $self->{hdl}->push_write ($res);
      $self->response_done;
      return;
   }

   if (ref ($content) eq 'CODE') {
      weaken $self;

      my $chunk_cb = sub {
         my ($chunk) = @_;

         return 0 unless defined ($self) && defined ($self->{hdl}) && !$self->{disconnected};

         delete $self->{transport_polled};

         if (defined ($chunk) && length ($chunk) > 0) {
            $self->{hdl}->push_write ($chunk);

         } else {
            $self->response_done;
         }

         return 1;
      };

      $self->{transfer_cb} = $content;

      $self->{hdl}->on_drain (sub {
         return unless $self;

         if (length $res) {
            my $r = $res;
            undef $res;
            $chunk_cb->($r);

         } elsif (not $self->{transport_polled}) {
            $self->{transport_polled} = 1;
            $self->{transfer_cb}->($chunk_cb) if $self;
         }
      });

   } else {
      $res .= $content;
      $self->{hdl}->push_write ($res);
      $self->response_done;
   }
};

=head1 SYNOPSIS

    use AnyEvent::HTTPD; # Optional,
                         # because the patch module will use it first.
    use AnyEvent::HTTPD::SendMultiHeaderPatch;

    # In the http request handler,
    # separate the multiple values of the same field with \0 character.
    sub {
        my($httpd, $req) = @_;
        # ...
        $req->respond(
            200, 'OK', {
                'Set-Cookie' => "a=123; path=/; domain=.example.com\0b=456; path=/; domain=.example.com"
            }, "Set the cookies"
        );
    }

    # Or use the added util function header_add in AnyEvent::HTTPD::Util.
    use AnyEvent::HTTPD::Util;

    sub {
        my($httpd, $req) = @_;
        # ...
        my %header;
        header_add(\%header, 'Set-Cookie', 'a=123; path=/; domain=.example.com');
        header_add(\%header, 'Set-Cookie', 'b=456; path=/; domain=.example.com');
        $req->respond(200, 'OK', \%header, "Set the cookies");
    }

    # There also introduced another util function header_gets in AnyEvent::HTTPD::Util,
    # to extract multiple values in the header
    sub {
        my($httpd, $req) = @_;
        # ...
        my %header;
        header_add(\%header, 'Example', 'a');
        header_add(\%header, 'Example', 'b');

        my $example_values = header_gets(\%header, 'Example');
        # get ['a', 'b']
        my $no_values = header_gets(\%header, 'None');
        # get []
    }


=head1 CAVEATS

=over 4

=item This is a hack (should be stable)

This module is a hack patch that replace the method 'response' in package AnyEvent::HTTPD::HTTPConnection.
I think that it's still stable since the module AnyEvent::HTTPD has been frozen since 2011.3 (Today is 2013.4)

=item No \0 in your header values

Don't use \0 in your header values since it's used as the separater.

=back

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of AnyEvent::HTTPD::SendMultiHeaderPatch
