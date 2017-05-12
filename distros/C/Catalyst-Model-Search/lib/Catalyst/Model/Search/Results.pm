package Catalyst::Model::Search::Results;

use strict;
use warnings;
use Class::Std;
{
    my %total_hits_of   :ATTR( :init_arg<total_hits> :get<total_hits> );
    my %page_of         :ATTR(                       :get<page>       );
    my %items_of        :ATTR( :init_arg<items>                       );
     
    sub get_items : method {
        my $self = shift;
        return @{ $items_of{ident $self} };
    }

    sub as_num : NUMIFY {
        my ( $self, $ident ) = @_;
        return scalar @{ $items_of{$ident} };
    }
}

1;
__END__

=head1 NAME

Catalyst::Model::Search::Results - Standard access to search results

=head1 DESCRIPTION

This module represents a list of search results.

=head1 METHODS

=head2 get_total_hits

Returns the total number of hits returned by the search query.

=head2 get_page

Returns the current page, if you have requested a paged result list.

=head2 get_items

Returns an array of L<Catalyst::Model::Search::Item> objects.

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

