#
# This file is part of AnyEvent-Riak
#
# This software is copyright (c) 2014 by Damien Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package AnyEvent::Riak;
$AnyEvent::Riak::VERSION = '0.93';
# ABSTRACT: AnyEvent ProtocolBuffers Riak Client

use 5.010;
use strict;
use warnings;
use AnyEvent::Riak::PBC;
use Types::Standard -types;
use Carp;
require bytes;
use Moo;

use AnyEvent::Handle;

my $message_codes = {
  RpbErrorResp => 0,
  RpbPingReq => 1,
  RpbPingResp => 2,
  RpbGetClientIdReq => 3,
  RpbGetClientIdResp => 4,
  RpbSetClientIdReq => 5,
  RpbSetClientIdResp => 6,
  RpbGetServerInfoReq => 7,
  RpbGetServerInfoResp => 8,
  RpbGetReq => 9,
  RpbGetResp => 10,
  RpbPutReq => 11,
  RpbPutResp => 12,
  RpbDelReq => 13,
  RpbDelResp => 14,
  RpbListBucketsReq => 15,
  RpbListBucketsResp => 16,
  RpbListKeysReq => 17,
  RpbListKeysResp => 18,
  RpbGetBucketReq => 19,
  RpbGetBucketResp => 20,
  RpbSetBucketReq => 21,
  RpbSetBucketResp => 22,
  RpbMapRedReq => 23,
  RpbMapRedResp => 24,
  RpbIndexReq => 25,
  RpbIndexResp => 26,
  RpbSearchQueryReq => 27,
  RbpSearchQueryResp => 28,
  RpbResetBucketReq => 29,
  RpbResetBucketResp => 30,
  RpbGetBucketTypeReq => 31,
  RpbSetBucketTypeResp => 32,
  RpbCSBucketReq => 40,
  RpbCSUpdateReq => 41,
  RpbCounterUpdateReq => 50,
  RpbCounterUpdateResp => 51,
  RpbCounterGetReq => 52,
  RpbCounterGetResp => 53,
  RpbYokozunaIndexGetReq => 54,
  RpbYokozunaIndexGetResp => 55,
  RpbYokozunaIndexPutReq => 56,
  RpbYokozunaIndexPutResp => 57,
  RpbYokozunaSchemaGetReq => 58,
  RpbYokozunaSchemaGetResp => 59,
  RpbYokozunaSchemaPutReq => 60,
  DtFetchReq => 80,
  DtFetchResp => 81,
  DtUpdateReq => 82,
  DtUpdateResp => 83,
  RpbAuthReq => 253,
  RpbAuthResp => 254,
  RpbStartTls => 255,
};


has host                => ( is => 'ro', isa => Str,  default => sub { '127.0.0.1'} );
has port                => ( is => 'ro', isa => Int,  default => sub { 8087 } );
has on_connect          => ( is => 'ro', isa => CodeRef,  required => 1 );
has on_connect_error    => ( is => 'ro', isa => CodeRef,  required => 1 );
has connect_timeout     => ( is => 'ro', isa => Num,  default  => sub {5} );
has timeout             => ( is => 'ro', isa => Num,  default  => sub {5} );
has no_delay            => ( is => 'ro', isa => Bool, default  => sub {0} );

has _handle => ( is => 'ro', lazy => 1, clearer => 1, builder => sub {
    my ($self) = @_;
    my ($host, $port) = ($self->host, $self->port);

    my $on_connect = $self->on_connect;
    my $on_connect_error = $self->on_connect_error;
    my $c_timeout = $self->connect_timeout;
    my $no_delay = $self->no_delay;

    AnyEvent::Handle->new (
      connect  => [$host, $port],
      no_delay => $no_delay,
      on_connect => $on_connect,
      on_connect_error => $on_connect_error,
      on_prepare => sub { $c_timeout },
      on_error => sub { my ($handle, $fatal, $message) = @_;
                        croak "Panic: no special on_error has been set yet! error: $message"; },
    );

});


sub BUILD {
    my ($self) = @_;
    $self->_handle();
}


sub close {
    my ($self, $callback) = @_;
    defined $callback && ref($callback) eq 'CODE'
      or croak "last parameter must be a CoderRef callback";
    $self->_handle->low_water_mark(0);
    $self->_handle->on_drain( sub { shutdown($_[0]{fh}, 1); $callback->(); } );
    $self->_clear_handle();
    return;
}

# we don't want DESTROY to be autoloaded
sub DESTROY { }

### Deal with common, general case, Riak commands
our $AUTOLOAD;

sub AUTOLOAD {
  my $command = $AUTOLOAD;
  $command =~ s/.*://;

  my ($request_name, $request_code, $response_name, $response_code) = _command_to_req($command);
  my $method = sub { shift->_run_cmd($request_name, $request_code, $response_name, $response_code, @_) };

  # Save this method for future calls
  no strict 'refs';
  *$AUTOLOAD = $method;

  goto $method;
}

sub _command_to_req {
    my ($command) = @_;
    my $request_name  = 'Rpb' . ucfirst(_to_camel($command)) . 'Req';
    my $response_name = 'Rpb' . ucfirst(_to_camel($command)) . 'Resp';
    my $request_code  = $message_codes->{$request_name};
    my $response_code = $message_codes->{$response_name};
    defined $request_code && defined $response_code
      or croak "unknown method '$command'";
    return $request_name, $request_code, $response_name, $response_code;
}

sub _run_cmd {
    my $callback = pop;
    defined $callback && ref($callback) eq 'CODE'
      or croak "last parameter must be a CoderRef callback";
    my ( $self, $request_name, $request_code, $response_name, $expected_response_code, $args ) = @_;

    my $body = '';
    if (defined $args) {
        eval { $body = "$request_name"->encode($args); 1 }
          or return $callback->(undef, { error_code => -1, error_message => $@ });
    }

    my $handle = $self->_handle;
    $handle->on_error(sub {
        my ($handle, $fatal, $message) = @_;
        $fatal or $handle->destroy(); # force destroy even if non fatal
        $callback->(undef, { error_code => $!,
                             error_message => $message }) });

    $handle->timeout_reset;
    $handle->timeout($self->timeout);
    $handle->on_timeout(sub { $callback->(undef, { error_code => -1,
                                                   error_message => 'timeout' }) });
    $handle->push_write(  pack('N', bytes::length($body) + 1)
                        . pack('c', $request_code) . $body
                       );
    $handle->timeout_reset;

    $handle->push_read( chunk => 4, sub {
         my $len = unpack "N", $_[1];
         $_[0]->timeout_reset;
         $_[0]->unshift_read( chunk => $len, sub {
             $_[0]->timeout_reset;
             $_[0]->timeout(0);
             my ( $response_code, $response_body ) = unpack( 'c a*', $_[1] );

             if ($response_code == $message_codes->{RpbErrorResp}) {
                 my $decoded_message = RpbErrorResp->decode($response_body);
                 return $callback->(undef, { error_code => $decoded_message->errcode,
                                             error_message => $decoded_message->errmsg });
             }
             if ($response_code != $expected_response_code) {
                 return $callback->(undef, {
                   error_code => -2,
                   error_message =>   "wrong response (got: '$response_code', "
                                    . "expected: '$expected_response_code')" });
             }

             # my ($ret, $more_to_come) = ( 1, );

             my $result;
             if ($response_name) {
                 $result = $response_name->decode($response_body);
                 ref($result) eq $response_name
                   or return $callback->(undef, {
                     error_code => -2,
                     error_message =>   "wrong response (got: '" . ref($result) . "', "
                                      . "expected: '$response_name')" });
             } else {
                 $result = 1;
             }
             return $callback->($result);
         });
     });
    $handle->timeout_reset;
    return;
}

sub _to_camel {
    my ($str) = @_;
    $str =~ s/_([a-z])/uc($1)/ge;
    return $str;
}



# Now, some methods that are not generic

sub set_bucket {
    my ($request_name, $request_code, $response_name, $response_code) = _command_to_req('set_bucket');
    shift->_run_cmd($request_name, $request_code, undef, $response_code, @_);
}

sub reset_bucket {
    my ($request_name, $request_code, $response_name, $response_code) = _command_to_req('reset_bucket');
    shift->_run_cmd($request_name, $request_code, undef, $response_code, @_);
}

sub get_bucket_type {
    my $request_name = 'RpbGetBucketTypeReq';
    my $response_name = 'RpbGetBucketResp';
    shift->_run_cmd($request_name, $message_codes->{$request_name},
                    $response_name, $message_codes->{$response_name}, @_);
}

sub set_bucket_type {
    croak "not implemented yet";
}


sub get_client_id {
    croak "deprecated since Riak 1.4";
}


sub set_client_id {
    croak "deprecated since Riak 1.4";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Riak - AnyEvent ProtocolBuffers Riak Client

=head1 VERSION

version 0.93

=head1 SYNOPSIS

  use AnyEvent::Riak;
  my $cv1 = AE::cv;
  my $client = AnyEvent::Riak->new(
    on_connect       => sub { $cv1->send },
    on_connect_error => sub { $cv1->croak($_[1])},
  );
  $cv1->recv;

  my $cv2
  $client->put({ bucket  => 'bucket_name',
                 key     => 'key_name',
                 content => { value => 'plip',
                              content_type => 'text/plain',
                            },
               },
               sub {
                   my ($result, $error) = @_;
                   $error and $cv2->croak(
                     sprintf("error %d: %s",
                     @{$error}{qw(error_code error_message)})
                   );
                   $cv2->send($result);
               });

  my $put_result = $cv2->recv();

  my $cv3 = AE::cv;
  $client->get({ bucket => 'bucket_name',
                 key => 'key_name',
               },
               sub {
                   my ($result, $error) = @_;
                   $error and $cv3->croak(
                     sprintf("error %d: %s",
                     @{$error}{qw(error_code error_message)})
                   );
                   $cv3->send($result);
               });

  my $get_result = $cv3->recv();

=head1 ATTRIBUTES

=head2 host => $hostname

Str, Required. Riak IP or hostname. Default to 127.0.0.1

=head2 port => $port_number

Int, Required. Port of the PBC interface. Default to 8087

=head2 on_connect => $cb->($handle, $host, $port, $retry->())

CodeRef, required. Executed on connection. Check out
L<AnyEvent::Handle#on_connect-cb--handle-host-port-retry>

=head2 on_connect_error => $cb->($handle, $message)

CodeRef, required. Executed when the connection could not be established. Check out
L<AnyEvent::Handle#on_connect_error-cb--handle-message>

=head2 connect_timeout => $fractional_seconds

Float, Default 5. Timeout for connection operation, in seconds. Set to 0 for no timeout.

=head2 timeout => $fractional_seconds

Float, Default 5. Timeout for read/write operation, in seconds. Set to 0 for no timeout.

=head2 no_delay => <boolean>

Boolean, Default 0. If set to a true value, TCP_NODELAY will be enabled on the
socket, which means deactivating Nagle's algorithm. Use only if you know what
you're doing.

=head1 METHODS

=head2 $client->close($cb)

This method will wait until everything has been written to the connection, then
close the connection, and then calls the callback without parameters. Use this
to properly close the connection, before destroying the client instance.

=head2 get_bucket

Get bucket properties request.

=over

=item bucket

required, string

=item type

optional, string

=back

=head2 set_bucket

Set bucket properties request

=over

=item bucket

required, string

=item props

required, RpbBucketProps

=item type

optional, string

=back

=head2 reset_bucket

Reset bucket properties request

=over

=item bucket

required, string

=item type

optional, string

=back

=head2 get_bucket_type

Get bucket properties request

=over

=item type

required, string

=back

=head2 set_bucket_type

Set bucket properties request

=over

=item type

required, string

=item props

required, RpbBucketProps

=back

=head2 get

Get Request - retrieve bucket/key

=over

=item bucket

required, string

=item key

required, string

=item r

optional, number

=item pr

optional, number

=item basic_quorum

optional, boolean

=item notfound_ok

optional, boolean

=item if_modified

optional, string

fail if the supplied vclock does not match

=item head

optional, boolean

return everything but the value

=item deletedvclock

optional, boolean

return the tombstone's vclock, if applicable

=item timeout

optional, number

=item sloppy_quorum

optional, boolean

Experimental, may change/disappear

=item n_val

optional, number

Experimental, may change/disappear

=item type

optional, string

Bucket type, if not set we assume the 'default' type

=back

=head2 put

Put request - if options.return_body is set then the updated metadata/data for the key will be returned.

=over

=item bucket

required, string

=item key

optional, string

=item vclock

optional, string

=item content

required, RpbContent

=item w

optional, number

=item dw

optional, number

=item return_body

optional, boolean

=item pw

optional, number

=item if_not_modified

optional, boolean

=item if_none_match

optional, boolean

=item return_head

optional, boolean

=item timeout

optional, number

=item asis

optional, boolean

=item sloppy_quorum

optional, boolean

Experimental, may change/disappear

=item n_val

optional, number

Experimental, may change/disappear

=item type

optional, string

Bucket type, if not set we assume the 'default' type

=back

=for Pod::Coverage BUILD

=for Pod::Coverage get_client_id

=for Pod::Coverage set_client_id

=begin NOT_IMPLEMENTED

=method auth

Authentication request

=over

=item user

required, string

=item password

required, string

=back

=method set_client_id

=over

=item client_id

required, string

Client id to use for this connection
=back

=end NOT_IMPLEMENTED

=begin NOT_IMPLEMENTED

=method del

Delete request

=over

=item bucket

required, string

=item key

required, string

=item rw

optional, number

=item vclock

optional, string

=item r

optional, number

=item w

optional, number

=item pr

optional, number

=item pw

optional, number

=item dw

optional, number

=item timeout

optional, number

=item sloppy_quorum

optional, boolean

Experimental, may change/disappear
=item n_val

optional, number

Experimental, may change/disappear
=item type

optional, string

Bucket type, if not set we assume the 'default' type
=back

=method list_buckets

List buckets request 

=over

=item timeout

optional, number

=item stream

optional, boolean

=item type

optional, string

Bucket type, if not set we assume the 'default' type
=back

=method list_keys

List keys in bucket request

=over

=item bucket

required, string

=item timeout

optional, number

=item type

optional, string

Bucket type, if not set we assume the 'default' type
=back

=method map_red

Map/Reduce request

=over

=item request

required, string

=item content_type

required, string

=back

=method index

Secondary Index query request

=over

=item bucket

required, string

=item index

required, string

=item qtype

required, one of 'eq', 'range'

=item key

optional, string

key here means equals value for index?
=item range_min

optional, string

=item range_max

optional, string

=item return_terms

optional, boolean

=item stream

optional, boolean

=item max_results

optional, number

=item continuation

optional, string

=item timeout

optional, number

=item type

optional, string

Bucket type, if not set we assume the 'default' type
=item term_regex

optional, string

=item pagination_sort

optional, boolean

Whether to use pagination sort for non-paginated queries=back
=method CS_bucket

 added solely for riak_cs currently for folding over a bucket and returning objects.

=over

=item bucket

required, string

=item start_key

required, string

=item end_key

optional, string

=item start_incl

optional, boolean

=item end_incl

optional, boolean

=item continuation

optional, string

=item max_results

optional, number

=item timeout

optional, number

=item type

optional, string

Bucket type, if not set we assume the 'default' type
=back

=method counter_update

Counter update request

=over

=item bucket

required, string

=item key

required, string

=item amount

required, sint64

=item w

optional, number

=item dw

optional, number

=item pw

optional, number

=item returnvalue

optional, boolean

=back

=method counter_get

 counter value

=over

=item bucket

required, string

=item key

required, string

=item r

optional, number

=item pr

optional, number

=item basic_quorum

optional, boolean

=item notfound_ok

optional, boolean

=back

=end NOT_IMPLEMENTED

=head1 RESPONSE OBJECTS

Results returned from various methods are blessed response objects from the
following types. Their attributes can be accessed using accessors (of the same
name), or using the response as a HashRef.

=head2 RpbErrorResp

Error response - may be generated for any Req

=over

=item errmsg

required, string

=item errcode

required, number

=back

=head2 RpbGetServerInfoResp

Get server info request - no message defined, just send RpbGetServerInfoReq message code

=over

=item node

optional, string

=item server_version

optional, string

=back

=head2 RpbGetBucketResp

Get bucket properties response

=over

=item props

required, RpbBucketProps

=back

=head2 RpbGetClientIdResp

Get ClientId Request - no message defined, just send RpbGetClientIdReq message code

=over

=item client_id

required, string

Client id in use for this connection

=back

=head2 RpbGetResp

Get Response - if the record was not found there will be no content/vclock

=over

=item content

repeated, RpbContent

=item vclock

optional, string

the opaque vector clock for the object

=item unchanged

optional, boolean

=back

=head2 RpbPutResp

Put response - same as get response with optional key if one was generated

=over

=item content

repeated, RpbContent

=item vclock

optional, string

the opaque vector clock for the object

=item key

optional, string

the key generated, if any

=back

=head2 RpbListBucketsResp

List buckets response - one or more of these packets will be sent the last one will have done set true (and may not have any buckets in it)

=over

=item buckets

repeated, string

=item done

optional, boolean

=back

=head2 RpbListKeysResp

List keys in bucket response - one or more of these packets will be sent the last one will have done set true (and may not have any keys in it)

=over

=item keys

repeated, string

=item done

optional, boolean

=back

=head2 RpbMapRedResp

Map/Reduce response one or more of these packets will be sent the last one will have done set true (and may not have phase/data in it)

=over

=item phase

optional, number

=item response

optional, string

=item done

optional, boolean

=back

=head2 RpbIndexResp

Secondary Index query response

=over

=item keys

repeated, string

=item results

repeated, RpbPair

=item continuation

optional, string

=item done

optional, boolean

=back

=head2 RpbCSBucketResp

 return for CS bucket fold

=over

=item objects

repeated, RpbIndexObject

=item continuation

optional, string

=item done

optional, boolean

=back

=head2 RpbCounterUpdateResp

Counter update response? No message | error response

=over

=item value

optional, sint64

=back

=head2 RpbCounterGetResp

Counter value response

=over

=item value

optional, sint64

=back

=head1 AUTHOR

Damien Krotkine <dams@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Damien Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
