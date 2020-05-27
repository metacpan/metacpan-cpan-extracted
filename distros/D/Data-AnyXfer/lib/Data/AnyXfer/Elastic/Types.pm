package Data::AnyXfer::Elastic::Types;

use v5.16.3;
use strict;
use warnings;

use MooseX::Types -declare => [    #
    qw/ IndexName IndexType IndexId IndexNameArray/
];

use MooseX::Types qw/ Str ArrayRef /;
use Const::Fast;

=head1 NAME

Data::AnyXfer::Elastic::Types - Common Elasticsearch Moo Types

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Types qw/ IndexName IndexType IndexId IndexNameArray /;

    ...

    has index_name => (
        is => 'ro',
        isa => IndexName,
    );

=head1 DESCRIPTION

A collection of Moo types specific to Core::Elasticsearch.

The types are validated so that strings can B<only> contain:

    - lowercase a-z
    - numbers
    - full-stops
    - dashes
    - underscores

=head1 TYPES

=over

=item IndexName

Moo Type for Elasticsearch index name

=item IndexType

Moo Type for Elasticsearch index type

=item IndexId

Moo Type for Elasticsearch document name

=item IndexNameArray

Moo Type for multiple Elasticsearch index names

=back

=cut

const my $MSG =>
    'Input does not conform - only [a-z 0-9] and [\. \- \_] permitted';

const my $REGX => qr/^[a-z0-9-_]*$/;

subtype IndexName,    #
    as 'Str',           #
    where { $_ =~ $REGX },    #
    message {$MSG};           #

subtype IndexType,            #
    as 'Str',                   #
    where { $_ =~ $REGX },    #
    message {$MSG};           #

subtype IndexId,              #
    as 'Str',                   #
    where { $_ =~ $REGX },    #
    message {$MSG};           #

subtype IndexNameArray,       #
    as 'ArrayRef[IndexName]';

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

