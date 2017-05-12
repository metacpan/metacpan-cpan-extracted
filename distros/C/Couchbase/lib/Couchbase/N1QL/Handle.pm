package Couchbase::N1QL::Row;
use strict;
use warnings;

package Couchbase::N1QL::Handle;
use strict;
use warnings;
use Couchbase;
use Couchbase::_GlueConstants;
use Couchbase::N1QL::Params;
use JSON::MaybeXS;
use base (qw(Couchbase::View::Handle));

my $JSON = JSON::MaybeXS->new->allow_nonref;

sub new {
    my ($cls, $bucket, $query, $qargs, $params) = @_;
    my $pobj = Couchbase::N1QL::Params->new();

    $qargs ||= {};
    $params ||= {};
    $params = {%$params};

    my $host = delete $params->{_host};
    $host ||= '';

    $pobj->setquery($query, LCB_N1P_QUERY_STATEMENT);
    if (ref $qargs eq 'HASH') {
        while (my ($k,$v) = each %$qargs) {
            $pobj->namedparam("\$$k", $JSON->encode($v));
        }
    } elsif (ref $qargs eq 'ARRAY') {
        $pobj->posparam($JSON->encode($_)) for @$qargs;
    }

    while (my ($k,$v) = each %$params) {
        $pobj->setopt($k,$v);
    }

    # So now we have the params. Let's create the query
    my $self = Couchbase::_n1qlhandle_new($bucket, $pobj, $host);
    $self->[VHIDX_PRIVCB] = \&row_callback;
    $self->_priv({
        errinfo => undef
    });
    return bless $self, $cls;
}

sub process_meta {
    my ($self) = @_;
    eval {
        $self->meta($JSON->decode($self->meta));
    }; if ($@) {
        return;
    }

    $self->_priv->{errinfo} = $self->meta->{errors};
}

sub row_callback {
    my ($self,$rows) = @_;
    if (!$rows) {
        $self->process_meta();
        return;
    }
    foreach my $row (@$rows) {
        eval {
            $row = $JSON->decode($row);
        }; if ($@) {
            printf("Decoding error!\n");
            printf("$@: %s\n", $row);
        }
        bless $row, 'Couchbase::N1QL::Row';
        push @{$self->rows}, $row;
    }
}

sub errinfo {
    my $self = shift;
    return $self->_priv->{errinfo};
}

sub as_hash {
    my $self = shift;
    my %h = (
        status => $self->errstr,
    );
    if (!$self->is_ok) {
        $h{errinfo} = $self->errinfo;
    }
    return \%h;
}

1;
