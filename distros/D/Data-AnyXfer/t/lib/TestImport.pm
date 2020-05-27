package TestImport;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Data::AnyXfer::Elastic::Index;

=head1 NAME

    TestImport

=head1 DESCRIPTION

 A simple module that creates a elasticsearch index for testing purposes.

=cut

has silo         => ( is => 'ro', isa => Str );
has index_name   => ( is => 'ro', isa => Str );
has index_type   => ( is => 'ro', isa => Str );
has connect_hint => ( is => 'ro', isa => Str );

sub BUILD {
    my $self = shift;

    $self->_run_import();

    return $self;
}

sub _run_import {
    my $self = shift;

    my $index = Data::AnyXfer::Elastic::Index->new(
        silo         => $self->silo,
        index_name   => $self->index_name,
        index_type   => $self->index_type,
        connect_hint => $self->connect_hint,
    );

    foreach my $data ( _data() ) {
        $index->index( body => $data );
    }

    return 1;
}

sub _data {
    return (
        { name => 'Liverpool St',  region => 'East' },
        { name => 'Fenchurch St',  region => 'East' },
        { name => 'Cannon St',     region => 'South' },
        { name => 'Waterloo',      region => 'South' },
        { name => 'Victoria',      region => 'South' },
        { name => 'Paddington',    region => 'West' },
        { name => 'Euston',        region => 'North' },
        { name => 'St Pancras',    region => [ 'North', 'International' ] },
        { name => 'King\'s Cross', region => 'North' },
    );
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

