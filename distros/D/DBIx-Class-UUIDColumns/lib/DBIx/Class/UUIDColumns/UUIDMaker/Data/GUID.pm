package DBIx::Class::UUIDColumns::UUIDMaker::Data::GUID;

use strict;
use warnings;

use base qw/DBIx::Class::UUIDColumns::UUIDMaker/;
use Data::GUID ();

sub as_string {
    return Data::GUID->new->as_string;
};

1;
__END__

=head1 NAME

DBIx::Class::UUIDColumns::UUIDMaker::Data::GUID - Create uuids using Data::GUID

=head1 SYNOPSIS

  package Artist;
  __PACKAGE__->load_components(qw/UUIDColumns Core DB/);
  __PACKAGE__->uuid_columns( 'artist_id' );
  __PACKAGE__->uuid_class('::Data::GUID');

=head1 DESCRIPTION

This DBIx::Class::UUIDColumns::UUIDMaker subclass uses Data::GUID to generate
uuid strings in the following format:

  098f2470-bae0-11cd-b579-08002b30bfeb

=head1 METHODS

=head2 as_string

Returns the new uuid as a string.

=head1 SEE ALSO

L<Data::GUID>

=head1 AUTHOR

Chris Laco <claco@chrislaco.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
