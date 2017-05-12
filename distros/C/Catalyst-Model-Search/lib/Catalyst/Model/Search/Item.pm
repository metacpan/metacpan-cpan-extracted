package Catalyst::Model::Search::Item;


use strict;
use warnings;
use Class::Std;
{
    my %score_of    : ATTR( :init_arg<score> :get<score> );
    my %key_of      : ATTR( :init_arg<key>   :get<key>   );
    my %data_of     : ATTR;
    
    sub get_fields : method {
        my $self = shift;
        if ( ref $data_of{ident $self} eq 'HASH' ) {
            return keys %{ $data_of{ident $self} };
        }
        return ();
    }
    
    sub add_data : method {
        my ( $self, $data ) = @_;
        
        $data_of{ident $self}->{ $data->{name} } = $data->{value};
    }
    
    sub get : method {
        my ( $self, $key ) = @_;
        return $data_of{ident $self}->{$key};
    }

    sub as_str : STRINGIFY {
        my ( $self, $ident ) = @_;
        return $key_of{$ident};
    }
}

1;
__END__

=head1 NAME

Catalyst::Model::Search::Item - Standard access to a search result item

=head1 DESCRIPTION

This module represents a single search result item.

=head1 METHODS

=head2 get_score

Returns the score the search engine assigned to this item.

=head2 get_key

Returns the unique key for this item.

=head2 get_fields

Returns an array of all of the data fields stored in this item.

=head2 get( 'key' )

Returns the text data associated with the specified key.  This method is only
useful if you have set the Catalyst::Model::Search 'result_style' config
option to 'full'.

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

