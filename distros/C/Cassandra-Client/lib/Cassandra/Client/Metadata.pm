package Cassandra::Client::Metadata;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Metadata::VERSION = '0.13';
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
    my ($self, $query, $id, $input_metadata, $decoder, $encoder)= @_;
    $self->{prepare_cache}{$query}= {
        id => $id,
        input_metadata => $input_metadata,
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

__END__

=pod

=head1 NAME

Cassandra::Client::Metadata

=head1 VERSION

version 0.13

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
