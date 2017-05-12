package Couchbase::Client::Async::Request;
use strict;
use warnings;
use Array::Assign;

use Couchbase::Client::IDXConst;
use Class::XSAccessor::Array {
    accessors => {
        key => REQIDX_KEY,
        value => REQIDX_VALUE,
        expiry => REQIDX_EXP,
        cas => REQIDX_CAS,
        arithmetic_delta => REQIDX_ARITH_DELTA,
        arithmetic_initial => REQIDX_ARITH_INITIAL,
    }
};



1;

__END__

=head1 NAME

Couchbase::Client::Async::Request - Request container for asynchronous
couchbase client

=head1 DESCRIPTION

This documents the fields of the Request object. For a more detailed explanation
of how to use this structure, look at L<Couchbase::Client::Async>

=head2 FIELDS

The request object is a simple array reference. You can either access the fields
directly by using the constants provided via L<Couchbase::Client::IDXConst> or
use the named accessors.

=over

=item REQIDX_KEY, key

This is the key for the operation. Nearly all commands require this.

=item REQIDX_VALUE, value

Required for non-arithmetic mutate commands, e.g. set, add, replace etc.

=item REQIDX_CAS, cas

Optional for mutator commands.

=item REQIDX_EXP, expiry

The expiration value (in seconds from now) for the value. This is required for
touch commands, and optional for other mutators.

=item REQIDX_ARITH_DELTA

Required for arithmetic operations, this is a signed integer which will be
added to the existing value.

=item REQIDX_ARITH_INITIAL

Optional for arithmetic operations, this is an unsigned value which will be
used as the default value, if there is no existing value

=back