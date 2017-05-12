package Apache2::Filter::HTTPHeadersFixup;

$Apache2::Filter::HTTPHeadersFixup::VERSION = '0.06';

use strict;
use warnings FATAL => 'all';

use mod_perl 1.9917;

use base qw(Apache2::Filter);

use Apache2::Connection ();
use APR::Brigade ();
use APR::Bucket ();

use Apache::TestTrace;

use constant DEBUG => 0;

use subs qw(mydebug);
*mydebug = DEBUG ? \&Apache::TestTrace::debug : sub {};

use Apache2::Const -compile => qw(OK DECLINED CONN_KEEPALIVE);
use APR::Const    -compile => ':common';

# this is the function that needs to be overriden
sub manip {
    my ($class, $ra_headers) = @_;
    warn "You should write a subclass of " . __PACKAGE__  .
        " since by default HTTP headers are left intact\n";
}

# perl < 5.8 can't handle more than one attribute in the subroutine
# definition so add the "method" attribute separately
use attributes ();
attributes::->import(__PACKAGE__ => \&handler, "method");

sub handler : FilterConnectionHandler {

    mydebug join '', "-" x 20 ,
        (@_ == 6 ? " input" : " output") . " filter called ", "-" x 20;

    # $mode, $block, $readbytes are passed only for input filters
    # so there are 3 more arguments
    return @_ == 6 ? handle_input(@_) : handle_output(@_);

}

sub context {
    my ($f) = shift;

    my $ctx = $f->ctx;
    unless ($ctx) {
        mydebug "filter context init";
        $ctx = {
            headers             => [],
            done_with_headers   => 0,
            seen_body_separator => 0,
            keepalives          => $f->c->keepalives,
        };
        # since we are going to manipulate the reference stored in
        # ctx, it's enough to store it only once, we will get the same
        # reference in the following invocations of that filter
        $f->ctx($ctx);
        return $ctx;
    }

    my $c = $f->c;
    if ($c->keepalive == Apache2::Const::CONN_KEEPALIVE &&
        $ctx->{done_with_headers} &&
        $c->keepalives > $ctx->{keepalives}) {

        mydebug "a new request resetting the input filter state";

        $ctx->{headers}             = [];
        $ctx->{done_with_headers}   = 0;
        $ctx->{seen_body_separator} = 0;
        $ctx->{keepalives} = $c->keepalives;
    }

    return $ctx;
}

sub handle_output {
    my($class, $f, $bb) = @_;

    my $ctx = context($f);

    # handling the HTTP request body
    if ($ctx->{done_with_headers}) {
        mydebug "passing the body through unmodified";
        my $rv = $f->next->pass_brigade($bb);
        return $rv unless $rv == APR::Const::SUCCESS;
        return Apache2::Const::OK;
    }

    $bb->flatten(my $data);

    mydebug "data: $data\n";

    my $c = $f->c;
    my $ba = $c->bucket_alloc;
    while ($data =~ /(.*\n)/g) {
        my $line = $1;
        mydebug "READ: [$line]";
        if ($line =~ /^[\r\n]+$/) {
            # let the user function do the manipulation of the headers
            # without the separator, which will be added when the
            # manipulation has been completed
            $ctx->{done_with_headers}++;
            $class->manip($ctx->{headers});
            my $data = join '', @{ $ctx->{headers} }, "\n";
            $ctx->{headers} = [];

            my $out_bb = APR::Brigade->new($c->pool, $ba);
            $out_bb->insert_tail(APR::Bucket->new($ba, $data));

            my $rv = $f->next->pass_brigade($out_bb);
            return $rv unless $rv == APR::Const::SUCCESS;

            return Apache2::Const::OK;
            # XXX: is it possible that some data will be along with
            # headers in the same incoming bb?
        }
        else {
            push @{ $ctx->{headers} }, $line;
        }
    }

    return Apache2::Const::OK;
}

sub handle_input {
    my($class, $f, $bb, $mode, $block, $readbytes) = @_;

    my $ctx = context($f);

    # handling the HTTP request body
    if ($ctx->{done_with_headers}) {
        mydebug "passing the body through unmodified";
        return Apache2::Const::DECLINED;
    }

    # any custom input HTTP header buckets to inject?
    return Apache2::Const::OK if inject_header_bucket($bb, $ctx);

    # normal HTTP headers processing
    my $c = $f->c;
    until ($ctx->{seen_body_separator}) {
        my $ctx_bb = APR::Brigade->new($c->pool, $c->bucket_alloc);
        my $rv = $f->next->get_brigade($ctx_bb, $mode, $block, $readbytes);
        return $rv unless $rv == APR::Const::SUCCESS;

        while (!$ctx_bb->is_empty) {
            my $b = $ctx_bb->first;

            if ($b->is_eos) {
                mydebug "EOS!!!";
                $b->remove;
                $bb->insert_tail($b);
                last;
            }

            my $len = $b->read(my $data);

            # leave the non-data buckets as is
            unless ($len) {
                $b->remove;
                $bb->insert_tail($b);
                next;
            }

            # XXX: losing meta buckets here
            $b->delete;
            mydebug "filter read:\n[$data]";

            if ($data =~ /^[\r\n]+$/) {
                # normally the body will start coming in the next call to
                # get_brigade, so if your filter only wants to work with
                # the headers, it can decline all other invocations if that
                # flag is set. However since in this test we need to send 
                # a few extra bucket brigades, we will turn another flag
                # 'done_with_headers' when 'seen_body_separator' is on and
                # all headers were sent out
                mydebug "END of original HTTP Headers";
                $ctx->{seen_body_separator}++;

                # let the user function do the manipulation of the headers
                # without the separator, which will be added when the
                # manipulation has been completed
                $class->manip($ctx->{headers});

                # but at the same time we must ensure that the
                # the separator header will be sent as a last header
                # so we send one newly added header and push the separator
                # to the end of the queue
                push @{ $ctx->{headers} }, "\n";
                mydebug "queued header [$data]";
                inject_header_bucket($bb, $ctx);
                last; # there should be no more headers in $ctx_bb
                # notice that if we didn't inject any headers, this will
                # still work ok, as inject_header_bucket will send the
                # separator header which we just pushed to its queue
            } else {
                push @{ $ctx->{headers} }, $data;
            }
        }
    }

    return Apache2::Const::OK;
}

# returns 1 if a bucket with a header was inserted to the $bb's tail,
# otherwise returns 0 (i.e. if there are no headers to insert)
sub inject_header_bucket {
    my ($bb, $ctx) = @_;

    return 0 unless @{ $ctx->{headers} };

    # extra debug, wasting cycles
    my $data = shift @{ $ctx->{headers} };
    $bb->insert_tail(APR::Bucket->new($bb->bucket_alloc, $data));
    mydebug "injected header: [$data]";

    # next filter invocations will bring the request body if any
    if ($ctx->{seen_body_separator} && !@{ $ctx->{headers} }) {
        $ctx->{done_with_headers}   = 1;
    }

    return 1;
}

1;
__END__

=pod

=head1 NAME

Apache2::Filter::HTTPHeadersFixup - Manipulate Apache 2 HTTP Headers

=head1 Synopsis

  # MyApache/FixupInputHTTPHeaders.pm
  package MyApache::FixupInputHTTPHeaders;
  
  use strict;
  use warnings FATAL => 'all';
  
  use base qw(Apache2::Filter::HTTPHeadersFixup);
  
  sub manip {
      my ($class, $ra_headers) = @_;
  
      # modify a header
      for (@$ra_headers) {
          s/^(Foo).*/$1: Moahaha/;
      }
  
      # push header (don't forget "\n"!)
      push @$ra_headers, "Bar: MidBar\n";
  }
  1;

  # httpd.conf
  <VirtualHost Zoot>
      PerlModule MyApache::FixupInputHTTPHeaders
      PerlInputFilterHandler MyApache::FixupInputHTTPHeaders
  </VirtualHost>

  # similar for output headers

=head1 Description

C<Apache2::Filter::HTTPHeadersFixup> is a super class which provides an
easy way to manipulate HTTP headers without invoking any mod_perl HTTP
handlers. This is accomplished by using input and/or output connection
filters.

It supports KeepAlive connections.

This class cannot be used as is. It has to be sub-classed. Read on.

=head1 Usage

A new class inheriting from C<Apache2::Filter::HTTPHeadersFixup> needs
to be created. That class needs to include a single function
C<manip()>. This function is invoked with two arguments, the package
it was invoked from and a reference to an array of headers, each
terminated with a new line.

That function can manipulate the values in that array. It shouldn't
return anything. That means you can't assign to the reference itself
or the headers will be lost.

Now you can modify, add or remove headers.

The function works identically for input and output HTTP headers.

See the L<Synopsis> section for an example. More examples can be seen
in the test suite.

=head1 Debug

C<Apache2::Filter::HTTPHeadersFixup> includes internal tracing calls,
which make it easy to debug the parsing of the headers.

First change the constant DEBUG to 1 in
C<Apache2::Filter::HTTPHeadersFixup>. Then enable Apache-Test debug
tracing. For example to run a test with tracing enabled do:

  % t/TEST -trace=debug -v manip/out_append

Or you can set the C<APACHE_TEST_TRACE_LEVEL> environment variable to
I<debug> at the server startup:

  APACHE_TEST_TRACE_LEVEL=debug apachectl start

All the tracing goes into I<error_log>.

=head1 Bugs

=head1 See Also

L<Apache2>, L<mod_perl>, L<Apache2::Filter>




=head1 Author

Philip M. Gollucci E<lt>pgollucci@p6m7g8.comE<gt>

Previously developed by Stas Bekman.




=head1 Copyright

The C<Apache2::Filter::HTTPHeadersFixup> module is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
