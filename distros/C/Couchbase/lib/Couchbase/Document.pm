package Couchbase::Document;
use strict;
use warnings;

use Couchbase::Core;
use Couchbase::Constants;
use Couchbase::_GlueConstants;
use Couchbase;
use base qw(Exporter);

our @EXPORT = (qw(COUCHBASE_FMT_JSON COUCHBASE_FMT_UTF8 COUCHBASE_FMT_RAW COUCHBASE_FMT_STORABLE));

use Class::XSAccessor::Array {
    accessors => {
        id => RETIDX_KEY,
        expiry => RETIDX_EXP,
        _cas => RETIDX_CAS,
        value => RETIDX_VALUE,
        errnum => RETIDX_ERRNUM,
    }
};

sub is_ok {
    my $num = $_[0]->[RETIDX_ERRNUM];
    warn("Requested is_ok() on document which does not have a last operation")
        unless $num != -1;
    return $num == COUCHBASE_SUCCESS;
}

sub is_not_found { $_[0]->[RETIDX_ERRNUM] == COUCHBASE_KEY_ENOENT }
sub is_cas_mismatch { $_[0]->[RETIDX_ERRNUM] == COUCHBASE_KEY_EEXISTS }
sub is_already_exists { $_[0]->[RETIDX_ERRNUM] == COUCHBASE_KEY_EEXISTS }
sub new {
    my ($pkg, $id, $doc, $options) = @_;
    if (ref $id && $id->isa($pkg)) {
        return $id->copy();
    }

    my $rv = bless [], $pkg;
    $rv->id($id);
    $rv->value($doc);
    $rv->errnum(-1);
    $rv->format(COUCHBASE_FMT_JSON);

    if ($options) {
        while (my ($k,$v) = each %$options) {
            no strict 'refs';
            $rv->$k ($v);
        }
    }

    return $rv;
}

sub errstr {
    my $self = shift;
    my $rc = $self->errnum || 0;
    my $s = $Couchbase::ErrorMap[$rc];
    if (! $s) {
        $s = $Couchbase::ErrorMap[$rc] = Couchbase::strerror($rc);
    }
    return $s;
}

sub copy {
    my $self = shift;
    bless my $cp = [@$self], 'Couchbase::Document';

    $cp->_cas(0);
    return $cp;
}

our %FMT_STR2NUM = (
    utf8 => COUCHBASE_FMT_UTF8,
    raw => COUCHBASE_FMT_RAW,
    storable => COUCHBASE_FMT_STORABLE,
    json => COUCHBASE_FMT_JSON
);

our %FMT_NUM2STR = reverse(%FMT_STR2NUM);

sub format {
    my ($self, $fmtspec) = @_;
    if (scalar @_ == 1) {
        my ($fmt_s, $fmt_i) = (undef, $self->[RETIDX_FMTSPEC]);
        if (wantarray) {
            $fmt_s = $FMT_NUM2STR{$fmt_i} || "UNKNOWN";
            return ($fmt_s, $fmt_i);
        }
        return $fmt_i;
    }

    if ($fmtspec !~ /^\d+$/) {
        my $numfmt = $FMT_STR2NUM{$fmtspec};
        if (! defined($numfmt)) {
            die("Unrecognized format code " . $fmtspec);
        }
        $fmtspec = $numfmt;
    }
    $_[0]->[RETIDX_FMTSPEC] = $fmtspec;
}

# This doesn't really mean anything special, but is akin to what's used in Python:
sub as_hash {
    my $self = shift;
    my ($fmt_s, $fmt_i) = $self->format;
    my %h = (
        id => $self->id,
        value => $self->value,
        status => sprintf("Code: 0x0%X. Description: %s", $self->errnum, $self->errstr),
        format => sprintf("0x%X (%s)", $fmt_i, $fmt_s),
        expiry => $self->expiry,
        CAS => sprintf("0x%X", $self->_cas || 0)
    );
    return \%h;
}

sub _data_printer {
    my $self = shift;
    my $r = bless $self->as_hash, ref($self) . "::_PrettyDummy";
    Data::Printer::p($r);
}


__END__

=head1 NAME

Couchbase::Document - Object represnting an item in the cluster.


=head1 SYNOPSIS


    my $doc = Couchbase::Document->new("id_string", ["content"]);


=head1 DESCRIPTION

A document is the basic unit of the API and corresponds with an item as it is
stored in the cluster. A newly created document exists only locally in the
application, and must be submitted to the cluster via one of the methods in
L<Couchbase::Bucket>


=head2 CONSTRUCTORS


=head3 new($id)

=head3 new($id, $value, $options)


Creates a new document object. A document object must have a non-empty ID which is
used to associate this object with the relevant item on the cluster. If you desire
to I<store> the document on the cluster, you will also need to supply a value for
the document.

Additional options may also be specified in the C<$options> hashref. The value
for the options may also be set individually by accessor methods documented
below.


=head2 PROPERTIES


=head3 id()

Gets/Sets the ID for this document. The ID should only be set during creation
of the document object.


=head3 value()

=head3 value($new_value)

Gets or sets the new value of the document. The value may be anything that can
be encoded according to the document's L<"format()"> property.

When retrieving a document (via the C<get()> method of L<Couchbase::Bucket>), this
field will be updated with the value stored on the server, if successful.


=head3 format()

=head3 format($format)


Get and set the I<storage format> for the item's value on the cluster. Typical
applications will not need to modify this value, but it may be desirable to
use a special format for performance reasons, or to store values which are
not representable in the default format.

Formats may be set either by specifying their numeric constants, or using
a string alias. The following formats are recognized:


=over

=item C<COUCHBASE_FMT_JSON>, "json"

Stores the item as JSON. This is the default format and allows the value
to be indexed by view queries. The value for the document must be something
encodable as JSON, thus hashes, arrays, and simple scalars are acceptable, while
references to strings, numbers, and similar are I<not>.


=item C<COUCHBASE_FMT_STORABLE>, "storable"

Encodes the value using the C<freeze> method of L<Storable>. Use this format
only for values which cannot be encoded as JSON. Do not use this format
if you wish this value to be readable by non-Perl applications.


=item C<COUCHBASE_FMT_RAW>, "raw"

Stores the item as is, and marks it as an opaque string of bytes.


=item C<COUCHBASE_FMT_UTF8>, "utf8"

Stores the string as is, but flags it on the server as UTF-8. Note that no
client-side validation is made to ensure the value is indeed a legal UTF-8
sequence.

The goal of this format is mainly to indicate to other languages
(for example, Python or Java) which distinguish between bytes and strings
that the stored value is a string. For Perl this is effectively like the
C<COUCHBASE_FMT_RAW> format, except that when retrieving the value, the
C<utf8> flag is set on the scalar.

=back


=head3 expiry()

=head3 expiry($seconds)

Specify the expiration value to be associated with the document. This
value is only read from and never written to, and is used to determine
the "Time to live" for the document. See L<Couchbase::Document/"touch($doc)">


=head2 ERROR CHECKING

=head3 is_ok()

Returns a boolean indicating whether the last operation performed on the cluster
was successful or not. You may inspect the actual error code (and message) by
using the L<"errnum()"> and L<"errstr()"> methods.


=head3 errnum()

Returns the numerical error code of the last operation. An error code of
C<0> means the operation was successful. Other codes indicate other errors.
There are also some convenient methods (below) to check for common error
conditions.

Some of the error codes are documented in L<Couchbase::Constants>.


=head3 errstr()

Returns a textual description of the error. This should be used for
informational purposes only


=head3 is_not_found()

Returns true if the last operation failed because the document did not
exist on the cluster


=head3 is_cas_mismatch()

Returns true if the last operation failed because the local document
contains a stale state. If this is true, the value should typically
be retrieved, or the C<ignore_cas> option should be used in the operation.


=head3 is_already_exists()

Returns true if the last operation failed because the item already
existed in the cluster. Check this on an C<insert> operation.
