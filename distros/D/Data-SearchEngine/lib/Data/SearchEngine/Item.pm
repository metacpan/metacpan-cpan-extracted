package Data::SearchEngine::Item;
{
  $Data::SearchEngine::Item::VERSION = '0.33';
}
use Moose;
use MooseX::Storage;

# ABSTRACT: An individual search result.

with qw(MooseX::Storage::Deferred);


has id => (
    is => 'rw',
    isa => 'Str'
);


has score => (
    is => 'rw',
    isa => 'Num',
    default => 0
);


has values => (
    traits  => [ 'Hash' ],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        keys        => 'keys',
        get_value   => 'get',
        set_value   => 'set',
    },
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Data::SearchEngine::Item - An individual search result.

=head1 VERSION

version 0.33

=head1 SYNOPSIS

  my $results = Data::SearchEngine::Results->new;

  $results->add(Data::SearchEngine::Item->new(
    id => 'SKU',
    values => {
        name => 'Foobar',
        description => 'A great foobar!'
    },
    score => 1.0
  ));

=head1 DESCRIPTION

An item represents an individual search result.  It's really just a glorified
HashRef.

=head1 ATTRIBUTES

=head2 id

A unique identifier for this item.

=head2 score

The score this item earned.

=head2 values

The name value pairs for this item.

=head1 METHODS

=head2 keys

Returns the keys from the values HashRef, e.g. a list of the value names for
this item.

=head2 get_value

Returns the value for the specified key for this item.

=head2 set_value

Sets the value for the specified key for this item.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

