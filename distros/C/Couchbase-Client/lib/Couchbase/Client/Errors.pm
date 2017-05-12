package Couchbase::Client::Errors;
use strict;
use warnings;
use base qw(Exporter);
require Couchbase::Client::Errors_const;
our @EXPORT;


if(!caller) {
    no strict 'refs';
    foreach my $const (@EXPORT) {
        my $val = &{$const}();
        printf("NAME: %s, VALUE=%d\n",
               $const, $val);
    }
}

1;

__END__

=head1 NAME

Couchbase::Client::Errors - Error definitions for Couchbase

=head1 DESCRIPTION

This is just a listing of the known and current error codes.

This listing may be incomplete and varies depending on which constants are
actually provided by the C<libcouchbase> installed on your system.

See C<$INCLUDE/libcouchbase/types.h> for a full listing.

All listings are defined as C<LIBCOUCHBASE_$name> in the C code,
and as C<COUCHBASE_$name> in Perl.

=over

=item SUCCESS

No error has ocurred.

=item ETMPFAIL

A 'temporary' failure has ocurred. This usually means that the server which was
the source or target of the operation (for example, a key store) was unreachable
or unresponsive.

=item KEY_EEXISTS

An operation which required the key not to already exist was attempted, but the
key was found to have already existed

=item KEY_ENOENT

An operation which required the key to already exist was attempted (i.e. C<get>),
but the key was not found.

=item NETWORK_ERROR

A network I/O issue was encountered during the operation.

=item NOT_MY_VBUCKET

An operation was sent to the wrong server. The server which received the operation
does not host the key.

This error is common during failover and adding a new node to the cluster and is
generally transient

=back

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distributed this software under the same terms and conditions as
Perl itself.

