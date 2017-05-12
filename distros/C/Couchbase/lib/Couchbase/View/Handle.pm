package Couchbase::View::Row;
use strict;
use warnings;
use Class::XSAccessor accessors => [qw(key value id geometry)];

sub doc {
    return $_[0]->{__doc__};
}

package Couchbase::View::Handle;
use strict;
use warnings;
use Couchbase;
use Couchbase::_GlueConstants;
use URI::Escape qw(uri_escape);
use Carp qw(cluck);
use JSON::MaybeXS;
use base (qw(Couchbase::Document));
use Constant::Generate [qw(ERRINFO ROWCOUNT REQFLAGS)], start_at => 0;
use Devel::Peek;

use Class::XSAccessor::Array accessors => {
    _priv => VHIDX_PLPRIV,
    done => VHIDX_ISDONE,
    rows => VHIDX_ROWBUF,
    meta => VHIDX_META,
    remaining_json => VHIDX_META,
    http_code => VHIDX_HTCODE
};

my $JSON = JSON::MaybeXS->new->allow_nonref;

sub new {
    my ($cls, $parent, $viewspec, %options) = @_;
    my ($view,$design);

    if ((ref $viewspec || '') eq 'ARRAY') {
        ($view, $design) = @$viewspec;
    } else {
        ($view, $design) = ($viewspec =~ m,([^/]+)/(.*),);
    }

    die("Invalid view path: Must pass 'view/design' (or [view, design])") unless $view && $design;

    my $flags;
    if (delete $options{spatial}) {
        $flags |= LCB_CMDVIEWQUERY_F_SPATIAL;
    }
    if (delete $options{include_docs}) {
        $flags |= LCB_CMDVIEWQUERY_F_INCLUDE_DOCS;
    } else {
        $flags |= LCB_CMDVIEWQUERY_F_NOROWPARSE;
    }



    # Form the options string
    my $opt_str = join('&', map {
        sprintf("%s=%s", uri_escape($_), uri_escape($options{$_}))
    } keys %options);


    my $inner = Couchbase::_viewhandle_new($parent, $view, $design, $opt_str, $flags);

    $inner->[VHIDX_PRIVCB] = \&row_callback;
    $inner->[VHIDX_PLPRIV] = [];
    $inner->[VHIDX_PATH] = $viewspec;
    $inner->_priv->[REQFLAGS] = $flags;

    return $inner;
}

sub row_callback {
    my ($self, $rows) = @_;
    if (!$rows) {
        $self->process_meta();
        return;
    }

    # It's significantly quicker if we can reduce the number of subcalls to the JSON
    # parser.
    my $parse_whole =
        $self->[VHIDX_PLPRIV]->[REQFLAGS] & LCB_CMDVIEWQUERY_F_NOROWPARSE;

    foreach my $row (@$rows) {
        if ($parse_whole) {
            $row = $JSON->decode($row->{value});
        } else {
            foreach my $k (qw(key value geometry)) {
                if ((my $tmp = $row->{$k})) {
                    $row->{$k} = $JSON->decode($tmp);
                }
            }
        }

        bless $row, 'Couchbase::View::Row';
        push @{$self->rows}, $row;
    }
}

sub is_ok {
    my $self = shift;
    if (!$self->SUPER::is_ok()) {
        return 0;
    }
    if ($self->errinfo) {
        return 0;
    }
    return 1;
}

sub path {
    return shift->id;
}

sub cas {
    warn ("This method is not implemented for " . __PACKAGE__);
    return;
}

sub count {
    return shift->_priv->[ROWCOUNT];
}

sub errinfo {
    my $self = shift;
    return $self->_priv->[ERRINFO];
}

sub info {
    return $_[0];
}

sub errstr {
    my $self = shift;
    my $ret = $self->SUPER::errstr;
    if (!$ret) {
        return $ret;
    }
    if ($self->http_code !~ /^2\d\d/) {
        $ret .= sprintf(" (HTTP=%d)", $self->http_code);
    }
    if ($self->errinfo) {
        if (ref $self->errinfo eq 'ARRAY') {
            $ret .= " [There were some errors fetching individual rows. See ->errinfo]";
        } elsif (ref $self->errinfo eq 'HASH') {
            $ret .= sprintf(" [Query Error (error=%s, reason=%s)]",
                            $self->errinfo->{error}, $self->errinfo->{reason});
        }
    }
    return $ret;
}

sub next {
    my $self = shift;

    GT_AGAIN:
    if (!@{$self->rows}) {
        if ($self->done) {
            return wantarray ? () : undef;
        }
        Couchbase::_viewhandle_fetch($self);
        goto GT_AGAIN;
    }

    if (wantarray) {
        my @ret = @{$self->rows};
        @{$self->rows} = ();
        return @ret;
    } else {
        return shift @{$self->rows};
    }
}

sub slurp {
    my $self = shift;
    while (!$self->done) {
        Couchbase::_viewhandle_fetch($self);
    }
    return $self->rows;
}

sub stop {
    my $self = shift;
    Couchbase::_viewhandle_stop($self);
}

sub process_meta {
    my $self = shift;
    my $meta = $self->[VHIDX_META];

    if (!defined($meta)) {
        return; # oops
    }

    my $json;
    eval {
        $json = $JSON->decode($meta);
    };

    if (!$json) {
        return; # Not JSON!
    }

    if (exists $json->{errors}) {
        # Errors received from individual nodes
        $self->_priv->[ERRINFO] = delete $json->{errors};
    } elsif (exists $json->{error}) {
        # Errors received for the query itself, e.g. "not_found"
        $self->_priv->[ERRINFO] = {
            reason => delete $json->{reason},
            error => delete $json->{error}
        };
    }
    $self->_priv->[ROWCOUNT] = $json->{total_rows};
}

sub as_hash {
    my $self = shift;
    my %h = (
        path => $self->path,
        count => $self->count,
        status => $self->errstr,
    );
    if (!$self->is_ok) {
        $h{errinfo} = $self->errinfo;
    }
    return \%h;
}

1;

__END__

=head1 NAME


Couchbase::View::Handle - Class for view query handles


=head1 DESCRIPTION

This is a subclass of L<Couchbase::Document>. It contains some view-specific
information. The fields of this object will only contain meaningful values
once the query has been completed (i.e. if calling C<view_iterator>, ensure
the iterator has been exhausted).

=head2 Row Object

The row object (nominally, C<Couchbase::View::Row>) is the object used to
represent a single view row. This object is returned by the L</next> method
(when using an iterator) or as the element type of the L</rows> arrayref
(if using slurp mode). The row object contains the following fields

=head3 key

This is the key emitted as the first argument of the C<emit> function in the
Javascript view.

=head3 value

This is the value emitted as the second argument of the C<emit> function in the
Javascript view

=head3 id

This is the document ID associated with the row. This will only be present if
the C<reduce> function is not used in the query.

=head3 geometry

Valid only for geospatial views, contains the GeoJSON of the given result. Note
that this is the geometry of the emitted item, and may be partially outside the
C<start_range> and C<end_range> parameters.

=head3 doc

This special field contains a L<Couchbase::Document> instance if the
C<include_docs> option was set when the query was made. The document is
fetched internally by the library for each row which has a valid L</id>
field present.

See the C<view_slurp> documentation for more information
on C<include_docs>

=head2 rows

I<Valid only in slurp mode>.

Returns the rows for the query

=head2 stop

I<Valid only in iterator mode>.

Abort iteration. This means to stop fetching extra data from the network. There
will likely still be extra data available from L</next>

=head2 count

Returns the total amount of rows in the result set. This does not mean the amount
of rows which will be returned via the iterator, but rather the server-side count
of the the rows which matched the query parameters

=head2 meta

Return the remaining JSON structure as a read-only hashref. Useful if you think
the iterator is missing something.

=head2 http_code

Returns the HTTP status code for the operation, e.g C<200> or C<404>

=head2 errinfo

Returns extended (non-http, non-libcouchbase, non-memcached) error information.
This is usually a hash converted from a JSON error response.
