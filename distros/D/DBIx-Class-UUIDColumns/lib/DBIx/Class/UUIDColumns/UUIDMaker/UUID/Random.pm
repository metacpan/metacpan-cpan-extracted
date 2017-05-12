package DBIx::Class::UUIDColumns::UUIDMaker::UUID::Random;

use strict;
use warnings;

use base qw/DBIx::Class::UUIDColumns::UUIDMaker/;
use UUID::Random ();

sub as_string {
    return UUID::Random::generate;
};

1;
__END__

=head1 NAME

DBIx::Class::UUIDColumns::UUIDMaker::UUID::Random - Create uuids using UUID::Random

=head1 SYNOPSIS

  package Artist;
  __PACKAGE__->load_components(qw/UUIDColumns Core DB/);
  __PACKAGE__->uuid_columns( 'artist_id' );
  __PACKAGE__->uuid_class('::UUID::Random');

=head1 DESCRIPTION

This DBIx::Class::UUIDColumns::UUIDMaker subclass uses UUID::Random to generate
uuid strings using UUID::Random::generate.

=head1 METHODS

=head2 as_string

Returns the new uuid as a string.

=head1 SEE ALSO

L<UUID::Random>

=head1 AUTHOR

Moritz Onken <onken@houseofdesign.de>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
