package Cassandra::Client::Metadata;
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args)= @_;

    return bless {
        prepare_cache => {},
    }, $class;
}

sub prepare_cache {
    return $_[0]{prepare_cache};
}

sub add_prepared {
    my ($self, $query, $id, $input_metadata, $result_metadata, $decoder, $encoder)= @_;
    $self->{prepare_cache}{$query}= {
        id => $id,
        input_metadata => $input_metadata,
        result_metadata => $result_metadata,
        decoder => $decoder,
        encoder => $encoder
    };
    if (values %{$self->{prepare_cache}} > 500) {
        unless ($self->{warned}++) {
            warn "Cassandra::Client: found more than 500 queries in our prepared statement cache, try using placeholders";
        }
    }
    return;
}

sub is_prepared {
    my ($self, $queryref)= @_;
    my $cached= $self->{prepare_cache}{$$queryref};
    if (!$cached) { return; }

    return 1;
}

1;
