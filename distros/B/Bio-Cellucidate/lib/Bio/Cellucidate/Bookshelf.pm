package Bio::Cellucidate::Bookshelf;

=pod

=head1 NAME

Bio::Cellucidate::Bookshelf

=head1 SYNOPSIS

    # Set your authentication, see L<http://cellucidate.com/api> for more info.
    $Bio::Cellucidate::AUTH = { login => 'email@server', api_key => '12334567890' };

    # All your bookshelves
    $bookshelves = Bio::Cellucidate::Bookshelf->find( $hashref );

    # Bookshelf by a bookshelf id
    $bookshelf = Bio::Cellucidate::Bookshelf->get( $bookshelf_id );

    # All books on a bookshelf (given an id);
    $books = Bio::Cellucidate::Bookshelf->books( $bookshelf_id );


=head1 SEE ALSO

L<http://cellucidate.com>

=head1 AUTHOR

Brian Kaney, E<lt>brian@vermonster.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Brian Kaney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

use base Bio::Cellucidate::Base;

sub route { '/bookshelves'; }
sub element { 'bookshelf'; }

# Bio::Cellucidate::Bookshelf->books($bookshelf_id);
sub books {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::Book->route, $format)->processResponseAsArray(Bio::Cellucidate::Book->element);
} 

1;
