package Couchbase::Client::Return;
use strict;
use warnings;

use Couchbase::Client::IDXConst;
use Couchbase::Client::Errors;

use Class::XSAccessor::Array {
    accessors => {
        cas => RETIDX_CAS,
        value => RETIDX_VALUE,
        errnum => RETIDX_ERRNUM,
        errstr => RETIDX_ERRSTR
    }
};

sub is_ok {
    $_[0]->[RETIDX_ERRNUM] == COUCHBASE_SUCCESS;
}

{
    no strict 'refs';
    foreach my $errsym (@Couchbase::Client::Errors::EXPORT) {
        my $subname = $errsym;
        $subname =~ s/COUCHBASE_//g;
        *{$subname} = sub { $_[0]->errnum == $_[1] };
    }
}

1;

__END__

=head1 NAME

Couchbase::Client::Return - Common return datatype for Couchbase

=head2 DESCRIPTION

This is the common datatype for couchbase operations. Each operation (e.g.
C<get>, C<set> etc.) will typically have complex return types to facilitate
various types of errors and status reports.

The object is implemented as a simple array whose constants are available in
C<Couchbase::Client::IDXConst> if performance is an issue for calling the methods

=head2 FIELDS

=over

=item errnum

=item is_ok

C<errnum> is the Couchbase specific error code indicating stataus. An operation
is successful if C<errnum> is equal to C<COUCHBASE_SUCCESS>.

The C<is_ok> function does this check internally, and will probably look nicer
in your code.

Some error definitions and explanations can be found in L<Couchbase::Client::Errors>

=item errstr

A human-readable representation of C<errnum>

=item value

I<only valid for get operations>

The returned value for the request. If this is C<undef> it might be advisable
to check error status.

=item cas

I<only valid for get operations>

The opaque CAS item used for atomic updates.

While the protocol itself defines CAS as a <unit64_t>, in perl it is stored as the
equivalent of a C<pack("Q", $casval)> (this is not the actual code used, but
an C<unpack("Q", $casval)> will yield the numeric value)

CAS values will B<always> be returned for C<get>-like functions.

=item <ERRNAME>

Some nice magic in this module.

Instead of doing this:

    if($ret->errnum == COUCHBASE_KEY_EEXISTS) {
        ...
    }
    
you can do this

    if($ret->KEY_EEXISTS) {
        ...
    }
    
    
In other words, you can call any error 'basename' (that is, the
error without the C<COUCHBASE_> prefix) as a method on this object,
and its return value will be a boolean indicating whether C<errnum> is equal
to C<COUCHBASE_$name>

=back