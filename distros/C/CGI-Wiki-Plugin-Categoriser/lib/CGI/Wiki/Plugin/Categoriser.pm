package CGI::Wiki::Plugin::Categoriser;
use strict;
use CGI::Wiki::Plugin;

use vars qw( $VERSION @ISA );
$VERSION = '0.02';
@ISA = qw( CGI::Wiki::Plugin );

=head1 NAME

CGI::Wiki::Plugin::Categoriser - Category management for CGI::Wiki.

=head1 DESCRIPTION

Uses node metadata to build a model of how nodes are related to each
other in terms of categories.

=head1 SYNOPSIS

  use CGI::Wiki;
  use CGI::Wiki::Plugin::Categoriser;

  my $wiki = CGI::Wiki->new( ... );
  $wiki->write_node( "Red Lion", "nice beer", $checksum,
                     { category => [ "Pubs", "Pub Food" ] } );
  $wiki->write_node( "Holborn Station", "busy at peak times", $checksum,
                     { category => "Tube Station" } );

  my $categoriser = CGI::Wiki::Plugin::Categoriser->new;
  $wiki->register_plugin( plugin => $categoriser );

  my $isa_pub = $categoriser->in_category( category => "Pubs",
                                           node     => "Red Lion" );
  my @categories = $categoriser->categories( node => "Holborn Station" );

=head1 METHODS

=over 4

=item B<new>

  my $categoriser = CGI::Wiki::Plugin::Categoriser->new;
  $wiki->register_plugin( plugin => $categoriser );

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item B<in_category>

  my $isa_pub = $categoriser->in_category( category => "Pubs",
                                           node     => "Red Lion" );

Returns true if the node is in the category, and false otherwise. Note
that this is B<case-insensitive>, so C<Pubs> is the same category as
C<pubs>. I might do something to make it plural-insensitive at some
point too.

=cut

sub in_category {
    my ($self, %args) = @_;
    my @catarr = $self->categories( node => $args{node} );
    my %categories = map { lc($_) => 1 } @catarr;
    return $categories{lc($args{category})};
}

=item B<subcategories>

  $wiki->write_node( "Category Pub Food",
                     "pubs that serve food",
                     $checksum,
                     { category => [ "Pubs", "Food", "Category" ] } );
  my @subcategories = $categoriser->subcategories( category => "Pubs" );
  # will return ( "Pub Food" )

  # Or if you prefer CamelCase node names:
  $wiki->write_node( "CategoryPubFood",
                     "pubs that serve food",
                     $checksum,
                     { category => [ "Pubs", "Food", "Category" ] } );
  my @subcategories = $categoriser->subcategories( category => "Pubs" );
  # will return ( "PubFood" )

To add a subcategory C<Foo> to a given category C<Bar>, write a node
called any one of C<Foo>, C<Category Foo>, or C<CategoryFoo> with
metadata indicating that it's in categories C<Bar> and C<Category>.

Yes, this pays specific attention to the Wiki convention of defining
categories by prefacing the category name with C<Category> and
creating a node by that name. If different behaviour is required we
should probably implement it using an optional argument in the
constructor.

=cut

sub subcategories {
    my ($self, %args) = @_;
    return () unless $args{category};
    my $datastore = $self->datastore;
    my %cats = map { $_ => 1 }
                   $datastore->list_nodes_by_metadata(
                       metadata_type  => "category",
                       metadata_value => "Category" );
    my @in_cat = $datastore->list_nodes_by_metadata(
                       metadata_type  => "category",
                       metadata_value => $args{category} );
    return map { s/^Category\s+//; $_ } grep { $cats{$_} } @in_cat;
}

=item B<categories>

  my @categories = $categoriser->categories( node => "Holborn Station" );

Returns an array of category names in no particular order.

=cut

sub categories {
    my ($self, %args) = @_;
    my $dbh = $self->datastore->dbh;
    my $sth = $dbh->prepare( "
SELECT metadata.metadata_value FROM metadata, node WHERE node.name = ? AND metadata.node = node.name AND metadata.version = node.version AND metadata.metadata_type = 'category'
    " );
    $sth->execute( $args{node} );
    my @categories;
    while ( my ($cat) = $sth->fetchrow_array ) {
        push @categories, $cat;
    }
    return @categories;
}

=head1 SEE ALSO

=over 4

=item *

L<CGI::Wiki>

=item *

L<CGI::Wiki::Plugin>

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 TODO

Improve subcategories, do category hierarchy.

=cut

1;
