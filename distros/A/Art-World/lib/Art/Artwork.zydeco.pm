include Behavior::Showable;
include Behavior::Collectionable;

class Artwork with Showable, Collectionable  {
    has creation_date;
    has creator (
        is => ro,
        # Should be ArrayRed of Artists
        type => ArrayRef[ Object ]
    );
    has material;
    has size;
};


=encoding UTF-8

=head1 NAME

Art::Artwork -

=head1 SYNOPSIS

  my $artwork = Art->new_artwork(
    creator => [ $artist, $another_artist ]  ,
    value => 100,
    owner => $f->person_name );

=head1 DESCRIPTION

Artwork is a Zydeco subclass of L<Art::Work>.

=head1 ROLES

=over

=item L<C<Behavior::Showable>>

=item L<C<Behavior::Collectionable>>

=back

=head1 AUTHORS

=over

=item Sébastien Feugère <sebastien@feugere.net>

=item Seb. Hu-Rillettes <shr@balik.network>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2020 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=cut
