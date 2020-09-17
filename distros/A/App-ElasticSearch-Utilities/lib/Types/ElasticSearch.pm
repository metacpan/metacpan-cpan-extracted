package Types::ElasticSearch;
# ABSTRACT: Types for working with ElasticSearch

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use Type::Library -base;
use Type::Tiny;

my $TimeConstant = Type::Tiny->new(
    name       => "TimeConstant",
    constraint => sub { defined($_) && /^\d+(y|M|w|d|h|m|s|ms)$/ },
    message    => sub {
        "must be time constant: https://www.elastic.co/guide/en/elasticsearch/reference/master/common-options.html#time-units"
    },
);

__PACKAGE__->meta->add_type($TimeConstant);
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Types::ElasticSearch - Types for working with ElasticSearch

=head1 VERSION

version 7.8

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
